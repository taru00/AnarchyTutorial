-- new script file
G.topBlockDropCount = 0
enableExplosionEffect = true

function OnObjectEnter(self, object)	
  Debug:PrintLine("ObjectEnter")

  if (object:GetKey() == "topBlock") then
    G.topBlockDropCount = G.topBlockDropCount + 1
    Debug:PrintLine("topBlockDropCount: "..G.topBlockDropCount.." ")    
  end  

  if G.topBlockDropCount > 2 and enableExplosionEffect then
    enableExplosionEffect = false
    
    -- Play Explosion Sound
    local soundObject = Fmod:GetSound("sndGameOver")   
    soundObject:Play(0, true)
    
    -- Play Explosion Effect
    local explosionEffect = Game:GetEffect("ExplosionEffect")    
    explosionEffect:Restart()
    
    -- small trick to make Explosion Effect without WindAction API(C++)
    -- Apply LinearImpulse to all blocks
    local effectPosition = explosionEffect:GetPosition()
        
    for i = 1, #G.blockList do
    
      force = G.blockList[i]:GetPosition() - effectPosition
      force = force:getNormalized() 
      force.x = force.x * (2000 + Util:GetRandFloat(4000.f))
      force.y = force.y * (2000 + Util:GetRandFloat(4000.f))
      force.z = force.z * (500 + Util:GetRandFloat(1000.f)) 
      
      G.blockList[i]:GetComponentOfType("vHavokRigidBody"):ApplyLinearImpulse(force)
    
    end    
  end
  
end


function OnThink(self)

  if G.topBlockDropCount > 2 then
    -- Debug:PrintLine("GameOver")
    local w, h = Screen:GetViewportSize()
    -- show game over message    
    Debug:PrintAt(w/2 - 80, h/2 - 12, "GAME OVER", Vision.V_RGBA_RED, "Fonts/eras36")    
  end
 
end
