SELECT 'CREATE DATABASE hasura_app'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hasura_app')\gexec

SELECT 'CREATE DATABASE bbb_graphql'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bbb_graphql')\gexec

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'hasura_app') THEN
    CREATE USER hasura_app WITH PASSWORD 'hasura_app';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bbb_hasura') THEN
    CREATE USER bbb_hasura WITH PASSWORD 'bbb_hasura';
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE hasura_app TO hasura_app;
GRANT ALL PRIVILEGES ON DATABASE bbb_graphql TO postgres;
GRANT CONNECT ON DATABASE bbb_graphql TO bbb_hasura;
