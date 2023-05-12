# 4. Persistent volumes and persistent volume claims

## 4.1 Initializing an NFS server
This will create an NFS server on the worker1 node. Note that it's best to use a dedicated NFS server, or a cluster of servers, instead of mounting the server on the dedicated worker node.

Run `ansible-playbook nfs/nfs-server-setup-playbook.yaml`. This will run the `nfs-server-setup.sh` (courtesy of [this](https://learn.microsoft.com/en-us/azure/aks/azure-nfs-volume) microsoft guideline) on the worker1 (vbox32), creating an NFS server.

Then run `ansible-playbook playbooks/setup-csi-driver-nfs.yaml`. This will enable Helm3 (if not enabled), and install the [csi-driver-nfs](https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts) chart. It may take a **long** time before the csi-driver pods will start running (took 11 minutes in my case).

After that, run `ansible-playbook playbooks/setup-nfs-storage-class.yaml`. Make sure that you specify the server IP address and the export share correctly. This will create nfs-csi storage class that can be used to dynamically create persistent volumes & volume claims.

To test if the storage class provides correctly, you can either try creating a persistent volume claim (see `resources/postgres.yaml`), or creating a mount yourself. To create a mount, you'll need an `nfs-common` client, you can install it using `install-nfs-client.yaml` playbook. To mount, create some directory, e.g. `/tmp/pvc` and mount to it using `sudo mount -t nfs -o hard,nfsvers=4 192.168.50.32:/export /tmp/pvc`. If this fails, check if `192.168.50.32` (NFS server) is available, and if it is try changing the `nfsvers` til it doesn't fail. You can check your mounts using `showmount -a 192.168.50.32` and exports using `showmount -e 192.168.50.32`. It should mount to the `/export (everyone)` if you didn't change the export directory in the NFS server script. To unmount, use `sudo umount 192.168.50.32:/share/name /my/mounted/directory`, or if you get `stale file` errors on the mounted directory, use `sudo umount -f /my/mounted/directory`.

If you want to create a new share, do the following:
1. Go to `/etc/exports` file and append something like this: `/export/k8s  [client ip](rw,async,insecure,fsid=0,crossmnt,no_subtree_check)`. This will create an `/export/k8s` share available for the specified client IP (or IPs).
1. Reload the file with `sudo exportfs -rv`. This will add the new entry.
1. If the new export doesn't show up in `showmount -e 192.168.50.32`, restart the server kernel: `sudo nohup service nfs-kernel-server restart`.

## 4.2 Creating a persistent volume & a claim to the volume
### 4.2.1 Creating PV & PVC manually
Create a persistent volume with NFS and add a `claimRef` pointing at a PVC with a specific name. When this PVC gets created, it'll get bound to the created PV.
```
---
# PV
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-data
  labels:
    type: nfs
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  claimRef:
    namespace: postgres
    name: postgres-pvc
  nfs:
    # vbox32/nfs server ip
    server: 192.168.50.32
    # nfs server export path
    path: /export/k8s

---
# PVC [Bind to existing volume]
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: postgres
spec:
  accessModes: 
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

### 4.2.2 Creating a PV & PVC automatically
To create a persistent (NFS) volume automatically, use the created NFS-CSI storage class when creating a volume claim. It will automatically provide the persistent volume. E.g.:
```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvs
  namespace: my-namespace
spec:
  storageClassName: nfs-csi
  accessModes: 
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```
If this fails (e.g. PVC unbound error when deploying), try creating the volume manually.

## 4.3 Deploying PostgreSQL
First create a secret, for example:
```
apiVersion: v1
kind: Secret
metadata:
  name: postgres-auth
  namespace: postgres
  labels:
    app: postgres
type: Opaque
data:
  postgres-user: cm9vdA==
  postgres-password: bXlwYXNzd29yZA==
```

## 4.4 Deploying PgAdmin
First, create PgAdmin secret using the following template:
```
apiVersion: v1
kind: Secret
metadata:
  name: pgadmin-secret
  namespace: postgres
  labels:
    app: pgadmin
type: Opaque
data:
  pgadmin-password: bXlwd2Q=
```