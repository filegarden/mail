# syntax=docker/dockerfile:1

FROM alpine

# This installs the following:
# - Postfix, the heart of the mail server (the mail transfer agent).
# - Dovecot, to authenticate you when signing into your email (via SASL).
# - GNU Parallel, to run both Postfix and Dovecot and combine their output.
RUN apk add --no-cache postfix dovecot parallel

RUN --mount=type=bind,target=./build.sh,source=./build.sh \
    ./build.sh

COPY etc /etc

CMD parallel \
    # If either Postfix or Dovecot exits, also halt the other so the container
    # can restart.
    --halt now,done=1 \
    # Ensure different lines logged at the same time don't intermingle.
    --line-buffer \
    # Run Postfix and Dovecot both in the foreground so their output appears in
    # the container logs.
    ::: 'postfix start-fg' 'dovecot -F'
