# Volumenes y datos
# Introduction

Al final de este capítulo, usted debería ser capaz de:
    - Comprender y crear volúmenes persistentes.​
    - Configurar reclamos de volumen persistentes.
    - Administrar los modos de acceso al volumen.
    - Implemente una aplicación con acceso al almacenamiento persistente.
    - Analice el aprovisionamiento dinámico del almacenamiento.
    - Configurar secretos y ConfigMaps.

# Visión general

Los motores de contenedores tradicionalmente no han ofrecido almacenamiento que sobreviva al contenedor. Dado que los contenedores se consideran transitorios, esto podría provocar una pérdida de datos o opciones complejas de almacenamiento externo. Un volumen de Kubernetes comparte la vida útil del Pod, no los contenedores que contiene. Si un contenedor termina, los datos seguirán estando disponibles para el nuevo contenedor. 

Un volumen es un directorio, posiblemente rellenado previamente, que se pone a disposición de los contenedores en un pod. La creación del directorio, el almacenamiento back-end de los datos y el contenido dependen del tipo de volumen. A partir de la versión 1.13, había 27 tipos de volúmenes diferentes, desde rbd para obtener acceso a **Ceph**, hasta **NFS** y volúmenes dinámicos de un proveedor de la nube como **gcePersistentDisk** de Google. Cada uno tiene opciones de configuración y dependencias particulares. 

La adopción de la interfaz de almacenamiento de contenedores (**Container Storage Interface - CSI**) permite el objetivo de una interfaz estándar de la industria para la orquestación de contenedores para permitir el acceso a sistemas de almacenamiento arbitrarios. Actualmente, los complementos de volumen están **"in-tree"**, lo que significa que se compilan y construyen con los archivos binarios principales de Kubernetes. Este objeto **"out-of-tree"** permitirá a los proveedores de almacenamiento desarrollar un único controlador y permitir que el complemento se incluya en contenedores. Esto reemplazará el complemento **Flex** existente que requiere un acceso elevado al nodo host, un gran problema de seguridad. 

Si desea que la vida útil de su almacenamiento sea diferente a la de un pod, puede usar **volúmenes persistentes**. Estos permiten que un Pod reclame volúmenes vacíos o rellenados previamente mediante un Reclamo de volumen persistente y luego sobreviva al Pod. Los datos dentro del volumen podrían ser utilizados por otro Pod o como un medio para recuperar datos. 

Hay dos objetos API que ya existen para proporcionar datos a un Pod. Los datos codificados se pueden pasar usando un **secret** y los datos no codificados se pueden pasar con un **ConfigMap**. Estos se pueden usar para pasar datos importantes como claves SSH, contraseñas o incluso un archivo de configuración como /etc/hosts .

# **Introducing Volumes**

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

# **Tipos de volumen**

Hay varios tipos que puede usar para definir volúmenes, cada uno con sus pros y sus contras. Algunos son locales y muchos utilizan recursos basados ​​en la red.

En **GCE** o **AWS**, puede usar volúmenes de tipo **GCEpersistentDisk** o **awsElasticBlockStore** , lo que le permite montar discos GCE y EBS en sus pods, suponiendo que ya haya configurado cuentas y privilegios.


Los volúmenes **emptyDir** y **hostPath** son fáciles de usar. Como se mencionó, **emptyDir** es un directorio vacío que se borra cuando muere el Pod, pero se vuelve a crear cuando se reinicia el contenedor. El **volumen hostPath** monta un recurso desde el sistema de archivos del nodo host. El recurso podría ser un directorio, un socket de archivo, un carácter o un dispositivo de bloque. Estos recursos ya deben existir en el host para ser utilizados. Hay dos tipos, **DirectoryOrCreate** y **FileOrCreate** , que crean los recursos en el host y los usan si aún no existen.


**NFS** (Network File System) e iSCSI (Internet Small Computer System Interface) son opciones sencillas para escenarios de lectores múltiples.


**rbd** para almacenamiento en bloque o **CephFS** y **GlusterFS**, si están disponibles en su clúster de Kubernetes, pueden ser una buena opción para  necesidades de múltiples escritores.

Además de los tipos de volumen que acabamos de mencionar, hay muchos otros posibles, y se agregan más: **azureDisk , azureFile , csi , downAPI , fc** (fibre channel)**, flocker , gitRepo , local , projected , portworxVolume , quobyte , scaleIO , secret , storageos , vsphereVolume , persistenteVolumeClaim , CSIPersistentVolumeSource , etc.**


**CSI** permite aún más flexibilidad y desacoplamiento de complementos sin necesidad de editar el código principal de Kubernetes. Fue desarrollado como un estándar para exponer complementos arbitrarios en el futuro. 


# **Shared Volume Example**

El siguiente archivo YAML crea un pod, **exampleA** , con dos contenedores, ambos con acceso a un volumen compartido:

```
containers:
- name: alphacont
    image: busybox
    volumeMounts:
    - mountPath: /alphadir
    name: sharevol
- name: betacont
    image: busybox
    volumeMounts:
    - mountPath: /betadir
    name: sharevol
volumes:
- name: sharevol
    emptyDir: {}
```

Ahora, eche un vistazo a los siguientes comandos y salidas:

```
kubectl exec -ti exampleA -c betacont -- touch /betadir/foobar
kubectl exec -ti exampleA -c alphacont -- ls -l /alphadir
total 0
-rw-r--r-- 1 root root 0 Nov 19 16:26 foobar
```



Puede usar **emptyDir** o **hostPath** fácilmente, ya que esos tipos no requieren ninguna configuración adicional y funcionarán en su clúster de Kubernetes.

Tenga en cuenta que un contenedor (betacont) escribió y el otro contenedor (alphacont) tuvo acceso inmediato a los datos. No hay nada que impida que los contenedores sobrescriban los datos del otro. Las consideraciones de bloqueo o control de versiones deben ser parte de la aplicación en contenedores para evitar la corrupción.


# Persistent Volumes and Claims

Un **persistent volume** (pv) es una abstracción de almacenamiento que se usa para retener datos por más tiempo que el Pod que los usa. Los pods definen un volumen de tipo **persistenteVolumeClaim** ( pvc ) con varios parámetros de tamaño y posiblemente el tipo de almacenamiento de back-end conocido como **StorageClass**. Luego, el clúster adjunta el archivo **persistentVolume**.

Kubernetes utilizará de forma dinámica los volúmenes que estén disponibles, independientemente de su tipo de almacenamiento, lo que permitirá reclamar cualquier almacenamiento de back-end.

## Persistent Storage Phases

- **Provision**
El Provisioning puede ser de PV creados con anticipación por el administrador del clúster o solicitados desde una fuente dinámica, como el proveedor de la nube.

- **Bind**
La vinculación O **Binding**, ocurre cuando un ciclo de control(control loop) en el cp detecta el PVC, que contiene UN **amount of storage**, un  **access request** y, opcionalmente, un **StorageClass** en particular . El observador localiza un PV coincidente o espera a que el aprovisionador de **StorageClass** cree uno. El PV debe coincidir al menos con la cantidad de almacenamiento solicitada, pero puede proporcionar más.

- **Use**
La fase de uso (*Use*) comienza cuando se monta el **bound volume** para que lo use el Pod, y que continúa mientras el Pod lo requiera.


- **Release**
Releasing happens when the Pod is done with the volume and an API request is sent, deleting the PVC. The volume remains in the state from when the claim is deleted until available to a new claim. The resident data remains depending on the persistentVolumeReclaimPolicy.

El **Releasing** o liberación ocurre cuando el Pod termina con el volumen y se envía una API request, eliminando el PVC. El volumen permanece en el estado desde que se eliminó la reclamación hasta que esté disponible para una nueva reclamación. Los datos residentes permanecen en función de la política de recuperación de volumen persistente **persistentVolumeReclaimPolicy**.

## **Reclaim**

La fase de reclamo tiene tres opciones:

- **Retain**, que mantiene los datos intactos, lo que permite que un administrador maneje el almacenamiento y los datos.
- **Delete**, le dice al complemento de volumen que elimine el API object, así como el almacenamiento detrás de él.
- The **Recycle**, ejecuta un rm -rf /mountpoint y luego lo pone a disposición de un nuevo reclamo. Con la estabilidad del aprovisionamiento dinámico, está previsto que la opción Reciclar quede obsoleta.

Tenga en cuenta los siguientes dos comandos:

`kubectl get pv`

`kubectl get pvc`

# Persistent Volume

El siguiente ejemplo muestra una declaración básica de un volumen persistente utilizando el tipo **hostPath**.

```
kind: PersistentVolume
apiVersion: v1
metadata:
    name: 10Gpv01
    labels: 
        type: local 
spec:
    capacity: 
        storage: 10Gi
    accessModes:
        - ReadWriteOnce
    hostPath:
        path: "/somepath/data01"
```


Cada tipo tendrá sus propios ajustes de configuración. Por ejemplo, no sería necesario configurar un disco persistente Ceph o GCE ya creado, pero podría reclamarse al proveedor. 



Persistent volumes are not a namespaces object, but persistent volume claims are. A beta feature of v1.13 allows for static provisioning of Raw Block Volumes, which currently support the Fibre Channel plugin, AWS EBS, Azure Disk and RBD plugins among others.

Los **Persistent volumes** no son un objeto de **namespaces**, pero los **persistent volume claims** sí lo son. Una función beta de v1.13 permite el aprovisionamiento estático de **Raw Block Volumes**, que actualmente es compatible con el **plugin Fibre Channel, AWS EBS, Azure Disk y RBD, entre otros.**

El uso de almacenamiento conectado localmente (locally attached storage) se ha convertido en una función estable. Esta característica se usa a menudo como parte de bases de datos y filesystems distribuidos.


# Persistent Volume Claim

With a persistent volume created in your cluster, you can then write a manifest for a claim, and use that claim in your pod definition. In the Pod, the volume uses the persistentVolumeClaim.

Con un **persistent volume** creado en su clúster, puede escribir un manifiesto para un claim y usar ese claim en su definición de pod. En el Pod, el volumen usa el persistenteVolumeClaim .



```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
    name: myclaim
spec:
    accessModes:
        - ReadWriteOnce
    resources:
        requests:
                storage: 8GI
```
En el Pod:

```
spec:
    containers:
....
    volumes:
        - name: test-volume
          persistentVolumeClaim:
                claimName: myclaim
```
La configuración del Pod también podría ser tan compleja como esta:


```
volumeMounts:
      - name: Cephpd
        mountPath: /data/rbd
  volumes:
    - name: rbdpd
      rbd:
        monitors:
        - '10.19.14.22:6789'
        - '10.19.14.23:6789'
        - '10.19.14.24:6789'
        pool: k8s
        image: client
        fsType: ext4
        readOnly: true
        user: admin
        keyring: /etc/ceph/keyring
        imageformat: "2"
        imagefeatures: "layering"
```

# Dynamic Provisioning - Aprovisionamiento dinámico

Si bien el manejo de volúmenes con una definición de volumen persistente y la abstracción del **storage provider/proveedor de almacenamiento** mediante un reclamo (claim) son poderosos, un administrador de clúster aún necesita crear esos volúmenes en primer lugar. A partir de Kubernetes v1.4, el aprovisionamiento dinámico permitió que el clúster solicitara almacenamiento desde una fuente exterior preconfigurada. Las llamadas API realizadas por el plugin apropiado permiten una amplia gama de uso de almacenamiento dinámico. 

El recurso de la API de **StorageClass** permite que un administrador defina un aprovisionador de volumen persistente de cierto tipo, pasando parámetros específicos de almacenamiento.

With a StorageClass created, a user can request a claim, which the API Server fills via auto-provisioning. The resource will also be reclaimed as configured by the provider. AWS and GCE are common choices for dynamic storage, but other options exist, such as a Ceph cluster or iSCSI. Single, default class is possible via annotation.

Con un **StorageClass** creado, un usuario puede solicitar un reclamo, que el servidor de API completa a través del aprovisionamiento automático. El recurso también se reclamará según lo configurado por el proveedor. **AWS** y **GCE** son opciones comunes para el almacenamiento dinámico, pero existen otras opciones, como un clúster de **Ceph** o **iSCSI**. Una sola clase predeterminada es posible mediante anotación.

Aquí hay un ejemplo de **StorageClass** usando **GCE**: 


```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast      # Could be any name
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd 
```

# Uso de Rook para orquestación de almacenamiento

De acuerdo con la naturaleza desacoplada y distribuida de la tecnología Cloud, el proyecto [Rook](https://rook.io/) permite la orquestación del almacenamiento utilizando múltiples proveedores de almacenamiento.


Al igual que con otros agentes del clúster, Rook usa definiciones de recursos personalizadas (**CRD - custom resource definitions**) y un operador personalizado para aprovisionar almacenamiento de acuerdo con el tipo de almacenamiento de back-end, tras una llamada a la API.

Se admiten varios proveedores de almacenamiento:

- Ceph
- Cassandra
- Network File System (NFS).
