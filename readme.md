# Test Technique DevOps/SRE

Bienvenue dans ce test technique pour le poste de DevOps/SRE. Votre mission est de déployer une application, ses dépendances (ex : database) ainsi qu'une solution opensource de logging et tracing en respectant les consignes ci-dessous.

## 🛠️ Étape 1 : l'application

L'application est une API faite en go qui créée des logs ainsi que des traces grâce à [OpenTelemetry](https://opentelemetry.io/docs/what-is-opentelemetry/).
Vous n'avez pas besoin de comprendre le code pour ce test.

L'application a besoin d'une base de donnée **postgresql** pour fonctionner et d'initialiser sa table sql **avant son démarrage**.
Avant de commencer le test technique, veuillez lancer en local l'API en suivant les instructions suivantes :

1. Démarrer une base de données PostgreSQL avec Docker :

   ```bash
   $> docker run -d --name postgres \
     -e POSTGRES_USER=admin \
     -e POSTGRES_PASSWORD=admin \
     -e POSTGRES_DB=postgres \
     -p 5432:5432 postgres:14
   ```

2. Appliquer les migrations de base de données :

   ```bash
   $> cd ./applications/services/a/db
   $> docker run \
   --rm --network host \
   -v $(pwd)/migrate:/tmp/migrate migrate/migrate \
   -path=/tmp/migrate -database "postgresql://admin:admin@localhost:5432/postgres?sslmode=disable" -verbose up
   ```

3. Vérifier que la base de données est bien initialisée :

   ```bash
   $> psql -h localhost -U admin -d postgres -c 'select * from users;'  # Mot de passe : admin
   ```

4. Configurer l’application :

   ```bash
   $> cd ..
   $> cat <<EOF > ./configuration.yaml
   host: 127.0.0.1
   port: 5432
   user: admin
   name: postgres
   ssl_mode: disable
   EOF
   ```

5. Lancer l’application :

   ```bash
   $> POSTGRES_CONFIGURATION='./configuration.yaml' \
   POSTGRES_PASSWORD='admin' \
   go run ./...

   $> curl 127.0.0.1:8080/users | jq
   $> curl -v 127.0.0.1:8080/readiness
   $> curl -v 127.0.0.1:8080/liveness
   ```

L'API écrit par défaut les traces sur la sortie standard, mais la variable environment `OTLP_ENDPOINT` permet de configurer la sortie des traces.

Vous trouverez les dockerfiles :
* de [l'api](applications/services/a/Dockerfile)
* de la [migration sql](applications/services/a/db/Dockerfile)

Nous vous conseillons de ne pas les modifier.

> Example : `OTLP_ENDPOINT=tempo.local:4318` envoie les traces sur un server grafana tempo

## ☁️ Étape 2 : Se connecter à AWS

Vous recevrez des identifiants AWS pour cette étape. Assurez-vous de bien les configurer.


## 🚀 Étape 3 : Déployer sur AWS

- Tout doit être déployé à l'aide de **terraform** (un bonus sera accordé si le projet est déployé avec **terragrunt**).
- Vous pouvez utiliser les services aws que vous voulez, mais imposons l'usage d' **Amazon EKS (Kubernetes managé)** pour deployer l'API.

> Nous avons déjà autorisé l'utilisation de certains services AWS sur le compte fournit, n'hésitez pas à nous contacter si les services qui vous intéressent sont bloqués.


## 🖥️ Étape 5 : Automatisation du déploiement

Le déploiement doit être fait en moins de ligne de commande possible (un bonus sera accordé si le déploiement est fait en une seule ligne de commande).


## 👤 Résultat

Lorsque vous avez terminé :
- Rassemblez tous les fichiers nécessaires pour comprendre et déployer votre solution.
- Ajoutez une **documentation claire** pour une personne n'ayant pas de compétences particulières en DevOps/SRE.
- Envoyez votre solution à l'adresse email suivante :  
  **engineering+sre_interview@join-jump.com**

Bonne chance ! 🚀


