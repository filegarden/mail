#!/bin/sh

# Exit if an error occurs or an unset variable is referenced.
set -eu

# Allow execution of our scripts.
chmod u+x /usr/local/bin/*

# Create an initial DKIM private key, or else OpenDKIM won't start.
/usr/local/bin/dkim
