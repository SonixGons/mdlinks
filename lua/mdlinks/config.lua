---@module 'mdlinks.config'
--- Central configuration with validation, platform defaults, normalization, and accessors.
--- Pure data (no side effects besides optional keymaps).

local M = {}

---@type MdlinksConfig
local Defaults = {
	keymap = "gm",
	footnote_backref_key = nil,
	open_cmd = nil, -- nil → platform default
	open_url_cmd = nil, -- nil → platform default
	anchor_levels = { 1, 2, 3, 4, 5, 6 },
	debug = false,
}

---@type MdlinksResolvedConfig
local state --- set in setup()

-- ---------- helpers ----------

--- Normalize a command into argv (or error).
--- Accepts: nil (error if called), string → {string}, string[] → validated
---@param cmd string|string[]
---@return string[]
local function normalize_cmd_strict(cmd)
	local t = type(cmd)
	if t == "string" then
		return { cmd }
	elseif t == "table" then
		local out = {}
		for i, v in ipairs(cmd) do
			if type(v) ~= "string" then
				error(("open_*_cmd must be array of strings; index %d is %s"):format(i, type(v)))
			end
			out[i] = v
		end
		if #out == 0 then
			error("open_*_cmd must not be empty")
		end
		return out
	else
		error("open_*_cmd must be string or string[]")
	end
end

--- anchor_levels: table of positive integers
---@param arr any
---@return integer[]
local function normalize_levels(arr)
	if arr == nil then
		return { 1, 2, 3, 4, 5, 6 }
	end
	if type(arr) ~= "table" then
		error("anchor_levels must be an array of integers")
	end
	local out = {}
	for i, v in ipairs(arr) do
		if type(v) ~= "number" or v % 1 ~= 0 or v < 1 then
			error(("anchor_levels[%d] must be an integer >= 1"):format(i))
		end
		out[#out + 1] = v
	end
	return out
end

--- Platform default openers (argv form, shellless).
---@return string[] open_cmd, string[] open_url_cmd
local function compute_platform_defaults()
	local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
	local is_wsl = (vim.fn.has("wsl") == 1)
	local is_mac = (vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1)

	if is_win and not is_wsl then
		-- Use `start` to respect file associations; empty title "" is required.
		local argv = { "cmd.exe", "/c", "start", "" }
		return argv, argv
	elseif is_wsl then
		if vim.fn.executable("wslview") == 1 then
			local argv = { "wslview" }
			return argv, argv
		else
			-- Fallback: delegate to Windows via PowerShell
			local argv = { "powershell.exe", "-NoProfile", "-Command", "Start-Process" }
			return argv, argv
		end
	elseif is_mac then
		local argv = { "open" }
		return argv, argv
	else
		local argv = { "xdg-open" }
		return argv, argv
	end
end

-- ---------- core normalization ----------

---@param user MdlinksConfig|nil
---@return MdlinksResolvedConfig
function M._with_defaults(user)
	user = user or {}

	-- 1) Scalar validation
	if user.keymap ~= nil and type(user.keymap) ~= "string" then
		error("keymap must be a string or nil")
	end
	if user.footnote_backref_key ~= nil and type(user.footnote_backref_key) ~= "string" then
		error("footnote_backref_key must be a string or nil")
	end
	if user.debug ~= nil and type(user.debug) ~= "boolean" then
		error("debug must be boolean or nil")
	end

	-- 2) Platform defaults FIRST (so they get normalized too)
	local open_def, open_url_def = compute_platform_defaults()
	local open_raw = user.open_cmd ~= nil and user.open_cmd or Defaults.open_cmd or open_def
	local open_url_raw = user.open_url_cmd ~= nil and user.open_url_cmd or Defaults.open_url_cmd or open_url_def

	-- 3) Normalize complex fields
	local open_cmd = normalize_cmd_strict(open_raw)
	local open_url_cmd = normalize_cmd_strict(open_url_raw)
	local levels = normalize_levels(user.anchor_levels or Defaults.anchor_levels)

	-- 4) Build resolved config
	return {
		keymap = user.keymap ~= nil and user.keymap or Defaults.keymap,
		footnote_backref_key = user.footnote_backref_key ~= nil and user.footnote_backref_key
			or Defaults.footnote_backref_key,
		open_cmd = open_cmd,
		open_url_cmd = open_url_cmd,
		anchor_levels = levels,
		debug = user.debug ~= nil and user.debug or Defaults.debug,
	}
end

-- ---------- public API ----------

--- Merge user options into defaults with guards and (optionally) install keymaps.
---@param opts MdlinksConfig|nil
function M.setup(opts)
	local cfg = M._with_defaults(opts)
	state = cfg
	M.cfg = cfg

	if cfg.keymap then
		vim.keymap.set("n", cfg.keymap, function()
			vim.cmd("silent! MdlinksFollow")
		end, { desc = "mdlinks: follow URL/file/image/heading on the current line" })
	end

	if cfg.footnote_backref_key then
		vim.keymap.set("n", cfg.footnote_backref_key, function()
			vim.cmd("silent! MdlinksFootnoteBack")
		end, { desc = "mdlinks: jump back from footnote definition" })
	end
end

--- Get full resolved config (deep copy to keep immutability).
---@return MdlinksResolvedConfig
function M.options()
	return vim.deepcopy(state)
end

--- Get a single resolved option by key.
---@param key '"keymap"'|'"footnote_backref_key"'|'"open_cmd"'|'"open_url_cmd"'|'"anchor_levels"'|'"debug"'
---@return any
function M.get(key)
	return state and state[key] or nil
end

return M
