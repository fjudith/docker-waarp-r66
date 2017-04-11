Persistant Installation of PostgreSQL and Waarp-R66 on Kubernetes
=================================================================

This example describes how to run a persisten installation of [Waarp-R66](http://waarp.fr) and [PostgreSQL](https://www.postgresql.org/) on Kubernetes. We'll use the official [postgres](https://hub.docker.com/_/postgres/) and [waarp-r66](https://hub.docker.com/r/fjudith/waarp-r66/) [Docker](https://www.docker.com) images for this installation.

## Quickstart

Put your desired PostgreSQL and Waarp-R66 passwords in separated files called `postgres.password.txt` and `waarp-r66.password.txt` with no trailing newline. The first `tr` commands will remove the newline if your editor added one.

**Note**: if your cluster enforces **selinux** and you will be using [Host Path](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd#host-path) for storage, then please follow this [extra step](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd#selinux).

```bash
tr --delete '\n' <postgres.password.txt >.strippedpassword.txt && mv .strippedpassword.txt postgres.password.txt
tr --delete '\n' <waarp-r66.password.txt >.strippedpassword.txt && mv .strippedpassword.txt waarp-r66.password.txt
# PostgresSQL persistent volumes
kubectl create -f https://https://raw.githubusercontent.com/fjudith/docker-waarp-r66/kubernetes/waarp-site1-db-persistentvolumeclaim.yaml
```

