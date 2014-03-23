
-- line types for the two climbing surfaces
LINE_TYPE_LEDGE = 2
LINE_TYPE_PLATFORM = 3

-- jump to platform
g_jumpToPlatformDock = 
{
	m_lineTypes = {LINE_TYPE_LEDGE, LINE_TYPE_PLATFORM},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal)
						local heightDiff = dockPointToPos[2]
						dockPointToPos[2] = 0
						dockPointToPos:normalize3()
						return ((heightDiff < -1) and
								(heightDiff > -4) and
								(math.abs(dockPointToPos:dot3(forward)) > 0.8) and
								(edgeNormal:dot3(forward) < 0.1))
					end,
	m_maxDistance = 3,
	m_minDistance = 0
}

-- drop from platform docking type
g_dropFromPlatformDock = 
{
	m_lineTypes = {LINE_TYPE_LEDGE, LINE_TYPE_PLATFORM},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal) 						
						return (dockPointToPos:length3() < 0.5 ) 
					end,
	m_maxDistance = 2,
	m_minDistance = 0
}

	-- searches for a platform line to jump up to.  If it find ones it initiates the dock
	-- and returns true.  Otherwise it returns false.
function jumpToPlatform(line, distance)

	-- if a line was found dock to it
	if( line ~= nil and not hkbIsNodeActive("Idle To Sword")) then
	
		-- create and assign a line docking object which will constrain the character to the line
		setLineDockingTarget( line )
		
		-- set the correct platform start state
		hkbSetVariable("PlatformStartState", 0)			
		
		-- set the correct animation based on the line type
		if( line.m_lineType == LINE_TYPE_LEDGE ) then
			hkbSetVariable("ClimbAnimationIndex", 1)	
		else
			hkbSetVariable("ClimbAnimationIndex", 0)
		end
		
		-- fire the jump to platform event
		hkbFireEvent("Platform")
		
		if (hkbIsNodeActive("Idle Sword")) then
			hkbFireEvent("SheathSwordFast")
		end
		
		return true
	end
	
	return false
end

	-- searches for a platform to catch.  If it finds one it initiates the dock and 
	-- returns true, otherwise it returns false
function tryCatchPlatform()
		
	if ((g_characterState.m_dockingTarget == nil) and not hkbIsNodeActive("Idle Sword")) then

		-- look for a platform line that we are dropping below
		local line = g_lineWorld:findLineToDockTo( g_dropFromPlatformDock )
		if(line ~= nil) then					
			
			-- assign the docking object
			setLineDockingTarget( line )
		
			-- set the correct start state
			hkbSetVariable("PlatformStartState", 1)			
			
			-- set the correct animation based on the line type
			if( line.m_lineType == LINE_TYPE_LEDGE ) then
				hkbSetVariable("ClimbAnimationIndex", 1)
			else
				hkbSetVariable("ClimbAnimationIndex", 0)
			end
			
			-- fire the platform event
			hkbFireEvent("Platform")						
			
			return true
		end
	end
	
	return false
end

	-- updates the character when they are docked
function onDockedPlatformUpdated()

	local platformMovement =
	{
		m_exitCondition =	function()
								return	((not g_gamePad:inLeftStickInDeadZone()) and 
										(g_characterState.m_stickDirection:dot3(g_characterState.m_forward) > 0.8))
							end,
		m_exitFunction =	function()
								hkbFireEvent("Climb")
								g_characterState.m_dockedSpeed = 0
							end,
		m_leftNodeName = "Hanging Move Left Selector",
		m_rightNodeName = "Hanging Move Right Selector"
	}
	
	updateLineMovement(platformMovement)
	
end

function undockPlatform()

	if (g_characterState.m_dockingTarget ~= nil) then
	
		-- find a spot on the floor to land on
		local from = hkVector4.new()		
		local to = hkVector4.new()
			
		from:setAddMul4( g_characterState.m_currentPos, g_characterState.m_forward, -0.75)
		to:setAddMul4( from, UP_DIRECTION, -6.0)
		
		-- cast a ray to find the point on the geometry
		local hit, hitFraction, hitNormal, hitPosition = hkbCastRay(from, to)		
		
		-- don't drop if there isn't anywhere to land
		if( hit == false ) then		
			return
		end
				
		-- assign the spot on the floor to the docking object
		local plane = hkVector4.new(UP_DIRECTION)
		plane[3] = plane:dot3(hitPosition)
		setPlaneDockingTarget( plane )
		
		-- raise the drop event
		hkbFireEvent("Drop")
		
	end
	
end

function onPlatformEventRaised()

	local eventName = hkbGetHandleEventName()
	
	-- get the name of the event that was raised
	if(eventName == "Platform Drop Finished" or eventName == "ClimbFinished") then			
		
		-- reset the docking object
		clearDockingTarget()
	
	end
end

function onDeactivateClimbUp()
	
	-- if we are pressing the gamepad at this point, set the locomotion start state to running
	if( g_gamePad.m_padMagnitude > 0.5 ) then
		-- set the locomotion start state to running
		hkbSetVariable("LocomotionStartState", 1)
	end
	
	
end

function onDeactivatePostPlatformIdle()

	-- set the locomotion start state to idle
	hkbSetVariable("LocomotionStartState", 0)
end