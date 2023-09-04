AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "OnGround" )
	self:NetworkVar( "String", 0, "SurfaceMaterial" )
	self:NetworkVar( "Float", 0, "Speed" )
	self:NetworkVar( "Float", 1, "SkidSound" )
	self:NetworkVar( "Float", 2, "GripLoss" )
	self:NetworkVar( "Bool", 1, "Damaged" )
	self:NetworkVar( "Entity", 0, "BaseEnt" )

	if SERVER then
		self:NetworkVarNotify( "Damaged", self.OnDamaged )
	end
end

local function FastClamp( a, b, c )
	return ( a > c and c ) or ( b > a and b ) or a
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_vehicles/tire001c_car.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON  )
		self:SetUseType( SIMPLE_USE )
		self:AddFlags( FL_OBJECT )

		self:DrawShadow( false )

		self.OldMaterial = ""
		self.OldMaterial2 = ""
		self.OldVar = 0
		self.OldVar2 = 0

		local Color = self:GetColor()
		local dot = Color.r * Color.g * Color.b * Color.a
		self.OldColor = dot

		self.snd_roll = "simulated_vehicles/sfx/concrete_roll.wav"
		self.snd_roll_dirt = "simulated_vehicles/sfx/dirt_roll.wav"
		self.snd_roll_grass = "simulated_vehicles/sfx/grass_roll.wav"

		self.snd_skid = "simulated_vehicles/sfx/concrete_skid.wav"
		self.snd_skid_dirt = "simulated_vehicles/sfx/dirt_skid.wav"
		self.snd_skid_grass = "simulated_vehicles/sfx/grass_skid.wav"

		self.RollSound = CreateSound(self, self.snd_roll)
		self.RollSound_Dirt = CreateSound(self, self.snd_roll_dirt)
		self.RollSound_Grass = CreateSound(self, self.snd_roll_grass)

		self.Skid = CreateSound(self, self.snd_skid)
		self.Skid_Dirt = CreateSound(self, self.snd_skid_dirt)
		self.Skid_Grass = CreateSound(self, self.snd_skid_grass)
	end

	function ENT:Use( ply )
		local base = self:GetBaseEnt()
		if not base:IsValid() then return end

		if base:GetIsVehicleLocked() then
			base:EmitSound( "doors/default_locked.wav" )

			return
		end

		base:SetPassenger( ply )
	end

	function ENT:Think()
		if self.GhostEnt then
			local Color = self:GetColor()
			local dot = Color.r * Color.g * Color.b * Color.a
			if dot ~= self.OldColor then
				if self.GhostEnt:IsValid() then
					self.GhostEnt:SetColor( Color )
					self.GhostEnt:SetRenderMode( self:GetRenderMode() )
				end
				self.OldColor = dot
			end
		end

		if self:GetDamaged() then
			self:WheelFxBroken()
		else
			self:WheelFx()
		end

		self:NextThink( CurTime() + 0.15 )
		return true
	end

	local div_1500 = 1 / 1500
	function ENT:WheelFxBroken()
		local ForwardSpeed = math.abs( self:GetSpeed() )
		local SkidSound = FastClamp( self:GetSkidSound(), 0, 255 )
		local WheelOnGround = self:GetOnGround()
		local EnableDust = WheelOnGround and self:GetVelocity():LengthSqr() > 40000
		local Material = self:GetSurfaceMaterial()
		local GripLoss = self:GetGripLoss()

		if EnableDust ~= self.OldVar then
			self.OldVar = EnableDust
		end

		if EnableDust then
			if Material ~= self.OldMaterial then
				self.OldMaterial = Material
			end
		end

		if self.RollSound_Broken then
			local Volume = FastClamp( SkidSound * 0.5 + ForwardSpeed / div_1500, 0, 1 ) * ( WheelOnGround and 1 or 0 )
			local PlaySound = Volume > 0.1

			self.OldPlaySound = self.OldPlaySound or false
			if PlaySound ~= self.OldPlaySound then
				self.OldPlaySound = PlaySound
				if PlaySound then
					self.RollSound_Broken:PlayEx(0,0)
				else
					self.RollSound_Broken:Stop()
				end
			end


			self.RollSound_Broken:ChangeVolume( Volume )
			self.RollSound_Broken:ChangePitch( 100 + FastClamp( ( ForwardSpeed - 100 ) * 0.004 + ( SkidSound * self:GetVelocity():Length() * 0.00125 ) + GripLoss * 22, 0, 155 ) )
		end
	end

	function ENT:WheelFx()
		local ForwardSpeed = math.abs( self:GetSpeed() )
		local SkidSound = FastClamp( self:GetSkidSound(), 0, 255 )
		local Speed = self:GetVelocity():Length()
		local WheelOnGround = self:GetOnGround()
		local EnableDust = WheelOnGround and Speed > 200
		local Material = self:GetSurfaceMaterial()
		local GripLoss = self:GetGripLoss()

		if EnableDust ~= self.OldVar then
			self.OldVar = EnableDust

			if EnableDust then
				if Material == "grass" then
					self.RollSound_Grass = CreateSound(self, self.snd_roll_grass)
					self.RollSound_Grass:PlayEx(0,0)
					self.RollSound_Dirt:Stop()
					self.RollSound:Stop()
				elseif Material == "dirt" or Material == "sand" then
					self.RollSound_Dirt = CreateSound(self, self.snd_roll_dirt)
					self.RollSound_Dirt:PlayEx(0,0)
					self.RollSound_Grass:Stop()
					self.RollSound:Stop()
				else
					self.RollSound_Grass:Stop()
					self.RollSound_Dirt:Stop()
					self.RollSound = CreateSound(self, self.snd_roll)
					self.RollSound:PlayEx(0,0)
				end
			else
				self.RollSound:Stop()
				self.RollSound_Grass:Stop()
				self.RollSound_Dirt:Stop()
			end
		end

		if EnableDust then
			if Material ~= self.OldMaterial then
				if Material == "grass" then
					self.RollSound_Grass = CreateSound(self, self.snd_roll_grass)
					self.RollSound_Grass:PlayEx(0,0)
					self.RollSound_Dirt:Stop()
					self.RollSound:Stop()

				elseif Material == "dirt" or Material == "sand" then
					self.RollSound_Grass:Stop()
					self.RollSound_Dirt = CreateSound(self, self.snd_roll_dirt)
					self.RollSound_Dirt:PlayEx(0,0)
					self.RollSound:Stop()
				else
					self.RollSound_Grass:Stop()
					self.RollSound_Dirt:Stop()
					self.RollSound = CreateSound(self, self.snd_roll)
					self.RollSound:PlayEx(0,0)
				end
				self.OldMaterial = Material
			end

			if Material == "grass" then
				self.RollSound_Grass:ChangeVolume( FastClamp( ( ForwardSpeed - 100 ) * 0.000625, 0, 1 ), 0 )
				self.RollSound_Grass:ChangePitch( 80 + FastClamp( ( ForwardSpeed - 100 ) * 0.004, 0, 255 ), 0 )
			elseif Material == "dirt" or Material == "sand" then
				self.RollSound_Dirt:ChangeVolume( FastClamp( ( ForwardSpeed - 100 ) * 0.000625, 0, 1 ), 0 )
				self.RollSound_Dirt:ChangePitch( 80 + FastClamp( ( ForwardSpeed - 100 ) * 250, 0, 255 ), 0 )
			else
				self.RollSound:ChangeVolume( FastClamp( ( ForwardSpeed - 100 ) * div_1500, 0, 1 ), 0 )
				self.RollSound:ChangePitch( 100 + FastClamp( ( ForwardSpeed - 400 ) * 0.005, 0, 255 ), 0 )
			end
		end


		if WheelOnGround ~= self.OldVar2 then
			self.OldVar2 = WheelOnGround
			if WheelOnGround then
				if Material == "grass" or Material == "snow" then
					self.Skid:Stop()
					self.Skid_Grass = CreateSound(self, self.snd_skid_grass)
					self.Skid_Grass:PlayEx(0,0)
					self.Skid_Dirt:Stop()
				elseif Material == "dirt" or Material == "sand" then
					self.Skid_Grass:Stop()
					self.Skid_Dirt = CreateSound(self, self.snd_skid_dirt)
					self.Skid_Dirt:PlayEx(0,0)
					self.Skid:Stop()
				elseif Material == "ice" then
					self.Skid_Grass:Stop()
					self.Skid_Dirt:Stop()
					self.Skid:Stop()
				else
					self.Skid = CreateSound(self, self.snd_skid)
					self.Skid:PlayEx(0,0)
					self.Skid_Grass:Stop()
					self.Skid_Dirt:Stop()
				end
			else
				self.Skid:Stop()
				self.Skid_Grass:Stop()
				self.Skid_Dirt:Stop()
			end
		end

		if WheelOnGround then
			if Material ~= self.OldMaterial2 then
				if Material == "grass" or Material == "snow" then
					self.Skid:Stop()
					self.Skid_Grass = CreateSound(self, self.snd_skid_grass)
					self.Skid_Grass:PlayEx(0,0)
					self.Skid_Dirt:Stop()

				elseif Material == "dirt" or Material == "sand" then
					self.Skid:Stop()
					self.Skid_Grass:Stop()
					self.Skid_Dirt = CreateSound(self, self.snd_skid_dirt)
					self.Skid_Dirt:PlayEx(0,0)
				elseif Material == "ice" then
					self.Skid_Grass:Stop()
					self.Skid_Dirt:Stop()
					self.Skid:Stop()
				else
					self.Skid = CreateSound(self, self.snd_skid)
					self.Skid:PlayEx(0,0)
					self.Skid_Grass:Stop()
					self.Skid_Dirt:Stop()
				end
				self.OldMaterial2 = Material
			end

			if Material == "grass" or Material == "snow" then
				self.Skid_Grass:ChangeVolume( FastClamp( SkidSound, 0, 1 ) )
				self.Skid_Grass:ChangePitch(math.min(90 + (SkidSound * Speed / 500),150))
			elseif Material == "dirt" or Material == "sand" then
				self.Skid_Dirt:ChangeVolume( FastClamp( SkidSound, 0, 1 ) * 0.8 )
				self.Skid_Dirt:ChangePitch(math.min(120 + (SkidSound * Speed / 500),150))
			else
				self.Skid:ChangeVolume( FastClamp( SkidSound * 0.5, 0, 1 ) )
				self.Skid:ChangePitch( math.min( 85 + ( SkidSound * Speed / 800 ) + GripLoss * 22, 150 ) )
			end
		end
	end

	function ENT:OnRemove()
		self.RollSound_Grass:Stop()
		self.RollSound_Dirt:Stop()
		self.RollSound:Stop()

		self.Skid:Stop()
		self.Skid_Grass:Stop()
		self.Skid_Dirt:Stop()

		if self.RollSound_Broken then
			self.RollSound_Broken:Stop()
		end
		if self.PreBreak then
			self.PreBreak:Stop()
		end
	end

	function ENT:PhysicsCollide( data, physobj )
		if data.Speed > 100 and data.DeltaTime > 0.2 then
			if data.Speed > 400 then
				self:EmitSound( "Rubber_Tire.ImpactHard" )
				self:EmitSound( "simulated_vehicles/suspension_creak_".. math.random(1,6) ..".ogg" )
			else
				self:EmitSound( "Rubber.ImpactSoft" )
			end
		end
	end

	function ENT:OnTakeDamage( dmginfo )
		self:TakePhysicsDamage( dmginfo )

		if self:GetDamaged() or not simfphys.DamageEnabled then return end

		local Damage = dmginfo:GetDamage()
		local DamagePos = dmginfo:GetDamagePosition()
		local Type = dmginfo:GetDamageType()
		local BaseEnt = self:GetBaseEnt()

		if TYPE == DMG_BLAST then return end  -- no tirepopping on explosions

		if BaseEnt:IsValid() then
			if BaseEnt:GetBulletProofTires() then return end

			if Damage > 1 then
				if not self.PreBreak then
					self.PreBreak = CreateSound(self, "ambient/gas/cannister_loop.wav")
					self.PreBreak:PlayEx(0.5,100)

					timer.Simple(math.Rand(0.5,5), function()
						if self:IsValid() and not self:GetDamaged() then
							self:SetDamaged( true )
							if self.PreBreak then
								self.PreBreak:Stop()
								self.PreBreak = nil
							end
						end
					end)
				else
					self:SetDamaged( true )
					self.PreBreak:Stop()
					self.PreBreak = nil
				end
			end
		end
	end

	function ENT:OnDamaged( name, old, new)
		if new == old then return end

		if new == true then
			self.dRadius = self:BoundingRadius() * 0.28

			self:EmitSound( "simulated_vehicles/sfx/tire_break.ogg" )

			if self.GhostEnt:IsValid() then
				self.GhostEnt:SetParent( nil )
				self.GhostEnt:GetPhysicsObject():EnableMotion( false )
				self.GhostEnt:SetPos( self:LocalToWorld( Vector(0,0,-self.dRadius) ) )
				self.GhostEnt:SetParent( self )
			end

			self.Skid:Stop()
			self.Skid_Grass:Stop()
			self.Skid_Dirt:Stop()

			self.RollSound:Stop()
			self.RollSound_Grass:Stop()
			self.RollSound_Dirt:Stop()

			self.RollSound_Broken = CreateSound(self, "simulated_vehicles/sfx/tire_damaged.wav")
		else
			if self.GhostEnt:IsValid() then
				self.GhostEnt:SetParent( nil )
				self.GhostEnt:GetPhysicsObject():EnableMotion( false )
				self.GhostEnt:SetPos( self:LocalToWorld( Vector(0,0,0) ) )
				self.GhostEnt:SetParent( self )
			end

			if self.RollSound_Broken then
				self.RollSound_Broken:Stop()
			end
		end

		local BaseEnt = self:GetBaseEnt()
		if BaseEnt:IsValid() then
			BaseEnt:SetSuspension( self.Index , new )
		end
	end
end

if CLIENT then
	function ENT:Initialize()
		self.FadeHeat = 0

		timer.Simple( 0.01, function()
			if not self:IsValid() then return end
			self.Radius = self:BoundingRadius()
		end)
	end

	function ENT:Think()
		if self:IsDormant() then return end
		local curtime = CurTime()
		local entTable = self:GetTable()
		entTable.SmokeTimer = entTable.SmokeTimer or 0
		if entTable.SmokeTimer < curtime then
			self:ManageSmoke()
			entTable.SmokeTimer = curtime + 0.005
		end
	end

	local distance = 6000 * 6000
	function ENT:ManageSmoke()
		if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) > distance then return end

		local BaseEnt = self:GetBaseEnt()
		if not BaseEnt:IsValid() then return end
		if not BaseEnt:GetActive() then return end

		local WheelOnGround = self:GetOnGround()
		local GripLoss = self:GetGripLoss()
		local Material = self:GetSurfaceMaterial()

		if WheelOnGround and ( GripLoss > 0 ) and (Material == "concrete" or Material == "rock" or Material == "tile") then
			self.FadeHeat = FastClamp( self.FadeHeat + GripLoss * .06, 0, 10 )
		else
			self.FadeHeat = self.FadeHeat * 0.995
		end

		local Scale = self.FadeHeat ^ 3 * 0.001
		local SmokeOn = ( self.FadeHeat >= 7 )

		local lcolor = BaseEnt:GetTireSmokeColor()
		lcolor:Mul( 255 )

		local OnRim = self:GetDamaged()

		local Dir = self:GetForward()
		if not ( BaseEnt:GetGear() < 2 ) then
			Dir:Mul( -1 )
		end

		local WheelSize = self.Radius or 0
		local Pos = self:GetPos()

		if SmokeOn and not OnRim then
			local effectdata = EffectData()
				effectdata:SetOrigin( Pos )
				effectdata:SetNormal( Dir )
				effectdata:SetMagnitude( Scale )
				effectdata:SetRadius( WheelSize )
				effectdata:SetStart( lcolor )
				effectdata:SetEntity( NULL )
			util.Effect( "simfphys_tiresmoke", effectdata )
		end

		if WheelOnGround then
			local DirtOn = GripLoss > 0.05

			if DirtOn then
				local effectdata = EffectData()
					effectdata:SetOrigin( Pos )
					effectdata:SetNormal( Dir )
					effectdata:SetMagnitude( GripLoss )
					effectdata:SetRadius( WheelSize )
					effectdata:SetEntity( self )
				util.Effect( "simfphys_tiresmoke", effectdata )
			end

			if OnRim and ( DirtOn or self:GetVelocity():LengthSqr() > 22500 ) then
				self:MakeSparks( GripLoss, Dir, Pos, WheelSize )
			end
		end

	end

	function ENT:MakeSparks( Scale, Dir, Pos, WheelSize )
		self.NextSpark = self.NextSpark or 0

		if self.NextSpark < CurTime() then

			self.NextSpark = CurTime() + 0.1
			local effectdata = EffectData()
				effectdata:SetOrigin( Pos - Vector(0,0,WheelSize * 0.5) )
				effectdata:SetNormal( (Dir + Vector(0,0,0.5)) * Scale * 0.5)
			util.Effect( "manhacksparks", effectdata, true, true )
		end
	end

	function ENT:Draw()
		return false
	end

	function ENT:OnRemove()
	end
end