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

### Results (see `jobs/<job-name>/.../agent|verifier`)

| Scenario | `agent/` downloaded | `verifier/` downloaded |
|---|---|---|
| baseline | everything | everything |
| exclude | `trajectory.json` (+`oracle.txt`) | all except `debug.log` |
| include | `trajectory.json` (+`oracle.txt`) | `extra/trace.txt`, `reward.txt` |
| both | `trajectory.json`, `sessions/session-1.jsonl` (+`oracle.txt`) | `extra/trace.txt`, `reward.txt` |

Key behaviors proven: exclude wins when a file matches both lists (`debug.log`),
the reward file survives any include list, and all trials scored reward 1, so
filtering never affects verification.

## Nested-folder interaction (`configs/nested-*.yaml`)

| Scenario | Agent filters | Result |
|---|---|---|
| nested-exclude-sub | include `parent/*`, exclude `parent/sub/*` | `parent/keep.txt` survives, subfolder carved out |
| nested-exclude-parent | include `parent/sub/*`, exclude `parent/*` | nothing downloaded: include cannot rescue files from an excluded parent (fnmatch `*` crosses `/`) |

The empty result logs a warning instead of failing the trial:

```
No files in '/logs/agent' matched include=['parent/sub/*'] exclude=['parent/*']; downloading nothing
```

(For the nested runs, the solution additionally writes `parent/keep.txt`,
`parent/sub/inner-1.txt`, and `parent/sub/inner-2.txt` under `/logs/agent`.)
