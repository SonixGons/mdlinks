---@module 'mdlinks.core.resolve'
--- Resolution utilities: headings, reference definitions, footnotes.
--- Pure logic, no UI. Returns plain data or nil.

local Strings = require("mdlinks.utils.strings")

local M = {}

--- Convert heading line to normalized anchor and level.
---@param s string
---@return string|nil, integer|nil
function M.heading_to_anchor(s)
  local hashes, text = s:match("^(#+)%s*(.-)%s*$")
  if not hashes or text == "" then return nil end
  return Strings.normalize_anchor(text), #hashes
end

--- Find first line whose heading anchor equals `anchor` and level in `levels`.
---@param anchor string
---@param levels integer[]
---@return integer|nil
function M.find_heading_line(anchor, levels)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i = 1, #lines do
    local a, lvl = M.heading_to_anchor(lines[i])
    if a and a == anchor then
      for _, L in ipairs(levels) do
        if L == lvl then return i end
      end
    end
  end
  return nil
end

--- Resolve `[id]: target "title"` reference definition.
---@param id string
---@return RefDefinition|nil
function M.resolve_reference_definition(id)
  local function norm(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%s+", " ")
    return s:lower()
  end
  local nid = norm(id)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i = 1, #lines do
    local k, rest = lines[i]:match("^%s*%[([^%]]+)%]%s*:%s*(.+)$")
    if k and norm(k) == nid then
      local target = rest:gsub('%s+".*"$', ""):match("^%s*(.-)%s*$")
      return { target = target, line = i }
    end
  end
  return nil
end

--- Resolve `[^id]: ...` footnote definition line number.
---@param id string
---@return integer|nil
function M.resolve_footnote_definition_line(id)
  local function norm(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%s+", " ")
    return s:lower()
  end
  local nid = norm(id)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i = 1, #lines do
    local key = lines[i]:match("^%s*%[%^([^%]]+)%]%s*:")
    if key and norm(key) == nid then
      return i
    end
  end
  return nil
end

--- First `[^id]` reference line (to jump back from definition).
---@param id string
---@return integer|nil
function M.find_first_footnote_reference_line(id)
  local function norm(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%s+", " ")
    return s:lower()
  end
  local nid = norm(id)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i = 1, #lines do
    for _, key in lines[i]:gmatch("()%[%^([^%]]+)%]()") do
      if norm(key) == nid then return i end
    end
  end
  return nil
end

return M
