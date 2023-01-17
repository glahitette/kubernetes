# kubernetes cheat sheet

## Linux

- In vi / vim, to indent multiple lines:
  - set the shiftwidth using :set shiftwidth=2
  - mark multiple lines using **Shift v** and the up/down keys
  - press `>` or `<`
  - repeat / cancel the action using `.` / `u`
- Use `grep -A2 Mounts` to show two lines after the line matching `Mounts`

## Setup

```
export do='--dry-run=client -o yaml'
export now='--force --grace-period 0
```

## Intro

- Check all resources at once: `k get all [-A]`
- Select the acgk8s cluster to interact: `k config use-context acgk8s`
- API e.g. for pod manifests : `k explain pods[.child1.child2] | more` OR https://kubernetes.io/docs/reference/kubernetes-api/

## Create resources

- Create a secret (with implicit base64 encoding): `k -n moon create secret generic secret1 --from-literal user=test --from-literal pass=pwd`
- Create an NGINX pod with `k [-n <my_namespace>] run pod1 --image=nginx:alpine [’--labels app=my_app]`
- Create a temporary NGINX pod named tmp to check a service connection
```
k run tmp --restart=Never --rm --image=nginx:alpine -i -- curl http://project-plt-6cc-svc.pluto:3333
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0  32210      0 --:--:-- --:--:-- --:--:-- 32210
...
<title>Welcome to nginx!</title>
```
- Create a busybox pod with `k [-n <my_namespace>] run pod6 --image=busybox:1.31.0 $do --command -- sh -c "touch /tmp/ready && sleep 1d" > 6.yaml`
- Create a pod YAML file with a volume backed by a config map, per https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap, then check the output of a key from the mounted volume
```
k create -f https://kubernetes.io/examples/pods/pod-configmap-volume.yaml $do > pod.yml
k exec chewie -n yoda -- cat /etc/starwars/planet
```

- Create a job with `k -n neptune create job neb-new-job --image=busybox:1.31.0 $do > /opt/course/3/job.yaml -- sh -c "sleep 2 && echo done"`
  - Namespace goes before the `create` keyword; command goes at the end 
- Remember there is no such thing as starting a Job or CronJob! Check the pod execution...
- Create an nginx deployment: `k create deployment sunny --image=nginx:stable $do > sunny_deployment.yml` (deployment name is used as prefix for pods' name)
- Create a Service...
  - ...to expose a given pod `k -n pluto expose pod project-plt-6cc-api --name project-plt-6cc-svc --port 3333 --target-port 80`
    - `expose` will create everything needed...much faster than creating a service and editing it to set the correct selector labels 
      - `k -n pluto create service clusterip project-plt-6cc-svc --tcp 3333:80 $do`
  - ...for an nginx deployment, which serves on port 80 and connects to the containers on port 8000: `k expose deployment nginx --port=80 --target-port=8000 [--type ClusterIp|NodePort|...] $do`

## Update resources

- Add / remove a label: `k label pods my-pod new-label=awesome` / `k label pods my-pod new-label-`
- Perform a rolling update to change the image used in the fish Deployment to nginx:1.21.5 (2 options):
```
k edit deployment fish
k set image deployment/fish nginx=nginx:1.21.5
```
- Check rollout status: `k rollout status deployment/rolling-deployment`
- Roll back to the previous version: `k rollout undo deployment/rolling-deployment`

## Delete / replace resources
- Force replace, delete and then re-create the resource: `k replace --force -f ./pod.json`
- Delete a pod (with the `--force` flag) to apply a change: `k delete pod broken-pod --force`
- Delete pods and services with label name=myLabel: `k delete pods,services -l name=myLabel`

## Execute commands

- Create a one-shot pod: `k run --image busybox --restart=Never -ti busybox --rm`
- Execute commands on a running pod:
  - `k -n moon exec secret-handler -- env | grep SECRET1`
  - `k -n moon exec secret-handler -- cat /tmp/secret2/key`
- Connect to an existing pod in interactive mode: `k exec <podName> -i sh`

## Debugging

- Use `k get pods [-A] [--show-labels]` to check the `STATUS` of all Pods in a Namespace, but also their `READY` and `RESTARTS` attributes.
- Use `k get pod <pod_name> -o json | jq .status.phase` to get the status of a given pod
- Use `k describe <resource_name>` to get detailed information about Kubernetes objects, including events.
- Use `k logs <pod_name> [-c <container_name>]` to retrieve pod / container logs.
- List events for a given namespace / all namespaces: `k get events -n <my-namespace>` / `k get events -A` 
- Show metrics for pods / pod / nodes: `k top pods` / `k top pod --selector=XXXX=YYYY` / `k top node`
- Repeat command every n seconds, example: `watch -n 2 kubectl get pods`
- Check cluster-level logs if you still cannot locate any relevant information.
  - Check the kube-apiserver logs, e.g.
    `sudo tail -100f /var/log/containers/kube-apiserver-k8s-control_kube-system_kube-apiserver-<hash>.log`
  - Check the kubelet status / logs: `sudo systemctl status kubelet` / `sudo journalctl -fu kubelet`
- More troubleshooting tips...
  - for pods at https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
  - for applications at https://kubernetes.io/docs/tasks/debug/debug-application/
  - for clusters at https://kubernetes.io/docs/tasks/debug/debug-cluster/

## YAML templates

- Search YAML templates
  - in documentation web pages with `kind: <resource_name>`
  - on disk with `grep -r <search> [directory]`
- Pod: [Tasks](https://kubernetes.io/docs/tasks/) > [Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/), copy file URL then `wget <file_url>`and modify... 
- Deployment
- ConfiMap
- Secret
- Service

## Secrets for ServiceAccount

- If a Secret belongs to a ServiceAccount, it'll have the annotation `kubernetes.io/service-account.name`
- To show the base64 encoded token:

```
k -n neptune get secret neptune-secret-1 -o yaml
apiVersion: v1
data: ...
token: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNkltNWFaRmRxWkRKMmFHTnZRM0JxV0haT1IxZzFiM3BJY201SlowaEhOV3hUWmt3elFuRmFhVEZhZDJNaWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUp1WlhCMGRXNWxJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5elpXTnlaWFF1Ym1GdFpTSTZJbTVsY0hSMWJtVXRjMkV0ZGpJdGRHOXJaVzR0Wm5FNU1tb2lMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2libVZ3ZEhWdVpTMXpZUzEyTWlJc0ltdDFZbVZ5Ym1WMFpYTXVhVzh2YzJWeWRtbGpaV0ZqWTI5MWJuUXZjMlZ5ZG1salpTMWhZMk52ZFc1MExuVnBaQ0k2SWpZMlltUmpOak0yTFRKbFl6TXROREpoWkMwNE9HRTFMV0ZoWXpGbFpqWmxPVFpsTlNJc0luTjFZaUk2SW5ONWMzUmxiVHB6WlhKMmFXTmxZV05qYjNWdWREcHVaWEIwZFc1bE9tNWxjSFIxYm1VdGMyRXRkaklpZlEuVllnYm9NNENUZDBwZENKNzh3alV3bXRhbGgtMnZzS2pBTnlQc2gtNmd1RXdPdFdFcTVGYnc1WkhQdHZBZHJMbFB6cE9IRWJBZTRlVU05NUJSR1diWUlkd2p1Tjk1SjBENFJORmtWVXQ0OHR3b2FrUlY3aC1hUHV3c1FYSGhaWnp5NHlpbUZIRzlVZm1zazVZcjRSVmNHNm4xMzd5LUZIMDhLOHpaaklQQXNLRHFOQlF0eGctbFp2d1ZNaTZ2aUlocnJ6QVFzME1CT1Y4Mk9KWUd5Mm8tV1FWYzBVVWFuQ2Y5NFkzZ1QwWVRpcVF2Y3pZTXM2bno5dXQtWGd3aXRyQlk2VGo5QmdQcHJBOWtfajVxRXhfTFVVWlVwUEFpRU43T3pka0pzSThjdHRoMTBseXBJMUFlRnI0M3Q2QUx5clFvQk0zOWFiRGZxM0Zrc1Itb2NfV013
kind: Secret ...
```
 
- To get the base64 decoded token, one we could pipe it manually through `echo <token> | base64 -d -` or we simply do:
```
k -n neptune describe secret neptune-secret-1
Data
====
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6Im5aZFdqZDJ2aGNvQ3BqWHZOR1g1b3pIcm5JZ0hHNWxTZkwzQnFaaTFad2MifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJuZXB0dW5lIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Im5lcHR1bmUtc2EtdjItdG9rZW4tZnE5MmoiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoibmVwdHVuZS1zYS12MiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjY2YmRjNjM2LTJlYzMtNDJhZC04OGE1LWFhYzFlZjZlOTZlNSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpuZXB0dW5lOm5lcHR1bmUtc2EtdjIifQ.VYgboM4CTd0pdCJ78wjUwmtalh-2vsKjANyPsh-6guEwOtWEq5Fbw5ZHPtvAdrLlPzpOHEbAe4eUM95BRGWbYIdwjuN95J0D4RNFkVUt48twoakRV7h-aPuwsQXHhZZzy4yimFHG9Ufmsk5Yr4RVcG6n137y-FH08K8zZjIPAsKDqNBQtxg-lZvwVMi6viIhrrzAQs0MBOV82OJYGy2o-WQVc0UUanCf94Y3gT0YTiqQvczYMs6nz9ut-XgwitrBY6Tj9BgPprA9k_j5qEx_LUUZUpPAiEN7OzdkJsI8ctth10lypI1AeFr43t6ALyrQoBM39abDfq3FksR-oc_WMw
ca.crt:     ...
```

## Helm

- List release with `helm [-n my_namespace] ls [-a]`, example:
```
➜ helm -n mercury ls -a
NAME                            NAMESPACE     STATUS          CHART           APP VERSION
internal-issue-report-apache    mercury       deployed        apache-8.6.3    2.4.48     
internal-issue-report-apiv2     mercury       deployed        nginx-9.5.2     1.21.1     
internal-issue-report-app       mercury       deployed        nginx-9.5.0     1.21.1     
internal-issue-report-daniel    mercury       pending-install nginx-9.5.0     1.21.1 
```

- Delete an installed release with `helm [-n my_namespace] uninstall <release_name>`
- List / search repo:
```
helm repo list
NAME    URL                               
bitnami https://charts.bitnami.com/bitnami

helm search repo nginx
NAME                  CHART VERSION   APP VERSION     DESCRIPTION          
bitnami/nginx         9.5.2           1.21.1          Chart for the nginx server             ...
```
- Upgrade a release, example `helm -n mercury upgrade internal-issue-report-apiv2 bitnami/nginx`

- `helm rollback` for undoing a helm rollout/upgrade
- Check customisable values setting for an install, e.g. `helm show values bitnami/apache [| yq e]`
- Custom install example `helm -n mercury install internal-issue-report-apache bitnami/apache --set replicaCount=2`

## References
- https://kubernetes.io/docs/reference/k/cheatsheet/
- https://github.com/dennyzhang/cheatsheet-kubernetes-A4
- https://codefresh.io/blog/kubernetes-cheat-sheet/
- https://intellipaat.com/blog/tutorial/devops-tutorial/kubernetes-cheat-sheet/