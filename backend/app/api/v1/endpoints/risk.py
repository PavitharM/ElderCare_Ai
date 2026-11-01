from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ....db.session import get_db
from ....models.elderly import ElderlyProfile
from ....schemas.risk import RiskAssessmentOut
from ....services import risk
from ...deps import target_elderly

router = APIRouter()


@router.get("/risk-assessment/latest", response_model=RiskAssessmentOut)
def get_latest_risk_assessment(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    return risk.latest_or_evaluate(db, elderly.id)


@router.post("/risk-assessment/evaluate", response_model=RiskAssessmentOut)
def evaluate_risk_assessment(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    assessment, _ = risk.evaluate(db, elderly.id)
    db.commit()
    db.refresh(assessment)
    return assessment
