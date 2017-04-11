Persistant Installation of PostgreSQL and Waarp-R66 on Kubernetes
=================================================================

This example describes how to run a persisten installation of [Waarp-R66](http://waarp.fr) and [PostgreSQL](https://www.postgresql.org/) on Kubernetes. We'll use the official [postgres](https://hub.docker.com/_/postgres/) and [waarp-r66](https://hub.docker.com/r/fjudith/waarp-r66/) [Docker](https://www.docker.com) images for this installation.

## Quickstart

Put your desired PostgreSQL and Waarp-R66 passwords in separated files called `postgres.password.txt` and `waarp-r66.password.txt` with no trailing newline. The first `tr` commands will remove the newline if your editor added one.

**Note**: if your cluster enforces **selinux** and you will be using [Host Path](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd#host-path) for storage, then please follow this [extra step](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd#selinux).

```bash
# PostgresSQL with persistent volumes and secret file
tr --delete '\n' <postgres.password.txt >.strippedpassword.txt && mv .strippedpassword.txt postgres.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-site1-db-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-site1-dblog-persistentvolumeclaim.yaml
kubectl create secret generic postgres-pass --from-file=postgres.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-r66-pg-deployment.yaml

# Waarp-66 with persistent volumes and secret file
tr --delete '\n' <waarp-r66.password.txt >.strippedpassword.txt && mv .strippedpassword.txt waarp-r66.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-site1-etc-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-site1-data-persistentvolumeclaim.yaml
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-site1-log-persistentvolumeclaim.yaml
kubectl create secret generic waarp-r66-pass --from-file=waarp-r66.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-r66-deployment.yaml
```

