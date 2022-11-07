ARG PG_MAJOR=14

FROM postgres:10.22-alpine@sha256:8ee4d835d1173ebb2ca2a1f45d7fbbb99eecb506b635c35ea7d137d25e0ce28b AS pg10
FROM postgres:11.17-alpine@sha256:4ec053dcacd7c50b19b06210d1916d554f9aef05455d0e4eac3332c26211b51a AS pg11
FROM postgres:12.12-alpine@sha256:06398adf86069c9c2d707bc1fa6621338ae53c6601fbae318eb09e9daa50534b AS pg12
FROM postgres:13.8-alpine@sha256:4ae1cf0ccaa11c25b90103553beecb7c4e5b44cfdf3bf81171ec784de8b79df4 AS pg13
FROM postgres:14.5-alpine@sha256:ac09c433f64f2d310a83e5cc24dadc13561f645199d4ec8e503824de22e14668 AS pg14
FROM postgres:15-alpine@sha256:f46b2ae1a00a87552a52fe83d36f7aef60ef61f9d64baf3bfc4abaa89847024b AS pg15

# patched pg14 with security_invoker for views
FROM technowledgy/postgres:14-alpine@sha256:7c0f1aa810a52f179ea14ae0ba96963221488cc4d0984ad7a098288498fd3cd2 AS pg14-invoker

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
