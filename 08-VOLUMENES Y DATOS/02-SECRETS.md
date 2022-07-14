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

A secret can be used as an environmental variable in a Pod. You can see one being configured in the following example:

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

Se almacenan en el almacenamiento tmpfs en el nodo del host y solo se envían al host que ejecuta el Pod. Todos los volúmenes solicitados por un Pod deben montarse antes de que se inicien los contenedores dentro del Pod. Por lo tanto, debe existir un secreto antes de ser solicitado.



They are stored in the tmpfs storage on the host node, and are only sent to the host running Pod. All volumes requested by a Pod must be mounted before the containers within the Pod are started. So, a secret must exist prior to being requested.