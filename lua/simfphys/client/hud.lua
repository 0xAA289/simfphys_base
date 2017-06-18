local screenw = ScrW()
local screenh = ScrH()
local Widescreen = (screenw / screenh) > (4 / 3)
local sizex = screenw * (Widescreen and 1 or 1.32)
local sizey = screenh
local xpos = sizex * 0.02
local ypos = sizey * 0.8
local x = xpos * (Widescreen and 43.5 or 32)
local y = ypos * 1.015
local radius = 0.085 * sizex
local startang = 105

local lights_on = Material( "simfphys/hud/low_beam_on" )
local lights_on2 = Material( "simfphys/hud/high_beam_on" )
local lights_off = Material( "simfphys/hud/low_beam_off" )
local fog_on = Material( "simfphys/hud/fog_light_on" )
local fog_off = Material( "simfphys/hud/fog_light_off" )
local cruise_on = Material( "simfphys/hud/cc_on" )
local cruise_off = Material( "simfphys/hud/cc_off" )
local hbrake_on = Material( "simfphys/hud/handbrake_on" )
local hbrake_off = Material( "simfphys/hud/handbrake_off" )
local HUD_1 = Material( "simfphys/hud/hud" )
local HUD_2 = Material( "simfphys/hud/hud_center" )
local HUD_3 = Material( "simfphys/hud/hud_center_red" )
local ForceSimpleHud = not file.Exists( "materials/simfphys/hud/hud.vmt", "GAME" ) -- lets check if the background material exists, if not we will force the old hud to prevent fps drop

local ShowHud = false
local ShowHud_ms = false
local AltHud = false
local AltHudarcs = false
local Hudmph = false
local Hudreal = false
local isMouseSteer = false
local hasCounterSteerEnabled = false
local slushbox = false

local turnmenu = KEY_COMMA

local ms_sensitivity = 1
local ms_fade = 1
local ms_deadzone = 1.5
local ms_exponent = 2
local ms_key_freelook = KEY_Y

cvars.AddChangeCallback( "cl_simfphys_hud", function( convar, oldValue, newValue ) ShowHud = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_ms_hud", function( convar, oldValue, newValue ) ShowHud_ms = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_althud", function( convar, oldValue, newValue ) AltHud = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_althud_arcs", function( convar, oldValue, newValue ) AltHudarcs = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_hudmph", function( convar, oldValue, newValue ) Hudmph = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_hudrealspeed", function( convar, oldValue, newValue ) Hudreal = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_mousesteer", function( convar, oldValue, newValue ) isMouseSteer = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_ctenable", function( convar, oldValue, newValue ) hasCounterSteerEnabled = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_auto", function( convar, oldValue, newValue ) slushbox = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_ms_sensitivity", function( convar, oldValue, newValue )  ms_sensitivity = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_return", function( convar, oldValue, newValue )  ms_fade = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_deadzone", function( convar, oldValue, newValue )  ms_deadzone = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_exponent", function( convar, oldValue, newValue ) ms_exponent = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_keyfreelook", function( convar, oldValue, newValue ) ms_key_freelook = tonumber( newValue ) end)

cvars.AddChangeCallback( "cl_simfphys_key_turnmenu", function( convar, oldValue, newValue ) turnmenu = tonumber( newValue ) end)

ShowHud = GetConVar( "cl_simfphys_hud" ):GetBool()
ShowHud_ms = GetConVar( "cl_simfphys_ms_hud" ):GetBool()
AltHud = GetConVar( "cl_simfphys_althud" ):GetBool()
AltHudarcs = GetConVar( "cl_simfphys_althud_arcs" ):GetBool()
Hudmph = GetConVar( "cl_simfphys_hudmph" ):GetBool()
Hudreal = GetConVar( "cl_simfphys_hudrealspeed" ):GetBool()
isMouseSteer = GetConVar( "cl_simfphys_mousesteer" ):GetBool()
hasCounterSteerEnabled = GetConVar( "cl_simfphys_ctenable" ):GetBool()
slushbox = GetConVar( "cl_simfphys_auto" ):GetBool()

turnmenu = GetConVar( "cl_simfphys_key_turnmenu" ):GetInt()

ms_sensitivity = GetConVar( "cl_simfphys_ms_sensitivity" ):GetFloat()
ms_fade = GetConVar( "cl_simfphys_ms_return" ):GetFloat()
ms_deadzone = GetConVar( "cl_simfphys_ms_deadzone" ):GetFloat()
ms_exponent = GetConVar( "cl_simfphys_ms_exponent" ):GetFloat()
ms_key_freelook = GetConVar( "cl_simfphys_ms_keyfreelook" ):GetInt()

local ms_pos_x = 0
local sm_throttle = 0

local function DrawCircle( X, Y, radius )
	local segmentdist = 360 / ( 2 * math.pi * radius / 2 )
	
	for a = 0, 360 - segmentdist, segmentdist do
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
	end
end

hook.Add( "StartCommand", "simfphysmove", function( ply, cmd )
	if ply ~= LocalPlayer() then return end
	
	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then return end
	
	if isMouseSteer then
		local freelook = input.IsButtonDown( ms_key_freelook )
		ply.Freelook = freelook
		if not freelook then 
			local frametime = FrameTime()
			
			local ms_delta_x = cmd:GetMouseX()
			local ms_return = ms_fade * frametime
			
			local Moving = math.abs(ms_delta_x) > 0
			
			ms_pos_x = Moving and math.Clamp(ms_pos_x + ms_delta_x * frametime * 0.05 * ms_sensitivity,-1,1) or (ms_pos_x + math.Clamp(-ms_pos_x,-ms_return,ms_return))
			
			SteerVehicle = ((math.max( math.abs(ms_pos_x) - ms_deadzone / 16, 0) ^ ms_exponent) / (1 - ms_deadzone / 16))  * ((ms_pos_x > 0) and 1 or -1)
			
		end
	else
		SteerVehicle = 0
	end
	
	net.Start( "simfphys_mousesteer" )
		net.WriteEntity( vehicle )
		net.WriteFloat( SteerVehicle )
	net.SendToServer()
end)

local function drawsimfphysHUD(vehicle)
	if isMouseSteer and ShowHud_ms then
		local MousePos = ms_pos_x
		local m_size = sizex * 0.15
		
		draw.SimpleText( "V", "simfphysfont", sizex * 0.5 + MousePos * m_size - 1, sizey * 0.45, Color( 240, 230, 200, 255 ), 1, 1 )
		draw.SimpleText( "[", "simfphysfont", sizex * 0.5 - m_size * 1.05, sizey * 0.45, Color( 240, 230, 200, 180 ), 1, 1 )
		draw.SimpleText( "]", "simfphysfont", sizex * 0.5 + m_size * 1.05, sizey * 0.45, Color( 240, 230, 200, 180 ), 1, 1 )
		
		if (ms_deadzone > 0) then
			draw.SimpleText( "^", "simfphysfont", sizex * 0.5 - (ms_deadzone / 16) * m_size, sizey * 0.453, Color( 240, 230, 200, 180 ), 1, 2 )
			draw.SimpleText( "^", "simfphysfont", sizex * 0.5 + (ms_deadzone / 16) * m_size, sizey * 0.453, Color( 240, 230, 200, 180 ), 1, 2 )
		else
			draw.SimpleText( "^", "simfphysfont", sizex * 0.5, sizey * 0.453, Color( 240, 230, 200, 180 ), 1, 2 )
		end
	end
	
	if not ShowHud then return end
	
	local maxrpm = vehicle:GetLimitRPM()
	local rpm = vehicle:GetRPM()
	local throttle = math.Round(vehicle:GetThrottle() * 100,0)
	local revlimiter = vehicle:GetRevlimiter() and (maxrpm > 2500) and (throttle > 0)
	
	local powerbandend = math.min(vehicle:GetPowerBandEnd(), maxrpm)
	local redline = math.max(rpm - powerbandend,0) / (maxrpm - powerbandend)
	
	local Active = vehicle:GetActive() and "" or "!"
	local speed = vehicle:GetVelocity():Length()
	local mph = math.Round(speed * 0.0568182,0)
	local kmh = math.Round(speed * 0.09144,0)
	local wiremph = math.Round(speed * 0.0568182 * 0.75,0)
	local wirekmh = math.Round(speed * 0.09144 * 0.75,0)
	local cruisecontrol = vehicle:GetIsCruiseModeOn()
	local gear = vehicle:GetGear()
	local DrawGear = not slushbox and (gear == 1 and "R" or gear == 2 and "N" or (gear - 2)) or (gear == 1 and "R" or gear == 2 and "N" or "(".. (gear - 2)..")")
	
	if AltHud and not ForceSimpleHud then
		local LightsOn = vehicle:GetLightsEnabled()
		local LampsOn = vehicle:GetLampsEnabled()
		local FogLightsOn = vehicle:GetFogLightsEnabled()
		local HandBrakeOn = vehicle:GetHandBrakeEnabled()
		
		s_smoothrpm = s_smoothrpm or 0
		s_smoothrpm = math.Clamp(s_smoothrpm + (rpm - s_smoothrpm) * 0.3,0,maxrpm)
		
		local endang = startang + math.Round( (s_smoothrpm/maxrpm) * 255, 0)
		local c_ang = math.cos( math.rad(endang) )
		local s_ang = math.sin( math.rad(endang) )
		local ang_pend = startang + math.Round( (powerbandend / maxrpm) * 255, 0)
		local r_rpm = math.floor(maxrpm / 1000) * 1000
		local in_red = s_smoothrpm < powerbandend
		
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		local mat = LightsOn and (LampsOn and lights_on2 or lights_on) or lights_off
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x * 1.119, y * 0.98, sizex * 0.014, sizex * 0.014 )
		
		local mat = FogLightsOn and fog_on or fog_off
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x * 1.116, y * 0.92, sizex * 0.018, sizex * 0.018 )
		
		local mat = cruisecontrol and cruise_on or cruise_off
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x * 1.116, y * 0.861, sizex * 0.02, sizex * 0.02 )
		
		local mat = HandBrakeOn and hbrake_on or hbrake_off
		surface.SetMaterial( mat )
		surface.DrawTexturedRect( x * 1.1175, y * 0.815, sizex * 0.018, sizex * 0.018 )
		
		surface.SetMaterial( HUD_1 )
		surface.DrawTexturedRect( x - radius, y - radius + 1, radius * 2, radius * 2)
		
		surface.SetMaterial( in_red and HUD_2 or HUD_3 )
		surface.DrawTexturedRect( x - radius, y - radius + 1, radius * 2, radius * 2)
		
		draw.NoTexture()
		
		local step = 0
		for i = 0,maxrpm,250 do
			step = step + 1
			
			local anglestep = (255 / maxrpm) * i
			
			local n_col_on
			local n_col_off
			if (i < powerbandend) then
				n_col_off = Color(150, 150, 150, 150)
				n_col_on = Color(255, 255, 255, 255)
			else
				n_col_off = Color( 150, 0, 0, 150)
				n_col_on = Color( 255, 0, 0, 255 )
			end
			local u_col = (s_smoothrpm > i) and n_col_on or n_col_off
			surface.SetDrawColor( u_col )
			
			local cos_a = math.cos( math.rad(startang + anglestep) )
			local sin_a = math.sin( math.rad(startang + anglestep) )
			
			if step > 4 then
				step = 1
				surface.DrawLine( x + cos_a * radius / 1.3, y + sin_a * radius / 1.3, x + cos_a * radius, y + sin_a * radius)
				local printnumber = tostring(i / 1000)
				draw.SimpleText(printnumber, "simfphysfont3", x + cos_a * radius / 1.5, y + sin_a * radius / 1.5,u_col, 1, 1 )
			else
				surface.DrawLine( x + cos_a * radius / 1.05, y + sin_a * radius / 1.05, x + cos_a * radius, y + sin_a * radius)
			end
		end
		
		local center_ncol = in_red and Color(0,254,235,200) or Color( 255, 0, 0, 255 )
		
		surface.SetDrawColor( in_red and Color(255,255,255,255) or Color( 255, 0, 0, 255 ) )
		surface.DrawLine( x + c_ang * radius / 3.5, y + s_ang * radius / 3.5, x + c_ang * radius, y + s_ang * radius)
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		if AltHudarcs then
			
			draw.Arc(x,y,radius,radius / 6.66,startang,math.min(endang,ang_pend),1,Color(255,255,255,150),true)
			
			-- middle
			--draw.Arc(x,y,radius / 3.5,radius / 66,startang,360,15,Color(255,255,255,50),true)
			
			-- outer
			--draw.Arc(x,y,radius,radius / 6.66,startang,ang_pend,1,Color(150,150,150,50),true)
			draw.Arc(x,y,radius,radius / 6.66,ang_pend,360,1,Color(120,0,0,230),true)
			
			draw.Arc(x,y,radius,radius / 6.66,math.Round(ang_pend - 1,0),startang + (s_smoothrpm / maxrpm) * 255,1,Color(255,0,0,140),true)
			
			--inner
			--draw.Arc(x,y,radius / 5,radius / 70,0,360,15,center_ncol,true)
		end
		
		draw.SimpleText( (gear == 1 and "R" or gear == 2 and "N" or (gear - 2)), "simfphysfont2", x * 0.999, y * 0.996, center_ncol, 1, 1 )
		
		local print_text = Hudmph and "MPH" or "KM/H"
		draw.SimpleText( print_text, "simfphysfont3", x * 1.08, y * 1.03, Color(255,255,255,50), 1, 1 )
		
		local printspeed = Hudmph and (Hudreal and mph or wiremph) or (Hudreal and kmh or wirekmh)
		
		local digit_1  =  printspeed % 10
		local digit_2 =  (printspeed - digit_1) % 100
		local digit_3  = (printspeed - digit_1 - digit_2) % 1000
		
		local col_on = Color(150,150,150,50)
		local col_off = Color(255,255,255,150)
		local col1 = (printspeed > 0) and col_off or col_on
		local col2 = (printspeed >= 10) and col_off or col_on
		local col3 = (printspeed >= 100) and col_off or col_on
		
		draw.SimpleText( digit_1, "simfphysfont4", x * 1.08, y * 1.11, col1, 1, 1 )
		draw.SimpleText( digit_2/ 10, "simfphysfont4", x * 1.045, y * 1.11, col2, 1, 1 )
		draw.SimpleText( digit_3 / 100, "simfphysfont4", x * 1.01, y * 1.11, col3, 1, 1 )
		
		sm_throttle = sm_throttle + (throttle - sm_throttle) * 0.1
		local t_size = (sizey * 0.1)
		draw.RoundedBox( 0, x * 1.12, y * 1.06, sizex * 0.007, sizey * 0.1, Color(150,150,150,50) )
		draw.RoundedBox( 0, x * 1.12, y * 1.06 + t_size - t_size * math.min(sm_throttle / 100,1), sizex * 0.007, t_size * math.min(sm_throttle / 100,1), Color(255,255,255,150) )
		
		return
	end

	if (cruisecontrol) then
		draw.SimpleText( "cruise", "simfphysfont", xpos + sizex * 0.115, ypos + sizey * 0.035, Color( 255, 127, 0, 255 ), 2, 1 )
	end

	draw.RoundedBox( 8, xpos, ypos, sizex * 0.118, sizey * 0.075, Color( 0, 0, 0, 80 ) )
	
	draw.SimpleText( "Throttle: "..throttle.." %", "simfphysfont", xpos + sizex * 0.005, ypos + sizey * 0.035, Color( 255, 235, 0, 255 ), 0, 1)
	
	draw.SimpleText( "RPM: "..math.Round(rpm,0)..Active, "simfphysfont", xpos + sizex * 0.005, ypos + sizey * 0.012, Color( 255, 235 * (1 - redline), 0, 255 ), 0, 1 )
	
	draw.SimpleText( "GEAR:", "simfphysfont", xpos + sizex * 0.062, ypos + sizey * 0.012, Color( 255, 235, 0, 255 ), 0, 1 )
	draw.SimpleText( DrawGear, "simfphysfont", xpos + sizex * 0.11, ypos + sizey * 0.012, Color( 255, 235, 0, 255 ), 2, 1 )
	
	draw.SimpleText( (Hudreal and mph or wiremph).." mph", "simfphysfont", xpos + sizex * 0.005, ypos + sizey * 0.062, Color( 255, 235, 0, 255 ), 0, 1 )
	
	draw.SimpleText( (Hudreal and kmh or wirekmh).." kmh", "simfphysfont", xpos + sizex * 0.11, ypos + sizey * 0.062, Color( 255, 235, 0, 255 ), 2, 1 )
end

local turnmode = 0
local turnmenu_wasopen = false

local function drawTurnMenu( vehicle )
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyforward" ):GetInt() ) or  input.IsKeyDown( GetConVar( "cl_simfphys_key_air_forward" ):GetInt() ) then
		turnmode = 0
	end
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyleft" ):GetInt() ) or input.IsKeyDown( GetConVar( "cl_simfphys_key_air_left" ):GetInt() ) then
		turnmode = 2
	end
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyright" ):GetInt() ) or input.IsKeyDown( GetConVar( "cl_simfphys_key_air_right" ):GetInt() ) then
		turnmode = 3
	end
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyreverse" ):GetInt() ) or input.IsKeyDown( GetConVar( "cl_simfphys_key_air_reverse" ):GetInt() ) then
		turnmode = 1
	end
	
	local cX = ScrW() / 2
	local cY = ScrH() / 2
	
	local sx = sizex * 0.065
	local sy = sizex * 0.065
	
	local selectorX = (turnmode == 2 and (-sx - 1) or 0) + (turnmode == 3 and (sx + 1) or 0)
	local selectorY = (turnmode == 0 and (-sy - 1) or 0)
	
	draw.RoundedBox( 8, cX - sx * 0.5 - 1 + selectorX, cY - sy * 0.5 - 1 + selectorY, sx + 2, sy + 2, Color( 240, 200, 0, 255 ) )
	draw.RoundedBox( 8, cX - sx * 0.5 + selectorX, cY - sy * 0.5 + selectorY, sx, sy, Color( 50, 50, 50, 255 ) )
	
	draw.RoundedBox( 8, cX - sx * 0.5, cY - sy * 0.5, sx, sy, Color( 0, 0, 0, 100 ) )
	draw.RoundedBox( 8, cX - sx * 0.5, cY - sy * 1.5 - 1, sx, sy, Color( 0, 0, 0, 100 ) )
	draw.RoundedBox( 8, cX - sx * 1.5 - 1, cY - sy * 0.5, sx, sy, Color( 0, 0, 0, 100 ) )
	draw.RoundedBox( 8, cX + sx * 0.5 + 1, cY - sy * 0.5, sx, sy, Color( 0, 0, 0, 100 ) )
	
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	--X
	if turnmode == 0 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX - sx * 0.3, cY - sy - sy * 0.3, cX + sx * 0.3, cY - sy + sy * 0.3 )
	surface.DrawLine( cX + sx * 0.3, cY - sy - sy * 0.3, cX - sx * 0.3, cY - sy + sy * 0.3 )
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	
	-- <=
	if turnmode == 2 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX - sx + sx * 0.3, cY - sy * 0.15, cX - sx + sx * 0.3, cY + sy * 0.15 )
	surface.DrawLine( cX - sx + sx * 0.3, cY + sy * 0.15, cX - sx, cY + sy * 0.15 )
	surface.DrawLine( cX - sx + sx * 0.3, cY - sy * 0.15, cX - sx, cY - sy * 0.15 )
	surface.DrawLine( cX - sx, cY - sy * 0.3, cX - sx, cY - sy * 0.15 )
	surface.DrawLine( cX - sx, cY + sy * 0.3, cX - sx, cY + sy * 0.15 )
	surface.DrawLine( cX - sx, cY + sy * 0.3, cX - sx - sx * 0.3, cY )
	surface.DrawLine( cX - sx, cY - sy * 0.3, cX - sx - sx * 0.3, cY )
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	
	-- =>
	if turnmode == 3 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX + sx - sx * 0.3, cY - sy * 0.15, cX + sx - sx * 0.3, cY + sy * 0.15 )
	surface.DrawLine( cX + sx - sx * 0.3, cY + sy * 0.15, cX + sx, cY + sy * 0.15 )
	surface.DrawLine( cX + sx - sx * 0.3, cY - sy * 0.15, cX + sx, cY - sy * 0.15 )
	surface.DrawLine( cX + sx, cY - sy * 0.3, cX + sx, cY - sy * 0.15 )
	surface.DrawLine( cX + sx, cY + sy * 0.3, cX + sx, cY + sy * 0.15 )
	surface.DrawLine( cX + sx, cY + sy * 0.3, cX + sx + sx * 0.3, cY )
	surface.DrawLine( cX + sx, cY - sy * 0.3, cX + sx + sx * 0.3, cY )
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	
	-- ^
	if turnmode == 1 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX, cY - sy * 0.4, cX + sx * 0.4, cY + sy * 0.3 )
	surface.DrawLine( cX, cY - sy * 0.4, cX - sx * 0.4, cY + sy * 0.3 )
	surface.DrawLine( cX + sx * 0.4, cY + sy * 0.3, cX - sx * 0.4, cY + sy * 0.3 )
	surface.DrawLine( cX, cY - sy * 0.26, cX + sx * 0.3, cY + sy * 0.24 )
	surface.DrawLine( cX, cY - sy * 0.26, cX - sx * 0.3, cY + sy * 0.24 )
	surface.DrawLine( cX + sx * 0.3, cY + sy * 0.24, cX - sx * 0.3, cY + sy * 0.24 )
	
	surface.SetDrawColor( 255, 255, 255, 255 ) 
end

local function simfphysHUD()
	local ply = LocalPlayer()
	local turnmenu_isopen = false
	
	if not IsValid( ply ) or not ply:Alive() then turnmenu_wasopen = false return end

	local vehicle = ply:GetVehicle()
	if not IsValid( vehicle ) then turnmenu_wasopen = false return end
	
	local vehiclebase = vehicle.vehiclebase
	
	if not IsValid( vehiclebase ) then turnmenu_wasopen = false return end
	
	local IsDriverSeat = vehicle == vehiclebase:GetDriverSeat()
	if not IsDriverSeat then turnmenu_wasopen = false return end
	
	drawsimfphysHUD( vehiclebase )
	
	if vehiclebase.HasTurnSignals and input.IsKeyDown( turnmenu ) then
		turnmenu_isopen = true
		
		drawTurnMenu( vehiclebase )
	end
	
	if turnmenu_isopen ~= turnmenu_wasopen then
		turnmenu_wasopen = turnmenu_isopen
		
		if turnmenu_isopen then
			turnmode = 0
		else			
			net.Start( "simfphys_turnsignal" )
				net.WriteEntity( vehiclebase )
				net.WriteInt( turnmode, 32 )
			net.SendToServer()
			
			if turnmode == 1 or turnmode == 2 or turnmode == 3 then
				vehiclebase:EmitSound( "simulated_vehicles/sfx/indicator_start1.wav" )
			else
				vehiclebase:EmitSound( "simulated_vehicles/sfx/indicator_end1.wav" )
			end
		end
	end
end
hook.Add( "HUDPaint", "simfphys_HUD", simfphysHUD)

-- draw.arc function by bobbleheadbob
-- https://dl.dropboxusercontent.com/u/104427432/Scripts/drawarc.lua
-- https://facepunch.com/showthread.php?t=1438016&p=46536353&viewfull=1#post46536353

function surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness,bClockwise)
	local triarc = {}
	local deg2rad = math.pi / 180
	
	-- Correct start/end ang
	local startang,endang = startang or 0, endang or 0
	if bClockwise and (startang < endang) then
		local temp = startang
		startang = endang
		endang = temp
		temp = nil
	elseif (startang > endang) then 
		local temp = startang
		startang = endang
		endang = temp
		temp = nil
	end
	
	
	-- Define step
	local roughness = math.max(roughness or 1, 1)
	local step = roughness
	if bClockwise then
		step = math.abs(roughness) * -1
	end
	
	
	-- Create the inner circle's points.
	local inner = {}
	local r = radius - thickness
	for deg=startang, endang, step do
		local rad = deg2rad * deg
		table.insert(inner, {
			x=cx+(math.cos(rad)*r),
			y=cy+(math.sin(rad)*r)
		})
	end
	
	
	-- Create the outer circle's points.
	local outer = {}
	for deg=startang, endang, step do
		local rad = deg2rad * deg
		table.insert(outer, {
			x=cx+(math.cos(rad)*radius),
			y=cy+(math.sin(rad)*radius)
		})
	end
	
	
	-- Triangulize the points.
	for tri=1,#inner*2 do -- twice as many triangles as there are degrees.
		local p1,p2,p3
		p1 = outer[math.floor(tri/2)+1]
		p3 = inner[math.floor((tri+1)/2)+1]
		if tri%2 == 0 then --if the number is even use outer.
			p2 = outer[math.floor((tri+1)/2)]
		else
			p2 = inner[math.floor((tri+1)/2)]
		end
	
		table.insert(triarc, {p1,p2,p3})
	end
	
	-- Return a table of triangles to draw.
	return triarc
	
end

function surface.DrawArc(arc)
	for k,v in ipairs(arc) do
		surface.DrawPoly(v)
	end
end

function draw.Arc(cx,cy,radius,thickness,startang,endang,roughness,color,bClockwise)
	surface.SetDrawColor(color)
	surface.DrawArc(surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness,bClockwise))
end
