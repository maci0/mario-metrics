local socket = require("socket.core")

local playerId = ""
local sessionId = ""
local playerName = ""
local playerCompany = ""

emu.log(emu.getRomInfo().name)

local debug = false
local timerDebug = false
local demoMode = false

local memory = {
   playerState = 0x000E,
   gameState = 0x0770,
   coinCounter = 0x075E,
   lives = 0x075A,
   worldCounter = 0x2073,
   levelCounter = 0x2075,
   levelLoad = 0x0772,
   starTimer = 0x079F
}

local playerState = {
   leftMost = 0x00,
   dies = 0x06,
   finishedLevel = 0x04,
   normal = 0x08,
   mushroom = 0x09,
   dying = 0x0B,
   hit = 0x0A,
   flower = 0x0C
}

local gameState = {
   demo = 0x00,
   normal = 0x01,
   endWorld = 0x02,
   endGame = 0x03
}

local world = 0
local levelStarted = false
local level = 0
local timer = 0
local collectedCoins = 0
local state = 0
local lives = 1

local ppuCharacters = { 
   A = 0x0A,
   B = 0x0B,
   C = 0x0C,
   D = 0x0D,
   E = 0x0E,
   F = 0x0F,
   G = 0x10,
   H = 0x11,
   I = 0x12,
   J = 0x13,
   K = 0x14,
   L = 0x15,
   M = 0x16,
   N = 0x17,
   O = 0x18,
   P = 0x19,
   Q = 0x1A,
   R = 0x1B,
   S = 0x1C,
   T = 0x1D,
   U = 0x1E,
   V = 0x1F,
   W = 0x20,
   X = 0x21,
   Y = 0x22,
   Z = 0x23,
   SPACE = 0x24,
   COIN = 0x2E,
   DASH = 0x28
}



function httpGet(host, port, path)
   local tcp = socket.tcp()
   tcp:settimeout(2)
   tcp:connect(host, port)
   tcp:send("GET " .. path .. " HTTP/1.1\r\nHost: " .. host .. ":" .. port .. "\r\nConnection: close\r\n\r\n")

   -- local text
   -- repeat
   --       text = tcp:receive()
   --       emu.log(text)
   -- until text == nil
   tcp:close()
end

function char_to_hex(c)
   return string.format("%%%02X", string.byte(c))
end

function urlencode(url)
   if url == nil then
     return
   end
   url = url:gsub("\n", "\r\n")
   url = url:gsub("([^%w _ %- . ~])", char_to_hex)
   url = url:gsub(" ", "+")
   return url
 end

function sendEvent(event)

   queryString = "/event?gameEvent=" .. event .. "&sessionId=" .. urlencode(sessionId) .. "&playerId=" .. urlencode(playerId) .. "&playerName=" .. urlencode(playerName) .. "&playerCompany=" .. urlencode(playerCompany) .. "&gameLevel=" .. level .. "&timeLeft=" .. timer .. "&totalCoins=" .. collectedCoins .. "&lives=" .. lives
   
   if debug then
      emu.log("Sending event: " .. queryString)
   end
   
   httpGet(
   "127.0.0.1",
   8082,
   queryString
   )
end

function playerStateCallback(address, value)
   if emu.read(memory.gameState, emu.memType.cpu) ~= gameState.normal and not demoMode then
      return
   end

   if debug then
      emu.log("playerStateCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end

   -- only run when player is playing, not in demo mode
   -- Player died

   if state ~= playerState.finishedLevel and value == playerState.finishedLevel then
      sendEvent("completedLevel")
      emu.log("Player completed a level, time left: " .. timer .. " with lives: " .. lives)
   end

   if value == playerState.dying or value == playerState.dies and levelStarted then
      sendEvent("death")
      emu.log("Player died, time left: " .. timer)
      levelStarted = false
   end

   -- Player picket up the mushroom
   -- if value == playerState.mushroom then
   --    sendEvent("mushroom")
   --    emu.log("Player ate mushroom")
   -- end

   -- Player got hit
   -- if value == playerState.hit then
   --    sendEvent("hit")
   --    emu.log("Player got hit")
   -- end

   -- Player picked up the fireflower
   -- if value == playerState.flower then
   --    sendEvent("flower")
   --    emu.log("Player got flower")
   -- end

   state = value
end

function main()
   -- set max number of lives, 0 = 1 live
   local MaxLife = os.getenv("TOTAL_LIFE");
   if MaxLife ~= nil then 
      emu.write(memory.lives, tonumber(MaxLife), emu.memType.cpu)
   end

   -- see list of levels https://www.mariowiki.com/Super_Mario_Bros.
   -- start from world, starting from (0: world 1)
   local StartFromWorld = os.getenv("START_WORLD");
   if StartFromWorld ~= nil then 
      emu.write(0x075F, tonumber(StartFromWorld), emu.memType.cpu)
   end

   gameLoop()
end

function gameLoop()
   timer = tonumber(tostring( emu.read(0x07F8, emu.memType.cpu) .. emu.read(0x07F9, emu.memType.cpu) .. emu.read(0x07FA, emu.memType.cpu)))

   lives = tonumber(tostring(emu.read(memory.lives, emu.memType.cpu))) + 1
   
   local demoTextAddress = 0x2007

   -- Write "NEW RELIC DEMO" to the title location
   -- local cooltext = { 0x2E, 0x28, 0x17, 0x0E, 0x20, 0x24, 0x1B, 0x0E, 0x15, 0x12, 0x0C, 0x24, 0x0D, 0x0E, 0x16, 0x18, 0x28, 0x2E }
   -- for index, value in pairs(cooltext) do
   --    emu.write(demoTextAddress, value, emu.memType.ppu)
   --    demoTextAddress = demoTextAddress + 1

   --    if emu.read(memory.worldCounter, emu.memType.ppu) < 8 and emu.read(memory.levelCounter, emu.memType.ppu) < 4 then
   --       level = tostring(emu.read(memory.worldCounter, emu.memType.ppu) .. "-" .. emu.read(memory.levelCounter, emu.memType.ppu))
   --    end
   -- end
   if emu.read(memory.worldCounter, emu.memType.ppu) < 8 and emu.read(memory.levelCounter, emu.memType.ppu) < 4 then
      level = tostring(emu.read(memory.worldCounter, emu.memType.ppu) .. "-" .. emu.read(memory.levelCounter, emu.memType.ppu))
   end

   SetPlayerName()
   local GameTitle = os.getenv("GAME_TITLE");
   if GameTitle ~= nil then 
      SetTitle(GameTitle)
   else
      SetTitle("-New Relic Demo-")
   end
end


function SetPlayerName()
   local nameSlotStart = 0x2043
   -- only render the first 10 characters of the player name
   local firstName = string.sub(Split(string.upper(playerName), " ")[1],1,7)
   for i = 1, string.len(firstName) do
      local char = string.sub(firstName, i, i)
      if ppuCharacters[char] ~= nil then
         emu.write(nameSlotStart, ppuCharacters[char], emu.memType.ppu)
      else
         emu.write(nameSlotStart, ppuCharacters['SPACE'], emu.memType.ppu)
      end
      nameSlotStart = nameSlotStart + 1
   end

   -- clear the remaining of the MARIO
   if string.len(firstName) < 5 then
      nameSlotStart = 0x2043 + string.len(firstName)
      for i = string.len(firstName) + 1, 5 do
         emu.write(nameSlotStart, ppuCharacters['SPACE'], emu.memType.ppu)
         nameSlotStart = nameSlotStart + 1
      end
   end
end

function SetTitle(title)
   local nameSlotStart = 0x2007
   -- only render the first 10 characters of the player name
   local titleUpper = string.upper(title)
   for i = 1, string.len(titleUpper) do
      local char = string.sub(titleUpper, i, i)
      if ppuCharacters[char] ~= nil then
         emu.write(nameSlotStart, ppuCharacters[char], emu.memType.ppu)
      elseif char == '-' then
         emu.write(nameSlotStart, ppuCharacters['DASH'], emu.memType.ppu)
      else
         emu.write(nameSlotStart, ppuCharacters['SPACE'], emu.memType.ppu)
      end
      nameSlotStart = nameSlotStart + 1
   end
end


function Split(s, delimiter)
   result = {};
   for match in (s..delimiter):gmatch("(.-)"..delimiter) do
       table.insert(result, match);
   end
   return result;
end

function coinCollectCallback(address, value)
   if emu.read(memory.gameState, emu.memType.cpu) ~= gameState.normal and not demoMode then
      return
   end

   if debug then
      emu.log("coinCollectCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end

   local oldCoins = emu.read(memory.coinCounter, emu.memType.cpu)
   if value ~= oldCoins then
      sendEvent("coin")
      collectedCoins = value
      emu.log("Player picked up a coin, total coins: " .. collectedCoins)
   end
end

function timerCallback(address, value)
   if emu.read(memory.gameState, emu.memType.cpu) ~= gameState.normal and not demoMode then
      return
   end

   if timerDebug then
      emu.log("timerCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end

   local timermax = 400
   if demoMode then
      -- During demo mode, the timer is set to 401
      timermax = 401
   end
   -- Level Started
   if timer == timermax then
      emu.log("Level:" .. level)
      sendEvent("levelstart")
      levelStarted = true
   end

   -- Out of time
   if timer == 0 then
      sendEvent("timeout")
      emu.log("Player ran out of time")
      levelStarted = false
   end
end

function starTimerCallback(address, value)
   if emu.read(memory.gameState, emu.memType.cpu) ~= gameState.normal and not demoMode then
      return
   end

   if timerDebug then
      emu.log("starTimerCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end
   -- Star Timer Started
   if value == 35 then
      sendEvent("star")
      emu.log("Player got a star")
      emu.log("Player got a star " .. value)
   end

end

emu.addEventCallback(main, emu.eventType.startFrame)
-- emu.addMemoryCallback(starTimerCallback, emu.memCallbackType.cpuWrite, memory.starTimer)
emu.addMemoryCallback(timerCallback, emu.memCallbackType.cpuWrite, 0x07FA)
emu.addMemoryCallback(playerStateCallback, emu.memCallbackType.cpuWrite, memory.playerState)
emu.addMemoryCallback(coinCollectCallback, emu.memCallbackType.cpuWrite, memory.coinCounter)


if debug then
   emu.log("Mario Metrics Lua script loaded.")
end


-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
   local lines = {}
   for line in io.lines(file) do 
     lines[#lines + 1] = line
   end
   return lines
 end
 
 -- tests the functions above
 local userfile = os.getenv("APPDATA") .. '/player.ini'
 local lines = lines_from(userfile)
 
 -- print all line numbers and their contents
 for k,v in pairs(lines) do
   if k == 1 then playerName = v end
   if k == 2 then playerId = v end
   if k == 3 then playerCompany = v end
   if k == 4 then sessionId = v end
 end

sendEvent("loaded")
