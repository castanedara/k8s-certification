Exercise 9.3: Working with CoreDNS

1. We can leverage CoreDNS and predictable hostnames instead of IP addresses. A few steps back we created the service-lab NodePort in the Accounting namespace. We will create a new pod for testing using Ubuntu. The pod name will be named nettool.

Podemos aprovechar CoreDNS y hostnames predecibles en lugar de direcciones IP. Unos pasos atrás, creamos el NodePort del laboratorio de servicios en el namespace Accounting. Crearemos un nuevo pod para probar usando Ubuntu. El nombre del pod se llamará nettool.

`student@cp: ̃$ vim nettool.yaml`

**nettool.yaml:**

```
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
spec:
  containers:
  - name: ubuntu
    image: ubuntu:latest
    command: [ "sleep" ]
    args: [ "infinity" ]
```

2. Cree el pod y luego inicie sesión en él.

```
student@cp: ̃$ kubectl create -f nettool.yaml
pod/ubuntu created
```
```
student@cp: ̃$ kubectl exec -it ubuntu -- /bin/bash
```


## On Container
- (a) Agregue algunas herramientas para investigar el DNS y la red. La instalación le preguntará la zona geográfica y la información de la zona horaria (timezone). Alguien en Austin respondería primero 2. América, luego 37 para Chicago, que sería la hora central


`root@ubuntu:/# apt-get update ; apt-get install curl dnsutils -y`

- (b) Utilice el comando **dig** sin opciones. Debería ver los name servers root y luego información sobre la respuesta del servidor DNS, como la dirección IP.
`root@ubuntu:/# dig`

```
; <<>> DiG 9.16.1-Ubuntu <<>>
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 3394
;; flags: qr rd ra; QUERY: 1, ANSWER: 13, AUTHORITY: 0, ADDITIONAL: 1
<output_omitted>
;; Query time: 4 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
;; WHEN: Thu Aug 27 22:06:18 CDT 2020
;; MSG SIZE rcvd: 431
```
- (c) También eche un vistazo al archivo /etc/resolv.conf, que indicará los servidores de nombres y los domains predeterminados para buscar si no usa un nombre distinguido completamente calificado (FQDN - Fully Qualified Distinguished Name). Desde la salida podemos ver que la primera entrada es default.svc.cluster.local.

```
root@ubuntu:/# cat /etc/resolv.conf

nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
c.endless-station-188822.internal google.internal
options ndots:5
```

- (d) Use the dig command to view more information about the DNS server. Us the -x argument to get the FQDN using the IP we know. Notice the domain name, which uses .kube-system.svc.cluster.local., to match the pod namespaces instead of default. Also note the name, kube-dns, is the name of a service not a pod.

Use el comando dig para ver más información sobre el servidor DNS. Usa el argumento -x para obtener el FQDN usando la IP que conocemos. Observe el nombre de dominio (domain), que usa `.kube-system.svc.cluster.local.`, para que coincida con el namespace del pod en lugar del predeterminado. Tenga en cuenta también que el nombre, **kube-dns** , es el nombre de un servicio, no de un pod.


`root@ubuntu:/# dig @10.96.0.10 -x 10.96.0.10`

```
...
;; QUESTION SECTION:
;10.0.96.10.in-addr.arpa. IN PTR
;; ANSWER SECTION:
10.0.96.10.in-addr.arpa.
↪→ 30 IN PTR kube-dns.kube-system.svc.cluster.local.
;; Query time: 0 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
;; WHEN: Thu Aug 27 23:39:14 CDT 2020
;; MSG SIZE rcvd: 139
```

- (e) Recuerde el nombre del service-lab de servicios que creamos y los namespaces en los que se creó. Utilice esta información para crear un FQDN y ver el pod expuesto.

```
root@ubuntu:/# curl service-lab.accounting.svc.cluster.local.
```

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
body {
width: 35em;
margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif;
}
...
```

- (f) Intente ver la página predeterminada usando solo el nombre del servicio. Debería fallar ya que nettool está en el namespace default.


`root@ubuntu:/# curl service-lab`

```
curl: (6) Could not resolve host: service-lab
```

- (g) Agregue los namespaces de accounting al nombre y vuelva a intentarlo. El tráfico puede acceder a un servicio usando un nombre, incluso a través de diferentes namespaces.

```
root@ubuntu:/# curl service-lab.accounting
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<output_omitted>
```

- (h) Salga del contenedor y observe los servicios que se ejecutan dentro del namespace de kube-system. En el resultado, vemos que el servicio kube-dns tiene la IP del servidor DNS y los puertos expuestos que utiliza el DNS.

`root@ubuntu:/# exit`

```
student@cp: ̃$ kubectl -n kube-system get svc

NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
kube-dns ClusterIP 10.96.0.10 <none> 53/UDP,53/TCP,9153/TCP 42h
```

3. Examinar el service en detalle. Entre otra información, observe el selector en uso para determinar los pods con los que se comunica el servicio.


`student@cp: ̃$ kubectl -n kube-system get svc kube-dns -o yaml`

```
...
labels:
k8s-app: kube-dns
kubernetes.io/cluster-service: "true"
kubernetes.io/name: KubeDNS
...
selector:
k8s-app: kube-dns
sessionAffinity: None
type: ClusterIP
...
```

4. Busque pods con las mismas labels en todos los espacios de nombres. Vemos que todos los pods de infraestructura tienen esta label, incluidos ?coredns?

`student@cp: ̃$ kubectl get pod -l k8s-app --all-namespaces`

```
NAMESPACE NAME READY STATUS RESTARTS AGE
kube-system calico-kube-controllers-5447dc9cbf-275fs 1/1 Running 0 41h
kube-system calico-node-6q74j 1/1 Running 0 43h
kube-system calico-node-vgzg2 1/1 Running 0 42h
kube-system coredns-f9fd979d6-4dxpl 1/1 Running 0 41h
kube-system coredns-f9fd979d6-nxfrz 1/1 Running 0 41h
kube-system kube-proxy-f4vxx 1/1 Running 0 41h
kube-system kube-proxy-pdxwd 1/1 Running 0 41h
```

5. Mire los detalles de una de los pods de coredns. Lea las especificaciones del pod y busque la imagen en uso, así como cualquier información de configuración. Debería encontrar que la configuración proviene de un configmap.

`student@cp: ̃$ kubectl -n kube-system get pod coredns-f9fd979d6-4dxpl -o yaml`

```
...
spec:
containers:
- args:
- -conf
- /etc/coredns/Corefile
image: k8s.gcr.io/coredns:1.7.0
...
volumeMounts:
- mountPath: /etc/coredns
name: config-volume
readOnly: true
...
volumes:
- configMap:
defaultMode: 420
items:
- key: Corefile
path: Corefile
name: coredns
name: config-volume
...
```

6. Vea los configmaps en el namespace de kube-system

`student@cp: ̃$ kubectl -n kube-system get configmaps`

```
NAME DATA AGE
calico-config 4 43h
coredns 1 43h
extension-apiserver-authentication 6 43h
kube-proxy 2 43h
kubeadm-config 2 43h
kubelet-config-1.21 1 43h
kubelet-config-1.22 1 41h
```

7. Vea los detalles del configmapn de coredns. Tenga en cuenta que aparece el dominio cluster.local.

`student@cp: ̃$ kubectl -n kube-system get configmaps coredns -o yaml`

```
apiVersion: v1
data:
Corefile: |
.:53 {
errors
health {
lameduck 5s
}
ready
kubernetes cluster.local in-addr.arpa ip6.arpa {
pods insecure
fallthrough in-addr.arpa ip6.arpa
ttl 30
}
prometheus :9153
forward . /etc/resolv.conf {
max_concurrent 1000
}
cache 30
loop
reload
loadbalance
}
kind: ConfigMap
...
```

8. Si bien hay muchas opciones y archivos de zona que podemos configurar, comencemos con una edición simple. Agregue una declaración de reescritura de modo que test.io redirija a cluster.local Se puede encontrar más información sobre cada línea en coredns.io.


`student@cp: ̃$ kubectl -n kube-system edit configmaps coredns`

```
apiVersion: v1
data:
Corefile: |
.:53 {
rewrite name regex (.*)\.test\.io {1}.default.svc.cluster.local #<-- Add this line
errors
health {
lameduck 5s
}
ready
kubernetes cluster.local in-addr.arpa ip6.arpa {
pods insecure
fallthrough in-addr.arpa ip6.arpa
ttl 30
}
prometheus :9153
forward . /etc/resolv.conf {
max_concurrent 1000
}
cache 30
loop
reload
loadbalance
}
```

9. Elimine los pods de coredns para que vuelvan a leer el configmap actualizado.

```
student@cp: ̃$ kubectl -n kube-system delete pod coredns-f9fd979d6-s4j98 coredns-f9fd979d6-xlpzf

pod "coredns-f9fd979d6-s4j98" deleted
pod "coredns-f9fd979d6-xlpzf" deleted
```

10. Cree un nuevo servidor web y cree un servicio ClusterIP para verificar que la dirección funcione. Tenga en cuenta la nueva IP del servicio para comenzar con un reverse lookup.

`student@cp: ̃$ kubectl create deployment nginx --image=nginx`

```
deployment.apps/nginx created
```

`student@cp: ̃$ kubectl expose deployment nginx --type=ClusterIP --port=80`

service/nginx expose

`student@cp: ̃$ kubectl get svc`

```
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
kubernetes ClusterIP 10.96.0.1 <none> 443/TCP 3d15h
nginx ClusterIP 10.104.248.141 <none> 80/TCP 7s
```

11. Inicie sesión en el contenedor de ubuntu y pruebe la reescritura de URL comenzando con la resolución de IP inversa.


`student@cp: ̃$ kubectl exec -it ubuntu -- /bin/bash`

## On Container

- (a) Utilice el comando dig. Tenga en cuenta que el nombre del servicio pasa a formar parte del FQDN.


`root@ubuntu:/# dig -x 10.104.248.141`
```
....
;; QUESTION SECTION:
;141.248.104.10.in-addr.arpa. IN PTR
;; ANSWER SECTION:
141.248.104.10.in-addr.arpa.
30 IN PTR nginx.default.svc.cluster.local.↪→
....
```

- (b) Ahora que tenemos la búsqueda inversa, pruebe la búsqueda directa (forward lookup). La IP debe coincidir con la que usamos en el paso anterior.

`root@ubuntu:/# dig nginx.default.svc.cluster.local.`

```
....
;; QUESTION SECTION:
;nginx.default.svc.cluster.local. IN A
;; ANSWER SECTION:
nginx.default.svc.cluster.local. 30 IN A 10.104.248.141
....
```

- (c) Ahora pruebe para ver si la regla de reescritura para el dominio test.io que agregamos resuelve la IP. Tenga en cuenta que la respuesta usa el nombre original, no el FQDN solicitado.

`root@ubuntu:/# dig nginx.test.io`

```
....
;; QUESTION SECTION:
;nginx.test.io. IN A
;; ANSWER SECTION:
nginx.default.svc.cluster.local. 30 IN A 10.104.248.141
....
```

12. Salga del contenedor y luego edite el configmap para agregar una sección de respuesta.

`student@cp: ̃$ kubectl -n kube-system edit configmaps coredns`

```
....
data:
Corefile: |
.:53 {
rewrite stop { #<-- Edit this and following
two lines↪→
name regex (.*)\.test\.io {1}.default.svc.cluster.local
answer name (.*)\.default\.svc\.cluster\.local {1}.test.io
}
errors
health {
....
```

13. Elimine los pods de coredns nuevamente para asegurarse de que vuelvan a leer el configmap actualizado.

`student@cp: ̃$ kubectl -n kube-system delete pod coredns-f9fd979d6-fv9qn coredns-f9fd979d6-lnxn5`

```
pod "coredns-f9fd979d6-fv9qn" deleted
pod "coredns-f9fd979d6-lnxn5" deleted
```

14. Vuelva a iniciar sesión en el contenedor de ubuntu. Esta vez, la respuesta debe mostrar el FQDN con el FQDN solicitado.

`student@cp: ̃$ kubectl exec -it ubuntu -- /bin/bash`

## On Container

`root@ubuntu:/# dig nginx.test.io`
```
....
;; QUESTION SECTION:
;nginx.test.io. IN A
;; ANSWER SECTION:
nginx.test.io. 30 IN A 10.104.248.141
....
```

15. Salga y elimine el contenedor de herramientas de prueba de DNS para recuperar los recursos.

`student@cp: ̃$ kubectl delete -f nettool.yaml`
