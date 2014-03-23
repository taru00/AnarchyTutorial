
CAMERA_MODE_DEFAULT = 0
CAMERA_MODE_STRAFE = 1
CAMERA_MODE_CLIMBING_LEDGE = 2

g_camera = {
	m_from = hkVector4.new( 0.0, 4.0, 2.5 ),
	m_to = hkVector4.new( 0.0, 0.0, 1.75 ),
	m_up = hkVector4.new( 0, 0, 1 ),
	m_forward = hkVector4.new( 0, 0, 0),
	
	m_angle = 0,

	m_mode = 0,
			
	m_targetLeadAmount = hkVector4.new(),	
	m_cameraFollowDistance = 5.0,
	
	m_orbitMaxSpeedX = 1.75,
	m_orbitMaxSpeedY = 1,	
	m_orbitSpeedX = 0.0,
	m_orbitSpeedY = 0.0,
	
	m_cameraArmLocalSpace = hkVector4.new(0, 1.0, 0.0)
}
 
	-- updates the camera
function g_camera:update( timestep )
		
	-- set the camera mode based on the active state
	self.m_mode = CAMERA_MODE_DEFAULT
	if( hkbIsNodeActive("Strafe Logic") ) then
		self.m_mode = CAMERA_MODE_STRAFE
	elseif( hkbIsNodeActive("Climb Behavior") or ( not hkbIsNodeActive("Leap Docking") and (hkbIsNodeActive("Leap Far Platform Clip") or hkbIsNodeActive("Leap Far Wall Clip"))) ) then
		self.m_mode = CAMERA_MODE_CLIMBING_LEDGE
	end
			
	-- compute the camera angle (cached for efficiency)
	self.m_forward[0] = self.m_from[0] - self.m_to[0]
	self.m_forward[1] = self.m_from[1] - self.m_to[1]	
	self.m_forward[2] = 0
	self.m_forward:normalize3()
	self.m_angle = math.atan2( self.m_forward[0], self.m_forward[1] )			
	
	-- update the orbit speed
	if( g_gamePad:isRightStickInDeadZone() ) then					 		
		self.m_orbitSpeedX = self.m_orbitSpeedX - self.m_orbitSpeedX * 0.1
		self.m_orbitSpeedY = self.m_orbitSpeedY - self.m_orbitSpeedY * 0.1
	else
		self.m_orbitSpeedX = clamp(self.m_orbitSpeedX + g_gamePad.m_rightStickX * 0.05, -self.m_orbitMaxSpeedX, self.m_orbitMaxSpeedX)
		self.m_orbitSpeedY = clamp(self.m_orbitSpeedY + g_gamePad.m_rightStickY * 0.05, -self.m_orbitMaxSpeedY, self.m_orbitMaxSpeedY)
	end		
	
	-- update the camera logic
	if( self.m_mode == CAMERA_MODE_STRAFE ) then
		g_camera:updateOverTheShoulderCamera( timestep )		
	else
		g_camera:update3dPersonCamera( timestep )
	end
	
	-- Set the HBT variables which control it
	hkbSetVariable("inputcamerafrom", self.m_from)
	hkbSetVariable("inputcamerato", self.m_to)
	hkbSetVariable("inputcameraup", self.m_up)	
end

function g_camera:update3dPersonCamera( timestep )	
		
	local checkVisible = true

	-- add support for a follow cam
	if(g_followCam) then
		local velocityDir = hkVector4.new()
		velocityDir:setSub4(g_characterState.m_currentPos, g_characterState.m_lastPos)
		local dotForward = self.m_cameraArmLocalSpace:dot3(g_characterState.m_forward)
		
		if(hkbIsNodeActive("Take Cover Behavior")) then
			velocityDir:setMul4(g_characterState.m_forward, -1)
		elseif((dotForward > 0) and not (hkbIsNodeActive("Locomotion State Machine") or hkbIsNodeActive("Hanging Logic"))) then
			velocityDir = g_characterState.m_forward
		end
		
		if(velocityDir:lengthSquared3() > 0.00001) then

			velocityDir:normalize3()
				
			local characterRight = hkVector4.new()
			characterRight:setCross(velocityDir, UP_DIRECTION)
			local dotRight = self.m_cameraArmLocalSpace:dot3(characterRight)
			
			local blendInSpeed = 0
			local maxDot = 0.5 
			local maxSpeed = self.m_orbitMaxSpeedX * 2.0
			
			if (hkbIsNodeActive("Drop Down To Docking")) then
				maxSpeed = maxSpeed * 2
			end
		
			if (dotRight > maxDot) then
				blendInSpeed = maxSpeed
			elseif (dotRight < -maxDot) then
				blendInSpeed = -maxSpeed
			else
				blendInSpeed = maxSpeed * (dotRight / maxDot)
			end
			
			local blend = 0.1
			self.m_orbitSpeedX = self.m_orbitSpeedX * (1 - blend) + blendInSpeed * blend
			
		end
	end
	
	-- rotate the camera arm if the camera is moving
	if( (math.abs(self.m_orbitSpeedX) > 0) or (math.abs(self.m_orbitSpeedY) > 0) ) then
	
		local side = hkVector4.new(0, 0, 0)
		side:setCross(UP_DIRECTION, self.m_cameraArmLocalSpace)
		side:normalize3()

		local armHeight = self.m_cameraArmLocalSpace[2]
		
		if	(armHeight > 0.7 and self.m_orbitSpeedY > 0) or 
			(armHeight < -0.1 and self.m_orbitSpeedY < 0) then
			
			self.m_orbitSpeedY = 0
		end
		
		
		local rotationY = hkQuaternion.new(0, 0, 0, 1)	
		rotationY:setAxisAngle(side, -self.m_orbitSpeedY * timestep )
		self.m_cameraArmLocalSpace:setRotatedDir(rotationY, self.m_cameraArmLocalSpace)
		
		local rotationX = hkQuaternion.new(0, 0, 0, 1)	
		rotationX:setAxisAngle(UP_DIRECTION, -self.m_orbitSpeedX * timestep )
		self.m_cameraArmLocalSpace:setRotatedDir(rotationX, self.m_cameraArmLocalSpace)
		
	end
	
	-- compute the target of the camera.  the target is the character's location
	-- plus a height offset (changes based on camera mode) plus a fraction of
	-- their velocity.
	local targetTo = nil
	
	-- add height offset based on mode
	if( self.m_mode == CAMERA_MODE_DEFAULT ) then
		targetTo = hkbGetOldWorldFromModel():getTranslation()
		targetTo[2] = targetTo[2] + 1.6
	elseif( self.m_mode == CAMERA_MODE_CLIMBING_LEDGE ) then		
		local headWorldSpace = hkQsTransform.new()
		local headIndex = hkbGetBoneIndex("Ribcage")
		local headModelSpace = hkbGetOldBoneModelSpace(headIndex)
		headWorldSpace:setMul(hkbGetOldWorldFromModel(), headModelSpace)
		targetTo = headWorldSpace:getTranslation()						
	end
	
	-- add a fraction of the character's velocity so that camera "leads" the character
	local scaledVelocity = hkbGetCharacterControllerVelocity()
	local targetToNoLead = hkVector4.new(targetTo)
	scaledVelocity:mul4(10 * timestep)		
	self.m_targetLeadAmount:setInterpolate4(self.m_targetLeadAmount, scaledVelocity, 5.0 * timestep )	
	targetTo:add4(self.m_targetLeadAmount)
	
	-- change the camera follow distance based on mode
	local cameraFollowDistance = nil
	if( self.m_mode == CAMERA_MODE_DEFAULT ) then
		cameraFollowDistance = g_normalFollowDistance
	elseif( self.m_mode == CAMERA_MODE_CLIMBING_LEDGE ) then		
		cameraFollowDistance = g_climbingFollowDistance
	end	
	self.m_cameraFollowDistance = interpolate( self.m_cameraFollowDistance, cameraFollowDistance, 0.05)
	
	-- compute the look at location of the camera.  this is at the same height as the
 	-- camera's target but rotated by the camera's arm
	local targetFrom = hkVector4.new()
	targetFrom = hkbGetOldWorldFromModel():getTranslation()
	targetFrom[2] = targetTo[2]
	targetFrom:addMul4(self.m_cameraArmLocalSpace, self.m_cameraFollowDistance)	
	
	if (checkVisible) then
		-- make sure the camera doesn't go through the wall
		local cameraDirection = hkVector4.new()
		cameraDirection:setSub4(targetFrom, targetTo)
		cameraDirection:normalize3()
			
		local hitTestTo = targetToNoLead
		local hitTestFrom = targetFrom
		--hitTestTo:setAddMul4(targetTo, cameraDirection, 0.3)
			
		local hit, hitFraction, hitNormal, hitPosition = hkbCastRay(targetToNoLead, hitTestFrom, 3)		
			
		if( hitFraction > 0.1 ) then
								 
			targetFrom:setAddMul4(hitPosition, cameraDirection, -0.05)

		end 
	end
	-- smoothly interpolate to the new targets
	self.m_to:setInterpolate4(self.m_to, targetTo, .25)
	self.m_from:setInterpolate4(self.m_from, targetFrom, .33)
	self.m_up = UP_DIRECTION
	
end

function g_camera:updateOverTheShoulderCamera( timestep )

	---- update the aim angle
	g_characterState.m_aimTargetCameraAngleX = angleDiff(g_characterState.m_aimTargetCameraAngleX + self.m_orbitSpeedX * timestep)
	g_characterState.m_aimTargetCameraAngleY = angleDiff(g_characterState.m_aimTargetCameraAngleY + self.m_orbitSpeedY * timestep)

	-- get the head position in world space
	local headWorldSpace = hkQsTransform.new()
	local headIndex = hkbGetBoneIndex("Head")
	local headModelSpace = hkbGetOldBoneModelSpace(headIndex)
	headWorldSpace:setMul(hkbGetOldWorldFromModel(), headModelSpace)	
	
	-- compute the target to
	local targetTo = hkVector4.new()
	targetTo:setRotatedDir(hkQuaternion.new(UP_DIRECTION, -g_characterState.m_aimTargetCameraAngleX), FORWARD_DIRECTION)
	targetTo:setRotatedDir(hkQuaternion.new(LEFT_DIRECTION, g_characterState.m_aimTargetCameraAngleY), targetTo)	
	targetTo:setAddMul4(hkbGetOldWorldFromModel():getTranslation(), targetTo, 10.0)
	--targetTo[2] = headWorldSpace:getTranslation()[2] * 0.75

	local forward = hkVector4.new()
	forward:setSub4(targetTo, hkbGetOldWorldFromModel():getTranslation() )
	forward:normalize3()
	
	local side = hkVector4.new()
	side:setCross( forward, UP_DIRECTION )	
			
	local targetFrom = headWorldSpace:getTranslation()
	targetFrom[2] = 2
	targetFrom:addMul4(forward, -2.5)
	targetFrom:addMul4(side, -0.75)	
	targetFrom:addMul4(UP_DIRECTION, 0.1)	
		
	self.m_to:setInterpolate4(self.m_to, targetTo, 0.3)
	self.m_from:setInterpolate4(self.m_from, targetFrom, 0.5)
	
	--hkDebugDisplay.showPoint(targetTo, hkDebugDisplay.YELLOW)
	
	self.m_up = UP_DIRECTION
end
