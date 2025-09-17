---@module 'mdlinks.open'
local M = {}

---@return "windows"|"mac"|"linux"
local function platform()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then return "windows" end
  if vim.fn.has("mac") == 1 then return "mac" end
  return "linux"
end

---@param args string[]
---@return nil
local function spawn_detached(args)
  -- Silent, detached job
  vim.fn.jobstart(args, { detach = true })
end

---@param url string
---@return nil
function M.open_url(url)
  local pf = platform()
  if pf == "windows" then
    -- Use start via cmd to respect default browser
    spawn_detached({ "cmd.exe", "/c", "start", "", url })
  elseif pf == "mac" then
    spawn_detached({ "open", url })
  else
    spawn_detached({ "xdg-open", url })
  end
end

---@param path string
---@return nil
local function open_with_system(path)
  local pf = platform()
  if pf == "windows" then
    spawn_detached({ "cmd.exe", "/c", "start", "", path })
  elseif pf == "mac" then
    spawn_detached({ "open", path })
  else
    spawn_detached({ "xdg-open", path })
  end
end

---@param path string
---@return boolean
local function is_text_like(path)
  local lower = path:lower()
  return lower:match("%.md$") or lower:match("%.txt$") or lower:match("%.lua$")
      or lower:match("%.json$") or lower:match("%.toml$") or lower:match("%.yaml$")
end

---@param path string
---@return boolean
local function is_image(path)
  local l = path:lower()
  return l:match("%.png$") or l:match("%.jpe?g$") or l:match("%.gif$")
      or l:match("%.webp$") or l:match("%.bmp$") or l:match("%.svg$")
end

---@param path string
---@return boolean
local function is_pdf(path)
  return path:lower():match("%.pdf$") ~= nil
end

---@param path string
---@return nil
function M.open_path(path)
  if is_text_like(path) then
    -- open in current window as a buffer
    vim.cmd.edit(vim.fn.fnameescape(path))
  else
    -- Let OS pick the associated app (PDF viewer, image viewer, etc.)
    open_with_system(path)
  end
end

---@param level integer
---@param text string
---@return nil
function M.jump_to_heading(level, text)
  -- Exact prefix with that many #'s, then optional spaces, then text
  -- We keep it simple on purpose: your example uses exact "## test".
  local pat
  if text == "" then
    pat = string.format("^%s%s", string.rep("#", level), "%s*$")
  else
    -- Escape magic chars in text
    local esc = vim.pesc(text)
    pat = string.format("^%s%%s*%s%%s*$", string.rep("#", level), esc)
  end

  -- Try from top; keep cursor history
  local save = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local ok = vim.fn.search(pat, "W") ~= 0
  if not ok then
    vim.api.nvim_win_set_cursor(0, save)
    vim.notify("[mdlinks] Heading not found: " .. string.rep("#", level) .. " " .. text, vim.log.levels.WARN)
  end
end

return M
