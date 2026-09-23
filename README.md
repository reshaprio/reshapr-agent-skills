# reShapr Agent skills

Agent plugins and skills for using the reShapr platform.

[![License](https://img.shields.io/github/license/reshaprio/reshapr-controllers?style=for-the-badge&logo=apache)](https://www.apache.org/licenses/LICENSE-2.0)
[![Project Chat](https://img.shields.io/badge/discord-reshapr-pink.svg?color=7289da&style=for-the-badge&logo=discord)](https://discord.gg/KyDUdam34h)
[![GitHub stars](https://img.shields.io/github/stars/reshaprio/reshapr-agent-skills?style=for-the-badge&logo=github&color=ffad05)](https://github.com/reshaprio/reshapr-agent-skills)

## What this is

This repository packages agent knowledge for building, refining, and validating [reShapr](https://reshapr.io)
MCP servers — as installable **plugins** (for agent marketplaces) and as **skills** (`SKILL.md`)
that coding agents such as GitHub Copilot or Claude Code can load on demand.

## Repository layout

```text
marketplace.json           # Marketplace manifest listing available plugins
plugins/
  reshapr-builder-plugin/  # plugin.json + skills/reshapr-builder/SKILL.md (canonical source)
  reshapr-operator/        # reserved for a future operator-facing plugin
.github/skills/            # Workspace-discoverable skills (symlinked into plugins/*/skills)
evals/                     # Vally eval and experiment harnesses for skill quality
.vally.yaml                # Vally configuration (skill, eval, and results paths)
```

Each skill under `plugins/*/skills/<name>/` follows the standard `SKILL.md` + `assets/` +
`references/` layout. `.github/skills/<name>` is a symlink to its plugin skill, so the same
source is discovered both as a marketplace plugin and as a workspace skill.

## Available plugins

| Plugin | Description |
| --- | --- |
| [`reshapr-builder`](./plugins/reshapr-builder-plugin) | Create, refine, and validate reShapr MCP servers: import APIs, attach Prompts/Resources/CustomTools/ToolsOutputFilters, select operations, expose endpoints, and test MCP methods — locally (`reshapr run`) or against an existing control plane. |

## Requirements

- Node.js `>=22`

## Getting started

```bash
npm install
```

To use the plugins from this repo locally in VS Code, open this folder as a workspace: `.vscode/settings.json`
already registers it as a local plugin marketplace (`chat.plugins.marketplaces`).

## Validating skills with Vally

Skills are linted and evaluated with [Vally](https://www.npmjs.com/package/@microsoft/vally-cli):

```bash
npm run lint:skills          # lint every skill under the configured paths
npm run lint:skills:strict   # same, failing on warnings too
npm run lint:evals           # also validate the eval specs under evals/
npm run lint:vally           # strict lint of skills and evals together
```

## Evaluating skill relevance

`evals/reshapr-builder-relevance` checks that an agent correctly decides when the
`reshapr-builder` skill should be used, with deterministic graders (no LLM judge required):

```bash
npm run eval:reshapr-builder        # run the routing eval
npm run experiment:reshapr-builder  # compare behavior with and without the skill loaded
```

See [`evals/reshapr-builder-relevance/README.md`](./evals/reshapr-builder-relevance/README.md) for details.

## Adding a new skill

1. Create `plugins/<plugin-name>/plugin.json` and `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`.
2. Add an entry for the plugin in [`marketplace.json`](./marketplace.json).
3. Symlink it under `.github/skills/<skill-name>` so it is also discoverable as a workspace skill.
4. Run `npm run lint:skills` and add an eval under `evals/` for routing or capability checks.

## License

Apache License 2.0 — see [LICENSE](./LICENSE).

