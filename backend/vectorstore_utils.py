import os
import shutil

from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS


from dotenv import load_dotenv   # to load HF_TOKEN from system env

FAISS_DIR = "faiss_index"


# Load embedding model once
embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)


def load_vectorstore(chunks):
    """
    Load existing FAISS index if present,
    otherwise create a new one.
    Also adds new chunks if provided.
    """

    # -------------------------
    # If index exists
    # -------------------------
    if os.path.exists(FAISS_DIR):

        vs = FAISS.load_local(
            FAISS_DIR,
            embeddings,
            allow_dangerous_deserialization=True
        )

        # Add new documents if provided
        if chunks:
            vs.add_texts(chunks)
            vs.save_local(FAISS_DIR)

        return vs

    # -------------------------
    # Create new FAISS
    # -------------------------
    else:

        vs = FAISS.from_texts(chunks, embeddings)
        vs.save_local(FAISS_DIR)

        return vs


def get_vectorstore():
    """
    Load FAISS without adding new documents.
    Used by the chatbot query.
    """

    if not os.path.exists(FAISS_DIR):
        return None

    return FAISS.load_local(
        FAISS_DIR,
        embeddings,
        allow_dangerous_deserialization=True
    )


def reset_vectorstore():
    """
    Delete FAISS index completely.
    Used by UI reset button.
    """

    if os.path.exists(FAISS_DIR):
        shutil.rmtree(FAISS_DIR)

    return True