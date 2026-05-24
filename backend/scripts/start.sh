#!/bin/bash
cd "$(dirname "$0")/.."
./bin/server &
echo "Server started on :8080"
open ../app/build/macos/Build/Products/Release/family_health.app
