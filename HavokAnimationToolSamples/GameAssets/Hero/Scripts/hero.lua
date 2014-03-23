-- constants
TWO_PI = 2.0 * 3.14159
DEG_TO_RAD = (3.14159 / 180.0)
RAD_TO_DEG = (180.0 / 3.14159)

X_AXIS = hkVector4.new( 1, 0, 0 )
Y_AXIS = hkVector4.new( 0, 1, 0 )
Z_AXIS = hkVector4.new( 0, 0, 1 )

UP_DIRECTION = hkVector4.new( 0, 0, 1 )
FORWARD_DIRECTION = hkVector4.new( 0, -1, 0 )
LEFT_DIRECTION = hkVector4.new( 1, 0, 0 )

-- follow cam variables
g_followCam = false
g_normalFollowDistance = 5.0
g_climbingFollowDistance = 3.5

-- interpolates a scalar value
function interpolate( a, b, t )
	return ((1.0 - t) * a) + (t * b)		
end

-- returns a value clamped between min and max
function clamp( value, min, max )
    if( value > max ) then return max end
    if( value < min ) then return min end
    return value
end

-- clamps an angle to the rangle of [-2PI, 2PI]
function angleDiff( diff )
    if (diff > TWO_PI/2) then diff = diff - TWO_PI end
    if (diff < -TWO_PI/2) then diff = diff + TWO_PI end
    return diff
end

-- the lua state of the character
g_characterState = {
	
	m_timestep = 0.0,
	
	m_angle = 0.0,
	
	m_aimAngleX = 0.0,
	m_aimAngleY = 0.0,
	
	m_forward = hkVector4.new(),
		
	m_aimTargetCameraAngleX = 0.0,
	m_aimTargetCameraAngleY = 0.0,
	
	m_characterWidth = 0.01,
	m_dockedSpeed = 0.0,	
	m_dockedMaxSpeed = 1.0,	
	m_dockedAcceleration = 0.1,	
	m_dockingTarget = nil,
	m_lineLength = 0.0,
	m_distanceOnLine = 0.0,
	m_lineParam = 0.0,
	m_dockedMoveDirection = 0.0,
	m_stickDirection = hkVector4.new(),
	
	m_currentPos = hkVector4.new(),
	m_lastPos = hkVector4.new(),
	
	m_fallTimer = 0,
	m_fallVelocity = nil,
	
	m_isSupported = true,
	m_isSupportedCounter = 0,
	m_checkForFalling = false,
	
	m_coverToCover = false,
	
	m_desiredJumpAngle = 0,
	
	m_pushingIntoWall = false
}

	-- root level update.  called everyframe to update the character.
function onUpdateRoot()

	g_gamePad:update( hkbGetTimestep() )
	g_camera:update( hkbGetTimestep() )

	if( g_lineWorld ~= nil ) then	
		g_lineWorld:drawLines()
	end
	
	-- record the timestep
	g_characterState.m_timestep = hkbGetTimestep()
	 
	-- Compute the character angle (cached for efficiency)
	local fwd = hkVector4.new( 1, 0, 0 )
	fwd:setRotatedDir( hkbGetOldWorldFromModel():getRotation(), X_AXIS)
	g_characterState.m_angle = math.atan2( fwd[1], fwd[0] )
	
	-- store off the characters forward direction
	g_characterState.m_forward:setRotatedDir(hkbGetOldWorldFromModel():getRotation(), FORWARD_DIRECTION)
	
	-- Compute which foot is forward and store it in a behavior variable
	local leftLegIndex = hkbGetBoneIndex("LeftLegCalf")
	local rightLegIndex = hkbGetBoneIndex("RightLegCalf")
	
	local leftLegModelSpace = hkbGetOldBoneModelSpace(leftLegIndex)
	local rightLegModelSpace = hkbGetOldBoneModelSpace(rightLegIndex)
		
	local leftForward = leftLegModelSpace:getTranslation():dot3(FORWARD_DIRECTION)
	local rightForward = rightLegModelSpace:getTranslation():dot3(FORWARD_DIRECTION)
			
	if rightForward > leftForward then		
		hkbSetVariable("IsRightFootForward", 1)		
	else		
		hkbSetVariable("IsRightFootForward", 0)	
	end
	
	-- record consecutive positions so we can derive the character velocity
	g_characterState.m_lastPos = g_characterState.m_currentPos
	g_characterState.m_currentPos = hkbGetOldWorldFromModel():getTranslation()
	
	-- check if the character is supported with a raycast
	local from = hkVector4.new()
	local to = hkVector4.new()	
	
	local velocity = hkbGetCharacterControllerVelocity()
	velocity[2] = 0.0
		
	local castAhead = hkVector4.new()
	castAhead:setMul4(hkbGetTimestep() * 8.0, velocity)
	local castAheadLength = castAhead:normalizeWithLength3()
	castAhead:mul4( math.min( castAheadLength, 0.7 ) )
	
	from:setAdd4( g_characterState.m_currentPos, castAhead )
	from[2] = from[2] + 0.25

	to:setAddMul4(from, UP_DIRECTION, -1.0)
	
	local hitGround = true;
    if (castAhead:isOk3()) then
        hitGround = hkbCastRay(from, to)
    end
	
	if( hitGround == true ) then		
		g_characterState.m_isSupportedCounter = 0
		g_characterState.m_isSupported = true
	else
		g_characterState.m_isSupportedCounter = g_characterState.m_isSupportedCounter + 1
		g_characterState.m_isSupported = g_characterState.m_isSupportedCounter < 3		
	end
	
	if( g_characterState.m_isSupported == true ) then
		--hkDebugDisplay.showLine(from, to, hkDebugDisplay.RED)
	else		
		--hkDebugDisplay.showLine(from, to, hkDebugDisplay.GREEN)
		
		-- check if the character should fall
		local isFalling = hkbIsNodeActive("Jump Behavior")
		local isHanging = hkbIsNodeActive("Climb Behavior")
		local isVaulting = hkbIsNodeActive("Vault Behavior") or hkbIsNodeActive("Vault Right Behavior")
		local isLeaping = hkbIsNodeActive("Leap Script")
		local isStrafing = hkbIsNodeActive("Strafe Logic")
		local isTakingCover = hkbIsNodeActive("Take Cover Behavior")
		
		local wantsToHang = g_gamePad.m_leftTrigger > 0.5
		
		-- fall if not falling or hanging		
		if(g_characterState.m_checkForFalling or
			( isFalling == false and 
		    isHanging == false and 
			isVaulting == false and 
			isLeaping == false and 
			isStrafing == false and
			isTakingCover == false)) then
		
			if( wantsToHang == true ) then
				tryCatchPlatform()
			end
			
			-- cast a secondary ray to determine if this is a short or long fall
			to:setAddMul4(from, UP_DIRECTION, -5.0)
			hitGround = hkbCastRay(from, to)
			
			if(hitGround) then
				hkbSetVariable("FallingSelector", 0)
			else
				hkbSetVariable("FallingSelector", 1)
			end
		
			hkbFireEvent("Fall")
		end										
	end
	
	-- try to determine if we are pushing into a wall in front of us
	from:setAddMul4( g_characterState.m_currentPos, UP_DIRECTION, 0.5 )
	to:setAddMul4( from, g_characterState.m_forward, 1.0 )
	
	local hitFrontWall
	local frontWallFraction 
	local frontWallNormal
	
	hitFrontWall, frontWallFraction, frontWallNormal = hkbCastRay(from, to)
	
	g_characterState.m_pushingIntoWall = false
	if hitFrontWall and (frontWallNormal:dot3(g_gamePad.m_leftDirection) < -0.7) then
		g_characterState.m_pushingIntoWall = true
	end
	
	if ((g_characterState.m_dockingTarget ~= nil) and (g_characterState.m_dockingTarget.m_lineType ~= nil)) then
	
		local line = hkVector4.new()
		local toLine = hkVector4.new()					
		line:setSub4(g_characterState.m_dockingTarget.m_b, g_characterState.m_dockingTarget.m_a)				
		toLine:setSub4(hkbGetOldWorldFromModel():getTranslation(), g_characterState.m_dockingTarget.m_a)		
		
		g_characterState.m_lineLength = line:length3()
		g_characterState.m_distanceOnLine = line:dot3(toLine) / g_characterState.m_lineLength
		g_characterState.m_lineParam = g_characterState.m_distanceOnLine / g_characterState.m_lineLength
		
		local stickAngle = angleDiff(-g_gamePad.m_padAngle - g_camera.m_angle - 180 * DEG_TO_RAD )	
		local stickRotation = hkQuaternion.new( UP_DIRECTION, stickAngle )	
		g_characterState.m_stickDirection = hkVector4.new()
		g_characterState.m_stickDirection:setRotatedDir(stickRotation, Y_AXIS)
		g_characterState.m_dockedMoveDirection = g_characterState.m_stickDirection:dot3(line)
	
	end
		
end

	-- root level event raised.  called whenever an event is raised
function onRootEventRaised()

	-- get the name of the event that was raised	
	local eventName = hkbGetHandleEventName()
		
	-- perform the correct action
	if( eventName == "Action" ) then	
		
		if hkbIsNodeActive("Hanging Logic") then
			undockPlatform()
		elseif hkbIsNodeActive("In Cover Docking") then	
			coverToCover()
		elseif not (hkbIsNodeActive("Vault Behavior") or hkbIsNodeActive("Take Cover Behavior"))  then		
			takeCover()
		
		end
		
	elseif( eventName == "JumpButton" ) then
		
		if	not hkbIsNodeActive("Weapon Chooser") and
			not hkbIsNodeActive("Climb Behavior") and
			not hkbIsNodeActive("Leap Behavior") and
			not hkbIsNodeActive("Take Cover Behavior") and
			not hkbIsNodeActive("Vault Behavior") and
			not hkbIsNodeActive("Vault Right Behavior") and
			not (hkbIsNodeActive("Jump Behavior") and not hkbIsNodeActive("Land Logic")) and
			not hkbIsNodeActive("Strafe Blend") then
		
			
			-- try to execute any of the jumping actions
			if( not jumpActions() ) then
			
				-- the character can jump while blocked, so clear out the blocking angle
				g_characterState.m_lastBlockedAngle = nil
		
				
				if hkbIsNodeActive("Idle Logic") then
					hkbFireEvent("JumpOnSpot")
				else
					hkbFireEvent("JumpFromRun")
				end
				
			end
		end
		
	elseif( eventName == "Strafe" ) then
				
		g_characterState.m_aimTargetCameraAngleX = g_camera.m_angle
		g_characterState.m_aimTargetCameraAngleY = -0.14
		
		g_camera.m_mode = 1
			
	elseif( eventName == "ToIdle" ) then
			
		g_camera.m_mode = 0
	
	elseif( eventName == "WeaponToggle" ) then	
		
		local hanging = (g_characterState.m_dockingTarget ~= nil) and 
						((g_characterState.m_dockingTarget.m_lineType == LINE_TYPE_LEDGE) or 
						(g_characterState.m_dockingTarget.m_lineType == LINE_TYPE_PLATFORM))
		
		if( hkbIsNodeActive("Idle Sword") ) then		
			hkbSetVariable("WeaponType", 0)
			hkbFireEvent("SheathSword")
		-- if we are docked to a platform (boxType 2) then don't draw the sword						
		elseif (g_characterState.m_dockingTarget == nil) or (not hanging) then
			hkbFireEvent("DrawSword")		
		end
		
	elseif( eventName == "SwordDrawn" ) then
	
		hkbSetVariable("WeaponType", 1)	
		
	-- This is used by the Delayed Animation Loading Demo only
	elseif( eventName == "UnloadNonLocomotionBundles" ) then
	
		-- Unload non-locomotion bundles
		-- This means that only locomotion movement will be possible
		hkbUnloadAnimationAssets("Default_Bundle", "Cover_Bundle");
		
	-- This is used by the Delayed Animation Loading Demo only
	elseif( eventName == "LoadBundles" ) then
	
		-- Ensure all animations are loaded
		hkbLoadAnimationAssets();

	-- This is used by the Asynchronous Animation Loading Demo only
	elseif( eventName == "UnloadBundles" ) then
	
		-- Unload all animations attached to this character.
		hkbUnloadAnimationAssets();
			
	-- This is used by the Asynchronous Animation Loading Demo only
	elseif( eventName == "LoadLocomotionBundle" ) then
	
		-- Only load the 'Locomotion_Bundle' bundle.
		hkbLoadAnimationAssets("Locomotion_Bundle");
	end
	
end

JUMP_ACTION_JUMP_TO_PLATFORM = 0
JUMP_ACTION_LEAP_TO_PLATFORM = 1
JUMP_ACTION_VAULT = 2

function jumpActions()

	local line = nil
	local selectedLine = nil
	local selectedDistance = 0
	local closestDistance = 10000000.0	
	local jumpAction = -1
	
	-- try to find a jump to platform line
	line, closestDistance = g_lineWorld:findLineToDockTo( g_jumpToPlatformDock, closestDistance )
	
	if(line ~= nil) then
		selectedLine = line
		selectedDistance = closestDistance
		jumpAction = JUMP_ACTION_JUMP_TO_PLATFORM

	end
	
	-- try to find a leap to platform line
	line, closestDistance = g_lineWorld:findLineToDockTo( g_leapToPlatformDock, closestDistance )
	if(line ~= nil) then
		selectedLine = line
		selectedDistance = closestDistance
		jumpAction = JUMP_ACTION_LEAP_TO_PLATFORM
		
	end
		
	-- try to find a vaulting line
	line, closestDistance = g_lineWorld:findLineToDockTo( g_lowVaultDock, closestDistance )
	if(line ~= nil) then
		selectedLine = line
		selectedDistance = closestDistance
		jumpAction = JUMP_ACTION_VAULT
		
	end

	-- execute the appropriate behavior given the line type we've discovered
	
	if(jumpAction == JUMP_ACTION_JUMP_TO_PLATFORM) then
		return jumpToPlatform(selectedLine, selectedDistance)
		
	elseif(jumpAction == JUMP_ACTION_LEAP_TO_PLATFORM) then
		return leapToPlatform(selectedLine, selectedDistance)
		
	elseif(jumpAction == JUMP_ACTION_VAULT) then
		return vaultLowWall(selectedLine, selectedDistance)
		
	end
	
	return false
end
