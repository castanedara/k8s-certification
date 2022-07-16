# Exercise 8.1: Create a ConfigMap

## Overview

Los archivos de contenedores son efímeros, lo que puede ser problemático para algunas aplicaciones. Si se reinicia un contenedor, los archivos se perderán. Además, necesitamos un método para compartir archivos entre contenedores dentro de un Pod.

Un Volumen es un directorio al que pueden acceder los contenedores en un Pod. Los proveedores de la nube ofrecen volúmenes que persisten más allá de la vida útil del Pod, de modo que los volúmenes de AWS o GCE podrían completarse previamente y ofrecerse a los Pods, o transferirse de un Pod a otro. Ceph también es otra solución popular para volúmenes persistentes y dinámicos.

A diferencia de los volúmenes de Docker actuales, un volumen de Kubernetes tiene la vida útil del Pod, no los contenedores que contiene. También puede usar diferentes tipos de volúmenes en el mismo pod simultáneamente, pero los volúmenes no se pueden montar de forma anidada. Cada uno debe tener su propio punto de montaje. Los volúmenes se declaran con spec.volumes y los puntos de montaje con los parámetros spec.containers.volumeMounts. Cada tipo de volumen en particular, actualmente 24, puede tener otras restricciones.

https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes

También trabajaremos con un ConfigMap, que es básicamente un conjunto de pares clave-valo/key-value. Estos datos pueden estar disponibles para que un Pod pueda leer los datos como variables de entorno o datos de configuración. Un ConfigMap es similar a un secreto, excepto que no son matrices codificadas en base64 bytes. Se almacenan como cadenas y se pueden leer en forma serializada.


There are three different ways a ConfigMap can ingest data, from a literal value, from a file or from a directory of files.

Hay tres formas diferentes en que un ConfigMap puede ingerir datos, desde un valor literal, desde un archivo o desde un directorio de archivos.


1. Crearemos un ConfigMap que contenga colores primarios. Crearemos una serie de archivos para ingerir en el ConfigMap. Primero, creamos un directorio primario y lo completamos con cuatro archivos. Luego creamos un archivo en nuestro directorio de inicio con nuestro color favorito.

```
student@cp: ̃$ 
mkdir primary
echo c > primary/cyan
echo m > primary/magenta
echo y > primary/yellow
echo k > primary/black
echo "known as key" >> primary/black
echo blue > favorite
```

2. Ahora crearemos el ConfigMap y lo completaremos con los archivos que creamos, así como con un valor literal de la línea de comando.

```
student@cp: ̃$ kubectl create configmap colors \
--from-literal=text=black \
--from-file=./favorite \
--from-file=./primary/

configmap/colors created
```

3. Vea cómo se organizan los datos dentro del clúster. Use el tipo de salida yaml y luego json para ver el formato.

```
student@cp: ̃$ kubectl get configmap colors
NAME DATA AGE
colors 6 30s
```

```
student@cp: ̃$ kubectl get configmap colors -o yaml
```
```
apiVersion: v1
data:
  black: |
    k
    known as key
  cyan: |
    c
  favorite: |
    blue
  magenta: |
    m
  text: black
  yellow: |
    y
kind: ConfigMap
<output_omitted>
```

4. Ahora podemos crear un Pod para usar el ConfigMap. En este caso, un parámetro particular se define como una variable de entorno.

`student@cp: ̃$ vim simpleshell.yaml`

```
apiVersion: v1
kind: Pod
metadata:
  name: shell-demo
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: ilike
      valueFrom:
        configMapKeyRef:
          name: colors
          key: favorite
 ```

 5. Cree el Pod y vea la variable de entorno. Después de ver el parámetro, salga y elimine el pod.

```
student@cp: ̃$ kubectl create -f simpleshell.yaml
pod/shell-demo created
```

```
student@cp: ̃$ kubectl exec shell-demo -- /bin/bash -c 'echo $ilike'
blue
```

```
student@cp: ̃$ kubectl delete pod shell-demo
pod "shell-demo" deleted
```
6. All variables from a file can be included as environment variables as well. Comment out the previous env: stanza and add a slightly different envFrom to the file. Having new and old code at the same time can be helpful to see and understand the differences. Recreate the Pod, check all variables and delete the pod again. They can be found spread throughout the environment variable output

Todas las variables de un archivo también se pueden incluir como variables de entorno. Comente la estrofa env: anterior y agregue un envFrom ligeramente diferente al archivo. Tener código nuevo y antiguo al mismo tiempo puede ser útil para ver y comprender las diferencias. Vuelva a crear el pod, verifique todas las variables y elimine el pod nuevamente. Se pueden encontrar repartidos por toda la salida de la variable de entorno.

`student@cp: ̃$ vim simpleshell.yaml`

**simpleshell.yaml:**

```
apiVersion: v1
kind: Pod
metadata:
  name: shell-demo
spec:
  containers:
  - name: nginx
    image: nginx
      #    env:
      #    - name: ilike
      #      valueFrom:
      #        configMapKeyRef:
      #          name: colors
      #          key: favorite
    envFrom:
      - configMapRef:
          name: colors
```

```
student@cp: ̃$ kubectl create -f simpleshell.yaml
pod/shell-demo created
```


```
student@cp: ̃$ kubectl exec shell-demo -- /bin/bash -c 'env'

black=k
known as key
KUBERNETES_SERVICE_PORT_HTTPS=443
cyan=c
<output_omitted>
```

```
student@cp: ̃$ kubectl delete pod shell-demo
pod "shell-demo" deleted
```

7. También se puede crear un ConfigMap a partir de un archivo YAML. Cree uno con algunos parámetros para describir un automóvil.

`student@cp: ̃$ vim car-map.yaml`


**car-map.yaml:**
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: fast-car
  namespace: default
data:
  car.make: Ford
  car.model: Mustang
  car.trim: Shelby
```

8. Cree el ConfigMap y verifique la configuración.

```
student@cp: ̃$ kubectl create -f car-map.yaml
configmap/fast-car created
```

```
student@cp: ̃$ kubectl get configmap fast-car -o yaml
.....
apiVersion: v1
data:
  car.make: Ford
  car.model: Mustang
  car.trim: Shelby
kind: ConfigMap
<output_omitted>
```

9. We will now make the ConfigMap available to a Pod as a mounted volume. You can again comment out the previous environmental settings and add the following new stanza. The containers: and volumes: entries are indented the same number of spaces
Ahora haremos que ConfigMap esté disponible para un pod como un volumen montado. Puede volver a comentar la configuración ambiental anterior y agregar la siguiente estrofa nueva. Los containers: y volumes: las entradas están identadas con el mismo número de espacios

`student@cp: ̃$ vim simpleshell.yaml`

**simpleshell.yaml**

```
apiVersion: v1
kind: Pod
metadata:
  name: shell-demo
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
      - name: car-vol
        mountPath: /etc/cars
  volumes:
    - name: car-vol
      configMap:
        name: fast-car
```

10. Create the Pod again. Verify the volume exists and the contents of a file within. Due to the lack of a carriage return in the file your next prompt may be on the same line as the output, Shelby

Vuelva a crear el pod. Verifique que exista el volumen y el contenido de un archivo dentro. Debido a la falta de un retorno de carro en el archivo, su próximo aviso puede estar en la misma línea que la salida, Shelby

```
student@cp: ̃$ kubectl create -f simpleshell.yaml
pod "shell-demo" created
```

```
student@cp: ̃$ kubectl exec shell-demo -- /bin/bash -c 'df -ha |grep car'

/dev/root 9.6G 3.2G 6.4G 34% /etc/cars
```

```
student@cp: ̃$ kubectl exec shell-demo -- /bin/bash -c 'cat /etc/cars/car.trim'
Shelby #<-- Then your prompt
```

11. Elimine el Pod y los ConfigMaps que estábamos usando.

```
student@cp: ̃$ kubectl delete pods shell-demo
pod "shell-demo" deleted
```

```
student@cp: ̃$ kubectl delete configmap fast-car colors
configmap "fast-car" deleted
configmap "colors" deleted
```