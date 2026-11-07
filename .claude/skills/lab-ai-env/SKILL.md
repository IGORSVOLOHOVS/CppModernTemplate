---
name: lab-ai-env
description: >-
  Report on this repository's AI environment: reads the hooks' event log
  .claude/logs/ai.jsonl and the Claude Code transcripts in
  ~/.claude/projects/<project>/, and writes .claude/logs/report-<date>.md -
  totals, failures, friction, context health, prompt quality, and suggestions
  that cite log lines. Use when the user asks where the tokens went, why
  sessions stall, fail or ask for permission, what the hooks logged, how to
  tune CLAUDE.md or settings.json, or says "AI usage report", "lab-ai-env",
  "отчёт по токенам", "куда ушли токены", "разбери логи Claude".
---

# lab-ai-env

## What the environment records

- `.claude/logs/ai.jsonl` - one JSON object per line, UTF-8 without a BOM,
  appended by the hooks in `.claude/settings.json`: `log.ps1`, `gate.ps1`,
  `session-start-stop.ps1`. Fields: `ts`, `event`, `session`, `tool`,
  `decision` (`deny`, from the gate), `detail` (the first 200 characters of a
  prompt, message or reason). A field an event lacks is omitted. Events:
  SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Notification,
  SubagentStop, PreCompact, Stop, SessionEnd. Over 10 MB it is moved to
  `ai.jsonl.<yyyyMMddHHmmss>.bak` at SessionStart. An older file may start
  with a BOM, and its gate lines carry no `session`: read it as `utf-8-sig`.
  `{"ts":"2026-09-08T20:29:27+03:00","event":"PreToolUse","session":"abc","tool":"Bash","decision":"deny"}`
- `~/.claude/projects/<project>/<session>.jsonl` - the transcripts; subagents
  in `<session>/subagents/agent-*.jsonl`. `<project>` is the repository's
  absolute path with every character outside `[A-Za-z0-9]` turned into `-`:
  `C:\Users\me\waam-monitoring` -> `C--Users-me-waam-monitoring`. Assistant
  lines carry `message.usage` (`input_tokens`, `output_tokens`,
  `cache_read_input_tokens`, `cache_creation_input_tokens`); a failed tool
  call is a `tool_result` with `is_error: true`, and its error text exists
  only there.

Both hold prompt text: `.claude/logs/` stays out of git, and so does the report.

## Steps

1. Take the period from the user; without one, cover everything in both
   sources.
2. Count with a throwaway Python script in the scratchpad, streaming line by
   line - a transcript runs to megabytes, so never read one whole into the
   context. Keep, for every finding, the file and line it came from.
3. Read `CLAUDE.md` (root or `.claude/`) and `.claude/settings.json`, so each
   suggestion is an edit to a named line.
4. Write `.claude/logs/report-<yyyy-mm-dd>.md`, the six parts below in this
   order, and answer with its path and the three numbers that matter most.

## The report

1. **Totals** - sessions, turns, subagents, tokens in and out, cache-hit
   ratio (`cache_read / (input + cache_read + cache_creation)`).
2. **Failures** - the ten most frequent failing tool calls, the first line of
   each error, and the CLAUDE.md line that would have prevented it.
3. **Friction** - gate denials and permission prompts (Notification) per
   session, with the allowlist entry that would remove each repeated one.
4. **Context health** - compactions per session (PreCompact), tokens before
   each, files read more than twice in one session.
5. **Prompt quality** - prompts followed by a reverted edit, and prompts
   Claude had to ask back about, quoted to 200 characters.
6. **Suggestions** - concrete diffs: lines for CLAUDE.md, permissions for
   settings.json, a skill for work repeated in 3 or more sessions. Each cites
   the lines that justify it: `ai.jsonl:1204`, `<session>.jsonl:88`.

Facts only: every sentence carries a number, a path or a log line; no
adjective stands in for a count. The report proposes; applying a suggestion
is a separate change, made on an issue branch.
