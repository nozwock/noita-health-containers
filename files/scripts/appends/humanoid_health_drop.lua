local nxml = dofile_once("mods/health_container/files/scripts/lib/nxml/nxml.lua") ---@type nxml

for content in nxml.edit_file("data/entities/base_humanoid.xml") do
  content:add_child(nxml.new_element("LuaComponent", {
    execute_every_n_frame = "-1",
    script_death = "mods/health_container/files/scripts/components/drop_health_container.lua",
    remove_after_executed = "1",
  }))
end
