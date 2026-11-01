from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

from .config import settings

LOCAL_TZ = ZoneInfo(settings.TIMEZONE)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def local_now() -> datetime:
    return datetime.now(LOCAL_TZ)


def local_today() -> date:
    return local_now().date()


def as_utc(dt: datetime) -> datetime:
    """MySQL returns naive datetimes; values are always stored in UTC."""
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt.astimezone(timezone.utc)
