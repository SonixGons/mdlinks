---@module 'mdlinks.utils.paths'
--- Cross-platform path helpers and process spawning for Linux/macOS/Windows.
--- Design:
---   - Pure helpers (no UI). Caller modules handle notifications.
---   - Windows support uses either PowerShell (preferred) or cmd.exe "start".
---   - WSL support prefers "wslview" when available; falls back to powershell.exe.

---@class PathsUtil
local M = {}

--------------------------------------------------------------------------------
-- OS / Platform detection
--------------------------------------------------------------------------------

--- Check if Neovim runs on Windows (native).
---@return boolean
local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

--- Check if Neovim runs inside WSL.
---@return boolean
local function is_wsl()
  -- Heuristic: presence of "Microsoft" in /proc/version or system property
  if vim.fn.has("wsl") == 1 then return true end
  local ok, data = pcall(function()
    local f = io.open("/proc/version", "r")
    if not f then return "" end
    local s = f:read("*a") or ""
    f:close()
    return s
  end)
  return ok and data:lower():find("microsoft") ~= nil or false
end

--- Check simple executability for a command name.
---@param cmd string
---@return boolean
local function has_exec(cmd)
  return vim.fn.executable(cmd) == 1
end

--------------------------------------------------------------------------------
-- Path utilities
--------------------------------------------------------------------------------

--- Expand ~ and resolve relative path against current buffer directory.
---@param rel string
---@return string
function M.normalize_path(rel)
  -- Windows drive-letter absolute paths: leave as-is if they match "X:\..."
  if is_windows() and rel:match("^%a:[/\\]") then
    return rel
  end
  -- Expand ~
  local p = rel:gsub("^~", vim.fn.expand("~"))
  -- Absolute POSIX path?
  if p:match("^/") then return p end
  -- Windows absolute path via backslash root (e.g. "\Users\..."): join to drive of current buffer
  if is_windows() and p:match("^\\") then
    local cur = vim.fn.expand("%:p:h")
    local drive = cur:match("^(%a:)")
    if drive then return drive .. p end
  end
  -- Resolve relative path against the buffer directory
  local bufdir = vim.fn.expand("%:p:h")
  local full = vim.fn.fnamemodify(bufdir .. "/" .. p, ":p")
  return full
end

--------------------------------------------------------------------------------
-- Opener detection (URL vs File)
--------------------------------------------------------------------------------

--- Detect the best opener argv for the current platform.
--- For Linux/macOS returns string command; for Windows/WSL returns argv array.
---@param kind? "url"|"file"|nil
---@return string|string[]
function M.detect_opener(kind)
  -- macOS: "open"
  if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    return "open"
  end

  -- Linux (non-WSL): "xdg-open"
  if not is_windows() and not is_wsl() then
    return "xdg-open"
  end

  -- WSL: prefer wslview; else use powershell.exe Start-Process
  if is_wsl() then
    if has_exec("wslview") then
      return "wslview"
    end
    if has_exec("powershell.exe") then
      -- Start-Process <target> → open in Windows default app
      return { "powershell.exe", "-NoProfile", "-Command", "Start-Process" }
    end
    -- last resort in WSL: try xdg-open (may or may not be configured)
    return "xdg-open"
  end

  -- Native Windows:
  -- Prefer PowerShell because quoting rules are simpler with jobstart argv.
  if is_windows() then
    if has_exec("powershell") then
      return { "powershell", "-NoProfile", "-Command", "Start-Process" }
    end
    -- Fallback: cmd.exe /c start "" <target>
    return { "cmd.exe", "/c", "start", "" }
  end

  -- Safe fallback
  return "xdg-open"
end

--------------------------------------------------------------------------------
-- Process spawning
--------------------------------------------------------------------------------

--- Spawn a detached process using argv (string or array) and a target.
--- Handles Windows peculiarities (`cmd.exe /c start "" <target>`).
---@param argv string|string[]
---@param target string
---@return boolean,string|nil,integer|nil
function M.spawn(argv, target)
  -- Determine the "exe" (actual program to run) for both string/array forms.
  local exe = (type(argv) == "string") and argv
    or (type(argv) == "table" and type(argv[1]) == "string" and argv[1] or nil)

  -- Guard: invalid argv
  if not exe then
    return false, "Invalid opener argv (exe missing)", -1
  end

  -- Guard: exe must be found in PATH
  if vim.fn.executable(exe) ~= 1 then
    return false, ("Not executable: %q"):format(exe), -1
  end

  -- If argv is a plain string, use the simple 2-arg form: { exe, target }
  if type(argv) == "string" then
    local job = vim.fn.jobstart({ exe, target }, { detach = true })
    if job <= 0 then
      return false, ("jobstart failed (%s %s)"):format(exe, target), job
    end
    return true, nil, job
  end

  -- Array form: copy, normalize Windows 'start' semantics if needed, then append target
  local cmd = vim.deepcopy(argv)

  -- Windows: cmd.exe /c start requires an empty window-title argument right after 'start'
  -- Detect "... cmd.exe, /c, start, ..." and insert "" if missing.
  do
    local exe_lc = exe:lower()
    if exe_lc:find("cmd%.exe$", 1, true) then
      -- Find the index of 'start' (case-insensitive) in the argv
      local start_idx ---@type integer|nil
      for i = 1, #cmd do
        if type(cmd[i]) == "string" and cmd[i]:lower() == "start" then
          start_idx = i
          break
        end
      end
      if start_idx then
        -- If there is no argument immediately after 'start' or it isn't an empty title, insert ""
        local after = cmd[start_idx + 1]
        if after ~= "" then
          table.insert(cmd, start_idx + 1, "")
        end
      end
    end
  end

  -- Finally append the target
  table.insert(cmd, target)

  -- Launch
  local job = vim.fn.jobstart(cmd, { detach = true })
  if job <= 0 then
    return false, ("jobstart failed (argv: %s)"):format(vim.inspect(cmd)), job
  end
  return true, nil, job
end

return M
