
# Exercise 11.1: Service Mesh

```
Si tiene una gran cantidad de servicios para exponer fuera del clúster, o para exponer un puerto de número bajo en el nodo host, puede implementar un ingress controller. Si bien nginx y GCE tienen controladores que se mencionan mucho en Kubernetes.io, hay muchos para elegir. Aún más funcionalidades y métricas provienen del uso de una red de servicios, como Istio, Linkerd, Contour, Aspen u otras

```

1. Instalaremos **linkerd** utilizando sus propios scripts. Hay bastante salida. En lugar de mostrarlo todo, se ha omitido la salida. Mire a través de la salida y asegúrese de que todo tenga una marca de verificación verde. Algunos pasos pueden tardar unos minutos en completarse. Cada comando se enumera aquí para facilitar la instalación. Además, estos pasos se encuentran en el archivo **setupLinkerd.txt**.


```
student@cp:˜$ curl -sL run.linkerd.io/install | sh
student@cp:˜$ export PATH=$PATH:/home/student/.linkerd2/bin
student@cp:˜$ echo "export PATH=$PATH:/home/student/.linkerd2/bin" >> $HOME/.bashrc
student@cp:˜$ linkerd check --pre
#student@cp:˜$ linkerd install | kubectl apply -f -
student@cp:˜$ linkerd install --set proxyInit.runAsRoot=true  | kubectl apply -f -
student@cp:˜$ linkerd check
student@cp:˜$ linkerd viz install | kubectl apply -f -
student@cp:˜$ linkerd viz check
student@cp:˜$ linkerd viz dashboard &
```

2. By default the GUI is on available on the localhost. We will need to edit the service and the deployment to allow outside access, in case you are using a cloud provider for the nodes. Edit to remove all characters after equal sign for -enforced-host, which is around line 59.

De forma predeterminada, la GUI está disponible en localhost. Tendremos que editar el servicio y el deployment para permitir el acceso externo, en caso de que esté utilizando un proveedor de nube para los nodos. Edite para eliminar todos los caracteres después del signo igual para -enforced-host, que está alrededor de la línea 59.

`student@cp:˜$ kubectl -n linkerd-viz edit deploy web`
```
1 spec:
2 containers:
3 - args:
4 - -linkerd-controller-api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085
5 - -linkerd-metrics-api-addr=metrics-api.linkerd-viz.svc.cluster.local:8085
6 - -cluster-domain=cluster.local
7 - -grafana-addr=grafana.linkerd-viz.svc.cluster.local:3000
8 - -controller-namespace=linkerd
9 - -viz-namespace=linkerd-viz
10 - -log-level=info
11 - -enforced-host= #<-- Remove everything after equal sign
12 image: cr.l5d.io/linkerd/web:stable-2.11.1
13 imagePullPolicy: IfNotPresent
```

```
        - -enforced-host=^(localhost|127\.0\.0\.1|web\.linkerd-viz\.svc\.cluster\.local|web\.linkerd-viz\.svc|\[::1\])(:\d+)?$
```

3. Ahora edite el puerto de nodo http y escriba para que sea un puerto de nodo.

`student@cp:˜$ kubectl edit svc web -n linkerd-viz`

```

2 ports:
3 - name: http
4 nodePort: 31500 #<-- Add line with an easy to remember port
5 port: 8084
6 ....
7 sessionAffinity: None
8 type: NodePort #<-- Edit type to be NodePort
9 status:
10 loadBalancer: {}
11 ....
```

4. Prueba el acceso usando un navegador local a tu IP pública. Su IP será diferente a la que se muestra a continuación.
```
student@cp:˜$ curl ifconfig.io
104.197.159.20
```

5. Desde su sistema local, abra un navegador y vaya a la IP pública y al puerto de nodo de número alto.

![LAB1-1.PNG](https://github.com/castanedara/k8s-certification/blob/main/11-INGRESS/LAB1-1.PNG?raw=true)

6. Para que linkerd preste atención a un objeto, debemos agregar una anotación. El comando de inyección de linkerd hará esto por nosotros. Genere YAML y canalícelo a linkerd y luego vuelva a canalizarlo a kubectl. Espere un error sobre cómo se creó el objeto, pero el proceso funcionará. El comando puede ejecutarse en una línea si omite la barra invertida. Vuelva a crear la implementación de nginx-one con la que trabajamos en un ejercicio de laboratorio anterior.

```
student@cp:˜$ kubectl -n accounting get deploy nginx-one -o yaml | \
linkerd inject - | kubectl apply -f -

<output_omitted>
```

7. Check the GUI, you should see that the accounting namespaces and pods are now meshed, and the name is a link.
Verifique la GUI, debería ver que los namespaces y los pods de accounting ahora están entrelazados, y el nombre es un link.

8. Generate some traffic to the pods, and watch the traffic via the GUI. Use the service-lab service.
Genere algo de tráfico a los pods y observe el tráfico a través de la GUI. Utilice el servicio de laboratorio de servicio.
`student@cp:˜$ kubectl -n accounting get svc`

```
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
nginx-one ClusterIP 10.107.141.227 <none> 8080/TCP 5h15m
service-lab NodePort 10.102.8.205 <none> 80:30759/TCP 5h14m
```
`student@cp:˜$ curl 10.102.8.205`

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<output_omitted>
```

![LAB1-2.PNG](https://github.com/castanedara/k8s-certification/blob/main/11-INGRESS/LAB1-2.PNG?raw=true)


9. Amplíe el deployment de nginx-one. Genere tráfico para obtener métricas de todos los pods.

`student@cp:˜$ kubectl -n accounting scale deploy nginx-one --replicas=5`

```
deployment.apps/nginx-one scaled
```

`student@cp:˜$ curl 10.102.8.205 #Several times`

10. Explore some of the other information provided by the GUI. Note that the initial view is of the default namespaces. Change to accounting to see details of the nginx-one deployment.

Explore parte de la otra información proporcionada por la GUI. Tenga en cuenta que la vista inicial es del namespaces default. Cambie a accounting para ver los detalles de la implementación de nginx-one


![LAB1-3.PNG](https://github.com/castanedara/k8s-certification/blob/main/11-INGRESS/LAB1-3.PNG?raw=true)
