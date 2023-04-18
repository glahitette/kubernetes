<!-- TOC -->
    * [References:](#references)
    * [ArgoCD](#argocd)
    * [ArgoCD CLI](#argocd-cli)
    * [Managing secrets in GitOps](#managing-secrets-in-gitops)
    * [App of Apps pattern](#app-of-apps-pattern)
    * [Argo Rollouts](#argo-rollouts)
    * [External cluster](#external-cluster)
    * [ApplicationSets](#applicationsets)
<!-- TOC -->

### References:
- GitOps Fundamentals: [course]|(https://learning.codefresh.io/course/gitops-fundamentals), https://github.com/glahitette/gitops-certification-examples (forked from https://github.com/codefresh-contrib/gitops-certification-examples) 
- GitOps At Scale: [course]|(https://learning.codefresh.io/course/gitops-scale), https://github.com/glahitette/gitops-cert-level-2-examples/ (forked from https://github.com/codefresh-contrib/gitops-cert-level-2-examples)

### ArgoCD

- Install (no-auth): `k create ns argocd && k apply -n argocd -f https://raw.githubusercontent.com/codefresh-contrib/gitops-certification-examples/main/argocd-noauth/install.yaml`
- Application health: “Healthy” -> 100% healthy; “Progressing” -> not healthy but still has a chance to reach healthy state; “Suspended” -> suspended or paused (e.g. cron job); “Missing” -> not present in the cluster; “Degraded” -> indicates failure or resource could not reach healthy state in time; “Unknown” -> Health assessment failed and actual health status is unknown
- Argo CD health checks are completely independent from Kubernetes health probes
- Sync strategy:
  - Manual
  - Automatic sync
    - Auto-pruning: controls what Argo CD does when you remove/delete files from Git: delete if enabled, never delete if disabled (default) 
    - Self-Heal: controls how Argo CD handles manual changes on cluster: discard changes (= align with git) if enabled

### ArgoCD CLI
- Install: `curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.1.5/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd`
- Login: `argocd login [localhost:30443 | kubernetes-vm:30443] [--insecure] --username admin --password <...>`
- Create application to `default` project, `default` namespace and manual (none) sync policy:
```
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook \
--dest-namespace default --dest-server https://kubernetes.default.svc
```
- Create application from a Helm chart, to `helm-ns` namespace (will be created if missing) with auto sync policy, auto prune and self healing:
```
argocd app create helm-guestbook --dest-namespace helm-ns --dest-server https://kubernetes.default.svc \
--repo https://github.com/argoproj/argocd-example-apps.git \
--path helm-guestbook --helm-set replicaCount=2
--sync-option Prune=true,CreateNamespace=True --self-heal
```
  - Important note: Argo CD can deploy applications from Helm charts and monitor them for new versions / sync'ing. But the application is recognized as an Argo app, rendered with the Helm template, that can only be operated by Argo CD, and no longer a Helm application (`helmp list` returns empty).
- List apps / sync app | get app details | get app history | delete app: `argocd app list`, `argocd app [sync | get | history | delete] demo`

### Managing secrets in GitOps
- Kubernetes secrets are not encrypted / base64 encoding used should be never seen as a security feature!!!
- Install [Bitnami Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)... in the `kube-system` namespace, as ArgoCD application...:
```
argocd app create bitnami-sealed-controller --sync-policy auto --dest-namespace kube-system --dest-server https://kubernetes.default.svc \
--repo https://github.com/codefresh-contrib/gitops-certification-examples \
--path ./bitnami-sealed-controller
```
- ...or with Helm (for reference):
```
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets-controller sealed-secrets/sealed-secrets
```
- Once installed, the Bitnami Sealed Secrets controller creates two keys on its own:
  - The public key for secret encryption, which will be used outside the cluster (ok to share).
  - The private key for secret decryption, which should stay within the cluster, and never be shared.
- [Process](https://learning.codefresh.io/path-player?courseid=gitops-fundamentals&unit=gitops-fundamentals_63a080ca69969Unit):
  - Create a plain Kubernetes secret locally: never commit it anywhere.
  - Use kubeseal to encrypt the secret in a SealedSecret: `kubeseal < db-creds.yml > db-creds-encrypted.yaml -o yaml`
    - Sealed secrets are cluster and namespace specific! To use the same secret for different clusters, it must be encrypted for each cluster individually.
  - Delete the original secret from your workstation and apply the sealed secret to the cluster: `k [-n my-ns] apply -f db-creds-encrypted.yaml`
  - Commit the Sealed secret to Git.
  - Deploy your application that expects normal Kubernetes secrets to function.
  - The Bitnami Sealed Secrets controller decrypts the Sealed secrets and passes them to your application as plain secrets.

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