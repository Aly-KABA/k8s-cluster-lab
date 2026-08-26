# Image de base légère avec Python
FROM python:3.12-slim

WORKDIR /app

# Copie et installation des dépendances (mis en cache si le code change mais pas les deps)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code de l'application
COPY main.py .

EXPOSE 8000

# Lance l'API avec uvicorn (serveur ASGI), accessible depuis l'extérieur du conteneur
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
