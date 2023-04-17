<!-- TOC -->
    * [ArgoCD](#argocd)
    * [App of Apps pattern](#app-of-apps-pattern)
    * [Argo Rollouts](#argo-rollouts)
    * [External cluster](#external-cluster)
    * [ApplicationSets](#applicationsets)
<!-- TOC -->

### ArgoCD

- Create application to `default` project, `default` namespace and manual (none) sync policy, then sync it:
```
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook \
--dest-namespace default --dest-server https://kubernetes.default.svc
argocd app sync guestbook
```
- Create application to `default` project, `default` namespace with auto sync policy, auto prune and self healing:
```
argocd app create demo --sync-policy auto --dest-namespace default --dest-server https://kubernetes.default.svc \
--repo https://github.com/glahitette/gitops-certification-examples \
--path helm-app \
--sync-option Prune=true --self-heal
```
- Create a Helm application to `default` namespace
```
argocd app create helm-guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path helm-guestbook --dest-namespace default \
--dest-server https://kubernetes.default.svc --helm-set replicaCount=2
```

### App of Apps pattern

- From a directory structure, your Git repository might look something like this:
```
My Apps
├── my-projects
│   ├── my-project.yml
├── my-apps
│   ├── child-app-1.yml
│   ├── child-app-2.yml
│   ├── child-app-3.yml
│   ├── child-app-4.yml
├── root-app
└───├── parent-app.yml
```
- The root app definition would look something like this:
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
name: root-app
namespace: argocd
spec:
destination:
namespace: my-app
server: https://kubernetes.default.svc
project: my-project
source:
path: my-apps
repoURL: https://github.com/hseligson1/app-of-apps
targetRevision: HEAD
```
- The my-apps directory contains the application for each child app. Within that manifest, your file might look something like this:
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
name: child-app-1
namespace: argocd
spec:
destination:
namespace: my-app
server: https://kubernetes.default.svc
project: my-project
source:
path: guestbook
repoURL: https://github.com/argoproj/argocd-example-apps.git
targetRevision: HEAD
syncPolicy:
syncOptions:
- CreateNamespace=true
automated:
selfHeal: true
prune: true
```

- def
```
```

### Argo Rollouts

- abc
- def
```
```

### External cluster

- abc
- def
```
```

### ApplicationSets

- abc
- def
```
```