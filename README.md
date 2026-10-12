# scratch.ranma

A plugin for [ranma](https://github.com/masshirodev/ranma), the terminal tiling window manager: named scratch programs, each toggled by a key of its own. pyprland's named scratchpads, on top of ranma's one scratchpad.

## Install

With [hako](https://github.com/masshirodev/hako.ranma), in `~/.config/ranma/lua/plugins/scratch.lua`:

```lua
return {
  "masshirodev/scratch.ranma",
  config = function()
    require("scratch").setup {
      { name = "git", argv = { "lazygit" }, key = "g" },
      { name = "top", cmd = "btop", key = "t", width = 90, height = 85 },
      { name = "calc", argv = { "python3", "-q" }, key = "c", width = 50, height = 40 },
    }
  end,
}
```

Or by hand, as ranma loads any package under `pack/*/start/`:

```sh
git clone https://github.com/masshirodev/scratch.ranma ~/.config/ranma/pack/plugins/start/scratch.ranma
```

and call `require("scratch").setup { ... }` in `init.lua`. Without a call to `setup` the plugin declares its options and does nothing else.

Needs: Nothing beyond ranma.

## What it does

```text
pyprland's named scratchpads for ranma. In init.lua (or hako's `config`):

  require("scratch").setup {
    { name = "git", argv = { "lazygit" }, key = "g" },
    { name = "top", cmd = "btop", key = "t", width = 90, height = 85 },
    { name = "calc", argv = { "python3", "-q" }, key = "c", width = 50, height = 40 },
  }

leader z opens the scratch folder; each spec's key toggles its program:
  first press   start it, in a float centred over this workspace
  pressed again hide it, still running (focused), or focus it (shown)
  hidden        bring it back over the workspace you are on (a program
                started in another session takes you to that session)
  ended         start it again (or respawn its pane, under remain_on_exit)
The palette's `scratch NAME` does the same, completing the names.

A spec: name (required), argv (a list of words) or cmd (a shell line), and
optionally key, width and height (percent of the workspace), cwd and desc.
setup's second argument: { folder = "z" }, or folder = false to bind each
spec's key at WM mode's top level instead.

Hidden programs are parked on a workspace of their own (scratch.workspace,
99 unless set), not in ranma's scratchpad, which stays yours. Each program's
pane id is kept in ranma.store("scratch"), so a config reload finds it again;
the pane is named after its spec, which is how a stale id is told apart.
Options (settings panel, "scratch" group): scratch.workspace, scratch.width,
scratch.height.
```

### Specs

| Field | | |
| --- | --- | --- |
| `name` | required | Letters, digits, `_`, `.` and `-`. The pane is renamed to it, and it is the palette command's argument. |
| `argv` | this or `cmd` | A list of words, run as they are (`{ "lazygit" }`). |
| `cmd` | this or `argv` | A shell command line (`"btop --utf-force"`). |
| `key` | optional | The key behind the folder (`leader z g`). Without one, the program is only reached from the palette. |
| `width`, `height` | optional | Percent of the workspace, 10 to 100. Default: the `scratch.width` and `scratch.height` options. |
| `cwd` | optional | The directory it starts in (`~/` is your home). Default: the focused pane's. |
| `desc` | optional | What the which-key hint calls it. Default: its name. |

The program sees `RANMA_SCRATCH=<name>` in its environment. An unknown field, a duplicate name, or both or neither of `argv` and `cmd` is an error where `setup` was called.

`setup(specs, { folder = "z" })` picks the folder's key. `folder = false` binds each spec's key at WM mode's top level instead, under a `scratch` heading in the hint; mind that those keys then replace any of ranma's defaults they share.

### Binds and commands

| Key / command | Does |
| --- | --- |
| `leader z` | The `+scratch` folder (in the `plugins` group), made only when a spec has a key. |
| `leader z <key>` | Toggle that spec's program, as above. |
| `:scratch <name>` | The same from the palette (`leader :`), completing the names. |

## How a hidden program is kept

ranma 0.1.0 offers three places a program could wait while hidden. This plugin parks it on a workspace of its own.

- **`ranma popup`** is out. It is a blocking command for scripts: it waits for the program to end and closes the float when it does, and a bind cannot run it, since it would wait on the very ranma it asks. There is no way to hide a popup and show it again with its process alive.
- **ranma's scratchpad** (`move_to_scratchpad`, `scratchpad_toggle`) keeps a process alive, but it is one layer for every pane in it: showing one named program there would show every other one, and your own scratchpad panes with them. Using it would break the one guarantee this plugin wants, that `alt+s` stays yours.
- **A parking workspace** (`move_to_workspace_silent 99`) keeps the process running, hides that one pane alone, and leaves the scratchpad untouched. Showing it again is `move_to_workspace` back to where you are, then `float_size` and `snap center`. This is what scratch does.

The cost is that the parking workspace is a real workspace. While anything is parked, the bar and the workspace switcher list it (`99:lazygit`), and `workspace 99` goes there. `workspace next` and `prev` wrap within 1 to 10, so they never land on it. Pick another number with `scratch.workspace` if 99 is yours. Each session parks on its own workspace 99, and a program stays in the session it was started in.

Each program's pane id is kept in `ranma.store("scratch")`, so a config reload, which starts Lua over, still finds it. A stored id is trusted only while the pane by that id is still named after its spec, so an id left over from a restarted server never toggles somebody else's pane.

## Options

In ranma's settings panel under `scratch`, or `ranma.set { scratch = { ... } }`. hako's `opts` would set them too, but the `config` function that calls `setup` replaces that, so set them inside it: `ranma.set { scratch = { workspace = 90 } }` before `setup`.

| Option | Default | |
| --- | --- | --- |
| `scratch.workspace` | `99` | Where hidden scratch programs wait, still running (11 to 99). |
| `scratch.width` | `80` | A scratch program's width, in percent, unless its spec says. |
| `scratch.height` | `70` | A scratch program's height, in percent, unless its spec says. |

## License

MIT or Apache-2.0, as ranma.
