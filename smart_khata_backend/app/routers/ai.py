import os
import tempfile
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from app.models.schemas import VoiceIntentRequest, VoiceIntentResponse
from app.auth.dependencies import require_employee_or_owner
from app.services.ai_service import classify_and_execute_intent, transcribe_audio_file

router = APIRouter(prefix="/api/ai", tags=["AI Voice Command Interface"])

@router.post("/intent", response_model=VoiceIntentResponse)
async def process_text_intent(
    payload: VoiceIntentRequest,
    current_user: dict = Depends(require_employee_or_owner)
):
    result = await classify_and_execute_intent(payload.text, payload.context)
    return VoiceIntentResponse(**result)

@router.post("/stt-intent", response_model=VoiceIntentResponse)
async def process_speech_intent(
    file: UploadFile = File(...),
    current_user: dict = Depends(require_employee_or_owner)
):
    # Save incoming audio file to temporary directory
    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, f"voice_{file.filename}")
    with open(temp_path, "wb") as f:
        content = await file.read()
        f.write(content)

    try:
        # Converts Speech-to-Text NO MATTER WHAT (Whisper ASR + ASR decoder fallback)
        transcribed_text = transcribe_audio_file(temp_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Audio transcription failed: {str(e)}")
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    # Execute NLP Intent Detection & Automated Ledger Mutation
    result = await classify_and_execute_intent(transcribed_text)
    return VoiceIntentResponse(**result)
