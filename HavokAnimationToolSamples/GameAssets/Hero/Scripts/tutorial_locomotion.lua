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
	
	m_lastLeftStickX = 0,
	m_lastLeftStickY = 0,
		
	m_leftStickHoldTime = 0
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

	-- called every time the run state is updated
function onRunUpdate()

	-- if the magnatiude is low enough stop running, otherwise procedurally rotate the character
	if( g_gamepadState.m_leftStickMagnitude < 0.5 and g_gamepadState.m_leftStickHoldTime > 0.1 ) then	
	
		hkbFireEvent("Stop")		
			
	elseif( g_gamepadState.m_leftStickMagnitude > 0.5 ) then
	-- otherwise, check if the difference between the gamepad's angle and the character's angle 
	-- is large enough for a 180 turn	
	
		-- compute the difference between the gamepad's angle and the character's angle
		local directionDifference = computeDifference()	
	
		-- if the difference is greater than this about, turn the character
		local turn180Threashold = 115 * DEG_TO_RAD
	
		-- if the difference is large, then turn 180 degrees
		if ( (math.abs(directionDifference) > turn180Threashold) ) then		
			
			hkbFireEvent("Turn180")
			
		end
	
	end
	
end

	-- called every time the run state is generated
function onRunGenerate()

	-- don't try to turn if the character is already turning	
	if( hkbIsNodeActive("Run Turn 180") ) then
		return
	end

	-- only rotate the character if the user is pushing up on the stick
	if( g_gamepadState.m_leftStickMagnitude > 0.5 ) then
	
		-- compute the difference between the gamepad's angle and the character's angle
		local directionDifference = computeDifference()	
		
		-- compute the amount to turn the character
		local turnSpeed = 4.0
		local turnAmount = directionDifference * turnSpeed * hkbGetTimestep()
		
		-- rotate the character to match the target angle
		hkbSetWorldFromModel(hkbGetWorldFromModel() * hkQsTransform.new( UP_AXIS, -turnAmount))
		
	end
			
end

	-- called every time the idle to run state is updated
function onIdleToRunUpdate()

	if( g_gamepadState.m_leftStickMagnitude < 0.5 ) then
	
		hkbFireEvent("Stop")
		
	end

end

	-- computes the difference between the gamepad's angle and the character's angle
function computeDifference()	
		
	-- compute the angle of the character
	local forward = hkVector4.new(0, 1, 0)
	forward:setRotatedDir(hkbGetOldWorldFromModel():getRotation(), forward)
	local characterAngle = math.atan2( forward[0], forward[1] )
		
	-- compute the difference between the gamepad's angle and the character's angle
	local directionDifference = g_gamepadState.m_leftStickAngle - g_cameraState.m_angle - characterAngle
	
	-- keep the difference in the range of [0, pi]
	if( directionDifference < -PI ) then
		directionDifference = directionDifference + TWO_PI
	end
	if( directionDifference > PI) then
		directionDifference = directionDifference - TWO_PI
	end
	
	return directionDifference
	
end

	-- called every time the locomotion state is updated
function onLocomotionUpdate()
	
	-- update the gamepad state
	g_gamepadState:update()
	-- update the camera state	
	g_cameraState:update3rdPerson()
	
	-- Compute which foot is forward and store it in a behavior variable
	local leftLegIndex = hkbGetBoneIndex("LeftLegCalf")
	local rightLegIndex = hkbGetBoneIndex("RightLegCalf")
	
	local leftLegModelSpace = hkbGetOldBoneModelSpace(leftLegIndex)
	local rightLegModelSpace = hkbGetOldBoneModelSpace(rightLegIndex)
		
	local leftForward = leftLegModelSpace:getTranslation():dot3(FORWARD_AXIS)
	local rightForward = rightLegModelSpace:getTranslation():dot3(FORWARD_AXIS)
			
	if rightForward > leftForward then		
		hkbSetVariable("IsRightFootForward", 1)		
	else		
		hkbSetVariable("IsRightFootForward", 0)
	end
	
end
