dofile_once("data/scripts/game_helpers.lua")
dofile_once("data/scripts/lib/utilities.lua")

function do_health_drop()
  local entity = GetUpdatedEntityID()
  local x, y = EntityGetTransform(entity)

  if GameGetIsTrailerModeEnabled() then return end

  if math.random() < ModSettingGet("health_container.drop_chance_constant") then
    EntityLoad("mods/health_container/files/entities/items/health_container.xml", x, y - 7)
  end
end

function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items) do_health_drop() end