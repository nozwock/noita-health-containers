dofile_once("data/scripts/game_helpers.lua")
dofile_once("data/scripts/lib/utilities.lua")
local const = dofile_once("mods/health_container/files/scripts/const.lua") ---@type const
local utils = dofile_once("mods/health_container/files/scripts/utils.lua") ---@type utils
local font = dofile_once("mods/health_container/files/scripts/font.lua") ---@type font

function item_pickup(entity_item, entity_who_picked, item_name)
  local damage_model = EntityGetFirstComponent(entity_who_picked, "DamageModelComponent")
  if not damage_model then return end

  local player_hp = ComponentGetValue2(damage_model, "hp")
  local player_max_hp = ComponentGetValue2(damage_model, "max_hp")

  local player_hp_gain_scale = utils:ModSettingGetNumber("hp_gain.player_max_hp_scale")

  ---Scale `hp_gain` with player's maximum HP.
  ---@param hp_gain number
  ---@return number
  local function scale_hp_gain(hp_gain)
    return hp_gain * (player_max_hp - const.BASE_PLAYER_HP) / const.BASE_PLAYER_HP * player_hp_gain_scale
  end

  local hp_gain_mode = utils:ModSettingGetNumber("hp_gain.mode")

  local enemy_max_hp
  local vsc = utils:EntityGetFirstVSC(entity_item, "enemy_max_hp")
  if vsc then
    enemy_max_hp = ComponentGetValue2(vsc, "value_float")
  elseif hp_gain_mode == const.enum.HP_GAIN_MODE.ENEMY_HP_FRACTION then
    hp_gain_mode = const.enum.HP_GAIN_MODE.CONSTANT -- fallback
  end

  local hp_gain = 0
  if hp_gain_mode == const.enum.HP_GAIN_MODE.CONSTANT then
    hp_gain = utils:ModSettingGetNumber("hp_gain.constant_hp")
    hp_gain = hp_gain + scale_hp_gain(hp_gain)
  elseif hp_gain_mode == const.enum.HP_GAIN_MODE.PLAYER_HP_FRACTION then
    hp_gain = player_max_hp * utils:ModSettingGetNumber("hp_gain.player_hp_fraction")
  elseif hp_gain_mode == const.enum.HP_GAIN_MODE.ENEMY_HP_FRACTION then
    hp_gain = utils:ModSettingGet("hp_gain.enemy_base_hp")
      + enemy_max_hp * utils:ModSettingGetNumber("hp_gain.enemy_hp_fraction")
    hp_gain = hp_gain + scale_hp_gain(hp_gain)
  end

  local max_hp_gain = utils:ModSettingGetNumber("max_hp_gain")

  local hp_gain_variation = utils:ModSettingGetNumber("hp_gain_variation_percentage")
  if hp_gain_variation < 1 then -- 100% means no variation
    hp_gain_variation = utils:RandomFloat(hp_gain_variation, 1)
    hp_gain = hp_gain * hp_gain_variation
    max_hp_gain = max_hp_gain * hp_gain_variation
  end

  if max_hp_gain > 0 then
    player_max_hp = player_max_hp + max_hp_gain
    ComponentSetValue2(damage_model, "max_hp", player_max_hp)
  end

  ComponentSetValue2(damage_model, "hp", player_hp + hp_gain)
  local x, y = EntityGetFirstHitboxCenter(entity_item)
  font:popup(x, y, string.format("+ %.1f", hp_gain * 25), 0.5, 0.45, 1, 0.23)

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
