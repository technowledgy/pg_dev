ARG PG_MAJOR=16

FROM postgres:12.19-alpine@sha256:f2d204bc40c7cf3b929977208e0eda0d5672b5c4c3f788e886e90e12982bf8f0 AS pg12
FROM postgres:13.15-alpine@sha256:c1ec55f10506775b62f85eefc61a594bc78366a7499f9eb007945fb3b4cd1584 AS pg13
FROM postgres:14.12-alpine@sha256:55633b9ab4c34e2844648f9ab877b46a87c36fc3d32f06a0c7d1703360d4fa81 AS pg14
FROM postgres:15.7-alpine@sha256:ede3a168dae0d2154440c2b1b2c7773201bfa969d85a1859c44b6f4ab2df0ef7 AS pg15
FROM postgres:16.3-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065 AS pg16

# patched pg14 with security_invoker for views
FROM technowledgy/postgres:14-alpine@sha256:397a998dc1e42a63cfc8a8ab024d8ab1e47f7af6abb43bbb89bb8c4174638d23 AS pg14-invoker

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
ARG PGTAP_VERSION=v1.3.3

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
        clang15 \
        llvm15 \
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
   ; with pg with sql <(echo "DROP SCHEMA pgtap CASCADE; CREATE EXTENSION pgtap;") with make test \
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
