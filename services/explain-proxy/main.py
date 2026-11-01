"""Pluto Inspector explain proxy (Google Cloud Run).

POST /explain with a Firebase ID token (Authorization: Bearer <token>) and a
verification-result summary. The service checks the token, then asks Gemini for
a beginner explanation. The Gemini key lives only here (Secret Manager env),
never in the APK. No photo is ever received.
"""
import json
import os
import time
from collections import defaultdict, deque
from typing import Annotated, Literal

import httpx
from fastapi import FastAPI, Header, HTTPException, Request
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from pydantic import BaseModel, ConfigDict, Field, StringConstraints

PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', '')
GEMINI_KEY = os.environ.get('GEMINI_API_KEY', '')
MODELS = ['gemini-3.8-flash', 'gemini-flash-latest', 'gemini-flash-lite-latest']

RATE_LIMIT, RATE_WINDOW_S = 10, 60  # explanations per user per minute
MAX_BODY_BYTES = 4096

# No interactive docs in production; nothing to browse.
app = FastAPI(title='pluto-explain-proxy', docs_url=None, redoc_url=None, openapi_url=None)
_google_request = google_requests.Request()
_calls: dict[str, deque] = defaultdict(deque)

Code = Annotated[str, StringConstraints(pattern=r'^[A-Za-z0-9_]{1,64}$')]
Type = Literal['cw', 'ccw'] | None


class Motor(BaseModel):
    model_config = ConfigDict(extra='forbid')
    motor: Code | None = None
    observed_type: Type = None
    expected_type: Type = None
    finding: Literal['match', 'mismatch', 'unknown'] | None = None


class Summary(BaseModel):
    """Only short enumerated codes are accepted, so free text cannot reach the prompt."""
    model_config = ConfigDict(extra='forbid')
    status: Literal['pass', 'incorrectInstallation', 'unableToVerify',
                    'incorrect_installation', 'unable_to_verify']
    reasons: list[Code] = Field(default_factory=list, max_length=12)
    motors: list[Motor] = Field(default_factory=list, max_length=8)


@app.middleware('http')
async def harden(request: Request, call_next):
    if int(request.headers.get('content-length') or 0) > MAX_BODY_BYTES:
        from fastapi.responses import JSONResponse
        return JSONResponse({'detail': 'payload too large'}, status_code=413)
    response = await call_next(request)
    response.headers.update({
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'Referrer-Policy': 'no-referrer',
        'Cache-Control': 'no-store',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    })
    return response


def _rate_limited(uid: str) -> bool:
    now, q = time.monotonic(), _calls[uid]
    while q and now - q[0] > RATE_WINDOW_S:
        q.popleft()
    if len(q) >= RATE_LIMIT:
        return True
    q.append(now)
    return False


def prompt_for(summary: Summary) -> str:
    facts = json.dumps(summary.model_dump())
    return ('You are the assistant in a Pluto mini-drone propeller inspection app. '
            f'The on-device detector produced this result: {facts}. Explain to a beginner, '
            'in under 120 words, what the result means and exactly what to do next (which '
            'propeller to swap, or how to retake the photo: top-down, whole drone visible, '
            'steady, good light). CW and CCW propellers have mirrored blade pitch; diagonal '
            'motors share a type. Use only the facts given; do not invent findings. Never '
            'suggest arming or spinning the motors. Plain text, no markdown.')


@app.get('/health')  # /healthz is reserved by Cloud Run
def health():
    return {'ok': True}


@app.post('/explain')
async def explain(summary: Summary, authorization: str = Header(default='')):
    if not authorization.startswith('Bearer '):
        raise HTTPException(401, 'missing token')
    try:
        claims = id_token.verify_firebase_token(
            authorization.removeprefix('Bearer '), _google_request, audience=PROJECT_ID)
    except Exception:
        raise HTTPException(401, 'invalid token')
    if not claims or not claims.get('email_verified', False):
        raise HTTPException(401, 'invalid token')
    if _rate_limited(claims['sub']):
        raise HTTPException(429, 'too many requests, try again in a minute')
    body = {'contents': [{'parts': [{'text': prompt_for(summary)}]}]}
    async with httpx.AsyncClient(timeout=12) as client:
        for model in MODELS:
            try:
                r = await client.post(
                    f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
                    headers={'x-goog-api-key': GEMINI_KEY}, json=body)
            except httpx.HTTPError:
                continue
            if r.status_code == 200:
                parts = r.json()['candidates'][0]['content']['parts']
                return {'text': ''.join(p.get('text', '') for p in parts).strip(), 'model': model}
    raise HTTPException(503, 'Gemini unavailable')
