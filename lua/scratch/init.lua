-- scratch's module: setup() and the toggle. plugin/scratch.lua is the reference.

local M = {}

local FIELDS = { name = true, argv = true, cmd = true, key = true, width = true,
                 height = true, cwd = true, desc = true }

local store = ranma.store("scratch")
local specs, names = {}, {}
-- The spec whose pane the next pane_open is: exec opens it after the bind
-- returns, so the id only arrives in the hook.
local pending = nil
-- The workspace last shown in each session, other than the parking one: where
-- a program comes back to while the scratchpad (workspace 0) is up.
local here = {}

local function quote(s)
  return "'" .. s:gsub("'", [['\'']]) .. "'"
end

local function expand(path)
  if path:sub(1, 2) == "~/" then return os.getenv("HOME") .. path:sub(2) end
  return path
end

-- The command line exec runs. RANMA_SCRATCH tells the program (and a curious
-- user) which scratch it is.
local function line(spec)
  local run
  if spec.argv then
    local words = {}
    for i, w in ipairs(spec.argv) do words[i] = quote(w) end
    run = "exec " .. table.concat(words, " ")
  else
    run = spec.cmd
  end
  local l = "RANMA_SCRATCH=" .. quote(spec.name) .. "; export RANMA_SCRATCH; " .. run
  if spec.cwd then l = "cd " .. quote(expand(spec.cwd)) .. " && " .. l end
  return l
end

local function check(spec, i)
  if type(spec) ~= "table" then error(("scratch: spec %d is not a table"):format(i), 3) end
  for k in pairs(spec) do
    if not FIELDS[k] then error(("scratch: spec %d has an unknown field %q"):format(i, tostring(k)), 3) end
  end
  local name = spec.name
  if type(name) ~= "string" or not name:match("^[%w_.-]+$") then
    error(("scratch: spec %d needs a name of letters, digits, _ . -"):format(i), 3)
  end
  if specs[name] then error(("scratch: %q is named twice"):format(name), 3) end
  if (spec.argv == nil) == (spec.cmd == nil) then
    error(("scratch: %q needs argv or cmd, not both"):format(name), 3)
  end
  if spec.argv ~= nil and (type(spec.argv) ~= "table" or #spec.argv == 0) then
    error(("scratch: %q: argv is a list of words"):format(name), 3)
  end
  if spec.cmd ~= nil and (type(spec.cmd) ~= "string" or spec.cmd == "") then
    error(("scratch: %q: cmd is a shell command line"):format(name), 3)
  end
  for _, k in ipairs { "width", "height" } do
    local v = spec[k]
    if v ~= nil and (math.type(v) ~= "integer" or v < 10 or v > 100) then
      error(("scratch: %q: %s is a percent, 10-100"):format(name, k), 3)
    end
  end
  for _, k in ipairs { "key", "cwd", "desc" } do
    if spec[k] ~= nil and type(spec[k]) ~= "string" then
      error(("scratch: %q: %s is a string"):format(name, k), 3)
    end
  end
end

-- The program's pane, if it still runs: the id kept, and the pane by it
-- still named after the spec (an id from before a restart may be anybody's).
local function find(name)
  local id = store:get(name)
  local p = id and ranma.pane(id)
  if p and p.title == name then return p end
  if id then store:set(name, nil) end
  return nil
end

local function size(spec)
  return spec.width or ranma.get("scratch.width"), spec.height or ranma.get("scratch.height")
end

-- Float the focused pane at the spec's size, centred.
local function place(spec)
  local w, h = size(spec)
  ranma.action(("float_size %d %d"):format(w, h))
  ranma.action("snap center")
end

local function start(spec, st)
  if st.workspace == 0 then ranma.action("scratchpad_toggle") end
  pending = spec.name
  ranma.defer(3000, function()
    if pending == spec.name then pending = nil end
  end)
  ranma.action("exec " .. line(spec))
end

local function show(spec, p, st, ended)
  local park = ranma.get("scratch.workspace")
  local ws = st.workspace
  if p.session ~= st.session or ws == 0 or ws == park then
    ws = here[p.session] or 1
  end
  if st.workspace == 0 then ranma.action("scratchpad_toggle") end
  p:focus()
  ranma.action("move_to_workspace " .. ws)
  place(spec)
  if ended then ranma.action("respawn_pane") end
end

function M.toggle(name)
  local spec = specs[name]
  if not spec then return ranma.notify("scratch: no scratch named " .. tostring(name)) end
  local st = ranma.state()
  local p = find(name)
  if not p then return start(spec, st) end
  -- A pane that stayed after its program ended (remain_on_exit) has nothing
  -- in its foreground: the press runs it again rather than hiding it.
  local ended = p:program() == nil
  if p.visible and ended then
    p:focus()
    ranma.action("respawn_pane")
  elseif p.visible and st.focused == p.id then
    ranma.action("move_to_workspace_silent " .. ranma.get("scratch.workspace"))
  elseif p.visible then
    p:focus()
  else
    show(spec, p, st, ended)
  end
end

local function on_open(ev)
  local name = pending
  if not name then return end
  pending = nil
  local p = ranma.pane(ev.pane)
  if not p then return end
  store:set(name, ev.pane)
  p:rename(name)
  p:focus()
  place(specs[name])
end

local function on_close(ev)
  for _, name in ipairs(names) do
    if store:get(name) == ev.pane then store:set(name, nil) end
  end
end

local function on_workspace(ev)
  local ws = ev.workspace
  if ws and ws ~= 0 and ws ~= ranma.get("scratch.workspace") then
    here[ranma.state().session] = ws
  end
end

-- setup(specs, opts): declare the programs, bind their keys, and listen for
-- their panes. Call it once, while the configuration loads.
function M.setup(list, opts)
  opts = opts or {}
  for k in pairs(opts) do
    if k ~= "folder" then error(("scratch: setup has no option %q"):format(tostring(k)), 2) end
  end
  if type(list) ~= "table" then error("scratch: setup takes a list of specs", 2) end
  if next(names) then error("scratch: setup was called twice", 2) end
  for i, spec in ipairs(list) do
    check(spec, i)
    specs[spec.name] = spec
    names[#names + 1] = spec.name
  end
  local folder = opts.folder
  if folder == nil then folder = "shift+z" end
  if folder ~= false and type(folder) ~= "string" then
    error("scratch: folder is a key, or false", 2)
  end

  local bound = false
  for _, name in ipairs(names) do
    local spec = specs[name]
    if spec.key then
      local key = folder and (folder .. " " .. spec.key) or spec.key
      ranma.bind(key, function() M.toggle(name) end,
        { desc = spec.desc or name, exit = true, group = (not folder) and "scratch" or nil })
      bound = true
    end
  end
  -- An empty folder is an error at load, so it is only made with keys in it.
  if folder and bound then ranma.bind(folder, { folder = "scratch", group = "plugins" }) end

  if #names > 0 then
    ranma.command("scratch", function(arg)
      if not arg or arg == "" then return ranma.notify("scratch: name one: " .. table.concat(names, ", ")) end
      M.toggle(arg)
    end, { desc = "toggle a scratch program", args = "<name>", complete = names })
  end

  ranma.on("pane_open", on_open)
  ranma.on("pane_close", on_close)
  ranma.on("workspace_change", on_workspace)
end

return M
