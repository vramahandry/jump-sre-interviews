## Example:
## A la racine du repo
## $> docker build . -t api/a:0.0.0 -f ./applications/services/a/Dockerfile

FROM golang:1.23.1 as builder

WORKDIR /app
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a --installsuffix cgo -o service-a ./applications/services/a

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /app/service-a .

ENTRYPOINT ["./service-a"]
