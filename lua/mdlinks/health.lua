---@module 'mdlinks.health'
--- :checkhealth mdlinks
--- Structured checks: Environment -> Config -> Openers -> Keymaps -> Parser self-test

local M = {}

-- Compatibility wrapper: works on 0.9 (report_*) and 0.10+ (start/ok/...)
local H = (function()
  local health = vim.health or require("vim.health")
  local ok = health.ok or health.report_ok
  local info = health.info or health.report_info
  local warn = health.warn or health.report_warn
  local err = health.error or health.report_error
  local start = health.start or health.report_start
  return { ok = ok, info = info, warn = warn, err = err, start = start }
end)()

local function get_cfg()
  local ok, mod = pcall(require, "mdlinks.config")
  if not ok or type(mod.options) ~= "function" then
    return nil, "mdlinks.config not available"
  end
  local cfg = mod.options()
  if type(cfg) ~= "table" then
    return nil, "invalid config table"
  end
  return cfg, nil
end

---@param argv string[]|nil
---@return boolean,string
local function check_argv(argv)
  if type(argv) ~= "table" or #argv == 0 then
    return false, "not set / empty"
  end
  for i, v in ipairs(argv) do
    if type(v) ~= "string" then
      return false, ("argv[%d] is %s, expected string"):format(i, type(v))
    end
  end
  return true, "ok"
end

---@param exe string
---@return boolean
local function is_executable(exe)
  -- `cmd.exe` and `powershell.exe` usually resolve fine; still use `executable()`
  return vim.fn.executable(exe) == 1
end

---@param argv string[]
---@return boolean,string
local function check_opener(argv)
  local ok, why = check_argv(argv)
  if not ok then return false, why end
  local exe = argv[1]
  if not is_executable(exe) then
    return false, ("executable not found in $PATH: %q"):format(exe)
  end
  return true, ("found %q"):format(exe)
end

---@param key string|nil
---@return boolean,string
local function check_keymap_installed(key)
  if not key or key == "" then
    return true, "no keymap requested (ok)"
  end
  -- maparg(..., { dict = 1 }) → table on success, empty dict on missing
  local m = vim.fn.maparg(key, "n", false, true)
  if type(m) == "table" and (m.lhs or m.rhs) then
    return true, ("mapped %q → %s"):format(key, m.rhs or "<function>")
  end
  return false, ("not mapped: %q (plugin not initialized yet? lazy loading?)"):format(key)
end

local function section_environment()
  H.start("Environment")
  local nv = vim.version()
  local vstr = ("%d.%d.%d"):format(nv.major, nv.minor, nv.patch)
  if nv.major > 0 or nv.minor >= 9 then
    H.ok("Neovim " .. vstr .. " (>= 0.9 OK)")
  else
    H.err("Neovim " .. vstr .. " (< 0.9)")
  end

  local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
  local is_wsl = (vim.fn.has("wsl") == 1)
  local is_mac = (vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1)
  local os = is_win and "Windows" or (is_mac and "macOS" or "Linux/Unix")
  H.info(("OS: %s%s"):format(os, is_wsl and " (WSL)" or ""))
end

local function section_config(cfg)
  H.start("Config")
  H.ok(("anchor_levels = {%s}"):format(table.concat(cfg.anchor_levels or {}, ",")))
  H.info(("debug = %s"):format(tostring(cfg.debug)))
  H.info(("keymap = %s"):format(cfg.keymap and ("%q"):format(cfg.keymap) or "nil"))
  H.info(("footnote_backref_key = %s"):format(cfg.footnote_backref_key and ("%q"):format(cfg.footnote_backref_key) or "nil"))
end

local function section_openers(cfg)
  H.start("Openers (argv)")
  do
    local ok, msg = check_opener(cfg.open_cmd)
    if ok then H.ok("open_cmd: " .. msg) else H.err("open_cmd: " .. msg) end
  end
  do
    local ok, msg = check_opener(cfg.open_url_cmd)
    if ok then H.ok("open_url_cmd: " .. msg) else H.err("open_url_cmd: " .. msg) end
  end
  -- WSL hint
  local is_wsl = (vim.fn.has("wsl") == 1)
  if is_wsl and cfg.open_cmd and cfg.open_cmd[1] ~= "wslview" then
    H.warn("WSL detected: consider using `wslview` for best experience")
  end
end

local function section_keymaps(cfg)
  H.start("Keymaps")
  local ok1, msg1 = check_keymap_installed(cfg.keymap)
  if ok1 then H.ok(msg1) else H.warn(msg1) end
  local ok2, msg2 = check_keymap_installed(cfg.footnote_backref_key)
  if ok2 then H.ok(msg2) else H.info(msg2) end
end

local function section_parser_selftest()
  H.start("Parser self-test")
  local okp, parser = pcall(require, "mdlinks.core.parser")
  if not okp or type(parser.links_in_line) ~= "function" then
    H.err("mdlinks.parser not available")
    return
  end
  local sample = table.concat({
    "prefix ",
    "[A](http://example.com) ",
    "[B](#my-heading) ",
    "![C](./img.png) ",
    "[D](../doc.pdf) ",
    "suffix",
  }, "")
  local hits = parser.links_in_line(sample)
  if type(hits) ~= "table" then
    H.err("links_in_line returned non-table")
    return
  end
  local kinds = { url = 0, heading = 0, image = 0, file = 0 }
  for _, h in ipairs(hits) do
    kinds[h.kind] = (kinds[h.kind] or 0) + 1
  end
  local ok_cnt = (kinds.url == 1 and kinds.heading == 1 and kinds.image == 1 and kinds.file == 1)
  if ok_cnt then
    H.ok(("detected 4 entities (url=1, heading=1, image=1, file=1)"))
  else
    H.warn(("unexpected entity breakdown: url=%d heading=%d image=%d file=%d")
      :format(kinds.url or 0, kinds.heading or 0, kinds.image or 0, kinds.file or 0))
  end
end

--- Main entry point for :checkhealth mdlinks
function M.check()
  section_environment()

  local cfg, why = get_cfg()
  if not cfg then
    H.err(why or "no config")
    return
  end

  section_config(cfg)
  section_openers(cfg)
  section_keymaps(cfg)
  section_parser_selftest()
end

return M
