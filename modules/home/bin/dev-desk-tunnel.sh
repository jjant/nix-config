#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Missing port. Usage $0 HOST SOURCE_PORT [OUTPUT_PORT]"
    exit 1
fi

USERNAME="jjantdev"
HOST=$1
SOURCE_PORT=$2
OUTPUT_PORT=${3:-$SOURCE_PORT}

echo "Tunneling DevDesktop from $SOURCE_PORT to $OUTPUT_PORT"
ssh -T -L "$SOURCE_PORT":localhost:"$OUTPUT_PORT" "$USERNAME"@"$HOST"
