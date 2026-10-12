# AGENTS.md

scratch.ranma is a ranma plugin in Lua: `plugin/scratch.lua` declares the
options and carries the header comment that is the reference `README.md`
repeats; `lua/scratch/init.lua` is the module, `setup()` and the toggle.
ranma's API is https://github.com/masshirodev/ranma/blob/main/doc/CONFIG.md
(`ranma --dump-types` prints it as LuaLS annotations).

- Push to `main`.
- A change to what it does changes the header comment and `README.md` in the
  same commit, and an option goes in the README's table. Why a hidden program
  sits on a parking workspace, not in a popup or ranma's scratchpad, is in the
  README ("How a hidden program is kept"); revisit it when ranma can hide a
  single pane.
- Only use API the latest ranma release has: CI loads the plugin into it.
- Check it loads: `ranma --check-config` lists every plugin and why one failed;
  `ranma lua` runs code in the live server.
  CI (`.github/workflows/ci.yml`) loads it into the latest ranma release on
  every push and fails if it does not.
- Test behaviour in a private ranma server (its own `RANMA_CONFIG_DIR` and XDG
  directories, `RANMA_SOCKET RANMA RANMA_PANE TMUX` unset), never the one your
  terminal runs in: this checkout is watched by any server that packadds it.
- `AGENTS.local.md` (gitignored) carries what is true of one checkout on one
  machine. Never commit it.
