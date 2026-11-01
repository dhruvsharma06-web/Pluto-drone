"""Pluto Inspector explain proxy (Google Cloud Run).

POST /explain with a Firebase ID token (Authorization: Bearer <token>) and a
verification-result summary. The service checks the token, then asks Gemini for
a beginner explanation. The Gemini key lives only here (Secret Manager env),
never in the APK. No photo is ever received.
"""
import json
import os

import httpx
from fastapi import FastAPI, Header, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from pydantic import BaseModel

PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', '')
GEMINI_KEY = os.environ.get('GEMINI_API_KEY', '')
MODELS = ['gemini-3.8-flash', 'gemini-flash-latest', 'gemini-flash-lite-latest']

app = FastAPI(title='pluto-explain-proxy')
_google_request = google_requests.Request()


class Motor(BaseModel):
    motor: str | None = None
    observed_type: str | None = None
    expected_type: str | None = None
    finding: str | None = None


class Summary(BaseModel):
    status: str
    reasons: list[str] = []
    motors: list[Motor] = []


def prompt_for(summary: Summary) -> str:
    facts = json.dumps(summary.model_dump())
    return ('You are the assistant in a Pluto mini-drone propeller inspection app. '
            f'The on-device detector produced this result: {facts}. Explain to a beginner, '
            'in under 120 words, what the result means and exactly what to do next (which '
            'propeller to swap, or how to retake the photo: top-down, whole drone visible, '
            'steady, good light). CW and CCW propellers have mirrored blade pitch; diagonal '
            'motors share a type. Use only the facts given; do not invent findings. Never '
            'suggest arming or spinning the motors. Plain text, no markdown.')


@app.get('/healthz')
def healthz():
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
    if not claims:
        raise HTTPException(401, 'invalid token')
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
