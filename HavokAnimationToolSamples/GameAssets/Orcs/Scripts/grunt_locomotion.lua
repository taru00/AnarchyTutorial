-- the current movement vector
g_movementVector = nil

-- handle simple input and movement control
function OnUpdateLocomotion()
	
	-- update Locomotion Speed and Rotation
	CalculateMovementVector()	
	CalculateSpeeds()
	
	-- update Directional Pad
	if(g_gamepadState.m_DPadFW == 1 and 
		hkbIsNodeActive("move forward") == false) then
		
		hkbFireEvent("to MoveForward")
		
	elseif(g_gamepadState.m_DPadBW == 1 and 
		hkbIsNodeActive("move backwoard") == false) then		
		
		hkbFireEvent("to MoveBackward")
	
	elseif(g_gamepadState.m_DPadLeft == 1 and 
		hkbIsNodeActive("move Left") == false) then			
		
		hkbFireEvent("to MoveLeft")
	
	elseif(g_gamepadState.m_DPadRight == 1 and 
		hkbIsNodeActive("move Right") == false) then		
		
		hkbFireEvent("to MoveRight")
	
	elseif(g_gamepadState.m_isDPadReleased == 1 and 
		hkbIsNodeActive("Simple Locomotion") == false) then		
		
		hkbFireEvent("to Locomotion")
	end
			
	-- rotate Character
	if( g_gamepadState.m_Trigger > 0.5 or g_gamepadState.m_Trigger < -0.5 ) then

		hkbSetVariable("TurnSpeed", g_gamepadState.m_Trigger / 5.0)
	end	
end

-- calculates movement and turn speeds for simple locomotion
function CalculateSpeeds()

	-- get the character forward vector
	local forward = hkVector4.new( 0, -1, 0 )
	forward:setRotatedDir( hkbGetOldWorldFromModel():getRotation(), forward )
	
	-- get the movment speed and turn speed
	local turnAxis = hkVector4.new()
	turnAxis:setCross( forward, g_movementVector )
	
	-- assign the proper variables
	hkbSetVariable("MovementSpeed", g_movementVector:length3() )
	hkbSetVariable("TurnSpeed", turnAxis[2]*360)
end

-- calculates the movement vector 
function CalculateMovementVector()

	-- update the gamepad state
	g_gamepadState:update()
	-- update the camera state	
	g_cameraState:update3rdPerson()
	
	-- get movement basis by projecting camera basis onto the floor
	local forward = hkVector4.new()
	forward:setSub4( g_cameraState.m_to, g_cameraState.m_from )
	forward[3] = 0
	forward:normalize3()
	
	local right = hkVector4.new(0, 0, 1)
	right:setCross( forward, right )
	right:normalize3()
	
	-- project gamepad input onto movement basis
	g_movementVector = hkVector4.new()	
	g_movementVector:setMul4( forward, g_gamepadState.m_leftStickY )
	g_movementVector:setAddMul4( g_movementVector, right, g_gamepadState.m_leftStickX )
	
end




