## Example:
## dans le dossier applications/services/a/db
## docker build . -t migration:0.0.0

FROM migrate/migrate

COPY . .

ENTRYPOINT ["sh", "-c", "migrate -path=./migrate -database \"postgresql://$POSTGRES_USERNAME:$POSTGRES_PASSWORD@postgres:5432/postgres?sslmode=disable\" -verbose up"]
