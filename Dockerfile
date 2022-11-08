FROM --platform=${BUILDPLATFORM} ghcr.io/instrumentisto/rust:1.64.0-buster as build
ARG TARGETARCH
WORKDIR /work/
COPY . .
RUN make release TARGETARCH=${TARGETARCH}

FROM ghcr.io/instrumentisto/rust:1.64.0-buster as deps
WORKDIR /work/
RUN mkdir -p deps \
    && find /usr/lib/*/libmilter.so* | xargs -I {} cp --parent {} deps/

FROM gcr.io/distroless/cc
LABEL org.opencontainers.image.authors="Hsn723" \
      org.opencontainers.image.title="reject-rbl-rcpt" \
      org.opencontainers.image.source="https://github.com/hsn723/reject-rbl-rcpt"
COPY LICENSE /LICENSE
COPY --from=build /work/target/release/reject-rbl-rcpt /
COPY --from=deps /work/deps /

ENTRYPOINT ["/reject-rbl-rcpt"]
