local socket = require("socket.core")

local playerId = os.getenv("PLAYEREMAIL")
local playerName = os.getenv("PLAYERNAME")
local playerCompany = os.getenv("PLAYERCOMPANY")

emu.log(emu.getRomInfo().name)
local debug = false
local timerDebug = false
local demoMode = true

local memory = {
   playerState = 0x000E,
   gameState = 0x0770,
   coinCounter = 0x075E,
   worldCounter = 0x2073,
   levelCounter = 0x2075,
   levelLoad = 0x0772,
   starTimer = 0x079F
}

local playerState = {
   leftMost = 0x00,
   dies = 0x06,
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
local level = 0
local timer = 0
local state = 0

function httpGet(host, port, path)
   local tcp = socket.tcp()
   tcp:settimeout(2)
   tcp:connect(host, port)
   tcp:send("GET " .. path .. " HTTP/1.1\r\nHost: " .. host .. ":" .. port .. "\r\nConnection: close\r\n\r\n")

   --    local text
   --    repeat
   --        text = tcp:receive()
   --        emu.log(text)
   --    until text == nil
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

   queryString = "/event?gameEvent=" .. event .. "&playerId=" .. urlencode(playerId) .. "&playerName=" .. urlencode(playerName) .. "&playerCompany=" .. urlencode(playerCompany) .. "&gameLevel=" .. level
   
   if debug then
      emu.log("Sending event: " .. queryString)
   end
   
   httpGet(
   "192.168.0.100",
   8082,
   queryString
   )
end

function playerStateCallback(address, value)
   if debug then
      emu.displayMessage("Debug", "playerStateCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end

   -- only run when player is playing, not in demo mode
   if emu.read(0x0770, emu.memType.cpu) ~= gameState.normal and not demoMode then
      return
   end

   -- Player died
   if value == playerState.dying then
      sendEvent("death")
      emu.displayMessage("Event", "Player died")
   end

   -- Player picket up the mushroom
   if value == playerState.mushroom then
      sendEvent("mushroom")
      emu.displayMessage("Event", "Player ate mushroom")
   end

   -- Player got hit
   if value == playerState.hit then
      sendEvent("hit")
      emu.displayMessage("Event", "Player got hit")
   end

   -- Player picked up the fireflower
   if value == playerState.flower then
      sendEvent("flower")
      emu.displayMessage("Event", "Player got flower")
   end
end

function main()
   --  if emu.read(0x0770, emu.memType.cpu) == gameState.normal then
   gameLoop()
   --end
end

function gameLoop()
   timer = tonumber(tostring( emu.read(0x07F8, emu.memType.cpu) .. emu.read(0x07F9, emu.memType.cpu) .. emu.read(0x07FA, emu.memType.cpu)))

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
   if debug then
      emu.displayMessage("Debug", "coinCollectCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end

   local oldCoins = emu.read(memory.coinCounter, emu.memType.cpu)
   if value ~= oldCoins then
      sendEvent("coin")
      emu.displayMessage("Event", "Player picked up a coin")
   end
end

function timerCallback(address, value)
   if timerDebug then
      emu.displayMessage("Debug", "timerCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end
   local timermax = 400
   if demoMode then
      -- During demo mode, the timer is set to 401
      timermax = 401
   end
   -- Level Started
   if timer == timermax then
      emu.displayMessage("Event:", "Level Started: " .. level)
      emu.log("Level:" .. level)
      sendEvent("levelstart")
   end

   -- Out of time
   if timer == 0 then
      sendEvent("timeout")
      emu.displayMessage("Event", "Player ran out of time")
   end
end

function starTimerCallback(address, value)
   if timerDebug then
      emu.displayMessage("Debug", "starTimerCallback:" .. string.format("0x%04x", address) .. " " .. string.format("0x%02x",value))
   end
   -- Star Timer Started
   if value == 35 then
      sendEvent("star")
      emu.displayMessage("Event", "Player got a star")
      emu.log("Player got a star " .. value)
   end

end

emu.addEventCallback(main, emu.eventType.startFrame)
emu.addMemoryCallback(starTimerCallback, emu.memCallbackType.cpuWrite, memory.starTimer)
emu.addMemoryCallback(timerCallback, emu.memCallbackType.cpuWrite, 0x07FA)
emu.addMemoryCallback(playerStateCallback, emu.memCallbackType.cpuWrite, memory.playerState)
emu.addMemoryCallback(coinCollectCallback, emu.memCallbackType.cpuWrite, memory.coinCounter)


if debug then
   emu.displayMessage("Debug", "Mario Metrics Lua script loaded.")
end
sendEvent("loaded")
