---@module 'mdlinks.parser'
local M = {}

---@class MdLink
---@field raw string
---@field text string
---@field target string
---@field kind  "url"|"file"|"image"|"heading"

---@param line string
---@param col integer  -- 1-based cursor column
---@return MdLink|nil
function M.link_under_cursor(line, col)
  if type(line) ~= "string" or type(col) ~= "number" then return nil end

  -- Find [label](target) around cursor
  local s1, e1, label, target = line:find("%[([^%]]+)%]%(([^)]+)%)")
  if not s1 then return nil end
  if col < s1 or col > e1 then return nil end

  -- Classify target
  local lower = target:lower()

  local function is_url(s)
    return s:match("^%a[%w+.-]*://") ~= nil
  end

  local function is_heading(s)
    -- Accept "#foo", "##foo", "### foo", etc.
    return s:match("^%s*#+") ~= nil
  end

  local function is_image_path(s)
    return s:match("%.png$") or s:match("%.jpe?g$") or s:match("%.gif$")
        or s:match("%.webp$") or s:match("%.bmp$") or s:match("%.svg$")
  end

  local kind ---@type MdLink["kind"]
  if is_url(lower) then
    kind = "url"
  elseif is_heading(target) then
    kind = "heading"
  elseif is_image_path(lower) then
    kind = "image"
  else
    kind = "file"
  end

  return {
    raw = line:sub(s1, e1),
    text = label,
    target = target,
    kind = kind,
  }
end

return M
