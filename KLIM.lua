local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local placeId = 109983668079237
local visitedServers = {}
local currentJobId = game.JobId -- Получаем ID текущего сервера
local player = Players.LocalPlayer

print("Текущий сервер JobId:", currentJobId)

local function getServerList()
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=25"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        return data
    end)
    
    if success then
        return result
    else
        warn("Не удалось получить список серверов")
        return nil
    end
end

local function getRandomServer()
    local serverData = getServerList()
    if not serverData or not serverData.data then
        return nil
    end
    
    local availableServers = {}
    
    for _, server in pairs(serverData.data) do
        -- Исключаем текущий сервер, посещенные серверы, полные и пустые серверы
        if server.id and 
           server.id ~= currentJobId and -- НЕ текущий сервер
           not visitedServers[server.id] and -- НЕ посещенный ранее
           server.playing > 0 and -- НЕ пустой
           server.playing < server.maxPlayers then -- НЕ полный
            table.insert(availableServers, server.id)
        end
    end
    
    -- Если подходящих серверов нет, очищаем историю (кроме текущего)
    if #availableServers == 0 then
        visitedServers = {}
        visitedServers[currentJobId] = true -- Оставляем текущий в исключениях
        
        for _, server in pairs(serverData.data) do
            if server.id and 
               server.id ~= currentJobId and
               server.playing > 0 and 
               server.playing < server.maxPlayers then
                table.insert(availableServers, server.id)
            end
        end
    end
    
    if #availableServers > 0 then
        local randomIndex = math.random(1, #availableServers)
        local selectedServer = availableServers[randomIndex]
        visitedServers[selectedServer] = true
        print("Выбран сервер:", selectedServer, "из", #availableServers, "доступных")
        return selectedServer
    end
    
    return nil
end

local function serverHop()
    local serverId = getRandomServer()
    
    if serverId then
        print("Телепортируемся на сервер:", serverId)
        -- Обновляем текущий JobId для следующей итерации
        currentJobId = serverId
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    else
        warn("Не найден подходящий сервер, используем обычный телепорт")
        TeleportService:Teleport(placeId, player)
    end
end

-- Основной цикл
spawn(function()
    while true do
        wait(7)
        print("Начинаем поиск нового сервера...")
        serverHop()
    end
end)

print("Server hopper запущен! Смена сервера каждые 7 секунд.")
print("Исключаем текущий сервер:", currentJobId)
