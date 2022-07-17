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


While we have talked about three services, some build upon others. A Service is an operator running inside the kube-controller-manager, which sends API calls via the kube-apiserver to the Network Plugin (such as Calico) and the kube-proxy pods running all nodes. The Service operator also creates an Endpoint operator, which queries for the ephemeral IP addresses of pods with a particular label. These agents work together to manage firewall rules using iptables or ipvs.

Take a look at the image below. The ClusterIP service configures a persistent IP address and directs traffic sent to that address to the existing pod's ephemeral addresses. This only handles inside the cluster traffic.

When a request for a NodePort is made, the operator first creates a ClusterIP. After the ClusterIP has been created, a high numbered port is determined and a firewall rule is sent out so that traffic to the high numbered port on any node will be sent to the persistent IP, which then will be sent to the pod(s).

A LoadBalancer does not create a load balancer. Instead, it creates a NodePort and makes an async request to use a load balancer. If a listener sees the request, as found when using public cloud providers, one would be created. Otherwise, the status will remain Pending as no load balancer has responded to the API call.

An ingress controller is a microservice running in a pod, listening to a high port on whichever node the pod may be running, which will send traffic to a Service based on the URL requested. It is not a built-in service, but is often used with services to centralize traffic to services. More on an ingress controller is found in a future chapter.


![alt text](https://github.com/castanedara/k8s-certification/blob/main/09-SERVICIOS/bicxpld1h6ar-Service_Relationships.png?raw=true)


Built-In Services

