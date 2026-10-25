
FROM alpine:latest

# Installer Python et les dépendances système
RUN apk add --no-cache python3 py3-pip

WORKDIR /opt/webapp

# Copier les dépendances
COPY webapp/requirements.txt /tmp/requirements.txt

# Créer un environnement virtuel et installer les dépendances
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# Rendre Python et Gunicorn accessibles
ENV PATH="/opt/venv/bin:$PATH"
ENV PORT=5000

# Copier le code de l'application
COPY webapp/ /opt/webapp/

# Démarrer l'application
EXPOSE 5000

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} wsgi"]


