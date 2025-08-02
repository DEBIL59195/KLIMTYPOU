local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Настройки
local SETTINGS = {
    GAME_ID = 109983668079237,
    PASTEFY_URL = "https://pastefy.app/bU2qZQm8/raw",
    COOLDOWN_TIME = 5 * 60,
    COUNTDOWN_TIME = 4
}

-- Хранилище данных
local SERVER_LIST = {}
local BLACKLIST = {}
local SHOW_COUNTDOWN = true

-- Проверка всех возможных ошибок телепортации
local function IsTeleportError(err)
    local errorStr = tostring(err)
    return string.find(errorStr, "Unauthorized") ~= nil or
           string.find(errorStr, "cannot be joined") ~= nil or
           string.find(errorStr, "Teleport") ~= nil or
           string.find(errorStr, "experience is full") ~= nil or
           string.find(errorStr, "GameFull") ~= nil
end

local function LoadServers()
    local success, response = pcall(function()
        return game:HttpGet(SETTINGS.PASTEFY_URL)
    end)
    
    if not success then 
        warn("❌ Ошибка загрузки списка серверов: "..tostring(response))
        return {}
    end
    
    local servers = {}
    for serverId in string.gmatch(response, "([a-f0-9%-]+)") do
        table.insert(servers, serverId)
    end
    return servers
end

local function IsServerAvailable(serverId)
    if not BLACKLIST[serverId] then return true end
    return (os.time() - BLACKLIST[serverId]) > SETTINGS.COOLDOWN_TIME
end

local function TryTeleport(target)
    if SHOW_COUNTDOWN then
        for i = SETTINGS.COUNTDOWN_TIME, 1, -1 do
            print("🕒 Подключение через "..i.." сек...")
            task.wait(1)
        end
        SHOW_COUNTDOWN = false
    end
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            SETTINGS.GAME_ID,
            target,
            Players.LocalPlayer
        )
    end)
    
    if not success then
        if IsTeleportError(err) then
            print("⛔ Ошибка: "..tostring(err):match("^[^\n]+"))
        else
            print("⚠ Неизвестная ошибка: "..tostring(err):match("^[^\n]+"))
        end
        BLACKLIST[target] = os.time()
        return false
    end
    return true
end

local function TeleportLoop()
    while true do
        SERVER_LIST = LoadServers()
        if #SERVER_LIST == 0 then
            warn("⚠ Список серверов пуст. Повторная попытка через 10 сек...")
            task.wait(10)
        else
            print("✅ Доступно серверов: "..#SERVER_LIST)
            break
        end
    end
    
    while true do
        local available = {}
        for _, serverId in ipairs(SERVER_LIST) do
            if IsServerAvailable(serverId) then
                table.insert(available, serverId)
            end
        end
        
        if #available == 0 then
            print("⏳ Все серверы на кд. Ожидание "..SETTINGS.COOLDOWN_TIME.." сек...")
            SHOW_COUNTDOWN = true
            task.wait(SETTINGS.COOLDOWN_TIME)
            SERVER_LIST = LoadServers()
        else
            local target = available[math.random(1, #available)]
            print("🔍 Попытка подключения к "..target:sub(1, 8).."...")
            
            if TryTeleport(target) then
                print("🚀 Успешное подключение!")
                break
            else
                -- Мгновенный переход к следующему серверу без отсчета
                task.wait(0.05)
            end
        end
    end
end

-- Основной цикл
while true do
    local success, err = pcall(TeleportLoop)
    if not success then
        warn("🛑 Критическая ошибка: "..tostring(err))
        SHOW_COUNTDOWN = true
        task.wait(5)
    end
end
