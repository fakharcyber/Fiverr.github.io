@echo off
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Ollama"
echo Downloading Qwen 1.5B...
ollama pull qwen2.5:1.5b
pause
