local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Настройки
local SETTINGS = {
    GAME_ID = 109983668079237,
    PASTEFY_URL = "https://pastefy.app/kA1NrWR2/raw",
    COOLDOWN_TIME = 5 * 60,
    COUNTDOWN_TIME = 6,
    ERROR_RETRY_DELAY = 3,  -- 3 секунды при ошибке
    SUCCESS_DELAY = 3       -- 6 секунд при успехе
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
        print("⏳ Повторная попытка через "..SETTINGS.ERROR_RETRY_DELAY.." сек...")
        task.wait(SETTINGS.ERROR_RETRY_DELAY)  -- Ожидание 3 секунды при ошибке
        return false
    end
    
    print("✅ Успешное подключение! Завершение через "..SETTINGS.SUCCESS_DELAY.." сек...")
    task.wait(SETTINGS.SUCCESS_DELAY)  -- Ожидание 6 секунд при успехе
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
            end
            -- При ошибке уже есть задержка в TryTeleport
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
