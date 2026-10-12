-- scratch: named scratch programs, each toggled by a key of its own.
--
-- pyprland's named scratchpads for ranma. In init.lua (or hako's `config`):
--
--   require("scratch").setup {
--     { name = "git", argv = { "lazygit" }, key = "g" },
--     { name = "top", cmd = "btop", key = "t", width = 90, height = 85 },
--     { name = "calc", argv = { "python3", "-q" }, key = "c", width = 50, height = 40 },
--   }
--
-- leader Z (shift+z) opens the scratch folder; a spec's key toggles it:
--   first press   start it, in a float centred over this workspace
--   pressed again hide it, still running (focused), or focus it (shown)
--   hidden        bring it back over the workspace you are on (a program
--                 started in another session takes you to that session)
--   ended         start it again (or respawn its pane, under remain_on_exit)
-- The palette's `scratch NAME` does the same, completing the names.
--
-- A spec: name (required), argv (a list of words) or cmd (a shell line), and
-- optionally key, width and height (percent of the workspace), cwd and desc.
-- setup's second argument: { folder = "shift+z" }, or folder = false to bind each
-- spec's key at WM mode's top level instead.
--
-- Hidden programs are parked on a workspace of their own (scratch.workspace,
-- 99 unless set), not in ranma's scratchpad, which stays yours. Each program's
-- pane id is kept in ranma.store("scratch"), so a config reload finds it again;
-- the pane is named after its spec, which is how a stale id is told apart.
-- Options (settings panel, "scratch" group): scratch.workspace, scratch.width,
-- scratch.height.
--
-- ranma's plugin API: https://github.com/masshirodev/ranma/blob/main/doc/CONFIG.md ("Plugins", "Pane
-- handles", "Hooks", "Commands").

ranma.option("scratch.workspace", {
  type = "int", min = 11, max = 99, default = 99, slider = false,
  name = "Parking workspace", desc = "Where hidden scratch programs wait, still running.",
})
ranma.option("scratch.width", {
  type = "int", min = 10, max = 100, step = 5, default = 80,
  name = "Width", desc = "A scratch program's width, in percent, unless its spec says.",
})
ranma.option("scratch.height", {
  type = "int", min = 10, max = 100, step = 5, default = 70,
  name = "Height", desc = "A scratch program's height, in percent, unless its spec says.",
})
