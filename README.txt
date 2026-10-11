FAKHAR FIVERR AI - CHAT READY FREE VERSION

This version adds a robot/chat screen plus Fiverr Reply Assistant.

1) Start Python AI
Keep the Python server running in one CMD:
cd E:\fakhar_fiverr_ai_free\backend
venv\Scripts\activate
python -m pip install -r requirements.txt
python -m uvicorn app:app --host 0.0.0.0 --port 8000

Or use 3_START_PYTHON_AI.bat from this folder.

2) Flutter
Open a NEW CMD:
cd E:\fakhar_fiverr_ai_free
4_CREATE_FLUTTER.bat

The Flutter app has two tabs:
- Chat: talk directly to robot Fakhar
- Fiverr: paste client message and generate a reply

For Windows desktop the Flutter API URL is:
http://127.0.0.1:8000

Do NOT close the Python CMD while using the app.

3) Ollama
Ollama must be installed and the model must exist:
ollama pull qwen2.5:1.5b

4) Fiverr
Copy client message -> Fiverr tab -> Generate -> Copy -> review -> paste into Fiverr -> send yourself.

This starter does not automate sending messages on Fiverr.


## Urdu / Roman Urdu
The chat prompt is configured to understand Urdu script, Roman Urdu and mixed Urdu-English, and to answer in the same language during direct chat. Fiverr client replies remain professional English unless you ask otherwise.
