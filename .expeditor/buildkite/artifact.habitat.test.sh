#!/usr/bin/env bash

set -ueo pipefail

export HAB_ORIGIN='ci'
export PLAN='inspec'

echo "--- system details"
uname -a

echo "--- Generating fake origin key"
hab origin key generate ${HAB_ORIGIN}

echo "--- Building $PLAN"
project_root="$(git rev-parse --show-toplevel)"
cd "$project_root"

DO_CHECK=true hab pkg build .

. results/last_build.sh

echo "--- Installing $pkg_ident"
hab pkg install "results/$pkg_artifact"

echo "+++ Testing $PLAN"
pushd "$project_root/test/artifact"
rake
popd
