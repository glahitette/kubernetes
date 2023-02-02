Q:
- Use context: kubectl config use-context k8s-c3-CCC
- Make a backup of etcd running on cluster3-controlplane1 and save it on the controlplane node at /tmp/etcd-backup.db. 
- Then create a Pod of your kind in the cluster. 
- Finally restore the backup, confirm the cluster is still working and that the created Pod is no longer with us.


Answer:

- `etcd` Backup
  - First we log into the controlplane and try to create a snapshop of etcd:
```
➜ root@cluster3-controlplane1:~# ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db
Error:  rpc error: code = Unavailable desc = transport is closing
```
- - But authentication fails. The api-server is connecting to etcd, so we check its manifest configuration:
```
➜ root@cluster3-controlplane1:~# cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd
- --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
- --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
- --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
- --etcd-servers=https://127.0.0.1:2379
```
- - We use the authentication information and pass it to etcdctl:
```
➜ root@cluster3-controlplane1:~# ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key
```
- - Snapshot saved at `/tmp/etcd-backup.db`. NOTE: Dont use `snapshot status` because it can alter the snapshot file and render it invalid
- `etcd` restore
  - Now create a Pod in the cluster and wait for it to be running: `k run test --image=nginx`
  - Stop all controlplane components: `cd /etc/kubernetes/manifests/ && mv * ..`
  - Restore the snapshot into a new directory `/var/lib/etcd-backup`:
```
➜ root@cluster3-controlplane1:~# ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
--data-dir /var/lib/etcd-backup \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key

2020-09-04 16:50:19.650804 I | mvcc: restore compact to 9935
2020-09-04 16:50:19.659095 I | etcdserver/membership: added member 8e9e05c52164694d [http://localhost:2380] to cluster cdf818194e3a8c32
```
- - We could specify another host to make the backup from by using etcdctl --endpoints http://IP, but here we just use the default value which is: http://127.0.0.1:2379,http://127.0.0.1:4001.
- - Update `etcd` to use the new directory:
```
➜ root@cluster3-controlplane1:~# vim /etc/kubernetes/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd
  namespace: kube-system
spec:
...
volumes:
- hostPath:
  path: /var/lib/etcd-backup                # change
...
```
- - Move all controlplane yaml files back to the `manifest` directory: `mv /etc/kubernetes/*.yaml /etc/kubernetes/manifests/`
- - Wait a few minutes for etcd to restart and for the api-server to be reachable again: `watch crictl ps`
- - Then we check again for the test Pod: `k get pod -l run=test` --> No resources found in default namespace.
