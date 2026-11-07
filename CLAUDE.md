# cpp-modern-template

Project code: `cmt`. The vocabulary (types, scopes, branch grammar) lives in
`recipe.ps1` and is written once - read it there, never restate it.

## Rules

1. Work starts from an issue. The branch is named
   `cmt-<issue>/<type>/<slug>` - no branch without an issue number.
2. Commits are `<type>(<scope>): <what changed>`, made with `git commit -s`.
   The description says what changed, not what you were doing. Never skip
   the git hooks (no `--no-verify`, no `-c core.hooksPath=`): the server
   judges every commit again, so a skipped hook only moves the red to the
   pull request.
3. Run `& (Join-Path (git rev-parse --show-toplevel) recipe.ps1) test` before
   proposing anything. Its verdict is `$LASTEXITCODE`, read right after the
   call - never through a pipe, which reports its last command, not the
   recipe. It tests, lints and formats in place: commit what it leaves
   behind, and keep `git status` clean before a merge or a branch switch.
4. This repository never commits a key. That is its one deliberate reversal
   of R-02, which puts keys in a `.claude/.env` committed with the repository:
   here `.claude/.env` is gitignored, is in no commit, and stays on the machine
   that made it. Read keys from that file or from the environment, never ask
   anyone to paste one into a chat, and never write one into a tracked file.
5. `.claude/logs/` holds prompt text, so it stays out of git - `.gitignore`
   must exclude it, and nothing in it is ever committed.
6. Everything written here, and on this repository's Gitea pages - issues,
   pull requests, comments, reviews, releases, the wiki - is written in
   English, whatever language the conversation is in (§5).
7. The gate (`.claude/hooks/gate.ps1`) refuses a recursive delete, a
   force-push, a history rewrite on `test` or `release`, and a tool call it
   cannot read. These pass: a delete whose every path is under `$env:TEMP`
   (your scratchpad), `--force-with-lease` on your own branch, and the
   realign, `git reset --hard origin/<branch>`. Everything else is judged on
   the way into `release` - so do the work, and let the gates judge it.
   Switching a deny off is a change to `gate.ps1` and to this line, in one
   commit.
8. Post a manual test's status (§9) only on the tester's result, stated in
   the current turn, and end its description with `recorded by Claude Code`,
   for example `passed by <login>, recorded by Claude Code`.

Propose into `test` without being asked: once `recipe.ps1 test` is green,
push the branch, open the pull request, and merge it - a merge commit - once
`propose / gate` is green. Where no runner serves this repository there is no
gate: merge once `recipe.ps1 test` is green locally, and say so in the pull
request.

`release` changes only by an act of a name in the recipe's `$Reviewers`:
merging the pull request from `test`, or the owner's override (§8) - the
manual round set aside, a merge past a red or missing check, or a direct push
to `release`. You may open the pull request from `test` into `release`. You
merge it, write the override (the recipe's `$OverridePhrase` on a line of its
own, and a `Why:` line quoting the request), or push to `release` - with the
override in a commit body - only when a `$Reviewers` name tells you to in the
current turn. Say so in the PR comment or the commit body:
`recorded by Claude Code for <login>`.

This is the only rules file. If a rule is not here, it is not a rule -
put it here or drop it.

## Where this repository is deliberately relaxed

- Keys are not committed: rule 4 reverses R-02 by the owner's decision.
- `$Reviewers` names only `igors`, who posts every pull request, so nobody
  is asked for a review and approvals stay 0 (§8, "A lab of one").
- The history from before the lab came in as it stood: `release` starts from
  the old default branch's tip, and nothing was reworded or signed off (R-09).
- Branch protection starts at stage 1 and moves to stage 2 once `propose` and
  `release-gate` have each run once (§8). Until then the gates advise, so
  nothing merges before they are green.
