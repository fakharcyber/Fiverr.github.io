from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import httpx

APP_NAME = "Fakhar Fiverr AI"
OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
MODEL = "qwen2.5:1.5b"

BASE_PROMPT = """
You are Fakhar, a friendly AI assistant for a Fiverr freelancer.

Freelancer services:
- Flutter
- Dart
- Supabase
- REST API integration
- HTML, CSS, JavaScript
- Microsoft Documentation / technical documentation

You help the freelancer understand clients and write professional replies.

Language understanding rules:
- The freelancer may write in English, Urdu script, Roman Urdu, or mixed Urdu-English.
- Understand common Pakistani Roman Urdu naturally, including informal spellings and chat-style wording such as "muje", "mujhe", "kia/kya", "kaise/kese", "raha/rahi", "karna hai", "samjha do", and "fiverr client ko kya jawab doon".
- Do not treat Roman Urdu as random or meaningless text. Infer the intended meaning from context.
- In direct chat with the freelancer, answer in the same language they use. For Urdu/Roman Urdu, answer in simple Urdu/Roman Urdu. For English, answer in English. If they ask for English practice or an English reply, answer in English.
- When translating or explaining an English client message, explain it in simple Urdu/Roman Urdu when the freelancer asks in Urdu/Roman Urdu.

Rules:
- Speak naturally and helpfully.
- You can chat casually with the freelancer before working on Fiverr messages.
- For Fiverr replies, use polite, concise, natural professional English unless the freelancer explicitly asks for another language.
- Do not invent price, delivery time, experience, certifications, guarantees, portfolio links, or project details.
- Ask for missing requirements when needed.
- Never ask for passwords, OTPs, secret keys, or private credentials.
- Never claim an action was completed when it was not.
"""

class ReplyRequest(BaseModel):
    client_message: str = Field(min_length=1, max_length=8000)
    reply_type: str = Field(default="general", max_length=50)
    extra_context: str = Field(default="", max_length=3000)

class ChatMessage(BaseModel):
    role: str = Field(pattern="^(user|assistant)$")
    content: str = Field(min_length=1, max_length=5000)

class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=5000)
    history: list[ChatMessage] = Field(default_factory=list, max_length=20)

class AIResponse(BaseModel):
    reply: str
    model: str

app = FastAPI(title=APP_NAME, version="0.2.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

async def ask_ollama(messages: list[dict]) -> str:
    payload = {
        "model": MODEL,
        "stream": False,
        "messages": messages,
        "options": {
            "temperature": 0.5,
            "num_predict": 300,
        },
    }
    try:
        async with httpx.AsyncClient(timeout=120) as client:
            response = await client.post(OLLAMA_URL, json=payload)
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Ollama is not running. Start Ollama first.")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="AI took too long. Try a shorter message.")

    if response.status_code != 200:
        raise HTTPException(status_code=500, detail=f"Ollama error: {response.text[:500]}")

    data = response.json()
    reply = ((data.get("message") or {}).get("content") or "").strip()
    if not reply:
        raise HTTPException(status_code=500, detail="AI returned an empty reply.")
    return reply

@app.get("/")
async def root():
    return {"app": APP_NAME, "status": "running", "model": MODEL}

@app.get("/health")
async def health():
    try:
        async with httpx.AsyncClient(timeout=3) as client:
            r = await client.get("http://127.0.0.1:11434/api/tags")
        return {"ok": True, "ollama": r.status_code == 200, "model": MODEL}
    except Exception as e:
        return {"ok": True, "ollama": False, "model": MODEL, "error": str(e)}

@app.post("/chat", response_model=AIResponse)
async def chat(req: ChatRequest):
    messages = [{"role": "system", "content": BASE_PROMPT + "\nYou are currently chatting with the freelancer directly. Answer their question first, and keep the reply easy to understand."}]
    for item in req.history[-20:]:
        messages.append({"role": item.role, "content": item.content})
    messages.append({"role": "user", "content": req.message})
    reply = await ask_ollama(messages)
    return AIResponse(reply=reply, model=MODEL)

@app.post("/generate-reply", response_model=AIResponse)
async def generate_reply(req: ReplyRequest):
    prompt = f"""
Create a message that the freelancer can send to the Fiverr client.

Client message:
{req.client_message}

Reply type:
{req.reply_type}

Extra context:
{req.extra_context}

Return only the message to the client.
"""
    messages = [
        {"role": "system", "content": BASE_PROMPT},
        {"role": "user", "content": prompt},
    ]
    reply = await ask_ollama(messages)
    return AIResponse(reply=reply, model=MODEL)
