<!-- TOC -->
* [Application Design and Build (20% of CKAD exam)](#application-design-and-build--20-of-ckad-exam-)
  * [Building Container Images](#building-container-images)
  * [Running Jobs and CronJobs](#running-jobs-and-cronjobs)
  * [Building Multi-Container Pods](#building-multi-container-pods)
  * [Using Init Containers](#using-init-containers)
  * [Exploring volumes](#exploring-volumes)
  * [Using PersistentVolumes](#using-persistentvolumes)
* [Application Deployment (20% of CKAD exam)](#application-deployment--20-of-ckad-exam-)
  * [Understanding Deployments](#understanding-deployments)
  * [Performing Rolling Updates](#performing-rolling-updates)
  * [Deploying with Blue/Green and Canary Strategies](#deploying-with-bluegreen-and-canary-strategies)
  * [Helm](#helm)
* [Application Observability and Maintenance (15% of CKAD exam)](#application-observability-and-maintenance--15-of-ckad-exam-)
  * [Understanding the API Deprecation Policy](#understanding-the-api-deprecation-policy)
  * [Implementing Probes and Health Checks](#implementing-probes-and-health-checks)
  * [Monitoring Kubernetes Applications](#monitoring-kubernetes-applications)
  * [Accessing Container Logs](#accessing-container-logs)
  * [Debugging in Kubernetes](#debugging-in-kubernetes)
* [Application Environment, Configuration, and Security (25% of CKAD exam)](#application-environment-configuration-and-security--25-of-ckad-exam-)
  * [Using Custom Resources (CRD)](#using-custom-resources--crd-)
  * [Using ServiceAccounts](#using-serviceaccounts)
  * [Understanding Kubernetes Auth](#understanding-kubernetes-auth)
  * [Exploring Admission Control](#exploring-admission-control)
  * [Managing Compute Resource Usage](#managing-compute-resource-usage)
  * [Configuring Applications with ConfigMaps and Secrets](#configuring-applications-with-configmaps-and-secrets)
  * [Configuring SecurityContext for Containers](#configuring-securitycontext-for-containers)
* [Services and Networking (20% of CKAD exam)](#services-and-networking--20-of-ckad-exam-)
  * [Controlling Network Access with NetworkPolicies](#controlling-network-access-with-networkpolicies)
  * [Exploring Services](#exploring-services)
  * [Exposing Applications with Ingress](#exposing-applications-with-ingress)
<!-- TOC -->

# Application Design and Build (20% of CKAD exam)
## Building Container Images
- Build a container image from the current directory. The -t flag specifies the image tag name. `docker build -t my-image:1.0 .`
- Save an image to a file: `docker save -o ~/my-image.1.0.tar my-image:1.0`

## Running Jobs and CronJobs

[//]: # (- A Job is designed to run a containerized task successfully to completion.)
[//]: # (- CronJobs run Jobs periodically according to a schedule.)
- The restartPolicy for a Job or CronJob Pod must be `OnFailure` or `Never`.
- Use `activeDeadlineSeconds` in the Job spec to terminate the Job if it runs too long.
- Example with busybox:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  template:
    spec:
      containers:
      - name: print
        image: busybox:stable
        command: ["echo", "This is a test!"]
      restartPolicy: Never
  backoffLimit: 4
  activeDeadlineSeconds: 10
```

## Building Multi-Container Pods

- A sidecar container performs some task that helps the main container.
- An ambassador container proxies network traffic to and/or from the main container.
- An adapter container transforms the main container’s output.
- Example with sidecar:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-test
spec:
  containers:
    - name: writer
      image: busybox:stable
      command: ['sh', '-c', 'echo "The writer wrote this!" > /
output/data.txt; while true; do sleep 5; done']
      volumeMounts:
        - name: shared
          mountPath: /output
    - name: sidecar
      image: busybox:stable
      command: ['sh', '-c', 'while true; do cat /input/data.txt;
sleep 5; done']
      volumeMounts:
        - name: shared
          mountPath: /input
  volumes:
    - name: shared
      emptyDir: {}
```

## Using Init Containers

- Init containers run to completion before the main container starts up.
- Add init containers using the initContainers field of the PodSpec.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-test
spec:
  containers:
  - name: nginx
    image: nginx:stable
  initContainers:
  - name: busybox
    image: busybox:stable
    command: ['sh', '-c', 'sleep 60']
```

## Exploring volumes

- The volumes field in the Pod spec defines details about volumes used in the Pod.
- The volumeMounts field in the container spec mounts a volume to a specific container at a specific location.
- hostPath volumes mount data from a specific location on the host (k8s node). 
- hostPath volume types:
  - Directory – Mounts an existing directory on the host.
  - DirectoryOrCreate – Mounts a directory on the host, and creates it if it doesn’t exist.
  - File – Mounts an existing single file on the host.
  - FileOrCreate – Mounts a file on the host, and creates it if it doesn’t exist.
- emptyDir volumes provide temporary storage that uses the host file system and are removed if the Pod is deleted.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-volume-test
spec:
  restartPolicy: OnFailure
  containers:
    - name: busybox
      image: busybox:stable
      command: ['sh', '-c', 'cat /data/data.txt']
      volumeMounts:
        - name: host-data
          mountPath: /data
  volumes:
    - name: host-data
      hostPath:
        path: /etc/hostPath
        type: Directory
```

## Using PersistentVolumes

- A PersistentVolume defines a storage resource. [Example](hostPath-pv.yml)
- A PersistentVolumeClaim defines a request to consume a storage resource. [Example](hostPath-pvc.yml)
- PersistentVolumeClaims automatically bind to a PersistentVolume that meets their criteria.
- Mount a PersistentVolumeClaim to a container like a regular volume. [Example](pv-pod-test.yml)

# Application Deployment (20% of CKAD exam)
## Understanding Deployments
- A Deployment actively manages a desired state for a set of replica Pods.
- The Pod template provides the Pod configuration that the Deployment will use to create new Pods.
- The replicas field sets the number of replicas. You can scale up or down by changing this value.

## Performing Rolling Updates
- A rolling update gradually rolls out changes to a Deployment’s Pod  template by gradually replacing replicas with new ones.
- Use `k rollout status` to check the status of a rolling update.
- Roll back the latest rolling update with: `k rollout undo`

## Deploying with Blue/Green and Canary Strategies
- You can use multiple Deployments to set up blue/green environments in Kubernetes.
- Use labels and selectors on Services to direct user traffic to different Pods.
- A simple way to set up a canary environment in Kubernetes is to use a Service that selects Pods from 2 different Deployments. Vary the number of replicas to direct fewer users to the canary environment.
- Blue/Green - Create a second, identical environment running the new code, **_test it, then_** point user traffic to the new environment.
  - [Blue deployment](blue-deployment.yml), [Green deployment](green-deployment.yml), [Service](blue-green-test-svc.yml)
- Canary - Create a second, identical environment running the new code, and **_direct a small percentage of user traffic to the new environment to verify_** it is working before deploying the new code for all users.
  - [Main deployment](main-deployment.yml), [Canary deployment](canary-deployment.yml), [Service](canary-test-svc.yml)

## Helm

# Application Observability and Maintenance (15% of CKAD exam)
## Understanding the API Deprecation Policy
## Implementing Probes and Health Checks
- Liveness probes check if a container is healthy so that it can be restarted if it is not. [liveness](liveness-pod.yml)
- Readiness probes check whether a container is fully started up and ready to be used. [readiness](readiness-pod.yml)
- Probes can run a command inside the container, make an HTTP request, or attempt a TCP socket connection to determine container status.

## Monitoring Kubernetes Applications
- The Kubernetes metrics API provides metric data about container performance.
- You can view Pod metrics using kubectl top pod. When metrics server is installed, you can use kubectl top to view
  resource usage data.

## Accessing Container Logs
## Debugging in Kubernetes

# Application Environment, Configuration, and Security (25% of CKAD exam)
## Using Custom Resources (CRD)
- [Example](beehives_crd.yml)

## Using ServiceAccounts
- ServiceAccounts allow processes within containers to authenticate with the Kubernetes API Server. 
- You can set the Pod’s ServiceAccount with `serviceAccountName` in the Pod spec.
- The Pod’s ServiceAccount token is automatically mounted to the Pod’s containers.
- [ServiceAccount example](my-service-account.yml), [Pod example](my-service-account-pod.yml)

## Understanding Kubernetes Auth
- Normal users usually authenticate using client certificates, while ServiceAccounts usually use tokens.
- Authorization for both normal users and ServiceAccounts can be managed using Role-Based Access Control (RBAC):
  - `Role` / `ClusterRole` - Defines a set of permissions, and exists within a Namespace / cluster-wide.
  - `RoleBinding` / `ClusterRoleBinding` - Binds a Role or ClusterRole to subjects such as users or ServiceAccounts. The permissions take effect within a Namespace / clusterwide.

## Exploring Admission Control
- Admission Controllers act upon incoming requests to the Kubernetes API. They can validate/deny and even modify requests.
- Example: `sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml` to enable the `NamespaceAutoProvision`  admission controller plugin automatically creates Namespaces:
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 172.30.1.2:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --<...>
    - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
```

## Managing Compute Resource Usage
- Resource Requests - Specify an **approximate** amount of expected resource usage - used **to schedule Pods on Nodes** where the requested resources are available.
- Resource Limits - Specify an enforced upper limit for resource usage. The container process will be terminated if it exceeds these limits.
- ResourceQuota limits the amount of resources that can be used **within a specific Namespace**. If a user attempts to create or modify objects in that Namespace such that the quota would be exceeded, the request will be denied.
- [Resource-consumer example](resource-consumer-pod.yml), [Pod example](resources-pod.yml), [Quota example](resources-test-quota.yml)

## Configuring Applications with ConfigMaps and Secrets
- Data from both ConfigMaps and Secrets can be passed to containers using either a volume mount or environment variables.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-configmap
data:
  message: Hello, World!
  app.cfg: |
    # A configuration file!
    key1=value1
    key2=value2
---
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  sensitive.data: U2VjcmV0IFN0dWZmIQo=
  passwords.txt: U2VjcmV0IHN0dWZmIGluIGEgZmlsZSEK
---
apiVersion: v1
kind: Pod
metadata:
  name: cm-pod
spec:
  restartPolicy: Never
  containers:
    - name: busybox
      image: busybox:stable
      command: ['sh', '-c', 'echo $MESSAGE; cat /config/app.cfg; echo $SENSITIVE_STUFF; cat /secret-config/passwords.txt']
      env:
        - name: MESSAGE
          valueFrom:
            configMapKeyRef:
              name: my-configmap
              key: message
        - name: SENSITIVE_STUFF
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: sensitive.data
      volumeMounts:
        - name: config
          mountPath: /config
          readOnly: true
        - name: secret-config
          mountPath: /secret-config
          readOnly: true
  volumes:
    - name: config
      configMap:
        name: my-configmap
        items:
          - key: app.cfg
            path: app.cfg
    - name: secret-config
      secret:
        secretName: my-secret
        items:
        - key: passwords.txt
          path: passwords.txt
```

## Configuring SecurityContext for Containers
- A container's SecurityContext allows you to control advanced security related settings for the container.
- Example:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: securitycontext-pod
spec:
  containers:
    - name: busybox
      image: busybox:stable
      command: ['sh', '-c', 'while true; do echo Running...; sleep 5; done']
      securityContext:
        runAsUser: 3000 # container process will run as user ID 3000
        runAsGroup: 4000 # container process will run as group ID 4000
        allowPrivilegeEscalation: false # Disables privileged mode for the container
        readOnlyRootFilesystem: true # Marks the container's root filesystem read-only
```

# Services and Networking (20% of CKAD exam)
## Controlling Network Access with NetworkPolicies
- NetworkPolicies allow you to control what traffic is and is not allowed within the cluster network.
- If you combine a namespaceSelector and a podSelector within the  same rule, the traffic must meet both the Pod- and Namespace-related conditions in order to be allowed.
- Even if a NetworkPolicy allows outgoing traffic from the source Pod, NetworkPolicies could still block the same traffic when it is incoming to the destination Pod.
- If no NetworkPolicies select a Pod, the Pod is **non-isolated: it allows traffic to and from itself**.
- If a Pod is selected by at least 1 NetworkPolicy, it is isolated. In order for traffic to be allowed, at least 1 NetworkPolicy that selects the Pod must allow the traffic.
- the empty podSelector {} selects **all Pods in the Namespace**.
- [Example]()
```yaml
# A default deny NetworkPolicy disables all traffic by default, leaving it up to
# other NetworkPolicies to specifically allow desired traffic.
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-test-a-default-deny-ingress
  namespace: np-test-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# This policy affects only Ingress (incoming) traffic. It allows traffic from
# any Pod that meets both of the following criteria:
# In a Namespace with the team=bteam label.
# The Pod has the label app: np-test-client .
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-test-client-allow
  namespace: np-test-a
spec:
  podSelector:
    matchLabels:
      app: np-test-server
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              team: bteam
          podSelector:
            matchLabels:
              app: np-test-client
      ports:
        - protocol: TCP
          port: 80
```

## Exploring Services
- Services allow you to expose an application running in multiple Pods.
- ClusterIP Services expose the Pods to other applications **within the cluster**: [ClusterIP example](service-clusterip.yml)
  - It provides an IP address and hostnames within the cluster network that other Pods can use to access the Service.
- NodePort Services expose the Pods **externally** using a port that listens on every node in the cluster: [NodePort example](service-nodeport.yml)

## Exposing Applications with Ingress
- An Ingress manages external access to Kubernetes applications: [Ingress example](ingress-test-ingress.yml)
- Usually, an Ingress routes traffic to a Service backend. An Ingress can also provide additional features such as SSL termination.
- You need an Ingress controller to implement the Ingress functionality. Which controller you use determines the specifics of how the Ingress will work.

