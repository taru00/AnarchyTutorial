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
	
	m_DPadFW = 0,
	m_DPadBW = 0,
	m_DPadLeft = 0,
	m_DPadRight = 0,	
	m_isPreviousDPadPressed = 0,
	m_isDPadPressed = 0,
	m_isDPadReleased = 0
}


	-- updates the state of the gamepad
function g_gamepadState:update()
	
	self.m_DPadFW = hkbGetVariable("D Pad FW")
	self.m_DPadBW = hkbGetVariable("D Pad BW")
	self.m_DPadLeft = hkbGetVariable("D Pad Left")
	self.m_DPadRight = hkbGetVariable("D Pad Right")
	
	self.m_isPreviousDPadPressed = self.m_isDPadPressed
		
	if(self.m_DPadFW == 1.0 or self.m_DPadBW == 1.0 or self.m_DPadLeft == 1.0 or self.m_DPadRight == 1.0) then
		self.m_isDPadPressed = 1		
	else
		self.m_isDPadPressed = 0
	end		

	if(self.m_isPreviousDPadPressed == 1 and self.m_isDPadPressed == 0) then
		self.m_isDPadReleased = 1
	else
		self.m_isDPadReleased = 0
	end
	
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

	-- called every time the idle state is updated
function onIdleUpdate()
	
	local numDirections = 8
	
	-- if the magnatiude is high enough start running
	if( g_gamepadState.m_leftStickMagnitude > 0.5 ) then
		
		-- compute the difference between the gamepad's angle and the character's angle
		local directionDifference = computeDifference()
		
		-- select the animation
		local directionVariable = math.floor(directionDifference / (PI / (numDirections / 2)) + 0.5)
		
		-- since the range of the direction variable is [-3, 3] we need to map negative
		-- values to the animation index range in our selector which is [0,7]
		if( directionVariable < 0 ) then
			directionVariable = directionVariable + numDirections
		end
		
		-- select the animation in the manual selector generator
		hkbSetVariable("DirectionAnimation", directionVariable)
		
		-- raise the event to go (but don't spam the event queue)
		if( hkbIsNodeActive("Idle to Run Selector") == false ) then		
			
			hkbFireEvent("Go")
			
		end
		
	end
	
end	
