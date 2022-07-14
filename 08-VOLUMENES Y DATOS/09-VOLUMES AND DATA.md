# Volumenes y datos
## Introduction

Al final de este capítulo, usted debería ser capaz de:
    - Comprender y crear volúmenes persistentes.​
    - Configurar reclamos de volumen persistentes.
    - Administrar los modos de acceso al volumen.
    - Implemente una aplicación con acceso al almacenamiento persistente.
    - Analice el aprovisionamiento dinámico del almacenamiento.
    - Configurar secretos y ConfigMaps.

## Visión general

Los motores de contenedores tradicionalmente no han ofrecido almacenamiento que sobreviva al contenedor. Dado que los contenedores se consideran transitorios, esto podría provocar una pérdida de datos o opciones complejas de almacenamiento externo. Un volumen de Kubernetes comparte la vida útil del Pod, no los contenedores que contiene. Si un contenedor termina, los datos seguirán estando disponibles para el nuevo contenedor. 

Un volumen es un directorio, posiblemente rellenado previamente, que se pone a disposición de los contenedores en un pod. La creación del directorio, el almacenamiento back-end de los datos y el contenido dependen del tipo de volumen. A partir de la versión 1.13, había 27 tipos de volúmenes diferentes, desde rbd para obtener acceso a **Ceph**, hasta **NFS** y volúmenes dinámicos de un proveedor de la nube como **gcePersistentDisk** de Google. Cada uno tiene opciones de configuración y dependencias particulares. 

La adopción de la interfaz de almacenamiento de contenedores (**Container Storage Interface - CSI**) permite el objetivo de una interfaz estándar de la industria para la orquestación de contenedores para permitir el acceso a sistemas de almacenamiento arbitrarios. Actualmente, los complementos de volumen están **"in-tree"**, lo que significa que se compilan y construyen con los archivos binarios principales de Kubernetes. Este objeto **"out-of-tree"** permitirá a los proveedores de almacenamiento desarrollar un único controlador y permitir que el complemento se incluya en contenedores. Esto reemplazará el complemento **Flex** existente que requiere un acceso elevado al nodo host, un gran problema de seguridad. 

Si desea que la vida útil de su almacenamiento sea diferente a la de un pod, puede usar **volúmenes persistentes**. Estos permiten que un Pod reclame volúmenes vacíos o rellenados previamente mediante un Reclamo de volumen persistente y luego sobreviva al Pod. Los datos dentro del volumen podrían ser utilizados por otro Pod o como un medio para recuperar datos. 

Hay dos objetos API que ya existen para proporcionar datos a un Pod. Los datos codificados se pueden pasar usando un **secret** y los datos no codificados se pueden pasar con un **ConfigMap**. Estos se pueden usar para pasar datos importantes como claves SSH, contraseñas o incluso un archivo de configuración como /etc/hosts .

**Introducing Volumes**

Una especificación de Pod puede declarar uno o más volúmenes y dónde están disponibles. Cada uno requiere un nombre, un tipo y un punto de montaje. El mismo volumen puede estar disponible para varios contenedores dentro de un Pod, lo que puede ser un método de comunicación de contenedor a contenedor. Un volumen puede estar disponible para múltiples Pods, y cada uno de ellos tiene un modo de acceso para escribir. No hay verificación de concurrencia, lo que significa que es probable que se dañen los datos, a menos que se produzca un bloqueo externo.



![alt text](https://github.com/castanedara/k8s-certification/blob/main/08-VOLUMENES%20Y%20DATOS/njibb9wicexq-KubernetesPodVolumes.png?raw=true)

**Volúmenes de pods de Kubernetes**

Un modo de acceso particular es parte de una solicitud de Pod. Como solicitud, al usuario se le puede otorgar más, pero no menos acceso, aunque primero se intenta una coincidencia directa. El clúster agrupa los volúmenes con el mismo modo y luego los ordena por tamaño, del más pequeño al más grande. El reclamo se compara con cada uno en ese grupo de modo de acceso, hasta que coincida un volumen de tamaño suficiente. Los tres modos de acceso son:

- **ReadWriteOnce**, que permite la lectura y escritura por un solo nodo
- **ReadOnlyMany**, que permite solo lectura por múltiples nodos
- **ReadWriteMany**, que permite la lectura y escritura de muchos nodos.

Por lo tanto, dos pods en el mismo nodo pueden escribir en **ReadWriteOnce**, pero un tercer pod en un nodo diferente no estaría listo debido a un error **FailedAttachVolume**.

Cuando se solicita un volumen, el kubelet local utiliza el script **kubelet_pods.go** para asignar los dispositivos sin formato, determinar y crear el punto de montaje para el contenedor y luego crear el **symbolic link** en el **filesystem**  del nodo host para asociar el almacenamiento al contenedor. El  **API server** realiza una solicitud de almacenamiento al complemento **StorageClass** , pero los detalles de las solicitudes al backend storage dependen del complemento en uso. 

Si no se realizó una solicitud para un **StorageClass** en particular , los únicos parámetros utilizados serán el modo de acceso y el tamaño. El volumen podría provenir de cualquiera de los tipos de almacenamiento disponibles y no hay una configuración para determinar cuál de los disponibles se utilizará.

**Volume Spec**
Uno de los muchos tipos de almacenamiento disponibles es un **emptyDir**. El kubelet creará el directorio en el contenedor, pero no montará ningún almacenamiento. Todos los datos creados se escriben en el espacio contenedor compartido. Como resultado, no sería un almacenamiento persistente. Cuando se destruye el Pod, el directorio se eliminaría junto con el contenedor.


```
apiVersion: v1
kind: Pod
metadata:
    name: fordpinto 
    namespace: default
spec:
    containers:
    - image: simpleapp 
      name: gastank 
      command:
        - sleep
        - "3600"
      volumeMounts:
      - mountPath: /scratch
        name: scratch-volume
    volumes:
    - name: scratch-volume
            emptyDir: {}
```

El archivo YAML anterior crearía un Pod con un solo contenedor con un volumen llamado **scratch-volume** created, que crearía el directorio **/scratch** dentro del contenedor.

**Tipos de volumen**

Hay varios tipos que puede usar para definir volúmenes, cada uno con sus pros y sus contras. Algunos son locales y muchos utilizan recursos basados ​​en la red.

En **GCE** o **AWS**, puede usar volúmenes de tipo **GCEpersistentDisk** o **awsElasticBlockStore** , lo que le permite montar discos GCE y EBS en sus pods, suponiendo que ya haya configurado cuentas y privilegios.


Los volúmenes **emptyDir** y **hostPath** son fáciles de usar. Como se mencionó, **emptyDir** es un directorio vacío que se borra cuando muere el Pod, pero se vuelve a crear cuando se reinicia el contenedor. El **volumen hostPath** monta un recurso desde el sistema de archivos del nodo host. El recurso podría ser un directorio, un socket de archivo, un carácter o un dispositivo de bloque. Estos recursos ya deben existir en el host para ser utilizados. Hay dos tipos, **DirectoryOrCreate** y **FileOrCreate** , que crean los recursos en el host y los usan si aún no existen.


NFS (Network File System) and iSCSI (Internet Small Computer System Interface) are straightforward choices for multiple readers scenarios.

NFS (Network File System) e iSCSI (Internet Small Computer System Interface) son opciones sencillas para escenarios de lectores múltiples.







