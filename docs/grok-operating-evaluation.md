# Grok CLI operating-surface evaluation

A Grok session in this checkout is not a Claude session with the tool names swapped. Three facts decide the first day of work. Each one was taken from a raw file or from `grok inspect` on this tree, then checked again by `.claude/scripts/grok-operating-contract.sh`.

## What an expert does that was not requested

Do not treat a compatibility inventory as a defect list, and do not tell the model that Claude hooks are off. Read the skill file Grok will actually load, run the command that file only mentions, and ask `grok inspect` what this process loaded. The earlier warning that deny rules and hook events should be assumed absent was the wrong way around on this machine.

## Raw material

Not the inventory summary. These files:

- `.claude/skills/setup-engine/SKILL.md` still contains the literal line `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow` `` and the next instruction: if the block did not render, assume `minimal`.
- `.claude/settings.json` is the hook and deny list. `grok inspect` (Grok 1.0.74, this directory, folder trusted) reports that file as a permission source, reports the project `session-start` hook `compatibilityStatus: enabled`, and skips PowerShell-prefixed denies as an unknown tool prefix.
- `.claude/docs/agent-teams.md` still requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` for multi-session teams.
- `CLAUDE.md` lines 60-61 still say hooks, deny rules, and ask-first mode load only when Claude Code starts here.

Grok's own skill document says a `` !`command` `` in a skill body runs nothing and reaches the model as literal text. That is why the setup-engine line is still in the file after Grok has loaded the skill.

## Method

`grok inspect --json` for `invocableAs`, hook `compatibilityStatus`, and permission skip reasons. `bash .claude/hooks/yaml-helper.sh resolve_config --keys workflow` for the command the bang line names. It printed `workflow: minimal (rigor:minimal)`, which matches the skill's unrendered fallback while `project.yaml` has no `modes:` block. The contract script runs those checks. It exits 1 when a fact is missing and 2 when `grok` or the skill file cannot be read. A string match between the harness and the README is not the witness.

## What else shows this is right

`grok inspect` is a second program. It reported `/local:help`, `/local:settings`, and `/local:changelog`, and bare `/start`, `/brainstorm`, `/setup-engine`, `/dev-story`, and `/produce-asset`. The contract script fails if those qualified names change. Removing `spawn_subagent` from a copy of the harness makes the same script exit 1. `CLAUDE.md` is not in the diff.

## technical-director

`.claude/docs/agent-teams.md` is a second Claude session, opt-in with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. This session spawns specialists with `spawn_subagent`. `.claude/hooks/log-agent.sh` already accepts `subagentType` when that hook runs. Inspect shows the project `subagent_start` hook enabled. Do not reimplement it.

## producer

`README.md` section `在 Grok 里用` and `.grok/rules/harness.md` are the two texts a session loads for this contract. Ask-before-write stays the `CLAUDE.md` question "May I write this to [filepath]?", including when a hook also runs.

## lead-programmer

The load-bearing raw line is the bang line in `.claude/skills/setup-engine/SKILL.md`, not the hit count of `!` lines. Tool names in `.claude/skills/team-combat/SKILL.md` (`AskUserQuestion`, `Agent`, `TaskCreate`) are already the harness table. Leave the skill bodies alone.

## Ranked list

1. **required** — Both loaded texts say a `!` line, `${CLAUDE_SKILL_DIR}`, and `$ARGUMENTS` are literal, and that `/setup-engine` falls back to `workflow: minimal` when the block did not render.
2. **required** — Both loaded texts say to ask before a write even if a hook runs, not to reimplement `.claude/settings.json`, and to use `grok inspect` as the witness. PowerShell-prefixed denies do not apply.
3. **required** — `.claude/scripts/grok-operating-contract.sh` checks the two texts, the raw setup-engine lines, `resolve_config --keys workflow`, and live `grok inspect` names and hook status.
4. **deferred** — Leave `CLAUDE.md` lines 60-61 unchanged. Those lines are: "Started outside this file's folder? Warn first: hooks, deny rules and the ask-first mode load only when Claude Code starts here". Reason: the sentence names Claude Code and is that client's start warning. A Grok session also loads the file. The Grok rule is in the harness and the README section, checked against `grok inspect`. Rewriting lines 60-61 would make the Claude warning false. No `CLAUDE.md` diff.
5. **deferred** — Rewrite `.claude/skills/` or `.claude/agents/` to delete bang lines or rename tools. Reason: the literal bang line is evidence the fallback still applies. The harness map covers the tool names.
6. **deferred** — Reimplement hooks, the status line, or deny rules. Reason: inspect shows the project hooks enabled and the settings file loaded. Copying them would fork the list.
7. **deferred** — Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Reason: teams here are in-session `spawn_subagent` calls.
