BEGIN;

CREATE TABLE IF NOT EXISTS users (
    ID UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_name TEXT NOT NULL,
    first_name TEXT NOT NULL,
    email TEXT NOT NULL
);

INSERT INTO users
    ( last_name, first_name, email )
VALUES
    ( 'Claireau', 'Penelope', 'penelope-claireau@test.local'),
    ( 'Jones', 'Ansel', 'jonesa@test.local'),
    ( 'Buire', 'Xavier', 'x.buire@test.local'),
    ( 'Poisson', 'Avril', 'poisson.avril.1@test.local'),
    ( 'Minot', 'Nicolas', 'nicolas.minot@test.local'),
    ( 'Glairier', 'Christelle', 'gc@test.local');

COMMIT;