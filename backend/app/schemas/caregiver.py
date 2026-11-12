from pydantic import BaseModel, Field


class LinkElderlyRequest(BaseModel):
    linking_code: str = Field(..., min_length=4, max_length=16)  # e.g. "EG-8829-KP"
