"""Emergency alert workflow (SRS FR-19, FR-21): notify linked caregivers and record delivery status."""

from sqlalchemy.orm import Session

from ...models.caregiver import CaregiverElderlyLink
from ...models.emergency import EmergencyIncident, IncidentNotification
from .senders import get_push_sender


def _alert_text(incident: EmergencyIncident, patient_name: str) -> tuple[str, str]:
    title = f"ElderGuard alert: {incident.title}"
    body = f"{patient_name} - {incident.description or incident.title}. Location: {incident.location_text or 'unknown'}"
    return title, body[:240]


def notify_caregivers(db: Session, incident: EmergencyIncident) -> list[IncidentNotification]:
    elderly = incident.elderly
    patient_name = elderly.user.full_name if elderly and elderly.user else "Your relative"
    title, body = _alert_text(incident, patient_name)
    data = {"incident_id": incident.id, "elderly_id": incident.elderly_id, "type": incident.incident_type}
    sender = get_push_sender()

    links = (
        db.query(CaregiverElderlyLink)
        .filter(CaregiverElderlyLink.elderly_id == incident.elderly_id, CaregiverElderlyLink.status == "active")
        .all()
    )

    records: list[IncidentNotification] = []
    for link in links:
        if not link.allows("receive_alerts"):
            continue
        user = link.caregiver.user
        tokens = list(user.device_tokens)
        if not tokens:
            status, message = "queued", "Caregiver has no registered push device"
        else:
            results = [sender.send(t.token, title, body, data) for t in tokens]
            delivered = [r for r in results if r.status in ("sent", "simulated_sent")]
            status = delivered[0].status if delivered else "failed"
            message = (delivered[0] if delivered else results[0]).message

        record = IncidentNotification(
            incident_id=incident.id,
            recipient_user_id=user.id,
            contact_name=user.full_name,
            contact_phone=user.phone,
            channel="push",
            delivery_status=status,
            status_message=message[:255],
        )
        db.add(record)
        records.append(record)
    return records
