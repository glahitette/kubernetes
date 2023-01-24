# kubernetes-app/Dockerfile
FROM python:3.7-alpine
LABEL maintainer="Guillaume Lahitette"

# Create and change working directory
WORKDIR /app

# Add application requirements
COPY requirements.txt .

# Install requirements
RUN pip install -r requirements.txt

# Add application
COPY app.py .
COPY config.py .

# Create a specific user to run the Python application
RUN adduser -D my-user -u 1000
USER 1000

# Launch application
ENTRYPOINT ["gunicorn"]
CMD ["--config", "config.py", "app:app", "--log-config", "/etc/config/log-config.ini"] # <== Mise à jour
