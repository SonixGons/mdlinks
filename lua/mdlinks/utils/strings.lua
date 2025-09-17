---@module 'mdlinks.utils.strings'
--- String helpers: URI decode, anchor normalization, simple scanners.

local M = {}

--- Percent-decoding for local file links (minimal).
---@param s string
---@return string
function M.uri_decode(s)
  return (s:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

--- Normalize GitHub-like anchors: strip '#', lowercase, collapse spaces to '-'.
---@param s string
---@return string
function M.normalize_anchor(s)
  local a = s:gsub("^%s*#*", "")
  a = a:lower()
  a = a:gsub("[^%w%s%-_]", "")
  a = a:gsub("%s+", "-")
  a = a:gsub("%-+", "-")
  a = a:gsub("^%-+", ""):gsub("%-+$", "")
  return a
end

--- Detect if string starts with a URI scheme (generic).
---@param s string
---@return boolean
function M.has_scheme(s)
  return s:match("^[a-zA-Z][a-zA-Z0-9+.-]*:") ~= nil
end

--- Detect typical web urls (http/https/ftp/mailto).
---@param s string
---@return boolean
function M.is_web_url(s)
  return s:match("^https?://") or s:match("^ftp://") or s:match("^mailto:")
end

--- Find a bare URL or <autolink> covering given column (1-based).
---@param line string
---@param col integer
---@return string|nil
function M.url_under_cursor(line, col)
  local i = 1
  while true do
    local s, e = line:find("<https?://[^%s>]+>", i)
    if not s then break end
    if col >= s and col <= e then
      return line:sub(s + 1, e - 1)
    end
    i = e + 1
  end
  i = 1
  while true do
    local s, e = line:find("https?://[%w%p]+", i)
    if not s then break end
    if col >= s and col <= e then
      local url = line:sub(s, e):gsub("[%)%]%.,;:]+$", "")
      return url
    end
    i = e + 1
  end
  return nil
end

return M

