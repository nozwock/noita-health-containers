dofile_once("data/scripts/game_helpers.lua")
dofile_once("data/scripts/lib/utilities.lua")
local const = dofile_once("mods/health_container/files/scripts/const.lua") ---@type const
local utils = dofile_once("mods/health_container/files/scripts/utils.lua") ---@type utils

function item_pickup(entity_item, entity_who_picked, item_name)
  local enemy_max_hp
  local hp_gain_mode = const.enum.HP_GAIN_MODE.CONSTANT
  local comp = EntityGetFirstComponent(entity_item, "VariableStorageComponent", "hp_gain_mode")
  if comp then
    hp_gain_mode = ComponentGetValue2(comp, "value_int")
    comp = EntityGetFirstComponent(entity_item, "VariableStorageComponent", "enemy_max_hp")
    if comp then enemy_max_hp = ComponentGetValue2(comp, "value_float") end
  end

  local damage_model = EntityGetFirstComponent(entity_who_picked, "DamageModelComponent")
  if not damage_model then return end

  local player_hp = ComponentGetValue2(damage_model, "hp")
  local player_max_hp = ComponentGetValue2(damage_model, "max_hp")

  local hp_gain = 0
  local hp_gain_player_scale = ModSettingGet(utils:ResolveModSettingId("hp_gain_player_scale")) --[[@as number]]
  local function get_scaled_hp_gain(hp_gain)
    return hp_gain * (player_max_hp - const.BASE_PLAYER_HP) / const.BASE_PLAYER_HP * hp_gain_player_scale
  end
  if hp_gain_mode == const.enum.HP_GAIN_MODE.CONSTANT then
    hp_gain = utils:ModSettingGet("hp_gain_constant") --[[@as number]]
    hp_gain = hp_gain + get_scaled_hp_gain(hp_gain)
  elseif hp_gain_mode == const.enum.HP_GAIN_MODE.PLAYER_HP_FRACTION then
    hp_gain = player_max_hp * utils:ModSettingGet("hp_gain_fraction_player")
  elseif hp_gain_mode == const.enum.HP_GAIN_MODE.ENEMY_HP_FRACTION then
    hp_gain = utils:ModSettingGet("hp_gain_fraction_enemy_constant")
      + enemy_max_hp * utils:ModSettingGet("hp_gain_fraction_enemy")
    hp_gain = hp_gain + get_scaled_hp_gain(hp_gain)
  end

  local max_hp_gain = ModSettingGet(utils:ResolveModSettingId("max_hp_gain")) --[[@as number]]

  local hp_gain_variation = ModSettingGet(utils:ResolveModSettingId("hp_gain_variation_percentage")) --[[@as number]]
  if hp_gain_variation < 1 then -- 100% means no variation
    hp_gain_variation = utils:TruncateNumber(utils:RandomFloat(hp_gain_variation, 1), 2)
    hp_gain = hp_gain * hp_gain_variation
    max_hp_gain = max_hp_gain * hp_gain_variation
  end

  if max_hp_gain > 0 then
    player_max_hp = player_max_hp + max_hp_gain
    ComponentSetValue2(damage_model, "max_hp", player_max_hp)
  end

  ComponentSetValue2(damage_model, "hp", player_hp + hp_gain)
  GamePrint(string.format("Picked up Health (%.1f)", hp_gain * 25))

  local x, y = EntityGetTransform(entity_item)
  GamePlaySound("mods/health_container/files/audio/health_container_audio.snd", "health_container/hc_heal", x, y)
  shoot_projectile(
    entity_item,
    "mods/health_container/files/entities/particles/health_container_pickup.xml",
    x,
    y,
    0,
    0
  )
  EntityKill(entity_item)
end
