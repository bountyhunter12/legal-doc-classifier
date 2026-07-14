# ============================================================
# Render Dockerfile for the Legal Document Classifier.
#
# Render auto-sets $PORT (defaults to 10000 on free plan) and
# expects the app to bind 0.0.0.0:$PORT. The same image works
# locally because `PORT` has a sensible default.
#
# We deliberately do NOT COPY ./saved_model/ — the 418 MB
# Legal-BERT checkpoint is gitignored, and shipping it through
# Render's build context would blow past the free-plan image
# size. Instead, app/model_loader.py downloads the weights on
# first boot from the Hugging Face Hub repo given by $HF_MODEL_ID.
# ============================================================
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=10000

WORKDIR /app

# Install Python deps first so this layer caches across code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy only the small source files. saved_model/ is intentionally
# excluded — see the comment block above for the rationale.
COPY app/ ./app/
COPY index.html ./index.html

# Hugging Face Hub cache lives under /tmp so the model survives
# only inside one container's lifetime. This is fine on Render
# free because the service is single-instance and we re-download
# only on cold start.
ENV HF_HOME=/tmp/hf_cache \
    TRANSFORMERS_CACHE=/tmp/hf_cache \
    HF_HUB_CACHE=/tmp/hf_cache

EXPOSE 10000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
