simfphys.jcon = {}

hook.Add("JoystickInitialize", "simfphys_joystick", function()
	simfphys.jcon.steer_left = jcon.register{
		uid = "joystick_steer_left",
		type = "analog",
		description = "Steer Left",
		category = "Simfphys",
	}

	simfphys.jcon.steer_right = jcon.register{
		uid = "joystick_steer_right",
		type = "analog",
		description = "Steer Right",
		category = "Simfphys",
	}

	simfphys.jcon.throttle = jcon.register{
		uid = "joystick_throttle",
		type = "analog",
		description = "Throttle",
		category = "Simfphys",
	}

	simfphys.jcon.brake = jcon.register{
		uid = "joystick_brake",
		type = "analog",
		description = "Brake",
		category = "Simfphys",
	}

	simfphys.jcon.gearup = jcon.register{
		uid = "joystick_gearup",
		type = "digital",
		description = "Gear Up",
		category = "Simfphys",
	}

	simfphys.jcon.geardown = jcon.register{
		uid = "joystick_geardown",
		type = "digital",
		description = "Gear Down",
		category = "Simfphys",
	}

	simfphys.jcon.handbrake = jcon.register{
		uid = "joystick_handbrake",
		type = "digital",
		description = "Handbrake",
		category = "Simfphys",
	}

	simfphys.jcon.clutch = jcon.register{
		uid = "joystick_clutch",
		type = "analog",
		description = "Clutch",
		category = "Simfphys",
	}

	simfphys.jcon.air_forward = jcon.register{
		uid = "joystick_air_w",
		type = "analog",
		description = "Air (forward)",
		category = "Simfphys",
	}

	simfphys.jcon.air_reverse = jcon.register{
		uid = "joystick_air_s",
		type = "analog",
		description = "Air (backward)",
		category = "Simfphys",
	}

	simfphys.jcon.air_left = jcon.register{
		uid = "joystick_air_a",
		type = "analog",
		description = "Air (left)",
		category = "Simfphys",
	}

	simfphys.jcon.air_right = jcon.register{
		uid = "joystick_air_d",
		type = "analog",
		description = "Air (right)",
		category = "Simfphys",
	}

	simfphys.jcon.gear_n = jcon.register{
		uid = "joystick_gear_n",
		type = "digital",
		description = "Gear Neutral",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_1 = jcon.register{
		uid = "joystick_gear_1",
		type = "digital",
		description = "Gear 1",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_2 = jcon.register{
		uid = "joystick_gear_2",
		type = "digital",
		description = "Gear 2",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_3 = jcon.register{
		uid = "joystick_gear_3",
		type = "digital",
		description = "Gear 3",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_4 = jcon.register{
		uid = "joystick_gear_4",
		type = "digital",
		description = "Gear 4",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_5 = jcon.register{
		uid = "joystick_gear_5",
		type = "digital",
		description = "Gear 5",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_6 = jcon.register{
		uid = "joystick_gear_6",
		type = "digital",
		description = "Gear 6",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_7 = jcon.register{
		uid = "joystick_gear_7",
		type = "digital",
		description = "Gear 7",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_8 = jcon.register{
		uid = "joystick_gear_8",
		type = "digital",
		description = "Gear 8",
		category = "Simfphys (Gears)",
	}

	simfphys.jcon.gear_r = jcon.register{
		uid = "joystick_gear_r",
		type = "digital",
		description = "Gear Reverse",
		category = "Simfphys (Gears)",
	}

	local enable_joystick_convar = CreateConVar("w", "0", FCVAR_SERVER_CAN_EXECUTE, "Enable joystick support?", 0, 1)

	local function simfphys_joystickhandler()
		local plys = player.GetAll()

		for i = 1, player.GetCount() do
			local ply = plys[i]
			if not ply:IsConnected() then continue end
			local vehicle = ply:GetVehicle()
			if not vehicle:IsValid() then return end
			if not vehicle.fphysSeat then return end
			if vehicle.base:GetDriverSeat() ~= vehicle then return end

			for k, v in pairs(simfphys.jcon) do
				if istable(v) and v.IsJoystickReg then continue end
				local val = joystick.Get(ply, v.uid)

				if v.type == "analog" then
					vehicle.base.PressedKeys[v.uid] = val and val / 255 or 0
				else
					if string.StartWith(v.uid, "joystick_gear_") then
						if v.uid == "joystick_gear_r" then
							if val then
								vehicle.base:ForceGear(1)
							end
						elseif v.uid == "joystick_gear_n" then
							if val then
								vehicle.base:ForceGear(2)
							end
						else
							for i = 1, 8 do
								if v.uid == "joystick_gear_" .. i then
									if val then
										vehicle.base:ForceGear(i + 2)
									end

									break
								end
							end
						end
					else
						vehicle.base.PressedKeys[v.uid] = val and 1 or 0
					end
				end
			end
		end
	end

	if tonumber( enable_joystick_convar:GetString() ) ~= 0 then
		hook.Add( "Think", "simfphys_joystickhandler", simfphys_joystickhandler )
	end

	cvars.RemoveChangeCallback( "sv_simfphys_joysticksupport", "simfphys_joystickhandler" ) --incase of a lua refresh
	cvars.AddChangeCallback( "sv_simfphys_joysticksupport", function( _, _, new )
		if tonumber( new ) ~= 0 then
			hook.Add( "Think", "simfphys_joystickhandler", simfphys_joystickhandler )
		else
			hook.Remove( "Think", "simfphys_joystickhandler" )
		end
	end, "simfphys_joystickhandler" )

end)