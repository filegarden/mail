# syntax=docker/dockerfile:1

FROM alpine:3

# This installs the following packages.
RUN apk add --no-cache \
    # The heart of the mail server (the mail transfer agent).
    postfix \
    # Authenticates you when logging into your email (via SASL).
    dovecot \
    # Cryptographically signs outbound mail (via DKIM).
    opendkim \
    # Runs these simultaneously and combines their output.
    parallel \
    # The scripting language required to run `dehydrated`, which automatically
    # obtains and renews our hostname's TLS certificates for encrypting mail in
    # transit.
    bash \
    # A tool for making HTTP requests.
    curl \
    # Lets us parse JSON results from Cloudflare's API, which we use to prove to
    # Let's Encrypt that we own the domain we're requesting certificates for.
    jq

# Copy our library utilities into the image, and let all users access them.
COPY --chmod=0444 usr/lib /usr/lib

# Copy our scripts into the image, and let only privileged users execute them.
COPY --chmod=0500 usr/local/bin /usr/local/bin

# Run our image prebuild script.
RUN /usr/local/bin/prebuild

# Copy our config files into the image.
COPY etc /etc

# Copy all scripts for unprivileged users into the image, setting permissions
# only so the user each script is for can execute that script.
COPY --chmod=0500 --chown=acme home/acme/bin /home/acme/bin
COPY --chmod=0500 --chown=dkim home/dkim/bin /home/dkim/bin

# Run our image build script.
RUN /usr/local/bin/build

# Use our `usr/local/bin/healthcheck` script to check if the server is ready to
# accept mail.
HEALTHCHECK --start-period=120s --start-interval=1s CMD [ "healthcheck" ]

# When the container starts, run our start script by default. (Note this can be
# overwritten using `docker compose run`.)
CMD /usr/local/bin/start
