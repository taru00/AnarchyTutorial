
g_characterProperties =
{
	m_idleToMoveThreshold = 0.01
	, m_meleeChainCount = 1
}

function g_characterProperties:update()
	
	
end

function ShouldDie()
	return (hkbGetVariable("Dying"));
end

function ShouldMove()
	local moveSpeed = hkbGetVariable("MoveSpeed");
	return (moveSpeed >= g_characterProperties.m_idleToMoveThreshold);
end

function ShouldChallenge()
	return (hkbGetVariable("Challenging"));
end

function ShouldMeleeAttack()
	return (hkbGetVariable("MeleeAttacking"));
end

function ShouldRangedAttack()
	return (hkbGetVariable("RangedAttacking"));
end

function ShouldAoeAttack()
	return (hkbGetVariable("AoeAttacking"));
end

function ShouldBlock()
	return (hkbGetVariable("Blocking"));
end

function ShouldCharge()
	return (hkbGetVariable("Charging"));
end


-- /////////////////////////////////////////////////////////////////////////////
-- Idle State
-- /////////////////////////////////////////////////////////////////////////////
function onUpdateIdle()
	g_characterProperties:update();
	
	if (ShouldMove()) then
		hkbFireEvent("MoveStart");
	elseif (ShouldChallenge()) then
		hkbFireEvent("ChallengeStart");
	elseif (ShouldMeleeAttack()) then		
		hkbFireEvent("MeleeAttackStart");
	elseif (ShouldRangedAttack()) then		
		hkbFireEvent("RangedAttackStart");
	elseif (ShouldAoeAttack()) then		
		hkbFireEvent("AoeAttackStart");
	elseif (ShouldBlock()) then		
		hkbFireEvent("BlockStart");
	elseif (ShouldCharge()) then		
		hkbFireEvent("ChargeStart");
	end
end


-- /////////////////////////////////////////////////////////////////////////////
-- Move State
-- /////////////////////////////////////////////////////////////////////////////
function onUpdateMove()
	g_characterProperties:update();
	
	-- should we return to idle?
	if (ShouldMove() == false) then
		hkbFireEvent("MoveStop");
	elseif (ShouldChallenge()) then
		hkbFireEvent("ChallengeStart");
	elseif (ShouldMeleeAttack()) then		
		hkbFireEvent("MeleeAttackStart");
	elseif (ShouldRangedAttack()) then		
		hkbFireEvent("RangedAttackStart");
	elseif (ShouldAoeAttack()) then		
		hkbFireEvent("AoeAttackStart");
	elseif (ShouldBlock()) then		
		hkbFireEvent("BlockStart");
	elseif (ShouldCharge()) then		
		hkbFireEvent("ChargeStart");
	end
end


-- /////////////////////////////////////////////////////////////////////////////
-- MeleeAttack State
-- /////////////////////////////////////////////////////////////////////////////
function onActivateMeleeAttack()
	local chooseMeleeAttack = math.random(0, g_characterProperties.m_meleeChainCount);
	hkbSetVariable("MeleeAttackType", chooseMeleeAttack);
end

function onHandleEventMeleeAttack()
	-- listen for the "MeleeAttackStop" event
	local eventName = hkbGetHandleEventName();
	if (eventName == "MeleeAttackStop") then
		hkbSetVariable("MeleeAttacking", false);
		hkbSetVariable("MeleeWeaponActive", false);
	end
	
	if (eventName == "MeleeWeaponActiveStart") then
		hkbSetVariable("MeleeWeaponActive", true);
	end
	
	if (eventName == "MeleeWeaponActiveEnd") then
		hkbSetVariable("MeleeWeaponActive", false);
	end
end


-- /////////////////////////////////////////////////////////////////////////////
-- Ranged Attacking State
-- /////////////////////////////////////////////////////////////////////////////
function onHandleEventRangedAttack()
	local eventName = hkbGetHandleEventName();
	if (eventName == "RangedAttackStop") then
		hkbSetVariable("RangedAttacking", false);
	end	
end


-- /////////////////////////////////////////////////////////////////////////////
-- Aoe Attacking State
-- /////////////////////////////////////////////////////////////////////////////
function onHandleEventAoeAttack()
	local eventName = hkbGetHandleEventName();
	if (eventName == "AoeAttackStop") then
		hkbSetVariable("AoeAttacking", false);
	end	
end


-- /////////////////////////////////////////////////////////////////////////////
-- Blocking State
-- /////////////////////////////////////////////////////////////////////////////
function onHandleEventBlock()
	local eventName = hkbGetHandleEventName();
	if (eventName == "BlockStop") then
		hkbSetVariable("Blocking", false);
	end	
end


-- /////////////////////////////////////////////////////////////////////////////
-- Challenge State
-- /////////////////////////////////////////////////////////////////////////////
function onHandleEventChallenge()
	-- listen for the "ChallengeStop" event
	local eventName = hkbGetHandleEventName();
	if (eventName == "ChallengeStop") then
		hkbSetVariable("Challenging", false);
	end	
end


-- /////////////////////////////////////////////////////////////////////////////
-- Alive SuperState
-- /////////////////////////////////////////////////////////////////////////////
function onUpdateAlive()
	if (ShouldDie()) then
		hkbFireEvent("DyingStart");
	end
end


-- /////////////////////////////////////////////////////////////////////////////
-- Dead SuperState
-- /////////////////////////////////////////////////////////////////////////////
function onActivateDead()
	-- @todo: is there a way to get the DeathType variable's max?
	local chooseDeath = math.random(0,2);	-- @todo: temp for testing
	hkbSetVariable("DeathType", chooseDeath);	-- Each character has its own DeathType max. values out of range will be ignored.
end

function onHandleEventDead()
	-- listen for the "DyingEnd" event
	local eventName = hkbGetHandleEventName();
	if (eventName == "DyingEnd") then
		hkbSetVariable("Dying", false);
	end	
end
