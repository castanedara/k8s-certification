## Uso de DaemonSets
Un objeto más nuevo con el que trabajar es el DaemonSet. Este controlador garantiza que exista un solo pod en cada nodo del clúster. Cada Pod usa la misma imagen. Si se agrega un nuevo nodo, el controlador DaemonSet implementará un nuevo Pod en su nombre. Si se elimina un nodo, el controlador también eliminará el Pod. 

El uso de un DaemonSet permite garantizar que un contenedor en particular siempre se esté ejecutando. En un entorno grande y dinámico, puede ser útil tener una aplicación de registro o generación de métricas en cada nodo sin que un administrador recuerde implementar esa aplicación. 

**uso kind: DaemonSet.**​
Hay formas de efectuar el **kube-apischeduler** de modo que algunos nodos no ejecuten un DaemonSet

