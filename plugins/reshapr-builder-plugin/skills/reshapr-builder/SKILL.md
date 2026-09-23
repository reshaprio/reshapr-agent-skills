---
name: reshapr-builder
description: 'Use when a reShapr builder wants to create, refine, or validate an MCP server. Covers importing APIs, attaching artifacts, selecting operations, exposing endpoints, testing MCP methods, and choosing between local CLI iteration and an existing control plane.'
argument-hint: 'What are you building with reShapr?'
---

# reShapr Builder Workflow

Use this skill when a developer or agent builder wants to create a new MCP server with reShapr, narrow or enrich its capability surface, and verify that the resulting endpoint behaves correctly for real MCP clients.

## When to Use

- Build a first MCP endpoint from an OpenAPI, GraphQL, or Protobuf contract
- Fine tune which operations, prompts, resources, custom tools, or output filters are exposed
- Add scripted orchestration behind one higher-level MCP tool
- Choose between a fast local proof-of-concept flow and an existing control plane
- Validate a reShapr endpoint with raw MCP requests before connecting an agent

## Outcome

Produce a reShapr MCP server that:

- exposes the intended tool surface and only that surface
- includes any needed attached artifacts for agent-facing behavior
- can be discovered and called by an MCP client
- has verification evidence for discovery, listing, and at least one representative tool call

## Decide the Working Mode First

Choose one path before making changes:

### Path A: Local instance

Use this when you want the shortest route to a working endpoint.

- Prefer the CLI workflow
- Use a local reShapr environment started with `reshapr run`
- Iterate quickly on imports, plans, expositions, and attached artifacts

### Path B: Existing control plane

Use this when you are targeting a control plane that already exists outside the local CLI-managed environment.

- Use the existing control plane and its registered proxy or gateway
- Create or refine Services, Configuration Plans, Expositions, and attached artifacts against that running platform
- Validate endpoint behavior directly against the deployed MCP surface

## Inputs to Collect

Before changing anything, gather these facts:

- backend contract source: local file, remote URL, or existing Service
- backend base URL the proxy should call
- target environment: local `reshapr run` stack or an existing control plane
- desired exposure mode: quick local proof or team-shared endpoint on an existing control plane
- required agent-facing capabilities: plain generated tools, prompts, resources, declarative custom tools, scripted custom tools, output filters
- access model: public endpoint, API key, or OAuth

If any of these are missing, stop and resolve them before making broad changes.

## Artifact Authoring Mode

When the user asks for Prompts, Resources, CustomTools, or ToolsOutputFilters, do not draft them from memory alone.

Always load and use these local references first:

- [Artifact authoring guide](./references/artifact-authoring.md)
- [Artifact golden examples](./references/golden-examples.md)
- [Discovery prompts playbook](./references/discovery-prompts.md)
- [CLI quick reference and field notes](./references/cli-quick-reference.md)
- [Prompts schema](./references/Prompts-v1alpha1-schema.json)
- [Resources schema](./references/Resources-v1alpha1-schema.json)
- [CustomTools schema](./references/CustomTools-v1alpha1-schema.json)
- [ToolsOutputFilters schema](./references/ToolsOutputFilters-v1alpha1-schema.json)

Use the schemas to guarantee structural validity, the guides to improve task fit, naming, safety, and MCP usability, and the golden examples as starter patterns instead of inventing shapes from scratch.

When the user asks for a scripted `CustomTools` artifact from a natural-language description, first discover the current platform surface through the CLI before writing YAML or JavaScript.

When the request is underspecified or several Services or operations are plausible, use the discovery prompts playbook to ask only the minimum questions needed to disambiguate the artifact.

## Procedure

### 1. Prepare the environment

For local iteration:

1. Run `reshapr info` to confirm the CLI is installed, see which control plane is currently targeted, and verify whether you are already authenticated.
2. If `reshapr info` shows that you are not authenticated, run `reshapr login` before any discovery commands.
   - If the control plane URL is `http://localhost:*`, you may ask the user whether to authenticate with the default local development credentials (`admin` / `password`) or log in themselves. Only offer this shortcut for `localhost` URLs, and only as a question; never type arbitrary credentials on the user's behalf.
3. Confirm the local stack is running with `reshapr status`.
4. Confirm a proxy or gateway is registered in the intended Gateway Group.

For an existing control plane:

1. Run `reshapr info` to confirm the target control plane is the one currently selected and to verify the active organization and authentication state.
2. If `reshapr info` shows that you are not authenticated, run `reshapr login` before discovery.
3. Confirm a proxy or gateway exists for the selected Gateway Group.
4. Confirm any required backend or endpoint credentials already exist.

### 2. Establish the baseline Service

If starting from an API contract:

- import it through the CLI for local iteration
- import it against the existing control plane when working remotely

Baseline checks:

- the Service exists exactly once in the intended organization
- the discovered name and version are the ones you intend to expose
- the operation set matches the source contract closely enough to proceed

If the user wants a scripted `CustomTools` artifact or asks what can be orchestrated:

1. Run `reshapr service list --output json` to enumerate candidate Services.
2. Run `reshapr config list --output json` to identify existing Configuration Plans and their current exposure scope.
3. Drill into the most relevant candidate Service or Plan to inspect operations, existing artifacts, and whether the desired business action should be same-Service or cross-Service.
4. Present the plausible Services and operations back to the user when the description could map to several options.
5. Use the discovery prompts playbook when you need to ask the user to choose between several plausible mappings.

### 3. Create the first exposable configuration

Create a Configuration Plan that points to the real backend endpoint.

- start with the minimal backend endpoint and a narrow operation set when possible
- do not expose everything by default if the goal is a focused agent workflow
- create an Exposition only after the plan is valid
- never modify a pre-existing Configuration Plan you did not create for this task; create a new, dedicated Plan that selects only the artifacts and operations the current request needs
- name skill-created Plans and Expositions with a `reshapr-builder-` prefix followed by a short descriptive slug, so they are clearly identifiable and never collide with hand-made resources

For either environment, apply changes in this order:

1. Service
2. artifact attachment when needed
3. ConfigurationPlan
4. Exposition

### 4. Fine tune the agent-facing surface

Pick the smallest mechanism that fits the need.

Use generated tools only when:

- the raw backend operations are already suitable for agents

Use attached artifacts when you need more control:

- Prompts: reusable guidance the client can request explicitly
- Resources: reusable static context that should be listed or read by the client
- Declarative Custom Tools: stable higher-level actions derived from one Service
- Scripted Custom Tools: orchestration, branching, aggregation, or cross-Service workflows
- Output filters: normalize or shrink responses after tool execution

Decision rules:

- If the agent keeps calling several tools to complete one stable business task, move that workflow into a custom tool.
- If the task is mostly mapping, shaping, or packaging one API action, prefer a declarative custom tool first.
- If the task needs branching logic, parallel calls, partial-failure handling, or cross-Service calls, use a scripted custom tool.
- If the tool works but returns too much or inconsistently shaped data, add an output filter.
- If the agent needs stable reference material, add a Resource instead of embedding that context into every prompt.

For scripted `CustomTools`, use this additional workflow:

1. Turn the user description into one explicit business action with a bounded success result.
2. Discover candidate Services with `reshapr service list --output json`.
3. Discover candidate Configuration Plans with `reshapr config list --output json`.
4. Inspect the chosen Service or Plan to identify the exact underlying tools or operations to call.
5. Decide whether the script is same-Service or cross-Service.
6. Build the minimal `input` schema that matches the user-facing action rather than the backend protocol.
7. Build the minimal exhaustive `tools` allow-list.
8. Generate the JavaScript `script` using `rs.callTool`, `rs.callToolAsync`, `rs.awaitPromises`, and `rs.fail` only as needed.
9. Return a compact JSON-serializable result that hides backend orchestration details.

When several services or operations could satisfy the same description:

- prefer the option already exposed or already selected in a relevant Configuration Plan
- prefer read-only or lower-risk operations when the user intent is ambiguous
- ask the user to choose when the tradeoff changes behavior materially

When generating a reShapr artifact:

- choose the artifact kind from the user intent before writing YAML
- bind it to the exact existing `service.name` and `service.version`
- satisfy the corresponding schema completely
- reuse the closest golden example as the initial shape when one exists
- optimize for agent usability, not just schema validity
- prefer the smallest artifact that solves the problem cleanly
- never edit a pre-existing attached artifact you did not create; always attach a new artifact file instead, even when a pre-existing artifact of the same kind already covers part of the need
- name the new artifact file with a `reshapr-builder-` prefix followed by a short descriptive slug (e.g. `reshapr-builder-compare-repositories.yaml`) so it is clearly identified as skill-generated and never overwrites an existing attachment with the same source name

When generating a scripted `CustomTools` artifact specifically:

- derive the `script` from the user description only after discovering the actual callable Services and operations
- keep the script deterministic and shallow
- keep branching explicit
- check every tool-call result before using its content
- use parallel calls only when they are independent and improve the action materially
- use `rs.fail` for terminal business failures that should stop the whole action

### 5. Re-expose the refined endpoint

After changing plan selection or attached artifacts:

- refresh the Exposition or create a dedicated one for the new surface
- keep separate Expositions when different consumers need different capabilities
- avoid mixing exploratory and production-oriented surfaces unless that is intentional

### 6. Test the endpoint as an MCP server

Validate with raw MCP requests before handing the endpoint to an agent.

For stateless MCP testing, verify this sequence:

1. `server/discover`
2. `tools/list`
3. `prompts/list` when prompts are expected
4. `resources/list` when resources are expected
5. `tools/call` for one representative success case

If the endpoint uses session-based MCP, initialize once and reuse the negotiated session headers consistently.

After attaching an artifact or creating/updating a Plan or Exposition, MCP propagation to the proxy is asynchronous. If a just-added capability is missing from a list method, retry once or twice before concluding the configuration is wrong — see [cli-quick-reference.md](./references/cli-quick-reference.md).

When testing, ensure:

- the chosen protocol mode is internally consistent
- the endpoint URL matches the intended Exposition
- authentication headers match the endpoint access model
- the listed tool names and resource URIs match the configured capability surface

When testing a newly generated artifact, also ensure:

- Prompts list with the intended names and arguments
- Resources list with the intended URIs or templates
- CustomTools appear with the intended input contract and behavior
- ToolsOutputFilters measurably change the returned payload shape when expected

For scripted `CustomTools`, also ensure:

- the `tools` allow-list matches the actual calls performed by the script
- same-Service versus cross-Service calls are intentional
- one representative success path works end to end
- one representative failure path returns the expected structured failure behavior

### 7. Iterate on failures locally, not abstractly

If validation fails, repair according to the nearest cause.

Common branches:

- `server/discover` fails: check endpoint URL, proxy reachability, protocol mode, and authentication
- `tools/list` is missing expected tools: check selected operations, included artifacts, and whether the Exposition has refreshed
- `resources/list` or `prompts/list` is empty unexpectedly: check artifact attachment and plan artifact selection
- `tools/call` returns a backend or script failure: inspect the selected plan, backend endpoint, artifact logic, and runtime guardrails
- `tools/call` succeeds but a GraphQL-backed field is missing from the result: check whether the underlying tool needs an explicit `__relation_<field>` argument (see [cli-quick-reference.md](./references/cli-quick-reference.md)) before assuming a script or filter bug
- Existing control plane resources do not behave as expected: check the active organization, selected gateway group, backend endpoint, and whether the Exposition reflects the latest plan or artifact changes

Repair one layer at a time. Do not keep adding new artifacts or policy changes before the current slice validates.

## Completion Criteria

The work is complete only when all applicable checks pass:

- the Service or corresponding custom resource is present and healthy
- the Configuration Plan matches the intended backend and selected capability surface
- the Exposition is reachable through the intended gateway or proxy
- MCP discovery succeeds in the chosen protocol mode
- expected tools are visible in `tools/list`
- expected prompts or resources are visible when configured
- at least one representative `tools/call` succeeds with a useful response
- no unintended capabilities are exposed compared with the stated goal

For work against an existing control plane, also require:

- the target organization and gateway group are the intended ones
- the deployed endpoint reflects the latest plan and artifact selection
- sensitive values are not embedded in ad hoc commands or tracked files

## Guardrails

- Prefer a narrow initial surface over exposing every discovered operation.
- Treat successful reconciliation and successful MCP behavior as separate checks.
- Keep credentials out of tracked files and shell history when possible.
- Use separate Expositions for materially different consumer experiences.
- When both local and remote work are possible, prototype locally first, then reproduce the validated setup against the existing control plane.
- Treat schema conformance as necessary but insufficient: generated artifacts must also be task-shaped, readable, and minimally exposed.
- Never modify a pre-existing artifact or Configuration Plan you did not create for this task. Always create a new one, prefixed `reshapr-builder-`, instead of editing someone else's resource.
- Only offer the default local `admin` / `password` login shortcut for `http://localhost:*` control planes, and only as a question the user can decline.
- Never run `reshapr login` without an explicit `--server` when a local `reshapr-control-plane` container might be running; detect it via `docker ps` first (see [cli-quick-reference.md](./references/cli-quick-reference.md)) rather than letting the CLI fall back to its default server.

## Example Prompts

- Build a reShapr MCP server from this OpenAPI URL and expose only the operations an agent needs.
- Help me fine tune this reShapr endpoint with a custom tool and an output filter, then verify it with MCP requests.
- Reproduce this locally validated reShapr MCP server on an existing control plane.
- Diagnose why my reShapr endpoint lists the tool but fails on `tools/call`.