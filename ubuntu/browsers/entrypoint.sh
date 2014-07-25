#!/bin/bash

set -e

DISPLAY=:1

if [ "$1" = "/bin/sh" ]; then
    echo "Error: Startup parameters missing"
    exit 1
fi

echo "Starting Xvfb"
Xvfb :1 -screen 0 1024x768x24 2> Xvfb-err.log &

echo "Starting chromedriver"
chromedriver --url-base=/wd/hub --port=4444 --verbose 2> chromedriver-err.log > chromedriver-out.log &

echo "Starting cucumber with: $@"
cucumber --strict -r test/cucumber-helpers -r test/integration $@