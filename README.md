# E2E evidence: include/exclude patterns for agent & verifier log downloads

Supporting test runs for the Harbor PR adding `include_logs` / `exclude_logs` to
`AgentConfig` and `VerifierConfig`, with CLI flags `--agent-include-logs`,
`--agent-exclude-logs`, `--verifier-include-logs`, `--verifier-exclude-logs`.

Semantics (mirrors Harbor dataset task filtering): fnmatch glob patterns matched
against paths relative to the logs directory; `include` narrows the set when given,
then `exclude` subtracts, so **exclude wins on overlap**. The verifier reward file
is always downloaded.

## Test task (`tasks/log-filter-demo/`)

Oracle task on Daytona. The solution writes a known log tree so filters have
something to act on:

```
/logs/agent/                      /logs/verifier/
├── trajectory.json               ├── reward.txt
├── scratch.txt                   ├── test-stdout.txt
└── sessions/                     ├── debug.log
    ├── session-1.jsonl           └── extra/trace.txt
    └── session-2.jsonl
```

(`agent/oracle.txt` is additionally written by the oracle agent itself via a direct
file download, outside the bulk-download filter's scope by design.)

## Scenarios (`configs/`, `jobs/`)

Each scenario ran twice: from a config file (`e2e-cfg-*`) and from CLI flags
(`e2e-cli-*`). Both surfaces produced identical results.

| Scenario | Agent filters | Verifier filters |
|---|---|---|
| baseline | none | none |
| exclude | exclude `sessions/*`, `scratch.txt` | exclude `debug.log` |
| include | include `trajectory.json` | include `extra/*` |
| both | include `trajectory.json`, `sessions/*`; exclude `sessions/session-2.jsonl` | include `extra/*`, `debug.log`; exclude `debug.log` |

CLI example (config-file equivalent: `harbor run -c configs/both.yaml`):

```bash
harbor run -p tasks/log-filter-demo -e daytona -a oracle --job-name e2e-cli-both \
  --agent-include-logs 'trajectory.json' --agent-include-logs 'sessions/*' \
  --agent-exclude-logs 'sessions/session-2.jsonl' \
  --verifier-include-logs 'extra/*' --verifier-include-logs 'debug.log' \
  --verifier-exclude-logs 'debug.log'
```

## Results (see `jobs/`)

**All runs behaved exactly as expected, and every CLI run (`e2e-cli-*`) produced
file-for-file identical output to its config-file twin (`e2e-cfg-*`).**
All trials scored reward 1: filtering never affects verification.

Spot-checks confirmed per scenario: exclude removes exactly the matched files;
include keeps only matches; when a file is in both lists (`debug.log`), exclude
wins; and `reward.txt` always survives. Two extra nested-folder runs
(`configs/nested-*.yaml`, also config/CLI pairs) confirmed the same rule on
folder overlap: include `parent/*` + exclude `parent/sub/*` carves the subfolder
out, while the reverse downloads nothing (include cannot rescue files from an
excluded parent) and logs a warning instead of failing the trial.
