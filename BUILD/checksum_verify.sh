#!/bin/sh
DIR="$( cd "$( dirname "$0" )" && pwd )"
(cd $DIR && shasum -c "$( basename "$DIR/SHA512SUM" )")
