# etcd1 server name used instead of 127.0.0.1

ETCDCTL_API=3 etcdctl get cluster.name \
--endpoints=https://etcd1:2379 \
--cacert=/home/cloud_user/etcd-certs/etcd-ca.pem \
--cert=/home/cloud_user/etcd-certs/etcd-server.crt \
--key=/home/cloud_user/etcd-certs/etcd-server.key