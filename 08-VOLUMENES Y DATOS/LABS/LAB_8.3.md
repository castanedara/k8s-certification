# Exercise 8.3: Creating a Persistent Volume Claim (PVC)

Antes de que los pods puedan aprovechar el nuevo PV, debemos crear un Reclamo de volumen persistente (PVC).

1. Comience por determinar si existen actualmente.

student@cp: ̃$ kubectl get pvc
No resources found in default namespace.

2. Cree un archivo YAML para el nuevo pvc.

student@cp: ̃$ vim pvc.yaml

**pvc.yaml:**

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-one
spec:
  accessModes:
  - ReadWriteMany
  resources:
     requests:
       storage: 200Mi
```

3. Cree y verifique que el nuevo pvc esté enlazado. Tenga en cuenta que el tamaño es 1Gi, aunque se sugirió 200Mi. Solo se podría usar un volumen de al menos ese tamaño.

```
student@cp: ̃$ kubectl create -f pvc.yaml
persistentvolumeclaim/pvc-one created
```

```
student@cp: ̃$ kubectl get pvc
NAME      STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-one   Bound    pvvol-1   1Gi        RWX                           6s
```

4. Vuelva a mirar el estado del PV para determinar si está en uso. Debería mostrar un estado de Bound.

```
student@cp: ̃$ kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Retain           Bound    default/pvc-one                           4m44s
```

5. Cree una nuevo deployment para usar el pvc. Copiaremos y editaremos un archivo yaml de deployment existente. Cambiaremos el nombre del deployment y luego agregaremos una sección de montajes de volumen (volumeMounts) en la sección de contenedores y volúmenes a la especificación general. El nombre utilizado debe coincidir en ambos lugares, independientemente del nombre que utilice. ClaimName debe coincidir con un pvc existente. Como se muestra en el siguiente ejemplo. La línea de volúmenes tiene la misma identación que los contenedores y dnsPolicy.

`student@cp: ̃$ cp first.yaml nfs-pod.yaml`

`student@cp: ̃$ vim nfs-pod.yaml`

**nfs-pod.yaml:**

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx-nfs
  namespace: default
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: nginx
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - name: nfs-vol
          mountPath: /opt
        ports:
        - containerPort: 80
          protocol: TCP
      volumes:
      - name: nfs-vol
        persistentVolumeClaim:
          claimName: pvc-one
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
```

6. Cree el pod usando el archivo recién editado.

student@cp: ̃$ kubectl create -f nfs-pod.yaml
deployment.apps/nginx-nfs created

7. Mira los detalles del Pod. Es posible que también vea los pods daemonset ejecutándose.

```
student@cp: ̃$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
nginx-nfs-8d5666cfb-xcgdd   1/1     Running   0          100s
```

```
student@cp: ̃$ kubectl describe pod nginx-nfs-1054709768-s8g28

k8s@srv-master1:~$ kubectl describe pod nginx-nfs-8d5666cfb-xcgdd
Name:         nginx-nfs-8d5666cfb-xcgdd
Namespace:    default
Priority:     0
Node:         srv-worker1.kruger.com.ec/192.168.111.138
<output_omitted>
Mounts:
/opt from nfs-vol (rw)
<output_omitted>
Volumes:
  nfs-vol:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc-one
    ReadOnly:   false
<output_omitted>
```

8. Ver el estado del PVC. Debería mostrarse como enlazado.

```
student@cp: ̃$ kubectl get pvc

NAME      STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-one   Bound    pvvol-1   1Gi        RWX                           17m
```

