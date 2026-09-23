# reshapr-builder Vally harness

This harness evaluates one narrow question first: does the agent correctly decide
when the `reshapr-builder` skill should be used?

## What it measures

- positive routing cases where the request is clearly about building or validating a reShapr MCP surface
- negative routing cases where the request belongs to documentation, Java controller work, or generic Node.js setup
- evidence quality: the agent must cite concrete clues from the request instead of returning only a yes/no answer

## Files

- `eval.yaml`: the core capability eval
- `reshapr-builder-relevance.experiment.yaml`: comparison run with and without the skill loaded

## Commands

```bash
npm run lint:vally
npm run eval:reshapr-builder
npm run experiment:reshapr-builder
```

## Notes

- The eval uses deterministic graders only, so it does not require an LLM judge.
- The eval uses Vally's preferred `agent_environment` key.
- The experiment isolates one variable, `/environment/skills`, because experiment variants operate on Vally's resolved environment shape.
- This is a routing harness, not yet an end-to-end execution harness for `reshapr` CLI or MCP calls.