ARG PG_MAJOR=14

FROM postgres:10.22-alpine@sha256:8fd7adce93fa576236cc72295aa94d3862fc5f39c72bae557457ae603755051c AS pg10
FROM postgres:11.17-alpine@sha256:fc14518fc08466864e1916f2a0daf7b4a5bcdec8f65e8d8f1415efb249402b5f AS pg11
FROM postgres:12.12-alpine@sha256:55fb7ba926381c2ac1f8f58bb181dd932f140aa467c3097a07c6815648dbc5e2 AS pg12
FROM postgres:13.8-alpine@sha256:fc3670fa23119159394dfdb98eee89b30ef5a506791aea6ff7d8a4e73a8cd4a4 AS pg13
FROM postgres:14.5-alpine@sha256:322e9d80bbe0d19df45a2cfa262b50947683b4da283afdb6bee8e549aea87bf3 AS pg14

# patched pg14 with security_invoker for views
FROM technowledgy/postgres:14-alpine@sha256:5d0b09edacbc29f20a96d0a6eb03be97dcb08396c5861f156730a95d80262956 AS pg14-invoker

# hadolint ignore=DL3006
FROM pg${PG_MAJOR} AS base
LABEL author Wolfgang Walther
LABEL maintainer opensource@technowledgy.de
LABEL license MIT

WORKDIR /usr/src
SHELL ["/bin/sh", "-eux", "-c"]

COPY tools /usr/local/bin
COPY initdb /docker-entrypoint-initdb.d
COPY ext /usr/local/share/postgresql/extension

# renovate: datasource=github-tags depName=pg_prove lookupName=theory/tap-parser-sourcehandler-pgtap
ARG PG_PROVE_VERSION=v3.35

# renovate: datasource=github-tags depName=pgtap lookupName=theory/pgtap
ARG PGTAP_VERSION=v1.2.0

# renovate: datasource=github-tags depName=TAP::Harness::JUnit lookupName=jlavallee/tap-harness-junit
ARG TAP_HARNESS_JUNIT_VERSION=v0.40

### set up multi-process logging
RUN mkfifo /var/log/stdout \
### install deps
  ; apk add \
        --no-cache \
        coreutils \
        entr \
        git \
# to silence initdb "locale not found" warnings
        musl-locales \
        perl \
        perl-xml-simple \
        the_silver_searcher \
        tmux \
### build deps
  ; apk add \
        --no-cache \
        --virtual build-deps \
        build-base \
        perl-dev \
        perl-module-build \
        perl-test-deep \
        perl-test-pod \
        perl-test-pod-coverage \
        su-exec \
### pg_prove
  ; git clone --depth 1 --branch ${PG_PROVE_VERSION} https://github.com/theory/tap-parser-sourcehandler-pgtap \
  ; (cd tap-parser-sourcehandler-pgtap \
   ; perl Build.PL \
   ; ./Build \
   ; ./Build test \
   ; ./Build install \
    ) \
### pgtap
  ; git clone --depth 1 --branch ${PGTAP_VERSION} https://github.com/theory/pgtap \
  ; (cd pgtap \
   ; make \
   ; make install \
# Running these pgtap tests implicitly tests pg_prove and with pg, too.
   ; with pg with make installcheck \
   ; with pg with make test \
    ) \
### tap-harness-junit
  ; git clone --depth 1 --branch ${TAP_HARNESS_JUNIT_VERSION} https://github.com/jlavallee/tap-harness-junit \
  ; (cd tap-harness-junit \
   ; perl Build.PL \
   ; ./Build \
   ; ./Build test \
   ; ./Build install \
    ) \
### cleanup
  ; rm -rf -- /usr/src/* /tmp/* \
  ; apk del --no-cache build-deps

FROM base AS test

RUN apk add \
        --no-cache \
        ncurses \
        yarn \
  ; yarn global add \
         bats \
         bats-assert \
         bats-support

FROM base
