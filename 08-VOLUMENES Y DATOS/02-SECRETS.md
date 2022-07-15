# Secrets

Los pods pueden acceder a datos locales mediante volúmenes, pero hay algunos datos que no desea que se puedan leer a simple vista. Las contraseñas pueden ser un ejemplo. Usando el recurso del  **API Secrets**, la misma contraseña podría codificarse o encriptarse.


Puede crear, obtener o eliminar secrets (consulte los siguientes comandos):


``kubectl get secrets ``

Los secretos se pueden codificar manualmente o a través de kubectl create secret :

`kubectl create secret generic --help`

`kubectl create secret generic mysql --from-literal=password=root`

A secret is not encrypted, only base64-encoded, by default. You must create an EncryptionConfiguration with a key and proper identity. Then, the kube-apiserver needs the --encryption-provider-config flag set to a previously configured provider, such as aescbc or ksm. Once this is enabled, you need to recreate every secret, as they are encrypted upon write. 

Un secreto no está cifrado, solo codificado en base64, de forma predeterminada. Debe crear una configuración de cifrado (**EncryptionConfiguration**)  con una clave y una identidad adecuada. Luego, kube-apiserver necesita el indicador --encryption-provider-config establecido en un proveedor configurado previamente, como **aescbc** o **ksm** . Una vez que esto está habilitado, debe volver a crear cada secreto, ya que se cifran al escribir. 

Son posibles varias claves. Cada clave para un proveedor se prueba durante el descifrado. La primera clave del primer proveedor se utiliza para el cifrado. Para rotar claves, primero cree una nueva clave, reinicie (todos) los procesos de kube-apiserver y luego vuelva a crear cada secreto. 

Puede ver la cadena codificada dentro del secreto con kubectl. El secret se descodificará y se presentará como una cadena guardada en un archivo. El archivo se puede utilizar como una variable de ambiente o en un nuevo directorio, similar a la presentación de un volumen.



También se puede crear un secret manualmente y luego insertarlo en un archivo YAML (consulte los comandos y resultados a continuación):

```
$ echo LFTr@1n | base64
TEZUckAxbgo=
```
```
$ vim secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: lf-secret
data:
  password: TEZUckAxbgo=
```

# Using Secrets via Environment Variables


Un secret se puede usar como una variable de ambiente en un Pod. Puede ver uno configurado en el siguiente ejemplo:

```
...
spec:
    containers:
    - image: mysql:5.5
      name: dbpod
      env:
      - name: MYSQL_ROOT_PASSWORD
        valueFrom:
            secretKeyRef:
              name: mysql
              key: password 

```
No hay límite para la cantidad de secretos utilizados, pero hay un límite de 1 MB para su tamaño. Cada secreto ocupa memoria, junto con otros objetos API, por lo que una gran cantidad de secrets podría agotar la memoria en un host.

Se almacenan en el almacenamiento **tmpfs** en el nodo del host y solo se envían al host que ejecuta el Pod. Todos los volúmenes solicitados por un Pod deben montarse antes de que se inicien los contenedores dentro del Pod. Por lo tanto, debe existir un secreto antes de ser solicitado.



They are stored in the tmpfs storage on the host node, and are only sent to the host running Pod. All volumes requested by a Pod must be mounted before the containers within the Pod are started. So, a secret must exist prior to being requested.

# Montaje de secrets como volúmenes

También puede montar secretos como archivos usando una definición de volumen en un manifiesto de pod. La ruta de montaje contendrá un archivo cuyo nombre será la clave del secreto creado con el paso **kubectl create secret** anterior.

```
spec:
    containers:
    - image: busybox
      command:
        - sleep
        - "3600"
      volumeMounts:
      - mountPath: /mysqlpassword
        name: mysql
      name: busy
    volumes:
    - name: mysql
        secret:
            secretName: mysql

````
Una vez que el pod se está ejecutando, puede verificar que se pueda acceder al secreto en el contenedor ejecutando este comando (seguido de la salida):

```
$ kubectl exec -ti busybox -- cat /mysqlpassword/password

LFTr@1n

```

# Datos portátiles con ConfigMaps

Un recurso de API similar a Secrets es ConfigMap, excepto que los datos no están codificados. De acuerdo con el concepto de desacoplamiento en Kubernetes, el uso de un ConfigMap desacopla una imagen de contenedor de los artefactos de configuración. 

Almacenan datos como conjuntos de pares clave-valor o archivos de configuración simples en cualquier formato. Los datos pueden provenir de una colección de archivos o de todos los archivos en un directorio. También se puede rellenar a partir de un valor literal. 

Un ConfigMap se puede utilizar de varias maneras diferentes. Un contenedor puede utilizar los datos como variables de entorno de una o más fuentes. Los valores contenidos en el interior se pueden pasar a los comandos dentro del pod. Se puede crear un Volumen o un archivo en un Volumen, incluyendo diferentes nombres y modos de acceso particulares. Además, los componentes del clúster, como los controladores, pueden usar los datos.



Digamos que tiene un archivo en su filesystem local llamado config.js . Puede crear un ConfigMap que contenga este archivo. El objeto configmap tendrá una sección de datos que contiene el contenido del archivo (vea el comando y el resultado a continuación):

```
$ kubectl get configmap foobar -o yaml

kind: ConfigMap
apiVersion: v1
metadata:
    name: foobar
data:
    config.js: |
         {
...

```
Los ConfigMaps se pueden consumir de varias formas:


- Pod de variables de ambiente de uno o varios ConfigMaps
- Usar valores de ConfigMap en los comandos de Pod
- Rellenar volumen desde ConfigMap
- Agregar datos de ConfigMap a una ruta específica en Volumen
- Establecer nombres de archivo y modo de acceso en Volumen desde datos de ConfigMap
- Puede ser utilizado por componentes y controladores del sistema.

# Using ConfigMaps

Like secrets, you can use ConfigMaps as environment variables or using a volume mount. They must exist prior to being used by a Pod, unless marked as optional. They also reside in a specific namespace.

Al igual que los secretos, puede usar ConfigMaps como variables de entorno o usar un montaje de volumen. Deben existir antes de ser utilizados por un Pod, a menos que estén marcados como opcionales. También residen en un namespace específico.

En el caso de las variables de entorno, su manifiesto de pod utilizará la clave **valueFrom** y el valor **configMapKeyRef** para leer los valores. Por ejemplo:

```
env:
- name: SPECIAL_LEVEL_KEY
  valueFrom:
    configMapKeyRef:
      name: special-config
      key: special.how

```

Con los volúmenes, define un volumen con el tipo configMap en su pod y lo monta donde debe usarse:

```
volumes:
    - name: config-volume
      configMap:
        name: special-config
```


# Lab 8.1. Create a ConfigMap

