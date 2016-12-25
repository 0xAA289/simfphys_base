
TOOL.Category		= "simfphys"
TOOL.Name			= "#Suspension Editor"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "constant_f" ] = 25000
TOOL.ClientConVar[ "constant_r" ] = 25000

TOOL.ClientConVar[ "height_f" ] = 0
TOOL.ClientConVar[ "height_r" ] = 0

TOOL.ClientConVar[ "damping_f" ] = 2500
TOOL.ClientConVar[ "damping_r" ] = 2500


if CLIENT then
	language.Add( "tool.simfphyssuspensioneditor.name", "simfphys suspension editor" )
	language.Add( "tool.simfphyssuspensioneditor.desc", "A tool used to edit suspension on simfphys vehicles" )
	language.Add( "tool.simfphyssuspensioneditor.0", "Left click apply settings. Reload to reset" )
	language.Add( "tool.simfphyssuspensioneditor.1", "Left click apply settings. Reload to reset" )
end
function TOOL:LeftClick( trace )
	local ent = trace.Entity
	
	if (!IsValid(ent)) then return false end
	
	local IsVehicle = ent:GetClass() == "gmod_sent_vehicle_fphysics_base"
	
	if (!IsVehicle) then return false end
	
	local data = {
		[1] = {tonumber( self:GetClientInfo( "constant_f" ) ),tonumber( self:GetClientInfo( "damping_f" ) )},
		[2] = {tonumber( self:GetClientInfo( "constant_f" ) ),tonumber( self:GetClientInfo( "damping_f" ) )},
		[3] = {tonumber( self:GetClientInfo( "constant_r" ) ),tonumber( self:GetClientInfo( "damping_r" ) )},
		[4] = {tonumber( self:GetClientInfo( "constant_r" ) ),tonumber( self:GetClientInfo( "damping_r" ) )}
	}
	
	local elastics = ent.Elastics
	if (elastics) then
		for i = 1, table.Count( elastics ) do
			local elastic = elastics[i]
			if (ent.StrengthenSuspension == true) then
				if (IsValid(elastic)) then
					elastic:Fire( "SetSpringConstant", data[i][1] * 0.5, 0 )
					elastic:Fire( "SetSpringDamping", data[i][2] * 0.5, 0 )
				end
				local elastic2 = elastics[i * 10]
				if (IsValid(elastic2)) then
					elastic2:Fire( "SetSpringConstant", data[i][1] * 0.5, 0 )
					elastic2:Fire( "SetSpringDamping", data[i][2] * 0.5, 0 )
				end
			else
				if (IsValid(elastic)) then
					elastic:Fire( "SetSpringConstant", data[i][1], 0 )
					elastic:Fire( "SetSpringDamping", data[i][2], 0 )
				end
			end
		end
	end
	
	ent:SetFrontSuspensionHeight( tonumber( self:GetClientInfo( "height_f" ) ) )
	ent:SetRearSuspensionHeight( tonumber( self:GetClientInfo( "height_r" ) ) )

	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Reload( trace )
	local ent = trace.Entity
	local ply = self:GetOwner()
	
	if (!IsValid(ent)) then return false end
	
	local IsVehicle = ent:GetClass() == "gmod_sent_vehicle_fphysics_base"
	
	if (!IsVehicle) then return false end
	
	if (SERVER) then
		local vname = ent:GetSpawn_List()
		local VehicleList = list.Get( "simfphys_vehicles" )[vname]
		
		local data = {
			[1] = {VehicleList.Members.FrontConstant,VehicleList.Members.FrontDamping,VehicleList.Members.FrontHeight},
			[2] = {VehicleList.Members.FrontConstant,VehicleList.Members.FrontDamping,VehicleList.Members.FrontHeight},
			[3] = {VehicleList.Members.RearConstant,VehicleList.Members.RearDamping,VehicleList.Members.RearHeight},
			[4] = {VehicleList.Members.RearConstant,VehicleList.Members.RearDamping,VehicleList.Members.RearHeight},
		}
		
		local elastics = ent.Elastics
		if (elastics) then
			for i = 1, table.Count( elastics ) do
				local elastic = elastics[i]
				if (ent.StrengthenSuspension == true) then
					if (IsValid(elastic)) then
						elastic:Fire( "SetSpringConstant", data[i][1] * 0.5, 0 )
						elastic:Fire( "SetSpringDamping", data[i][2] * 0.5, 0 )
					end
					local elastic2 = elastics[i * 10]
					if (IsValid(elastic2)) then
						elastic2:Fire( "SetSpringConstant", data[i][1] * 0.5, 0 )
						elastic2:Fire( "SetSpringDamping", data[i][2] * 0.5, 0 )
					end
				else
					if (IsValid(elastic)) then
						elastic:Fire( "SetSpringConstant", data[i][1], 0 )
						elastic:Fire( "SetSpringDamping", data[i][2], 0 )
					end
				end
			end
		end
		ent:SetFrontSuspensionHeight( 0 )
		ent:SetRearSuspensionHeight( 0 )
	end
	
	return true
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#tool.simfphyssuspensioneditor.name", Description = "#tool.simfphyssuspensioneditor.desc" } )
	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "simfphys", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )
	
	panel:AddControl( "Label",  { Text = "" } )
	panel:AddControl( "Label",  { Text = "--- Front ---" } )
	panel:AddControl( "Slider", 
	{
		Label 	= "Front Height",
		Type 	= "Float",
		Min 	= "-1",
		Max 	= "1",
		Command = "simfphyssuspensioneditor_height_f"
	})
	panel:AddControl( "Slider", 
	{
		Label 	= "Front Constant",
		Type 	= "Float",
		Min 	= "0",
		Max 	= "50000",
		Command = "simfphyssuspensioneditor_constant_f"
	})
	panel:AddControl( "Slider", 
	{
		Label 	= "Front Damping",
		Type 	= "Float",
		Min 	= "0",
		Max 	= "5000",
		Command = "simfphyssuspensioneditor_damping_f"
	})
	panel:AddControl( "Label",  { Text = "" } )
	panel:AddControl( "Label",  { Text = "--- Rear ---" } )
	panel:AddControl( "Slider", 
	{
		Label 	= "Rear Height",
		Type 	= "Float",
		Min 	= "-1",
		Max 	= "1",
		Command = "simfphyssuspensioneditor_height_r"
	})
	panel:AddControl( "Slider", 
	{
		Label 	= "Rear Constant",
		Type 	= "Float",
		Min 	= "0",
		Max 	= "50000",
		Command = "simfphyssuspensioneditor_constant_r"
	})
	panel:AddControl( "Slider", 
	{
		Label 	= "Rear Damping",
		Type 	= "Float",
		Min 	= "0",
		Max 	= "5000",
		Command = "simfphyssuspensioneditor_damping_r"
	})
end
