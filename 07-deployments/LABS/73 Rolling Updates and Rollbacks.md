# Lab 7.3. Rolling Updates and Rollbacks

Una de las ventajas de los microservicios es la capacidad de reemplazar y actualizar un contenedor sin dejar de responder a las solicitudes de los clientes. Usaremos la configuración OnDelete que actualiza un contenedor cuando se elimina el predecesor, luego usaremos la función RollingUpdate también, que inicia una actualización continua de inmediato.


    ```
    versiones de nginx
    El software nginx se actualiza en una línea de tiempo distinta de Kubernetes. Si el laboratorio muestra una versión anterior, use la versión predeterminada actual y luego una versión más nueva. Las versiones se pueden ver con este comando: sudo docker image ls nginx
    ```

1.  Comience por ver la configuración actual de la estrategia de actualización para el DaemonSet creado en la sección anterior.

    ```
    student@cp: ̃$ kubectl get ds ds-one -o yaml | grep -A 4 Strategy

    ....
    updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate 
    ....
    ```

2.  Edite el objeto para usar la estrategia de actualización OnDelete. Esto permitiría la terminación manual de algunos de los pods, lo que daría como resultado una imagen actualizada cuando se vuelvan a crear.

    ```
    student@cp: ̃$ kubectl edit ds ds-one

    ....
    updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: OnDelete #<-- Edit to be this line
    ....
    ```

3.  Actualice DaemonSet para usar una versión más nueva del servidor nginx. Esta vez use el comando establecer en lugar de editar. Configure la versión para que sea 1.16.1-alpine
    ```
    student@cp: ̃$ kubectl set image ds ds-one nginx=nginx:1.16.1-alpine
    daemonset.apps/ds-one image updated
    ```
4.  Verifique que el parámetro Image:para el Pod marcado en la sección anterior no haya cambiado.

    ```
    student@cp: ̃$ kubectl describe po ds-one-b1dcv |grep Image:

    Image:                nginx:1.15.1
    ```

5.  Eliminar el pod. Espere hasta que el Pod de reemplazo se esté ejecutando y verifique la versión.
    ```
    student@cp: ̃$ kubectl delete po ds-one-b1dcv
    pod "ds-one-b1dcv" deleted
    ```

    ```
    student@cp: ̃$ kubectl get pod

    NAME                   READY     STATUS    RESTARTS   AGE
    ds-one-xc86w           1/1       Running   0          19s
    ds-one-z31r4           1/1       Running   0          4m8s
    ```
    ```
    student@cp: ̃$ kubectl describe pod ds-one-xc86w |grep Image:

    Image:                nginx:1.16.1-alpine
    ```
6. Vea la imagen que se ejecuta en el Pod anterior. Todavía debería mostrar la versión 1.15.1.

    ```
    student@cp: ̃$ kubectl describe pod ds-one-z31r4 |grep Image:

    Image:                nginx:1.15.1
    ```

7.  Ver el historial de cambios del DaemonSet. Debería ver dos revisiones en la lista. Como no usamos la opción --record, no vimos por qué se actualizó el objeto.

    ```
    student@cp: ̃$ kubectl rollout history ds ds-one

    daemonsets "ds-one"
    REVISION        CHANGE-CAUSE
    1                <none>
    2                <none>
    ```

8. Vea la configuración de las distintas versiones del DaemonSet. La Image:line debe ser la única diferencia entre las dos salidas

    ```
    student@cp: ̃$ kubectl rollout history ds ds-one --revision=1

    daemonsets "ds-one" with revision #1

    Pod Template:
        Labels:        system=DaemonSetOne
        Containers:
            nginx:
                Image:        nginx:1.15.1
                Port:        80/TCP
                Environment:        <none>
                Mounts:        <none>
        Volumes:        <none>
    ```

    ```
    student@cp: ̃$ kubectl rollout history ds ds-one --revision=2
    ....
    Image:        nginx:1.16.1-alpine
    .....
    ```
9.  Use kubectl rollout undo para cambiar el DaemonSet a una versión anterior. Como todavía estamos usando la estrategia OnDelete, no debería haber cambios en los Pods.

    ```
    student@cp: ̃$ kubectl rollout undo ds ds-one --to-revision=1
    daemonset.apps/ds-one rolled back
    ```
    ```
    student@cp: ̃$ kubectl describe pod ds-one-xc86w |grep Image:
    Image:                nginx:1.16.1-alpine
    ```

10.  Elimine el Pod, espere a que aparezca el reemplazo y luego verifique la versión de la imagen nuevamente.

    ```
    student@cp: ̃$ kubectl delete pod ds-one-xc86w
    pod "ds-one-xc86w" deleted
    ```

    ```
    student@cp: ̃$ kubectl get pod
    NAME                   READY     STATUS        RESTARTS   AGE
    ds-one-qc72k           1/1       Running       0          10s
    ds-one-xc86w           0/1       Terminating   0          12m
    ds-one-z31r4           1/1       Running       0          28m
    ```

    ```
    student@cp: ̃$ kubectl describe po ds-one-qc72k |grep Image:
    Image:                nginx:1.15.1
    ```
11.  Ver los detalles del DaemonSet. La imagen debe ser v1.15.1 en la salida.

    ```
    student@cp: ̃$ kubectl describe ds |grep Image:
    Image:                nginx:1.15.1
    ```

12.  Vea la configuración actual para la salida YAML de DaemonSet. Busque la estrategia de actualización: el tipo:

    ```
    student@cp: ̃$ kubectl get ds ds-one -o yaml
    ```

    ```
    apiVersion: apps/v1
    kind: DaemonSet
    .....
            terminationGracePeriodSeconds: 30
        updateStrategy:
            type: OnDelete
    status:
        currentNumberScheduled: 2
    ...
    ```

13.  Cree un nuevo DaemonSet, esta vez configurando la política de actualización en RollingUpdate. Comience generando un nuevo archivo de configuración.

    ```
    student@cp: ̃$ kubectl get ds ds-one -o yaml  > ds2.yaml
    ```

14.  Edite el archivo. Cambie el nombre, alrededor de la línea 69 y la estrategia de actualización alrededor de la línea 100, de vuelta al RollingUpdate por defecto.

    ```
    student@cp: ̃$ vim ds2.yaml

    ....
    name: ds-two
    ....
    type: RollingUpdate

    ```

15.  Cree el nuevo DaemonSet y verifique la versión de nginx en los nuevos pods

    ```
    student@cp: ̃$ kubectl create -f ds2.yaml
    daemonset.apps/ds-two created
    ```

    ```
    student@cp: ̃$ kubectl get pod
    NAME                   READY     STATUS    RESTARTS   AGE
    ds-one-qc72k           1/1       Running   0          28m
    ds-one-z31r4           1/1       Running   0          57m
    ds-two-10khc           1/1       Running   0          5m
    ds-two-kzp9g           1/1       Running   0          5m
    ```

    ```
    student@cp: ̃$ kubectl describe po ds-two-10khc |grep Image:
    Image:                nginx:1.15.1
    ```

16. Edite el archivo de configuración y establezca la imagen en una versión más reciente, como 1.16.1-alpine. Incluya la opción --record.

    ```
    student@cp: ̃$ kubectl edit ds ds-two --record
    ....
    - image: nginx:1.16.1-alpine
    .....
    ```

17.  Ver la edad de los DaemonSets. Debe tener alrededor de diez minutos, dependiendo de qué tan rápido escribas.

    ```
    student@cp: ̃$ kubectl get ds ds-two
    NAME      DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE-SELECTOR   AGE
    ds-two    2         2         2         2            2           <none>          10m
    ```

18.  Ahora vea la edad de los Pods. Dos deberían ser mucho más jóvenes que el DaemonSet. También tienen unos segundos de diferencia debido a la naturaleza de la actualización continua en la que se terminaba y se recreaba uno y luego el otro pod.


    ```
    student@cp: ̃$ kubectl get pod
    NAME                   READY     STATUS    RESTARTS   AGE
    ds-one-qc72k           1/1       Running   0          36
    mds-one-z31r4           1/1       Running   0          1h
    ds-two-2p8vz           1/1       Running   0          34s
    ds-two-8lx7k           1/1       Running   0          32s
    ```

19.  Verifique que los Pods estén usando la nueva versión del software.

    ```
    student@cp: ̃$ kubectl describe po ds-two-8lx7k |grep Image:
    Image:                nginx:1.16.1-alpine
    ```

20.  Vea el estado de rollout y el historial de los DaemonSets.

    ```
    student@cp: ̃$ kubectl rollout status ds ds-two
    daemon set "ds-two" successfully rolled out
    ```
    ```
    student@cp: ̃$ kubectl rollout history ds ds-two
    daemonsets "ds-two"REVISION        CHANGE-CAUSE
    1                <none>
    2                kubectl edit ds ds-two --record=true
    ```

21.  Ver los cambios en la actualización. Deben tener el mismo aspecto que el historial anterior, pero no es necesario que se eliminen los pods para que se realice la actualización.

    ```
    student@cp: ̃$ kubectl rollout history ds ds-two --revision=2

    ...
    Image:        nginx:1.16.1-alpine
    ```

22.  Limpie el sistema eliminando los DaemonSets.

    ```
    student@cp: ̃$ kubectl delete ds ds-one ds-two

    daemonset.apps "ds-one" deleted
    daemonset.apps "ds-two" deleted
    ```