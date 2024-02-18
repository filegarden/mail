# syntax=docker/dockerfile:1

FROM alpine

# This installs the following:
# - Postfix, the heart of the mail server (the mail transfer agent).
# - Dovecot, to authenticate you when signing into your email (via SASL).
# - GNU Parallel, to run both Postfix and Dovecot and show their output.
RUN apk add --no-cache postfix dovecot parallel

RUN --mount=type=bind,target=./build.sh,source=./build.sh \
    ./build.sh

COPY /etc /etc

CMD parallel --line-buffer --halt now,done=1 ::: 'postfix start-fg' 'dovecot -F'
