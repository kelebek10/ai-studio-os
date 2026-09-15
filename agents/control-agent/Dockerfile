FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./

RUN useradd --create-home --uid 10001 controlagent
USER 10001

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s \
  CMD ["python", "healthcheck.py"]

ENTRYPOINT ["python", "control.py"]
