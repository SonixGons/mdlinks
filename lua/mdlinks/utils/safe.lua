---@module 'mdlinks.utils.safe'
--- Safe-call helpers with structured returns (no notify here).

local M = {}

--- Execute a function safely; return ok + result/err.
---@generic T
---@param fn fun(...):T
---@vararg any
---@return boolean, T|nil, string|nil
function M.safe_call(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return true, res, nil end
  return false, nil, tostring(res)
end

return M
