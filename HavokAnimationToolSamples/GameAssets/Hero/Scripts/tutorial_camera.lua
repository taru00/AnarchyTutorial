	-- helper table to store the state of the camera
g_cameraState = {
	m_from = hkVector4.new( 0.0, 5.0, 1.5 ),
	m_to = hkVector4.new( 0.0, 0.0, 0.5 ),
	m_up = hkVector4.new( 0, 0, 1.0 ),	
	
	m_worldUp = hkVector4.new(0.0, 0.0, 1.0),
	
	m_angle = 0,

	m_cameraFollowDistance = 5.0,
	
	m_orbitMaxSpeedX = 1.75,
	m_orbitMaxSpeedY = 1,	
	
	m_orbitSpeedX = 0.0,
	m_orbitSpeedY = 0.0,
	
	m_cameraArmLocalSpace = hkVector4.new(0, 1.0, 0.0)
}

	-- updates the camera in 3rd person mode
function g_cameraState:update3rdPerson()	
	
	-- update the orbit speed
	if( g_gamepadState.m_rightStickMagnitude < 0.1 ) then					 		
		self.m_orbitSpeedX = self.m_orbitSpeedX - self.m_orbitSpeedX * 0.1
		self.m_orbitSpeedY = self.m_orbitSpeedY - self.m_orbitSpeedY * 0.1
	else
		self.m_orbitSpeedX = clamp( self.m_orbitSpeedX + g_gamepadState.m_rightStickX * 0.05, 
								   -self.m_orbitMaxSpeedX, self.m_orbitMaxSpeedX)
		self.m_orbitSpeedY = clamp(self.m_orbitSpeedY + g_gamepadState.m_rightStickY * 0.05, 
								   -self.m_orbitMaxSpeedY, self.m_orbitMaxSpeedY)
	end		
	
	-- rotate the camera arm if the camera is moving
	if( (math.abs(self.m_orbitSpeedX) > 0) or (math.abs(self.m_orbitSpeedY) > 0) ) then
			
		-- prevent camera from rotating too high or too low		
		if (self.m_cameraArmLocalSpace[2] > 0.7 and self.m_orbitSpeedY > 0) or 
		   (self.m_cameraArmLocalSpace[2] < -0.1 and self.m_orbitSpeedY < 0) then		   
			
			self.m_orbitSpeedY = 0
			
		end			
		
		-- compute the x axis to rotate about
		local side = hkVector4.new(0, 0, 0)
		side:setCross(self.m_worldUp, self.m_cameraArmLocalSpace)
		side:normalize3()
				
		-- rotate about the x axis
		local rotationY = hkQuaternion.new(0, 0, 0, 1)	
		rotationY:setAxisAngle(side, -self.m_orbitSpeedY * hkbGetTimestep() )
		self.m_cameraArmLocalSpace:setRotatedDir(rotationY, self.m_cameraArmLocalSpace)
		
		-- rotate about the y axis
		local rotationX = hkQuaternion.new(0, 0, 0, 1)	
		rotationX:setAxisAngle(self.m_worldUp, -self.m_orbitSpeedX * hkbGetTimestep() )
		self.m_cameraArmLocalSpace:setRotatedDir(rotationX, self.m_cameraArmLocalSpace)
		
	end
	
	-- compute camera vectors from character position and camera arm	
	local targetTo = hkVector4.new(0, 0, 0)
	local targetFrom = hkVector4.new(0, 0, 0)
	
	targetTo = hkbGetOldWorldFromModel():getTranslation()
	targetTo[2] = targetTo[2] + 1.6
		
	targetFrom = hkbGetOldWorldFromModel():getTranslation()
	targetFrom[2] = targetTo[2]
	targetFrom:addMul4(self.m_cameraArmLocalSpace, self.m_cameraFollowDistance)	
	
	self.m_to:setInterpolate4(self.m_to, targetTo, .25)
	self.m_from:setInterpolate4(self.m_from, targetFrom, .33)
	self.m_up = self.m_worldUp
	
	-- set behavior variables to the local camera variables 
	hkbSetVariable("inputcamerafrom", self.m_from)
	hkbSetVariable("inputcamerato", self.m_to)
	hkbSetVariable("inputcameraup", self.m_up)
	
	-- compute camera angle for locomotion logic
	local forward = hkVector4.new()
	forward[0] = self.m_from[0] - self.m_to[0]
	forward[1] = self.m_from[1] - self.m_to[1]	
	forward[2] = 0
	forward:normalize3()
	self.m_angle = -math.atan2( forward[0], forward[1] )
	
end

	-- returns a value clamped between min and max
function clamp( value, min, max )
    if( value > max ) then return max end
    if( value < min ) then return min end
    return value
end