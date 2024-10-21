local const = dofile_once("mods/health_container/files/scripts/const.lua") ---@type const

---@class utils
local utils = {}

---@param id string
function utils:ResolveModSettingId(id)
	return const.MOD_ID .. "." .. id
end

---@param id string
function utils:ModSettingGet(id)
	return ModSettingGet(self:ResolveModSettingId(id))
end

---@param id string
---@return number
function utils:ModSettingGetNumber(id)
	return utils:ModSettingGet(id) --[[@as number]]
end

---@param entity_id entity_id
---@param name string?
function utils:EntityGetFirstVSC(entity_id, name)
	local vsc_comps = EntityGetComponent(entity_id, "VariableStorageComponent")
	if not vsc_comps then
		return
	end
	for _, vsc in ipairs(vsc_comps) do
		if name then
			if ComponentGetValue2(vsc, "name") == name then
				return vsc
			end
		else
			return vsc
		end
	end
end

---Returns a float in range [a, b].
---@param a number
---@param b number
function utils:RandomFloat(a, b)
	return a + math.abs(b - a) * math.random()
end

---@param number number
---@param decimal? integer
function utils:TruncateNumber(number, decimal)
	if decimal <= 0 then
		decimal = nil
	end
	local pow = 10 ^ (decimal or 0)
	return math.floor(number * pow) / pow
end

return utils
