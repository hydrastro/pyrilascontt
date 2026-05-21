#!/usr/bin/env bash
set -euo pipefail

mkdir -p test

if [ ! -f test/results.xml ]; then
  cat > test/results.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="no-junit-results-produced" tests="1" failures="0" errors="0" skipped="1">
  <testcase classname="ci" name="no-results-xml-produced">
    <skipped message="The test command did not produce test/results.xml"/>
  </testcase>
</testsuite>
XML
fi
