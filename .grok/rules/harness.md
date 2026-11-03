# Grok harness

This repository is Claude Code Game Studios. Grok loads its rules, its 74 skills, and its 49 agents. Run the skill the user invoked. Where that skill names a Claude tool, call the Grok tool.

Start `grok` in the directory that holds `CLAUDE.md` and `project.yaml`.

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

An agent team in this project is the orchestrator spawning specialists in this session with `spawn_subagent`, not `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.

`model: opus`, `model: sonnet`, and `model: haiku` on a skill or an agent mean this session's model.

Three studio commands share a name with a Grok command. The studio skill is the qualified one: `/local:help`, `/local:settings`, `/local:changelog`. Every other studio skill keeps its bare name, including `/start`, `/brainstorm`, `/setup-engine`, and `/dev-story`.

Image and video generation for a game asset runs `/produce-asset`. It reads the approved spec, asks before each generation, and writes into the engine asset root.

Ask before a write the way `CLAUDE.md` states: "May I write this to [filepath]?" When a skill says `AskUserQuestion`, call `ask_user_question`. Ask even if a hook also runs. Do not reimplement the hooks or deny rules in `.claude/settings.json`. Whether this checkout loaded them is what `grok inspect` reports. PowerShell-prefixed denies in that file do not apply.

A `!` shell line, `${CLAUDE_SKILL_DIR}`, or `$ARGUMENTS` in a skill body is literal text. Grok does not run it. If the skill says what to do when the block did not render, do that. Otherwise run the command with `run_terminal_command`. For `/setup-engine`, that fallback is `workflow: minimal`.
