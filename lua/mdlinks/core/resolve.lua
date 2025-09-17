---@module 'mdlinks.resolve'
local M = {}

---@param bufnr integer
---@return string
local function buf_dir(bufnr)
  local p = vim.api.nvim_buf_get_name(bufnr)
  if p == "" then return vim.uv.cwd() end
  return vim.fn.fnamemodify(p, ":p:h")
end

---@param s string
---@return boolean
local function looks_windows_abs(s)
  -- "E:/path/.." or "C:\path\.."
  return s:match("^[A-Za-z]:[\\/]")
end

---@param base string
---@param rel string
---@return string
local function join(base, rel)
  if rel:match("^[\\/%.]") then
    return vim.fn.fnamemodify(base .. "/" .. rel, ":p")
  else
    return vim.fn.fnamemodify(base .. "/" .. rel, ":p")
  end
end

---@class Resolved
---@field kind "url"|"file"|"image"|"heading"
---@field url? string
---@field path? string
---@field heading? { level: integer, text: string }

---@param bufnr integer
---@param link MdLink
---@return Resolved|nil
function M.resolve(bufnr, link)
  if type(link) ~= "table" then return nil end

  if link.kind == "url" then
    return { kind = "url", url = link.target }
  elseif link.kind == "heading" then
    -- Normalize "##test" / "## test"
    local hashes, text = link.target:match("^%s*(#+)%s*(.*)$")
    local level = hashes and #hashes or 1
    text = (text or ""):gsub("%s+$", "")
    return { kind = "heading", heading = { level = level, text = text } }
  else
    local t = link.target
    -- Strip surrounding quotes for paths like ("./foo bar.pdf")
    t = (t:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1"))

    local path
    if looks_windows_abs(t) or t:match("^/") or t:match("^~[/\\]") then
      path = vim.fn.fnamemodify(t, ":p")
    else
      path = join(buf_dir(bufnr), t)
    end
    return { kind = link.kind, path = path }
  end
end

return M
