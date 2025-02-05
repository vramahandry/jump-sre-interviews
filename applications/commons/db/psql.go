package db

import (
	"database/sql"
	"fmt"
	"os"

	"github.com/XSAM/otelsql"
	_ "github.com/lib/pq"
	"go.opentelemetry.io/otel"
	semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
	"gopkg.in/yaml.v3"
)

type Config struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	User     string `yaml:"user"`
	Name     string `yaml:"name"`
	Password string `yaml:"password"`
	SSLMode  string `yaml:"ssl_mode"`
}

func readConfiguration(path string) (Config, error) {
	errMsg := "readConfiguration has failed with file: " + path
	yamlFile, err := os.ReadFile(path)
	if err != nil {
		return Config{}, fmt.Errorf("%s: ReadFile err: %w", errMsg, err)
	}

	var conf Config
	err = yaml.Unmarshal(yamlFile, &conf)
	if err != nil {
		return Config{}, fmt.Errorf("%s: Unmarshal err: %w", errMsg, err)
	}

	conf.Password = os.Getenv("POSTGRES_PASSWORD")
	if conf.Password == "" {
		return Config{}, fmt.Errorf("%s: no password given", errMsg)
	}

	return conf, nil
}

func NewPSQLDB(configPath string) (*sql.DB, error) {
	conf, err := readConfiguration(configPath)
	if err != nil {
		return nil, fmt.Errorf("NewPSQLDB has failed: %w", err)
	}

	return newPsqlDB(conf)
}

func newPsqlDB(conf Config) (*sql.DB, error) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s",
		conf.Host, conf.Port, conf.User, conf.Password, conf.Name)

	if conf.SSLMode != "" {
		psqlconn += fmt.Sprintf(" sslmode=%s", conf.SSLMode)
	}

	db, err := otelsql.Open(
		"postgres",
		psqlconn,
		otelsql.WithAttributes(
			semconv.DBSystemPostgreSQL,
		),
		otelsql.WithTracerProvider(otel.GetTracerProvider()),
	)
	if err != nil {
		return nil, fmt.Errorf("otelsql.Open error: %w", err)
	}

	err = db.Ping()
	if err != nil {
		return nil, err
	}

	return db, nil
}
