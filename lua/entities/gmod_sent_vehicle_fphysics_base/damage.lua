function ENT:ApplyDamage( damage, type )
	if type == DMG_BLAST then
		damage = damage * 10
	end

	if type == DMG_BULLET then
		damage = damage * 2
	end

	local MaxHealth = self:GetMaxHealth()
	local CurHealth = self:GetCurHealth()

	local NewHealth = math.max( math.Round(CurHealth - damage,0) , 0 )

	if NewHealth <= (MaxHealth * 0.6) then
		if NewHealth <= (MaxHealth * 0.3) then
			self:SetOnFire( true )
			self:SetOnSmoke( false )
		else
			self:SetOnSmoke( true )
		end
	end

	if MaxHealth > 30 and NewHealth <= 31 and self:EngineActive() then
		self:DamagedStall()
	end

	if NewHealth <= 0 then
		if (type ~= DMG_CRUSH) then

			self:ExplodeVehicle()

			return
		end

		if self:EngineActive() then
			self:DamagedStall()
		end

		self:SetCurHealth( 0 )

		return
	end

	self:SetCurHealth( NewHealth )
end

function ENT:HurtPlayers( damage )
	if not simfphys.pDamageEnabled then return end

	local Driver = self:GetDriver()

	if Driver:IsValid() and self.RemoteDriver ~= Driver then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( damage )
		dmginfo:SetAttacker( game.GetWorld() )
		dmginfo:SetInflictor( self )
		dmginfo:SetDamageType( DMG_DIRECT )

		Driver:TakeDamageInfo( dmginfo )
	end

	if not istable( self.PassengerSeats ) then return end

	for i = 1, #self.PassengerSeats do
		local Passenger = self.pSeat[i]:GetDriver()
		if Passenger:IsValid() then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage( damage )
			dmginfo:SetAttacker( game.GetWorld() )
			dmginfo:SetInflictor( self )
			dmginfo:SetDamageType( DMG_DIRECT )

			Passenger:TakeDamageInfo( dmginfo )
		end
	end
end

function ENT:ExplodeVehicle()
	if not self:IsValid() then return end
	if self.destroyed then return end

	self.destroyed = true

	local ply = self.EntityOwner
	local skin = self:GetSkin()
	local Col = self:GetColor()
	Col.r = Col.r * 0.8
	Col.g = Col.g * 0.8
	Col.b = Col.b * 0.8

	local Driver = self:GetDriver()
	if Driver:IsValid() and self.RemoteDriver ~= Driver then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( Driver:Health() + Driver:Armor() )
		dmginfo:SetAttacker( self.LastAttacker or game.GetWorld() )
		dmginfo:SetInflictor( self.LastInflictor or game.GetWorld() )
		dmginfo:SetDamageType( DMG_DIRECT )

		Driver:TakeDamageInfo( dmginfo )
	end

	if self.PassengerSeats then
		for i = 1, table.Count( self.PassengerSeats ) do
			local Passenger = self.pSeat[i]:GetDriver()
			if Passenger:IsValid() then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage( Passenger:Health() + Passenger:Armor() )
				dmginfo:SetAttacker( self.LastAttacker or game.GetWorld() )
				dmginfo:SetInflictor( self.LastInflictor or game.GetWorld() )
				dmginfo:SetDamageType( DMG_DIRECT )

				Passenger:TakeDamageInfo( dmginfo )
			end
		end
	end

	if self.GibModels then
		local bprop = ents.Create( "gmod_sent_vehicle_fphysics_gib" )
		bprop:SetModel( self.GibModels[1] )
		bprop:SetPos( self:GetPos() )
		bprop:SetAngles( self:GetAngles() )
		bprop.MakeSound = true
		bprop:Spawn()
		bprop:Activate()
		local bprop_phys = bprop:GetPhysicsObject()
		if bprop_phys:IsValid() then
			bprop_phys:SetVelocity( self:GetVelocity() + Vector( math.random( -5, 5 ), math.random( -5, 5 ), math.random( 150, 250 ) ) )
			bprop_phys:SetMass( self.Mass * 0.75 )
		end

		bprop.DoNotDuplicate = true
		bprop:SetColor( Col )
		bprop:SetSkin( skin )

		self.Gib = bprop

		simfphys.SetOwner( ply , bprop )

		if ply and ply:IsValid() then
			undo.Create( "Gib" )
			undo.SetPlayer( ply )
			undo.AddEntity( bprop )
			undo.SetCustomUndoText( "Undone Gib" )
			undo.Finish( "Gib" )
			ply:AddCleanup( "Gibs", bprop )
		end

		bprop.Gibs = {}
		local GibModels = self.GibModels
		for i = 2, #GibModels do
			local prop = ents.Create( "gmod_sent_vehicle_fphysics_gib" )
			prop:SetModel( GibModels[i] )
			prop:SetPos( self:GetPos() )
			prop:SetAngles( self:GetAngles() )
			prop:SetOwner( bprop )
			prop:Spawn()
			prop:Activate()
			prop.DoNotDuplicate = true
			bprop:DeleteOnRemove( prop )
			bprop.Gibs[i-1] = prop

			local PhysObj = prop:GetPhysicsObject()
			if PhysObj:IsValid() then
				PhysObj:SetVelocityInstantaneous( VectorRand() * 500 + self:GetVelocity() + Vector(0,0,math.random(150,250)) )
				PhysObj:AddAngleVelocity( VectorRand() )
			end


			simfphys.SetOwner( ply, prop )
		end
	else

		local bprop = ents.Create( "gmod_sent_vehicle_fphysics_gib" )
		bprop:SetModel( self:GetModel() )
		bprop:SetPos( self:GetPos() )
		bprop:SetAngles( self:GetAngles() )
		bprop.MakeSound = true
		bprop:Spawn()
		bprop:Activate()
		bprop:GetPhysicsObject():SetVelocity( self:GetVelocity() + Vector(math.random(-5,5),math.random(-5,5),math.random(150,250)) )
		bprop:GetPhysicsObject():SetMass( self.Mass * 0.75 )
		bprop.DoNotDuplicate = true
		bprop:SetColor( Col )
		bprop:SetSkin( skin )
		for i = 0, self:GetNumBodyGroups() do
			bprop:SetBodygroup( i, self:GetBodygroup( i ) )
		end

		self.Gib = bprop

		simfphys.SetOwner( ply, bprop )

		if ply and ply:IsValid() then
			undo.Create( "Gib" )
			undo.SetPlayer( ply )
			undo.AddEntity( bprop )
			undo.SetCustomUndoText( "Undone Gib" )
			undo.Finish( "Gib" )
			ply:AddCleanup( "Gibs", bprop )
		end

		if self.CustomWheels == true and not self.NoWheelGibs then
			bprop.Wheels = {}
			local GhostWheels = self.GhostWheels
			for i = 1, #GhostWheels do
				local Wheel = GhostWheels[i]
				if Wheel:IsValid() then
					local prop = ents.Create( "gmod_sent_vehicle_fphysics_gib" )
					prop:SetModel( Wheel:GetModel() )
					prop:SetPos( Wheel:LocalToWorld( Vector(0,0,0) ) )
					prop:SetAngles( Wheel:LocalToWorldAngles( Angle(0,0,0) ) )
					prop:SetOwner( bprop )
					prop:Spawn()
					prop:Activate()
					prop:GetPhysicsObject():SetVelocity( self:GetVelocity() + Vector(math.random(-5,5),math.random(-5,5),math.random(0,25)) )
					prop:GetPhysicsObject():SetMass( 20 )
					prop.DoNotDuplicate = true
					bprop:DeleteOnRemove( prop )
					bprop.Wheels[i] = prop

					simfphys.SetOwner( ply, prop )
				end
			end
		end
	end

	self:Extinguish()

	self:OnDestroyed()

	hook.Run( "simfphysOnDestroyed", self, self.Gib )

	self:Remove()
end

function ENT:OnTakeDamage( dmginfo )
	if not self:IsInitialized() then return end

	if hook.Run( "simfphysOnTakeDamage", self, dmginfo ) then return end

	local Damage = dmginfo:GetDamage()
	local DamagePos = dmginfo:GetDamagePosition()
	local Type = dmginfo:GetDamageType()
	local Driver = self:GetDriver()

	self.LastAttacker = dmginfo:GetAttacker()
	self.LastInflictor = dmginfo:GetInflictor()

	if simfphys.DamageEnabled then
		net.Start( "simfphys_spritedamage" )
			net.WriteEntity( self )
			net.WriteVector( self:WorldToLocal( DamagePos ) )
			net.WriteBool( false )
		net.Broadcast()

		self:ApplyDamage( Damage, Type )
	end
end

local function Spark( pos , normal , snd )
	local effectdata = EffectData()
	effectdata:SetOrigin( pos - normal )
	effectdata:SetNormal( -normal )
	util.Effect( "stunstickimpact", effectdata, true, true )

	if snd then
		sound.Play( Sound( snd ), pos, 75)
	end
end

function ENT:PhysicsCollide( data, physobj )

	if hook.Run( "simfphysPhysicsCollide", self, data, physobj ) then return end

	if data.HitEntity:IsValid() then
		if data.HitEntity:IsNPC() or data.HitEntity:IsNextBot() or data.HitEntity:IsPlayer() then
			Spark( data.HitPos , data.HitNormal , "MetalVehicle.ImpactSoft" )
			return
		end
	end

	if ( data.Speed > 60 && data.DeltaTime > 0.2 ) then

		local pos = data.HitPos

		if (data.Speed > 1000) then
			Spark( pos , data.HitNormal , "MetalVehicle.ImpactHard" )

			self:HurtPlayers( 5 )

			local dmg = DamageInfo()
				dmg:SetDamageType( DMG_CRUSH )
				dmg:SetDamage( ( data.Speed / 7 ) * simfphys.DamageMul )
				dmg:SetAttacker( Entity( 0 ) )
				dmg:SetInflictor( Entity( 0 ) )
				dmg:SetDamagePosition( pos )
			self:TakeDamageInfo( dmg )
		else
			Spark( pos , data.HitNormal , "MetalVehicle.ImpactSoft" )

			if data.Speed > 250 then
				local hitent = data.HitEntity:IsPlayer()
				if not hitent then
					if simfphys.DamageMul > 1 then
						local dmg = DamageInfo()
							dmg:SetDamageType( DMG_CRUSH )
							dmg:SetDamage( ( data.Speed / 28 ) * simfphys.DamageMul )
							dmg:SetAttacker( Entity( 0 ) )
							dmg:SetInflictor( Entity( 0 ) )
							dmg:SetDamagePosition( pos )
						self:TakeDamageInfo( dmg )
					end
				end
			end

			if data.Speed > 500 then
				self:HurtPlayers( 2 )

				local dmg = DamageInfo()
					dmg:SetDamageType( DMG_CRUSH )
					dmg:SetDamage( ( data.Speed / 14 ) * simfphys.DamageMul )
					dmg:SetAttacker( Entity( 0 ) )
					dmg:SetInflictor( Entity( 0 ) )
					dmg:SetDamagePosition( pos )
				self:TakeDamageInfo( dmg )
			end
		end
	end
end
