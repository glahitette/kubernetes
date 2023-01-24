echo "alias c=clear" >> ~/.bashrc
echo "alias h=history" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "alias kd='k get deployments -o wide'" >> ~/.bashrc
echo "alias kp='k get pods -o wide --show-labels'" >> ~/.bashrc
echo "alias kno='k get nodes -o wide'" >> ~/.bashrc
echo "alias kn='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'" >> ~/.bashrc
echo "alias ka='f() { [ "$1" ] && kubectl apply -f $1 ; } ; f'" >> ~/.bashrc
echo "source /etc/bash_completion" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "export do='--dry-run=client -o yaml'" >> ~/.bashrc
echo "export now='--force --grace-period 0'" >> ~/.bashrc
bash