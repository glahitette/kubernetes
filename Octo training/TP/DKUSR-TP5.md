# Docker / Kubernetes - TP5 : Configuration avancée et exposition des pods
> **Objectifs du TP** :
>- Créer et manipuler des ***configmap***
>- Créer des ressources directement via des fichiers YAML
>- Appréhender le concept de ***LivenessProbe*** et ***ReadinessProbe***
>- Exposer des applications via des **`Ingresses`**
>
> **Niveau de difficulté** : Intermédiaire

## 1- Introduction

Lors du précédent TP, nous avons vu comment déployer basiquement notre application depuis une registry privée. Nous allons à présent voir comment rendre notre application plus dynamique grâce aux ***configmaps*** et les bonnes pratiques permettant de savoir si notre application est saine grâce aux sondes (***Liveness*** et ***Readiness Probes***).

## 2- Configuration du pod grâce à une ConfigMap

Les ***configmaps*** permettent de grouper les configurations consommables par les ***pods***.
Notre objectif va être de faire en sorte que notre application liste le contenu du fichier `/etc/config/message` et l’affiche quand elle est interrogée sur l’URL `/config`.

Nous allons donc ajouter cette configuration à notre conteneur et modifier notre application en conséquence.

`kubectl` permet de générer des ***configmaps*** directement à partir de fichier de configuration. C’est ce que nous allons faire ici.

Commençons par créer le fichier (dans  `~/gula/deployment/`) :
```sh
dev $ echo -n "Hello from ConfigMap" > message
```
Créons maintenant la ***configmap*** :
```sh
dev $ kubectl create configmap myapp-config --from-file=message
configmap "myapp-config" created
```
Vérifions :
```sh
dev $ kubectl describe configmap myapp-config
Name:         myapp-config
Namespace:    gula
Labels:       <none>
Annotations:  <none>

Data
====
message:
----
Hello From ConfigMap
Events:  <none>
```

Notre configuration est maintenant disponible. Il faut que nous mettions à jour notre application pour qu’elle réponde lors de l’appel sur l’URL `/config` un fichier.

Ouvrez le fichier `app.py` et modifiez-le afin de faire en sorte que l’application écoute la route `/config` :

```py
# kubernetes-app/app.py
from flask import Flask
from http import HTTPStatus
from werkzeug.exceptions import HTTPException

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello Kubernetes!\n"

@app.route("/config")                           # <== Ajout
def config():                                   # <== Ajout
    with open('/etc/config/message','r') as f:  # <== Ajout
        return f.read()                         # <== Ajout

@app.errorhandler(HTTPException)
def handle_http_exception(exception: HTTPException):
    return exception.description, exception.code

@app.errorhandler(Exception)
def handle_exception(exception: Exception):
    return HTTPStatus.INTERNAL_SERVER_ERROR.description, HTTPStatus.INTERNAL_SERVER_ERROR
```

Ceci fait, nous allons devoir créer une nouvelle version de notre image docker et la pousser dans la registry. Il est temps de modifier notre `docker-compose.yml` pour préparer ces deux opérations :

```yaml
# kubernetes-app/docker-compose.yml
---
version: '3'
services:
  app:
    build: .
    image: "$REGISTRY_URL/$TRG/app:v0.2" # <== Mise à jour de la version
    ports:
    - "8000:8000"
```

Nous pouvons à présent lancer les commandes de reconstruction et de publication de la nouvelle image :
```sh
dev $ docker compose build
Building app
Sending build context to Docker daemon 22.47 MB
Step 1/10 : FROM python:3.7-alpine
 ---> 74f8760a2a8b
Step 2/10 : LABEL maintainer "<Nom> <Prénom>"
[..]
Successfully built e10b81a9ad54

dev $ docker compose push
Pushing app ($REGISTRY_URL/$TRG/app:v0.2)...
The push refers to a repository [653925650847.dkr.ecr.eu-west-1.amazonaws.com/aug/app]
c0973b845470: Layer already exists
45fcbdaa9e19: Layer already exists
18b267616b22: Layer already exists
67b9b2a215ea: Layer already exists
956940650d5d: Layer already exists
v0.2: digest: sha256:625f435d4b104f163ab68f3d0480299117452fad785400b0374a35e99dbce1a1 size: 2401
```

>>**Notez bien ces étapes** :
>>1. Adaptation de l'application
>>2. Modification du `docker-compose.yml` → pour monter la version l'image
>>3. Lancement de `docker compose build` → pour re-construire l'image
>>4. Lancement de `docker compose up` → pour tester localement l’application
>>5. Lancement de `docker compose push` → pour pousser l'image
>>
>> Vous allez être amenés à les rejouer très régulièrement dans la suite des TPs

Pour rappel, les opérations de _build_ et de _push_, ici ont été effectuées via `docker-compose`, mais si vous l’aviez souhaité, vous auriez pu obtenir les mêmes résultats avec les commandes suivantes :

```sh
dev $ docker image build -t=$REGISTRY_URL/$TRG/app:v0.2 .
dev $ docker image push $REGISTRY_URL/$TRG/app:v0.2
```

Testons maintenant une requête vers notre nouvelle route :
```sh
dev $ curl <IP_UN_DES_NOEUDS>:<NODEPORT>/config
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server.  If you entered the URL manually please check your spelling and try again.</p>
```

Pour l’instant, pas de résultat probant, mais c’est normal. Il est nécessaire de faire plusieurs opérations :
- Préciser qu’à présent nous allons utiliser la version **v0.2** de l’image
- Exposer la ***configmap*** dans notre ***pod***.

La modification à apporter dans le fichier du ***deployment*** est la suivante :

```yaml
# deployment/deployment-kubernetes-app.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubernetes-app
  labels:
    app: kubernetes-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubernetes-app
  template:
    metadata:
      labels:
        app: kubernetes-app
    spec:
      volumes:                              # <== Ajout
      - name: config-volume                 # <== Ajout
        configMap:                          # <== Ajout
          name: myapp-config                # <== Ajout
      containers:
      - name: kubernetes-app
        image: 261407191094.dkr.ecr.eu-west-3.amazonaws.com/gula/app:v0.2  # <== Modif version
        ports:
        - containerPort: 8000
          name: http
        volumeMounts:                       # <== Ajout
        - name: config-volume               # <== Ajout
          mountPath: /etc/config            # <== Ajout
      imagePullSecrets:
      - name: regsec
```

Notons de l’exposition de la ***configmap*** implique 2 nouveaux blocs de configuration :
- Un nouveau Volume qui se base sur la ***configmap*** créée précédemment
- Un point de montage au niveau de notre conteneur qui réutilise le volume initialisé et qui le monte sur le _mountPath_

Appliquons notre modification :

```sh
dev $ kubectl apply -f deployment-kubernetes-app.yaml
```

La nouvelle configuration va automatiquement déployer un nouveau ***pod*** prenant en compte la nouvelle configuration.

> **Exercice**
>
> À l’aide de `kubectl describe pod`, observez la nouvelle configuration.

Testons maintenant cette nouvelle configuration en faisant de nouveau un curl vers l’ip de notre service :
```sh
dev $ curl <IP_UN_DES_NŒUDS>:<NODEPORT>/config
Hello from ConfigMap
```
YAY !

## 3- LivenessProbe et ReadinessProbe

Ce mécanisme de _HealthCheck_ permet au système d'interroger une URL donnée de notre ***pod*** afin d’en déterminer l’état de santé et de le redémarrer le cas échéant.

Mettons à jour notre ***deployment*** :

```yaml
# deployment/deployment-kubernetes-app.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubernetes-app
  labels:
    app: kubernetes-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubernetes-app
  template:
    metadata:
      labels:
        app: kubernetes-app
    spec:
      volumes:
      - name: config-volume
        configMap:
          name: myapp-config
      containers:
      - name: kubernetes-app
        image: 261407191094.dkr.ecr.eu-west-3.amazonaws.com/gula/app:v0.2
        ports:
        - containerPort: 8000
          name: http
        livenessProbe:            # <== Ajout
          httpGet:                # <== Ajout
            path: /healthz        # <== Ajout
            port: 8000            # <== Ajout
          initialDelaySeconds: 3  # <== Ajout
          periodSeconds: 5        # <== Ajout
        readinessProbe:           # <== Ajout
          httpGet:                # <== Ajout
            path: /healthz        # <== Ajout
            port: 8000            # <== Ajout
          initialDelaySeconds: 3  # <== Ajout
          periodSeconds: 5        # <== Ajout
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      imagePullSecrets:
      - name: regsec
```

Appliquons notre modification :

```sh
dev $ kubectl apply -f deployment-kubernetes-app.yaml
```

Observons le résultat sur notre pod :

```sh
dev $ kubectl get po
NAME                                         READY     STATUS             RESTARTS   AGE
kubernetes-app-deployment-76dcfbd644-dhpcz   1/1       Running            0          51m
kubernetes-app-deployment-78cc7765c6-w29t8   0/1       CrashLoopBackOff   3          57s
```

Nous constatons ici que notre nouveau ***pod*** est dans l’état _CrashLoopBackOff_. Cela signifie que le système ne peut pas garantir la stabilité du conteneur au vu des URLs de _healthcheck_. Le ***pod*** redémarre sans cesse. Le ***deployment*** refuse de terminer le _rolling-update_ car il n’arrive pas à garantir la stabilité du nouveau ***pod***.

> **Question**
>
> Quelles sont les 2 types de ressources Kubernetes qui permettent de montrer cette situation ?
>
> _(Vérifiez avec `kubectl describe`)_

Notre application doit-être mise à jour pour pouvoir répondre sur la route `/healthz`, et renvoyer un code de retour HTTP entre 200 et 400.

```py
# kubernetes-app/app.py
from flask import Flask
from http import HTTPStatus
from werkzeug.exceptions import HTTPException

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello Kubernetes!\n"

@app.route("/config")
def config():
    with open('/etc/config/message','r') as f:
        return f.read()

@app.route("/healthz")      # <== Ajout
def healthz():              # <== Ajout
    return "Tutto bene !"   # <== Ajout

@app.errorhandler(HTTPException)
def handle_http_exception(exception: HTTPException):
    return exception.description, exception.code

@app.errorhandler(Exception)
def handle_exception(exception: Exception):
    return HTTPStatus.INTERNAL_SERVER_ERROR.description, HTTPStatus.INTERNAL_SERVER_ERROR
```

> **Exercices**
>- Notre application mise à jour, repackagez-la dans une nouvelle image Docker en version **v0.3** puis poussez-la sur la registry.
>- Le ***deployment*** doit également être mis à jour afin de récupérer la dernière version de notre application. Mettez-le à jour et appliquez la nouvelle version.

Félicitations, votre application est de nouveau up and running !

## 4- Exposition d’un service derrière une URL publique

Notre application est de plus en plus complète. On aimerait cependant pouvoir y accéder via une adresse ip publique. Pour y arriver, il nous faudra manipuler une nouvelle ressource nommée ***ingress***.

Exposons notre application kubernetes-application derrière une ***ingress*** pour pouvoir l’atteindre depuis Internet. Créons donc le fichier `ing.yaml` :

```yaml
# deployment/ing.yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubernetes-app
  labels:
    app: kubernetes-app
spec:
  rules:
  - host: kubernetes-app-gula.52.47.206.36.ip.aws.octo.training
    http:
      paths:
      - path: /
        backend:
          serviceName: kubernetes-app
          servicePort: 8000
```

> **Exercices**
>
>- Créer l’***ingress*** (avec `kubectl apply`)
>- Vérifier son fonctionnement en tapant l’adresse publique dans un autre onglet du navigateur : http://kubernetes-app-gula.52.47.206.36.ip.aws.octo.training

## 5- Conclusion

Bravo, votre application est désormais accessible depuis une adresse publique. Elle possède une configuration dynamique et son bon fonctionnement est surveillé par les ***liveness*** et ***readiness probes***.
