# kubernetes cheat sheet

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

- Create an NGINX pod with `k run pod1 --image=nginx:stable [-n <my_namespace>]`
- Create a pod YAML file with a volume backed by a config map, per https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap, then check the output of a key from the mounted volume
```
k create -f https://kubernetes.io/examples/pods/pod-configmap-volume.yaml $do > pod.yml
k exec chewie -n yoda -- cat /etc/starwars/planet
```

- Create a job with `k -n neptune create job neb-new-job --image=busybox:1.31.0 $do > /opt/course/3/job.yaml -- sh -c "sleep 2 && echo done"`
  - Namespace goes before the `create` keyword; command goes at the end 
- Remember there is no such thing as starting a Job or CronJob! Check the pod execution...
- Create an nginx deployment YAML file: `k create deployment sunny --image=nginx:stable $do > sunny_deployment.yml`

- Create a Service: `k expose deployment <deploymentName> --port=<service-port> --target-port=<target-port> [--type ClusterIp|NodePort|...] [--dry-run=client -o yaml]`

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

## Debugging

- Use `k get pods [-A] [--show-labels]` to check the `STATUS` of all Pods in a Namespace, but also their `READY` and `RESTARTS` attributes.
- Use `k get pod <pod_name> -o json | jq .status.phase` to get the status of a given pod
- Use `k describe <resource_name>` to get detailed information about Kubernetes objects, including events.
- Use `k logs <pod_name> [-c <container_name>]` to retrieve pod / container logs.
- List events for a given namespace / all namespaces: `k get events -n <my-namespace>` / `k get events -A` 
- Show metrics for pods / pod / nodes: `k top pods` / `k top pod --selector=XXXX=YYYY` / `k top node`
- Create a one-shot pod: `k run --image busybox --restart=Never -ti busybox --rm`
- Connect to an existing pod: `k exec <podName> -ti sh`
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