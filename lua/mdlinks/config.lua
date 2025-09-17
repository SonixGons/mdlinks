---@module 'mdlinks.config'
--- Central configuration with validation, defaults and accessors.
--- UI-facing; pure data, no side effects. Validates options per rules.

---@class MdlinksConfig
---@field keymap string|nil
---@field footnote_backref_key string|nil
---@field open_cmd string|nil|any    # string or argv table (command used for files)
---@field open_url_cmd string|nil|any# string or argv table (command used for web URLs)
---@field anchor_levels integer[]
---@field debug boolean|nil
local M = {}

---@type MdlinksConfig
local defaults = {
  keymap = "j",
  footnote_backref_key = nil,
  open_cmd = nil,
  open_url_cmd = nil,
  anchor_levels = { 1, 2, 3, 4, 5, 6 },
	debug = false,
  line_fallback = true, -- try first link on the line if none under cursor
}

---@type MdlinksConfig
local state = vim.deepcopy(defaults)

--- Validate array-like table
---@param t any
---@return boolean
local function is_array(t)
  if type(t) ~= "table" then return false end
  local n = #t
  for k, _ in pairs(t) do
    if type(k) ~= "number" or k < 1 or k > n then return false end
  end
  return true
end

--- Merge user options into defaults with guards.
---@param opts table|nil
---@return nil
function M.setup(opts)
  opts = type(opts) == "table" and opts or {}
  local s = vim.deepcopy(defaults)

  -- user overrides
  if type(opts.keymap) == "string" then s.keymap = opts.keymap end
  if type(opts.footnote_backref_key) == "string" then s.footnote_backref_key = opts.footnote_backref_key end
  if type(opts.open_cmd) == "string" or is_array(opts.open_cmd) then s.open_cmd = opts.open_cmd end
  if type(opts.open_url_cmd) == "string" or is_array(opts.open_url_cmd) then s.open_url_cmd = opts.open_url_cmd end
  if is_array(opts.anchor_levels) then s.anchor_levels = opts.anchor_levels end
  if type(opts.debug) == "boolean" then s.debug = opts.debug end
  if type(opts.line_fallback) == "boolean" then s.line_fallback = opts.line_fallback end

  -- platform defaults if unset
  if s.open_cmd == nil or s.open_url_cmd == nil then
    local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
    local is_wsl = (vim.fn.has("wsl") == 1)
    local is_mac = (vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1)
    if is_win and not is_wsl then
      s.open_cmd     = s.open_cmd     or { "cmd.exe", "/c", "start", "" }
      s.open_url_cmd = s.open_url_cmd or { "cmd.exe", "/c", "start", "" }
    elseif is_wsl then
      if vim.fn.executable("wslview") == 1 then
        s.open_cmd     = s.open_cmd     or "wslview"
        s.open_url_cmd = s.open_url_cmd or "wslview"
      else
        s.open_cmd     = s.open_cmd     or { "powershell.exe", "-NoProfile", "-Command", "Start-Process" }
        s.open_url_cmd = s.open_url_cmd or { "powershell.exe", "-NoProfile", "-Command", "Start-Process" }
      end
    elseif is_mac then
      s.open_cmd     = s.open_cmd     or "open"
      s.open_url_cmd = s.open_url_cmd or "open"
    else
      s.open_cmd     = s.open_cmd     or "xdg-open"
      s.open_url_cmd = s.open_url_cmd or "xdg-open"
    end
  end

  state = s
end

--- Get a single option value by key.
---@param key string
---@return any
function M.get(key)
  return state[key]
end

--- Return full options table (immutable clone).
---@return MdlinksConfig
function M.options()
  return vim.deepcopy(state)
end

return M

