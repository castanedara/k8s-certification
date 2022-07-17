# Exercise 9.4: Use Labels to Manage Resources

1. Intente eliminar todos los Pods con la label system=secondary, en todos los namespaces.

`student@cp: ̃$ kubectl delete pods -l system=secondary \
--all-namespaces`

```
pod "nginx-one-74dd9d578d-fcpmv" deleted
pod "nginx-one-74dd9d578d-sts5l" deleted
```

2.  Ver los Pods de nuevo. Las nuevas versiones de los Pods deberían estar ejecutándose mientras el controlador responsable de ellos continúa.

`student@cp: ̃$ kubectl -n accounting get pods`

```
NAME READY STATUS RESTARTS AGE
nginx-one-74dd9d578d-ddt5r 1/1 Running 0 1m
nginx-one-74dd9d578d-hfzml 1/1 Running 0 1m
```

3. También le dimos una label al deployment. Veael la deployment en el namespace accounting.

`student@cp: ̃$ kubectl -n accounting get deploy --show-labels`

```
NAME READY UP-TO-DATE AVAILABLE AGE LABELS
nginx-one 2/2 2 2 10m system=secondary
```

4. Elimine el deployment utilizando su label.

`student@cp: ̃$ kubectl -n accounting delete deploy -l system=secondary`
```
deployment.apps "nginx-one" deleted
```

5. Retire la label del nodo secundario. Tenga en cuenta que la sintaxis es un signo menos justo después de la clave que desea eliminar, o system en este caso.

`student@cp: ̃$ kubectl label node worker system-`
```
node/worker labeled
```