# Docker / Kubernetes - TP7 : Journalisation
> **Objectifs du TP** :
>- Adapter notre application pour la journalisation
>
> **Niveau de difficulté** :
> Intermédiaire

## 1- Introduction

Dans ce TP, nous allons traiter de l’épineuse question des journaux de notre application. Les formateurs ont créé l’infrastructure nécessaire à la collecte des journaux de toutes les applications.

Ils s’attendent simplement à ce que votre application envoie ces journaux au format JSON ou au format NGINX (pour les access logs).

Nous allons générer deux types de traces :
- Des **logs d’accès** à chaque fois qu’une page est demandée, au format standard NGINX
- Des **logs _ad hoc_**, que l’on imagine représentatives de l’activité fonctionnelle de notre application, au format JSON.

## 2- Ajout de dépendance et de fichiers de configuration

Pour commencer, nous allons déclarer la librairie qui nous sera utile pour formater nos logs en ajoutant une dépendance dans le fichier `requirements.txt` :
```sh
# kubernetes-app/requirements.txt
Flask==2.0.3
gunicorn==19.9.0
Jinja2==3.1.1
prometheus-client==v0.3.1
json-logging-py==0.2        # <== Ajout
```

Cette librairie nous sera utile pour configurer gunicorn, en particulier lui spécifier un format et des niveaux de logs particulier. Avant de pousser notre image, nous allons tester localement notre changement.

Nous allons par la suite créer un fichier de configuration du nom de `log-config.ini` dont le contenu sera le suivant :
```ini
; kubernetes-app/log-config.ini
[loggers]
keys=root, gunicorn.access

[handlers]
keys=console_json_stdout, console_plain_stdout

[formatters]
keys=json

[logger_root]
level=INFO
handlers=console_json_stdout

[logger_gunicorn.access]
level=INFO
handlers=console_plain_stdout
propagate=0
qualname=gunicorn.access

[handler_console_json_stdout]
class=StreamHandler
formatter=json
args=(sys.stdout, )

[handler_console_plain_stdout]
class=StreamHandler
args=(sys.stdout, )

[formatter_json]
class=jsonlogging.JSONFormatter
```

## 3- Adaptation du lancement et de la construction de l’image

Sur la ligne de démarrage de notre application, il va être nécessaire d’ajouter de nouveaux arguments.

Adaptons notre `Dockerfile` pour qu’il reflète l’ajout de ces nouveaux arguments au démarrage de l’application :

```Dockerfile
# kubernetes-app/Dockerfile
FROM python:3.7-alpine
LABEL maintainer="<Nom> <Prénom>"

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
```

Il est également nécessaire de modifier notre fichier `docker-compose.yml` pour passer en version **v0.6** et refléter le montage du nouveau fichier de configuration dans le conteneur lorsque nous allons le tester localement :
```yaml
# kubernetes-app/docker-compose.yml
---
version: '3'
services:
  app:
    build: .
    image: "$REGISTRY_URL/$TRG/app:v0.6"          # <== Mise à jour de la version
    ports:
    - "8000:8000"
    volumes:                                      # <== Ajout
    - "./log-config.ini:/etc/config/log-config.ini"  # <== Ajout
```

Ainsi, lorsque nous ferons un `docker compose up`, le fichier de configuration local sur notre machine sera monté dans le conteneur à l’endroit attendu.

Nous allons maintenant créer et test localement nos premières modifications :
```sh
dev $ docker compose build
[...]
dev $ docker compose up
Recreating kubernetes-app_app_1 ... done
Attaching to kubernetes-app_app_1
```

Si aucun message d’erreur n’apparaît, c’est déjà bon signe, il va falloir vérifier cependant que l’application trace bien les accès. Dans une seconde console, lancer un `curl` pour s’en assurer :

```sh
dev $ curl http://127.0.0.1:8000
Hello Kubernetes!
```
En rebasculant sur la fenêtre où vous avez lancé `gunicorn`, vous devriez trouver une trace de la forme suivante :
```sh
app_1 | 10.244.0.0 - - [21/Sep/2018:16:23:24 +0000] "GET / HTTP/1.1" 200 18 "-" "curl/7.47.0"
```
## 4- Adaptation et publication de l’application

Ajoutons à présent quelques lignes de logs supplémentaires dans notre application pour y insérer des traces vraiment très intéressantes :

```py
# kubernetes-app/app.py
import time

from flask import Flask
from http import HTTPStatus
from werkzeug.exceptions import HTTPException

from threading import Thread
from prometheus_client import start_http_server, Counter

app = Flask(__name__)
num_requests = Counter("num_requests", "Example counter")

def compute():
    app.logger.info("Starting CPU-consuming thread")              # <== Ajout
    timeNow = int(round(time.time()))
    timeToStop = timeNow + 200
    while timeToStop > timeNow:
        99 * 99
        timeNow = int(round(time.time()))
    app.logger.info("Ending CPU-consuming thread")                # <== Ajout

@app.route('/')
def hello():
    app.logger.info("This is a log line into the default route")  # <== Ajout
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

@app.route("/healthz")
def healthz():
    return "Tutto bene !"

@app.errorhandler(HTTPException)
def handle_http_exception(exception: HTTPException):
    app.logger.error("Raised Exception: %s" % exception)                                        # <== Ajout
    return exception.description, exception.code

@app.errorhandler(Exception)
def handle_exception(exception: Exception):
    app.logger.error("Raised Exception: %s" % exception)                                        # <== Ajout
    return HTTPStatus.INTERNAL_SERVER_ERROR.description, HTTPStatus.INTERNAL_SERVER_ERROR

start_http_server(9001)
```

> **Exercices**
>
>- Réutiliser les commandes `docker compose build` et `docker compose up` pour valider localement que les nouvelles lignes de logs produisent l’effet attendu.
>- Une fois le résultat correct obtenu, pousser l’image en **v0.6** sur la registry.

## 5- Déploiement de l’application dans K8s

Notre nouvelle image est prête, mais il nous reste une opération à faire avant de pouvoir l’utiliser dans notre cluster Kubernetes : installer le fichier de configuration des logs dans notre ***configmap*** `myapp-config` de manière à ce qu’il soit monté dans le conteneur.

**C’est à vous de jouer !!**

> **Exercices**
>
> Vous êtes maintenant livrés à vous même. Pour rappel, les opérations que vous souhaitez effectuer sont au nombre de 3 :
>- Modifier la ***configmap*** existante `myapp-config` pour lui ajouter une seconde donnée du nom de `log-config.ini` avec comme contenu le fichier éponyme
>- Modifier le ***deployment*** existant pour monter la version de l’image en **v0.6**
>- Vérifier que les nouveaux ***pods*** sont correctement instanciés et que les logs qu’ils produisent sont bien aux formats attendus (Access NGINX, JSON)

Si les choses ne se passent pas comme prévu, n’oubliez pas d’utiliser la commande `kubectl describe` pour comprendre la situation !!

> Hint : `kubectl create --save-config configmap myapp-config --from-file=message --from-file=../kubernetes-app/log-config.ini --dry-run -o yaml | kubectl apply -f -`

## 6- Admirons le résultat
Si vous êtes arrivés jusque là, bravo, il est temps de regarder le résultat dans la console Kibana. Vos formateurs vous ont installé une ***ingress*** du nom de http://kibana.52.47.206.36.ip.aws.octo.training.

Si l’index-pattern n’est pas créé, **veuillez contacter votre administrateur** ! _(Time Filter field name: @timestamp)_

N’hésitez pas à solliciter votre application au travers du service Kubernetes ou de l’ingress devant votre application !! Pour rappel, des logs seront produits à l’invocation des URLs `/` et `/slow`… `/healthz` est également invoquée régulièrement.

Utiliser les filtres de Kibana pour isoler différents types de logs :
- Voir uniquement les logs d’accès
- N’afficher que les **codes de retour** des logs d’accès
- Afficher uniquement les logs que vous avez ajoutés (**This is a log line…**)
- N’afficher que les logs du namespace où se trouve l’application

## 7- Conclusion

Nous voilà à la fin de ce TP. Encore un nouveau pas vers la production, avec des traces qui sont formatées et collectées dans un puits de logs avec finalement peu d’effort.
Notez que le paramétrage du niveau de logs est effectué au travers d’une ***configmap***, ce qui permet de changer au besoin le niveau de verbosité de tout ou partie de l’application sans devoir reconstruire le conteneur. Notez également qu’il est à tout moment possible de démarrer l’application localement (directement ou dans un conteneur construit localement) et qu’il est ainsi possible d’éviter de la déployer dans le cluster Kubernetes pour vérifier qu’elle fonctionne.
