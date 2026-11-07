# cpp-modern-template

A C++20 starting point from August and September 2023: a `Makefile` for g++ under
MSYS2 MinGW, the Visual Studio Code settings the Easy C++ Projects extension
writes, and one example program. It is a template to copy from, not a program.

## What is here

- `Makefile` compiles every `src/*.cpp` with `-std=c++20 -fmodules-ts`, plus any
  `module/*.cpp`, into `bin/main`, with `include/` and `lib/` as the header and
  library folders. `make run` builds and starts it. It links Google Benchmark,
  Google Test, SQLite, GLEW, GLFW and OpenGL into every build; `-lGLEW32` and
  `-lopengl32` are the MinGW names, so it links on Windows only. A comment lists
  the Qt 5 libraries to add for Qt.
- `src/main.cpp` is the example: it opens a 640 by 480 GLFW window and draws a
  red triangle with a minimal vertex and fragment shader until the window is
  closed. Its comments and messages are in Russian.
- `.vscode/` holds the build task (`make`), the run task (`make run`) and the
  debugger settings.
- `bin/`, `include/`, `lib/` and `module/` are not in the repository; the
  `Makefile` expects `bin/` to exist.

The old README was a set of example snippets, with the `pacman` and `apt-get`
lines that install the libraries: Boost uBLAS and a trapezoidal integral, Google
Benchmark, Google Test, SQLite, the same OpenGL triangle, and a Qt Charts sine
plot. This one replaces it; the snippets are in the history at commit `7bd1988`.

Nothing here is built or tested in this lab: the runner has neither the libraries
nor a display for the window.

## Kept as a tag

`master` on GitHub shares no history with `main`: `git merge-base` finds no
common ancestor. Its one commit, "version 1.0", holds the same files as `main` at
commit `2b865cb` without `.gitignore`. It is kept here as the tag
`import/master`.

## Working on it

This repository ships no program. `.\recipe.ps1` is still its whole interface:
`.\recipe.ps1 test` runs pytest and ruff over `.claude`, and `.\recipe.ps1 info`
prints the metadata. The other verbs print `nothing to <verb>`. `CLAUDE.md`
holds the rules.

## License

MIT, as it stood on GitHub. See [LICENSE](LICENSE).

## Lab requirements

This repository complies with [revision 4.0.0](http://127.0.0.1:3000/igors-lab/software-requirements/src/tag/v4.0.0/BEST_REQUIREMENTS.md) of the lab requirements, except R-02 (#7), R-09 (#8), R-37 (#9), R-41 (#10), R-42 (#11).
