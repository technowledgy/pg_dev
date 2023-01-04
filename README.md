# pg_dev

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/technowledgy/pg_dev/push.yaml?branch=main)
![GitHub](https://img.shields.io/github/license/technowledgy/pg_dev)

This images uses the official postgres docker image as a base and adds tooling for development. It's considered a drop-in replacement during development, while running the official image in production.

## Bundled Tools and Scripts

Currently, the following tools are added:

- [pgTAP](https://pgtap.org)
- [`pg_prove`](https://metacpan.org/pod/TAP::Parser::SourceHandler::pgTAP)

As well as some helper scripts:
- `tool`: Starts a tmux session to control output of other scripts.
- `with async`: Runs interactive prompts like a shell or psql without blocking the command chain.
- `with menu`: Provides a menu to choose options from other `with` helpers from.
- `with pg`: Sets up a temporary database to run tests against. Inspired by [PostgREST](https://github.com/PostgREST/postgrest/blob/main/test/with_tmp_db).
- `with sql`: Wrapper to create schema from .sql file via psql.
- `with watcher`: Enable watch mode for tests.

## How to use

Mount your source code into the container and run `pg_prove` with a temporary database in watch mode:

```bash
docker run --rm -v "$PWD:/usr/src" \
  tool \
    with menu \
    with watcher \
    with pg \
    with_sql schema.sql \
    with pg_prove -r --ext .spec.sql --pgtap-option suffix=.sql
```

This will load the schema defined in `schema.sql` through psql, create the pgTAP extension in a `pgtap` schema and then run pg_prove on all `.spec.sql` files found recursively.
