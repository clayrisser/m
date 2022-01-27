#!/bin/sh

_MAKE=$((make --version | grep -qE '^GNU\sMake\s4\.') && \
   echo make || \
   (gmake --version >/dev/null 2>/dev/null && echo gmake || echo make))
if [ -z "${M_ARGS_ENV_NAME}" ]; then
   M_ARGS_ENV_NAME=ARGS
fi
_TARGET=$1
_ARGS=""
if [ "${#@}" -gt "0" ]; then
   shift
   _ARGS=$@
fi
exec $_MAKE -s $_TARGET $M_ARGS_ENV_NAME="$_ARGS"
