# syntax=docker/dockerfile:1

FROM alpine

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
    # The tool `dehydrated` uses to communicate with our certificate authority
    # in order to issue and renew certificates.
    curl \
    # Allows `cron`, the tool we use to schedule automatic TLS certificate
    # renewal, to work for unprivileged users.
    busybox-suid \
    # Lets us parse JSON results from Cloudflare's API, which we use to prove to
    # Let's Encrypt that we own the domain we're requesting certificates for.
    jq

# Copy our scripts into the image, and set permissions to allow only privileged
# users to execute them.
COPY --chmod=0500 usr/local/bin /usr/local/bin

# Run our image prebuild script.
RUN /usr/local/bin/prebuild

# Copy our config files into the image.
COPY etc /etc

# Copy all scripts for unprivileged users into the image, setting permissions
# only so the user each script is for can execute that script.
COPY --chmod=0500 --chown=acme home/acme/bin /home/acme/bin
COPY --chmod=0500 --chown=opendkim home/opendkim/bin /home/opendkim/bin

# Run our image build script.
RUN /usr/local/bin/build

# When the container starts, run our start script.
CMD /usr/local/bin/start
