package middlewares

import (
	"net/http"
	"time"

	"github.com/Freelance-launchpad/sre-interviews/applications/commons/observability"
)

type wrappedWriter struct {
	http.ResponseWriter
	statusCode int
}

func (w *wrappedWriter) WriteHeader(StatusCode int) {
	w.ResponseWriter.WriteHeader(StatusCode)
	w.statusCode = StatusCode
}

func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		responseWriter := wrappedWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		next.ServeHTTP(&responseWriter, r)
		if responseWriter.statusCode <= 200 && responseWriter.statusCode < 300 {
			observability.Logger.Info(
				r.URL.Path,
				"method", r.Method,
				"statusCode", responseWriter.statusCode,
				"duration", time.Since(start).String(),
				"time", time.Now().UTC().Format(time.RFC3339Nano),
			)
		} else {
			observability.Logger.Error(
				r.URL.Path,
				"method", r.Method,
				"statusCode", responseWriter.statusCode,
				"duration", time.Since(start).String(),
				"time", time.Now().UTC().Format(time.RFC3339Nano),
			)
		}
	})
}
