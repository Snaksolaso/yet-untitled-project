#!/bin/bash
PNGS="$(find -type f -regex ".*\.png*")"
for f in $PNGS; do mv "$f" "${f//-/}"; done
PNGS2="$(find -type f -regex ".*\.png*")"
for f in $PNGS2; do mv "$f" "${f//_/}"; done
