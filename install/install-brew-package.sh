#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

# всё состояние — в Brewfile, список формул и касок правится там
brew bundle --file=Brewfile
