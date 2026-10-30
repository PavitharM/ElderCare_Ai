import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ...core.database import get_db
from ...models.user import User
from ...models.ai_risk import RiskAssessment
from ...schemas.ai_risk import RiskAssessmentOut
from ...ai.risk_engine import compute_risk_assessment
from ..deps import get_current_user

router = APIRouter()

@router.get("/risk-assessment/latest", response_model=RiskAssessmentOut)
def get_latest_risk_assessment(
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    if not target_elderly_id:
        raise HTTPException(status_code=400, detail="Target elderly_id not specified")

    assessment = db.query(RiskAssessment).filter(
        RiskAssessment.elderly_id == target_elderly_id
    ).order_by(desc(RiskAssessment.calculated_at)).first()

    if not assessment:
        # Compute dynamic observation
        data = compute_risk_assessment(db, target_elderly_id)
        assessment = RiskAssessment(
            id=str(uuid.uuid4()),
            elderly_id=target_elderly_id,
            risk_level=data["risk_level"],
            status_label=data["status_label"],
            confidence_score=data["confidence_score"],
            vital_score=data["vital_score"],
            adherence_score=data["adherence_score"],
            fall_risk_score=data["fall_risk_score"],
            contributing_factors=data["contributing_factors"],
            disclaimer=data["disclaimer"],
            calculated_at=data["calculated_at"],
        )
        db.add(assessment)
        db.commit()
        db.refresh(assessment)

    return assessment

@router.post("/risk-assessment/evaluate", response_model=RiskAssessmentOut)
def evaluate_risk_assessment(
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    if not target_elderly_id:
        raise HTTPException(status_code=400, detail="Target elderly_id not specified")

    data = compute_risk_assessment(db, target_elderly_id)
    assessment = RiskAssessment(
        id=str(uuid.uuid4()),
        elderly_id=target_elderly_id,
        risk_level=data["risk_level"],
        status_label=data["status_label"],
        confidence_score=data["confidence_score"],
        vital_score=data["vital_score"],
        adherence_score=data["adherence_score"],
        fall_risk_score=data["fall_risk_score"],
        contributing_factors=data["contributing_factors"],
        disclaimer=data["disclaimer"],
        calculated_at=data["calculated_at"],
    )
    db.add(assessment)
    db.commit()
    db.refresh(assessment)

    return assessment
