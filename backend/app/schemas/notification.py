from typing import Literal

from pydantic import BaseModel, Field


class PushTokenRequest(BaseModel):
    token: str = Field(..., min_length=10, max_length=255)
    platform: Literal["android", "ios", "web"] = "android"
