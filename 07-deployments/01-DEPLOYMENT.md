# ReplicationControllers  (RC)
**API apps/v1  : Deployments**

`kubectl create deployment dev-web --image=nginx:1.13.7-alpine`

## Detalles de implementación
En la página anterior, creamos una nueva implementación que ejecuta una versión particular del servidor web nginx. 
Para generar el archivo YAML de los objetos recién creados, ejecute el siguiente comando:
´kubectl get deployments,rs,pods -o yaml´

A veces, una salida JSON puede hacerlo más claro. Prueba este comando:

`kubectl get deployments,rs,pods -o json`

Ahora veremos la salida YAML, que también muestra los valores predeterminados que no se pasaron al objeto cuando se creó:

```
apiVersion: v1
 items:
 - apiVersion: apps/v1
   kind: Deployment
```

- **apiVersion**
El valor de v1 indica que este objeto se considera un recurso estable. En este caso, no es el despliegue. Es una referencia al tipo Lista . 

- **items**
Como la línea anterior es una Lista , declara la lista de elementos que muestra el comando. 

- **apiVersion**
El guión es una indicación YAML del primer elemento de la lista, que declara la apiVersion del objeto como apps/v1 . Esto indica que el objeto se considera estable. Los deployments son un operador utilizado en muchos casos. 


- **kind**
Aquí es donde se declara el tipo de objeto a crear, en este caso un deployment.


## Deployment Configuration Metadata

Continuando con la salida YAML, vemos que el siguiente bloque general de salida se refiere a los metadatos de la implementación. 
Aquí es donde encontraríamos etiquetas, anotaciones y otra información no relacionada con la configuración. 
Tenga en cuenta que esta salida no mostrará todas las configuraciones posibles. 
Muchas configuraciones que están configuradas como falsas de manera predeterminada no se muestran, como podAffinity o nodeAffinity .

```
metadata:
   annotations:
     deployment.kubernetes.io/revision: "1"
   creationTimestamp: 2017-12-21T13:57:07Z
   generation: 1
   labels:
     app: dev-web
   name: dev-web
   namespace: default
   resourceVersion: "774003"
   uid: d52d3a63-e656-11e7-9319-42010a800003
```

- **annotations**
Estos valores no configuran el objeto, pero brindan más información que podría ser útil para las aplicaciones de terceros o el seguimiento administrativo. 
A diferencia de las labels, no se pueden usar para seleccionar un objeto con kubectl.

- **creationTimestamp**
Muestra cuándo se creó originalmente el objeto. No se actualiza si se edita el objeto.

- **generation**
Cuántas veces se ha editado este objeto, como cambiar el número de réplicas, por ejemplo.

- **labels**
Cadenas arbitrarias utilizadas para seleccionar o excluir objetos para su uso con kubectl u otras llamadas a la API. Útil para que los administradores seleccionen objetos fuera de los límites típicos de los objetos.

- **name**
Esta es una cadena requerida, que pasamos desde la línea de comando. El nombre debe ser único para el espacio de nombres.

- **resourceVersion**
Un valor vinculado a la base de datos etcd para ayudar con la concurrencia de objetos. Cualquier cambio en la base de datos hará que este número cambie.

- **uid**
Sigue siendo una identificación única para la vida del objeto.


## Deployment Configuration Spec
Hay dos declaraciones de especificaciones para la implementación. El primero modificará el ReplicaSet creado, mientras que el segundo pasará la configuración del Pod.

```
spec:  
  progressDeadlineSeconds: 600   
  replicas: 1  
  revisionHistoryLimit: 10   
  selector:     
    matchLabels:       
      app: dev-web  
  strategy:     
    rollingUpdate:       
      maxSurge: 25%        
      maxUnavailable: 25%     
    type: RollingUpdate
```

- **spec**
Una declaración de que los siguientes elementos configurarán el objeto que se está creando.

- **progressDeadlineSeconds**
Tiempo en segundos hasta que se informa un error de progreso durante un cambio. Las razones pueden ser quotas, problemas de imagen o limit ranges.

- **replicas**
Como el objeto que se crea es un ReplicaSet, este parámetro determina cuántos pods se deben crear. Si usara "kubectl edit" y cambiara este valor a dos, se generaría un segundo Pod.

- **revisionHistoryLimit**
Cuántas especificaciones antiguas de ReplicaSet conservar para la reversión.

- **selector**
Una colección de valores combinados con AND. Todos deben estar satisfechos para que la réplica coincida. No cree pods que coincidan con estos selectores, ya que el "deployment controller" puede intentar controlar el recurso y generar problemas.

- **matchLabels**
Set-based requirements of the Pod selector. Often found with the matchExpressions statement, to further designate where the resource should be scheduled.
Requisitos basados en conjuntos del selector de Pod. A menudo se encuentra con la declaración "matchExpressions", para designar además dónde se debe programar el recurso.

- **strategy**
A header for values having to do with updating Pods. Works with the later listed type. Could also be set to Recreate, which would delete all existing pods before new pods are created. With RollingUpdate, you can control how many Pods are deleted at a time with the following parameters.
Un encabezado para valores relacionados con la actualización de Pods. Funciona con el tipo listado más tarde. También se podría establecer en Recreate, lo que eliminaría todos los pods existentes antes de que se creen nuevos pods. Con RollingUpdate, puede controlar cuántos pods se eliminan a la vez con los siguientes parámetros.

- **maxsurge**
Maximum number of Pods over desired number of Pods to create. Can be a percentage, default of 25%, or an absolute number. This creates a certain number of new Pods before deleting old ones, for continued access.
Número máximo de Pods sobre el número deseado de Pods para crear. Puede ser un porcentaje, predeterminado del 25 % o un número absoluto. Esto crea una cierta cantidad de Pods nuevos antes de eliminar los antiguos, para un acceso continuo.

- **maxUnavailable**
Un número o porcentaje de Pods que pueden estar en un estado distinto de Ready durante el proceso de actualización.

- type
Aunque aparece en último lugar en la sección, debido al nivel de sangría de espacios en blanco, se lee como el tipo de objeto que se está configurando. (por ejemplo, RollingUpdate).

## Deployment Configuration Pod Template

A continuación, veremos una plantilla de configuración para implementar los pods. Veremos algunos valores similares.
```
template:
  metadata:
  creationTimestamp: null
    labels:
      app: dev-web
  spec:
    containers:
    - image: nginx:1.17.7-alpine
      imagePullPolicy: IfNotPresent
      name: dev-web
      resources: {}
      terminationMessagePath: /dev/termination-log
      terminationMessagePolicy: File
    dnsPolicy: ClusterFirst
    restartPolicy: Always
    schedulerName: default-scheduler
    securityContext: {}
    terminationGracePeriodSeconds: 30
```

## Explicación de los elementos de configuración
- **template**
Datos que se pasan al **ReplicaSet** para determinar cómo implementar un objeto (en este caso, contenedores).

- **containers**
Palabra clave que indica que los siguientes elementos de esta sangría son para un contenedor.

- **image**
Este es el nombre de la imagen que se pasa al motor del contenedor, normalmente Docker. El motor extraerá la imagen y creará el Pod.

- **imagePullPolicy**
La configuración de la política se transmite al motor del contenedor, sobre cuándo y si una imagen debe descargarse o usarse desde un caché local.

- **name**
El trozo inicial de los nombres de Pod. Se agregará una cadena única.

- **resources**
Por defecto, vacío. Aquí es donde establecería restricciones y configuraciones de recursos, como un límite de CPU o memoria para los contenedores.

- **terminationMessagePath**
Una ubicación personalizable de dónde generar información de éxito o falla de un contenedor.

- **terminationMessagePolicy**
El valor predeterminado es **File**, que contiene el método de finalización. También podría establecerse en **FallbackToLogsOnError**, que usará la última parte del registro del contenedor si el archivo de mensajes está vacío y el contenedor muestra un error.

- **dnsPolicy**
Determina si las consultas de DNS deben ir a **coredns**  o, si se establece en **Default**, usar la configuración de resolución de DNS del nodo.

- **restartPolicy**
¿Debe reiniciarse el contenedor si se elimina? Los reinicios automáticos son parte de la fortaleza típica de Kubernetes.

- **scheduleName**
Permite el uso de un **scheduler/programador** personalizado, en lugar del predeterminado de Kubernetes.

- **securityContext**
Configuración flexible para pasar una o más configuraciones de seguridad, como el contexto de SELinux, los valores de AppArmor, los usuarios y los UID para que los utilicen los contenedores.

- **terminationGracePeriodSeconds**
La cantidad de tiempo de espera para que se ejecute un **SIGTERM** hasta que se use un **SIGKILL** para terminar el contenedor.

## Deployment Configuration Status

La salida de estado se genera cuando se solicita la información:

```
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: 2017-12-21T13:57:07Z
    lastUpdateTime: 2017-12-21T13:57:07Z
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2021-07-29T06:00:24Z"
    lastUpdateTime: "2021-07-29T06:00:33Z"
    message: ReplicaSet "test-5f6778868d" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 2
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2
```

El resultado anterior muestra cómo se vería la misma implementación si el número de réplicas se aumentara a dos. Los tiempos son diferentes a cuando se generó la implementación por primera vez.

- **availableReplicas**
Indica cuántos fueron configurados por el **ReplicaSet**. Esto se compararía con el valor posterior de **readyReplicas**, que se usaría para determinar si todas las réplicas se generaron por completo y sin errores.

- **observedGeneration**
Muestra la frecuencia con la que se ha actualizado la implementación. Esta información se puede utilizar para comprender la situación de despliegue y reversión de la implementación.


## Scaling and Rolling Updates

El servidor API permite que los ajustes de configuración se actualicen para la mayoría de los valores. Hay algunos valores inmutables, que pueden ser diferentes según la versión de Kubernetes que haya implementado. 

Una actualización común es cambiar la cantidad de réplicas en ejecución. Si este número se establece en cero, no habría contenedores, pero aún habría un conjunto de réplicas y una implementación. Este es el proceso de back-end cuando se elimina una implementación. Vea los comandos y salidas que se presentan a continuación:

`kubectl scale deploy/dev-web --replicas=4`

deployment "dev-web" scaled

`kubectl get deployments`

NAME     READY   UP-TO-DATE  AVAILABLE  AGE
dev-web  4/4     4           4          20s


Los valores no inmutables también se pueden editar a través de un editor de texto. Use editar para activar una actualización. Por ejemplo, para cambiar la versión implementada del servidor web nginx a una versión anterior, ejecute este comando (seguido de la salida): 

`kubectl edit deployment nginx`

```
      containers:
      - image: nginx:1.8 #<<---Set to an older version 
        imagePullPolicy: IfNotPresent
                name: dev-web
```
Esto activaría una actualización progresiva del **deployment**. Si bien la implementación mostraría una antigüedad mayor, una revisión de los Pods mostraría una actualización reciente y una versión anterior de la aplicación del servidor web implementada.


## Deployment Rollbacks

Con algunos de los ReplicaSets anteriores de una implementación que se mantienen, también puede relizar un  **roll back** a una revisión anterior escalando hacia arriba o hacia abajo. El número de configuraciones anteriores guardadas es configurable y ha cambiado de una versión a otra. A continuación, analizaremos más de cerca las reversiones mediante la opción **--record** del comando **kubectl create**, que permite la anotación en la definición del recurso (comandos seguidos de la salida).

kubectl get deployments.apps ghost -o yaml > ghost-deploy.yaml
kubectl apply -f ghost-deploy.yaml --record

`kubectl create deploy ghost --image=ghost --record`
`kubectl get deployments ghost -o yaml`

deployment.kubernetes.io/revision: "1" 
kubernetes.io/change-cause: kubectl create deploy ghost --image=ghost --record

Si falla una actualización, debido a una versión de imagen incorrecta, por ejemplo, puede revertir el cambio a una versión funcional con el comando **kubectl rollout undo (seguido de la salida)**:

`kubectl set image deployment/ghost ghost=ghost:09 --all`
`kubectl rollout history deployment/ghost deployments "ghost":`

REVISION   CHANGE-CAUSE
1 ​         kubectl create deploy ghost --image=ghost --record
2          kubectl set image deployment/ghost ghost=ghost:09 --all

`kubectl get pods`

NAME                    READY  STATUS            RESTARTS  AGE
ghost-2141819201-tcths  0/1    ImagePullBackOff  0         1m​

`kubectl rollout undo deployment/ghost ; kubectl get pods`

NAME                    READY  STATUS   RESTARTS  AGE
ghost-3378155678-eq5i6  1/1    Running  0         7s

Puede retroceder a una revisión específica con la opción **--to-revision=2** .


También puede editar el deployment con el comando **kubectl edit**.

También puede pausar un Deployment y luego reanudarlo. Consulte los siguientes dos comandos:


`kubectl rollout pause deployment/ghost`

`​kubectl rollout resume deployment/ghost`

Tenga en cuenta que aún puede realizar una actualización continua en ReplicationControllers con el comando **kubectl rolling-update**, pero esto se realiza en el lado del cliente. Por lo tanto, si cierra su cliente, la actualización continua se detendrá.

