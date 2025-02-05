// Help from : https://betterstack.com/community/guides/logging/logging-in-go/
package observability

import (
	"log/slog"
	"os"
)

var Logger = slog.New(
	slog.NewJSONHandler(
		os.Stdout,
		&slog.HandlerOptions{Level: slog.LevelDebug},
	),
)

func InitLogger(level slog.Level, name string, goVersion string) {
	Logger = slog.New(
		slog.NewJSONHandler(
			os.Stdout,
			&slog.HandlerOptions{Level: level},
		),
	).
		With(slog.Group(
			"program_info",
			"go_version", goVersion,
			"name", name,
		))
}
