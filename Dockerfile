# Research Platform - Multi-stage build
FROM python:3.12-slim AS builder
WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY src/ ./src/
WORKDIR /app/src
ENV PYTHONPATH=/app/src
EXPOSE 8080
CMD ["python", "app.py"]
