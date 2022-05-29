#!/bin/sh
DIR="$( cd "$( dirname "$0" )" && pwd )"
(cd DIR && shasum -a 512 "$( basename "$DIR/SHELLSHOCK" )" > "$( basename "$DIR/SHA512SUM" )")
chmod a+r $DIR/SHA512SUM
chmod a-w $DIR/SHA512SUM
chmod a-x $DIR/SHA512SUM
