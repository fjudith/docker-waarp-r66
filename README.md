# Instroduction

Waarp Gateway Ftp: Service extension to [Waarp-R66](https://hub.docker.com/r/fjudith/waarp-r66/)

## Docker image roadmap

[X] Password and SSL automation
[X] Transparent support of linked Mysql/MariaDB
[X] Transparent support of linked PostgreSQL
[X] SNMP support

# Quick start
Run the Waarp-GwFTP image

`docker run --name='waarp-gwftp' -it --rm -p 6621:6621 -p 50001-65534:50001-65534 -p 8076:8076 -p 8077:8077 fjudith/waarp-gwftp`

NOTE: Please alow a few minutes for the application to start, especially if populating a remote database at first lauch. If you want to make sure that everythin went fine, whatch the logs:

```bash
docker exec -it waarp-gwftp bash
tail -f /var/log/waarp/${WAARP_APPNAME}.log
```

Go  to http://localhost:8074 or point to the IP address of your docker host. On Mac or Windows, replace `localhost`with the address of your Docker host which you can get using:

```
docker-machine ip default
```
For admin console, go to https://localhost:8067. the default username and password are:

* username: **admin**
* password: **password**

# Configuration
Persistent Volumes
If you use this image in production, you'lll probably want to persist the following locations in a volume

```
/etc/waarp/certs      # JKS key & certs and GGP password stores
/etc/waarp/conf.d     # Configuration files
/var/lib/waarp        # Database and file transfer directories
/var/log/waarp        # Waarp engine logs
```

## Environment variables
### Basics
* **WAARP_APPNAME**: Name of the engine instance. Default=`server1` _(Incremental naming recommanded for large or distributed deployments)_
* **WAARP_LANGUAGE**: Default=`en`
* **WAARP_ADMIN_PASSWORD**: Web console password. Default=`password`

### Database
Default Database type is `H2`.
If the container is linked to a Mysql or PosgreSQL database, password and username are automatically sets.

* **WAARP_DATABASE_TYPE**: Database type, on of h2, mysql, postgresql, default=`h2`
* **WAARP_DATBASE_NAME**: Database name. default=`${WAARP_APPNAME}_waarp`
* **WAARP_DATABASE_USER**: Database username. default=`waarp`
* **WAARP_DATABASE_PASSWORD**: Database password. default=`waarp`
* **WAARP_DATABASE_URL**: Database URL. default=`jdbc:${WAARP_DATABASE_TYPE}:/var/lib/waarp/${WAARP_APPNAME}/db/${WAARP_DATABASE_NAME};MODE=ORACLE;AUTO_SERVER=TRUE`

### Security Credentials
> Keystores are automatically generated at first run and can be updated afterward (use volume to `certs` directory).
Admin password and User database are regerenerated each time the container starts.

Waarp aims a strong level of transport security.
The following variables allows to set the various keys and passwords required to secure the Waarp instance:

* **WAARP_SSL_DNAME**: Certificate distinguished name. Default=`CN=${WAARP_APPNAME}\, OU=xfer\, O=MYCompany\, L=Paris\, S=Paris, C=FR`
* **WAARP_KEYSIZE**: Key length. Default=`2048`
* **WAARP_KEYALG**: Key algorithm. Default=`RSA`
* **WAARP_SIGALG**: Signature algorithm. Default=`SHA256withRSA`
* **WAARP_KEYVAL**: Lifetime. Default=`3650` _(days)_
* **WAARP_ADMKEYSTOREPASS**: Admin console keystore. Default=`password`
* **WAARP_ADMKEYPASS**: Admin console keypass. Default=`password`
* **WAARP_KEYSTOREPASS**: Waarp keystore.  Default=`password`
* **WAARP_KEYPASS**: Waarp keypass.  Default=`password`
* **WAARP_TRUSTKEYSTOREPASS**: Trusted keystore.  Default=`password`

### SNMP

Only SNMPv2 and SNMPv3 (SHA/AES 256) is enabled by default.

* **WAARP_SNMP_AUTHPASS**: SNMPv3 auth password. Default=`password`
* **WAARP_SNMP_PRIVPASS**: SNMPv3 priv password. Default=`password`

### FTP Account

Default ftps account are `fromFTP` and `toFTP`.

* **WAARP_FTPCLIENT_USER**: Host ID. default=`ftp-client`
* **WAARP_FTPCLIENT_PASSWORD**: FTP Password. default=`password`
* **WAARP_FTPCLIENT_RETREIVECMD**. Retreive command. default=`NONE`
* **WAARP_FTPCLIENT_STORECMD**. Store command. default=`NONE`

# Deployment using PostgreSQL
Database is created by the database container and automatically populated by the application container on first run.

```bash
docker run -it -d --name=waarp-gwftp-pg \
--restart=always \
-e POSTGRES_USER=waarp \
-e POSTGRES_PASSWORD=Ch4ng3M3 \
-e POSTGRES_DB=server1-waarp \
-v waarp-r66-db:/var/lib/postgresql \
postgres

sleep 10

docker run -it -d --name=waarp-gwftp \
--link waarp-gwftp-pg:postgres \
--restart=always \
-p 6666:6666 \
-p 6667:6667 \
-p 8066:8066 \
-p 8067:8067 \
-p 8088:8088 \
fjudith/waarp-gwftp
```

# Docker-Compose

You can use docker-compose to automate the above commands if you create a file called `docker-compose.yml` and and write inside the following content:

```
waarp-gwftp-pg:
  image: postgres
  restart: always
  environment:
    POSTGRES_DB: gwftp1-waarp
    POSTGRES_PASSWORD: Ch4ng3M3
    POSTGRES_USER: waarp
  volumes:
  - waarp-gwftp1-db:/var/lib/postgresql
  - waarp-gwftp1-db:/var/log/postgresql

waarp-gwftp:
  image: fjudith/waarp-gwftp
  restart: always
  environment:
    WAARP_APPNAME: gwftp1
    WAARP_ADMIN_PASSWORD: V3rY1ns3cur3P4ssw0rd
  ports:
  - 6621:6621/tcp
  - 8076:8076/tcp
  - 8077:8077/tcp
  - 50001-65534:50001-65534/tcp
  links:
  - waarp-gwftp-pg:postgres
  volumes:
  - waarp-gwftp1-etc:/etc/waarp
  - waarp-gwftp1-data:/var/lib/waarp
  - waarp-gwftp1-log:/var/log/waarp
```
And run the following command from the same directory of the docker-compose.yml:

```
docker-compose up -d
```
# Reference
* http://www.waarp.fr
* https://github.com/waarp