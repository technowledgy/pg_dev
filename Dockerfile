ARG PG_MAJOR=15

FROM postgres:10.23-alpine@sha256:63cfb6eac6b362c7c994f22c3804c61b31898cf0cb52f8e7e86bd99a244f4366 AS pg10
FROM postgres:11.19-alpine@sha256:83a139c56cd318433bedaf07e7e127a9cac0cc81a7c48d8b2d12bd47da186291 AS pg11
FROM postgres:12.14-alpine@sha256:60b42ee4ee30dec1e0f03c44f2cf510550d56f08b0daf7d3954cc0464fdd2e04 AS pg12
FROM postgres:13.10-alpine@sha256:f5870b5a4d72544ee40a90b4b8574db808cdd4980168ff4d1e08ddf3e69d1863 AS pg13
FROM postgres:14.7-alpine@sha256:f56d60bbff317706f8264d631a45526f8f1c1bb7cffaa09f33582cd894cd0ca3 AS pg14
FROM postgres:15.2-alpine@sha256:07ec36ad2d5ab9250f38c8ef749239b662cf15d03c9ddb7167422edbbdf71156 AS pg15

# patched pg14 with security_invoker for views
FROM technowledgy/postgres:14-alpine@sha256:a4f3c83c894f4b7de1817f625e85f42c45da624f6ac2f1359b782bb7265dae0f AS pg14-invoker

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
