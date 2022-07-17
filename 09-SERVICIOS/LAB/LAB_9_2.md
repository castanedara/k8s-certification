# Exercise 9.2: Configure a NodePort

En un ejercicio anterior, implementamos un LoadBalancer que implementó un ClusterIP y un NodePort automáticamente. En este ejercicio implementaremos un NodePort. Si bien puede acceder a un contenedor desde dentro del clúster, se puede usar un NodePort para el tráfico NAT desde fuera del clúster. Una razón para implementar un NodePort en su lugar es que un LoadBalancer también es un recurso de balanceador de carga de proveedores de la nube como GKE y AWS.


1. En un paso anterior, pudimos ver la página de nginx usando la dirección IP interna del Pod. Ahora exponga el deployment usando --type=NodePort. También le daremos un nombre fácil de recordar y lo colocaremos en el namespace accounting. También podríamos pasar el puerto, lo que podría ayudar a abrir puertos en el firewall.

```
student@cp: ̃$ kubectl -n accounting expose deployment nginx-one --type=NodePort --name=service-lab
service/service-lab exposed
```

2. Vea los detalles de los servicios en el namespace accounting. Estamos buscando el puerto autogenerado.

```
student@cp: ̃$ kubectl -n accounting describe services
....
NodePort: <unset> 32103/TCP
....
```

3. Locate the exterior facing hostname or IP address of the cluster. The lab assumes use of GCP nodes, which we access via a FloatingIP, we will first check the internal only public IP address. Look for the Kubernetes cp URL. Whichever way you access check access using both the internal and possible external IP address

Localice el hostname o la dirección IP que se muestra hacia el exterior del clúster. El laboratorio asume el uso de nodos GCP, a los que accedemos a través de una IP flotante. Primero verificaremos la dirección IP pública interna. Busque la URL de cp de Kubernetes. Independientemente de la forma en que acceda, verifique el acceso utilizando tanto la dirección IP interna como la posible externa.

```
student@cp: ̃$ kubectl cluster-info
Kubernetes control plane is running at https://k8scp:6443
CoreDNS is running at https://k8scp:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

4. Pruebe el acceso al servidor web nginx usando la combinación de cp URL y NodePort.

```
student@cp: ̃$ curl http://k8scp:32103
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

5. Usando el navegador en su sistema local, use la dirección IP pública que usa para SSH en su nodo y el puerto. Aún debería ver la página predeterminada de nginx. Es posible que pueda usar curl para ubicar su dirección IP pública.

```
student@cp: ̃$ curl ifconfig.io
104.198.192.84
```

