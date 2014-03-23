g_gamePad = {
	m_padAngle = 0,
	m_padMagnitude = 0,
	m_previousLeftStickX = 0,
	m_previousLeftStickY = 0,
	m_leftStickX = 0,
	m_leftStickY = 0,
	m_leftStickHoldTime = 0,
	m_rightStickX = 0,
	m_rightStickY = 0,
	m_leftTrigger = 0,
	m_rightTrigger = 0,
	m_leftDirection = nil,
	m_rightDirection = nil
}

	-- update gamepad variables
function g_gamePad:update( timestep )
	self.m_previousLeftStickX = self.m_leftStickX
	self.m_previousLeftStickY = self.m_leftStickY
		
	self.m_leftStickX = interpolate(self.m_leftStickX, hkbGetVariable ("LeftStickX"), 0.9)
	self.m_leftStickY = interpolate(self.m_leftStickY, hkbGetVariable ("LeftStickY"), 0.9)
	self.m_rightStickX = interpolate(self.m_rightStickX, hkbGetVariable ("RightStickX"), 0.9)
	self.m_rightStickY = interpolate(self.m_rightStickY, hkbGetVariable ("RightStickY"), 0.9)	
	
	self.m_padAngle = math.atan2( self.m_leftStickX, -self.m_leftStickY )
	self.m_padMagnitude = math.sqrt(self.m_leftStickX * self.m_leftStickX + self.m_leftStickY * self.m_leftStickY)
	self.m_leftTrigger = hkbGetVariable("LeftTrigger")
				
	local diff = (self.m_previousLeftStickX - self.m_leftStickX) * (self.m_previousLeftStickX - self.m_leftStickX) + (self.m_previousLeftStickY - self.m_leftStickY) * (self.m_previousLeftStickY - self.m_leftStickY)
	if diff < 0.1 then		
		self.m_leftStickHoldTime = self.m_leftStickHoldTime + timestep
	else		
		self.m_leftStickHoldTime = 0;
	end	
	
	self.m_leftDirection = hkVector4.new(0, 0, 0)
	self.m_rightDirection = hkVector4.new(0, 0, 0)
	
	-- calculate the world space direction associated with the stick values
	if ((self.m_leftStickX * self.m_leftStickX + self.m_leftStickY * self.m_leftStickY) > 0.1) then
		local x = self.m_leftStickY * g_camera.m_forward[0] - self.m_leftStickX * g_camera.m_forward[1]
		local y = self.m_leftStickY * g_camera.m_forward[1] + self.m_leftStickX * g_camera.m_forward[0]
		self.m_leftDirection:set(x, y, 0, 0)
		self.m_leftDirection:normalize3()
		
	end
	
	if ((self.m_rightStickX * self.m_rightStickX + self.m_rightStickY * self.m_rightStickY) > 0.1) then
		local x = self.m_rightStickY * g_camera.m_forward[0] - self.m_rightStickX * g_camera.m_forward[1]
		local y = self.m_rightStickY * g_camera.m_forward[1] + self.m_rightStickX * g_camera.m_forward[0]
		self.m_rightDirection:set(x, y, 0, 0)
		self.m_rightDirection:normalize3()
		
	end
end

-- Returns true if the left game pad hasn't moved since the last update
function g_gamePad:isLeftStickStationary()
	return self.m_leftStickHoldTime > 0.01
end

-- Returns true if the left game stick hasn't moved in the given time frame
function g_gamePad:hasLeftStickBeenStationary( value )
	return self.m_leftStickHoldTime > value
end

-- Returns true if the left stick is the dead zone, false otherwise
function g_gamePad:inLeftStickInDeadZone()
	return (self.m_leftStickX * self.m_leftStickX + self.m_leftStickY * self.m_leftStickY) < 0.1
end

-- Returns true if the right stick is the dead zone, false otherwise
function g_gamePad:isRightStickInDeadZone()
	return (self.m_rightStickX * self.m_rightStickX + self.m_rightStickY * self.m_rightStickY) < 0.1
end
