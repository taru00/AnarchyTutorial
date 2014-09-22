function OnAfterSceneLoaded(self)
	G.isWindows = (Application:GetPlatformName() == "WIN32DX9" or 
				   Application:GetPlatformName() == "WIN32DX11")
	G.screenWidth, self.screenHeight = Screen:GetViewportSize()

	self.MoveSpeed = 5
	self.RotateSpeed = 50

	self.controls = Input:CreateMap()	
	self.character = self:GetComponentOfType("vHavokCharacterController")
  self.behavior = self:GetComponentOfType("vHavokBehaviorComponent")
    
	if G.isWindows then
		--self.controls:MapTrigger("Left", "KEYBOARD", "CT_KB_LEFT")
		--self.controls:MapTrigger("Right", "KEYBOARD", "CT_KB_RIGHT")
		self.controls:MapTrigger("Up", "KEYBOARD", "CT_KB_UP")
		self.controls:MapTrigger("Down", "KEYBOARD", "CT_KB_DOWN")
		self.controls:MapTrigger("Jump", "KEYBOARD", "CT_KB_SPACE")
		self.controls:MapTrigger("X", "MOUSE", "CT_MOUSE_NORM_X")
		self.controls:MapTrigger("Y", "MOUSE", "CT_MOUSE_NORM_Y")
	else
		-- create a virtual thumbstick then setup controls for it
		Input:CreateVirtualThumbStick()
		self.controls:MapTrigger("Left", "VirtualThumbStick", "CT_PAD_LEFT_THUMB_STICK_LEFT", {deadzone = 0.1})
		self.controls:MapTrigger("Right", "VirtualThumbStick", "CT_PAD_LEFT_THUMB_STICK_RIGHT", {deadzone = 0.1})
		self.controls:MapTrigger("Up", "VirtualThumbStick", "CT_PAD_LEFT_THUMB_STICK_UP", {deadzone = 0.1})
		self.controls:MapTrigger("Down", "VirtualThumbStick", "CT_PAD_LEFT_THUMB_STICK_DOWN", {deadzone = 0.1})
	end
end

function OnBeforeSceneUnloaded(self)
	-- make sure input map and screen refs are destroyed
    Game:DeleteAllUnrefScreenMasks()
	Input:DestroyMap(self.controls)
end

function OnThink(self)
	local isLeftPressed = self.controls:GetTrigger("Left")>0
	local isRightPressed = self.controls:GetTrigger("Right")>0
	local isUpPressed = self.controls:GetTrigger("Up")>0
	local isDownPressed = self.controls:GetTrigger("Down")>0
	local isJumpPressed = self.controls:GetTrigger("Jump")>0
	local dt = Timer:GetTimeDiff()

	local dx, dy = Input:GetMouseDelta()

	if math.abs(dx) > 0 or math.abs(dy) > 0 then
		local rotation = self:GetOrientation()
		rotation.x = rotation.x - dt * dx * self.RotateSpeed
		-- rotation.y = rotation.y - dt * dy * self.RotateSpeed
		self:SetOrientation(rotation)
	end

	if (isUpPressed or isDownPressed or isLeftPressed or isRightPressed) and
	   self.character:IsStanding() then
		local delta = Vision.hkvVec3(0, 0, 0)
		local dirForward = self:GetObjDir()
		local dirRight = self:GetObjDir_Right()
		
		if isUpPressed then
			delta = delta + dirForward * self.MoveSpeed
		end

		if isDownPressed then
			delta = delta - dirForward * self.MoveSpeed
		end

		if isLeftPressed then
			delta = delta + dirRight * self.MoveSpeed
		end

		if isRightPressed then
			delta = delta - dirRight * self.MoveSpeed
		end
		
    if self.behavior ~= nil then      
      self.behavior:TriggerEvent("Move")
      self.behavior:SetFloatVar("MoveSpeed", self.MoveSpeed)
    end
    
		self:SetMotionDeltaWorldSpace(delta)
	else
    self.behavior:TriggerEvent("MoveEnd")
  end
	
  if isJumpPressed == true then
    self.behavior:TriggerEvent("AoeAttack")
  end
   
	self.character:SetWantJump(isJumpPressed)
end
