FROM python:3.9-alpine3.14

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/

USER root
CMD ["python", "app/config.py"]
