#!/usr/bin/env bash
# grok-operating-contract.sh — gate for the two texts a Grok session loads
# at the repo root: .grok/rules/harness.md and the README section
# "在 Grok 里用". Exit 1 when either text is missing a required fact.
# Exit 2 when a file cannot be read (NOT ASSESSED). Exit 0 prints PRESENT
# lines and nothing else that would change between runs.
#
# This is a string gate, not an observation helper. compat-inventory.sh
# reports Claude-only constructs and always exits 0. This script fails
# when the operating contract is absent, because a silent skip would look
# the same as a pass.
#
# Usage: bash .claude/scripts/grok-operating-contract.sh [--root DIR]
#   --root DIR   check that tree instead of this repo (fixture runs)

set -u

ROOT=""
ROOT_SET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      [ $# -ge 2 ] || { echo "OPERATING_CONTRACT: fail" >&2; echo "MISSING: --root value" >&2; exit 2; }
      ROOT="$2"
      ROOT_SET=1
      shift 2 ;;
    --root=*) ROOT="${1#--root=}"; ROOT_SET=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0"; exit 0 ;;
    *) echo "OPERATING_CONTRACT: fail"; echo "MISSING: unknown argument $1"; exit 2 ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" || {
    echo "OPERATING_CONTRACT: fail"
    echo "NOT ASSESSED: cannot resolve repo root from script path"
    exit 2
  }
fi

HARNESS="$ROOT/.grok/rules/harness.md"
README="$ROOT/README.md"

if [ ! -r "$HARNESS" ]; then
  echo "OPERATING_CONTRACT: fail"
  echo "NOT ASSESSED: cannot read .grok/rules/harness.md"
  exit 2
fi
if [ ! -r "$README" ]; then
  echo "OPERATING_CONTRACT: fail"
  echo "NOT ASSESSED: cannot read README.md"
  exit 2
fi

SECTION="$(awk '
  /^## 在 Grok 里用$/ { capture=1; next }
  capture && /^## / { exit }
  capture { print }
' "$README")"

if [ -z "$SECTION" ]; then
  echo "OPERATING_CONTRACT: fail"
  echo "MISSING: README.md#在 Grok 里用 section"
  exit 1
fi

# One fact per line. The long lines are the statements that must appear
# verbatim in both texts, not a loose mention of a token.
FACTS='spawn_subagent
/local:help
/local:settings
/local:changelog
/produce-asset
/start
/brainstorm
/setup-engine
/dev-story
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
Start `grok` in the directory that holds `CLAUDE.md` and `project.yaml`.
An agent team in this project is the orchestrator spawning specialists in this session with `spawn_subagent`, not `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.'

missing=0
while IFS= read -r fact; do
  [ -n "$fact" ] || continue
  if ! grep -F -q -e "$fact" "$HARNESS"; then
    echo "MISSING: .grok/rules/harness.md $fact"
    missing=1
  fi
  if ! printf '%s\n' "$SECTION" | grep -F -q -e "$fact"; then
    echo "MISSING: README.md#在 Grok 里用 $fact"
    missing=1
  fi
done <<EOF
$FACTS
EOF

# Raw skill text, not the inventory summary. The bang line must still be
# literal in the file Grok reads, and the skill must still name its fallback.
SETUP="$ROOT/.claude/skills/setup-engine/SKILL.md"
if [ ! -r "$SETUP" ]; then
  echo "NOT ASSESSED: cannot read .claude/skills/setup-engine/SKILL.md"
  echo "OPERATING_CONTRACT: fail"
  exit 2
fi
if ! grep -F -q -e '!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow`' "$SETUP"; then
  echo "MISSING: .claude/skills/setup-engine/SKILL.md bang line"
  missing=1
fi
if ! grep -F -q -e 'If the block did not render (shell preprocessing disabled), assume `minimal` (the default).' "$SETUP"; then
  echo "MISSING: .claude/skills/setup-engine/SKILL.md unrendered fallback"
  missing=1
fi

RESOLVE_OUT=""
if ! RESOLVE_OUT="$(bash "$ROOT/.claude/hooks/yaml-helper.sh" resolve_config --keys workflow 2>/dev/null)"; then
  echo "NOT ASSESSED: resolve_config --keys workflow failed"
  echo "OPERATING_CONTRACT: fail"
  exit 2
fi
case "$RESOLVE_OUT" in
  "workflow: "*) ;;
  *) echo "MISSING: resolve_config workflow line"; missing=1 ;;
esac

# Live witness. File checks above do not ask Grok what it loaded.
# --root is a fixture for the string gate; inspect always describes the
# checkout grok was launched in, so a fixture does not consult it.
INSPECT_LINES=""
if [ -z "${ROOT_SET:-}" ]; then
  if ! command -v grok >/dev/null 2>&1; then
    echo "NOT ASSESSED: grok inspect not on PATH"
    echo "OPERATING_CONTRACT: fail"
    exit 2
  fi
  INSPECT_JSON="$(mktemp)"
  if ! grok inspect --json >"$INSPECT_JSON" 2>/dev/null; then
    rm -f "$INSPECT_JSON"
    echo "NOT ASSESSED: grok inspect failed"
    echo "OPERATING_CONTRACT: fail"
    exit 2
  fi
  INSPECT_LINES="$(python3 - "$ROOT" "$INSPECT_JSON" <<'PY'
import json, sys
root = sys.argv[1].rstrip("/")
try:
    with open(sys.argv[2], encoding="utf-8") as handle:
        data = json.load(handle)
except (OSError, json.JSONDecodeError):
    print("NOT ASSESSED: grok inspect JSON")
    sys.exit(2)
qualified = {"help": "local:help", "settings": "local:settings", "changelog": "local:changelog"}
bare = ["start", "brainstorm", "setup-engine", "dev-story", "produce-asset"]
found = {}
for skill in data.get("skills") or []:
    path = ((skill.get("source") or {}).get("path")) or ""
    if path.startswith(root + "/"):
        found[skill.get("name")] = skill
problems = []
lines = []
for name, expect in qualified.items():
    skill = found.get(name)
    if not skill or skill.get("invocableAs") != expect or skill.get("collidesWith") != name:
        problems.append("MISSING: inspect %s invocableAs %s" % (name, expect))
    else:
        lines.append("INSPECT: %s %s" % (name, expect))
for name in bare:
    skill = found.get(name)
    if not skill or skill.get("collidesWith") or skill.get("invocableAs"):
        problems.append("MISSING: inspect %s bare" % name)
    else:
        lines.append("INSPECT: %s bare" % name)
hook_ok = False
for hook in data.get("hooks") or []:
    src = (hook.get("source") or {}).get("path") or ""
    target = hook.get("target") or ""
    if src == root + "/.claude" and hook.get("compatibilityStatus") == "enabled" and "session-start.sh" in target:
        hook_ok = True
        break
if hook_ok:
    lines.append("INSPECT: project session-start hook enabled")
else:
    problems.append("MISSING: inspect project session-start hook enabled")
perm = data.get("permissions") or {}
sources = perm.get("sources") or []
if any(root in item and "settings.json" in item for item in sources):
    lines.append("INSPECT: settings.json loaded")
else:
    problems.append("MISSING: inspect settings.json loaded")
skipped = perm.get("skipped") or []
if any("PowerShell" in json.dumps(item) for item in skipped):
    lines.append("INSPECT: powershell deny skipped")
else:
    problems.append("MISSING: inspect powershell deny skipped")
if problems:
    print("\n".join(problems))
    sys.exit(1)
print("\n".join(lines))
PY
)"
  inspect_status=$?
  rm -f "$INSPECT_JSON"
  if [ "$inspect_status" -eq 2 ]; then
    printf '%s\n' "$INSPECT_LINES"
    echo "OPERATING_CONTRACT: fail"
    exit 2
  fi
  if [ "$inspect_status" -ne 0 ]; then
    printf '%s\n' "$INSPECT_LINES"
    missing=1
  fi
fi

if [ "$missing" -ne 0 ]; then
  echo "OPERATING_CONTRACT: fail"
  exit 1
fi

echo "OPERATING_CONTRACT: ok"
echo "CHECKED: .grok/rules/harness.md"
echo "CHECKED: README.md#在 Grok 里用"
while IFS= read -r fact; do
  [ -n "$fact" ] || continue
  echo "PRESENT: $fact"
done <<EOF
$FACTS
EOF
echo "RAW: setup-engine bang literal"
echo "RAW: setup-engine unrendered fallback"
printf 'RESOLVE: %s\n' "$RESOLVE_OUT"
if [ -n "$INSPECT_LINES" ]; then
  printf '%s\n' "$INSPECT_LINES"
fi

exit 0
