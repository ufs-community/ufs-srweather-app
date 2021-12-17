#!/bin/bash
set -eu

if [[ $(uname -s) == Darwin ]]; then
  readonly ENV_DIR=$(cd "$(dirname "$(greadlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
else
  readonly ENV_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
fi

cd ${ENV_DIR}

source detect_machine.sh
echo "MACHINE:" ${MACHINE}

ENV_FILE="wflow_${MACHINE}.env"

echo "ENV FILE:" ${ENV_FILE}

source ${ENV_FILE}

module list
