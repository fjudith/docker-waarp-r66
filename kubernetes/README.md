Persistant Installation of PostgreSQL and Waarp-R66 on Kubernetes
=================================================================

This example describes how to run a persisten installation of [Waarp-R66](http://waarp.fr) and [PostgreSQL](https://www.postgresql.org/) on Kubernetes. We'll use the official [postgres](https://hub.docker.com/_/postgres/) and [waarp-r66](https://hub.docker.com/r/fjudith/waarp-r66/) [Docker](https://www.docker.com) images for this installation.

Demonstrated Kubernetes Concepts:

* [Persistent Volumes](http://kubernetes.io/docs/user-guide/persistent-volumes/) to define persistent disks (disk lifecycle not tied to the Pods).
* [Services](http://kubernetes.io/docs/user-guide/services/) to enable Pods to locate one another.
* [External Load Balancers](http://kubernetes.io/docs/user-guide/services/#type-loadbalancer) to expose Services externally.
* [Deployments](http://kubernetes.io/docs/user-guide/deployments/) to ensure Pods stay up and running.
* [Secrets](http://kubernetes.io/docs/user-guide/secrets/) to store sensitive passwords.


## Quickstart

Put your desired PostgreSQL and Waarp-R66 passwords in separated files called `postgres.password.txt` and `waarp-r66.password.txt` with no trailing newline. The first `tr` commands will remove the newline if your editor added one.

**Note**: if your cluster enforces **selinux** and you will be using [Host Path](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd#host-path) for storage, then please follow this [extra step](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd#selinux).

```bash
# PostgresSQL with persistent volumes and secret file
tr --delete '\n' <postgres.password.txt >.strippedpassword.txt && mv .strippedpassword.txt postgres.password.txt
kubectl create secret generic postgres-pass --from-file=postgres.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-db-persistentvolume.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-db-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-dblog-persistentvolume.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-dblog-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-r66-pg-deployment.yaml

# Waarp-66 with persistent volumes and secret file
tr --delete '\n' <waarp-r66.password.txt >.strippedpassword.txt && mv .strippedpassword.txt waarp-r66.password.txt
kubectl create secret generic waarp-r66-pass --from-file=waarp-r66.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-etc-persistentvolume.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-etc-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-data-persistentvolume.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-data-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-log-persistentvolume.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-log-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-r66-deployment.yaml
```

## Cluster Requirements

Kubernetes runs in a variety of environments and is inherently modular. Not all clusters are the same. These are the requirements for this example.

* Kubernetes version 1.2 is required due to using newer features, such at PV Claims and Deployments. Run `kubectl version` to see your cluster version.
* [Cluster DNS](http://kubernetes.io/docs/user-guide/secrets/) will be used for service discovery.
* An [external load balancer](http://kubernetes.io/docs/user-guide/services/#type-loadbalancer) will be used to access WordPress.
* [Persistent Volume Claims](http://kubernetes.io/docs/user-guide/persistent-volumes/) are used. You must create Persistent Volumes in your cluster to be claimed. This example demonstrates how to create two types of volumes, but any volume is sufficient.

Consult a [Getting Started Guide](http://kubernetes.io/docs/getting-started-guides/) to set up a cluster and the [kubectl](http://kubernetes.io/docs/user-guide/prereqs/) command-line client.

## Decide where you will store your data

PostgreSQL and Waarp-R66 will each use aa [Persistent Volume](http://kubernetes.io/docs/user-guide/persistent-volumes/) to store their data. We will use a Persistent Volume Claim to claim an aivailable persistent volume. This example covers HostPath and NFS volumes. Choose one of the two, or see [Types of Persisten Volumes](http://kubernetes.io/docs/user-guide/persistent-volumes/#types-of-persistent-volumes) for more options.

### Host Path

Host paths are volumes mapped to directories on the host. **These should be used for testing or single-node clusters only**.
the data will not be moved between nodes if the pod is recreated on a new node. If the pod is deleted and recreated on a new node, **data will be lost**.

#### SELinux

On systems supporting selinux it is preferred to leave it _enabled/enforcing_. However, docker containers mount the host path with the _"svirt_sandbox_file_t"_ label type, which is incompatible with the default label type for /var/lib/kubernetes/pv (_"var_lib_t"), resulting in a permissions error when the postgres container attempts to `chown`_/var/lib/postgres/data_. Therefore, on selinux systems using host path, you should pre-create the host path directory (/var/lib/kubernetes/pv/) and change it'is selinux label type to "_svirt_sandbox_file_t", as follows:

```bash
## on every node:
mkdir -p /var/lib/kubernetes/pv
chmod a+rwt /var/lib/kubernetes/pv  # match /tmp permissions
chcon -Rt svirt_sandbox_file_t /var/lib/kubernetes/pv
```

Continuing with host path, create the persistent volume objects in Kubernetes using [*-persistentvolume.yaml](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes):

```bash
export KUBE_REPO=https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes
kubectl create -f $KUBE_REPO/waarp-site1-db-persistentvolume.yaml
kubectl create -f $KUBE_REPO/waarp-site1-dblog-persistentvolume.yaml
kubectl create -f $KUBE_REPO/waarp-site1-etc-persistentvolume.yaml
kubectl create -f $KUBE_REPO/waarp-site1-data-persistentvolume.yaml
kubectl create -f $KUBE_REPO/waarp-site1-log-persistentvolume.yaml
```

## Create the PostgreSQL and Waarp-R66 Passwords Secrets

Use [Secret](http://kubernetes.io/docs/user-guide/secrets/) objects to store the PostgreSQL and Waarp-R66 passwords. First create respective files (in the same directory as the waarp-r66 sample files) called `postgres.password.txt` and `waarp-r66.password.txt`, then save your passwords in it. Make sure to not have a trailing newline at the end of the password. The first `tr` command will remove the newline if your editor added one. Then, create the Secret object.

```bash
# PostgresSQL secret file
tr --delete '\n' <postgres.password.txt >.strippedpassword.txt && mv .strippedpassword.txt postgres.password.txt
kubectl create secret generic postgres-pass --from-file=postgres.password.txt

# Waarp-66 secret file
tr --delete '\n' <waarp-r66.password.txt >.strippedpassword.txt && mv .strippedpassword.txt waarp-r66.password.txt
kubectl create secret generic waarp-r66-pass --from-file=waarp-r66.password.txt
```

Postgres secret is referenced by the PostgreSQL and Waarp-R66 pod configuration so that those pods will have access to it. The PostgresSQL pod will set the database password, and the Waarp-r66 pod will use the password to access the database.
The Waarp secret is only referenced by the Waarp-R66 pod configuration. It will be used to access the Waarp-R66 http-admin page listening on tcp port 8087.

## Deploy PostgreSQL

Now that the persistent disks and secrets are defined, the Kubernetes pods can be launched. Start PostgresSQL using [waarp-r66-pg-deployment.yaml](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes/waarp-r66-pg-deployment.yaml).

```bash
kubectl create -f $KUBE_REPO/waarp-r66-pg-service.yaml
kubectl create -f $KUBE_REPO/waarp-site1-db-persistentvolumeclaim.yaml
kubectl create -f $KUBE_REPO/waarp-site1-dblog-persistentvolumeclaim.yaml
kubectl create -f $KUBE_REPO/waarp-r66-pg-deployment.yaml
```

