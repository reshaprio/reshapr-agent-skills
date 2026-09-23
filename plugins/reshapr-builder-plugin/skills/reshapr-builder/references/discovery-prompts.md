# Discovery Prompts Playbook

Use this playbook when the user request is too vague to map directly to a Service, Configuration Plan, operation, or artifact shape.

Ask the minimum number of questions needed to remove ambiguity. Prefer questions that change the generated artifact materially.

## General questions

- What business action should the MCP capability accomplish from the user point of view?
- Should this become a Prompt, Resource, Custom Tool, or Output Filter?
- Are you targeting the local `reshapr run` environment or an existing control plane?
- Do you already know the target Service name and version, or should I discover candidates?

## Service-selection questions

Ask these after running `reshapr service list --output json` and `reshapr config list --output json`.

- Which of these candidate Services should the artifact bind to?
- Should I prefer a Service already used by an existing Configuration Plan, or create a new surface?
- Is this workflow expected to stay within one Service, or is cross-Service orchestration acceptable?

## Prompts questions

- Should the prompt be static, or does it need caller-supplied arguments?
- Is the prompt meant to guide tool usage explicitly, or just provide reusable instructions?
- What tone or output style should the prompt enforce?

## Resources questions

- Is this a fixed resource, or a parameterized family of resources?
- Should the content be embedded inline, fetched from the backend dynamically, or referenced remotely?
- Who is the intended audience: user, model, app, or several of them?

## Declarative CustomTools questions

- Which single backend tool or operation should this custom tool wrap?
- Which backend arguments should stay fixed, and which should come from the MCP client input?
- What should the public tool name be if we optimize for the business task instead of the backend name?

## Scripted CustomTools questions

- What is the one bounded business action the script must provide?
- Which result fields are actually needed by the MCP client at the end?
- If several Services are available, which ones are allowed to participate in the orchestration?
- Should failures of secondary calls be tolerated, or should the whole action fail?
- Are some calls independent enough to run in parallel?

## ToolsOutputFilters questions

- Is the main problem excess payload size, unstable structure, sparse values, or all of these?
- Which fields must always survive in the final result?
- Should the filtered result stay JSON-shaped, or be converted to Toon?

## Stop conditions

Do not keep asking questions once you can name:

- the target artifact kind
- the target Service
- the intended capability name
- the minimum input or retained output shape
- the validation step that will confirm the artifact works