# kubernetes cheat sheet

## Intro

- Check all resources at once: `k get all [-A]`
- Select the acgk8s cluster to interact: `k config use-context acgk8s`
- API e.g. for pod manifests : `k explain pods[.child1.child2] | more` OR https://kubernetes.io/docs/reference/kubernetes-api/

## Create resources

- Create a pod YAML file with a volume backed by a config map, per https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap, then check the output of a key from the mounted volume
```
export do='--dry-run=client -o yaml'
k create -f https://kubernetes.io/examples/pods/pod-configmap-volume.yaml $do > pod.yml
k exec chewie -n yoda -- cat /etc/starwars/planet
```

- Create an nginx deployment YAML file: `export do='--dry-run=client -o yaml' && k create deployment sunny --image=nginx:stable $do > sunny_deployment.yml`

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

- Search YAML templates in documentation pages with `kind: <resource_name>`
- Pod
- Deployment
- ConfiMap
- Secret
- Service

## References
- https://kubernetes.io/docs/reference/k/cheatsheet/
- https://github.com/dennyzhang/cheatsheet-kubernetes-A4
- https://codefresh.io/blog/kubernetes-cheat-sheet/
- https://intellipaat.com/blog/tutorial/devops-tutorial/kubernetes-cheat-sheet/