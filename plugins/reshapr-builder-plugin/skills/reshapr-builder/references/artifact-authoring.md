# reShapr Artifact Authoring Guide

Use this guide when generating or reviewing a reShapr artifact. The JSON schemas guarantee structural validity. This guide improves intent fit, naming quality, and runtime usefulness.

Load [golden-examples.md](./golden-examples.md) alongside this guide when you want high-quality starter patterns for each artifact kind.

Load [discovery-prompts.md](./discovery-prompts.md) when the user request is still ambiguous after the initial CLI discovery.

Load [cli-quick-reference.md](./cli-quick-reference.md) for exact command shapes, known CLI limitations (e.g. `config update` is interactive-only), and the GraphQL relation-field gotcha before scripting a multi-step CLI sequence.

The four JSON schemas and the golden examples are copied (and, for the examples, hand-adapted)
from the `reshapr` repo. Maintainers should run
[`scripts/sync-resources.sh`](../scripts/sync-resources.sh) periodically to pick up upstream
changes instead of editing these copies from memory.

## Authoring Workflow

1. Identify the artifact kind from the user intent.
2. Discover the current platform surface when the artifact depends on existing Services, tools, or plans.
3. Resolve the exact target `service.name` and `service.version`.
4. Draft the YAML to match the corresponding schema exactly.
5. Review the artifact for task fit, naming, and exposure minimization.
6. Attach or expose it, then verify the resulting MCP capability with a real list or call.

## CLI Discovery First

Before authoring a `CustomTools` artifact, and especially before generating a scripted `script`, inspect the current reShapr surface through the CLI.

Start with:

- `reshapr service list --output json`
- `reshapr config list --output json`

Use these results to:

- identify candidate Services already available in the organization
- identify which Configuration Plans already exist and what surface may already be exposed
- decide whether the user description should target one Service or orchestrate several Services
- propose concrete candidate Services or operations back to the user when the request is ambiguous

If the candidate set is still unclear after listing, inspect the most relevant Service or Configuration Plan in more detail before drafting the artifact.

## Choose the Right Artifact

- Use `Prompts` when the model needs reusable instructions, accelerators, or orchestration guidance.
- Use `Resources` when the model needs read-only contextual data to inspect or cite.
- Use `CustomTools` when the model needs a task-shaped action instead of a raw backend operation.
- Use `ToolsOutputFilters` when the tool already does the right action but returns too much or poorly shaped data.

## Shared Rules

- Always set `apiVersion: reshapr.io/v1alpha1`.
- Always use the exact `kind` required by the schema.
- Always bind to a real existing Service with matching `service.name` and `service.version`.
- Reuse the closest golden example as a base shape before customizing it.
- Prefer stable, human-readable names that describe user intent rather than backend protocol details.
- Minimize exposure: do not add more capabilities, parameters, or retained fields than the use case needs.
- Never edit a pre-existing artifact file you did not create for this task, even to add one entry to it. Attach a new artifact file instead, named with a `reshapr-builder-` prefix (e.g. `reshapr-builder-compare-repositories.yaml`).
- Never edit a pre-existing Configuration Plan. Create a new, dedicated Plan (also `reshapr-builder-` prefixed) that selects exactly the artifacts and operations the current request needs.

## Prompts

### Required structure

- Root keys: `apiVersion`, `kind`, `service`, `prompts`
- Each prompt item must contain `result`

### Quality criteria

- Prompt names should describe the user task, not just mirror a tool name blindly.
- `result` should read like a direct instruction or reusable prompt fragment.
- Add `arguments` only when the prompt genuinely needs caller-supplied context.
- Argument names should be short, concrete, and aligned with the prompt text.
- Use placeholders like `${name}` only where runtime substitution is needed.

### Common mistakes

- Turning prompts into hidden tools instead of guidance.
- Making the prompt too generic to be reusable.
- Defining arguments that are never used in `result`.
- Binding the artifact to the wrong Service version.

## Resources

### Required structure

- Root keys: `apiVersion`, `kind`, `service`
- At least one of `resources` or `resourceTemplates` must exist

### Quality criteria

- Use `resources` for fixed known documents.
- Use `resourceTemplates` only when the resource space is genuinely parameterized.
- Resource keys must be valid URIs with a scheme.
- `name` should be compact; `title` and `description` should clarify why the resource matters.
- Provide `mimeType` when it helps the client interpret content correctly.
- Prefer `text` for static textual context, `blob` for embedded binary content, and `remoteContent` when the content should be fetched remotely.
- Use `annotations.audience`, `priority`, and `lastModified` only when they add real client hints.

### Common mistakes

- Using invalid or ambiguous URIs.
- Mixing multiple content sources on one resource.
- Creating templates when a few explicit resources would be clearer.
- Treating Resources as actions instead of read-only context.

## CustomTools

### Required structure

- Root keys: `apiVersion`, `kind`, `service`, `customTools`
- Every custom tool item requires `description` and `input`
- Declarative form requires `tool` and `arguments`
- Scripted form requires `script` and `tools`

### Quality criteria

- Prefer declarative tools first; use scripted tools only when orchestration or branching is required.
- Tool names should express the business action exposed to the MCP client.
- `input` must be a clear object schema with meaningful property descriptions and a minimal required set.
- Declarative `arguments` should map cleanly from the public input to the target tool contract.
- Every `${...}` placeholder must correspond exactly to a property declared under `input.properties`.
- Scripted tools should keep the allow-list exhaustive and minimal.
- In scripts, check `result.ok` before using `result.content`.
- Return compact JSON-serializable objects that hide backend complexity from the client.

### Script generation workflow

When the user provides a natural-language description for a scripted custom tool:

1. Restate the requested action as one bounded business capability.
2. Run `reshapr service list --output json` to discover candidate Services.
3. Run `reshapr config list --output json` to discover relevant existing Configuration Plans.
4. Inspect the most relevant Service or Plan to determine the actual underlying tools or operations available.
5. Choose same-Service calls when possible; use cross-Service calls only when the business action truly spans Services.
6. Design the public `input` schema around the user task, not the backend transport.
7. Build the smallest exhaustive `tools` allow-list.
8. Generate the JavaScript `script` around the `rs` host API.
9. Make the script return a compact final object instead of leaking intermediate backend payloads.

### Script writing rules

- Use `rs.callTool(...)` for sequential dependent calls.
- Use `rs.callToolAsync(...)` plus `rs.awaitPromises(...)` for independent calls that benefit from parallelism.
- Check every returned result object before reading `content`.
- Use `rs.fail(message, data)` when the whole business action should fail with a structured reason.
- Keep helper functions short and local to the script.
- Prefer explicit field extraction and reshaping over returning raw backend payloads.
- Do not declare tools in the allow-list that the script never calls.
- Do not call tools that are absent from the allow-list.

### When to ask the user

Ask the user to choose when:

- several Services plausibly match the description
- the same action could be implemented as declarative or scripted with materially different tradeoffs
- there is no obvious safe default for the underlying operation
- the result shape is a product decision rather than an implementation detail

### Common mistakes

- Copying the backend tool shape without improving usability.
- Using scripted tools when a declarative mapping would do.
- Omitting tools from the scripted allow-list.
- Using unsupported embedded substitutions such as `Bearer ${token}`.
- Exposing many low-level parameters instead of a task-shaped contract.
- Writing the script before discovering what Services and operations actually exist.
- Returning large intermediate payloads instead of a compact business result.
- Mixing unrelated orchestration paths into one scripted tool.

## ToolsOutputFilters

### Required structure

- Root keys: `apiVersion`, `kind`, `service`, `filters`
- Each filter key targets an existing tool name
- Each filter item must define at least one of `jsonRetain`, `jsonPatches`, `compact`, or `convertToToon`

### Quality criteria

- Use `jsonRetain` first when the main need is to shrink a large response to a few stable branches.
- Use `jsonPatches` to normalize names, remove noisy branches, or add stable derived values.
- Use `compact` when sparse values add noise rather than meaning.
- Use `convertToToon` when compact LLM-oriented output is the primary goal.
- Prefer a small, predictable response shape over a clever but fragile patch sequence.

### Common mistakes

- Treating filters as a security boundary.
- Patching a response before deciding what should be retained.
- Targeting a tool name that is not actually exposed on the bound Service.
- Writing long patch sequences where a narrower custom tool would be cleaner.

## Review Checklist

- Does the artifact kind match the user intent?
- Does `service.name` and `service.version` match the actual target Service exactly?
- Are all required schema fields present?
- Are names optimized for agent comprehension rather than backend fidelity?
- Is the resulting MCP surface smaller, clearer, or safer than the raw baseline?
- Can the capability be verified with `prompts/list`, `resources/list`, `tools/list`, or `tools/call`?