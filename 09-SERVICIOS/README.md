## Introducción
Objetivos de aprendizaje
Al final de este capítulo, usted debería ser capaz de:

- Explicar los servicios de Kubernetes.
- Exponer una aplicación.
- Discuta los tipos de servicio disponibles.
- Inicie un proxy local.
- Utilice el DNS del clúster.


# Visión general


Como se mencionó anteriormente, la arquitectura de Kubernetes se basa en el concepto de objetos transitorios y desacoplados conectados entre sí. Los servicios son los agentes que conectan los Pods entre sí, o brindan acceso fuera del clúster, con la idea de que cualquier Pod en particular podría terminarse y reconstruirse. Por lo general, al usar etiquetas/Labels, el pod actualizado se conecta y el microservicio continúa brindando el recurso esperado a través de un objeto Endpoint . Google ha estado trabajando en **Extensible Service Proxy (ESP)**, basado en el servidor proxy inverso HTTP nginx, para proporcionar un objeto más flexible y potente que los Endpoints, pero ESP no se ha adoptado mucho fuera de los entornos de Google App Engine o GKE. 

Hay varios tipos de servicios diferentes, con la flexibilidad de agregar más, según sea necesario. Cada servicio se puede exponer interna o externamente al clúster. Un servicio también puede conectar recursos internos a un recurso externo, como una base de datos de terceros. 

El agente **kube-proxy** observa la API de Kubernetes en busca de nuevos servicios y endpoints que se crean en cada nodo. Abre puertos aleatorios y escucha el tráfico en ClusterIP:Port , y redirige el tráfico a los endpoints de servicio generados aleatoriamente.

Los servicios proporcionan equilibrio de carga automático, haciendo coincidir una consulta de etiqueta. Si bien no hay configuración de esta opción, existe la posibilidad de afinidad de sesión vía IP. También se puede configurar un servicio headless, sin IP fija ni balanceo de carga. 

Las direcciones IP únicas se asignan y configuran a través de la base de datos etcd, de modo que los Servicios implementen iptables para enrutar el tráfico, pero podrían aprovechar otras tecnologías para brindar acceso a los recursos en el futuro.

# Patrón de actualización del servicio / Service Update Pattern

Las Labels se utilizan para determinar qué pods deben recibir tráfico de un servicio. Como hemos aprendido, las Labels se pueden actualizar dinámicamente para un objeto, lo que puede afectar qué Pods continúan conectándose a un servicio. 

The default update pattern is for a rolling deployment, where new Pods are added, with different versions of an application, and due to automatic load balancing, receive traffic along with previous versions of the application. 

El patrón de actualización predeterminado es para una implementación continua, donde se agregan nuevos pods, con diferentes versiones de una aplicación y, debido al equilibrio de carga automático, reciben tráfico junto con las versiones anteriores de la aplicación. 

Si hubiera una diferencia en las aplicaciones implementadas, de modo que los clientes tuvieran problemas para comunicarse con diferentes versiones, puede considerar una label más específica para la **implementación/deployment**, que incluye un número de versión. Cuando el deployment crea un nuevo **replication controller** para la actualización, la etiqueta no coincidiría. Una vez que se hayan creado los nuevos Pods, y tal vez se les haya permitido inicializarse por completo, editaríamos las etiquetas para las que se conecta el Servicio. El tráfico cambiaría a la versión nueva y lista, minimizando la confusión de la versión del cliente.

# Accessing an Application with a Service / Acceso a una aplicación con un servicio

El paso básico para acceder a un nuevo servicio es utilizar kubectl . Consulte los siguientes comandos y salidas:

`$ kubectl expose deployment/nginx --port=80 --type=NodePort`

`$ kubectl get svc`
```
NAME        TYPE       CLUSTER-IP  EXTERNAL-IP  PORT(S)        AGE
kubernetes  ClusterIP  10.0.0.1    <none>       443/TCP        18h
nginx       NodePort   10.0.0.112  <none>       80:31230/TCP   5s
```

`$ kubectl get svc nginx -o yaml`

```
apiVersion: v1
kind: Service
...
spec:
    clusterIP: 10.0.0.112
    ports:
    - nodePort: 31230
...

```
**Open browser http://Public-IP:31230.**

The kubectl expose command created a service for the nginx deployment. This service used port 80 and generated a random port on all the nodes. A particular port and targetPort can also be passed during object creation to avoid random values. The targetPort defaults to the port, but could be set to any value, including a string referring to a port on a backend Pod. Each Pod could have a different port, but traffic is still passed via the name. Switching traffic to a different port would maintain a client connection, while changing versions of software, for example.

El comando **kubectl expose** creó un service para el deployment de nginx. Este servicio usaba el puerto 80 y generaba un puerto aleatorio en todos los nodos. También se puede pasar un puerto particular y targetPort durante la creación del objeto para evitar valores aleatorios. Por defecto, targetPort es el puerto, pero se puede establecer en cualquier valor, incluida una cadena que se refiera a un puerto en un pod de backend. Cada pod podría tener un puerto diferente, pero el tráfico aún se transmite a través del nombre. Cambiar el tráfico a un puerto diferente mantendría una conexión de cliente, mientras cambia las versiones de software, por ejemplo.

El comando **kubectl get svc** le proporcionó una lista de todos los servicios existentes y vimos el servicio nginx , que se creó con una IP de clúster interna.

El rango de direcciones IP del clúster y el rango de puertos utilizados para el NodePort aleatorio se pueden configurar en las opciones de inicio del **API server**.

Los servicios también se pueden usar para apuntar a un servicio en un namespace diferente, o incluso a un recurso fuera del clúster, como una aplicación legacy/heredada que aún no está en Kubernetes.

# Tipos de servicio

**Service Types:**

- **ClusterIP**
El tipo de servicio ClusterIP es el predeterminado y solo proporciona acceso internamente (excepto si se crea manualmente un endpoint externo). El rango de ClusterIP utilizado se define a través de una opción de inicio del **API server**.
- **NodePort**
El tipo NodePort es excelente para la depuración o cuando se necesita una dirección IP estática, como abrir una dirección particular a través de un firewall. El rango de NodePort se define en la configuración del clúster.
- **LoadBalancer**
El servicio LoadBalancer se creó para pasar requests a un proveedor de la nube como GKE o AWS. Las soluciones de nube privada también pueden implementar este tipo de servicio si hay un plugin de proveedor de nube, como con CloudStack y OpenStack. Incluso sin un proveedor de nube, la dirección se pone a disposición del tráfico público y los paquetes se distribuyen automáticamente entre los Pods de la implementacion (deployment).
- **ExternalName**
Un servicio más nuevo es ExternalName, que es un poco diferente. No tiene selectores, ni define puertos o endpoints. Permite el retorno de un alias a un servicio externo. La redirección ocurre a nivel de DNS, no a través de un proxy o forward. Este objeto puede ser útil para los servicios que aún no se han incorporado al clúster de Kubernetes. Un simple cambio de tipo en el futuro redirigiría el tráfico a los objetos internos.

El comando **kubectl proxy** crea un servicio local para acceder a un **ClusterIP**. Esto puede ser útil para la resolución de problemas/(troubleshooting) o el trabajo de desarrollo.

# Tipos de servicio (continuación)


Si bien hemos hablado de tres servicios, algunos se basan en otros. Un servicio es un operador que se ejecuta dentro de **kube-controller-manager**, que envía llamadas API a través de **kube-apiserver** al Plugin de red (como Calico) y los pods de **kube-proxy** que se ejecutan en todos los nodos. El **Service operator** también crea un **Endpoint operator**, que consulta las direcciones IP efímeras de los pods con una **Etiqueta/label** particular. Estos agentes trabajan juntos para administrar las reglas del firewall mediante iptables o ipvs.

Hecha un vistazo a la imagen de abajo. El servicio ClusterIP configura una dirección IP persistente y dirige el tráfico enviado a esa dirección a las direcciones efímeras del pod existente. Esto solo maneja dentro del tráfico del clúster.

Cuando se realiza un request de NodePort, el operador primero crea un ClusterIP. Una vez que se ha creado el ClusterIP, se determina un puerto de número alto y se envía una regla de firewall para que el tráfico al puerto de número alto en cualquier nodo se envíe a la IP persistente, que luego se enviará a los pods.

Un LoadBalancer no crea un balanceador de carga. En su lugar, crea un NodePort y realiza una solicitud asíncrona para usar un balanceador de carga. Si un listener/oyente ve la solicitud, tal como se encuentra al usar proveedores de nube pública, se creará una. De lo contrario, el estado seguirá siendo Pendiente ya que ningún balanceador de carga ha respondido a la llamada a la API.

An ingress controller is a microservice running in a pod, listening to a high port on whichever node the pod may be running, which will send traffic to a Service based on the URL requested. It is not a built-in service, but is often used with services to centralize traffic to services. More on an ingress controller is found in a future chapter.

Un ingress controller es un microservicio que se ejecuta en un pod, escuchando un puerto alto en cualquier nodo que se esté ejecutando el pod, que enviará tráfico a un servicio según la URL solicitada. No es un **servicio integrado (built-in service)**, pero a menudo se usa con servicios para centralizar el tráfico a los servicios. Más información sobre un controlador de ingreso se encuentra en un capítulo futuro.


![SERVICIOS](https://github.com/castanedara/k8s-certification/blob/main/09-SERVICIOS/bicxpld1h6ar-Service_Relationships.png?raw=true)


**Built-In Services**

# Diagrama de servicios

Los controladores de servicios y endpoints se ejecutan dentro de **kube-controller-manager** y envían llamadas API a **kube-apiserver**. Luego, las llamadas API se envían al plugin de red, como **calico-kube-controller**, que luego se comunica con los agentes en cada nodo, como **calico-node**. Cada **kube-proxy** también recibe una llamada API para que pueda administrar el firewall localmente. El firewall suele ser iptables o ipvs. El modo **kube-proxy** se configura a través de un indicador enviado durante la inicialización, como **mode=iptables**, y también podría ser **IPVS** o **userspace**.


![DIAGRAMA DE SERVICIOS](https://raw.githubusercontent.com/castanedara/k8s-certification/main/09-SERVICIOS/g7mn32prjgih-ServicesDiagramProxy.png)


**Service Traffic**

En el **proxy mode** de **iptables**, kube-proxy continúa recibiendo actualizaciones del servidor API para los cambios en los objetos de servicio y Endpoint, y actualiza las reglas para cada objeto cuando se crea o elimina. 

El gráfico anterior muestra dos workers, cada uno con una réplica de MyApp en ejecución. Se ha configurado un **NodePort**, que dirigirá el tráfico desde el puerto 35001 al **ClusterIP** y luego a la IP efímera del pod. Todos los nodos usan la misma regla de firewall. Como resultado, puede conectarse a cualquier nodo y **Calico** llevará el tráfico a un nodo que esté ejecutando el pod.


# Vista general de la red

An example of a multi-container pod with two services sending traffic to its ephemeral IP can be seem in the diagram below. The diagram also shows an ingress controller, which would typically be represented as a pod, but has a different shape to show that it is listening to a high numbered port of an interface and is sending traffic to a service. Typically, the service the ingress controller sends traffic to would be a ClusterIP, but the diagram shows that it would be possible to send traffic to a NodePort or a LoadBalancer.

![DIAGRAMA DE SERVICIOS](https://raw.githubusercontent.com/castanedara/k8s-certification/main/09-SERVICIOS/k9384xxsvbjw-Service_Network.png)
