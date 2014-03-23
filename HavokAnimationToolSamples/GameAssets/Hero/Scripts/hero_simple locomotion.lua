-- the current movement vector
g_movementVector = nil

-- globals
PI = 3.14159
TWO_PI = PI * 2.0
DEG_TO_RAD = PI / 180.0
RAD_TO_DEG = 180.0 / PI
UP_AXIS = hkVector4.new(0.0, 0.0, 1.0)
FORWARD_AXIS = hkVector4.new(0.0, -1.0, 0.0)

-- helper table to store the state of the game pad.
g_gamepadState = 
{	
	m_leftStickX = 0,
	m_leftStickY = 0,
	m_leftStickMagnitude = 0,
	m_leftStickAngle = 0,
	
	m_rightStickX = 0,
	m_rightStickY = 0,
	m_rightStickMagnitude = 0,
	
	m_Trigger = 0,
	
	m_lastLeftStickX = 0,
	m_lastLeftStickY = 0,
		
	m_leftStickHoldTime = 0,
}


	-- updates the state of the gamepad
function g_gamepadState:update()
		
   	self.m_rightStickX = hkbGetVariable("RightStickX")
	self.m_rightStickY = hkbGetVariable("RightStickY")
	self.m_rightStickMagnitude = math.sqrt( self.m_rightStickX * self.m_rightStickX +
										    self.m_rightStickY * self.m_rightStickY )
										   
	self.m_lastLeftStickX = self.m_leftStickX
	self.m_lastLeftStickY = self.m_leftStickY	
			
	self.m_leftStickX = hkbGetVariable("LeftStickX")
	self.m_leftStickY = hkbGetVariable("LeftStickY")
	self.m_leftStickMagnitude = math.sqrt( self.m_leftStickX * self.m_leftStickX +
										   self.m_leftStickY * self.m_leftStickY )

	self.m_leftStickAngle = math.atan2( self.m_leftStickX, self.m_leftStickY )
	
	self.m_Trigger = hkbGetVariable("Trigger")
			
	local stickDifference = (self.m_lastLeftStickX - self.m_leftStickX) * 
							(self.m_lastLeftStickX - self.m_leftStickX) + 
							(self.m_lastLeftStickY - self.m_leftStickY) * 
							(self.m_lastLeftStickY - self.m_leftStickY)
	
	if( stickDifference < 0.1 ) then 	
		self.m_leftStickHoldTime =  self.m_leftStickHoldTime + hkbGetTimestep()		
	else		
		self.m_leftStickHoldTime = 0
	end
		
end

-- handle simple input and movement control
function OnUpdateSimpleLocomotion()
	
	-- update Locomotion Speed and Rotation
	CalculateMovementVector()	
	CalculateSpeeds()
				
	-- rotate Character
	if( g_gamepadState.m_Trigger > 0.5 or g_gamepadState.m_Trigger < -0.5 ) then

		hkbSetVariable("RotateAngle", g_gamepadState.m_Trigger / 5.0)
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
	hkbSetVariable("RotateAngle", turnAxis[2]*360)
end

-- calculates the movement vector 
function CalculateMovementVector()

	-- update the gamepad state
	g_gamepadState:update()

	-- get movement basis by projecting camera basis onto the floor
	local forward = hkVector4.new()
	-- forward:setSub4( g_cameraState.m_to, g_cameraState.m_from )
	forward:setSub4( hkVector4.new(0, -1, 0), hkVector4.new(0, 0, 0) )
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




