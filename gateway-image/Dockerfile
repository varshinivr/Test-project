ARG CLAUDE_VERSION=2.1.284

FROM debian:bookworm-slim AS binary
ARG CLAUDE_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg python3 \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o /tmp/claude-code.asc; \
    fingerprint="$(gpg --show-keys --with-colons /tmp/claude-code.asc | awk -F: '$1 == "fpr" { print $10; exit }')"; \
    test "$fingerprint" = "31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"; \
    gpg --batch --import /tmp/claude-code.asc; \
    base="https://downloads.claude.ai/claude-code-releases/$CLAUDE_VERSION"; \
    curl -fsSL "$base/manifest.json" -o /tmp/manifest.json; \
    curl -fsSL "$base/manifest.json.sig" -o /tmp/manifest.json.sig; \
    gpg --batch --verify /tmp/manifest.json.sig /tmp/manifest.json; \
    expected="$(python3 -c 'import json; print(json.load(open("/tmp/manifest.json"))["platforms"]["linux-x64"]["checksum"])')"; \
    curl -fsSL "$base/linux-x64/claude" -o /usr/local/bin/claude; \
    echo "$expected  /usr/local/bin/claude" | sha256sum --check --strict; \
    chmod 0755 /usr/local/bin/claude; \
    /usr/local/bin/claude --version

RUN curl -fsSL https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /tmp/rds-global-bundle.pem \
    && grep -q 'BEGIN CERTIFICATE' /tmp/rds-global-bundle.pem \
    && test "$(wc -c < /tmp/rds-global-bundle.pem)" -gt 10000

FROM gcr.io/distroless/cc-debian12:nonroot@sha256:ce0d66bc0f64aae46e6a03add867b07f42cc7b8799c949c2e898057b7f75a151

COPY --from=binary --chmod=0755 /usr/local/bin/claude /usr/local/bin/claude
WORKDIR /etc/claude
COPY --chmod=0644 gateway.yaml /etc/claude/gateway.yaml
COPY --from=binary --chmod=0644 /tmp/rds-global-bundle.pem /etc/claude/rds-global-bundle.pem
WORKDIR /

ENV CLAUDE_CONFIG_DIR=/tmp/.claude
ENV NODE_EXTRA_CA_CERTS=/etc/claude/rds-global-bundle.pem

EXPOSE 8080
USER nonroot

ENTRYPOINT ["/usr/local/bin/claude", "gateway", "--config", "/etc/claude/gateway.yaml"]