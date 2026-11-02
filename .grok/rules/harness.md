# Grok harness

This repository is Claude Code Game Studios. Grok loads its rules, its 74 skills, its 49 agents, and its hooks. Run the skill the user invoked. Where that skill names a Claude tool, call the Grok tool.

| When the skill says | Call |
|---|---|
| `AskUserQuestion` | `ask_user_question` |
| `Agent` or `Task` with a type | `spawn_subagent`, `subagent_type` set to that agent |
| `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet` | `todo_write` |
| `Read` | `read_file` |
| `Write` | `write` |
| `Edit` | `search_replace` |
| `Grep` | `grep` |
| `Glob` or `LS` | `list_dir` for names, `grep` when the skill wants file contents |
| `Bash` | `run_terminal_command` |
| `WebSearch` | `web_search` |
| `WebFetch` | `web_fetch` |

This session is the orchestrator. Spawn each specialist from here with `spawn_subagent`. When a skill tells a specialist to spawn another specialist, do that spawn yourself and pass the destination path in the prompt. The skill's bounded write exception still applies: a new file under `production/`, `docs/`, or `tests/`, at a path the skill named, inside a phase the user approved.

`model: opus`, `model: sonnet`, and `model: haiku` on a skill or an agent mean this session's model.

Three studio commands share a name with a Grok command. The studio skill is the qualified one: `/local:help`, `/local:settings`, `/local:changelog`. Every other studio skill keeps its bare name, including `/start`, `/brainstorm`, `/setup-engine`, and `/dev-story`.

Image and video generation for a game asset runs `/produce-asset`. It reads the approved spec, asks before each generation, and writes into the engine asset root.
