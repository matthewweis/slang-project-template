#!/bin/sh
DIR="$( cd "$( dirname "$0" )" && pwd )"
shasum -a 512 $DIR/SHELLSHOCK > $DIR/SHA512SUM
chmod a+r $DIR/SHA512SUM
chmod a-w $DIR/SHA512SUM
chmod a-x $DIR/SHA512SUM
