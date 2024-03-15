# syntax=docker/dockerfile:1

FROM alpine

# This installs the following:
# - Postfix, the heart of the mail server (the mail transfer agent).
# - Dovecot, to authenticate you when logging into your email (via SASL).
# - OpenDKIM, to cryptographically sign outbound emails (via DKIM).
# - GNU Parallel, to run all of these and combine their output.
RUN apk add --no-cache postfix dovecot opendkim parallel

# Copy our config files into the image.
COPY etc /etc

# Copy our scripts into the image, and set permissions to allow executing them.
COPY --chmod=0700 usr/local/bin /usr/local/bin

# Run our image build script.
RUN --mount=type=bind,target=./build.sh,source=./build.sh \
    ./build.sh

CMD parallel \
    # If one of the below processes exits, also halt the others so the container
    # can restart.
    --halt now,done=1 \
    # Ensure different lines logged at the same time don't intermingle.
    --line-buffer \
    # Run these commands in parallel, and in the foreground so GNU Parallel
    # can detect when they exit and stay open as long as they're open.
    ::: "postfix start-fg" "dovecot -F" "opendkim -f"
