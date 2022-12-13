ARG PG_MAJOR=14

FROM postgres:10.23-alpine@sha256:63cfb6eac6b362c7c994f22c3804c61b31898cf0cb52f8e7e86bd99a244f4366 AS pg10
FROM postgres:11.18-alpine@sha256:4a6be41f4176af134fe8a02b9f07928fab22fb1fb2777811360154912cb682cd AS pg11
FROM postgres:12.13-alpine@sha256:1c3dbfae0eba1390de48752fcd0c2bd229e4b7820065d6e4fd58928c17400994 AS pg12
FROM postgres:13.9-alpine@sha256:4f9369495218c2edb4ef6c1937e1b7f264935e85e4a16035ccee7a6f1154bda4 AS pg13
FROM postgres:14.6-alpine@sha256:1785b8611bb46e7b8776841be5febc322cdb84c3b72c12bfed364379ecdf9b0d AS pg14
FROM postgres:15-alpine@sha256:4f7921976c1fdb4e4e2260f0b097e646c8d4c8dbd50bc552ba631f5357e955ff AS pg15

# patched pg14 with security_invoker for views
FROM technowledgy/postgres:14-alpine@sha256:4e1d688abb7f23f51baebb65048f244f14908638aeb3c911174e42cbccab4d63 AS pg14-invoker

# hadolint ignore=DL3006
FROM pg${PG_MAJOR} AS base
LABEL org.opencontainers.image.authors Wolfgang Walther
LABEL org.opencontainers.image.source https://github.com/technowledgy/pg_dev
LABEL org.opencontainers.image.licences MIT

WORKDIR /usr/src
SHELL ["/bin/sh", "-eux", "-c"]

COPY tools /usr/local/bin
COPY initdb /docker-entrypoint-initdb.d
COPY ext /usr/local/share/postgresql/extension

# renovate: datasource=github-tags depName=pg_prove lookupName=theory/tap-parser-sourcehandler-pgtap versioning=perl
ARG PG_PROVE_VERSION=v3.36

# renovate: datasource=github-tags depName=pgtap lookupName=theory/pgtap
ARG PGTAP_VERSION=v1.2.0

# renovate: datasource=github-tags depName=TAP::Harness::JUnit lookupName=jlavallee/tap-harness-junit versioning=perl
ARG TAP_HARNESS_JUNIT_VERSION=v0.40

### set up multi-process logging
RUN mkfifo /var/log/stdout \
### install deps
  ; apk add \
        --no-cache \
        # nss_wrapper is currently only available in testing
        --repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
        coreutils \
        nss_wrapper \
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
