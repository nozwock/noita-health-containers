ModRegisterAudioEventMappings("mods/health_container/files/audio/audio_events.txt")
ModMaterialsFileAdd("mods/health_container/files/materials.xml")

function OnModInit() dofile_once("mods/health_container/files/scripts/on_init/appends.lua") end
