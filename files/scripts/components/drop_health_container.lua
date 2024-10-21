dofile_once("data/scripts/game_helpers.lua")
dofile_once("data/scripts/lib/utilities.lua")
local const = dofile_once("mods/health_container/files/scripts/const.lua") ---@type const
local utils = dofile_once("mods/health_container/files/scripts/utils.lua") ---@type utils

function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
  local entity_id = GetUpdatedEntityID()

  local damage_model = EntityGetFirstComponent(entity_id, "DamageModelComponent")
  if not damage_model then return end

  local max_hp = ComponentGetValue2(damage_model, "max_hp")

  local drop_chance = 0
  local drop_chance_mode = utils:ModSettingGetNumber("drop_chance_mode")
  if drop_chance_mode == const.enum.DROP_CHANCE_MODE.CONSTANT then
    drop_chance = utils:ModSettingGetNumber("drop_chance_constant")
  elseif drop_chance_mode == const.enum.DROP_CHANCE_MODE.ENEMY_SCALE then
    local base_chance = utils:ModSettingGetNumber("drop_chance_scale_base")
    local base_hp = utils:ModSettingGetNumber("drop_chance_scale_base_hp")
    drop_chance = max_hp / base_hp * base_chance
  end

  print("drop_mode", drop_chance_mode, "max_hp", max_hp, "drop_chance", drop_chance)

  if GameGetIsTrailerModeEnabled() or math.random() > drop_chance then return end

  local x, y = EntityGetTransform(entity_id)
  local pickup_entity_id = EntityLoad("mods/health_container/files/entities/items/health_container.xml", x, y - 7)
  EntityAddComponent2(pickup_entity_id, "VariableStorageComponent", { name = "enemy_max_hp", value_float = max_hp })
end
