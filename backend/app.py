import os
import shutil
from fastapi import FastAPI, UploadFile, File, Query

from rag_engine import ask_llm
from audio_utils import speak_text
from document_utils import read_pdf, read_docx, read_image
from video_utils import extract_audio_from_video
from vectorstore_utils import load_vectorstore, reset_vectorstore, get_vectorstore

from langchain_text_splitters import CharacterTextSplitter
from fastapi.staticfiles import StaticFiles


from dotenv import load_dotenv    # to load HF_TOKEN from system env

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()   

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create audio folder if it doesn't exist
os.makedirs("audio_files", exist_ok=True)

# Serve audio files
app.mount(
    "/audio",
    StaticFiles(directory="audio_files"),
    name="audio"
)

# -----------------------------
# FASTAPI APP
# -----------------------------

# Global conversation history
conversation_history = []

# -----------------------------
# HELPER: Format conversation history
# -----------------------------
def format_history(history):
    formatted = []
    for m in history:
        if isinstance(m, dict) and "role" in m and "content" in m:
            formatted.append(f"{m['role']}: {m['content']}")
        else:
            formatted.append(f"user: {str(m)}")
    return "\n".join(formatted)


# -----------------------------
# CHAT ENDPOINT
# -----------------------------
@app.post("/chat")
async def chat(
    question: str = Query(...),
    language: str = Query("english"),
    mode: str = Query("general")
):
    try:
        conversation_history.append(
            {"role": "user", "content": question})

        context = ""
        if mode == "document":
            vs = get_vectorstore()
            if vs:
                # Get more chunks for better coverage
                docs = vs.similarity_search(
                    question, k=5)  # increased from 3
                context = "\n\n---\n\n".join(
                    [d.page_content for d in docs])
                print(f"Context found: "
                      f"{len(context)} chars")
            else:
                print("No vectorstore found!")

        answer = ask_llm(
            question,
            conversation_history[:-1],
            mode=mode,
            context=context
        )

        audio_result = speak_text(answer, language)

        conversation_history.append({
            "role": "assistant",
            "content": answer,
        })

        if isinstance(audio_result, dict):
            raw_path = audio_result.get(
                "audio_path", "")
        else:
            raw_path = str(audio_result)

        filename = os.path.basename(
            raw_path.replace("\\", "/"))
        audio_url = \
            f"http://localhost:8000/audio/{filename}"

        return {
            "answer": answer,
            "audio_url": audio_url
        }

    except Exception as e:
        print(f"Chat error: {e}")
        return {"error": str(e)}
    
# -----------------------------
# FILE UPLOAD ENDPOINT
# -----------------------------
@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    try:
        filename = file.filename.lower()
        print(f"Received file: {filename}")  # debug log
        content = ""

        file.file.seek(0)

        if filename.endswith(".pdf"):
            content = read_pdf(file.file)
            print(f"PDF content length: {len(content)}")

        elif filename.endswith(
                (".docx", ".pptx", ".csv",
                 ".xls", ".xlsx")):
            # Pass filename to read_docx
            file.file.filename = filename
            content = read_docx(file.file)
            print(f"Doc content length: {len(content)}")

        elif filename.endswith(
                (".png", ".jpg", ".jpeg")):
            content = read_image(file.file)
            print(f"Image content length: {len(content)}")

        elif filename.endswith(".mp4"):
            content = extract_audio_from_video(file)

        else:
            return {"error": f"Unsupported file: {filename}"}

        if not content or not content.strip():
            return {
                "error":
                  f"No readable text found in '{filename}'. "
                  "Try a different file or format."
            }

        splitter = CharacterTextSplitter(
            chunk_size=900, chunk_overlap=150)
        chunks = splitter.split_text(content)

        if not chunks:
            return {"error": "Failed to create chunks."}

        load_vectorstore(chunks)
        print(f"Indexed {len(chunks)} chunks")

        return {
            "message": "Document indexed successfully",
            "chunks": len(chunks)
        }

    except Exception as e:
        print(f"Upload error: {e}")
        return {"error": str(e)}
    
# -----------------------------
# RESET VECTORSTORE ENDPOINT
# -----------------------------
@app.post("/reset")
async def reset_index():
    """
    Reset FAISS index completely.
    """
    reset_vectorstore()
    conversation_history.clear()
    return {"message": "FAISS index and conversation history cleared successfully."}