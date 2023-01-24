# kubernetes-app/config.py
import os

bind = "0.0.0.0:8000"
worker_class = "gthread"
threads = int(os.getenv('GUNICORN_CORES','1')) * 2 + 1
