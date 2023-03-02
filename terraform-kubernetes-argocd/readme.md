Reference: https://piotrminkowski.com/2022/06/28/manage-kubernetes-cluster-with-terraform-and-argo-cd/

```shell
terraform init

terraform apply -auto-approve

kubectl port-forward service/argocd-server 8443:443 -n argocd

kubectl get secret argocd-initial-admin-secret -n argocd --template={{.data.password}} | base64 -D

terraform destroy -auto-approve
```

to check argocd logs:

```
k -n argocd logs argocd-server-957669c76-fz98z # pod name suffix changes... 
```