local socket = require("socket.core")

local playerId = os.getenv("PLAYEREMAIL")
local sessionId = os.getenv("SESSIONID")
local playerName = os.getenv("PLAYERNAME")
local playerCompany = os.getenv("PLAYERCOMPANY")

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
local lives = 3

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
   url = url:gsub("([^%w ])", char_to_hex)
   url = url:gsub(" ", "+")
   return url
 end

function sendEvent(event)

   queryString = "/event?gameEvent=" .. event .. "&sessionId=jj" .. urlencode(sessionId) .. "&playerId=" .. urlencode(playerId) .. "&playerName=" .. urlencode(playerName) .. "&playerCompany=" .. urlencode(playerCompany) .. "&gameLevel=" .. level .. "&timeLeft=" .. timer .. "&totalCoins=" .. collectedCoins .. "&lives=" .. lives
   
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
   if emu.read(0x0770, emu.memType.cpu) ~= gameState.normal and not demoMode then
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
   --  if emu.read(0x0770, emu.memType.cpu) == gameState.normal then
   --  only allow 1 life
   emu.write(memory.lives, 0x00, emu.memType.cpu)
   gameLoop()
   --end
end

function gameLoop()
   timer = tonumber(tostring( emu.read(0x07F8, emu.memType.cpu) .. emu.read(0x07F9, emu.memType.cpu) .. emu.read(0x07FA, emu.memType.cpu)))

   lives = tonumber(tostring(emu.read(memory.lives, emu.memType.cpu))) + 1
   
   local demoTextAddress = 0x2007

   local cooltext = { 0x2E, 0x28, 0x17, 0x0E, 0x20, 0x24, 0x1B, 0x0E, 0x15, 0x12, 0x0C, 0x24, 0x0D, 0x0E, 0x16, 0x18, 0x28, 0x2E }
   for index, value in pairs(cooltext) do
      emu.write(demoTextAddress, value, emu.memType.ppu)
      demoTextAddress = demoTextAddress + 1

      if emu.read(memory.worldCounter, emu.memType.ppu) < 8 and emu.read(memory.levelCounter, emu.memType.ppu) < 4 then
         level = tostring(emu.read(memory.worldCounter, emu.memType.ppu) .. "-" .. emu.read(memory.levelCounter, emu.memType.ppu))
      end
   end

   emu.write(0x2046, 0x0C, emu.memType.ppu)
   emu.write(0x2047, 0x0E, emu.memType.ppu)
   emu.write(0x2048, 0x15, emu.memType.ppu)

end

function coinCollectCallback(address, value)
   if emu.read(0x0770, emu.memType.cpu) ~= gameState.normal and not demoMode then
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
   if emu.read(0x0770, emu.memType.cpu) ~= gameState.normal and not demoMode then
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
   if emu.read(0x0770, emu.memType.cpu) ~= gameState.normal and not demoMode then
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
sendEvent("loaded")
