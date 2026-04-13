import os
import uuid
from gtts import gTTS

AUDIO_DIR = "audio_files"

# Ensure directory exists
os.makedirs(AUDIO_DIR, exist_ok=True)

def speak_text(text, lang="english"):
    try:
        # Normalize language
        lang = lang.lower()
        code = "ur" if lang == "urdu" else "en"

        # Generate unique filename
        filename = f"{uuid.uuid4().hex}.mp3"
        path = os.path.join(AUDIO_DIR, filename)

        # Generate speech
        tts = gTTS(text=text, lang=code, slow=False)
        tts.save(path)

        return {
            "audio_path": path,
            "message": "Audio generated successfully"
        }

    except Exception as e:
        print("TTS Error:", e)

        # Fallback to English
        try:
            filename = f"{uuid.uuid4().hex}_fallback.mp3"
            path = os.path.join(AUDIO_DIR, filename)

            tts = gTTS(text=text, lang="en", slow=False)
            tts.save(path)

            return {
                "audio_path": path,
                "message": "Generated with fallback language (English)"
            }

        except Exception as inner_error:
            return {
                "error": str(inner_error)
            }