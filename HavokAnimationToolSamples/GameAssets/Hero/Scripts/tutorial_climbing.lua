-- Docking Target types
TARGET_TYPE_SHORT_WALL = 0
TARGET_TYPE_TALL_WALL = 1
TARGET_TYPE_LEDGE = 3

-- define some test Docking Targets
g_numTargets = 1
g_targets = {
	{
		m_start = hkVector4.new(-5, 5, 3),
		m_finish = hkVector4.new(5, 5, 3),
		m_rot = hkQuaternion.new(0, 0, 1, 0),
		m_type = TARGET_TYPE_LEDGE
	}
}

-- the currently selected Docking Target
g_target = nil

-- the current movement vector
g_movementVector = nil

-- handle simple input and movement control
function OnUpdateMain()

	CalculateMovementVector()
	
	CalculateSpeeds()
	
	-- draw some debug lines that represent the targets
	for targetIndex = 1, g_numTargets do
	
		local curTarget = g_targets[targetIndex]
		local color = hkDebugDisplay.BLACK
		
		-- draw the different wall types as different colors
		if (curTarget.m_type == TARGET_TYPE_SHORT_WALL) then
			color = hkDebugDisplay.RED
			
		elseif (curTarget.m_type == TARGET_TYPE_TALL_WALL) then
			color = hkDebugDisplay.BLUE
			
		elseif (curTarget.m_type == TARGET_TYPE_LEDGE) then
			color = hkDebugDisplay.GOLDENROD
			
		end
		
		hkDebugDisplay.showLine( curTarget.m_start, curTarget.m_finish, color )
	end
end

-- handle events for Undocked state
function OnEventUndocked()

	-- listen for the "Dock" event
	local eventName = hkbGetHandleEventName()
	if (eventName == "Dock") then
	
		-- search for nearest target within some range
		local target = GetNearestTarget( 6 )
		
		-- proceed if we found one
		if (target ~= nil) then
		
			-- setup the docking state
			SetupDockingState( target )
		
			-- assign the docking target
			hkbAssignLineDockingTarget( target.m_start, target.m_finish, target.m_rot )
		
			-- raise the CommitDocking event
			hkbFireEvent("CommitDocking")
		end
	end	
end

-- Update for Docked state
function OnUpdateDocked()

	-- project the user controled movement vector onto the docking target line
	local lineVector = hkVector4.new()
	lineVector:setSub4( g_target.m_finish, g_target.m_start )
	local lineDir = hkVector4.new(lineVector)
	lineDir:normalize3()
	
	local movement = g_movementVector:dot3( lineDir )
	
	-- determine if we need to transition to a different movement direction
	local movingRight = hkbIsNodeActive("Docked Mirror Modifier")
	
	-- flip the movement values when moving right
	if (not movingRight) then
	
		movement = -movement
	end
	
	-- transition to the other state if the movement direction becomes negative
	if (movement < 0) then
	
		if (movingRight) then
		
			hkbFireEvent("MoveLeft")
		else
		
			hkbFireEvent("MoveRight")
		end
	end
	
	-- project the character position onto the line
	local lineToChar = hkVector4.new()
	lineToChar:setSub4( hkbGetOldWorldFromModel():getTranslation(), g_target.m_start )
	local t = lineToChar:dot3( lineVector ) / lineVector:lengthSquared3()
	
	-- stop the motion of the character if he is near the end of the line
	if (movingRight and t >= 0.95) or ((not movingRight) and t <= 0.05) then
	
		movement = 0
	end
	
	-- assign the behavior variables
	if (movingRight) then
	
		hkbSetVariable("LeftRightSelector", 0)
	else
	
		hkbSetVariable("LeftRightSelector", 1)
	end
	
	hkbSetVariable( "MovementSpeed", movement )
end

function OnActivateUndocking()

	-- assign a plane docking target to represent the floor
	local floor = hkVector4.new(0, 0, 1, 0)
	
	hkbAssignPlaneDockingTarget( floor )
	
end

-- deactivate for Docked state
function OnDeactivateUndocking()

	-- Clear the Docking Target
	hkbAssignNullDockingTarget()
end

-- sets up docking state by assigning values to variables
function SetupDockingState( target )
	
	-- save of the docking target
	g_target = target
end

-- search targets for the nearest target that is less than maxDistance away
function GetNearestTarget( maxDistance )

	local target = nil
	local minDist = maxDistance
	local charPos = hkbGetOldWorldFromModel() : getTranslation()

	for targetIndex = 1, g_numTargets do
	
		local curTarget = g_targets[targetIndex]
		local dist = DistToLine(charPos, curTarget.m_start, curTarget.m_finish)
		
		if (dist < minDist) then
		
			minDist = dist
			target = curTarget	
		end
	end
	
	return target
end

-- get the minimum distance from a point to a line
function DistToLine(point, start, finish)

	local lineVector = hkVector4.new()
	local lineToPoint = hkVector4.new()
	
	lineVector:setSub4(finish, start)
	lineToPoint:setSub4(point, start)
	
	-- project the point onto the line
	local t = lineToPoint:dot3(lineVector)
	
	-- clamp at the minimum boundary
	if (t < 0) then
	
		return lineToPoint:length3()
	end
	
	-- normalize scale and clamp at max boundary
	t = t / lineVector:lengthSquared3()
	if (t > 1) then t = 1 end
	
	-- get the minimum vector from the line to the point
	lineToPoint:setAddMul4(start, lineVector, t)
	lineToPoint:setSub4( point, lineToPoint )
	
	-- return the length of the minimum vector
	return lineToPoint:length3()
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


