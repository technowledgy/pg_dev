ARG PG_MAJOR=14

FROM postgres:10.21-alpine@sha256:27a7a7da0883d5907415902c1b0e0d5033b9eb7b9588b5c5108dc863d2c69685 AS pg10
FROM postgres:11.16-alpine@sha256:5c42b2e19b9d0fbb9c574ed01a0a3fd2d37ed6eaa0486b0d6bb054938a3e96ed AS pg11
FROM postgres:12.11-alpine@sha256:2ecec7c3e880d004ff2c941ee5553c347b602ab839daf8a46aeba7cedb51ccaf AS pg12
FROM postgres:13.7-alpine@sha256:df49804c08bc8b5a082f8e348d36d632c3f353562716cfbb11231a31c7bfc433 AS pg13
FROM postgres:14.4-alpine@sha256:4ea11d3110e47a360ace22bbca73b2ebaa6dd2eec289e0b6949e4d96e2d4ba4c AS pg14

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
