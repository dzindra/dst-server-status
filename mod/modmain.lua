-- after how much time the status file will be refreshed 
local refreshRate = GetModConfigData("refreshRate")

-- delay for first write to file (seconds)
local initialDelay = 1

-- refresh file right after player joins/leaves?
local refreshAfterPlayerChange = GetModConfigData("refreshAfterPlayerChange")=="true"

-- here you can customize file path and name. Maybe use GetModConfigData for filename?
local filename = MODROOT .. "status.ini"


-- dumps data from tables clients and glob to file
-- handles only how data is written not where to get them
local function writeToFile(file, clients, glob)
  file:write("[global]\nclients="..#clients.."\n")
  
  for key, value in pairs(glob) do
    file:write(key.."=" .. tostring(value) .. "\n")
  end

  if #clients == 0 then
    return
  end
  
  for clientId, client in pairs(clients) do
    file:write("\n[client." .. clientId .. "]\n")
    
    for key, valueRaw in pairs(client) do
      local value = nil
      
      -- here you can customize output for specific keys  
      if key == "colour" then
        value = string.format("%.3f,%.3f,%.3f", valueRaw[1], valueRaw[2], valueRaw[3])
      else
        value = tostring(valueRaw)
      end
      
      if value ~= nil then
        file:write(key.."=" .. value .. "\n")
      end
    end
  end
end


-- opens file, fetches data from global structures and calls writeToFile
local function dumpData(leavingUserId)
  local file, errormsg = GLOBAL.io.open(filename, "w")
  if file == nil then
    print( "Unable to open status file \""..filename.."\": "..errormsg )
    return
  end
  
  local clients = GLOBAL.TheNet:GetClientTable()
  
  if leavingUserId ~= nil and #clients > 0 then
    -- working around pause_when_empty bug by removing last player with userid
    -- same as leavingUserId
    for i=#clients,1,-1 do
      if clients[i].userid == leavingUserId then
        table.remove(clients, i)
        break
      end
    end
  end
  
  writeToFile(file, clients, {
    gameMode = GLOBAL.TheNet:GetServerGameMode(),
    serverName = GLOBAL.TheNet:GetServerName(),
    days = GLOBAL.TheWorld.state.cycles + 1
  })
  file:close()
end



if GLOBAL.TheNet:GetIsServer() then  -- works only on server
  AddSimPostInit(function()  -- must hook on sim post init because TheWorld is ready here

    if refreshRate > 0 then  
      GLOBAL.TheWorld:DoPeriodicTask(refreshRate, function()
        dumpData()
      end, initialDelay)
    end
    
    -- When pause_when_empty is true on dedicated server and last player leaves,
    -- the server pauses periodic tasks after ms_playerdespawn event and 
    -- ms_playerleft is not fired.
    --
    -- But TheNet:GetClientTable() still contains the player that left, so 
    -- this means after last player leaves, the status file does not match
    -- the server state.
    --
    -- To work around this we simply take userId of despawning player and
    -- delete him from client manually
    -- 
    if GLOBAL.TheNet:IsDedicated() then
      GLOBAL.TheWorld:ListenForEvent("ms_playerdespawn", function(inst, player)
        local userId = nil
        if player ~= nil then
          userId = player.Network:GetUserID()
        end  
        dumpData(userId)
      end)
    end
    
    -- after ms_playerleft and ms_playerjoined just refresh the file if enabled
    if refreshAfterPlayerChange then
    
      if not GLOBAL.TheNet:IsDedicated() then  -- only for non dedicated servers - see workaround above 
        GLOBAL.TheWorld:ListenForEvent("ms_playerleft", function()
          dumpData()
        end)
      end
      
      GLOBAL.TheWorld:ListenForEvent("ms_playerjoined", function()
        dumpData()
      end)
    end
    
  end)
end
