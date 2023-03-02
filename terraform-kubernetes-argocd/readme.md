Reference: https://piotrminkowski.com/2022/06/28/manage-kubernetes-cluster-with-terraform-and-argo-cd/

```shell
terraform init

terraform apply

kubectl port-forward service/argocd-server 8443:443 -n argocd

kubectl get secret argocd-initial-admin-secret -n argocd --template={{.data.password}} | base64 -D
# GRtbgFlgskP0a1Xm


```