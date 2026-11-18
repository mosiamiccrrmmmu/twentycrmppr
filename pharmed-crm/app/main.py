from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from starlette.middleware.base import BaseHTTPMiddleware
from sqlalchemy import text
from app.core.database import engine

from app.core.config import settings, BASE_DIR
from app.core.database import init_db
from app.api import api_router


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        response.headers.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
        if request.url.scheme == "https":
            response.headers.setdefault("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        return response


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings.DATA_DIR.mkdir(parents=True, exist_ok=True)
    settings.BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    init_db()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="سامانه CRM فروش فارمد پلیمر رایان - نسخه چندکاربره مرکزی",
    docs_url="/api/docs" if settings.ENVIRONMENT.lower() != "production" else None,
    redoc_url="/api/redoc" if settings.ENVIRONMENT.lower() != "production" else None,
    lifespan=lifespan,
)

app.add_middleware(SecurityHeadersMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

if settings.ENVIRONMENT.lower() == "production":
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=settings.trusted_hosts)

app.include_router(api_router)


@app.get("/api/health")
def health():
    return {"status": "ok", "app": settings.APP_NAME, "version": settings.APP_VERSION}


@app.get("/api/ready")
def readiness():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return {"status": "ready", "database": "connected"}
    except Exception:
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail="سرویس آماده نیست؛ اتصال پایگاه داده برقرار نشد")


# Frontend
FRONTEND_DIR = BASE_DIR / "frontend"
INDEX_FILE = FRONTEND_DIR / "index.html"


@app.get("/")
def serve_frontend():
    if INDEX_FILE.exists():
        return FileResponse(INDEX_FILE, media_type="text/html; charset=utf-8")
    return HTMLResponse(
        "<h2>CRM فارمد</h2><p>فایل frontend/index.html پیدا نشد.</p>"
        "<p><a href='/api/docs'>API Docs</a> | <a href='/api/health'>Health</a></p>"
    )


MANAGER_FILE = FRONTEND_DIR / "manager.html"
FINANCE_FILE = FRONTEND_DIR / "finance.html"

@app.get("/manager")
def serve_manager():
    if MANAGER_FILE.exists():
        return FileResponse(MANAGER_FILE, media_type="text/html; charset=utf-8")
    return HTMLResponse("<h2>manager.html not found</h2>")

if FRONTEND_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(FRONTEND_DIR)), name="static")

@app.get("/tasks")
def serve_tasks():
    tasks_file = FRONTEND_DIR / "tasks.html"
    if tasks_file.exists():
        return FileResponse(tasks_file, media_type="text/html; charset=utf-8")
    return HTMLResponse("<h2>tasks.html not found</h2>")

@app.get("/finance")
def serve_finance():
    if FINANCE_FILE.exists():
        return FileResponse(FINANCE_FILE, media_type="text/html; charset=utf-8")
    return HTMLResponse("<h2>finance.html not found</h2>")

SALESOPS_FILE = FRONTEND_DIR / "salesops.html"
@app.get("/salesops")
def serve_salesops():
    if SALESOPS_FILE.exists():
        return FileResponse(SALESOPS_FILE, media_type="text/html; charset=utf-8")
    return HTMLResponse("<h2>salesops.html not found</h2>")
