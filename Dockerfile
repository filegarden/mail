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
    # Automatically obtains and renews our hostname's TLS certificates for
    # encrypting mail in transit.
    acme.sh \
    # Allows `cron`, the tool we use to schedule automatic jobs to run
    # periodically, to work for unprivileged users.
    busybox-suid

# Copy our scripts into the image, and set permissions to allow executing them.
COPY --chmod=0700 usr/local/bin /usr/local/bin

# Run our image prebuild script.
RUN /usr/local/bin/prebuild

# Copy our config files into the image.w
COPY etc /etc

# Copy all scripts for unprivileged users into the image, setting permissions so
# that only the user each script is for can execute that script.
COPY --chmod=700 --chown=acme-sh home/acme-sh/bin /home/acme-sh/bin
COPY --chmod=700 --chown=opendkim home/opendkim/bin /home/opendkim/bin

# Run our image build script.
RUN /usr/local/bin/build

# When the container starts, run our start script.
CMD /usr/local/bin/start
