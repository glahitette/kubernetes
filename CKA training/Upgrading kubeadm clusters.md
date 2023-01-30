### Upgrade the Control Plane
- `export K8S_VERSION=v1.22.2 && echo $K8S_VERSION`
- `export K8S_VERSION_LONG=1.22.2-00 && echo $K8S_VERSION_LONG`
- `export NODE_NAME=k8s-control && echo $NODE_NAME`
- Upgrade kubeadm: `sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=$K8S_VERSION_LONG`
  - Use `apt` instead of `apt-get` as needed
- Make sure it upgraded correctly: `kubeadm version`
- Drain the control plane node: `k drain $NODE_NAME --ignore-daemonsets`
- Plan the upgrade: `sudo kubeadm upgrade plan $K8S_VERSION`
- Upgrade the control plane components:`sudo kubeadm upgrade apply $K8S_VERSION`
- Upgrade kubelet and kubectl on the control plane node: `sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=$K8S_VERSION_LONG kubectl=$K8S_VERSION_LONG`
- Restart kubelet: `sudo systemctl daemon-reload && sudo systemctl restart kubelet && sudo systemctl status kubelet`
- Uncordon the control plane node: `k uncordon $NODE_NAME`
- Verify the control plane is working: `kno`

### Upgrade the Worker Nodes
- `export NODE_NAME=k8s-worker1 && echo $NODE_NAME`
- Run the following on the control plane node to drain worker node 1: `k drain $NODE_NAME --ignore-daemonsets --force`
  - You may get an error message that certain pods couldn't be deleted, which is fine.
- In a new terminal window, log in to worker node 1
  - `export K8S_VERSION_LONG=1.22.2-00 && echo $K8S_VERSION_LONG`
  - Upgrade kubeadm on worker node 1: `sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=$K8S_VERSION_LONG`
  - Upgrade the kubelet configuration on the worker node: `sudo kubeadm upgrade node`
  - Upgrade kubelet and kubectl on worker node 1: `sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=$K8S_VERSION_LONG kubectl=$K8S_VERSION_LONG`
  - Restart kubelet: `sudo systemctl daemon-reload && sudo systemctl restart kubelet && sudo systemctl status kubelet`
- From the control plane node, uncordon worker node 1: `sudo kubectl uncordon $NODE_NAME`
- Verify the worker node is working: `kno`
- Repeat process for other worker nodes
