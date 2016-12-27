if SERVER then
	AddCSLuaFile("simfphys/client/killicons.lua")
	AddCSLuaFile("simfphys/client/fonts.lua")
	AddCSLuaFile("simfphys/client/tab.lua")
	AddCSLuaFile("simfphys/client/hud.lua")
	
	AddCSLuaFile("simfphys/anim.lua")
	AddCSLuaFile("simfphys/convars.lua")
	AddCSLuaFile("simfphys/lights.lua")
	AddCSLuaFile("simfphys/rescuespawnlists.lua")
	AddCSLuaFile("simfphys/spawnlist.lua")
	AddCSLuaFile("simfphys/spawnlist_nobones.lua")
	AddCSLuaFile("simfphys/spawnlist_prewarvehicles.lua")
	AddCSLuaFile("simfphys/view.lua")
	
	include("simfphys/server/exitpoints.lua")
	include("simfphys/server/mousesteer.lua")
	include("simfphys/server/resource.lua")
	include("simfphys/server/spawner.lua")
end
	
if CLIENT then
	include("simfphys/client/killicons.lua")
	include("simfphys/client/fonts.lua")
	include("simfphys/client/tab.lua")
	include("simfphys/client/hud.lua")
end

include("simfphys/anim.lua")
include("simfphys/convars.lua")
include("simfphys/lights.lua")
include("simfphys/spawnlist.lua")
include("simfphys/spawnlist_nobones.lua")
include("simfphys/spawnlist_prewarvehicles.lua")
include("simfphys/view.lua")

timer.Simple( 0.5, function()
	include("simfphys/rescuespawnlists.lua")
end)