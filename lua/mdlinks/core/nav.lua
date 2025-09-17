---@module 'mdlinks.core.nav'
local Parser = require("mdlinks.core.parser")
local Resolve = require("mdlinks.core.resolve")
local Open = require("mdlinks.core.open")

local M = {}

---@return nil
function M.follow_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- 1-based col
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  local link = Parser.link_under_cursor(line, col)
  if not link then
    vim.notify("[mdlinks] No link under cursor", vim.log.levels.INFO)
    return
  end

  local resolved = Resolve.resolve(bufnr, link)
  if not resolved then return end

  if resolved.kind == "url" then
    Open.open_url(assert(resolved.url))
  elseif resolved.kind == "heading" then
    Open.jump_to_heading(assert(resolved.heading).level, resolved.heading.text)
  else
    Open.open_path(assert(resolved.path))
  end
end

return M
