#!/bin/sh
# Docker entrypoint script.

# Wait until Postgres is ready
while ! pg_isready -q -d $DB_URL
do
  echo "$(date) - waiting for database to start"
  sleep 10
done

echo "Connected to the database"

# Run migrations
SECRET_KEY_BASE=$SECRET_KEY_BASE DB_URL=$DB_URL \
  ./prod/rel/bank/bin/bank eval Bank.Release.migrate

# Run Phoenix app
SECRET_KEY_BASE=$SECRET_KEY_BASE DB_URL=$DB_URL \
  ./prod/rel/bank/bin/bank start

