---@module 'mdlinks.core.nav'
local Parser = require("mdlinks.core.parser")
local Resolve = require("mdlinks.core.resolve")
local Open = require("mdlinks.core.open")

local M = {}

---@return nil
function M.follow_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""

  -- Prefer link under cursor; fallback to nearest/first on the line
  local link = Parser.link_under_cursor(line, col)
              or Parser.link_best_on_line(line, col)

  if not link then
    vim.notify("[mdlinks] No link on this line", vim.log.levels.INFO)
    return false
  end

  local resolved = Resolve.resolve(bufnr, link)
  if not resolved then return false end

  if resolved.kind == "url" then
    Open.open_url(assert(resolved.url))
		return true
  elseif resolved.kind == "heading" then
    Open.jump_to_heading(assert(resolved.heading).level, resolved.heading.text)
		return true
  else
    Open.open_path(assert(resolved.path))
		return true
  end
end

return M
