#!/bin/sh

if [ -z "${M_ARGS_ENV_NAME}" ]; then
   M_ARGS_ENV_NAME=ARGS
fi
_TARGET=$1
_ARGS=""
if [ "${#@}" -gt "0" ]; then
   shift
   _ARGS=$@
fi
exec make -s $_TARGET $M_ARGS_ENV_NAME="$_ARGS"
