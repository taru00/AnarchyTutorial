-- the current movement vector
g_movementVector = nil

-- handle simple input and movement control
function OnUpdateAttack()


end


function OnHandleEventAttack()
		-- get the name of the event that was raised	
	local eventName = hkbGetHandleEventName()
	
	-- perform the correct action
	if( eventName == "gHitPoint" ) then	
		
		-- Calculate world attack direction 
		
		-- update global hit direction variable
		
		-- send global Event to active characters
		hkbFireEvent("gHitPoint")
	end

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
