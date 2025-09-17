---@module 'mdlinks.core.nav'
--- High-level navigation orchestration.
--- Orchestrates parser, resolver, and opener. No UI notify; returns (ok, err).

local Resolve = require("mdlinks.core.resolve")
local Strings = require("mdlinks.utils.strings")

---@class MdlinksNav
local M = {}

--- Follow entity under cursor (inline/ref/footnote/url).
---@return boolean,string|nil
function M.follow_under_cursor()
	print("debug mdlinks: follow under cursor")
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local col = pos[2] + 1

  -- bare URL
  do
    local naked = Strings.url_under_cursor(line, col)
    if naked then
			print("naked url: " .. naked)
      local ok, err = require("mdlinks.core.open").open_url(naked)
      return ok, ok and nil or (err or "failed to open URL")
    end
  end

  -- inline link
  do
    local kind, target = require("mdlinks.core.parser").inline_link_at(line, col)
    if kind == "inline" and target and target ~= "" then
      local ok, err = require("mdlinks.core.open").dispatch_open(target)
      if err == "anchor-target" then
        local anchor = Strings.normalize_anchor(target)
        local ln = Resolve.find_heading_line(anchor, require("mdlinks.config").get("anchor_levels"))
        if not ln then return false, "anchor not found: " .. target end
        vim.api.nvim_win_set_cursor(0, { ln, 0 }); vim.cmd("normal! ^zz")
        return true, nil
      end
      return ok, ok and nil or (err or "failed to open target")
    end
  end

  -- reference / footnote
  do
    local kind, id = require("mdlinks.core.parser").reference_like_at(line, col)
    if kind == "ref" and id and id ~= "" then
      local def = require("mdlinks.core.resolve").resolve_reference_definition(id)
      if not def then return false, ("reference not defined: [" .. id .. "]") end
      local ok, err = require("mdlinks.core.open").dispatch_open(def.target)
      if err == "anchor-target" then
        local anchor = Strings.normalize_anchor(def.target)
        local ln = Resolve.find_heading_line(anchor, require("mdlinks.config").get("anchor_levels"))
        if not ln then return false, "anchor not found: " .. def.target end
        vim.api.nvim_win_set_cursor(0, { ln, 0 }); vim.cmd("normal! ^zz")
        return true, nil
      end
      return ok, ok and nil or (err or "failed to open target")
    elseif kind == "footnote" and id and id ~= "" then
      local ln = require("mdlinks.core.resolve").resolve_footnote_definition_line(id)
      if not ln then return false, ("footnote not defined: [^" .. id .. "]") end
      vim.api.nvim_win_set_cursor(0, { ln, 0 }); vim.cmd("normal! ^zz")
      return true, nil
    end
  end

  return false, "no markdown entity under cursor (place cursor inside [...] or (...))"
end
--- Jump from `[^id]: …` definition line to first `[^id]` usage (backref).
---@return boolean,string|nil
function M.jump_footnote_backref()
	local line = vim.api.nvim_get_current_line()
  local id = line:match("^%s*%[%^([^%]]+)%]%s*:")
  if not id then return false, "not on a footnote definition line" end
  local ref = Resolve.find_first_footnote_reference_line(id)
  if not ref then return false, ("no reference found for [^" .. id .. "]") end
  vim.api.nvim_win_set_cursor(0, { ref, 0 }); vim.cmd("normal! ^zz")
  return true, nil
end

return M
