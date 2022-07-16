# Exercise 8.2: Creating a Persistent NFS Volume (PV)

Primero implementaremos un servidor NFS. Una vez probado, crearemos un volumen NFS persistente para que lo reclamen los contenedores.

1. Instale el software en su nodo cp.

```
student@cp: ̃$ sudo apt-get update && sudo \
      apt-get install -y nfs-kernel-server
<output_omitted>
```


2. Cree y complete un directorio para compartir. También déle permisos similares a /tmp/


```
student@cp: ̃$ sudo mkdir /opt/sfw
student@cp: ̃$ sudo chmod 1777 /opt/sfw/
student@cp: ̃$ sudo bash -c 'echo software > /opt/sfw/hello.txt'
```

3. Edite el archivo del servidor NFS para compartir el directorio recién creado. En este caso compartiremos el directorio con todos. Siempre puede husmear para ver la solicitud entrante en un paso posterior y actualizar el archivo para que sea más limitado.

```
student@cp: ̃$ sudo vim /etc/exports
/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)
```

4. Hacer que /etc/exports se vuelva a leer

`student@cp: ̃$ sudo exportfs -ra`

5. Pruebe montando el recurso desde su segundo nodo.

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

6. Regrese al nodo cp y cree un archivo YAML para el objeto con el tipo/kind, PersistentVolume. Use el hostname del servidor cp y el directorio que creó en el paso anterior. Solo se verifica la sintaxis, un nombre o directorio incorrecto no generará un error, pero no se iniciará un Pod que use el recurso. Tenga en cuenta que los "modos de acceso/accessModes" actualmente no afectan el acceso real y, por lo general, se usan como etiquetas en su lugar.


```
student@cp: ̃$ vim PVol.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvvol-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: /opt/sfw
    server: k8scp   #<-- Edit to match cp node
    readOnly: false
```
7. Cree el volumen persistente, luego verifique su creación

```
student@cp: ̃$ kubectl create -f PVol.yaml
    persistentvolume/pvvol-1 created

student@cp: ̃$ kubectl get pv

NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Retain           Available                                   7s

```