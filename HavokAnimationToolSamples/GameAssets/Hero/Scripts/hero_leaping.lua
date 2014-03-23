
-- leap to platform docking type
g_leapToPlatformDock =
{
	m_lineTypes = {LINE_TYPE_LEDGE, LINE_TYPE_PLATFORM},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal)
						local heightDiff = dockPointToPos[2]
						dockPointToPos[2] = 0
						dockPointToPos:normalize3()
						return ((edgeNormal:dot3(forward) < -0.5) and 		--edge facing
								(dockPointToPos:dot3(forward) < -0.8) and 	--edge in front
								(heightDiff >= -3) and				-- +/-2m
								(heightDiff <= 2))
					end,
	m_maxDistance = 7,
	m_minDistance = 2
}

	-- searches for a platform line to leap to.  If it finds one it initiates the dock
	-- and returns true.  Otherwise it returns false.
function leapToPlatform(line, distance)
	
	-- before leaping, we need to make sure that there is a drop in front of us
	-- find a spot on the floor to land on
	local from = hkVector4.new()		
	local to = hkVector4.new()
		
	from:setAddMul4( g_characterState.m_currentPos, g_characterState.m_forward, 2)
	to:setAddMul4( from, UP_DIRECTION, -1)
	
	-- cast a ray to find the point on the geometry
	local hit = hkbCastRay(from, to)	
	
	-- if a line was found dock to it
	if( (line ~= nil) and (not hit) and not hkbIsNodeActive("Idle To Sword") ) then

		
		-- create and assign a line docking object which will constrain the character to the line
		setLineDockingTarget( line )
		
		-- determine if we are going to leap near or leap far
		local closestPoint = closestPointOnLineToCharacter( line )
		
		-- get a vector pointing from the character to the point on the line
		local charToPoint = hkVector4.new()
		charToPoint:setSub4(closestPoint, g_characterState.m_currentPos) 
		
		-- store off the vertical component of this vector
		local heightDiff = charToPoint[2]
		charToPoint[2] = 0
		
		-- set the correct animation based on the line type
		if( g_characterState.m_dockingTarget.m_lineType == LINE_TYPE_LEDGE ) then
			hkbSetVariable("ClimbAnimationIndex", 1)
		else
			hkbSetVariable("ClimbAnimationIndex", 0)
		end
		
		-- set the selector variable
		if(heightDiff > 0.25) then
			hkbSetVariable("LeapSelector", 1)
		else
			hkbSetVariable("LeapSelector", 0)
		end
		
		
		-- fire the leap event
		hkbFireEvent("Leap")
		
		if (hkbIsNodeActive("Idle Sword")) then
			hkbFireEvent("SheathSwordFast")
		end
		
		return true
	end
	
	return false
end

function onHandleEventLeap()

	-- get the name of the event that was raised	
	local eventName = hkbGetHandleEventName()
		
	-- perform the correct action
	if( eventName == "LeapFinished" ) then	
	
		-- reset the docking object
		clearDockingTarget()
	
	end
	
end