"""Push senders. The log sender is used until FCM_CREDENTIALS_FILE is configured."""

import logging
from dataclasses import dataclass
from functools import lru_cache
from typing import Dict, Protocol

from ...core.config import settings

logger = logging.getLogger(__name__)


@dataclass
class SendResult:
    status: str  # sent | simulated_sent | failed
    message: str


class PushSender(Protocol):
    def send(self, token: str, title: str, body: str, data: Dict[str, str]) -> SendResult: ...


class LogPushSender:
    """Development sender: records the alert without contacting a push provider."""

    def send(self, token: str, title: str, body: str, data: Dict[str, str]) -> SendResult:
        logger.warning("[SIMULATED PUSH] to=%s… title=%s body=%s", token[:12], title, body)
        return SendResult("simulated_sent", "Simulated push (FCM not configured)")


class FcmPushSender:
    def __init__(self, credentials_file: str):
        import firebase_admin  # optional dependency, imported only when configured
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(credentials_file))
        self._messaging = messaging

    def send(self, token: str, title: str, body: str, data: Dict[str, str]) -> SendResult:
        message = self._messaging.Message(
            token=token,
            notification=self._messaging.Notification(title=title, body=body),
            data=data,
            android=self._messaging.AndroidConfig(priority="high"),
        )
        try:
            message_id = self._messaging.send(message)
            return SendResult("sent", f"FCM message {message_id}")
        except Exception as exc:  # provider errors must not break the emergency workflow
            logger.exception("FCM send failed")
            return SendResult("failed", f"FCM error: {exc}"[:255])


@lru_cache
def get_push_sender() -> PushSender:
    if settings.FCM_CREDENTIALS_FILE:
        try:
            return FcmPushSender(settings.FCM_CREDENTIALS_FILE)
        except Exception:
            logger.exception("Could not initialise FCM; falling back to simulated push")
    return LogPushSender()
