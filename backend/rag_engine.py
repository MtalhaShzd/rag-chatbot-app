import os
from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from dotenv import load_dotenv

load_dotenv()

def get_groq_llm():
    return ChatGroq(
        model="llama-3.3-70b-versatile",  # use this model
        temperature=0.6,
        groq_api_key=os.getenv("GROQ_API_KEY")
    )


def format_history(history):
    formatted = []
    for m in history:
        if isinstance(m, dict) and "role" in m \
                and "content" in m:
            formatted.append(
                f"{m['role']}: {m['content']}")
        else:
            formatted.append(f"user: {m}")
    return "\n".join(formatted)


def ask_llm(question, history,
             mode="general", context=""):

    if mode == "document" and context.strip():
        # Document mode — answer from context
        prompt = ChatPromptTemplate.from_template("""
You are a helpful AI assistant.
The user has uploaded a document. Answer ONLY based 
on the document content below.
If the answer is clearly present in the document, 
provide it directly and completely.
Do not say "not available" if the information IS 
in the context below.

Document Content:
{context}

Conversation History:
{history}

User Question: {question}

Answer based on the document above:
""")
    elif mode == "document" and not context.strip():
        # Document mode but no vectorstore yet
        prompt = ChatPromptTemplate.from_template("""
You are a helpful AI assistant.
The user wants to ask about an uploaded document 
but no document has been indexed yet.
Tell them to upload a document first using the 
Upload tab, then ask their question.

User Question: {question}

Response:
""")
    else:
        # General mode — answer from knowledge
        prompt = ChatPromptTemplate.from_template("""
You are a helpful, knowledgeable AI assistant.
Answer the user's question clearly and helpfully 
using your general knowledge.
Be conversational and thorough.

Conversation History:
{history}

User Question: {question}

Answer:
""")

    chain = prompt | get_groq_llm() | StrOutputParser()

    response = chain.invoke({
        "question": question,
        "history": format_history(history),
        "context": context,
    })

    return response