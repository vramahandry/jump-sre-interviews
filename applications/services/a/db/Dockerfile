## Example:
## dans le dossier applications/services/a/db
## docker build . -t migration:0.0.0

FROM migrate/migrate

COPY ./applications/services/a/db/migrate ./tmp/migrate

ENTRYPOINT ["sh", "-c", "migrate -path=./tmp/migrate -database \"postgresql://$POSTGRES_USERNAME:$POSTGRES_PASSWORD@$POSTGRES_HOST:5432/postgres?sslmode=disable\" -verbose up"]
