#!/bin/bash
# Verify the task, then write extra verifier files so verifier-side
# include/exclude filtering has something to act on.

mkdir -p /logs/verifier/extra
echo "verbose verifier debug output" > /logs/verifier/debug.log
echo "trace line" > /logs/verifier/extra/trace.txt

if grep -q "Hello, world!" /app/hello.txt; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
