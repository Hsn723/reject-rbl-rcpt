FROM ghcr.io/instrumentisto/rust:1.77.2-buster as build
WORKDIR /work/
COPY . .
RUN make release \
    && mkdir -p deps \
    && find /usr/lib/*/libmilter.so* | xargs -I {} cp --parent {} deps/

FROM gcr.io/distroless/cc
LABEL org.opencontainers.image.authors="Hsn723" \
      org.opencontainers.image.title="reject-rbl-rcpt" \
      org.opencontainers.image.source="https://github.com/hsn723/reject-rbl-rcpt"
COPY LICENSE /LICENSE
COPY --from=build /work/target/release/reject-rbl-rcpt /
COPY --from=build /work/deps /

ENTRYPOINT ["/reject-rbl-rcpt"]
