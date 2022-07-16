Exercise 8.4: Using a ResourceQuota to Limit PVC Count and Usage
Ejercicio 8.4: uso de  **ResourceQuota** una cuota de recursos para limitar el recuento y el uso de PVC

La flexibilidad del almacenamiento basado en la nube a menudo requiere limitar el consumo entre los usuarios. Usaremos el objeto ResourceQuota para limitar tanto el consumo total como la cantidad de solicitudes de volumen persistentes (persistent volume claims).

1. Empezamos borrando el deployment que habíamos creado para usar NFS, el pv y el pvc.

```
student@cp: ̃$ kubectl delete deploy nginx-nfs
deployment.apps "nginx-nfs" deleted
```

```
student@cp: ̃$ kubectl delete pvc pvc-one
persistentvolumeclaim "pvc-one" deleted
```
```
student@cp: ̃$ kubectl delete pv pvvol-1
persistentvolume "pvvol-1" deleted
```
2. Cree un archivo yaml para el objeto **ResourceQuota**. Establezca el límite de almacenamiento en diez reclamos/claims con un uso total de 500Mi.


```
student@cp: ̃$ vim storage-quota.yaml

apiVersion: v1
kind: ResourceQuota
metadata:
  name: storagequota
spec:
  hard:
    persistentvolumeclaims: "10"
    requests.storage: "500Mi"
```

3. Cree un nuevo namespace llamado small. Vea la información del namespace antes de la nueva cuota. El nombre largo con guiones dobles --namespace o el apodo ns funcionan para el recurso.


```
student@cp: ̃$ kubectl create namespace small
    namespace/small created
```
```
student@cp: ̃$ kubectl describe ns small

....
Name:         small
Labels:       kubernetes.io/metadata.name=small
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

4. Cree un nuevo pv y pvc en el namespace small.
```
student@cp: ̃$ kubectl -n small create -f PVol.yaml
persistentvolume/pvvol-1 created
```
```
student@cp: ̃$ kubectl -n small create -f pvc.yaml
persistentvolumeclaim/pvc-one created
```

5. Cree la nueva cuota de recursos, colocando este objeto en el namespace small
```
student@cp: ̃$ kubectl -n small create -f storage-quota.yaml
resourcequota/storagequota created
```

6. Verifique que el namespace small tenga cuotas. Compare la salida con el mismo comando anterior.

```
student@cp: ̃$ kubectl describe ns small
Name:         small
Labels:       kubernetes.io/metadata.name=small
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:                   storagequota
  Resource                Used   Hard
  --------                ---    ---
  persistentvolumeclaims  1      10
  requests.storage        200Mi  500Mi

No LimitRange resource.
-------- --- ---

```

7. Quite la línea del namespace del archivo nfs-pod.yaml. Debería estar alrededor de la línea 11 más o menos. Esto nos permitirá pasar otros namespace en la línea de comando


```
student@cp: ̃$ vim nfs-pod.yaml
```

8. Vuelva a crear el contenedor.

```
student@cp: ̃$ kubectl -n small create -f nfs-pod.yaml
deployment.apps/nginx-nfs created
```

9. Determine si el deployment tiene un pod en ejecución.
```
student@cp: ̃$ kubectl -n small get deploy
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx-nfs   1/1     1            1           32s
```

```
student@cp: ̃$ kubectl -n small describe deploy nginx-nfs
<output_omitted>
```

10. Mira a ver si los Pods están listas.

```
student@cp: ̃$ kubectl -n small get pod
NAME                         READY   STATUS    RESTARTS   AGE
nginx-nfs-5f58fd64fd-4wbkl   1/1     Running   0          2m33s
```

11. Asegúrese de que el Pod se esté ejecutando y esté utilizando el volumen montado de NFS. Si pasa el namespace, la primera pestaña completará automáticamente el nombre del pod


```
student@cp: ̃$ kubectl -n small describe pod \
nginx-nfs-2854978848-g3khf
```

```
Name:         nginx-nfs-5f58fd64fd-4wbkl
Namespace:    small
<output_omitted>
    Mounts:
      /opt from nfs-vol (rw)
<output_omitted>
```

12. Ver el uso de la cuota del namespace.

`student@cp: ̃$ kubectl describe ns small`

```
<output_omitted>
Resource Quotas
  Name:                   storagequota
  Resource                Used   Hard
  --------                ---    ---
  persistentvolumeclaims  1      10
  requests.storage        200Mi  500Mi

No LimitRange resource.
```

13. Cree un archivo de 300M dentro del directorio **/opt/sfw** en el host y vea el uso de la cuota nuevamente. Tenga en cuenta que con NFS el
el tamaño del recurso compartido no se tiene en cuenta para el deployment.

`student@cp: ̃$ sudo dd if=/dev/zero of=/opt/sfw/bigfile bs=1M count=300`

```
300+0 records in
300+0 records out
314572800 bytes (315 MB, 300 MiB) copied, 4.4077 s, 71.4 MB/s
```

```
student@cp: ̃$ kubectl describe ns small
<output_omitted>
Resource Quotas
  Name:                   storagequota
  Resource                Used   Hard
  --------                ---    ---
  persistentvolumeclaims  1      10
  requests.storage        200Mi  500Mi

No LimitRange resource.
```

```
student@cp: ̃$ du -h /opt/

301M /opt/sfw
41M /opt/cni/bin
41M /opt/cni
341M /opt/
```

14. Ahora permítanos ilustrar lo que sucede cuando un deployment solicita más que la cuota. Comience a apagar el deployment existente.

```
student@cp: ̃$ kubectl -n small get deploy
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx-nfs   1/1     1            1           13m
```

```
student@cp: ̃$ kubectl -n small delete deploy nginx-nfs

deployment.apps "nginx-nfs" deleted
```

15. Once the Pod has shut down view the resource usage of the namespace again. Note the storage did not get cleaned up when the pod was shut down
Una vez que el pod se haya apagado, vea nuevamente el uso de recursos del namespace. Tenga en cuenta que el almacenamiento no se limpió cuando se cerró el pod
```
student@cp: ̃$ kubectl describe ns small

<output_omitted>
Resource Quotas
  Name:                   storagequota
  Resource                Used   Hard
  --------                ---    ---
  persistentvolumeclaims  1      10
  requests.storage        200Mi  500Mi
```

16. Retire el pvc y luego vea el pv que estaba usando. Tenga en cuenta la  RECLAIM POLICY  y el STATUS.
```
student@cp: ̃$ kubectl -n small get pvc

NAME      STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-one   Bound    pvvol-1   1Gi        RWX                           21m
```

```
student@cp: ̃$ kubectl -n small delete pvc pvc-one
persistentvolumeclaim "pvc-one" deleted
```

```
student@cp: ̃$ kubectl -n small get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM           STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Retain           Released   small/pvc-one                           22m
```


17. El almacenamiento aprovisionado dinámicamente usa ReclaimPolicy de StorageClass, que podría ser Delete, Retain o algunos tipos permiten Recycle. Los volúmenes persistentes creados manualmente tienen el valor predeterminado Retener a menos que se establezca lo contrario en la creación. La política de almacenamiento predeterminada es retener el almacenamiento para permitir la recuperación de cualquier dato. Para cambiar esto, comience por ver la salida de yaml.


```
student@cp: ̃$ kubectl get pv/pvvol-1 -o yaml

    path: /opt/sfw
    server: k8scp
  persistentVolumeReclaimPolicy: Retain
status:
  phase: Released
```

18. Actualmente necesitaremos eliminar y volver a crear el objeto. Está previsto el desarrollo futuro de un plugin de eliminación. Volveremos a crear el volumen y le permitiremos usar la política Retain, luego la cambiaremos una vez que se ejecute.

```
student@cp: ̃$ kubectl delete pv/pvvol-1
persistentvolume "pvvol-1" deleted
student@cp: ̃$ grep Retain PVol.yaml
persistentVolumeReclaimPolicy: Retain
student@cp: ̃$ kubectl create -f PVol.yaml
persistentvolume "pvvol-1" created
```

19. Usaremos el parche kubectl para cambiar la política de retención a Delete. La salida de yaml de antes puede ser útil para obtener la sintaxis correcta.

```
student@cp: ̃$ kubectl patch pv pvvol-1 -p \
'{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'

persistentvolume/pvvol-1 patched

student@cp: ̃$ kubectl get pv/pvvol-1

NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Delete           Available                                   83s
```

20. Ver la configuración de cuota actual.

```
student@cp: ̃$ kubectl describe ns small
....
  requests.storage        0     500Mi
```

21. Crea el pvc de nuevo. Incluso sin pods en ejecución, tenga en cuenta el uso de recursos.

```
student@cp: ̃$ kubectl -n small create -f pvc.yaml
persistentvolumeclaim/pvc-one created
student@cp: ̃$ kubectl describe ns small
....
requests.storage 200Mi 500Mi
```

22. Quite la cuota existente del namespace.

```
student@cp: ̃$ kubectl -n small get resourcequota
NAME           AGE   REQUEST                                                       LIMIT
storagequota   32m   persistentvolumeclaims: 1/10, requests.storage: 200Mi/500Mi
```

```
student@cp: ̃$ kubectl -n small delete resourcequota storagequota
resourcequota "storagequota" deleted
```

23. Edite el archivo storagequota.yaml y reduzca la capacidad a 100Mi.

```
student@cp: ̃$ vim storage-quota.yaml
2 requests.storage: "100Mi"
```

24. Cree y verifique la nueva cuota de almacenamiento. Tenga en cuenta que el límite estricto ya se ha excedido

```
student@cp: ̃$ kubectl -n small create -f storage-quota.yaml
resourcequota/storagequota created

student@cp: ̃$ kubectl describe ns small
....
  persistentvolumeclaims  1      10
  requests.storage        200Mi  100Mi

No resource limits
```

25. Vuelva a crear el deployment. Ver el deployment. Tenga en cuenta que no se ven errores.

```
student@cp: ̃$ kubectl -n small create -f nfs-pod.yaml
deployment.apps/nginx-nfs created

student@cp: ̃$ kubectl -n small describe deploy/nginx-nfs
Name:                   nginx-nfs
Namespace:              small
<output_omitted>
```


26. Examine los pods para ver si realmente se están ejecutando.

```
student@cp: ̃$ kubectl -n small get po
NAME READY STATUS RESTARTS AGE
nginx-nfs-2854978848-vb6bh 1/1 Running 0 58s
```

27. Como pudimos implementar más pods incluso con una cuota fija aparente, hagamos una prueba para ver si se recupera el almacenamiento. Quite la implementación y la reclamación de volumen persistente.


```
student@cp: ̃$ kubectl -n small delete deploy nginx-nfs
deployment.apps "nginx-nfs" deleted
```

```
student@cp: ̃$ kubectl -n small delete pvc/pvc-one
persistentvolumeclaim "pvc-one" deleted
```


28. Ver si existe el volumen persistente. Verá que intentó una eliminación, pero falló. Si mira más de cerca, encontrará que el error tiene que ver con la falta de un plugin de eliminación de volumen para NFS. Otros protocolos de almacenamiento tienen un plugin.

```
student@cp: ̃$ kubectl -n small get pv

NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM           STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Delete           Failed   small/pvc-one                           16m
```

29. Asegúrese de que el despliegue, el pvc y el pv se eliminen.

```
student@cp: ̃$ kubectl delete pv/pvvol-1
persistentvolume "pvvol-1" deleted
```

30. Edite el archivo YAML del volumen persistente y cambie la politica de reclamación a persistentVolumeReclaimPolicy: a Recycle.

```
student@cp: ̃$ vim PVol.yaml
PVol.yaml
1 ....
2 persistentVolumeReclaimPolicy: Recycle
3 ....
```
31. Agregue un LimitRange al namespace e intente crear el volumen persistente(pv) y la reclamación de volumen persistente(pvc) nuevamente. Podemos usar el LimitRange que usamos antes.


```
student@cp: ̃$ kubectl -n small create -f low-resource-range.yaml
limitrange/low-resource-range created
```

32. Vea la configuración del namespace. Deben verse tanto las cuotas como los límites de recursos.

```
student@cp: ̃$ kubectl describe ns small
<output_omitted>
Resource Limits
 Type       Resource  Min  Max  Default Request  Default Limit  Max Limit/Request Ratio
 ----       --------  ---  ---  ---------------  -------------  -----------------------
 Container  cpu       -    -    500m             1              -
 Container  memory    -    -    100Mi            500Mi          -
```

33. Vuelva a crear el volumen persistente. Ver el recurso. Tenga en cuenta que la política de recuperación es Recycle.
```
student@cp: ̃$ kubectl -n small create -f PVol.yaml
persistentvolume/pvvol-1 created
```

```
student@cp: ̃$ kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Recycle          Available                                   7s
```


34. Intente volver a crear la reclamación de volumen persistente. La cuota solo entra en vigor si también hay un límite de recursos en vigor.

```
student@cp: ̃$ kubectl -n small create -f pvc.yaml
Error from server (Forbidden): error when creating "pvc.yaml": persistentvolumeclaims "pvc-one" is forbidden: exceeded quota: storagequota, requested: requests.storage=200Mi, used: requests.storage=0, limited: requests.storage=100Mi
```

35. Edite la cuota de recursos para aumentar el almacenamiento de solicitudes a 500mi.

```
student@cp: ̃$ kubectl -n small edit resourcequota

3spec:
  hard:
    persistentvolumeclaims: "10"
    requests.storage: 500Mi

status:
  hard:
    persistentvolumeclaims: "10"
    requests.storage: 100Mi

```

36. Crea el pvc de nuevo. Debería funcionar esta vez. A continuación, vuelva a crear el deployment.

```
student@cp: ̃$ kubectl -n small create -f pvc.yaml
persistentvolumeclaim/pvc-one created
student@cp: ̃$ kubectl -n small create -f nfs-pod.yaml
deployment.apps/nginx-nfs created
```

37. Ver la configuración del namespace.

```
student@cp: ̃$ kubectl describe ns small
<output_omitted>
```

38. Eliminar la implementación. Ver el estado del pv y pvc.

```
student@cp: ̃$ kubectl -n small delete deploy nginx-nfs
deployment.apps "nginx-nfs" deleted

student@cp: ̃$ kubectl -n small get pvc
NAME      STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-one   Bound    pvvol-1   1Gi        RWX                           87s

student@cp: ̃$ kubectl -n small get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM           STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Recycle          Bound    small/pvc-one                           6m34s
```


39. Elimine el pvc y verifique el estado del pv. Debería mostrarse como Disponible.

```
student@cp: ̃$ kubectl -n small delete pvc pvc-one
persistentvolumeclaim "pvc-one" deleted
```

```
student@cp: ̃$ kubectl -n small get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pvvol-1   1Gi        RWX            Recycle          Available                                   8m3s

```
40. Elimine el pv y cualquier otro recurso creado durante este laboratorio.

```
student@cp: ̃$ kubectl delete pv pvvol-1
persistentvolume "pvvol-1" deleted
```

