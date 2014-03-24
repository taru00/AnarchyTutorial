-- constants
MAX_POWER_TIME_DIFF = 1.5f

SHOOT_STATE_IDLE = 1
SHOOT_STATE_CHARGING = 2
SHOOT_STATE_FIRE = 3

function OnExpose(self)
	
end

function OnAfterSceneLoaded(self)
  self:SetTraceAccuracy(Vision.TRACE_POLYGON)
  
  self.RigidBody = self:GetComponentOfType("vHavokRigidBody")
  Vision.Assert(self.RigidBody ~= nil, "Rigid Body is missing!")

  self.inputmap = Input:CreateMap("InputMap")
  local w, h = Screen:GetViewportSize()

  self.inputmap:MapTrigger("X", {0, 0, w, h}, "CT_TOUCH_ABS_X")
  self.inputmap:MapTrigger("Y", {0, 0, w, h}, "CT_TOUCH_ABS_Y")
  self.inputmap:MapTrigger("Shoot", {0, 0, w, h}, "CT_TOUCH_ANY", {once = true})
  self.inputmap:MapTrigger("ShootPressed", {0, 0, w, h}, "CT_TOUCH_ANY", {once = false})
  
  if not G.useRemoteInput then
    self.inputmap:MapTrigger("X", "MOUSE", "CT_MOUSE_ABS_X")
    self.inputmap:MapTrigger("Y", "MOUSE", "CT_MOUSE_ABS_Y")
    self.inputmap:MapTrigger("Shoot", "MOUSE", "CT_MOUSE_LEFT_BUTTON", {once = true})
    self.inputmap:MapTrigger("ShootPressed", "MOUSE", "CT_MOUSE_LEFT_BUTTON", {once = false})
  end
  
  self.picked = nil
  self.ShootState = SHOOT_STATE_IDLE
  
  if Application:IsInEditor() and Application:GetEditorMode() ~= Vision.EDITOR_PLAY then
    --self:SetThinkFunctionStatus(false)
    Debug:PrintLine("Use 'Play the Game' when starting in editor!")
    Debug:Log("Use 'Play the Game' when starting in editor!")
    return
  end
end

function OnBeforeSceneUnloaded(self)
  if useRemoteInput then
    RemoteInput:StopServer()
  end

  Input:DestroyMap(self.inputmap);
end

function OnThink(self) 
 
  local x = self.inputmap:GetTrigger("X")
  local y = self.inputmap:GetTrigger("Y")
  
  if Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11" then
    -- draw cursor
    Debug.Draw:Line2D(x,y,x+10,y+5, Vision.V_RGBA_GREEN)
    Debug.Draw:Line2D(x,y,x+5,y+10, Vision.V_RGBA_GREEN)
    Debug.Draw:Line2D(x+10,y+5,x+5,y+10, Vision.V_RGBA_GREEN)
  end
    
  -- Shoot is triggered on Selected Stone
  if self.inputmap:GetTrigger("Shoot")>0 then    
    self.picked = Screen:PickEntity(x,y, 50000, true)    
    if self.picked ~= nil then
      -- start power gauage
      Debug:PrintLine("start power gauage charging")
      self.PowerStartTime = Timer:GetTime()
      self.Shoot = SHOOT_STATE_CHARGING
    end
  end

  if self.Shoot == SHOOT_STATE_CHARGING then
    if self.inputmap:GetTrigger("ShootPressed")>0 then
      -- power gauage update
      Debug:PrintLine("power gauage update")
      self.PowerEndTime = Timer:GetTime()
      self.timediff = self.PowerEndTime - self.PowerStartTime
      Debug:PrintLine(tostring(self.timediff))
      Debug:PrintAt(100, 20, "Power : "..tostring(self.timediff))
      
      if self.timediff > MAX_POWER_TIME_DIFF then
        -- timediff is reached to max limit
        Debug:PrintLine("Max Power")
        Debug:PrintLine("Shoot event is fired")
        self.Shoot = SHOOT_STATE_FIRE
      end   
    else
      Debug:PrintLine("Shoot event is fired")
      self.Shoot = SHOOT_STATE_FIRE
    end
  end
   
  -- shoot is triggered
  if self.Shoot == SHOOT_STATE_FIRE and self.picked ~= nil then
    Debug:PrintLine("handle Shoot event")
    local mainCam = Game:GetCamera()
    local direction = mainCam:GetDirection()
    direction:set(direction.x, direction.y, 0)    
    direction:normalizeIfNotZero() 
    
    --self.picked:GetComponentOfType("vHavokRigidBody"):ApplyForce(direction*300, Timer:GetThinkInterval())
    self.picked:GetComponentOfType("vHavokRigidBody"):ApplyLinearImpulse(direction*3)
    
    -- prevent duplicated shoot event
    self.picked = nil
    self.Shoot = SHOOT_STATE_IDLE
    
  end
end
