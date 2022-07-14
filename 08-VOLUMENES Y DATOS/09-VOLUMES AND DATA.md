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
![alt text](https://github.com/[username]/[reponame]/blob/[branch]/image.jpg?raw=true)

08-VOLUMENES Y DATOS\njibb9wicexq-KubernetesPodVolumes.png