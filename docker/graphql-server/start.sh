#!/bin/bash
set -euo pipefail

cd /app

until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" >/dev/null 2>&1; do
  echo "Waiting for postgres at ${PGHOST}:${PGPORT}..."
  sleep 2
done

yq e -i ".[1].configuration.connection_info.database_url = \"${HASURA_GRAPHQL_BBB_DATABASE_URL}\"" metadata/databases/databases.yaml
sed -i "s/^admin_secret: .*/admin_secret: ${HASURA_GRAPHQL_ADMIN_SECRET}/g" /app/config.yaml
sed -i "s#endpoint: .*#endpoint: http://127.0.0.1:${HASURA_GRAPHQL_SERVER_PORT}#g" /app/config.yaml

psql -v ON_ERROR_STOP=1 -c "SELECT 'CREATE DATABASE hasura_app' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hasura_app')\gexec"
psql -v ON_ERROR_STOP=1 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'bbb_graphql' AND pid <> pg_backend_pid();" >/dev/null || true
psql -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS bbb_graphql WITH (FORCE);"
psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE bbb_graphql;"
psql -v ON_ERROR_STOP=1 -c "ALTER DATABASE bbb_graphql SET timezone TO 'UTC';"
psql -v ON_ERROR_STOP=1 -d bbb_graphql -q -f /app/bbb_schema.sql --set ON_ERROR_STOP=on

echo "Starting hasura-graphql-engine"
gosu nobody graphql-engine serve &
PID=$!

while ! netstat -tuln | grep -q ":${HASURA_GRAPHQL_SERVER_PORT} "; do
  echo "Waiting for Hasura port ${HASURA_GRAPHQL_SERVER_PORT}..."
  sleep 1
done

echo "Applying Hasura metadata"
/usr/local/bin/hasura metadata apply --skip-update-check --endpoint "http://127.0.0.1:${HASURA_GRAPHQL_SERVER_PORT}" --admin-secret "${HASURA_GRAPHQL_ADMIN_SECRET}"

wait "$PID"
