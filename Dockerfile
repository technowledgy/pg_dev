ARG PG_VERSION=14.1

FROM postgres:${PG_VERSION}-alpine

LABEL author Wolfgang Walther
LABEL maintainer pg-dev@technowledgy.de
LABEL license MIT

WORKDIR /usr/src
SHELL ["/bin/sh", "-eux", "-c"]

COPY tools /bin

RUN apk add \
        --no-cache \
        entr \
# to silence initdb "locale not found" warnings
        musl-locales \
        perl \
        the_silver_searcher \
### build deps
  ; apk add \
        --no-cache \
        --virtual build-deps \
        clang \
        gcc \
        git \
        icu-dev \
        llvm \
        make \
        musl-dev \
        patch \
        perl \
        perl-module-build \
        perl-test-pod \
        perl-test-pod-coverage \
        su-exec \
### pg_prove
  ; git clone --depth 1 --branch develop https://github.com/theory/tap-parser-sourcehandler-pgtap \
  ; (cd tap-parser-sourcehandler-pgtap \
   ; perl Build.PL \
   ; ./Build \
   ; ./Build test \
   ; ./Build install \
    ) \
### pgtap
  ; git clone --depth 1 --branch master https://github.com/theory/pgtap \
  ; (cd pgtap \
   ; make \
   ; make install \
# Running these pgtap tests implicitly tests pg_prove and with_tmp_db, too.
   ; chown -R postgres . \
   ; su-exec postgres sh -c 'echo "" | with_tmp_db make installcheck' \
   ; su-exec postgres sh -c 'echo "CREATE EXTENSION pgtap;" | with_tmp_db make test' \
    ) \
### plpgsql_check
  ; git clone --depth 1 --branch master https://github.com/okbob/plpgsql_check \
  ; (cd plpgsql_check \
   ; CFLAGS=-Wno-unused-parameter make \
   ; make install \
   ; chown -R postgres . \
   ; su-exec postgres sh -c 'echo "" | with_tmp_db make installcheck' \
    ) \
### cleanup
  ; rm -rf -- * \
  ; apk del --no-cache build-deps

USER postgres
