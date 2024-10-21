dofile("data/scripts/lib/mod_settings.lua")

-- Use ModSettingGet() in the game to query settings.
local MOD_ID = "health_container"

---@param local_id string
local function ResolveModSettingId(local_id) return MOD_ID .. "." .. local_id end

---@param fn fun(a, b):boolean
---@param a any
---@param ... any
local function All(fn, a, ...)
  for _, b in ipairs({ ... }) do
    if not fn(a, b) then return false end
  end
  return true
end

---@param fn fun(a, b):boolean
---@param a any
---@param ... any
local function Any(fn, a, ...)
  for _, b in ipairs({ ... }) do
    if fn(a, b) then return true end
  end
  return false
end

---@param number number
---@param decimal? integer
local function TruncateNumber(number, decimal)
  if decimal <= 0 then decimal = nil end
  local pow = 10 ^ (decimal or 0)
  return math.floor(number * pow) / pow
end

---@param number number
local function FloorSliderValueInteger(number)
  return math.floor(number + 0.5) -- Because the slider can return ranging from 1.8 to 2.3 while showing 2, just as an example
end

---@param number number
---@param decimal? integer
local function FloorSliderValueFloat(number, decimal)
  if decimal <= 0 or not decimal then decimal = 0 end
  local pow = 10 ^ (decimal + 1)
  return TruncateNumber(number + 5 / pow, decimal)
end

---@class enum_variant_detail
---@field ui_name string
---@field ui_description string
---@alias enum_variant integer|string
---@alias enum_variant_details { [enum_variant]: enum_variant_detail }

---Order of variants determines the order.
---
---Very little sanity checks in place. Don't pass in empty lists, etc.
---@param variants enum_variant[]
---@param variant_details enum_variant_details
local function CreateGuiSettingEnum(variants, variant_details)
  return function(mod_id, gui, in_main_menu, im_id, setting)
    local setting_id = mod_setting_get_id(mod_id, setting)
    local prev_value = ModSettingGetNextValue(setting_id) or setting.value_default

    GuiLayoutBeginHorizontal(gui, mod_setting_group_x_offset, 0, true)

    local value = nil

    if variant_details[prev_value] == nil then prev_value = setting.value_default end

    if GuiButton(gui, im_id, 0, 0, setting.ui_name .. ": " .. variant_details[prev_value].ui_name) then
      for i, v in ipairs(variants) do
        if prev_value == v then
          value = variants[i % #variants + 1]
          break
        end
      end
    end
    local right_clicked, hovered = select(2, GuiGetPreviousWidgetInfo(gui))
    if right_clicked then
      value = setting.value_default
      GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
    end
    if hovered and is_visible_string(variant_details[prev_value].ui_description) then
      GuiTooltip(gui, variant_details[prev_value].ui_description, "")
    end

    GuiLayoutEnd(gui)

    if value ~= nil then
      ModSettingSetNextValue(setting_id, value, false)
      mod_setting_handle_change_callback(mod_id, gui, in_main_menu, setting, prev_value, value)
    end
  end
end

---@param mod_id string
---@param gui gui
---@param in_main_menu boolean
---@param im_id integer
---@param setting table
---@param value_formatting string
---@param value_display_multiplier? number
---@param value_map? fun(value:number):number
local function ModSettingSlider(
  mod_id,
  gui,
  in_main_menu,
  im_id,
  setting,
  value_formatting,
  value_display_multiplier,
  value_map
)
  local empty = "data/ui_gfx/empty.png"
  local setting_id = mod_setting_get_id(mod_id, setting)
  local value = ModSettingGetNextValue(mod_setting_get_id(mod_id, setting))
  if type(value) ~= "number" then value = setting.value_default or 0.0 end

  GuiLayoutBeginHorizontal(gui, mod_setting_group_x_offset, 0, true)

  if setting.value_min == nil or setting.value_max == nil or setting.value_default == nil then
    GuiText(gui, 0, 0, setting.ui_name .. " - not all required values are defined in setting definition")
    return
  end

  GuiText(gui, 0, 0, "")
  local x_start, y_start = select(4, GuiGetPreviousWidgetInfo(gui))

  GuiIdPushString(gui, MOD_ID .. setting_id)

  local value_new = GuiSlider(
    gui,
    im_id,
    -2,
    0,
    setting.ui_name,
    value,
    setting.value_min,
    setting.value_max,
    setting.value_default,
    setting.value_slider_multiplier or 1, -- This affects the steps for slider aswell, so it's not just a visual thing.
    " ",
    64
  )
  if value_map then value_new = value_map(value_new) end

  local x_end, _, w = select(4, GuiGetPreviousWidgetInfo(gui))
  local display_text = string.format(value_formatting, value_new * (value_display_multiplier or 1))
  local tw = GuiGetTextDimensions(gui, display_text)
  GuiImageNinePiece(gui, im_id + 1, x_start, y_start, x_end - x_start + w + tw - 2, 8, 0, empty, empty)
  local hovered = select(3, GuiGetPreviousWidgetInfo(gui))

  mod_setting_tooltip(mod_id, gui, in_main_menu, setting)

  if hovered then
    GuiColorSetForNextWidget(gui, 0.8, 0.8, 0.8, 1)
    GuiText(gui, 0, 0, display_text)
  end

  GuiIdPop(gui)
  GuiLayoutEnd(gui)

  if value ~= value_new then
    ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), value_new, false)
    mod_setting_handle_change_callback(mod_id, gui, in_main_menu, setting, value, value_new)
  end
end

local function mod_setting_integer(mod_id, gui, in_main_menu, im_id, setting)
  ModSettingSlider(
    mod_id,
    gui,
    in_main_menu,
    im_id,
    setting,
    setting.value_display_formatting or "%d",
    setting.value_display_multiplier,
    function(value) return FloorSliderValueInteger(value) end
  )
end

local function mod_setting_float(mod_id, gui, in_main_menu, im_id, setting)
  ModSettingSlider(
    mod_id,
    gui,
    in_main_menu,
    im_id,
    setting,
    setting.value_display_formatting or "%.1f",
    setting.value_display_multiplier,
    function(value) return FloorSliderValueFloat(value, setting.value_precision) end
  )
end

local DROP_CHANCE_MODE = { CONSTANT = 1, ENEMY_SCALE = 2 }
local HP_GAIN_MODE = { CONSTANT = 1, PLAYER_HP_FRACTION = 2, ENEMY_HP_FRACTION = 3 }

mod_settings_version = 1

mod_settings = {
  {
    category_id = "drop_chance",
    ui_name = "Drop Chance",
    ui_description = "The likelihood of a health container dropping when defeating an enemy.",
    foldable = false,
    _folded = false,
    settings = {
      {
        id = "drop_chance.mode",
        ui_name = "Mode",
        value_default = DROP_CHANCE_MODE.CONSTANT,
        ui_fn = CreateGuiSettingEnum({ DROP_CHANCE_MODE.CONSTANT, DROP_CHANCE_MODE.ENEMY_SCALE }, {
          [DROP_CHANCE_MODE.CONSTANT] = {
            ui_name = "Constant",
            ui_description = "The drop chance remains unchanged.",
          },
          [DROP_CHANCE_MODE.ENEMY_SCALE] = {
            ui_name = "Enemy HP Based",
            ui_description = "The drop chance varies according to enemy health.",
          },
        }),
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "drop_chance.constant_chance",
        ui_name = "Chance",
        value_default = 0.05,
        value_min = 0.01,
        value_max = 1,
        value_precision = 2,
        value_display_multiplier = 100,
        value_display_formatting = " %d%%",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("drop_chance.mode")) == DROP_CHANCE_MODE.CONSTANT then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "drop_chance.enemy_base_chance",
        ui_name = "Base Chance",
        ui_description = "The drop chance for an enemy with HP equal to 'Base Enemy HP'.",
        value_default = 0.02,
        value_min = 0.01,
        value_max = 1,
        value_precision = 2,
        value_display_multiplier = 100,
        value_display_formatting = " %d%%",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("drop_chance.mode")) == DROP_CHANCE_MODE.ENEMY_SCALE then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "drop_chance.enemy_base_hp",
        ui_name = "Base Enemy HP",
        ui_description = "The drop chance will vary based on how much the enemy's HP\ndiffers from this base value.\nDefault value of 25 is equal to about 10 Hämis or 1 Acid Slime.",
        value_default = 1,
        value_min = 0.04,
        value_max = 4,
        value_precision = 2,
        value_display_multiplier = 25,
        value_display_formatting = " %.1f HP",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("drop_chance.mode")) == DROP_CHANCE_MODE.ENEMY_SCALE then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
    },
  },
  {
    category_id = "hp_gain",
    ui_name = "HP Gain",
    ui_description = "By how much the player heals with each health container pickup.",
    foldable = false,
    _folded = false,
    settings = {
      {
        id = "hp_gain.mode",
        ui_name = "Mode",
        value_default = HP_GAIN_MODE.CONSTANT,
        ui_fn = CreateGuiSettingEnum(
          { HP_GAIN_MODE.CONSTANT, HP_GAIN_MODE.PLAYER_HP_FRACTION, HP_GAIN_MODE.ENEMY_HP_FRACTION },
          {
            [HP_GAIN_MODE.CONSTANT] = {
              ui_name = "Constant",
              ui_description = "Heals a fixed amount of HP with each pickup.",
            },
            [HP_GAIN_MODE.PLAYER_HP_FRACTION] = {
              ui_name = "Player HP Based",
              ui_description = "Heals a percentage of the player's max HP with each pickup.",
            },
            [HP_GAIN_MODE.ENEMY_HP_FRACTION] = {
              ui_name = "Enemy HP Based",
              ui_description = "Heals a percentage of the enemy's max HP with each pickup.",
            },
          }
        ),
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "hp_gain.constant_hp",
        ui_name = "Amount",
        value_default = 0.2,
        value_min = 0.04,
        value_max = 4,
        value_precision = 2,
        value_display_multiplier = 25,
        value_display_formatting = " %.1f HP",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("hp_gain.mode")) == HP_GAIN_MODE.CONSTANT then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "hp_gain.player_hp_fraction",
        ui_name = "HP Fraction",
        value_default = 0.05,
        value_min = 0.01,
        value_max = 1,
        value_precision = 2,
        value_display_multiplier = 100,
        value_display_formatting = " %d%%",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("hp_gain.mode")) == HP_GAIN_MODE.PLAYER_HP_FRACTION then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "hp_gain.enemy_base_hp",
        ui_name = "Base Amount",
        ui_description = "The amount of additional HP to be healed, along\nwith a percentage of the enemy's max HP.",
        value_default = 0.4,
        value_min = 0.04,
        value_max = 4,
        value_precision = 2,
        value_display_multiplier = 25,
        value_display_formatting = " %.1f HP",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("hp_gain.mode")) == HP_GAIN_MODE.ENEMY_HP_FRACTION then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "hp_gain.enemy_hp_fraction",
        ui_name = "HP Fraction",
        ui_description = "The percentage of enemy's max HP to be healed.",
        value_default = 0.4,
        value_min = 0.01,
        value_max = 1,
        value_precision = 2,
        value_display_multiplier = 100,
        value_display_formatting = " %d%%",
        ui_fn = function(...)
          if ModSettingGetNextValue(ResolveModSettingId("hp_gain.mode")) == HP_GAIN_MODE.ENEMY_HP_FRACTION then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      { -- HP_GAIN + HP_GAIN * ((MAX_HP - BASE_HP) / BASE_HP) * SCALE
        id = "hp_gain.player_max_hp_scale",
        ui_name = "Player HP Scale",
        ui_description = "The extent to which the healing amount\nscales with the player's maximum HP.",
        value_default = 0.4,
        value_min = 0,
        value_max = 2,
        value_precision = 2,
        value_display_formatting = " %.2fx",
        ui_fn = function(...)
          if
            Any(
              function(a, b) return a == b end,
              ModSettingGetNextValue(ResolveModSettingId("hp_gain.mode")),
              HP_GAIN_MODE.CONSTANT,
              HP_GAIN_MODE.ENEMY_HP_FRACTION
            )
          then
            mod_setting_float(...)
          end
        end,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
    },
  },
  {
    id = "max_hp_gain",
    ui_name = "Max HP Gain",
    ui_description = "The amount by which the player's maximum HP\nis increased upon picking up a health container.",
    value_default = 0,
    value_min = 0,
    value_max = 4,
    value_precision = 2,
    value_display_multiplier = 25,
    value_display_formatting = " %.1f HP",
    ui_fn = mod_setting_float,
    scope = MOD_SETTING_SCOPE_RUNTIME,
  },
  {
    id = "hp_gain_variation_percentage",
    ui_name = "HP Gain Variation",
    ui_description = "Randomize the amount of HP healed between a set percentage and 100%.",
    value_default = 0.6,
    value_min = 0,
    value_max = 1,
    value_precision = 2,
    value_display_multiplier = 100,
    value_display_formatting = " %d%%",
    ui_fn = mod_setting_float,
    scope = MOD_SETTING_SCOPE_RUNTIME,
  },
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate(init_scope)
  local old_version = mod_settings_get_version(MOD_ID) -- This can be used to migrate some settings between mod versions.
  mod_settings_update(MOD_ID, mod_settings, init_scope)
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
  -- if (not DebugGetIsDevBuild()) then --if these lines are enabled, the menu only works in noita_dev.exe.
  -- 	return 0
  -- end

  return mod_settings_gui_count(MOD_ID, mod_settings)
end

function ModSettingsGui(gui, in_main_menu) mod_settings_gui(MOD_ID, mod_settings, gui, in_main_menu) end
