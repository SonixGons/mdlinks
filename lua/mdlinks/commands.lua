---@module 'mdlinks.commands'
--- User commands; UI layer is allowed to notify.
--- Low-level modules never call vim.notify directly (per rules).

---@class MdlinksCommands
local M = {}

function M.register_user_commands()
  vim.api.nvim_create_user_command("MdlinksFollow", function()
    local ok_nav, nav = pcall(require, "mdlinks.core.nav")
    if not ok_nav then
      vim.notify("[mdlinks] internal error: nav not available", vim.log.levels.ERROR)
      return
    end
    local ok, err = nav.follow_under_cursor()
    if not ok then
      -- Surface common reasons with a friendly message
      local msg = ("[mdlinks] %s"):format(err or "no markdown entity under cursor")
      vim.notify(msg, vim.log.levels.WARN)
    end
  end, { desc = "Follow markdown entity (link/ref/url/footnote) under cursor" })

  vim.api.nvim_create_user_command("MdlinksFootnoteBack", function()
    local ok_nav, nav = pcall(require, "mdlinks.core.nav")
    if not ok_nav then
      vim.notify("[mdlinks] internal error: nav not available", vim.log.levels.ERROR)
      return
    end
    local ok, err = nav.jump_footnote_backref()
    if not ok then
      vim.notify("[mdlinks] " .. tostring(err or "no footnote definition here"), vim.log.levels.WARN)
    end
  end, { desc = "Jump from footnote definition back to first reference" })
end

return M
