"""Development server: python run.py (use `uvicorn app.main:app` without --reload in production)."""

import uvicorn

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
