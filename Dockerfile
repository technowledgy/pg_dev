ARG PG_MAJOR=15

FROM postgres:10.23-alpine@sha256:63cfb6eac6b362c7c994f22c3804c61b31898cf0cb52f8e7e86bd99a244f4366 AS pg10
FROM postgres:11.20-alpine@sha256:abed8d4c6fd728512f8b44d8ed9c2bcf624fd5523126c7e6df577fd4c60beb74 AS pg11
FROM postgres:12.15-alpine@sha256:0c9bec7e9e6b55772768390b96a9949773e1753c2098a8e2582b16a81abab293 AS pg12
FROM postgres:13.11-alpine@sha256:ace35ca529a7b68e93a8c6cb4f9bf945137293c4d284729ff2f620ca06b8ca19 AS pg13
FROM postgres:14.8-alpine@sha256:28407a9961e76f2d285dc6991e8e48893503cc3836a4755bbc2d40bcc272a441 AS pg14
FROM postgres:15.3-alpine@sha256:8aa5154e724b1d5c23d3df387a65e975d67253292d224ffdc22d125c0d6d4bda AS pg15

# patched pg14 with security_invoker for views
FROM technowledgy/postgres:14-alpine@sha256:77d7dd921a405ea881046eeea9dea2397d61e02a096dda81c2b26a4a3d25e77b AS pg14-invoker

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
