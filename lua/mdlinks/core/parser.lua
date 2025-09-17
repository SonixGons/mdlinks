---@module 'mdlinks.core.parser'
--- Parsers to extract markdown entities under the cursor.
--- Pure parsing; no I/O side effects. Suited for unit tests.

local M = {}

--- Extract inline link `[label](target)` that covers `col`.
---@param line string
---@param col integer
---@return string|nil,string|nil,integer|nil,integer|nil
function M.inline_link_at(line, col)
  local i = 1
  while true do
    local lb = line:find("%[", i, true)
    if not lb then return nil end
    local rb = lb and line:find("%]", lb + 1, true)
    if not rb then return nil end
    local lp = line:find("%(", rb + 1, true)
    if not lp then i = rb + 1 goto continue end
    local depth, pos, rp = 0, lp, nil
    while pos <= #line do
      local ch = line:sub(pos, pos)
      if ch == "(" then depth = depth + 1 end
      if ch == ")" then
        depth = depth - 1
        if depth == 0 then rp = pos; break end
      end
      pos = pos + 1
    end
    if not rp then return nil end
    if col >= lb and col <= rp then
      local inner = line:sub(lp + 1, rp - 1):match("^%s*(.-)%s*$")
      local target = inner:gsub('%s+".*"$', "")
      return "inline", target, lb, rp
    end
    ::continue::
    i = rp and (rp + 1) or (rb + 1)
  end
end

--- Extract reference link `[label][id]` / `[label][]` or footnote `[^id]`.
---@param line string
---@param col integer
---@return string|nil,string|nil,integer|nil,integer|nil
function M.reference_like_at(line, col)
  local i = 1
  while true do
    local lb = line:find("%[", i, true)
    if not lb then return nil end
    local rb = lb and line:find("%]", lb + 1, true)
    if not rb then return nil end
    if col < lb or col > rb + 1 then
      i = rb + 1
    else
      local nextch = line:sub(rb + 1, rb + 1)
      if nextch == "[" then
        local rb2 = line:find("%]", rb + 2, true)
        if not rb2 then return nil end
        if col >= lb and col <= rb2 then
          local idraw = line:sub(rb + 2, rb2 - 1)
          if line:sub(lb + 1, lb + 1) == "^" then
            return "footnote", line:sub(lb + 2, rb - 1), lb, rb2
          end
          local id = (idraw == "" and line:sub(lb + 1, rb - 1)) or idraw
          return "ref", id, lb, rb2
        end
        i = rb2 + 1
      else
        i = rb + 1
      end
    end
  end
end

return M
