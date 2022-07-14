# Labels

Parte de los metadatos de un objeto es una label. Aunque las labels no son objetos API, son una herramienta importante para la administración de clústeres. Se pueden utilizar para seleccionar un objeto en función de una cadena arbitraria, independientemente del tipo de objeto. Las etiquetas son inmutables a partir de la versión de API apps/v1 .

Cada recurso puede contener labels en sus metadatos. De forma predeterminada, al crear una implementación con kubectl create se agrega una etiqueta, como vimos en:

```
    labels:
        pod-template-hash: "3378155678"
        app: ghost ....
```

Luego podría ver las labels en nuevas columnas (comandos y salidas a continuación): 

`kubectl get pods -l app=ghost`

NAME                    READY  STATUS   RESTARTS  AGE
ghost-3378155678-eq5i6  1/1    Running  0         10m

` kubectl get pods -L app`

NAME                      READY   STATUS    RESTARTS   AGE   APP
dev-web-5747cdddf-24vhq   1/1     Running   0          18m   dev-web
dev-web-5747cdddf-g2n4l   1/1     Running   0          18m   dev-web
dev-web-5747cdddf-q946t   1/1     Running   0          18m   dev-web
dev-web-5747cdddf-z75kx   1/1     Running   0          18m   dev-web
ghost-dc9899fc7-j2df9     1/1     Running   0          18m   ghost

Si bien normalmente define labels en las plantillas de pod y en las especificaciones de los Deployments, también puede agregar labels sobre la marcha (comandos y resultados a continuación):

`kubectl label pods ghost-dc9899fc7-j2df9 foo=bar`

`kubectl get pods --show-labels`

NAME                    READY  STATUS   RESTARTS  AGE  LABELS
ghost-3378155678-eq5i6  1/1    Running  0         11m  foo=bar, pod-template-hash=3378155678,run=ghost

For example, if you want to force the scheduling of a pod on a specific node, you can use a nodeSelector in a pod definition, add specific labels to certain nodes in your cluster and use those labels in the pod. See the following example:

Por ejemplo, si desea forzar el scheduling de un pod en un nodo específico, puede usar un **nodeSelector** en una definición de pod, agregar etiquetas específicas a ciertos nodos en su clúster y usar esas etiquetas en el pod. Vea el siguiente ejemplo:


```
spec:
    containers:
    - image: nginx
    nodeSelector:
        disktype: ssd
```