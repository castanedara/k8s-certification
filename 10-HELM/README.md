Learning Objectives
By the end of this chapter, you should be able to:

- Examine easy Kubernetes deployments using the Helm package manager.
- Understand the Chart template used to describe what application to deploy.
- Discuss how Tiller creates the Deployment based on the Chart.
- Initialize Helm in a cluster.

# Helm

##  Deploying Complex Applications

We have used Kubernetes tools to deploy simple containers and services. Also necessary was to have a canonical location for software. Helm is similar to a package manager like **yum** or **apt**, with a chart being similar to a package, in that it has the binaries , as well as the installation and removal scripts.

A typical containerized application will have several manifests. Manifests for deployments, services, and configMaps. You will probably also create some secrets, Ingress, and other objects. Each of these will need a manifest.

With Helm, you can package all those manifests and make them available as a single tarball. You can put the tarball in a repository, search that repository, discover an application, and then, with a single command, deploy and start the entire application, one or more times.

The tarballs can be collected in a repository for sharing. You can connect to multiple repositories of applications, including those provided by vendors.

You will also be able to upgrade or roll back an application easily from the command line.

## Helm v3
With the near complete overhaul of Helm, the processes and commands have changed quite a bit. Expect to spend some time updating and integrating these changes if you are currently using the outdated Helm v2.

One of the most noticeable changes is the removal of the Tiller pod. This was an ongoing security issue, as the pod needed elevated permissions to deploy charts. The functionality is in the command alone, and no longer requires initialization to use.

In version 2, an update to a chart and deployment used a 2-way strategic merge for patching. This compared the previous manifest to the intended manifest, but not the possible edits done outside of helm commands. The third way now checked is the live state of objects.

Among other changes, software installation no longer generates a name automatically. One must be provided, or the --generated-name option must be passed.


# Chart Contents
A chart is an archived set of Kubernetes resource manifests that make up a distributed application. You can learn more from the [Helm 3](https://helm.sh/docs/topics/charts/) documentation. Others exist and can be easily created, for example by a vendor providing software. Charts are similar to the use of independent YUM repositories.

```
├── Chart.yaml
├── README.md
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── pvc.yaml
│   ├── secrets.yaml
│   └── svc.yaml
└── values.yaml
```

Click on the cards to learn more about chart components.

- Chart.yaml
The Chart.yaml file contains some metadata about the Chart, like its name, version, keywords, and so on, in this case, for MariaDB.


- values.yaml
The values.yaml file contains keys and values that are used to generate the release in your cluster. These values are replaced in the resource manifests using the Go templating syntax.


- templates
The templates directory contains the resource manifests that make up this MariaDB application.



# Templates
The templates are resource manifests that use the Go templating syntax. Variables defined in the values file, for example, get injected in the template when a release is created. In the MariaDB example we provided, the database passwords are stored in a Kubernetes secret, and the database configuration is stored in a Kubernetes ConfigMap.

We can see that a set of labels are defined in the Secret metadata using the Chart name, Release name, etc. The actual values of the passwords are read from the values.yaml file.

```
apiVersion: v1
kind: Secret
metadata:
    name: {{ template "fullname" . }}
    labels:
        app: {{ template "fullname" . }}
        chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
        release: "{{ .Release.Name }}"
        heritage: "{{ .Release.Service }}"
type: Opaque
data:
    mariadb-root-password: {{ default "" .Values.mariadbRootPassword | b64enc | quote }}
    mariadb-password: {{ default "" .Values.mariadbPassword | b64enc | quote }}
```

## Chart Repositories and Hub

Repositories are currently simple HTTP servers that contain an index file and a tarball of all the Charts present. Prior to adding a repository, you can only search the [Artifact Hub](https://artifacthub.io/) using the helm search hub command.

`$ helm search hub redis`

You can interact with a repository using the helm repo commands (commands are followed by the output):

`$ helm repo add bitnami ht‌tps://charts.bitnami.com/bitnami`

`$ helm repo list`

```
NAME      URL
bitnami   ht‌tps://charts.bitnami.com/bitnami
```

Once you have a repository available, you can search for Charts based on keywords. Below, we search for a redis Chart:

`$ helm search repo bitnami`

Once you find the chart within a repository, you can deploy it on your cluster.


## Deploying a Chart

To deploy a Chart, you can just use the **helm install command**. There may be several required resources for the installation to be successful, such as available PVs to match chart PVC. Currently, the only way to discover which resources need to exist is by reading the READMEs for each chart. This can be found by downloading the tarball and expanding it into the current directory. Once requirements are met and edits are made, you can install using the local files. Commands and output below:

$ helm fetch bitnami/apache --untar
$ cd apache/
$ ls

Chart.lock  Chart.yaml  README.md  charts  ci  files  templates  values.schema.json  values.yaml

$ helm install anotherweb

You will be able to list the release, delete it, even upgrade it and roll back.

The output of the deployment should be carefully reviewed. It often includes information on access to the applications within. If your cluster did not have a required cluster resource, the output is often the first place to begin troubleshooting.

