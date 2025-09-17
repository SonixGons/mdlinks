---@module 'mdlinks.core.open'
--- Opening strategies for URLs and files. No UI; callers handle notifications.

local Paths   = require("mdlinks.utils.paths")
local Strings = require("mdlinks.utils.strings")
local Cfg     = require("mdlinks.config")

local M = {}

local function dbg(...)
  if Cfg.get("debug") then
    print("mdlinks debug:", ...)
  end
end

--- Open a web URL with configured opener; if unset, pick platform default.
---@param url string
---@return boolean,string|nil
function M.open_url(url)
  local user = Cfg.get("open_url_cmd")
  local opener = user or Cfg.get("open_cmd") or Paths.detect_opener("url")
  dbg("open_url opener:", type(opener) == "table" and opener[1] or opener, "target:", url)
  local ok, err, job = Paths.spawn(opener, url)
  if not ok then
    dbg("open_url failed:", err or "unknown", "job:", tostring(job))
    -- optional fallback using vim.ui.open (Neovim 0.10+)
    if type(vim.ui.open) == "function" then
      local ok2, err2 = pcall(vim.ui.open, url)
      if ok2 then return true, nil end
      return false, ("open_url fallback failed: %s; primary: %s"):format(tostring(err2), tostring(err))
    end
  end
  return ok, err
end
--- Open a local file or directory with system opener; Windows/WSL supported.
---@param path string
---@return boolean,string|nil
function M.open_file(path)
  local user = Cfg.get("open_cmd")
  local opener = user or Paths.detect_opener("file")
  dbg("open_file opener:", type(opener) == "table" and opener[1] or opener, "target:", path)
  local ok, err, job = Paths.spawn(opener, path)
  if not ok then
    dbg("open_file failed:", err or "unknown", "job:", tostring(job))
    if type(vim.ui.open) == "function" then
      local ok2, err2 = pcall(vim.ui.open, path)
      if ok2 then return true, nil end
      return false, ("open_file fallback failed: %s; primary: %s"):format(tostring(err2), tostring(err))
    end
  end
  return ok, err
end

--- Decide how to open a target: anchor/url/file, keeping behavior consistent.
---@param raw string
---@return boolean,string|nil
function M.dispatch_open(raw)
  local s = Strings.uri_decode(raw)
  if s:match("^%s*#") then
    return false, "anchor-target"
  end
  if Strings.is_web_url(s) or (Strings.has_scheme(s) and not s:match("^file:")) then
    return M.open_url(s)
  end
  local norm = Paths.normalize_path(s)
  return M.open_file(norm)
end

return M
