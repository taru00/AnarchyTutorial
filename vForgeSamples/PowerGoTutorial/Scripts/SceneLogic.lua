-- new script file
function OnAfterSceneLoaded()
  Debug:Enable(true)
  --local cam01 = Game:GetEntity("CameraEntity")
  --local mainCam = Game:GetCamera()  
  --mainCam:Set(cam01:GetRotationMatrix(), cam01:GetPosition())

  --load the havok movie 
  GUI:LoadResourceFile("GUI/MenuSystem.xml")  
  if Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11" then
    -- draw cursor    
    --GUI:SetCursorVisible(true)
  end
end

function OnAfterSceneUnloaded()
 
  --hide the cursor again
  --GUI:SetCursorVisible(false)
end