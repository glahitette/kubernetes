echo "alias c=clear" >> ~/.bashrc
echo "alias h=history" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "alias kn='kubectl config set-context --current --namespace ' # switch namespace with kn default or kn my-namespace" >> ~/.bashrc
echo "source /etc/bash_completion" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "export do='--dry-run=client -o yaml'" >> ~/.bashrc
echo "export now='--force --grace-period 0'" >> ~/.bashrc
bash