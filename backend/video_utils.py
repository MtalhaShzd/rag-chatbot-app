import os
import tempfile
import speech_recognition as sr
from moviepy  import VideoFileClip

def speech_to_text_from_file(audio_path: str) -> str:
    """
    Convert WAV audio file to text using Google Speech Recognition.
    """
    recognizer = sr.Recognizer()

    with sr.AudioFile(audio_path) as source:
        recognizer.adjust_for_ambient_noise(source, duration=0.5)
        audio_data = recognizer.record(source)

    try:
        text = recognizer.recognize_google(audio_data)
    except sr.UnknownValueError:
        text = "Speech could not be understood."
    except sr.RequestError as e:
        text = f"Speech recognition error: {e}"

    return text


def extract_audio_from_video(file) -> str:
    """
    Extract audio from an uploaded video and convert it to text.
    Works with FastAPI UploadFile or raw file objects.
    Ensures proper cleanup and avoids file locking on Windows.
    """
    # Determine actual file object
    file_obj = getattr(file, "file", file)
    file_obj.seek(0)  # Reset pointer

    # Create temporary MP4 file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as temp_video:
        temp_video.write(file_obj.read())
        temp_video_path = temp_video.name

    temp_wav = temp_video_path.replace(".mp4", ".wav")
    clip = None

    try:
        clip = VideoFileClip(temp_video_path)

        if clip.audio is None:
            raise ValueError("Video has no audio track.")

        # Extract audio to WAV (remove verbose/logger args)
        clip.audio.write_audiofile(temp_wav)

        # Convert speech → text
        text = speech_to_text_from_file(temp_wav)

    except Exception as e:
        raise RuntimeError(f"Error processing video: {str(e)}")

    finally:
        # Close the clip to release the file (important on Windows)
        if clip:
            clip.close()

        # Cleanup temporary files
        if os.path.exists(temp_video_path):
            os.remove(temp_video_path)
        if os.path.exists(temp_wav):
            os.remove(temp_wav)

    return text