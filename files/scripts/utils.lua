local const = dofile_once("mods/health_container/files/scripts/const.lua") ---@type const

---@class utils
local utils = {}

---@param id string
function utils:ResolveModSettingId(id) return const.MOD_ID .. "." .. id end

---@param id string
function utils:ModSettingGet(id) return ModSettingGet(self:ResolveModSettingId(id)) end

---@param a number
---@param b number
function utils:RandomFloat(a, b) return a + math.abs(b - a) * math.random() end

---@param number number
---@param decimal? integer
function utils:TruncateNumber(number, decimal)
  if decimal <= 0 then decimal = nil end
  local pow = 10 ^ (decimal or 0)
  return math.floor(number * pow) / pow
end

return utils
