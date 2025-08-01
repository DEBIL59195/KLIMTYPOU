local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Настройки
local SETTINGS = {
    GAME_ID = 109983668079237, -- ID игры Steal a Brainrot
    PASTEFY_URL = "https://pastefy.app/GhGCBFIK/raw", -- Ваша ссылка
    COOLDOWN_TIME = 5 * 60, -- 5 минут кд на сервер (измените по желанию)
}

-- Хранилище данных
local SERVER_LIST = {}
local BLACKLIST = {} -- {serverId = os.time()}

-- Загрузка серверов
local function LoadServers()
    local success, response = pcall(function()
        return game:HttpGet(SETTINGS.PASTEFY_URL)
    end)
    
    if not success then error("❌ Ошибка загрузки: "..response) end
    
    local servers = {}
    for serverId in string.gmatch(response, "([a-f0-9%-]+)") do
        table.insert(servers, serverId)
    end
    return servers
end

-- Проверка доступности сервера
local function IsServerAvailable(serverId)
    if not BLACKLIST[serverId] then return true end
    return (os.time() - BLACKLIST[serverId]) > SETTINGS.COOLDOWN_TIME
end

-- Основной цикл телепортации
local function TeleportLoop()
    SERVER_LIST = LoadServers()
    print("✅ Готово к работе. Серверов:", #SERVER_LIST)
    
    while true do
        -- Фильтрация доступных серверов
        local available = {}
        for _, serverId in ipairs(SERVER_LIST) do
            if IsServerAvailable(serverId) then
                table.insert(available, serverId)
            end
        end
        
        -- Если нет доступных - ждем и пробуем снова
        if #available == 0 then
            print("⏳ Все серверы на кд. Ожидание...")
            task.wait(SETTINGS.COOLDOWN_TIME / 2)
            TeleportLoop()
            return
        end
        
        -- Выбор случайного сервера
        local target = available[math.random(1, #available)]
        
        -- Мгновенный телепорт с обработкой ошибок
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                SETTINGS.GAME_ID,
                target,
                Players.LocalPlayer
            )
        end)
        
        if not success then
            print("⚠ Ошибка на сервере:", target:sub(1, 8).."...")
            BLACKLIST[target] = os.time()
            task.wait(0.01) -- Минимальная задержка перед повторной попыткой
        else
            BLACKLIST[target] = os.time()
            print("🚀 Успешный переход:", target:sub(1, 8).."...")
            break -- Прерываем цикл после успешного телепорта
        end
    end
end

-- Автоперезапуск при любых ошибках
while true do
    local success, err = pcall(TeleportLoop)
    if not success then
        warn("💥 Критическая ошибка:", err)
        task.wait(5)
    end
end
