# 🤖 RAG Chatbot – Multimodal AI Assistant

A full-stack **Retrieval-Augmented Generation (RAG) Chatbot** built with **Flutter + FastAPI + Firebase**, capable of answering questions from both general knowledge and user-uploaded documents.

---

## 📌 Project Overview

RAG Chatbot is an intelligent multimodal AI assistant developed as a semester project for Mobile Application Development. It integrates modern AI technologies to provide accurate, context-aware responses using **document retrieval + LLM reasoning**.

Unlike traditional chatbots, this system uses **Retrieval-Augmented Generation (RAG)** to ensure responses are grounded in real document data instead of hallucinated answers.

---

## ✨ Key Features

### 📄 Multimodal Document Support
- PDF, DOCX, PPTX, XLSX, CSV  
- Images (OCR)  
- MP4 (Speech-to-Text)  

### 🤖 AI-Powered Chat
- General Knowledge Mode  
- Document-Based Q&A Mode  

### 🔐 Authentication
- Firebase Email/Password  
- Google Sign-In  

### 💬 Real-Time Chat System
- Chat history stored in Firestore  
- Session-based conversation grouping  

### 🔊 Text-to-Speech
- AI responses converted to audio using gTTS  

### 🎨 Modern UI
- Dark theme inspired by ChatGPT & Claude  

### ⚡ Fast Semantic Search
- FAISS vector database  
- HuggingFace embeddings  

---

## 🏗️ System Architecture

The application follows a client-server architecture:

Flutter Frontend → FastAPI Backend → AI + FAISS
↓
Firebase (Auth + Firestore)


### 🔹 Backend (FastAPI)
- Handles AI processing, document parsing, and TTS  
- Uses:
  - Groq LLM (Llama 3.3 70B)  
  - FAISS for vector search  
  - HuggingFace embeddings  

### 🔹 Frontend (Flutter)
- Provider-based state management  
- GoRouter for navigation  
- Clean modular structure  

### 🔹 Firebase
- Authentication  
- Firestore database for chat history  

---

## 🔄 Data Flow

1. User sends message  
2. API request sent to FastAPI  
3. FAISS retrieves relevant document chunks (if enabled)  
4. LLM generates response  
5. gTTS converts response to audio  
6. Response + audio returned to frontend  
7. Stored in Firestore  

---

## 🧠 Technology Stack

| Layer       | Technology |
|------------|-----------|
| Frontend   | Flutter (Dart) |
| Backend    | FastAPI (Python) |
| AI Model   | Groq (Llama 3.3 70B) |
| Vector DB  | FAISS |
| Embeddings | sentence-transformers |
| Auth       | Firebase Authentication |
| Database   | Cloud Firestore |
| TTS        | Google gTTS |

---

## 📡 API Endpoints

| Endpoint | Method | Description |
|----------|--------|------------|
| `/chat`  | POST   | Send message and get AI response |
| `/upload`| POST   | Upload document for indexing |
| `/reset` | POST   | Reset FAISS index |
| `/audio/{filename}` | GET | Retrieve audio file |
| `/docs`  | GET    | Swagger API docs |

---

## ⚙️ Installation & Setup

### 🔧 Prerequisites
- Flutter 3.x+  
- Python 3.9+  
- Node.js 18+  
- Firebase CLI  

---

### 🖥️ Backend Setup

cd backend
pip install -r requirements.txt

Create a .env file:

GROQ_API_KEY=your_key_here
HF_TOKEN=your_token_here

Run the server:

uvicorn app:app --host 0.0.0.0 --port 8000 --reload

Frontend Setup
cd rag_chatbot_app
flutter pub get

Configure Firebase:

flutterfire configure

Run the app:

flutter run
📁 Project Structure
Backend
backend/
├── app.py
├── rag_engine.py
├── document_utils.py
├── vectorstore_utils.py
├── audio_utils.py
├── video_utils.py
Frontend
lib/
├── screens/
├── providers/
├── services/
├── models/
├── core/
🚀 Features Breakdown
💬 Chat Modes
General Mode → AI answers from knowledge
Document Mode → Answers from uploaded files
📂 Upload System

Supports:

PDF, Word, PPT, Excel, CSV
Images (OCR)
Videos (Speech Recognition)
📊 Chat History
Stored in Firestore
Session-based grouping
Search + delete support
⚙️ Settings
Dark/Light mode
Language (English / Urdu)
Chat mode switching
🔐 Security
Firebase Authentication protection
Firestore rules (user-based access control)
Environment variables for API keys
CORS configuration for backend API
🛠️ Troubleshooting
Issue	Solution
CORS error	Enable CORSMiddleware
Audio not playing	Check static file serving
Document mode not working	Upload document first
Firebase login fails	Add SHA-1 key
🔮 Future Improvements
Multi-session chat threads
Real-time streaming responses
Voice input (Whisper integration)
Export chat as PDF
Cloud deployment & scaling
📜 Conclusion

This project demonstrates a production-level AI system combining:

Retrieval-Augmented Generation
Vector databases (FAISS)
Modern mobile development (Flutter)
Cloud services (Firebase)

It showcases how AI can be integrated into real-world applications with scalability, performance, and usability in mind.

DEMO link
https://drive.google.com/drive/folders/15-v636RbEzhzZq8ipsUgLVJpFlEw8SdJ?usp=sharing

Made with ❤️ by Talha Shahzad
