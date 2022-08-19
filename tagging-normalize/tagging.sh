#!/bin/sh

dir="$(dirname "$0")"

source "$dir/venv/bin/activate"

export PYTHONPATH="$dir:$PYTHONPATH"
python -m "main" "$@"
