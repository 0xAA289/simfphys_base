ENT.Type            = "anim"

ENT.PrintName = "Simulated Wheel"
ENT.Author = "Blu"
ENT.Information = "memes"
ENT.Category = "Fun + Games"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

game.AddParticles("particles/vehicle.pcf")
PrecacheParticleSystem("WheelDust")

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 1, "OnGround" )
	self:NetworkVar( "String", 2, "SurfaceMaterial" )
	self:NetworkVar( "Float", 3, "Speed" )
	self:NetworkVar( "Float", 4, "SkidSound" )
	self:NetworkVar( "Float", 5, "GripLoss" )
	self:NetworkVar( "Vector", 6, "SmokeColor" )
end
