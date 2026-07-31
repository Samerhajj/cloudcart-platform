FROM python:3.10-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

RUN useradd -m appuser
USER appuser

EXPOSE 5000

ENV FLASK_SECRET_KEY=""

CMD ["python3", "app.py"]
