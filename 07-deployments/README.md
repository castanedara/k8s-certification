# ReplicationControllers  (RC)
API apps/v1  : Deployments. 

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

- apiVersion
El valor de v1 indica que este objeto se considera un recurso estable. En este caso, no es el despliegue. Es una referencia al tipo Lista . 

- items
Como la línea anterior es una Lista , declara la lista de elementos que muestra el comando. 

- apiVersion
El guión es una indicación YAML del primer elemento de la lista, que declara la apiVersion del objeto como apps/v1 . Esto indica que el objeto se considera estable. Los deployments son un operador utilizado en muchos casos. 


- kind
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

- annotations
Estos valores no configuran el objeto, pero brindan más información que podría ser útil para las aplicaciones de terceros o el seguimiento administrativo. 
A diferencia de las labels, no se pueden usar para seleccionar un objeto con kubectl.

- creationTimestamp
Muestra cuándo se creó originalmente el objeto. No se actualiza si se edita el objeto.

- generation
Cuántas veces se ha editado este objeto, como cambiar el número de réplicas, por ejemplo.

- labels
Cadenas arbitrarias utilizadas para seleccionar o excluir objetos para su uso con kubectl u otras llamadas a la API. Útil para que los administradores seleccionen objetos fuera de los límites típicos de los objetos.

- name
Esta es una cadena requerida, que pasamos desde la línea de comando. El nombre debe ser único para el espacio de nombres.

- resourceVersion
Un valor vinculado a la base de datos etcd para ayudar con la concurrencia de objetos. Cualquier cambio en la base de datos hará que este número cambie.

- uid
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

- spec
Una declaración de que los siguientes elementos configurarán el objeto que se está creando.

- progressDeadlineSeconds
Tiempo en segundos hasta que se informa un error de progreso durante un cambio. Las razones pueden ser quotas, problemas de imagen o limit ranges.

- replicas
Como el objeto que se crea es un ReplicaSet, este parámetro determina cuántos pods se deben crear. Si usara "kubectl edit" y cambiara este valor a dos, se generaría un segundo Pod.

- revisionHistoryLimit
Cuántas especificaciones antiguas de ReplicaSet conservar para la reversión.

- selector
Una colección de valores combinados con AND. Todos deben estar satisfechos para que la réplica coincida. No cree pods que coincidan con estos selectores, ya que el "deployment controller" puede intentar controlar el recurso y generar problemas.

- matchLabels
Set-based requirements of the Pod selector. Often found with the matchExpressions statement, to further designate where the resource should be scheduled.
Requisitos basados en conjuntos del selector de Pod. A menudo se encuentra con la declaración "matchExpressions", para designar además dónde se debe programar el recurso.

- strategy
A header for values having to do with updating Pods. Works with the later listed type. Could also be set to Recreate, which would delete all existing pods before new pods are created. With RollingUpdate, you can control how many Pods are deleted at a time with the following parameters.
Un encabezado para valores relacionados con la actualización de Pods. Funciona con el tipo listado más tarde. También se podría establecer en Recreate, lo que eliminaría todos los pods existentes antes de que se creen nuevos pods. Con RollingUpdate, puede controlar cuántos pods se eliminan a la vez con los siguientes parámetros.

- maxsurge
Maximum number of Pods over desired number of Pods to create. Can be a percentage, default of 25%, or an absolute number. This creates a certain number of new Pods before deleting old ones, for continued access.
Número máximo de Pods sobre el número deseado de Pods para crear. Puede ser un porcentaje, predeterminado del 25 % o un número absoluto. Esto crea una cierta cantidad de Pods nuevos antes de eliminar los antiguos, para un acceso continuo.

- maxUnavailable
Un número o porcentaje de Pods que pueden estar en un estado distinto de Ready durante el proceso de actualización.

- type
Aunque aparece en último lugar en la sección, debido al nivel de sangría de espacios en blanco, se lee como el tipo de objeto que se está configurando. (por ejemplo, RollingUpdate).

## Deployment Configuration Pod Template
