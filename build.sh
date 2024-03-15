#!/bin/sh

# Exit if an error occurs or an unset variable is referenced.
set -eu

# Create an initial DKIM private key, or else OpenDKIM won't start.
/usr/local/bin/dkim
