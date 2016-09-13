#!/bin/bash
set -euo pipefail

VENV=/opt/app/venv
if [ ! -d $VENV ] ; then
    virtualenv $VENV
else
    echo "$VENV exists, moving on"
fi

cd /opt/app
HOME=/var ./venv/bin/python ./setup.py install
