# CLI Quick Reference and Field Notes

Command shapes and operational lessons captured from real runs of this skill. Use this as a
fast lookup before re-deriving a command from first principles, and check `reshapr <command>
--help` when a flag here looks stale — the installed CLI is the source of truth, not this file
or the public docs.

## Connection preflight (run before discovery)

```bash
reshapr info
```

Use `reshapr info` first to confirm which control plane is currently targeted and whether the
CLI is already authenticated.

If it shows that you are not connected, **do not run a bare `reshapr login`** — its default
server is not necessarily the one you want, and a locally running instance is easy to miss.
First check for a local control plane container:

```bash
docker ps --format '{{.Names}}\t{{.Ports}}' | grep reshapr-control-plane
```

If a container named `reshapr-control-plane` (or matching that pattern, e.g. from a
`reshapr run` compose project) is running, read its published host port from the `Ports`
column (mapped from the container's internal `5555`) and log in against it explicitly:

```bash
reshapr login --server http://localhost:5555
```

Only fall back to a bare `reshapr login` (default server) when no local control plane
container is found and the user has not named a target server themselves. Then rerun
`reshapr info` to confirm the connection before any discovery commands.

## Discovery (run after connection preflight)

```bash
reshapr service list --output json
reshapr service get <serviceId> --output json
reshapr config list --output json
reshapr config get <configId> --output json
reshapr artifact list -s <serviceId> --output json
reshapr artifact get <artifactId> --display
```

`config list` and `artifact list` reveal whether a Service already has attached artifacts and
Plans before you create anything new. Always inspect these before assuming a clean slate.

## Creating a new, skill-owned surface

Follow this order; do not skip straight to `expo create`.

```bash
# 1. Attach a new artifact file (never edit an existing one — see SKILL.md guardrails)
reshapr attach -f reshapr-builder-<slug>.yaml --output json

# 2. Create a dedicated Configuration Plan (never reuse/edit an existing one)
reshapr config create reshapr-builder-<slug> \
  --serviceId <serviceId> \
  --backendEndpoint <backendUrl> \
  --includedOperations '["<op1>"]' \
  --includedArtifacts '["reshapr-builder-<slug>.yaml"]' \
  --output json

# 3. Create the Exposition
reshapr expo create --configuration <planId> --gateway-group <gatewayGroupId> --output json
```

## Known CLI limitations (validated in practice)

- `reshapr config update <id>` opens an **interactive editor**; it does not accept flags like
  `--includedArtifacts` or `--includedOperations` directly on the command line. Do not try to
  script it. Create a new Configuration Plan instead (this also matches the "never edit a
  pre-existing Plan" guardrail).
- `reshapr secret update <id>` is interactive-only for the same reason.
- `reshapr config duplicate <id> --name <newName>` copies an existing Plan under a new name and
  ID. It is a fast starting point for a new Plan, but still requires a follow-up review: it
  copies the source Plan's current selection, which may not match what the new request needs.
- Deletion commands (`service delete`, `config delete`, `artifact delete`, `secret delete`)
  support `-f, --force` to skip the interactive confirmation prompt — use it for non-interactive
  cleanup during iteration. `expo delete <id>` does not prompt at all.
- Treat any flag list here as a hint, not ground truth: run `reshapr <command> --help` on the
  actual installed CLI before scripting a command with several flags, since flags can be added
  ahead of the public documentation.

## Structured-output pattern

Prefer `--output json` plus `jq` over parsing table output, especially to capture an ID for the
next command:

```bash
SERVICE_ID="$(
  reshapr service list --output json \
    | jq -er 'map(select(.name == "<Service Name>" and .version == "<version>")) | first | .id'
)"
```

## MCP propagation is asynchronous — expect a short delay, do not assume failure

Attaching a new artifact version or creating/updating an Exposition does not update the proxy's
MCP surface instantly. The control plane pushes `CREATED`/`UPDATED` events to the proxy over a
streaming channel; there is no CLI command that forces an immediate proxy refresh.

After attaching an artifact or creating/updating a Plan or Exposition:

1. Re-run the relevant MCP list method (`tools/list`, `prompts/list`, `resources/list`).
2. If the expected capability is still missing, wait briefly and retry once or twice before
   concluding the configuration is wrong.
3. Only after a retry still fails, fall back to checking the Configuration Plan's
   `includedArtifacts`/`includedOperations`, the artifact content itself, and proxy health —
   not the other way around.

## Artifact selection exposes whole files, not just matching entries

When a Configuration Plan's `includedArtifacts` selects a `CustomTools` (or other) artifact
file, **every** entry declared in that file becomes visible on the Exposition — not just the
entry that matches the current task. This is another reason to attach a new, narrowly scoped
artifact file per task instead of adding an entry to an existing multi-tool file.

## GraphQL Services: request nested fields explicitly

A GraphQL-backed tool (e.g. `repository`, `user`) can expose relation/nested fields in its
schema without returning them by default. Declaring `arguments` on a Custom Tool does not
automatically populate nested fields like `stars`, `primaryLanguage`, or `lastPushedAt` unless
the corresponding `__relation_<field>` argument (or the field's own required arguments) is set.
Before assuming a script or filter bug, inspect the raw backend response for the underlying
tool call and confirm the missing field actually needs an explicit relation argument.
