local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local placeId = 109983668079237
local visitedServers = {} -- таблица для хранения посещенных серверов

local function getRandomServer()
    local success, result = pcall(function()
        -- Получаем список серверов через внешний запрос к API Roblox
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        
        local availableServers = {}
        
        -- Фильтруем серверы, исключая уже посещенные
        for _, server in pairs(data.data) do
            if server.id and server.playing < server.maxPlayers then
                if not visitedServers[server.id] then
                    table.insert(availableServers, server.id)
                end
            end
        end
        
        -- Если все серверы были посещены, очищаем список
        if #availableServers == 0 then
            visitedServers = {}
            for _, server in pairs(data.data) do
                if server.id and server.playing < server.maxPlayers then
                    table.insert(availableServers, server.id)
                end
            end
        end
        
        -- Выбираем случайный сервер
        if #availableServers > 0 then
            local randomIndex = math.random(1, #availableServers)
            local selectedServerId = availableServers[randomIndex]
            visitedServers[selectedServerId] = true
            return selectedServerId
        end
        
        return nil
    end)
    
    if success then
        return result
    else
        return nil
    end
end

local function teleportToNewServer()
    local serverId = getRandomServer()
    
    if serverId then
        -- Телепортируемся на выбранный сервер
        TeleportService:TeleportToPlaceInstance(placeId, serverId, Players.LocalPlayer)
    else
        -- Если не удалось получить сервер, используем обычный телепорт
        TeleportService:Teleport(placeId, Players.LocalPlayer)
    end
end

-- Основной цикл
while true do
    wait(5) -- ждем 7 секунд
    teleportToNewServer()
end
