#!/bin/sh
DIR="$( cd "$( dirname "$0" )" && pwd )"
shasum -c "$( basename "$DIR/SHA512SUM" )"
