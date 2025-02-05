package observability

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

func newConsoleExporter() (trace.SpanExporter, error) {
	return stdouttrace.New()
}

func newOTLEporter(ctx context.Context, endpoint string) (trace.SpanExporter, error) {
	return otlptracehttp.New(
		ctx,
		otlptracehttp.WithInsecure(),
		otlptracehttp.WithEndpoint(endpoint),
	)
}

func newTraceProvider(ctx context.Context, endpoint string, appName string) (*trace.TracerProvider, error) {
	var exporter trace.SpanExporter
	var err error
	if endpoint != "" {
		exporter, err = newOTLEporter(ctx, endpoint)
	} else {
		exporter, err = newConsoleExporter()
	}
	if err != nil {
		return nil, err
	}

	r, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(appName),
		),
	)
	if err != nil {
		return nil, err
	}

	traceProvider := trace.NewTracerProvider(
		trace.WithBatcher(exporter, trace.WithBatchTimeout(time.Second)),
		trace.WithResource(r),
	)
	return traceProvider, nil
}

func SetupOtelSDK(ctx context.Context, endpoint string, appName string) (shutdown func(context.Context) error, err error) {
	var shutdownFuncs []func(context.Context) error

	shutdown = func(ctx context.Context) error {
		var err error

		for _, fn := range shutdownFuncs {
			err = errors.Join(err, fn(ctx))
		}

		shutdownFuncs = nil
		return err
	}

	handleErr := func(inErr error) {
		err = errors.Join(inErr, shutdown(ctx))
	}

	traceProvider, err := newTraceProvider(ctx, endpoint, appName)
	if err != nil {
		handleErr(err)
		return
	}

	shutdownFuncs = append(shutdownFuncs, traceProvider.Shutdown)
	otel.SetTracerProvider(traceProvider)
	otel.SetTextMapPropagator(propagation.TraceContext{})

	return
}

func HTTPSpanName(operation string, r *http.Request) string {
	return fmt.Sprintf("HTTP %s %s", r.Method, r.URL.Path)
}
