package main

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID         uuid.UUID
	Created_at time.Time
	LastName   string
	FirstName  string
	email      string
}

type UserStore struct {
	db *sql.DB
}

const listUsersQuery = `
SELECT ID, created_at, last_name, first_name, email FROM users
`

func (u *UserStore) ListUsers(ctx context.Context) ([]User, error) {
	const errMsg = "UserStore.ListUsers has failed"

	rows, err := u.db.QueryContext(ctx, listUsersQuery)
	if err != nil {
		return nil, fmt.Errorf("%s: QueryContext err: %w", errMsg, err)
	}

	users := []User{}
	for rows.Next() {
		user := User{}
		if err := rows.Scan(
			&user.ID,
			&user.Created_at,
			&user.LastName,
			&user.FirstName,
			&user.email,
		); err != nil {
			return nil, fmt.Errorf("%s: Scan err: %w", errMsg, err)
		}
		users = append(users, user)
	}

	return users, nil
}
