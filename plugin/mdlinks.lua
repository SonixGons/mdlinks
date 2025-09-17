-- plugin/mdlinks.lua
-- Runtime entrypoint (executes once). Keep it tiny: just register user commands.

if vim.g.loaded_mdlinks then
  return
end
vim.g.loaded_mdlinks = true

local ok, commands = pcall(require, "mdlinks.commands")
if ok and type(commands.register_user_commands) == "function" then
  commands.register_user_commands()
else
  -- Defer notify so we don't break startup if UI isn't ready yet
  vim.schedule(function()
    vim.notify("[mdlinks] commands module not available", vim.log.levels.ERROR)
  end)
end
