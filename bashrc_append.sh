echo "alias c=clear" >> ~/.bashrc
echo "alias h=history" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "alias ka='kubectl apply -f '" >> ~/.bashrc
echo "alias ka2='f() { [ "$1" ] && kubectl apply -f $1 ; } ; f'" >> ~/.bashrc
echo "alias kd='k get deployments -o wide'" >> ~/.bashrc
echo "alias kdd='k describe deployment '" >> ~/.bashrc
echo "alias kdn='k describe node '" >> ~/.bashrc
echo "alias kdp='k describe pod '" >> ~/.bashrc
echo "alias kds='k describe service '" >> ~/.bashrc
echo "alias kno='k get nodes -o wide'" >> ~/.bashrc
echo "alias kn='kubectl config set-context --current --namespace '" >> ~/.bashrc
echo "alias kn2='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d " " -f6 ; } ; f'" >> ~/.bashrc
echo "alias kp='k get pods -o wide --show-labels'" >> ~/.bashrc
echo "alias ks='k get service -o wide'" >> ~/.bashrc
echo "source /etc/bash_completion" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "export do='--dry-run=client -o yaml'" >> ~/.bashrc
echo "export now='--force --grace-period 0'" >> ~/.bashrc
bash
c
h
echo "All set! Now run"
