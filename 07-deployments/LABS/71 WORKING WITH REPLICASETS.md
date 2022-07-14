**Overview**

Comprender y administrar el estado de los contenedores es una tarea central de Kubernetes. En esta práctica de laboratorio, primero exploraremos los objetos de la API que se usan para administrar grupos de contenedores. Los objetos disponibles han cambiado a medida que Kubernetes ha madurado, por lo que la versión de Kubernetes en uso determinará cuáles están disponibles. Nuestro primer objeto será un ReplicaSet, que no incluye funciones de administración más nuevas que se encuentran con los Deployments. Un operador de Deployment administra los operadores de ReplicaSet por usted. También trabajaremos con otro objeto y observaremos un bucle llamado DaemonSet que garantiza que un contenedor se esté ejecutando en un nodo recién agregado. Luego, actualizaremos el software en un contenedor, veremos el historial de revisiones y retrocederemos a una versión anterior.

Un ReplicaSet es la próxima generación de un controlador de replicación, que difiere solo en los selectores admitidos. La única razón para usar más un ReplicaSet es si no necesita actualizar el software del contenedor o si requiere una orquestación de actualizaciones que no funcionará con el proceso típico.


1. Ver cualquier **currentReplicaSets**. Si eliminó recursos al final de un laboratorio anterior, no debería tener ninguno informado en el namespace predeterminado

    - `student@cp: ̃$ kubectl get rs`

      `No resources found in default namespace.`


2.  Create a YAML file for a simpleReplicaSet.  TheapiVersionsetting depends on the version of Kubernetes you areusing. The object is stable using theapps/v1apiVersion. We will use an older version ofnginxthen update to a newerversion later in the exercise.

2. Cree un archivo YAML para un ReplicaSet simple. La configuración de apiVersion depende de la versión de Kubernetes que esté utilizando. El objeto es estable con **apiVersion apps/v1**. Usaremos una versión anterior de nginx y luego actualizaremos a una versión más nueva más adelante en el ejercicio.

    - `student@cp: ̃$ vim rs.yaml`

        ```
        apiVersion: apps/v1
        kind: ReplicaSet
        metadata:
        name: rs-one
        spec:
        replicas: 2
        selector:
            matchLabels:
            system: ReplicaOne
        template:
            metadata:
            labels:
                system: ReplicaOne
            spec:
            containers:
            - name: nginx
                image: nginx:1.15.1
                ports:
                - containerPort: 80
        ```
3.  Crear el ReplicaSet:

    `student@cp: ̃$ kubectl create -f rs.yaml`

4. Ver el ReplicaSet recién creado

    `student@cp: ̃$ kubectl describe rs rs-one`

```
Name:         rs-one
Namespace:    default
Selector:     system=ReplicaOne
Labels:       <none>
Annotations:  <none>
Replicas:     2 current / 2 desired
Pods Status:  0 Running / 2 Waiting / 0 Succeeded / 0 Failed
Pod Template:
Labels:  system=ReplicaOne
Containers:
nginx:
Image:        nginx:1.15.1
Port:         80/TCP
Host Port:    0/TCP
Environment:  <none>
Mounts:       <none>
Volumes:        <none>
Events:
Type    Reason            Age   From                   Message
----    ------            ----  ----                   -------
Normal  SuccessfulCreate  11s   replicaset-controller  Created pod: rs-one-q85dr
Normal  SuccessfulCreate  11s   replicaset-controller  Created pod: rs-one-vj744

```

5. Vea los pods creados con el ReplicaSet. Desde el archivo yaml creado, debe haber dos Pods. Es posible que vea un cuadro Completamente ocupado que se borrará eventualmente

    `student@cp: ̃$ kubectl get pods`

```
NAME                      READY   STATUS    RESTARTS   AGE
rs-one-q85dr              1/1     Running   0          114s
rs-one-vj744              1/1     Running   0          114s
```
6. Ahora eliminaremos el ReplicaSet, pero no los Pods que controla.

    `student@cp: ̃$ kubectl delete rs rs-one --cascade=orphan`

    `replicaset.apps "rs-one" deleted`

7. Vuelva a ver el ReplicaSet y los pods:

`student@cp: ̃$ kubectl describe rs rs-one`

`Error from server (NotFound): replicasets.apps "rs-one" not found`

`student@cp: ̃$ kubectl get pods`

```
NAME           READY     STATUS    RESTARTS   AGErs-one-2p9x4   1/1       Running   0         7m
rs-one-3c6pb   1/1       Running   0          7m
```

8. Vuelva a crear el ReplicaSet. Siempre que no cambiemos el campo de selector, el nuevo ReplicaSet debería tomar posesión. Las versiones de software de pod no se pueden actualizar de esta manera.

    `student@cp: ̃$ kubectl create -f rs.yaml`

    `replicaset.apps/rs-one created`

9. Vea la edad(age) del ReplicaSet y luego los pods con:

`student@cp: ̃$ kubectl get rs`

```
NAME      DESIRED   CURRENT   READY     AGErs-one    2         2         2         46s
```

`student@cp: ̃$ kubectl get pods`

```
NAME           READY     STATUS    RESTARTS   AGErs-one-2p9x4   1/1       Running   0          8mrs-one-3c6pb   1/1       Running   0          8m
```

10. Ahora aislaremos un Pod de su ReplicaSet. Comience editando la etiqueta de un Pod. Cambiaremos el parámetro system: a IsolatedPod.

    `student@cp: ̃$ kubectl edit pod rs-one-3c6pb`

    ```
    labels:system: IsolatedPod   #<-- Change from ReplicaOnemanagedFields:
    ```

11. Vea la cantidad de pods dentro del ReplicaSet. Deberías ver dos corriendo.

    `student@cp: ̃$ kubectl get rs`

    ```
    NAME      DESIRED   CURRENT   READY     AGE
    rs-one    2         2         2         4m
    ```

12. Ahora vea los pods con la clave de label system. Debe tener en cuenta que hay tres, y uno es más nuevo que los demás. El ReplicaSet se aseguró de mantener dos réplicas, reemplazando el Pod que estaba aislado.

`student@cp: ̃$ kubectl get po -L system`

```
NAME           READY     STATUS    RESTARTS   AGE       SYSTEM
rs-one-3c6pb   1/1       Running   0          10m       IsolatedPod
rs-one-2p9x4   1/1       Running   0          10m       ReplicaOne
rs-one-dq5xd   1/1       Running   0          30s       ReplicaOne
```
13. Elimine el ReplicaSet, luego vea los pods restantes.

    ```
    student@cp: ̃$ kubectl delete rs rs-one`

    replicaset.apps "rs-one" deleted`
    ```

    ```
    student@cp: ̃$ kubectl get po

    NAME           READY     STATUS        RESTARTS   AGE
    rs-one-3c6pb   1/1       Running       0          14m
    rs-one-dq5xd   0/1       Terminating   0          4m

    ``` 

14. En el ejemplo anterior, los Pods no habían terminado de finalizar. Espera un poco y vuelve a comprobar. No debe haber conjuntos de réplicas, sino un pod.

    ```
    student@cp: ̃$ kubectl get rs
    No resources found in default namespaces.
    ```

    ```
    student@cp: ̃$ kubectl get pod
    NAME           READY     STATUS    RESTARTS   AGE
    rs-one-3c6pb   1/1       Running   0          16m
    ```
15. Elimine el Pod restante usando la etiqueta.

```
student@cp: ̃$ kubectl delete pod -l system=IsolatedPod

pod "rs-one-3c6pb" deleted
```
