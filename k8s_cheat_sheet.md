<!-- TOC -->
    * [General](#general)
    * [Create resources](#create-resources)
    * [Update resources](#update-resources)
    * [Execute commands](#execute-commands)
    * [Debugging](#debugging)
    * [Delete / replace resources](#delete--replace-resources)
    * [Secrets for ServiceAccount](#secrets-for-serviceaccount)
    * [NetworkPolicy](#networkpolicy)
    * [Helm](#helm)
<!-- TOC -->

### General
- Use `grep -A2 Mounts` to show two lines after the line matching `Mounts`
- Repeat command every n seconds, example: `watch -n 2 kubectl get pods`
- Check all resources at once: `k get all [-A]`
- Select the acgk8s cluster to interact: `k config use-context acgk8s`
- API e.g. for pod manifests : `k explain pods[.child1.child2] | more` OR https://kubernetes.io/docs/reference/kubernetes-api/

### Create resources
- Create a ConfigMap from a file, specifying the key: `k -n moon create configmap configmap-web-moon-html --from-file=index.html=/opt/course/15/web-moon.html # important to set the index.html key`
- Create a secret (with implicit base64 encoding): `k -n moon create secret generic secret1 --from-literal user=test --from-literal pass=pwd`
- Create an NGINX pod with `k [-n <my_namespace>] run pod1 --image=nginx:alpine [’--labels app=my_app]`
- Create a temporary NGINX pod named tmp to check a service connection (because the Service is in a different Namespace from the test pod, it is reachable using FQDNs):
```
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 sun-srv.sun:9999
Connecting to sun-srv.sun:9999 (10.23.253.120:9999)
<title>Welcome to nginx!</title>
```
- Create a busybox pod with `k [-n <my_namespace>] run pod6 --image=busybox:1.31.0 $do --command -- sh -c "touch /tmp/ready && sleep 1d" > 6.yaml`
- Create a pod YAML file with a volume backed by a config map, per https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap, then check the output of a key from the mounted volume
```
k create -f https://kubernetes.io/examples/pods/pod-configmap-volume.yaml $do > pod.yml
k exec chewie -n yoda -- cat /etc/starwars/planet
```
- Create a job with `k -n neptune create job neb-new-job --image=busybox:1.31.0 $do > /opt/course/3/job.yaml -- sh -c "sleep 2 && echo done"`
  - Remember there is no such thing as starting a Job or CronJob! Check the pod execution...
- Create an nginx deployment: `k create deployment sunny --image=nginx:stable $do > sunny_deployment.yml` (deployment name is used as prefix for pods' name)
- Create a Service...
  - ...to expose a given pod `k -n pluto expose pod project-plt-6cc-api --name project-plt-6cc-svc --port 3333 --target-port 80`
    - `expose` will create everything needed...much faster than creating a service and editing it to set the correct selector labels 
      - `k -n pluto create service clusterip project-plt-6cc-svc --tcp 3333:80 $do`
  - ...for an nginx deployment, which serves on port 80 and connects to the containers on port 8000: `k expose deployment nginx --port=80 --target-port=8000 [--type ClusterIp|NodePort|...] $do`
- Note: A NodePort Service kind of lies on top of a ClusterIP one, making the ClusterIP Service reachable on the Node IPs (internal and external).

### Update resources
- Add / remove a label: `k label pods my-pod new-label=awesome` / `k label pods my-pod new-label-`
- Recreate the pods in a deployment: `k -n moon rollout restart deploy web-moon`
- Perform a rolling update (e.g. to change an image): `k edit deployment fish` or `k set image deployment/fish nginx=nginx:1.21.5`
- Check rollout status: `k rollout status deployment/rolling-deployment`
- Roll back to the previous version: `k rollout undo deployment/rolling-deployment`

### Execute commands
- Create a one-shot pod: `k run --image busybox --restart=Never -ti busybox --rm`
- Execute commands on a running pod: `k -n moon exec secret-handler -- env | grep SECRET1`, `k -n moon exec secret-handler -- cat /tmp/secret2/key`
- Execute commands on a running pod in interactive mode: `k exec <podName> -i sh`

### Debugging
- Use `k get pods [-A] [--show-labels]` to check the `STATUS` of all Pods in a Namespace, but also their `READY` and `RESTARTS` attributes.
- Use `k get pod <pod_name> -o json | jq .status.phase` to get the status of a given pod
- Use `k describe <resource_name>` to get detailed information about Kubernetes objects, including events.
- Use `k logs <pod_name> [-c <container_name>]` to retrieve pod / container logs.
- List events for a given namespace / all namespaces: `k get events -n <my-namespace>` / `k get events -A` 
- Show metrics for pods / pod / nodes: `k top pods` / `k top pod --selector=XXXX=YYYY` / `k top node`
- Check cluster-level logs if you still cannot locate any relevant information.
  - Check the kube-apiserver logs, e.g.
    `sudo tail -100f /var/log/containers/kube-apiserver-k8s-control_kube-system_kube-apiserver-<hash>.log`
  - Check the kubelet status / logs: `sudo systemctl status kubelet` / `sudo journalctl -fu kubelet`
- More troubleshooting tips...
  - for pods at https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
  - for applications at https://kubernetes.io/docs/tasks/debug/debug-application/
  - for clusters at https://kubernetes.io/docs/tasks/debug/debug-cluster/

### Delete / replace resources
- Force replace, delete and then re-create the resource: `k replace --force -f ./pod.json`
- Delete pods and services with label name=myLabel: `k delete pods,services -l name=myLabel $now`

### Secrets for ServiceAccount
- If a Secret belongs to a ServiceAccount, it'll have the annotation `kubernetes.io/service-account.name`
- To get the base64 encoded token: `k -n neptune get secret neptune-secret-1 -o yaml`
- To get the base64 decoded token, pipe it manually through `echo <token> | base64 -d -` or `k -n neptune describe secret neptune-secret-1`

### NetworkPolicy
- Example of egress policy, 1) restricting outgoing tcp connections from Deployment frontend and only allows those going to Deployment api, 2) still allowing outgoing traffic on UDP/TCP ports 53 for DNS resolution.
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy <...>
spec:
  podSelector:
    matchLabels:
      id: frontend          # label of the pods this policy should be applied on
  policyTypes:
  - Egress                  # we only want to control egress
  egress:
  - to:                     # 1st egress rule
    - podSelector:            # allow egress only to pods with api label
      matchLabels:
      id: api
  - ports:                  # 2nd egress rule
    - port: 53                # allow DNS UDP
      protocol: UDP
    - port: 53                # allow DNS TCP
      protocol: TCP
```

### Helm
- List release with `helm [-n my_namespace] ls [-a]`
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
- Upgrade a release, e.g. `helm -n mercury upgrade internal-issue-report-apiv2 bitnami/nginx`
- Undo a helm rollout/upgrade: `helm rollback`
- Check customisable values setting for an install, e.g. `helm show values bitnami/apache [| yq e]`
- Custom install example `helm -n mercury install internal-issue-report-apache bitnami/apache --set replicaCount=2`

[//]: # (### Linux)
[//]: # ()
[//]: # (- In vi / vim, to indent multiple lines:)
[//]: # (  - set the shiftwidth using :set shiftwidth=2)
[//]: # (  - mark multiple lines using **Shift v** and the up/down keys)
[//]: # (  - press `>` or `<`)
[//]: # (  - repeat / cancel the action using `.` / `u`)

[//]: # (### YAML templates)
[//]: # ()
[//]: # (- Search YAML templates)
[//]: # (  - in documentation web pages with `kind: <resource_name>`)
[//]: # (  - on disk with `grep -r <search> [directory]`)
[//]: # (- Pod: [Tasks]&#40;https://kubernetes.io/docs/tasks/&#41; > [Configure Pods and Containers]&#40;https://kubernetes.io/docs/tasks/configure-pod-container/&#41;, copy file URL then `wget <file_url>`and modify... )
[//]: # (- Deployment)
[//]: # (- ConfiMap)
[//]: # (- Secret)
[//]: # (- Service)

[//]: # (### References)
[//]: # (- https://kubernetes.io/docs/reference/k/cheatsheet/)
[//]: # (- https://github.com/dennyzhang/cheatsheet-kubernetes-A4)
[//]: # (- https://codefresh.io/blog/kubernetes-cheat-sheet/)
[//]: # (- https://intellipaat.com/blog/tutorial/devops-tutorial/kubernetes-cheat-sheet/)