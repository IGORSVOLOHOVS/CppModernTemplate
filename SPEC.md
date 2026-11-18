# SPEC: cpp-modern-template

Software requirements specification reverse-engineered from the code at commit
`44d63d7` (2026-11-08). Written 2026-11-18. Every requirement names the file and
lines it was read from. Nothing here is a plan: what the repository declares but
does not do is listed separately in 3.8. The hub for the other documents is
[docs/README.md](docs/README.md).

<!-- jira-sync:start -->
Jira: KAN-96

## Tasks

This list is one ticket in Jira project KAN, [KAN-96](https://igorsvolohovs.atlassian.net/browse/KAN-96). Each line is a checkbox there: tick it in Jira and the sync ticks it here; add a checkbox there and it is appended here. Done items are the features described in section 3; open items are what the project declares but the code does not do yet.

- [x] Build (Makefile) (section 3.1) <!-- spec-build-makefile -->
- [x] Example program (src/main.cpp) (section 3.2) <!-- spec-example-program-src-main-cpp -->
- [x] Editor integration (.vscode) (section 3.3) <!-- spec-editor-integration-vscode -->
- [x] Repository interface (recipe.ps1) (section 3.4) <!-- spec-repository-interface-recipe-ps1 -->
- [x] Git hooks (.claude/hooks/git) (section 3.5) <!-- spec-git-hooks-claude-hooks-git -->
- [x] Claude Code hooks (.claude) (section 3.6) <!-- spec-claude-code-hooks-claude -->
- [x] CI workflows (.gitea/workflows) (section 3.7) <!-- spec-ci-workflows-gitea-workflows -->
- [ ] Qt 5 build (declared, not implemented) <!-- spec-qt-5-build -->
- [ ] Boost uBLAS, Google Benchmark, Google Test, SQLite examples (declared, not implemented) <!-- spec-boost-ublas-google-benchmark-google-test-sqlite-ex -->
- [ ] `include/`, `lib/`, `module/`, `bin/` folders (declared, not implemented) <!-- spec-include-lib-module-bin-folders -->
- [ ] Verbs `build`, `install`, `uninstall`, `run`, `publish` (declared, not implemented) <!-- spec-verbs-build-install-uninstall-run-publish -->
- [ ] Installer, wiki, manual tests, changelog (declared, not implemented) <!-- spec-installer-wiki-manual-tests-changelog -->
- [ ] Lab requirement exceptions R-02, R-09, R-37, R-41, R-42 (declared, not implemented) <!-- spec-lab-requirement-exceptions-r-02-r-09-r-37-r-41-r-4 -->
- [ ] Branch protection stage 2 (declared, not implemented) <!-- spec-branch-protection-stage-2 -->

<!-- jira-sync:end -->

## 1. Purpose and scope

The repository is a C++20 project skeleton for g++ under MSYS2 MinGW with one
example OpenGL program, "a template to copy from, not a program" (`README.md:3-5`),
plus the tooling that keeps the repository under the owner's lab rules
(`recipe.ps1`, `CLAUDE.md`, `.claude/`, `.gitea/`).

In scope:

- the `Makefile` build of `src/`, `module/`, `include/`, `lib/` into `bin/main`;
- the example program `src/main.cpp`;
- the Visual Studio Code configuration in `.vscode/`;
- `recipe.ps1`, the Git hooks, the Claude Code hooks, the Gitea workflows.

Out of scope (no code for it in the repository):

- any program logic beyond the triangle demo; any use of Google Test, Google
  Benchmark or SQLite, although they are linked;
- a Linux or macOS build (`README.md:12-13`);
- packaging or installing anything: `$Provides = @()` and no `$App`
  (`recipe.ps1:16-17`);
- building or testing the C++ code in CI (`recipe.ps1:69-73`, `README.md:28-29`).

## 2. Context

| Item | Value | Source |
|---|---|---|
| Actors | A developer who copies the template; the repository owner and Claude Code working under `CLAUDE.md`; the Gitea bot account behind `LAB_BOT_TOKEN`. Who else uses the template is not stated. | `README.md:5`, `CLAUDE.md`, `.gitea/workflows/*.yaml` |
| Build host OS | Windows: MinGW library names `-lGLEW32`, `-lopengl32`. | `Makefile:17`, `README.md:12-13` |
| Toolchain | g++ (MSYS2 MinGW x86_64 at `C:/msys64/mingw64/bin/g++.exe` in the IDE config), GNU make, gdb. | `Makefile:1`, `.vscode/c_cpp_properties.json:15`, `.vscode/launch.json:15-16` |
| Graphics | GLFW window, GLEW loader, OpenGL; shaders `#version 330 core`. Inference: the GPU driver must accept GLSL 3.30. | `src/main.cpp:2-3,44,52` |
| Editor | VS Code with the C/C++ extension (`cppdbg`) and Easy C++ Projects. | `.vscode/launch.json:6`, `.vscode/.easycpp` |
| Lab tooling runtime | Windows PowerShell; Python 3 with pytest and ruff 0.16.1. | `recipe.ps1:46-52`, `.claude/ruff.toml:2`, `.gitea/pull_request_template.md:16` |
| External systems | A Gitea server with Actions on Windows runners, its REST API and package registry; GitHub hosts this copy (`origin`) but has no workflows. Git LFS if installed. | `.gitea/workflows/*.yaml`, `.claude/hooks/git/pre-push:4-6` |

## 3. Functional requirements

### 3.1 Build (Makefile)

- **FR-1** The system shall compile with `g++` and the flags `-Wall -Wextra -std=c++20 -ggdb -fmodules-ts`. Source: `Makefile:1-2`. Verification: no test.
- **FR-2** The system shall compile every `module/*.cpp` into `bin/<name>.o`. Source: `Makefile:10-11,25-26`. Verification: no test.
- **FR-3** The system shall link all `src/*.cpp`, the module objects and every `include/*.hpp` into `bin/main`, with `-Iinclude` and `-Llib`. Source: `Makefile:13,18,31-32`. Verification: no test.
- **FR-4** The system shall link `-lbenchmark -lbenchmark_main -lgtest -lgtest_main -lsqlite3 -lGLEW32 -lglfw3 -lopengl32 -lpthread` into every build. Source: `Makefile:17,32`. Verification: no test.
- **FR-5** `make` (target `all`) shall build `bin/main`; `make run` shall build it and then execute `./bin/main`. Source: `Makefile:20-23`. Verification: no test.

### 3.2 Example program (src/main.cpp)

- **FR-6** The system shall initialise GLFW and, if that fails, print an error to stderr and return -1. Source: `src/main.cpp:7-10`. Verification: no test.
- **FR-7** The system shall create a 640 x 480 window titled "Привет, OpenGL"; if that fails it shall print an error, terminate GLFW and return -1. Source: `src/main.cpp:13-18`. Verification: no test.
- **FR-8** The system shall make the window's context current and initialise GLEW; if GLEW fails it shall print an error and return -1. Source: `src/main.cpp:21-27`. Verification: no test.
- **FR-9** The system shall upload the vertices (0, 0.5), (-0.5, -0.5), (0.5, -0.5) into a `GL_STATIC_DRAW` vertex buffer. Source: `src/main.cpp:30-40`. Verification: no test.
- **FR-10** The system shall compile a vertex shader that passes the 2D position through and a fragment shader that outputs (1, 0, 0, 1), link them into a program, print the info log to stderr on a compile or link failure and continue. Source: `src/main.cpp:42-91`. Verification: no test.
- **FR-11** Until the window is asked to close, the system shall clear the colour buffer, draw the triangle, swap buffers and poll events; then it shall terminate GLFW and return 0. Source: `src/main.cpp:94-115`. Verification: no test.

### 3.3 Editor integration (.vscode)

- **FR-12** The default build task "Build C++ project" shall run `make`; the default test task "Build & run C++ project" shall run `make run`. Source: `.vscode/tasks.json:4-24`. Verification: no test.
- **FR-13** The launch configuration "C++ Debug (gdb)" shall run the build task, then start `bin/main` under `gdb` in an external console with pretty-printing enabled. Source: `.vscode/launch.json:5-23`. Verification: no test.

### 3.4 Repository interface (recipe.ps1)

- **FR-14** The system shall accept exactly one verb from `build`, `install`, `uninstall`, `clean`, `run`, `publish`, `info`, `test` and reject any other. Source: `recipe.ps1:1-7`. Verification: no test.
- **FR-15** Before any verb, the system shall load `NAME=value` lines from `.claude/.env` into the environment, skip names already set, and strip surrounding quotes. Source: `recipe.ps1:28-38`. Verification: no test.
- **FR-16** `test` shall set `core.hooksPath` to `.claude/hooks/git`, run `python -m pytest .claude` (exit 0 or 5 pass), `python -m ruff check .claude`, `python -m ruff format .claude` in place, and exit 1 on the first failure, else 0. Source: `recipe.ps1:41-55`. Verification: no test (CI runs it: `propose.yaml:144-152`).
- **FR-17** `info` shall print `Name`, `Code`, `Version` and `Summary` and exit 0. Source: `recipe.ps1:56-62`. Verification: run by hand on 2026-11-18, output in docs/README.md.
- **FR-18** `clean` shall delete every `__pycache__`, `.pytest_cache` and `.ruff_cache` folder under the repository root. Source: `recipe.ps1:63-68`. Verification: no test.
- **FR-19** `build`, `install`, `uninstall`, `run` and `publish` shall print `nothing to <verb>` and exit 0. Source: `recipe.ps1:69-73`. Verification: `build` and `run` run by hand on 2026-11-18.

### 3.5 Git hooks (.claude/hooks/git)

- **FR-20** `commit-msg` shall refuse a message that starts with a UTF-8 byte-order mark. Source: `.claude/hooks/git/commit-msg.ps1:21-28`. Verification: no test.
- **FR-21** `commit-msg` shall refuse a subject that does not match `<type>(<scope>): <text>`, case-sensitive, with types and scopes read from `recipe.ps1`; a `Merge ...` subject passes only while `MERGE_HEAD` exists. Source: `.claude/hooks/git/commit-msg.ps1:7-19,32-47`, `recipe.ps1:19-20`. Verification: no test.
- **FR-22** `commit-msg` shall refuse a message without a `Signed-off-by: name <email>` trailer. Source: `.claude/hooks/git/commit-msg.ps1:48-53`. Verification: no test.
- **FR-23** `pre-push` shall run `git lfs pre-push` first when `git-lfs` is installed. Source: `.claude/hooks/git/pre-push:3-6`. Verification: no test.
- **FR-24** `pre-push` shall refuse a pushed branch whose name does not match `<code>-<issue>/<type>/<slug>` (code and types from `recipe.ps1`), except `test`, `from-*`, deletions and non-branch refs. Source: `.claude/hooks/git/pre-push.ps1:16-41,47-53,87-93`. Verification: no test.
- **FR-25** `pre-push` shall refuse deleting `release`, allow creating it, and refuse any other push to `release` unless one pushed first-parent commit not on `origin/test` carries `$OverridePhrase` alone on a line and a `Why:` line. Source: `.claude/hooks/git/pre-push.ps1:43-45,54-85`. Verification: no test.

### 3.6 Claude Code hooks (.claude)

- **FR-26** For every Bash or PowerShell tool call, the gate shall deny a recursive delete (`rm -r`, `Remove-Item -Recurse`, `rd /s`, `rimraf` and alike, also inside `bash -c`, `powershell -Command`, `cmd /c`, `xargs`) unless every path is under `$TEMP`. Source: `.claude/settings.json:10-12`, `.claude/hooks/gate.ps1:84-119,138-154`. Verification: no test.
- **FR-27** The gate shall deny `git push` with `--force`, `-f`, `--mirror` or a `+refspec`, and allow `--force-with-lease`. Source: `.claude/hooks/gate.ps1:155-163`. Verification: no test.
- **FR-28** On the branches `test` and `release`, the gate shall deny `reset --hard` (except to `origin/<branch>` or `@{u}`), `clean -f`, `commit --amend`, `rebase` and `filter-branch`. Source: `.claude/hooks/gate.ps1:121-129,164-177`. Verification: no test.
- **FR-29** The gate shall deny a PreToolUse call whose payload is empty, not JSON, or has no tool name. Source: `.claude/hooks/gate.ps1:2-4,34-36`. Verification: no test.
- **FR-30** The hooks shall append one JSON line per event (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Notification, SubagentStop, PreCompact, Stop, SessionEnd) to `.claude/logs/ai.jsonl`. Source: `.claude/settings.json:7-19`, `.claude/hooks/log.ps1:2-24`, `.claude/hooks/gate.ps1:6-23`, `.claude/hooks/session-start-stop.ps1:8-23`. Verification: no test.
- **FR-31** At SessionStart the system shall move `ai.jsonl` aside when it exceeds 10 MB, set `core.hooksPath`, warn on stderr when `recipe.ps1` is missing, and return context naming the branch and the issue number parsed from it. Source: `.claude/hooks/session-start-stop.ps1:26-48`. Verification: no test.

### 3.7 CI workflows (.gitea/workflows)

- **FR-32** `propose` shall, on a pull request into `test` (opened, reopened, synchronize), check the branch name, check each new non-merge commit for subject format and `Signed-off-by`, run `.\recipe.ps1 test` and `git diff --exit-code`, and on open/reopen request review from `$Reviewers` other than the poster and post a comment. Source: `.gitea/workflows/propose.yaml:1-193`. Verification: no test.
- **FR-33** `test` shall, on push to `test`, daily by cron `0 3 * * *` and on manual dispatch, check runner health, run `.\recipe.ps1 test` with a diff check and `.\recipe.ps1 build`; the install/uninstall proof runs only when `$App` is set, and wiki generation only when `$App` or `$Provides` is set. Source: `.gitea/workflows/test.yaml:1-120`. Verification: no test.
- **FR-34** `release-gate` shall, on a pull request into `release`, refuse a head branch other than `test`, run the recipe test, diff check and build, and then run the manual round from `tests/manual/tests.json`; an absent or empty list sets `manual/verdict` to success. Source: `.gitea/workflows/release-gate.yaml:27-150`. Verification: no test.
- **FR-35** `release` shall, on push to `release`, read `$Version`; unless tag `v<version>` already exists, build, write release notes, create Gitea release `v<version>` with a manual-test report and an SBOM, and close the shipped issues; on every push, also when the tag exists, record overrides and merge `release` back into `test` (opening an issue "test is behind release" when that fails). Source: `.gitea/workflows/release.yaml:38-401`. Verification: no test.
- **FR-36** `sweep` shall, every Monday by cron `0 4 * * 1`, delete remote work branches already merged into `test`, comment on pull requests idle for 30 days and close those idle for 60. Source: `.gitea/workflows/sweep.yaml:1-80`. Verification: no test.

### 3.8 Declared but not implemented

| Item | Where declared | State in code |
|---|---|---|
| Qt 5 build | `Makefile:15-16` (comment); Qt Charts example in the 2023 README (`git show 7bd1988:README.md`, section "Qt graph") | No Qt flag in `LIBRARIES`; no Qt source. |
| Boost uBLAS, Google Benchmark, Google Test, SQLite examples | 2023 README at `7bd1988` | Removed from the README (`README.md:23-26`); no source uses them; three of the libraries are still linked (`Makefile:17`). |
| `include/`, `lib/`, `module/`, `bin/` folders | `Makefile:4-8` | Not in the repository (`README.md:20-21`). |
| Verbs `build`, `install`, `uninstall`, `run`, `publish` | `recipe.ps1:3` | Print `nothing to <verb>` (`recipe.ps1:69-73`); `build` does not call `make`. |
| Installer, wiki, manual tests, changelog | `release-gate.yaml:60-74,107-150`, `test.yaml:61-110`, `release.yaml:402-423` | No `dist/`, `tools/wiki.py`, `tests/manual/` or `CHANGELOG.md` in the repository; the steps are skipped or take the empty path. |
| Lab requirement exceptions R-02, R-09, R-37, R-41, R-42 | `README.md`, section "Lab requirements" (issues #7 to #11) | Open; the requirement texts are on a server outside the repository. |
| Branch protection stage 2 | `CLAUDE.md:68-70` | Server setting; not visible in the repository. |

## 4. Interfaces

### 4.1 Make targets

| Target | Prerequisites | Action | Source |
|---|---|---|---|
| `all` (default) | `bin/main` | none | `Makefile:20` |
| `run` | `all` | `./bin/main` | `Makefile:22-23` |
| `bin/%.o` | `module/%.cpp` | `g++ $(CXX_FLAGS) -c` | `Makefile:25-26` |
| `bin/%.o` | `include/%.hpp` | `g++ $(CXX_FLAGS) -c` | `Makefile:28-29` |
| `bin/main` | `src/*.cpp`, module objects, headers | link with `$(LIBRARIES)` | `Makefile:31-32` |

### 4.2 Example program

| Aspect | Value | Source |
|---|---|---|
| Arguments, env, files | none | `src/main.cpp:5` |
| Window | 640 x 480, title "Привет, OpenGL" | `src/main.cpp:13` |
| stderr messages (Russian) | GLFW init, window, GLEW init, vertex/fragment shader compile, program link | `src/main.cpp:8,15,25,69,79,90` |
| Exit codes | 0 after the window closes; -1 on GLFW, window or GLEW failure | `src/main.cpp:9,17,26,115` |

### 4.3 recipe.ps1

| Verb | Effect | Exit | Source |
|---|---|---|---|
| `test` | hooks path, pytest, ruff check, ruff format | 0 or 1 | `recipe.ps1:41-55` |
| `info` | four metadata lines | 0 | `recipe.ps1:56-62` |
| `clean` | deletes cache folders | 0 | `recipe.ps1:63-68` |
| `build`, `install`, `uninstall`, `run`, `publish` | `nothing to <verb>` | 0 | `recipe.ps1:69-73` |

### 4.4 Hooks

| Hook | Trigger | Script | Blocks |
|---|---|---|---|
| Git `commit-msg` | `git commit` | `.claude/hooks/git/commit-msg` -> `commit-msg.ps1` | yes, exit 1 |
| Git `pre-push` | `git push` | `.claude/hooks/git/pre-push` -> `pre-push.ps1` | yes, exit 1 |
| Claude Code PreToolUse (Bash, PowerShell) | each tool call | `.claude/hooks/gate.ps1` | yes, `permissionDecision: deny` |
| Claude Code SessionStart, Stop, SessionEnd | session events | `.claude/hooks/session-start-stop.ps1` | no |
| Claude Code UserPromptSubmit, PostToolUse, Notification, SubagentStop, PreCompact | events | `.claude/hooks/log.ps1` | no |

Source: `.claude/settings.json:7-19`.

### 4.5 Workflows

| Workflow | Trigger | Jobs | Timeout |
|---|---|---|---|
| `propose` | PR into `test` | `gate` | 60 min |
| `test` | push to `test`, cron `0 3 * * *`, manual | `prove` | 60 min |
| `release-gate` | PR into `release` | `checks`, `manual-gate` | 60 min, 170 min |
| `release` | push to `release` | `publish` | 60 min |
| `sweep` | cron `0 4 * * 1` | `sweep` | 15 min |

Source: the `on:`, `jobs:` and `timeout-minutes:` lines of each file in `.gitea/workflows/`.

## 5. Data

- The example program keeps its data in memory: a 6-float vertex array, one
  vertex buffer, one shader program (`src/main.cpp:30-40,83-86`). It stores nothing.
- `.claude/logs/ai.jsonl`: one JSON object per line, UTF-8 without BOM, fields
  `ts`, `event`, `session`, `tool`, `decision` (gate only), `detail` (from `log.ps1`:
  first 200 characters of `prompt`, `message`, `reason`, `source` or `file_path`;
  from `session-start-stop.ps1`: branch, issue and hooks state, `turn finished`, or
  the session-end reason, lines 43, 50, 53). Rotated to
  `ai.jsonl.<yyyyMMddHHmmss>.bak` above 10 MB. Gitignored. Source:
  `.claude/hooks/log.ps1:4-18`, `.claude/hooks/session-start-stop.ps1:27-30`, `.gitignore:17`.
- `.claude/.env`: `NAME=value` lines, optional quotes. Gitignored, not in any
  commit by rule. Source: `recipe.ps1:30-37`, `.gitignore:20-24`, `CLAUDE.md:20-24`.
- `recipe.ps1` metadata is read as text by hooks and workflows with regular
  expressions; each list must be a literal on one line. Source:
  `.gitea/workflows/propose.yaml:55-59,157-166`, `.claude/hooks/git/pre-push.ps1:25-31`.
- `tests/manual/tests.json` (expected by `release-gate`, absent): an object with a
  `tests` array; each item has an `id` matching `^[a-z0-9][a-z0-9_-]{0,60}$`, not
  `verdict`, unique, and an optional boolean `blocking`. Source:
  `.gitea/workflows/release-gate.yaml:110-135`.
- Release files written by `release.yaml`: `release-body.md` (the release body,
  not an attachment), and the attached assets `manual-report.md` and
  `sbom.md` (the `$Needs`, `$Tools`, `$Version` lines of `recipe.ps1`). Source:
  `.gitea/workflows/release.yaml:120-124,279-337`.

## 6. Non-functional requirements

- **NFR-1** Every compile uses `-Wall -Wextra` and debug info `-ggdb`. Source: `Makefile:2`.
- **NFR-2** The build targets Windows with MSYS2 MinGW: `-lGLEW32`, `-lopengl32`, IDE paths under `C:\msys64\mingw64`. Source: `Makefile:17`, `.vscode/c_cpp_properties.json:7,15`.
- **NFR-3** Keys are not committed: `.claude/.env` is gitignored, and variables already set in the environment override the file. Source: `.gitignore:20-24`, `recipe.ps1:28-36`, `CLAUDE.md:20-24`.
- **NFR-4** ruff must be version 0.16.1; another version refuses to run. Source: `.claude/ruff.toml:1-2`.
- **NFR-5** CI fails when `.\recipe.ps1 test` leaves the tree changed. Source: `propose.yaml:148-152`, `test.yaml:58`, `release-gate.yaml:53`.
- **NFR-6** Runner health: fail below 5 GB free on `C:`, warn below 20 GB; `python`, `ruff`, `pytest`, `mypy` must answer. Source: `test.yaml:34-45`.
- **NFR-7** Concurrency: jobs in group `installer-<repo>` and `release-<repo>` are never cancelled; `release-gate` cancels the previous run of the same PR. Source: `test.yaml:18-20`, `release-gate.yaml:7-9,20-22`, `release.yaml:15-17`.
- **NFR-8** Manual-gate waits up to 150 minutes for results. Source: `release-gate.yaml:91,101`.
- **NFR-9** Log appends retry up to 20 times with waits of 10, 20, ... ms on a file-in-use error; logging hooks swallow errors and exit 0. Source: `.claude/hooks/log.ps1:20-26`.
- **NFR-10** The gate fails closed: an unreadable tool call is denied. Source: `.claude/hooks/gate.ps1:34-36`.
- **NFR-11** Line endings: LF by default; CRLF and UTF-8 working-tree encoding for `*.ps1`; LF for the two sh hooks; PDF, PNG, JPG, ZIP, 7z go to Git LFS. Source: `.gitattributes:1-13`.
- **NFR-12** Workflows run on Windows runners with the `powershell` shell; new PowerShell must parse in 5.1 and have no BOM. Source: `runs-on`/`shell` lines of `.gitea/workflows/*.yaml`, `.gitea/pull_request_template.md:16-17`.

## 7. Constraints and dependencies

There are no lock files and no pinned versions except ruff and the major versions
of the two actions the workflows use.

| Dependency | Version | Used by | Source |
|---|---|---|---|
| g++ with `-std=c++20 -fmodules-ts` | not pinned | build | `Makefile:1-2` |
| GNU make | not pinned | build | `Makefile`, `.vscode/tasks.json:11` |
| GLFW 3, GLEW, OpenGL | not pinned | `src/main.cpp` | `Makefile:17`, `src/main.cpp:2-3` |
| Google Benchmark, Google Test, SQLite 3, pthread | not pinned | linked, unused | `Makefile:17` |
| gdb | not pinned | debugging | `.vscode/launch.json:15-16` |
| Python 3, pytest | not pinned | `recipe.ps1 test` | `recipe.ps1:46`, `.claude/pytest.ini` |
| ruff | 0.16.1 | `recipe.ps1 test` | `.claude/ruff.toml:2` |
| Windows PowerShell 5.1 | 5.1 | recipe, hooks, workflows | `.gitea/pull_request_template.md:16` |
| Git, Git LFS (optional) | not pinned | hooks | `.claude/hooks/git/pre-push:4-6` |
| `actions/checkout` | v4 | workflows | e.g. `propose.yaml:27` |
| `actions/upload-artifact` | v3 | `release-gate` | `release-gate.yaml:442` |
| Gitea Actions, secret `LAB_BOT_TOKEN` | not stated | workflows | `.gitea/workflows/*.yaml` |

Licence: MIT (`LICENSE`).

## 8. Acceptance

Automated, as CI does it (not run for this document):

1. `.\recipe.ps1 test` exits 0, then `git diff --exit-code` exits 0
   (`propose.yaml:144-152`). Today pytest collects no tests (exit 5, accepted).

Manual checks:

2. `.\recipe.ps1 info` prints the four lines `Name`, `Code`, `Version`, `Summary`
   (FR-17; done on 2026-11-18).
3. `.\recipe.ps1 build` prints `nothing to build` and exits 0 (FR-19; done).
4. On Windows with MSYS2 and the libraries of `Makefile:17`, with `bin/` present:
   `make` produces the executable, `make run` shows a 640 x 480 window with a red
   triangle, and closing it ends with exit code 0 (FR-5 to FR-11; not done).
5. A commit with subject `Fix: x` or without `-s` is refused by `commit-msg`;
   a push of a branch named `my-branch` is refused by `pre-push` (FR-21, FR-22,
   FR-24; not done).
6. In a Claude Code session, `rm -rf build` is denied and
   `git push --force-with-lease` is allowed by the gate (FR-26, FR-27; not done).

## 9. Open questions

1. Who uses the template besides the owner, and is it still used for new
   projects? Nothing in the repository says.
2. Which g++, MSYS2 and library versions was it last built with? Nothing is pinned.
3. Does the link succeed with `-lgtest_main` and `-lbenchmark_main`, which each
   provide a `main()`, next to `src/main.cpp`'s `main()`? Not built here.
4. What does g++ do with the `include/*.hpp` files that `$^` puts on the link
   line (`Makefile:31-32`)? Not tested.
5. Was the `module/` path (C++20 modules with `-fmodules-ts`) ever used? No
   `module/` folder appears in any commit (`git log --all --name-only` lists none).
6. Why does IntelliSense use `c++23` while the build uses `c++20`?
7. What do lab requirements R-02, R-09, R-37, R-41 and R-42 require, and what
   is the state of issues #7 to #11? The texts are on the owner's Gitea server.
8. Which repository is the source of truth: the Gitea one the workflows serve, or
   this GitHub copy? GitHub branches are `main`, `master`, `test`, `release`;
   `origin/HEAD` is `release`. Partial answer, an inference: `README.md:33-36,47`
   speak of GitHub as where `master` and the licence came from and keep the old
   `master` "here" as a tag, and `CLAUDE.md:27-29` names "this repository's Gitea
   pages", which reads as the Gitea copy being the working one. Nothing states it.
9. Has branch protection reached stage 2 (`CLAUDE.md:68-70`)? Server state.
10. Was tag `v1.0.0` (at `44d63d7`) created by the `release` workflow? The tag
    exists; the run that made it is not visible here. Partial answer: it is a
    lightweight tag (`git cat-file -t v1.0.0` prints `commit`) on the commit that
    was pushed to `release`, as a tag made by the Gitea release call
    (`release.yaml:290-293`, `target_commitish` = the pushed SHA) would be; a tag
    made by hand with `git tag` would look the same, so this does not prove it.
