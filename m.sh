#!/bin/sh

if [ -z "${M_ARGS_ENV_NAME}" ]; then
   M_ARGS_ENV_NAME=ARGS
fi
target=$1
shift
exec make $target $M_ARGS_ENV_NAME="$@"
