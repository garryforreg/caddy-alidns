FROM abiosoft/caddy:builder as builder
ARG version="1.0.3"
ARG plugins="git,cors,realip,expires,cache,cloudflare,alidns"
ARG enable_telemetry="true"

# Process Wrapper
RUN go get -v github.com/abiosoft/parent
ADD https://raw.githubusercontent.com/jeffreystoke/caddy-docker/master/builder/builder.sh /usr/bin/builder.sh
RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh

#
# Final Stage
#
FROM alpine:3.10
LABEL maintainer "Garry Guo <garryforreg@gmail.com>"

ARG version="1.0.3"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="true"

# Telemetry Stats
ENV ENABLE_TELEMETRY="$enable_telemetry"

RUN apk add --no-cache \
  ca-certificates \
  curl \
  git \
  mailcap \
  openssh-client \
  tar \
  tzdata

# Install Caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# Validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/caddy/Caddyfile

# Install Process Wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/caddy/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
