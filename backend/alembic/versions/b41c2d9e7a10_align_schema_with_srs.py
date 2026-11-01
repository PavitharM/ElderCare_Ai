"""align schema with SRS: 4-level risk, baselines, push tokens, device-linked vitals

Revision ID: b41c2d9e7a10
Revises: 930b815e6425
Create Date: 2026-10-31 12:00:00

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b41c2d9e7a10"
down_revision: Union[str, None] = "930b815e6425"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

OLD_RISK = ("low", "moderate", "high")
NEW_RISK = ("normal", "warning", "high_risk", "critical")
OLD_METRICS = ("heart_rate", "spo2", "temperature", "blood_pressure")
NEW_METRICS = OLD_METRICS + ("activity_level",)


def upgrade() -> None:
    # --- risk_assessments: SRS FR-13 categories + scores that can reach 100 ---
    op.alter_column("risk_assessments", "risk_level",
                    existing_type=sa.Enum(*OLD_RISK, name="risk_level_enum"),
                    type_=sa.Enum(*OLD_RISK, *NEW_RISK, name="risk_level_enum"), existing_nullable=False)
    op.execute("UPDATE risk_assessments SET risk_level = CASE risk_level "
               "WHEN 'low' THEN 'normal' WHEN 'moderate' THEN 'warning' WHEN 'high' THEN 'high_risk' "
               "ELSE risk_level END")
    op.alter_column("risk_assessments", "risk_level",
                    existing_type=sa.Enum(*OLD_RISK, *NEW_RISK, name="risk_level_enum"),
                    type_=sa.Enum(*NEW_RISK, name="risk_level_enum"), existing_nullable=False)
    op.execute("UPDATE risk_assessments SET status_label = 'Assessment migrated' WHERE status_label IS NULL")
    op.alter_column("risk_assessments", "status_label", existing_type=sa.String(64), nullable=False)
    for col in ("vital_score", "adherence_score", "fall_risk_score"):
        op.alter_column("risk_assessments", col, existing_type=sa.Numeric(4, 2), type_=sa.Numeric(5, 2))
    op.add_column("risk_assessments", sa.Column("anomalies", sa.JSON(), nullable=True))

    # --- health_vitals: device link (FR-09), activity metric, wider value range ---
    op.add_column("health_vitals", sa.Column("device_id", sa.String(36), nullable=True))
    op.create_index("ix_health_vitals_device_id", "health_vitals", ["device_id"])
    op.create_foreign_key("fk_health_vitals_device", "health_vitals", "wearable_devices",
                          ["device_id"], ["id"], ondelete="SET NULL")
    op.alter_column("health_vitals", "metric_type",
                    existing_type=sa.Enum(*OLD_METRICS, name="vital_metric_enum"),
                    type_=sa.Enum(*NEW_METRICS, name="vital_metric_enum"), existing_nullable=False)
    op.alter_column("health_vitals", "value", existing_type=sa.Numeric(6, 2), type_=sa.Numeric(8, 2),
                    existing_nullable=False)

    # --- medications: frequency (FR-15) ---
    op.add_column("medications", sa.Column("frequency", sa.String(16), nullable=False, server_default="daily"))
    op.add_column("medications", sa.Column("days_of_week", sa.JSON(), nullable=True))

    # --- emergencies: fall confirmation window + caregiver recipients ---
    op.add_column("emergency_incidents", sa.Column("escalate_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("incident_notifications", sa.Column("recipient_user_id", sa.String(36), nullable=True))
    op.create_index("ix_incident_notifications_recipient_user_id", "incident_notifications", ["recipient_user_id"])
    op.create_foreign_key("fk_incident_notifications_user", "incident_notifications", "users",
                          ["recipient_user_id"], ["id"], ondelete="SET NULL")
    op.alter_column("incident_notifications", "contact_phone", existing_type=sa.String(32), nullable=True)

    # --- QR access audit ---
    op.add_column("hospital_qr_tokens", sa.Column("last_accessed_at", sa.DateTime(timezone=True), nullable=True))

    # --- new tables ---
    op.create_table(
        "patient_baselines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("elderly_id", sa.String(36), sa.ForeignKey("elderly_profiles.id", ondelete="CASCADE"),
                  nullable=False, unique=True),
        sa.Column("heart_rate_min", sa.Numeric(5, 1), nullable=False),
        sa.Column("heart_rate_max", sa.Numeric(5, 1), nullable=False),
        sa.Column("spo2_min", sa.Numeric(5, 1), nullable=False),
        sa.Column("temperature_min", sa.Numeric(4, 1), nullable=False),
        sa.Column("temperature_max", sa.Numeric(4, 1), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("defined_by", sa.String(128), nullable=True),
        sa.Column("updated_by_user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_table(
        "push_device_tokens",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token", sa.String(255), nullable=False, unique=True),
        sa.Column("platform", sa.String(16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_push_device_tokens_user_id", "push_device_tokens", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_push_device_tokens_user_id", table_name="push_device_tokens")
    op.drop_table("push_device_tokens")
    op.drop_table("patient_baselines")
    op.drop_column("hospital_qr_tokens", "last_accessed_at")
    op.drop_constraint("fk_incident_notifications_user", "incident_notifications", type_="foreignkey")
    op.drop_index("ix_incident_notifications_recipient_user_id", table_name="incident_notifications")
    op.drop_column("incident_notifications", "recipient_user_id")
    op.drop_column("emergency_incidents", "escalate_at")
    op.drop_column("medications", "days_of_week")
    op.drop_column("medications", "frequency")
    op.execute("DELETE FROM health_vitals WHERE metric_type = 'activity_level'")
    op.alter_column("health_vitals", "metric_type",
                    existing_type=sa.Enum(*NEW_METRICS, name="vital_metric_enum"),
                    type_=sa.Enum(*OLD_METRICS, name="vital_metric_enum"), existing_nullable=False)
    op.drop_constraint("fk_health_vitals_device", "health_vitals", type_="foreignkey")
    op.drop_index("ix_health_vitals_device_id", table_name="health_vitals")
    op.drop_column("health_vitals", "device_id")
    op.drop_column("risk_assessments", "anomalies")
    op.alter_column("risk_assessments", "risk_level",
                    existing_type=sa.Enum(*NEW_RISK, name="risk_level_enum"),
                    type_=sa.Enum(*OLD_RISK, *NEW_RISK, name="risk_level_enum"), existing_nullable=False)
    op.execute("UPDATE risk_assessments SET risk_level = CASE risk_level "
               "WHEN 'normal' THEN 'low' WHEN 'warning' THEN 'moderate' ELSE 'high' END")
    op.alter_column("risk_assessments", "risk_level",
                    existing_type=sa.Enum(*OLD_RISK, *NEW_RISK, name="risk_level_enum"),
                    type_=sa.Enum(*OLD_RISK, name="risk_level_enum"), existing_nullable=False)
