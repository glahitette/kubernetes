<!-- TOC -->
    * [General](#general)
    * [Create pods](#create-pods)
    * [Test a pod](#test-a-pod)
    * [Create other resources](#create-other-resources)
    * [Update resources](#update-resources)
    * [Debugging](#debugging)
    * [Delete / replace resources](#delete--replace-resources)
    * [Secrets for ServiceAccount](#secrets-for-serviceaccount)
    * [NetworkPolicy](#networkpolicy)
    * [Helm](#helm)
<!-- TOC -->

### General
- Use `grep -A2 Mounts` to show two lines after the line matching `Mounts`
- Watch pods / deployments / jobs: `k get pods -w` / `k get deployments -w` / `k get jobs -w`
- Repeat command every n seconds, example: `watch -n 2 kubectl get pods`
- List of resources: `k api-resources`
- Check all resources at once: `k get all [-A]`
- List k8s "internal" pods, sorted by node name: `k get pods -n kube-system --sort-by .spec.nodeName`
- Scale a deployment and record the command (into Annotations > change-cause): `k scale deployment my-deployment replicas=5 --record`
- Select the acgk8s cluster to interact: `k config use-context acgk8s`
- API e.g. for pod manifests : `k explain pods[.child1.child2] | more` OR https://kubernetes.io/docs/reference/kubernetes-api/

### Create pods
- Create an nginx pod with `k run my-pod --image=nginx:alpine [--port=80] [’--labels app=my_app]`
- Create a busybox pod with `k run my-pod --image=busybox $do --command -- sh -c "touch /tmp/ready && sleep 1d" > pod6.yml`
- Create a pod with a volume backed by a config map: `k create -f https://kubernetes.io/examples/pods/pod-configmap-volume.yaml $do > pod.yml`
- Create a one-shot pod:
  - to test interactively: `k run my-pod --image busybox --restart=Never --rm -ti`
  - to check a service connection (because the Service is in a different Namespace from the test pod, it is reachable using FQDNs):
```
k run my-pod [--restart=Never] --rm -i --image=nginx:alpine -- curl -m 5 sun-srv.sun:9999
Connecting to sun-srv.sun:9999 (10.23.253.120:9999)
<title>Welcome to nginx!</title>
```

### Test a pod
- With a command: `k exec my-pod [-c my-container] (-- env | grep SECRET1 || -- cat /tmp/secret2/key)`
- In interactive mode: `k exec my-pod [-c my-container] -ti -- sh`

### Create other resources
- Create a job with `k create job my-job --image=busybox:1.31.0 $do > /opt/course/3/job.yaml -- sh -c "sleep 2 && echo done"` then check the pod execution (no such thing as starting a Job or CronJob!)
- Create a ConfigMap from a file, with a specific key: `k create configmap my-cm --from-file=index.html=/opt/course/15/web-moon.html`
- Create a secret (with implicit base64 encoding): `k create secret generic my-secret --from-literal user=test --from-literal pass=pwd`
- Create an nginx deployment: `k create deployment my-dep --image=nginx:stable $do > my-dep.yml` (deployment name is used as prefix for pods' name)
- Create a Service...
  - ...to expose a given pod `k expose pod my-pod --name my-svc --port 3333 --target-port 80` (much faster than creating a service and editing it to set the correct selector labels) 
  - ...for an nginx deployment, which serves on port 80 and connects to the containers on port 8000: `k expose deployment nginx --port=80 --target-port=8000 [--type ClusterIp|NodePort|...] [$do]`
- Note: A NodePort Service kind of lies on top of a ClusterIP one, making the ClusterIP Service reachable on the Node IPs (internal and external).
- Create a quota: `k create quota my-quota --hard=cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10 [$do]`
- Create Role / ClusterRole to permissions within a namespace / cluster-wide: `k create role my-role --verb=get,list,watch --resource=pods,pods/logs`
- Create RoleBinding / ClusterRoleBinding to connect Roles / ClusterRoles to subjects (users, groups or ServiceAccounts): `k create rolebinding my-rb --role=my-role --user=my-user`
- Create a service account to allow container processes within Pods to authenticate with the K8s API: `k create sa my-sa`

### Update resources
- Add / remove / change a label: `k label pods my-pod app=b` / `k label pods my-pod app-` / `k label pods my-pod app=v2 --overwrite`
- Add a new label tier=web to all pods having 'app=v2' or 'app=v1' labels: `k label po -l "app in(v1,v2)" tier=web`
- Change a pod's image (to nginx:1.7.1): `k set image my-pod nginx=nginx:1.7.1`
- Recreate the pods in a deployment: `k rollout restart deploy web-moon`
- Perform a rolling update (e.g. to change an image): `k edit deployment fish` or `k set image deployment/fish nginx=nginx:1.21.5`
- Check rollout status: `k rollout status deployment/rolling-deployment`
- Roll back to the previous version: `k rollout undo deployment/rolling-deployment`
- Autoscale a deployment, pods between 5 and 10, targetting CPU utilization at 80%: `k autoscale deploy nginx --min=5 --max=10 --cpu-percent=80`
  - View the Horizontal Pod Autoscalers (hpa): `k get hpa nginx` 

### Debugging
- Use `k get pods [-A] [--show-labels]`: check `STATUS`, `READY` and `RESTARTS` attributes.
- Retrieve a pod status: `k get pod <pod_name> -o json | jq .status.phase`
- Retrieve pod / container logs: `k logs <pod_name> [-c <container_name>] [-p]` (if pod crashed and restarted, -p option gets logs about the previous instance)
- List events for a given namespace / all namespaces: `k get events -n <my-namespace>` / `k get events -A` 
- Show metrics for pods / pod / nodes: `k top pods [--containers] [--sort-by (cpu | memory)]` / `k top pod --selector=XXXX=YYYY` / `k top node [--sort-by (cpu | memory)]`

### Delete / replace resources
- Force replace a resource: `k replace --force -f ./pod.json`
- Delete pods and services using their label: `k delete pods,services -l app=b $now`

### Secrets for ServiceAccount
- If a Secret belongs to a ServiceAccount, it'll have the annotation `kubernetes.io/service-account.name`
- Use `k get secret ...` to get a base64 encoded token 
- Use `k describe secret ...` to get a base64 decoded token...or pipe it manually through `echo <token> | base64 -d -`

### NetworkPolicy
- Example of egress policy, 1) restricting outgoing tcp connections from frontend to api, 2) still allowing outgoing traffic on UDP/TCP ports 53 for DNS resolution.
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
- List release with `helm [-n my_ns] ls [-a]`
- List pending deployments on all namespaces: `helm list --pending -A`
- List / search repo: `helm repo list` / `helm search repo nginx`
- Download (not install) a chart from a repository: `helm pull [chart URL | repo/chartname] [...] [flags]`
- Untar a chart (after downloading it): `helm pull --untar [rep/chartname]`
- Check customisable values setting for an install, e.g. `helm show values bitnami/apache [| yq e]`
- Custom install example `helm install my-apache bitnami/apache --set replicaCount=2`
- Upgrade a release, e.g. `helm upgrade my-api-v2 bitnami/nginx`
- Undo a helm rollout/upgrade: `helm rollback`
- Delete an installed release with `helm uninstall <release_name>`

### Administer cluster
- Drain a node: `k drain [--ignore-daemonsets --force] <node name>`
  - The kubectl drain subcommand on its own does not actually drain a node of its DaemonSet pods: the DaemonSet controller (part of the control plane) immediately replaces missing Pods with new equivalent Pods.
  - The DaemonSet controller also creates Pods that ignore unschedulable taints, which allows the new Pods to launch onto a node that you are draining.
- Resume scheduling **new pods** onto the node: `k uncordon <node name>`

### Misc
- Startup probes: run at container startup and stop running once they succeed; very similar to liveness probes (which run constantly on a schedule); useful for legacy applications that can have long startup times.
- Readiness probes: used to prevent user traffic from being sent to pods that are still in the process of starting up (e.g. pod STATUS = Running but READY = "0/1")
  - Example: for a service backed by multiple container endpoints, user traffic will not be sent to a particular pod until its containers have all passed the readiness checks defined by their readiness probes.
- Pod’s restart policy: Always (by default), OnFailure (restarted only if error code returned), and Never.
- Pod with InitContainer(s) will show "Init(0/n)" in their STATUS during initialisation


[//]: # (### References)
[//]: # (- https://kubernetes.io/docs/reference/k/cheatsheet/)
[//]: # (- https://github.com/dennyzhang/cheatsheet-kubernetes-A4)
[//]: # (- https://codefresh.io/blog/kubernetes-cheat-sheet/)
[//]: # (- https://intellipaat.com/blog/tutorial/devops-tutorial/kubernetes-cheat-sheet/)