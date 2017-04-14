Persistent Installation of PostgreSQL and Waarp-R66 on Kubernetes
=================================================================

This example describes how to run a persisten installation of [Waarp-R66](http://waarp.fr) and [PostgreSQL](https://www.postgresql.org/) on Kubernetes. We'll use the official [postgres](https://hub.docker.com/_/postgres/) and [waarp-r66](https://hub.docker.com/r/fjudith/waarp-r66/) [Docker](https://www.docker.com) images for this installation.

Demonstrated Kubernetes Concepts:

* [Persistent Volumes](http://kubernetes.io/docs/user-guide/persistent-volumes/) to define persistent disks (disk lifecycle not tied to the Pods).
* [Services](https://kubernetes.io/docs/concepts/services-networking/service/) to enable Pods to locate one another.
* [NodePort](http://kubernetes.io/docs/user-guide/services/#node-port) to expose Services externally.
* [Deployments](http://kubernetes.io/docs/user-guide/deployments/) to ensure Pods stay up and running.
* [Secrets](http://kubernetes.io/docs/user-guide/secrets/) to store sensitive passwords.


## Quickstart

Put your desired PostgreSQL and Waarp-R66 passwords in separated files called `postgres.password.txt` and `waarp-r66.password.txt` with no trailing newline. The first `tr` commands will remove the newline if your editor added one.

**Note**: if your cluster enforces **selinux** and you will be using [Host Path](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes#host-path) for storage, then please follow this [extra step](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes#selinux).

```bash
# PostgreSQL and Waarp-R66 persistent volumes
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-site1-persistentvolume.yaml

# PostgreSQL with persistent volumes and secret file
tr --delete '\n' <postgres.password.txt >.strippedpassword.txt && mv .strippedpassword.txt postgres.password.txt
kubectl create secret generic postgres-pass --from-file=postgres.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-r66-pg-deployment.yaml

# Waarp-66 with persistent volumes and secret file
tr --delete '\n' <waarp-r66.password.txt >.strippedpassword.txt && mv .strippedpassword.txt waarp-r66.password.txt
kubectl create secret generic waarp-r66-pass --from-file=waarp-r66.password.txt
kubectl create -f https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes/waarp-r66-deployment.yaml
```

## Cluster Requirements

Kubernetes runs in a variety of environments and is inherently modular. Not all clusters are the same. These are the requirements for this example.

* Kubernetes version 1.2 is required due to using newer features, such as PV Claims and Deployments. Run `kubectl version` to see your cluster version.
* [Cluster DNS](http://kubernetes.io/docs/user-guide/secrets/) will be used for service discovery.
* An [NodePort](http://kubernetes.io/docs/user-guide/services/#node-port) will be used to access Waarp-R66.
* [Persistent Volume Claims](http://kubernetes.io/docs/user-guide/persistent-volumes/) are used. You must create Persistent Volumes in your cluster to be claimed. This example demonstrates how to create two types of volumes, but any volume is sufficient.

Consult a [Getting Started Guide](http://kubernetes.io/docs/getting-started-guides/) to set up a cluster and the [kubectl](http://kubernetes.io/docs/user-guide/prereqs/) command-line client.

## Decide where you will store your data

PostgreSQL and Waarp-R66 will each use [Persistent Volumes](http://kubernetes.io/docs/user-guide/persistent-volumes/) to store their data. We will use a Persistent Volume Claim to claim an aivailable persistent volume. Labels will be leveraged to provide static mapping from Volume Claim down to Persistent Volume. This example covers HostPath and NFS volumes. Choose one of the two, or see [Types of Persisten Volumes](http://kubernetes.io/docs/user-guide/persistent-volumes/#types-of-persistent-volumes) for more options.

### Host Path

Host paths are volumes mapped to directories on the host. **These should be used for testing or single-node clusters only**.
the data will not be moved between nodes if the pod is recreated on a new node. If the pod is deleted and recreated on a new node, **data will be lost**.

#### Ownership and Permissions issues

By default Host Path subdirectories are owned by the user running the Docker deamon (_i.e. root:root_) with MOD 755.
This is a big issue for images that runs with a different user as per [Dockerfile Best Practices](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#user) as it will not have permissions to write.

We have three options are available to solve this issue:

1. **Change MOD** to `777`/`a+rwt` of the Persistent Volume directory. 
   * Meaning all Pods or user accessing the node will also get read-write access to the data persisted
2. **Build a deriving image that enforce root** (_e.g._ Add `USER root` to the Dockerfile).
   * Requires you to maintain the image up-to-date.
3. **Create user and group in the node**, with the exact same `name`, `uid`, `gid` and change ownership of the Persistent Volume.
   * Secure but requires more administrative effort (_i.e._ stateless run to identify user attributes, add user to the node, pre-create persistent volume path with appropriate ownership. Thus create the pod).

We will use `option 3` in this guide.

#### SELinux

On systems supporting selinux it is preferred to leave it _enabled/enforcing_. However, docker containers mount the host path with the _"svirt_sandbox_file_t"_ label type, which is incompatible with the default label type for /var/lib/kubernetes/pv (_"var_lib_t"), resulting in a permissions error when the postgres container attempts to `chown`_/var/lib/postgres/data_. Therefore, on selinux systems using host path, you should pre-create the host path directory (/var/lib/kubernetes/pv/) and change it'is selinux label type to "_svirt_sandbox_file_t", as follows:

```bash
## on every node:
sudo groupadd -r --gid 499 waarp && sudo useradd -ms /bin/bash --uid 499 --gid 499 waarp

sudo mkdir -p /var/lib/kubernetes/pv
sudo chmod a+rwt /var/lib/kubernetes/pv

sudo mkdir -p \
  /var/lib/kubernetes/pv/waarp-site1-etc \
  /var/lib/kubernetes/pv/waarp-site1-data \
  /var/lib/kubernetes/pv/waarp-site1-log

sudo chown -R waarp:waarp \
  /var/lib/kubernetes/pv/waarp-site1-etc \
  /var/lib/kubernetes/pv/waarp-site1-data \
  /var/lib/kubernetes/pv/waarp-site1-log

sudo chcon -Rt svirt_sandbox_file_t /var/lib/kubernetes/pv
```

Continuing with host path, create the persistent volume objects in Kubernetes using [waarp-site1-persistentvolume.yaml](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes/waarp-site1-persistentvolume.yaml):

```bash
export KUBE_REPO=https://raw.githubusercontent.com/fjudith/docker-waarp-r66/master/kubernetes
kubectl create -f $KUBE_REPO/waarp-site1-persistentvolume.yaml
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
kubectl create -f $KUBE_REPO/waarp-r66-pg-deployment.yaml
```

Take a look at [waarp-r66-pg-deployment.yaml](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes/waarp-r66-pg-deployment.yaml), and note that we've defined two volume mounts for:

* /var/lib/postgres/data
* /var/log/postgres

And then created a Persistent Volume Claim that each looks for a 2GB volume. This claim is satisfied by any volume that meets the requirements, in our case one of the volumes we created above.

Also lookt at the `env` section and see that we specified the password by referencing the secret `posgres-pass`that we created above. Secrets can have multiple key:value pairs. Ours has only one key `postgres.password.txt`which was the name of the file we used to create de secret. The [PostgresSQL imgage](https://hub.docker.com/_/postgres/) sets the database password using the `POSTGRES_PASSWORD`environment variable.

It my take a short period before the new pod reaches the `Running` state. List all pods to see the status of this new pod.

```bash
kubectl get pods
```

```
NAME                            READY     STATUS    RESTARTS   AGE
waarp-r66-pg-2119572569-p170x   1/1       Running   0          1m
```

Kubernetes logs the stderr and stdout for each pod. Take a look at the logs for a pod by using `kubectl log`. Copy the pod name from the `get pods`command, and then:

```bash
kubectl logs <pod-name>
```

```
...
PostgreSQL init process complete; ready for start up.

LOG:  database system was shut down at 2017-04-12 12:14:19 UTC
LOG:  MultiXact member wraparound protections are now enabled
LOG:  database system is ready to accept connections
LOG:  autovacuum launcher started
```

Also in [waarp-r66-pg-deployment.yaml](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes/waarp-r66-pg-deployment.yaml) we created a service to allow ofther pods to reach this postgres instance. the name is `waarp-r66-pg`which resolves to the pod IP.

Up to this point one Deployment, one Pod, one PVC, one Service, one Endpoint, five PVs, and two Secrets have been created, shown below:

```bash
kubectl get deployment,pod,svc,endpoints,pvc -l app=waarp-r66 -o wide && \
  kubectl get secret postgres-pass && \
  kubectl get pv
```

```
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINER(S)   IMAGE(S)   SELECTOR                                     
deploy/waarp-r66-pg   1         1         1            1           3m        waarp-r66-pg   postgres   app=waarp-r66,io.kompose.service=waarp-r66-pg
                                                                                                                                                    
NAME                               READY     STATUS    RESTARTS   AGE       IP           NODE                                                       
po/waarp-r66-pg-2119572569-hfd58   1/1       Running   0          3m        10.2.33.10   172.17.4.201                                               
                                                                                                                                                    
NAME               CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE       SELECTOR                                                                         
svc/waarp-r66-pg   10.3.0.146   <none>        5432/TCP   3m        io.kompose.service=waarp-r66-pg                                                  
                                                                                                                                                    
NAME              ENDPOINTS         AGE                                                                                                             
ep/waarp-r66-pg   10.2.33.10:5432   3m                                                                                                              
                                                                                                                                                    
NAME                    STATUS    VOLUME            CAPACITY   ACCESSMODES   STORAGECLASS   AGE                                                     
pvc/waarp-site1-db      Bound     waarp-site1-log   2Gi        RWO                          3m                                                      
pvc/waarp-site1-dblog   Bound     waarp-site1-db    2Gi        RWO                          3m                                                      
NAME            TYPE      DATA      AGE                                                                                                             
postgres-pass   Opaque    1         3m                                                                                                              
NAME                CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS      CLAIM                       STORAGECLASS   REASON    AGE                   
waarp-site1-data    2Gi        RWO           Retain          Available                                                        3m                    
waarp-site1-db      2Gi        RWO           Retain          Bound       default/waarp-site1-dblog                            3m                    
waarp-site1-dblog   2Gi        RWO           Retain          Available                                                        3m                    
waarp-site1-etc     100Mi      RWO           Retain          Available                                                        3m                    
waarp-site1-log     2Gi        RWO           Retain          Bound       default/waarp-site1-db                               3m                     
```

## Deploy Waarp

Next deploy Waarp-R66 using [waarp-r66-deployment.yaml](https://github.com/fjudith/docker-waarp-r66/tree/master/kubernetes/waarp-r66-deployment.yaml):

```bash
kubectl create -f $KUBE_REPO/waarp-r66-deployment.yaml
```

Here we are using many of the same features, such as volume claims for persistent storage and two secrets for passwords.

The [Waarp-R66 image](https://hub.docker.com/u/fjudith/waarp-r66) accepts the database hostname through the environment variable `WAARP_DATABASE_URL`. We set the env value to the name of the PostgreSQL service we created: `waarp-r66-pg`.

The Waarp-R66 service hase the setting `type: LoadBalancer`. This will set up the waarp-r66 servic behind an external IP.

Find the external IP and port for your Waarp-R66 service. **It may take a minute to have an external IP assigned to the service , depending on your cluster environment**.

```
kubectl get pod -o wide -l app=waarp-r66
```

```
NAME                            READY     STATUS    RESTARTS   AGE       IP          NODE
waarp-r66-79982725-bdvvr        1/1       Running   4          1h        10.2.94.8   172.17.4.201
waarp-r66-pg-1179393831-nc0n3   1/1       Running   0          1h        10.2.94.7   172.17.4.201
```

```bash
kubectl get services waarp-r66
```

```
NAME        CLUSTER-IP   EXTERNAL-IP   PORT(S)                                                                      AGE

waarp-r66   10.3.0.214   <nodes>       6666:30174/TCP,6667:31364/TCP,8066:31167/TCP,8067:32057/TCP,8088:31061/TCP   42m
```

# Visit your new Waarp-R66 MFT

Now, we can visit ruuning Waarp-R66 app. Use the node IP running the waarp-r66 pod and the port mapped to `8067/TCP` you obtained above.

```
https://<node-ip>:<port>
```

You should see the familiar Waarp-R66 login page.

![Waarp-R66 login page](https://github.com/fjudith/docker-waarp-r66/raw/master/kubernetes/Waarp.png)
