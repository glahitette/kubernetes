terraform init

terraform apply -auto-approve

rm -rf argocd-password.txt

kubectl get secret argocd-initial-admin-secret -n argocd --template={{.data.password}} | base64 -D > argocd-password.txt

kubectl port-forward service/argocd-server 8443:443 -n argocd