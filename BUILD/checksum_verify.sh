#!/bin/sh
DIR="$( cd "$( dirname "$0" )" && pwd )"
shasum -c $DIR/SHA512SUM
