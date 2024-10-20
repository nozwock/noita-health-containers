dofile_once("data/scripts/game_helpers.lua")
dofile_once("data/scripts/lib/utilities.lua")
local const = dofile_once("mods/health_container/files/scripts/const.lua") ---@type const

function item_pickup(entity_item, entity_who_picked, item_name)
  local function TruncateHpValue(value)
    -- this function reduces inaccuracy building up over time due to how HP is handled and
    -- how this version of lua seems to handle floating point values.
    -- This function truncates values less than 1 HP (<0.04)
    local shifted = value * 100
    local truncated = shifted - (shifted % 4)
    return truncated / 100
  end

  local pos_x, pos_y = EntityGetTransform(entity_item)

  local damagemodels = EntityGetComponent(entity_who_picked, "DamageModelComponent")

  if damagemodels ~= nil then
    for i, v in ipairs(damagemodels) do
      local current_hp = ComponentGetValue2(v, "hp")

      local current_max_hp = ComponentGetValue2(v, "max_hp")
      local heal_amt = 0
      local mode = ModSettingGet("health_container.hp_gain_mode")

      if mode == const.enum.HP_GAIN_MODE.PLAYER_HP_FRACTION then
        heal_amt = current_max_hp * (ModSettingGet("health_container.hp_gain_fraction_player"))
      else
        heal_amt = ModSettingGet("health_container.hp_gain_constant") -- Health values are scaled up by 25 in the UI apparently.
      end

      heal_amt = math.max(heal_amt, 0.04) -- set heal_amt to be at least 1 HP
      local target_hp = TruncateHpValue(current_hp + heal_amt)

      -- handle expansion of max HP:
      local max_incr_amt = ModSettingGet("health_container.max_hp_gain")

      if max_incr_amt > 0 then
        max_incr_amt = math.max(0.04, max_incr_amt) -- set increase amt to at least 1 HP
      end

      local target_max_hp = TruncateHpValue(current_max_hp + max_incr_amt)

      -- Save values
      ComponentSetValue2(v, "max_hp", target_max_hp)

      if target_hp > target_max_hp then target_hp = target_max_hp end
      ComponentSetValue2(v, "hp", target_hp)
      GamePrint(string.format("Picked up Health (%d)", TruncateHpValue(heal_amt) * 25))
      break
    end
  end

  GamePlaySound(
    "mods/health_container/files/audio/health_container_audio.snd",
    "health_container/hc_heal",
    pos_x,
    pos_y
  )
  shoot_projectile(
    entity_item,
    "mods/health_container/files/entities/particles/health_container_pickup.xml",
    pos_x,
    pos_y,
    0,
    0
  )
  EntityKill(entity_item)
end
