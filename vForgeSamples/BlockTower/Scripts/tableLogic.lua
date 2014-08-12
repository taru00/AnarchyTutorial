-- info fields: HitPoint, HitNormal, Force, RelativeVelocity,
--              ColliderType, ColliderObject (maybe nil)
function OnCollision(self, info)
       
 if info.ColliderObject ~= nil then

    local block = info.ColliderObject;
    
    if (block:GetKey() == "bottomBlock") then
      --Debug:PrintLine("bottomBlock is dropped")  
    else
      
      local soundObject = Fmod:GetSound("sndBlockDropped")
      --Debug:PrintLine("play sndBlockDropped")  
      soundObject:Play(0, true)
    end
    
  end
end
