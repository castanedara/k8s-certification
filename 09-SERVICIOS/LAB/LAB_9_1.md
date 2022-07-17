# Exercise 9.1: Deploy A New Service

## Overview

Los **Servicios** (también llamados **microservices**) son objetos que declaran una política para acceder a un conjunto lógico de pods. Por lo general, se les asignan etiquetas para permitir el acceso persistente a un recurso, cuando los contenedores de front-end o back-end se terminan y reemplazan.

Las aplicaciones nativas pueden usar la API de Endpoints para acceder. Las aplicaciones no nativas(Non-native) pueden usar un puente basado en IP virtual (**Virtual IP-based bridge**) para acceder a los módulos de back-end. ServiceTypes El tipo podría ser:

- **ClusterIP** predeterminado: expone en una IP interna del clúster. Solo accesible dentro del clúster
- **NodePort** Expone la IP del nodo en un puerto estático. También se crea automáticamente un ClusterIP.
- **LoadBalancer** Expone el servicio externamente usando el balanceador de carga de los proveedores de la nube. NodePort y ClusterIP creados automáticamente.
- **ExternalName** Servicio de mapas a contenido de externalName usando un registro CNAME.

Utilizamos los servicios como parte del desacoplamiento, de modo que cualquier agente u objeto pueda reemplazarse sin interrupción para acceder desde el cliente a la aplicación de back-end.

1. Implemente dos servidores nginx con kubectl y un nuevo archivo .yaml. El tipo debe ser Deployment y etiquetarlo con nginx. Cree dos réplicas y exponga el puerto 8080. Lo que sigue es un archivo bien documentado. No es necesario incluir los comentarios al crear el archivo. Este archivo también se puede encontrar entre los otros ejemplos en el tarball.

`student@cp: ̃$ vim nginx-one.yaml`

**nginx-one.yaml**

```
apiVersion: apps/v1
# Determines YAML versioned schema.
kind: Deployment
# Describes the resource defined in this file.
metadata:
  name: nginx-one
  labels:
    system: secondary
# Required string which defines object within namespace.
  namespace: accounting
# Existing namespace resource will be deployed into.
spec:
  selector:
    matchLabels:
      system: secondary
# Declaration of the label for the deployment to manage
  replicas: 2
# How many Pods of following containers to deploy
  template:
    metadata:
      labels:
        system: secondary
# Some string meaningful to users, not cluster. Keys
# must be unique for each object. Allows for mapping
# to customer needs.
    spec:
      containers:
# Array of objects describing containerized application with a Pod.
# Referenced with shorthand spec.template.spec.containers
      - image: nginx:1.20.1
# The Docker image to deploy
        imagePullPolicy: Always
        name: nginx
# Unique name for each container, use local or Docker repo image
        ports:
        - containerPort: 8080
          protocol: TCP
# Optional resources this container may need to function.
      nodeSelector:
        system: secondOne
# One method of node affinity.
```


2. Vea las etiquetas existentes en los nodos del clúster.

`student@cp: ̃$ kubectl get nodes --show-labels`

```
<output_omitted>
```

3. Ejecute el siguiente comando y busque los errores. Suponiendo que no haya ningún error tipográfico, debería haber recibido un error sobre el namespace accounting.

`student@cp: ̃$ kubectl create -f nginx-one.yaml`

```
Error from server (NotFound): error when creating
"nginx-one.yaml": namespaces "accounting" not found
```
4. Cree el namespace e intente crear el deployment nuevamente. No debería haber errores esta vez.

```
student@cp: ̃$ kubectl create ns accounting
namespace/accounting" created
```
```
student@cp: ̃$ kubectl create -f nginx-one.yaml
deployment.apps/nginx-one created
```

5. Ver el estado de los nuevos pods. Tenga en cuenta que no muestran un estado Running.

```
student@cp: ̃$ kubectl -n accounting get pods
NAME READY STATUS RESTARTS AGE
nginx-one-74dd9d578d-fcpmv 0/1 Pending 0 4m
nginx-one-74dd9d578d-r2d67 0/1 Pending 0 4m
```

6. Vea el nodo al que se ha asignado cada uno (o no) y el motivo, que se muestra debajo de los eventos (Events) al final de la salida.

```
student@cp: ̃$ kubectl -n accounting describe pod nginx-one-74dd9d578d-fcpmv
```

```
Name: nginx-one-74dd9d578d-fcpmv
Namespace: accounting
Node: <none>
<output_omitted>
Events:
Type Reason Age From ....
---- ------ ---- ----
Warning FailedScheduling <unknown> default-scheduler
0/2 nodes are available: 2 node(s) didn't match node selector.
```

7. Etiquete con un Label el nodo secundario. Tenga en cuenta que el valor distingue entre mayúsculas y minúsculas. Verifique las labels.

```
student@cp: ̃$ kubectl label node worker system=secondOne
node/worker labeled
```

```
student@cp: ̃$ kubectl get nodes --show-labels

NAME STATUS ROLES AGE VERSION LABELS
k8scp Ready control-plane,master 15h v1.23.1 beta.kubernetes.io/arch=amd64,
beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8scp,
kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node-role.kubernetes.io/master=,
node.kubernetes.io/exclude-from-external-load-balancers=
worker Ready <none> 15h v1.23.1 beta.kubernetes.io/arch=amd64,
beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker,
kubernetes.io/os=linux,system=secondOne
```

8. Vea los pods en el namespace accounting. Es posible que aún se muestren como Pending. Dependiendo de cuánto tiempo haya pasado desde que intentó implementar, es posible que el sistema no haya buscado la etiqueta. Si los pods muestran Pendiente después de un minuto, elimine uno de los pods. Ambos deberían mostrarse en Running después de una eliminación. Un cambio de estado hará que el Deployment controller verifique el estado de ambos pods.



```
student@cp: ̃$ kubectl -n accounting get pods
NAME READY STATUS RESTARTS AGE
nginx-one-74dd9d578d-fcpmv 1/1 Running 0 10m
nginx-one-74dd9d578d-sts5l 1/1 Running 0 3s
```

9. Ver pods por la label que configuramos en el archivo YAML. Si mira hacia atrás, a los Pods se les dio una label de app=nginx.

```
student@cp: ̃$ kubectl get pods -l system=secondary --all-namespaces
NAMESPACE NAME READY STATUS RESTARTS AGE
accounting nginx-one-74dd9d578d-fcpmv 1/1 Running 0 20m
accounting nginx-one-74dd9d578d-sts5l 1/1 Running 0 9m
```

10. Recuerde que expusimos el puerto 8080 en el archivo YAML. Exponga el nuevo deployment.

```
student@cp: ̃$ kubectl -n accounting expose deployment nginx-one
service/nginx-one exposed
```

11. Vea los endpoints recién expuestos. Tenga en cuenta que el puerto 8080 se ha expuesto en cada Pod.

`student@cp: ̃$ kubectl -n accounting get ep nginx-one`

```
NAME ENDPOINTS AGE
nginx-one 192.168.1.72:8080,192.168.1.73:8080 47s
```

12. Intente acceder al Pod en el puerto 8080, luego en el puerto 80. Aunque expusimos el puerto 8080 del contenedor, la aplicación dentro no se configuró para escuchar en este puerto. El servidor nginx escucha en el puerto 80 de forma predeterminada. Un comando curl a ese puerto debería devolver la típica página de bienvenida.

```
student@cp: ̃$ curl 192.168.1.72:8080
curl: (7) Failed to connect to 192.168.1.72 port 8080: Connection refused
```

```
student@cp: ̃$ curl 192.168.1.72:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<output_omitted>
```

13. Eliminar el deployment. Edite el archivo YAML para exponer el puerto 80 y vuelva a crear el deployment.


student@cp: ̃$ kubectl -n accounting delete deploy nginx-one deployment.apps "nginx-one" deleted

```
student@cp: ̃$ vim nginx-one.yaml
```
**nginx-one.yaml:**
```
1 ....
2 ports:
3 - containerPort: 8080 #<-- Edit this line
4 protocol: TCP
5 ....
```

```
student@cp: ̃$ kubectl create -f nginx-one.yaml
deployment.apps/nginx-one created
```