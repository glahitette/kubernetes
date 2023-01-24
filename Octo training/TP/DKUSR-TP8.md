# Docker / Kubernetes - TP8 : Intégration
> **Objectifs du TP** :
>- Adapter notre application pour l’intégrer avec un _back-end_ de stockage
>- Manipuler des ressources custom
>- Adapter une readinessProbe

>
> **Niveau de difficulté** :
> Intermédiaire

## 1- Introduction

Au programme de ce TP, nous allons modifier notre application pour qu’elle s’appuie sur une base mémoire Redis.

## 2- Adaptation de l’application

Pour commencer, nous allons déclarer la librairie qui nous sera utile pour interagir avec un cluster Redis en ajoutant une dépendance dans le fichier `requirements.txt` :
```sh
# kubernetes-app/requirements.txt
Flask==2.0.3
gunicorn==19.9.0
Jinja2==3.1.1
prometheus-client==v0.3.1
json-logging-py==0.2
flask_redis_sentinel==2.0.1 # <== Ajout
```

Il va falloir adapter notre application pour qu'elle :
- Lise une variable d’environnement qui pointe sur les Redis-sentinels qui gèrent notre cluster Redis
- Implémente une API REST-ish minimaliste pour lire, créer ou mettre à jour et supprimer des messages.
- Expose un point d’entrée `/ready` distinct de `/healthz` qui renseigne de l’état de la connexion avec le cluster Redis.

```py
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
```

> **Exercice**
>
> Modifier une première fois le fichier `docker-compose.yml` pour préparer une version **v0.7** de l’application.

## 3- Tester localement avec Docker Compose

Le code est un peu plus long à produire qu’à l'accoutumée. Il va être nécessaire de vraiment tester localement notre application avant de la pousser sur la registry et dans Kubernetes.

> **Exercice**
>- Utiliser `docker compose build` et `docker compose up` puis `curl` dans une seconde console pour invoquer des `GET /ready`, `GET /messages/toto`.
>- S’assurer que les logs montrent bien un problème de connexion à Redis (et non une erreur de syntaxe).

Cette première étape de test n’est que le commencement, mais pour être encore plus confiant dans notre application, il serait bien de pouvoir tester localement notre application dans un contexte avec Redis et sa sentinelle. Pour ce faire, nous allons profiter de `docker compose`, qui vous permettra de reproduire la topologie quasiment similaire à ce que vous aurez sur Kubernetes.

Dans le même répertoire que votre application, créons un fichier `sentinel.conf` avec le contenu suivant :

```ini
# kubernetes-app/sentinel.conf
port 26379
dir "/tmp"
sentinel myid 4e0a5d1ce15dd3b5ef9a9e7d190d4f8d2e7b120a
sentinel deny-scripts-reconfig yes
sentinel monitor mymaster master 6379 1
sentinel config-epoch mymaster 0
maxclients 4064
sentinel leader-epoch mymaster 0
sentinel current-epoch 0
SENTINEL resolve-hostnames yes
```

De son côté, le fichier `docker-compose.yml` doit être adapté pour contenir les lignes suivantes :
```yaml
# kubernetes-app/docker-compose.yml
---
version: '3'
services:
  app:
    build: .
    image: "$REGISTRY_URL/$TRG/app:v0.7"
    ports:
    - "8000:8000"
    volumes:
    - "./log-config.ini:/etc/config/log-config.ini"
    environment:                                     # <== Ajout
    - REDIS_SENTINEL_SERVICE=sentinel                # <== Ajout
  master:                                            # <== Ajout
    image: redis                                     # <== Ajout
  sentinel:                                          # <== Ajout
    image: redis                                     # <== Ajout
    volumes:                                         # <== Ajout
    - ./sentinel.conf:/etc/sentinel.conf             # <== Ajout
    command: redis-sentinel /etc/sentinel.conf       # <== Ajout
    ports:                                           # <== Ajout
    - "26379:26379"                                  # <== Ajout
```

Lancez la commande `docker compose up` et admirez votre cluster redis-sentinel local.

À partir de maintenant, l’invocation d'un `GET /ready` ne doit plus retourner d’erreur.

Vous pouvez désormais développer ou tester localement votre application avec un environnement complet, avant de la packager et la publier de nouveau. Il n’est pas nécessaire ici de packager la partie Redis, car elle sera déployée dans le cluster Kubernetes par un autre mécanisme...
## 4- Redéploiement de l’application

> **Exercice**
>
> Publier l’image **v0.7** sur la registry

Pour mettre en musique notre application, nous allons la redéployer en opérant les modifications suivantes sur le ***deployment*** :
- Passer à la version **v0.7**
- Ajouter une variable d’environnement dans la définition du conteneur de notre ***deploiement*** `REDIS_SENTINEL_SERVICE=rfs-redisfailover`
- Changer la ***readinessProbe*** pour utiliser `/ready`

> **Exercice**
>
> Adapter le deployment en conséquence par le moyen de votre choix (`kubectl apply`)

> **Questions**
>- Que se passe-t-il pour votre application ?
>- Est-elle disponible ?
>- Pourquoi ?
>- À quoi correspond la variable d’environnement `REDIS_SENTINEL_SERVICE` ?


## 5- Déploiement du cluster Redis

Pour se sortir de cette situation dramatique, il va être nécessaire de jouer avec des ***crd***. Pour regarder celles qui sont déjà présentes, lancer la commande :
```sh
dev $ kubectl get crd
```
> **Questions**
>- Combien de ***crd*** ont été gentiment installées par vos formateurs ?
>- Dans quel ***namespace*** sont-elles déployées ?
>- Savez-vous à quoi elles servent ?

Nous allons à présent soumettre la création d’un cluster Redis en utilisant une ***crd*** en créant un fichier (nommé par exemple `redis.yaml` dans le dossier  `~/gula/deployment/`) :

```yaml
# deployment/redis.yaml
---
apiVersion: databases.spotahome.com/v1
kind: RedisFailover
metadata:
  name: redisfailover
spec:
  redis:
    storage:
      persistentVolumeClaim:
        metadata:
          name: redisfailover-persistant-data
        spec:
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
```

> **Exercices**
>
>- Créer un cluster Redis dans le ***namespace*** de travail en soumettant le fichier YAML ci-dessus.
>- Attendre quelques minutes que tous les ***pods*** soient créés.

> **Questions**
>- Pouvez-vous lister tous les ***pods*** et ***services*** créés par la ***crd*** ?
>- Repérer les générateurs de ces ***pods*** (quelles ressources de plus haut niveau les ont générés ?)
>- Sur quels ***pods*** pointe le ***service*** créé ?
>- Pouvez-vous faire une cartographie de tous les objets créés pour implémenter ce cluster Redis ?


## 6- Validation de l’application
Si vous avez survécu jusque là, bravo, il vous reste quelques petits `cURL` à lancer pour valider que tout est en ordre :

```sh
$  curl -v -X PUT -H 'Content-Type: application/json' http://kubernetes-app-gula.52.47.206.36.ip.aws.octo.training/messages/plop -d '{"data": "Hello world"}'

$  curl -v http://kubernetes-app-gula.52.47.206.36.ip.aws.octo.training/messages/plop

$  curl -v -X DELETE http://kubernetes-app-gula.52.47.206.36.ip.aws.octo.training/messages/plop
```

N’hésitez pas à faire des variantes de ces commandes pour provoquer des erreurs 404 (clé non trouvée) sur les `GET` et les `DELETE`. La lecture du code peut vous faire penser à d’autres erreurs possibles sur l’opération de `PUT` :
- Mauvais `Content-Type`,
- Parsing JSON invalide sur le body de la requête.

## 7- Conclusion
Bravo, vous savez maintenant presque tout sur l’utilisation de Kubernetes !!
