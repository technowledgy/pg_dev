ARG PG_VERSION=14.1

FROM postgres:${PG_VERSION}-alpine AS base

LABEL author Wolfgang Walther
LABEL maintainer pg-dev@technowledgy.de
LABEL license MIT

WORKDIR /usr/src
SHELL ["/bin/sh", "-eux", "-c"]

COPY tools /bin
COPY initdb /docker-entrypoint-initdb.d

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
        git \
        make \
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
# Running these pgtap tests implicitly tests pg_prove and with_pg, too.
   ; with_pg make installcheck \
   ; with_pg make test \
    ) \
### cleanup
  ; rm -rf -- * \
  ; apk del --no-cache build-deps

FROM base AS test

RUN apk add \
        --no-cache \
        --virtual build-deps \
        git \
### bats
  ; git clone --depth 1 --branch master https://github.com/bats-core/bats-core \
  ; (cd bats-core \
   ; ./install.sh / \
    ) \
### cleanup
  ; rm -rf -- * \
  ; apk del --no-cache build-deps

FROM base
