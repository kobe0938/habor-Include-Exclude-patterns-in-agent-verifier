#!/bin/bash
# Solve the task, then simulate a chatty agent by writing several files
# into /logs/agent so include/exclude filtering has something to act on.

echo "Hello, world!" > /app/hello.txt

mkdir -p /logs/agent/sessions
echo '{"steps": []}' > /logs/agent/trajectory.json
echo '{"event": "session-1"}' > /logs/agent/sessions/session-1.jsonl
echo '{"event": "session-2"}' > /logs/agent/sessions/session-2.jsonl
echo "scratch notes" > /logs/agent/scratch.txt

# Nested tree for parent/subfolder filter-interaction tests.
mkdir -p /logs/agent/parent/sub
echo "parent-level file" > /logs/agent/parent/keep.txt
echo "inner file 1" > /logs/agent/parent/sub/inner-1.txt
echo "inner file 2" > /logs/agent/parent/sub/inner-2.txt

echo "Done!"
