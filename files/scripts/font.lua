local nxml = dofile_once("mods/health_container/files/scripts/lib/nxml/nxml.lua")

--- Certified stolen code.
---
--- class to handle font generation, color management, and popup text displays.
---@class font
local font = {}

--- Returns the path to the virtual colored font file, generating it if it doesn't exist.
--- @private
--- @param r string
--- @param g string
--- @param b string
function font:get_path(r, g, b)
  local path = string.format("mods/health_container/vfs/font/%s%s%s.xml", r, g, b)
  if ModDoesFileExist(path) then return path end

  local xml = nxml.parse(ModTextFileGetContent("data/fonts/font_pixel.xml"))
  xml.attr.color_r = r
  xml.attr.color_g = g
  xml.attr.color_b = b
  xml.attr.color_a = "1"
  ModTextFileSetContent(path, tostring(xml))

  return path
end

--- Displays a popup text on the specified entity with customizable scale and color.
--- @param x integer
--- @param y integer
--- @param text string Text to display in the popup.
--- @param scale number Scale factor for the text size. Defaults to 1.
--- @param r number
--- @param g number
--- @param b number
function font:popup(x, y, text, scale, r, g, b)
  scale = scale or 1

  -- Adjust positions
  x = x - (#text * 3 * scale)
  y = y - 7

  ---@param ... number
  ---@return string ...
  local function _nums2string(...)
    local args = { ... } ---@type any[]
    for i = 1, #args do
      args[i] = string.format("%.2f", args[i])
    end
    return unpack(args) --[[@as string]]
  end

  local path = self:get_path(_nums2string(r, g, b))

  local entity = EntityCreateNew("text_popup")
  EntityAddComponent2(entity, "SpriteComponent", {
    image_file = path,
    is_text_sprite = true,
    text = text,
    z_index = -2,
    emissive = true,
  })
  EntityAddComponent2(entity, "LifetimeComponent", {
    lifetime = 60,
    fade_sprites = true,
  })
  EntityAddComponent2(entity, "LuaComponent", {
    script_source_file = "mods/health_container/files/scripts/components/text_popup_anim.lua",
  })
  EntitySetTransform(entity, x, y, 0, scale, scale)
end

return font
