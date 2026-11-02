---
name: produce-asset
description: >
  Produce a game asset from an approved spec: a canonical anchor, then
  variants, a sprite sheet, or a short motion reference, written into the
  engine asset root. Use when the user runs /produce-asset or asks to
  generate, draw, or animate a sprite, icon, tileset, character, or motion
  reference (生成、画、出图、精灵图、序列帧、动作参考).
argument-hint: "ASSET-012 or an asset name"
user-invocable: true
metadata:
  short-description: "Generate a specced game asset"
---

# Produce asset

`/asset-spec` writes the spec. This skill makes the files. It does not edit
`/art-bible`, `/asset-spec`, or an art bible.

Generation is an external call. Ask before it in every automation mode. A
plan the user approved covers only the calls that plan lists.

## 1. Resolve the asset

Accept an `ASSET-NNN` id, a name, or no argument.

With no argument, read `design/assets/asset-manifest.md` when it exists and
take the first row whose status is `Needed` and whose spec file exists. Ask
whether that row is the one to produce. No manifest: ask for an id or a name.

Read the matching `## ASSET-NNN` block in `design/assets/specs/`. The block's
**Visual Description** and **Naming** field are the brief. Its **Generation
Prompt** is Midjourney-style text; do not paste it into a tool.

No spec block: if `design/game-brief.md` exists, one confirmed description
plus that brief is enough, and the user confirms the file name. Say the
result is a proposal, not a constraint, and offer `/asset-spec` once. No
spec and no brief: stop and name `/asset-spec`. Do not invent a spec.

Done when the asset has a name, a visual description, and a destination
file name.

## 2. Load direction

Read `design/art/art-bible.md` when it exists. Otherwise use the spec's
**Art Bible Anchors** or **Brief anchor**, or the brief's **Art & audio
direction** line. A brief used as direction is a proposal, not a constraint.

No bible, no brief, and no anchor text on the spec: stop. Name `/brainstorm`
or `/art-bible`.

Done when the style constraints are quotes from one of those sources.

## 3. Classify

| The spec or the user asks for | Produce |
|---|---|
| A still: character, prop, icon, tile, background | One anchor, then variants |
| A set or palette swap | The same anchor, then one edit per variant |
| Frames, a cycle, or a sprite sheet | A sheet, via the installed `game-assets` reference for animation |
| An animatic, motion test, VFX preview, or loop | A video reference, default 6 seconds |
| UI that must show exact text, numbers, or a fixed layout | No image. Say to build it in code |
| Audio | No audio. Leave the spec's sonic description as the record |
| A 3D mesh or `.glb` | The installed `game-assets` 3D reference, starting from the anchor |

A video reference is not an engine sprite. A sheet's frames are the sprite.

Done when one row of the table is chosen and stated.

## 4. Plan, then ask

Read the installed `imagine` skill and the installed `game-assets` skill
before showing the plan. Read that skill's core asset reference, then the
one reference it names for this row. Follow those files for prompt shape,
tool choice, consistency, frame harvest, and a call that is refused or
cannot run.

Show the plan: asset id, the row above, each call (tool and purpose), and
the destination paths from the table below. Ask with `ask_user_question`.
That yes covers only those calls. Another call, or a retry past the
game-assets discard budget, asks again.

Write the prompt as 2–5 sentences of prose from the visual description and
the direction quotes. Positive description. No negative-prompt line.

The first image of a subject is the anchor. Later poses, variants, and
textures use `image_edit` on that anchor. A motion reference pins the
anchor as its first frame.

Done when the user has approved the listed calls, or has stopped the run.

## 5. Check, then place

Read each result back. Describe what the file shows, then compare that
description to the spec and to the engine-ready defaults in the game-assets
core reference. State each failed check. If the file cannot be read, say
the check did not run.

Copy a file into the repo only after the user accepts that result. Ask
first, naming each path. Copy the image or video only. Do not write
`.meta`, `.import`, or `.uid` beside it. An existing file at that path
needs its own yes before it is replaced.

| `engine.name` in `project.yaml` | Anchor | Still / sheet | Video reference |
|---|---|---|---|
| Unset or `godot` | `design/art/anchors/` | `assets/art/` or `assets/vfx/` | `assets/video/` |
| `unity` | `design/art/anchors/` | `Assets/Art/` or `Assets/VFX/` | `Assets/Video/` |
| `unreal` | `design/art/anchors/` | `Content/Art/` or `Content/VFX/` | `Content/Video/` |

The spec **Naming** field is the deliverable's file name. The anchor uses
that stem under `design/art/anchors/`. VFX categories use the VFX directory;
everything else in the still/sheet column uses the art directory. A `.glb`
uses the art directory.

When `engine.name` is absent, say that the engine is unset and that the
files are under `assets/`.

## 6. Manifest

Mark the row `Done` only after the user has accepted a result whose check
ran and passed. Ask, in one question, before editing
`design/assets/asset-manifest.md` and the spec block's **Status** line.
Leave both unchanged when the check failed, the check did not run, or the
user rejects the result.

No manifest row: do not invent an `ASSET-NNN` id. The file may still be
copied. Say the asset is not on the manifest.

Done when the status write has happened, or you have said why it did not.
