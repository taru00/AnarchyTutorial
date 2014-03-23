
	-- Logic ran while the character is in the idle state. 
function onUpdateIdle()	
	
	-- if the user is pushing the gamepad out of the dead zone start walking or running
	if (not g_gamePad:inLeftStickInDeadZone() and g_gamePad:isLeftStickStationary() and (g_characterState.m_pushingIntoWall == false)) then
		
		-- walk if the left trigger is pressed
		local shouldWalk = g_gamePad.m_leftTrigger > 0.5
		
		-- pick the correct animation based on the direction the user wants to go		
		local animationIndex = -1		
		if( shouldWalk == true ) then
			animationIndex = radialSelectAnimation(4)			
		else
			animationIndex = radialSelectAnimation(8)
		end
		
		-- set the variable of the animation index
		hkbSetVariable("AnimationIndex", animationIndex)
		
		-- raise the event to start walking or running
		if( shouldWalk == true ) then
			hkbFireEvent("StartWalking")
		else
			hkbFireEvent("StartRunning")
		end		
			
	end
		
end

	-- logic ran while the character is in the idle to run state
function onUpdateIdleToRun()

	-- check if the user is starting and stoping.  if so stop and do a stutter step
	if ( g_gamePad:inLeftStickInDeadZone() and g_gamePad:hasLeftStickBeenStationary(0.1) ) then		
		hkbFireEvent("Stop")		
	end
				
end

	-- logic ran while the character is in the running state
function onUpdateRunning()

	local wantsToWalk = g_gamePad.m_leftTrigger > 0.5
	local isWalking = hkbIsNodeActive("Walking Logic")

	-- check if the user is running but wants to start walking
	if( isWalking == false and wantsToWalk == true ) then
		hkbFireEvent("StartWalking")
		return
	end
	
	-- check if the user is walking but wants to start running
	if( isWalking == true and wantsToWalk == false ) then
		hkbFireEvent("StartRunning")
		return
	end	

	-- check if we should return to the idle state
	if ( g_gamePad:inLeftStickInDeadZone() and g_gamePad:hasLeftStickBeenStationary(0.1) ) or g_characterState.m_pushingIntoWall then
		hkbFireEvent("Stop")	
	end
	
	-- don't try to turn if the character is already turning	
	if( hkbIsNodeActive("Run Turn") == true or hkbIsNodeActive("Walk Turn") == true ) then
		return
	end
		
	-- compute the difference between the direction the character is facing 
	-- and the direction the user wants to go in
	local characterDifference = computeDifference()	
	
	-- if the difference is greater than this about, turn the character
	local fullTurnThreashold = 115 * DEG_TO_RAD
	
	-- if the difference is large, then turn 180 degrees
	if ( (math.abs(characterDifference) > fullTurnThreashold) and g_gamePad:isLeftStickStationary() ) then		
		hkbFireEvent("Turn180")		
	end
	
end

	-- prodedural animation code applied when the character is running
function onGenerateRunning()
	
	-- don't try to turn if the character is already turning	
	if( hkbIsNodeActive("Run Turn") == true or hkbIsNodeActive("Walk Turn") == true ) then
		return
	end
	
	-- compute the difference between the direction the character is facing 
	-- and the direction the user wants to go in	
	local characterDifference = computeDifference()
	
	-- use a different turn speed if the character is walking or running
	local turnSpeed = 3.0
	if( hkbIsNodeActive("Walking Logic") == true ) then
		turnSpeed = 2.0
	end		
	
	-- slowly rotate the character to point in the direction the user wants him to  be in
	hkbSetWorldFromModel( hkbGetWorldFromModel() * hkQsTransform.new( Z_AXIS, characterDifference * turnSpeed * g_characterState.m_timestep ) )	
	
end

	-- divides a circle into numSlices and returns the index (in clockwise order) of the slice which
	-- contains the gamepad's angle relative to the camera.
function radialSelectAnimation( numSlices )
	
	-- compute the angle that the character wants to go relative to the camera
	local angle = g_camera.m_angle + g_gamePad.m_padAngle + g_characterState.m_angle + (TWO_PI / (numSlices * numSlices) )
	
	-- map the angle into the range 0 to 2 pi
	if ( angle < 0 ) then
		angle = angle + TWO_PI 
    end
		angle = angle - TWO_PI * math.floor( angle / TWO_PI )
			
	-- select the segement that points in that direction
	return math.floor(angle / TWO_PI * numSlices )
	
end

	-- computes the difference between the characters current heading and the
	-- heading the user wants them to go in.
function computeDifference()

	-- if the user is not pushing the stick anywhere return.  this prevents the character from turning while stopping (which
	-- looks bad - like the skid to stop animation)
	if( g_gamePad.m_padMagnitude < 0.5 ) then
		return 0
	end
	
	-- check the difference between the characters current heading and the desired heading from the gamepad
	return angleDiff( -g_gamePad.m_padAngle - g_camera.m_angle - g_characterState.m_angle )			
	
end

	--<rev.jjt> Add timestep to calculation.
	--<rev.jjt> Use global gravity variable.
function onGenerateFalling()		
	
	if(g_characterState.m_lastPos ~= nil) then
	
		-- calculate a simple trajectory using Verlet integration
		local nextPos = hkVector4.new()
		local gravity = hkVector4.new(0, 0, -0.01)
		
		nextPos:setMul4(2, g_characterState.m_currentPos)
		nextPos:setAddMul4(nextPos, g_characterState.m_lastPos, -1)
		nextPos:setAdd4(nextPos, gravity)
		
		local newWorldFromModel = hkQsTransform.new()
		
		newWorldFromModel:setTranslation(nextPos)
		newWorldFromModel:setRotation(hkbGetWorldFromModel():getRotation())
		
		hkbSetWorldFromModel(newWorldFromModel)	
	
	end	
		
end

function onHandleEventsRunJumpIntro()

	-- get the name of the event that was raised	
	local eventName = hkbGetHandleEventName()
	
	-- If we are mid jump, test falling
	if (eventName == "Mid Jump") then
		g_characterState.m_checkForFalling = true
	elseif (eventName == "LandMove") then
		g_characterState.m_checkForFalling = false
	end
end

function onUpdateStrafing()

	-- calculate walk speed
	local oldWalkSpeed = hkbGetVariable("WalkSpeed")
	local newWalkSpeed = math.sqrt(g_gamePad.m_leftStickX * g_gamePad.m_leftStickX + g_gamePad.m_leftStickY * g_gamePad.m_leftStickY)
	
	-- dampen the walkSpeed variable
	local dampening = 0.2
	local walkSpeed = oldWalkSpeed * (1.0 - dampening) + newWalkSpeed * dampening
	
	hkbSetVariable("WalkSpeed", walkSpeed)
	
	-- calculate walk angle
	local oldWalkAngle = hkbGetVariable("WalkDirection")
	local newWalkAngle = g_gamePad.m_padAngle / 180 * RAD_TO_DEG
	
	-- reloop the newWalkAngle so that it is locally near the oldWalkAngle
	-- <rev.jjt> use a common function here (think there is one in hero.lua)
	if(math.abs(newWalkAngle - oldWalkAngle) > 1.0) then
		if (newWalkAngle > oldWalkAngle) then
			newWalkAngle = newWalkAngle - 2
		else
			newWalkAngle = newWalkAngle + 2
		end
	end
	
	-- dampen the walkAngle variable
	-- <rev.jjt> add a common "damp" function
	local walkAngle = oldWalkAngle * (1.0 - dampening) + newWalkAngle * dampening
	
	-- reloop the walk angle to the original branch
	if(walkAngle > 1) then
		walkAngle = walkAngle - 2
	elseif(walkAngle < -1) then
		walkAngle = walkAngle + 2
	end
	
	hkbSetVariable("WalkDirection", walkAngle)
				 	
end

function onGenerateStrafing()

	-- align the character to the target
	local difference = angleDiff(-g_characterState.m_aimTargetCameraAngleX - g_characterState.m_angle)
	hkbSetWorldFromModel( hkbGetWorldFromModel() * hkQsTransform.new( Z_AXIS, difference * 5.0 * g_characterState.m_timestep ) )
				
end

function onActivateRunJumpIntro()

	m_desiredJumpAngle = -g_gamePad.m_padAngle - g_camera.m_angle
	
end

function onDeactivateRunJumpIntro()

	g_characterState.m_checkForFalling = false
	
end

function onGenearteRunJumpIntro()

	local difference = angleDiff( m_desiredJumpAngle - g_characterState.m_angle )
	hkbSetWorldFromModel( hkbGetWorldFromModel() * hkQsTransform.new( Z_AXIS, difference * 5.0 * hkbGetTimestep() ) )	
end

function onActivateFalling()
	hkbSetVariable("ApplyGravity", false)
end

function onDeactivateFalling()
	hkbSetVariable("ApplyGravity", true)
end
	-- Sometimes the Land event isn't fired correctly and so the character floats
function onUpdateFalling()

	if( g_characterState.m_isSupported == true ) then
		
		if( g_gamePad:inLeftStickInDeadZone() or (hkbGetVariable("FallingSelector") == 1)) then
			hkbFireEvent("LandStop")
		else
			hkbFireEvent("LandMove")
		end
		
	end
	
end
