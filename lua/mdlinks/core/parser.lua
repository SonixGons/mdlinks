---@module 'mdlinks.parser'
local M = {}

---@class MdLink
---@field raw string
---@field text string
---@field target string
---@field kind  "url"|"file"|"image"|"heading"

---@class MdLinkHit : MdLink
---@field s integer  -- 1-based start col (inclusive)
---@field e integer  -- 1-based end col (inclusive)

---@param line string
---@return MdLinkHit[]  -- all links found in line, with their ranges
function M.links_in_line(line)
  if type(line) ~= "string" then return {} end
  local hits = {}
  local i = 1
  while true do
    local s1, e1, label, target = line:find("%[([^%]]+)%]%(([^)]+)%)", i)
    if not s1 then break end

    -- Reuse your kind classifier from link_under_cursor:
    local lower = target:lower()
    local function is_url(s) return s:match("^%a[%w+.-]*://") ~= nil end
    local function is_heading(s) return s:match("^%s*#+") ~= nil end
    local function is_image_path(s)
      return s:match("%.png$") or s:match("%.jpe?g$") or s:match("%.gif$")
          or s:match("%.webp$") or s:match("%.bmp$") or s:match("%.svg$")
    end
    local kind = (is_url(lower) and "url")
              or (is_heading(target) and "heading")
              or (is_image_path(lower) and "image")
              or "file"

    hits[#hits + 1] = {
      raw = line:sub(s1, e1),
      text = label,
      target = target,
      kind = kind,
      s = s1,
      e = e1,
    }
    i = e1 + 1
  end
  return hits
end

---@param line string
---@param col integer  -- 1-based cursor column
---@return MdLink|nil
function M.link_under_cursor(line, col)
  local hits = M.links_in_line(line)
  for _, h in ipairs(hits) do
    if col >= h.s and col <= h.e then
      return h
    end
  end
  return nil
end

---@param line string
---@param col integer
---@return MdLink|nil
function M.link_best_on_line(line, col)
  local hits = M.links_in_line(line)
  if #hits == 0 then return nil end

  -- 1) under cursor
  for _, h in ipairs(hits) do
    if col >= h.s and col <= h.e then return h end
  end
  -- 2) nearest by column distance
  local best, best_d = nil, math.huge
  for _, h in ipairs(hits) do
    local d = 0
    if col < h.s then d = h.s - col
    elseif col > h.e then d = col - h.e
    else d = 0 end
    if d < best_d then best, best_d = h, d end
  end
  return best
end

return M
