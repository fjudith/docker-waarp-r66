# Introduction

Waarp est moniteur de transfert de fichiers (MFT) libre et open-source developpé en Java sur la base du Framework Netty.
Il se compose d'un ensemble d'outils d'adressant aux différents scénario d'utilisation des échanges de fichiers.

* **Waarp R66 server**: Le moniteur et coeur du moteur de Waarp utilisant le protole R66.
* **Waarp Gateway**: Composant qui porte la compatiblité avec des protocoles tiers (e.g. FTP/S)
* **Waarp R66 Proxy**: Composant dédié aux échanges R66 en DMZ
* **Waarp Manager**: (Payant) Console centralisée d'administration et de supervision

## Historique

Waarp est un projet qui fût initialement développé pour la Direction Generale des Finances Publiques Française (DGFIP) et livré en 2007.
A cette occasion trois composants ont été implémentés:

* **OpenR66**: Le protocole d'échange alternatif à PeSIT
* **Golden Gate**: Ancien nom du moniteur Waarp-R66
* **Golden Gate FTP**: Connu désormais sous le nom de Waarp Gateway FTP

Depuis 2013, Waarp est également utilisé par la Direction General de la Gendarmerie Nationale (DGGN) dans le cadre de l'archivage documentaire de plus 4000 sites.

En chiffre, Waarp est déployé sur 30 sites régionaux et gère un volume quotidien de 100000 échanges à la DGFIP et respectivement 30 et 10000 pour la DGGN.

## Sécurité

Waarp supporte le chiffrement `SSL avec authentification mutuelle client/serveur` en mode pour le transfert et `DES` pour stocker les mots de passe.
Le protocole `HTTPS` est forcé par défaut sur les consoles d'administration Waarp-R66 et Waarp Manager.

## Distribution

Waarp est distrubé sous la forme d'une archive ZIP multi-plateforme ou sous de paquets compatible Redhat/Centos 6.
Une image Docker est également maintenue par la communauté.

https://hub.docker.com/r/fjudith/waarp-r66

## Architecture

### Système d'exploitation

Waarp est developpé en Java sous forme de fichiers JAR. Il supporte donc tous les systèmes d'exploitation support Java 1.7.

- Unix
- Linux
- Windows
- MacOS

### Base de donnée

Bien que reposant sur le pilote Jave Database Database Connectivity, Waarp ne support que les que les système de gestion de base de données relationels (SGBDR) suivant:

- Oracle
- Postgres
- MySQL
- H2

Ces moteurs sont supporté aussi bien en mode centralisé que distribué.


### Interaction

Hormis la console Web dont les fonctionnalité sont quelque peu limitée, Waarp fournie trois cannaux d'interaction permettant l'administration et la gestion des transferts.

- Batch: Ligne de commande
- API: Api REST
- GUI: Interface graphique
- XML: Fichier XML + Batch. (Limité la configuration)

### Tâche événnementielle

Les moniteurs de transfert de fichiers se distinguent par leur capacité à exécuter des process selon l'état d'avancement de la transaction.
Waarp permet de déclancher des process simultanément côté emmetteur et recepteur:

- Avant la transaction `pretasks`
- Après la transaction `posttasks`
- En cas d'échec de la transaction `errortasks`

Pour chacune de ces étapes plusieurs tâches peuvent être exécutées séquentiellement.

* **LOG**: Journalise ou créé un fichier contenant un message
* **SNMP**: Emet une interruption (trap) SNMP
* **MOVE**: Déplace le fichier dans le répertoire désigné en argument
* **MOVERENAME**: Déplace et renomme le fichier dans le répertoire désigné en argument
* **COPY**: Copie le fichier dans le répertoire désigné argument
* **COPYRENAME**: Copie et renomme le fichier dans le répertoire désigné en arguement 
* **LINKRENAME**: Créé un lien symbolique entre le fichier actuel et le fichier désigné en argument
* **RENAME**: Renomme le fichier actuel dans un autre répertoire (e.g in/fileA, out/fileB)
* **DELETE**: Supprime le fichier faisant l'objet du transfert
* **VALIDEPATH**: Test si le fichier est présent dans l'un des répertoires fournie en argument
* **CHKFILE**: 
* **TRANSCODE**: Transcode le fichier actuel d'une table de caractère vers un autre fichier utilisant une table de caractère tierse.
* **TAR**: Créé une archive TAR ou UNTAR le nom de fichier fournie en argument.
* **ZIP**: Créé une archive ZIP ou UNZIP le nom de fichier fournie en argument.
* **UNZEROED**:
* **CHMOD**: 
* **EXEC**: Exécute une commande externe selon le chemin et les informations de transfert transmisent en argument
* **EXECMODE**: Exécute une commande externe selon le chemin et les informations de transfert transmisent en argument, puis marque le fichier comme étant déplacé.
* **EXECOUTPUT**: Exécute une commande externe selon le chemin et les informations de transfert transmisent en argument. Ne marque le fichier comme étant déplacé, sauf si la variable #NEWFILENAME est utilisé en préfixe du nom de fichier
* **EXECJAVA**: Exécute une classe Java selon le chemin et les informations de transfert transmisent en argument
* **TRANSFER**: Soumet un nouveau transfert basé sur le chemin et les informations de transfert fournies en arguement. (utilise la formulation waarp-r66client send/recv)
* **FTP**: Initie un transfert FTP Synchrone.
* **RESCHEDULE**: Replanifie le transfert selon un délais estimé en millisecondes
* **RESTART**: Recommence le transfert

> Pour plus d'information: http://waarp.github.io/Waarp/res/document/onedocumentwaarp.pdf 

### Transaction

Waarp supporte les transactions en mode émission (SEND) et reception (RECV).

> n. Push et Pull

En mode SEND: 

* A se connecte à B.
* B authentifie A (i.e identifiant, mot de passe, certificats)
* B valide l'identifiant commun de la règle de transfert annoncé A.
  * (Optionnel) A exécute la procédure de pré-émission `spretasks`
  * (Optionnel) B exécute la procédure de pré-reception `rpretasks`
* A débute l'émission du fichier à l'hôte B.
* B Reçois le fichier dans le fichier dans son répertoire de travail.
  * (En cas d'erreur) A exécute la procédure d'erreur en émission `serrortasks`
  * (En cas d'erreur) A exécute la procédure d'erreur en émission `rerrortasks`
* A Clôture le transfert. B Déplace le fichier du répertoire de travail vers le répertoire de réception.
  * (Optionnel) A exécute la procédure de post-émission `rposttasks`
  * (Optionnel) B exécute la procédure de post-reception `rposttasks`

En mode RECV: 

* A se connecte à B.
* B authentifie A (i.e identifiant, mot de passe, certificats)
* B valide l'identifiant commun de la règle de transfert annoncé A.
  * (Optionnel) B exécute la procédure de pré-émission `spretasks`
  * (Optionnel) A exécute la procédure de pré-reception `rpretasks`
* B débute l'émission du fichier à l'hôte A.
* A Reçois le fichier dans le fichier dans son répertoire de travail.
  * (En cas d'erreur) B exécute la procédure d'erreur en émission `serrortasks`
  * (En cas d'erreur) B exécute la procédure d'erreur en émission `rerrortasks`
* B Clôture le transfert. B Déplace le fichier du répertoire de travail vers le répertoire de réception.
  * (Optionnel) B exécute la procédure de post-émission `rposttasks`
  * (Optionnel) A exécute la procédure de post-reception `rposttasks`