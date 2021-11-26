# pg_dev

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/technowledgy/pg_dev/Push%20to%20main)
![GitHub](https://img.shields.io/github/license/technowledgy/pg_dev)

This images uses the official postgres docker image as a base and adds tooling for development. It's considered a drop-in replacement during development, while running the official image in production.

## Bundled Tools and Scripts

Currently, the following tools are added:

- [pgTAP](https://pgtap.org)
- [`pg_prove`](https://metacpan.org/pod/TAP::Parser::SourceHandler::pgTAP)

As well as some helper scripts:
- `pgtap`: Opinionated helper to set up pgtap, load the schema and run pgTAP tests. Uses `with_tmp_db` internally.
- `with_sql`: Wrapper to create schema from .sql file via psql.
- `with_tmp_db`: Sets up a temporary database to run tests against. Adapted from [PostgREST](https://github.com/PostgREST/postgrest/blob/main/test/with_tmp_db).
- `with_watcher`: Enable watch mode for tests.

## How to use

Mount your source code into the container and run `pgtap` with a temporary database in watch mode:

```bash
docker run --rm -v "$PWD:/usr/src" with_watcher with_tmp_db with_sql schema.sql pgtap
```

This will load the schema defined in `schema.sql` through psql, create the pgTAP extension in a `pgtap` schema and then run pg_prove on all `.spec.sql` files found recursively.