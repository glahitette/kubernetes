# kubernetes-app/app.py
import time
import os                                                # <== Ajout

from flask import Flask, json, request                   # <== Modif
from flask_redis_sentinel import SentinelExtension       # <== Ajout
from http import HTTPStatus
from werkzeug.exceptions import HTTPException

from prometheus_client import start_http_server, Counter
from threading import Thread

redis_sentinel = SentinelExtension()                     # <== Ajout
redis_connection = redis_sentinel.default_connection     # <== Ajout

app = Flask(__name__)
app.config['REDIS_URL'] = "redis+sentinel://%s:26379/mymaster/0" % os.getenv('REDIS_SENTINEL_SERVICE')   # <== Ajout
redis_sentinel.init_app(app)                                                                             # <== Ajout
num_requests = Counter("num_requests", "Example counter")

def compute():
    app.logger.info("Starting CPU-consuming thread")
    timeNow = int(round(time.time()))
    timeToStop = timeNow + 200
    while timeToStop > timeNow:
        99 * 99
        timeNow = int(round(time.time()))
    app.logger.info("Ending CPU-consuming thread")

@app.route('/')
def hello():
    app.logger.info("This is a log line into the default route")
    num_requests.inc()
    return 'Hello, Kubernetes!'

@app.route("/config")
def config():
    num_requests.inc()
    with open('/etc/config/message','r') as f:
        return f.read()

@app.route("/slow")
def slow():
    t = Thread(target=compute)
    t.start()
    return "CPU is going to heat"


@app.route('/messages/<message>', methods=['GET'])          # <== Ajout
def get_message(message):                                   # <== Ajout
    m = redis_sentinel.master_for("mymaster").get(message)  # <== Ajout
    if m is None:                                           # <== Ajout
        return "Not Found", HTTPStatus.NOT_FOUND            # <== Ajout
    return m.decode("utf-8")                                # <== Ajout


@app.route('/messages/<message>', methods=['PUT'])                                                           # <== Ajout
def put_message(message):                                                                                    # <== Ajout
    if request.headers['Content-Type'] != 'application/json':                                                # <== Ajout
        return "HTTP header 'Content-Type: application/json' expected", HTTPStatus.UNSUPPORTED_MEDIA_TYPE    # <== Ajout
    redis_sentinel.master_for("mymaster").set(message, request.data)                                         # <== Ajout
    return "Created", HTTPStatus.CREATED                                                                     # <== Ajout


@app.route('/messages/<message>', methods=['DELETE'])                         # <== Ajout
def delete_message(message):                                                  # <== Ajout
    if redis_sentinel.master_for("mymaster").delete(message) == 1:            # <== Ajout
        return "Deleted", HTTPStatus.NO_CONTENT                               # <== Ajout


@app.route("/healthz")
def healthz():
    return "Tutto bene !"

@app.route('/ready')                                                                       # <== Ajout
def ready():                                                                               # <== Ajout
    try:                                                                                   # <== Ajout
        if redis_sentinel.master_for("mymaster").ping():                                   # <== Ajout
            return "PING OK"                                                               # <== Ajout
        raise Exception("PING KO")                                                         # <== Ajout
    except Exception as exception:                                                         # <== Ajout
        app.logger.error("Exception: %s" % exception)                                      # <== Ajout
        return "Redis master server unavailable", HTTPStatus.INTERNAL_SERVER_ERROR         # <== Ajout

@app.errorhandler(HTTPException)
def handle_http_exception(exception: HTTPException):
    app.logger.error("Raised Exception: %s" % exception)
    return exception.description, exception.code

@app.errorhandler(Exception)
def handle_exception(exception: Exception):
    app.logger.error("Raised Exception: %s" % exception)
    return HTTPStatus.INTERNAL_SERVER_ERROR.description, HTTPStatus.INTERNAL_SERVER_ERROR

start_http_server(9001)