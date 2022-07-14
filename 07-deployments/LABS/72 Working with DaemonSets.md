7.2: Working with DaemonSets

## Exercise 7.2: Working with DaemonSets

Un DaemonSet es un objeto de bucle de vigilancia como un Deployment con el que hemos estado trabajando en el resto de los laboratorios. El DaemonSet garantiza que cuando se agrega un nodo a un clúster, se crearán pods en ese nodo.

Una Deployment solo garantizaría que se cree una cantidad particular de pods en general, varios podrían estar en un solo nodo. 

El uso de un DaemonSet puede ser útil para garantizar que las aplicaciones estén en cada nodo, útil para cosas como métricas y registro, especialmente en clústeres grandes donde el hardware puede cambiarse con frecuencia.

En caso de que se elimine un nodo de un clúster, el DaemonSet se aseguraría de que los pods se recolecten como basura antes de eliminarlos.

A partir de Kubernetes v1.12, el scheduler maneja la implementación de DaemonSet, lo que significa que ahora podemos configurar ciertos nodos para que no tengan un pod de DaemonSet en particular.

Este paso adicional de automatización puede ser útil para usar con productos como ceph, donde a menudo se agrega o elimina almacenamiento, pero quizás entre un subconjunto de hardware. Permiten implementaciones complejas cuando se usan con recursos declarados como memoria, CPU o volúmenes.

1. Comenzamos creando un archivo yaml. En este caso, el tipo se establecería en DaemonSet. Para facilitar el uso, copiaremos el archivo rs.yaml creado anteriormente y haremos un par de ediciones. Eliminar las réplicas: 2 líneas.

```
student@cp: ̃$ cp rs.yaml ds.yaml
student@cp: ̃$ vim ds.yamld 
```

**ds.yamld**
```
kind: DaemonSet
.....
 name: ds-one
.....
  replicas: 2 #<<<----Remove this line
.....  
    system: DaemonSetOne #<<-- Edit both references9....
```

2.  Create and verify the newly formed DaemonSet. There should be one Pod per node in the cluster.

```
student@cp: ̃$ kubectl create -f ds.yaml
daemonset.apps/ds-one created

student@cp: ̃$ kubectl get ds

NAME      DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE-SELECTOR   AGE
ds-one    2         2         2         2            2           <none>          1m
```

```
student@cp: ̃$ kubectl get pod

NAME                   READY     STATUS    RESTARTS   AGE
ds-one-b1dcv           1/1       Running   0          2m
ds-one-z31r4           1/1       Running   0         2m
```

3.  Verifique la imagen que se ejecuta dentro de los Pods. Usaremos esta información en la siguiente sección.

```
student@cp: ̃$ kubectl describe pod ds-one-b1dcv | grep Image:

Image:                nginx:1.15.1

```