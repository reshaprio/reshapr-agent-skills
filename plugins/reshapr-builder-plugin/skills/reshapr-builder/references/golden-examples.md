# Artifact Golden Examples

These patterns are adapted from the curated Web UI artifact examples so the skill can reuse proven shapes instead of inventing every artifact from scratch.

Use the closest example as a starting point, then customize names, descriptions, bindings, and payload shape for the actual Service.

Full, schema-valid YAML files are available in [`assets/`](../assets/):

- [Prompts golden examples](../assets/prompts-examples.yaml)
- [Resources golden examples](../assets/resources-examples.yaml)
- [CustomTools golden examples](../assets/customtools-examples.yaml)
- [ToolsOutputFilters golden examples](../assets/toolsoutputfilters-examples.yaml)

Each asset file contains several complete entries under one placeholder `service` binding. Copy the entries you need, replace `<Service Name>` / `<Service Version>` with the real target Service, and delete the entries you do not need.

## Prompts

### Simple prompt

- Use when the client needs a reusable static instruction with no arguments.
- Pattern: one prompt with `title`, `description`, and a direct `result`.

### Parameterized prompt

- Use when the prompt needs caller-supplied context.
- Pattern: define `arguments`, then reuse them with `${argument}` placeholders inside `result`.

### Tool-guiding prompt

- Use when the prompt should steer the model toward one known MCP tool and argument mapping.
- Pattern: tell the model explicitly which tool to call and how to map the prompt argument to the tool input.

## Resources

### Inline resource

- Use when the content is static and should be served directly from the artifact.
- Pattern: `text` content embedded directly in the YAML.

### Backend resource

- Use when the resource should be fetched live from the backend endpoint on each read.
- Pattern: define metadata but omit inline content.

### Resource template

- Use when the resource space is parameterized and clients should expand a URI template.
- Pattern: put the entry under `resourceTemplates` rather than `resources`.

### MCP App resource

- Use when the resource is an interactive UI surface rather than plain content.
- Pattern: `ui://` URI, `mimeType: text/html;profile=mcp-app`, `remoteContent`, and UI-specific metadata.

## CustomTools

### Operation alias

- Use when one backend operation is correct but needs a friendlier name and cleaner public input.
- Pattern: declarative `tool` plus templated `arguments`.

### Multi-operation orchestration

- Use when several sequential calls should look like one task-shaped action.
- Pattern: scripted tool using `rs.callTool(...)` and compact final reshaping.

### Async orchestration

- Use when several independent calls can start concurrently.
- Pattern: `rs.callToolAsync(...)` plus `rs.awaitPromises(...)` and a small summarizer helper.

### Structured exception handling

- Use when a primary call failure should stop the whole action while secondary failures can be tolerated.
- Pattern: terminal failure via `rs.fail(...)`, secondary failure captured in the final payload.

## ToolsOutputFilters

### Retain fields

- Use when the main goal is to shrink a large JSON response to a few essential branches.
- Pattern: `jsonRetain` with a short list of JSON Pointer paths.

### JSON Patch edits

- Use when the response shape is almost correct but needs deterministic edits.
- Pattern: `jsonPatches` with a short ordered list of RFC 6902 operations.

### Compact output

- Use when the payload is noisy because of many sparse values.
- Pattern: `compact: true`.

### Convert to Toon

- Use when the main objective is an even smaller LLM-oriented payload.
- Pattern: `convertToToon: true`, optionally after retain or patch steps.

## Reuse rules

- Start from the closest example category, not from a blank page.
- Preserve only the structural pattern; replace the sample names and descriptions with Service-specific ones.
- Re-check the final artifact against the JSON schema and the target Service after customization.