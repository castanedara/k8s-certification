# Exercise 8.2: Creating a Persistent NFS Volume (PV)

We will first deploy an NFS server. Once tested we will create a persistent NFS volume for containers to claim.

1. Install the software on your cp node.

```
student@cp: ̃$ sudo apt-get update && sudo \
      apt-get install -y nfs-kernel-server
<output_omitted>
```


2. Make and populate a directory to be shared. Also give it similar permissions to /tmp/

```
student@cp: ̃$ sudo mkdir /opt/sfw
student@cp: ̃$ sudo chmod 1777 /opt/sfw/
student@cp: ̃$ sudo bash -c 'echo software > /opt/sfw/hello.txt
```

3. Edit the NFS server file to share out the newly created directory. In this case we will share the directory with all. You can
always snoop to see the inbound request in a later step and update the file to be more narrow.

```
student@cp: ̃$ sudo vim /etc/exports
/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)
```

4. Cause /etc/exports to be re-read

`student@cp: ̃$ sudo exportfs -ra`

5. Test by mounting the resource from your second node.

```
student@worker: ̃$ sudo apt-get -y install nfs-common
<output_omitted>
student@worker: ̃$ showmount -e k8scp
Export list for k8scp:
/opt/sfw *
student@worker: ̃$ sudo mount k8scp:/opt/sfw /mnt
student@worker: ̃$ ls -l /mnt

total 4
-rw-r--r-- 1 root root 9 Sep 28 17:55 hello.txt
```

6. Return to the cp node and create a YAML file for the object with kind, PersistentVolume. Use the hostname of the cp server and the directory you created in the previous step. Only syntax is checked, an incorrect name or directory will not generate an error, but a Pod using the resource will not start. Note that the accessModes do not currently affect actual access and are typically used as labels instead.

```
student@cp: ̃$ vim PVol.yaml

1 apiVersion: v1
2 kind: PersistentVolume
3 metadata:
4 name: pvvol-1
5 spec:
6 capacity:
7 storage: 1Gi
8 accessModes:
9 - ReadWriteMany
10 persistentVolumeReclaimPolicy: Retain
11 nfs:
12 path: /opt/sfw
13 server: k8scp #<-- Edit to match cp node
14 readOnly: false

```
7. Create the persistent volume, then verify its creation
```
student@cp: ̃$ kubectl create -f PVol.yaml
    persistentvolume/pvvol-1 created



student@cp: ̃$ kubectl get pv

NAME CAPACITY ACCESSMODES RECLAIMPOLICY STATUS  CLAIM STORAGECLASS REASON AGE
pvvol-1 1Gi RWX Retain  Available   4s 

```