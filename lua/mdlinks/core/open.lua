---@module 'mdlinks.core.open'
local M = {}

local function platform()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then return "windows" end
  if vim.fn.has("mac") == 1 then return "mac" end
  return "linux"
end

---@param argv string[]
---@return boolean, string|nil
local function job_detached(argv)
  if type(argv) ~= "table" or #argv == 0 then
    return false, "invalid opener argv"
  end
  local ok = pcall(vim.fn.jobstart, argv, { detach = true })
  if not ok then
    return false, "failed to spawn opener"
  end
  return true
end

---@param url string
---@return boolean, string|nil
function M.open_url(url)
  -- If you have user-configurable open_url_cmd, normalize & use it here.
  local pf = platform()
  if pf == "windows" then
    return job_detached({ "cmd.exe", "/c", "start", "", url })
  elseif pf == "mac" then
    return job_detached({ "open", url })
  else
    return job_detached({ "xdg-open", url })
  end
end

local function is_text_like(path)
  local l = path:lower()
  return l:match("%.md$") or l:match("%.txt$") or l:match("%.lua$")
      or l:match("%.json$") or l:match("%.toml$") or l:match("%.ya?ml$")
end

---@param path string
---@return boolean, string|nil
function M.open_path(path)
  if is_text_like(path) then
    local ok, _ = pcall(function()
      vim.cmd.edit(vim.fn.fnameescape(path))
    end)
    if not ok then
      return false, "failed to :edit file"
    end
    return true
  end
  local pf = platform()
  if pf == "windows" then
    return job_detached({ "cmd.exe", "/c", "start", "", path })
  elseif pf == "mac" then
    return job_detached({ "open", path })
  else
    return job_detached({ "xdg-open", path })
  end
end

---@param level integer|nil
---@param text string
---@return boolean, string|nil
function M.jump_to_heading(level, text)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local function slugify(s)
    s = tostring(s or ""):gsub("`", ""):lower()
    s = s:gsub("%s+", "-"):gsub("[^%w%-_]", ""):gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    return s
  end

  local target_slug ---@type string|nil
  local prefer_level = tonumber(level)

  local function looks_sluggy(t) return t:find("%-") or (t == t:lower() and not t:find("%u")) end
  if not prefer_level then
    target_slug = slugify(text)
  else
    if text == "" or text:sub(1,1) == "-" or looks_sluggy(text) then
      target_slug = slugify(text:gsub("^%-+", ""))
    end
  end

  ---@class H
  ---@field lnum integer
  ---@field level integer
  ---@field text string
  ---@field slug string
  local heads, counts = {}, {}
  for i = 1, #lines do
    local s = lines[i] or ""
    local hashes, htxt = s:match("^%s*(#+)%s*(.-)%s*$")
    if hashes and htxt and htxt ~= "" then
      local lev = #hashes
      local base = slugify(htxt)
      if base ~= "" then
        local n = (counts[base] or 0) + 1
        counts[base] = n
        local final = (n > 1) and (base .. "-" .. (n - 1)) or base
        heads[#heads + 1] = { lnum = i, level = lev, text = htxt, slug = final }
      end
    end
  end
  if #heads == 0 then
    return false, "no markdown headings in buffer"
  end

  local function normtxt(s) return (s or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""):lower() end
  local target_text_norm = normtxt(text)
  local slug_of_text = slugify(text)

  local function matches(h)
    return not prefer_level or h.level == prefer_level
  end

  local found
  if target_slug and target_slug ~= "" then
    for _, h in ipairs(heads) do if matches(h) and h.slug == target_slug then found = h; break end end
  end
  if not found and not target_slug and target_text_norm ~= "" then
    for _, h in ipairs(heads) do if matches(h) and normtxt(h.text) == target_text_norm then found = h; break end end
  end
  if not found and target_text_norm ~= "" then
    for _, h in ipairs(heads) do if matches(h) and h.slug == slug_of_text then found = h; break end end
  end
  if not found then
    local want = (prefer_level and (string.rep("#", prefer_level) .. " ") or "# ") .. text
    return false, ("heading not found: %s"):format(want)
  end

  -- Jump (keep jumplist) – UI centering (zz) bleibt Aufgabe der UI-Schicht
  local ok = pcall(vim.api.nvim_win_set_cursor, 0, { found.lnum, 0 })
  if not ok then
    return false, "failed to move cursor"
  end
  return true
end

return M
