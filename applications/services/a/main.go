package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"runtime"

	postgres "github.com/Freelance-launchpad/sre-interviews/applications/commons/db"
	"github.com/Freelance-launchpad/sre-interviews/applications/commons/middlewares"
	"github.com/Freelance-launchpad/sre-interviews/applications/commons/observability"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

var (
	name      = "a"
	goVersion = runtime.Version()
)

func listUsers(store UserStore) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		users, err := store.ListUsers(r.Context())
		if err != nil {
			observability.Logger.Error("list user", "error", err.Error())
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("INTERNAL_SERVER_ERROR"))
			return
		}

		body, err := json.Marshal(users)
		if err != nil {
			observability.Logger.Error("json unmarshal", "error", err.Error())
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("INTERNAL_SERVER_ERROR"))
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write(body)
	}
}

func main() {
	ctx := context.Background()

	observability.InitLogger(slog.LevelDebug, name, goVersion)

	otelShutdown, err := observability.SetupOtelSDK(ctx, os.Getenv("OTLP_ENDPOINT"), name)
	if err != nil {
		observability.Logger.ErrorContext(ctx, "unable to setup tracing", "error", err.Error())
		return
	}

	defer func() {
		if err := errors.Join(err, otelShutdown(ctx)); err != nil {
			observability.Logger.ErrorContext(ctx, "error while shutting tracing", "error", err.Error())
		}
	}()

	db, err := postgres.NewPSQLDB(os.Getenv("POSTGRES_CONFIGURATION"))
	if err != nil {
		observability.Logger.ErrorContext(ctx, "unable to setup postgresql connection", "error", err.Error())
		return
	}
	userStore := UserStore{db: db}

	router := http.NewServeMux()

	router.HandleFunc("GET /users", listUsers(userStore))
	router.HandleFunc("GET /liveness", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	router.HandleFunc("GET /readiness", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	stack := middlewares.Chaines(
		middlewares.Logging,
		otelhttp.NewMiddleware(
			"/",
			otelhttp.WithSpanNameFormatter(observability.HTTPSpanName),
		),
	)

	server := http.Server{
		Addr:    ":8080",
		Handler: stack(router),
	}

	observability.Logger.InfoContext(ctx, "launch server on :8080")
	server.ListenAndServe()
}
