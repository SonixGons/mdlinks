---@module 'mdlinks.core.types.core_types'
--- Shared core types for mdlinks.

---@alias MdlinksResult boolean
---@alias MdlinksError string

---@class AnchorMatch
---@field line integer
---@field level integer

---@class RefDefinition
---@field target string
---@field line integer

---@class FollowOutcome
---@field ok boolean
---@field err string|nil
