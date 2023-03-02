terraform init

terraform apply -auto-approve

kubectl get secret argocd-initial-admin-secret -n argocd --template={{.data.password}} | base64 -D

kubectl port-forward service/argocd-server 8443:443 -n argocd