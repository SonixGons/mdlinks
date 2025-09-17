---@module 'mdlinks.utils.paths'
--- Cross-platform open helpers.

local M = {}

local function is_windows() return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 end
local function is_wsl() return vim.fn.has("wsl") == 1 end

local function to_win_path(p) return (p:gsub("/", "\\")) end

---@param rel string
---@return string
function M.normalize_path(rel)
  if is_windows() and rel:match("^%a:[/\\]") then return rel end
  local p = rel:gsub("^~", vim.fn.expand("~"))
  if p:match("^/") then return p end
  if is_windows() and p:match("^\\") then
    local cur = vim.fn.expand("%:p:h")
    local drive = cur:match("^(%a:)")
    if drive then return drive .. p end
  end
  local bufdir = vim.fn.expand("%:p:h")
  return vim.fn.fnamemodify(bufdir .. "/" .. p, ":p")
end

---@param kind "url"|"file"
---@return string|string[]
function M.detect_opener(kind)
  if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    return "open"
  end
  if not is_windows() and not is_wsl() then
    return "xdg-open"
  end
  if is_wsl() then
    if vim.fn.executable("wslview") == 1 then return "wslview" end
    if vim.fn.executable("powershell.exe") == 1 then
      return { "powershell.exe", "-NoProfile", "-Command", "Start-Process" }
    end
    return "xdg-open"
  end
  -- Windows native: proven default; works for URLs & files
  return { "cmd.exe", "/c", "start", "" }
end

--- Spawn detached process. Adds Windows quoting for cmd.exe start.
---@param argv string|string[]
---@param target string
---@return boolean,string|nil,integer|nil
function M.spawn(argv, target)
  local exe = (type(argv) == "string") and argv
    or (type(argv) == "table" and type(argv[1]) == "string" and argv[1] or nil)
  if not exe then return false, "Invalid opener argv (exe missing)", -1 end
  if vim.fn.executable(exe) ~= 1 then
    return false, ("Not executable: %q"):format(exe), -1
  end

  local cmd
  if type(argv) == "string" then
    cmd = { exe, target }
  else
    cmd = vim.deepcopy(argv)
    local is_cmd = exe:lower():find("cmd%.exe$", 1, true) ~= nil
    if is_cmd then
      for i = 1, #cmd do
        if type(cmd[i]) == "string" and cmd[i]:lower() == "start" then
          if cmd[i + 1] ~= "" then table.insert(cmd, i + 1, "") end
          break
        end
      end
      if not (target:match("^%a+://") or target:match("^mailto:")) then
        local winp = to_win_path(target)
        target = '"' .. winp .. '"'
      end
    end
    table.insert(cmd, target)
  end

  local job = vim.fn.jobstart(cmd, { detach = true })
  if job <= 0 then
    return false, ("jobstart failed (argv: %s)"):format(vim.inspect(cmd)), job
  end
  return true, nil, job
end

return M
