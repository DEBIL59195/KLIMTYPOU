local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local placeId = 109983668079237
local visitedServers = {}
local currentJobId = game.JobId
local player = Players.LocalPlayer
local accountId = player.UserId .. "_" .. tick()
local teleportFailed = false

-- GUI по центру экрана
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FastHopper"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Основная панель по центру
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 350)  -- Увеличенный размер
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)  -- Центрирование
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- Позиция по центру
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
mainFrame.Parent = screenGui

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "FAST SERVER HOPPER"
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Кнопка закрытия
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = titleBar

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Информационная панель
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, -20, 0, 60)
infoFrame.Position = UDim2.new(0, 10, 0, 50)
infoFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
infoFrame.BorderSizePixel = 1
infoFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
infoFrame.Parent = mainFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -20)
infoLabel.Position = UDim2.new(0, 10, 0, 10)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Account: " .. accountId .. "\nИнтервал: 3.7с (2с после ошибки)\nКеш: " .. "10с" .. " | Лимит логов: 30"
infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextWrapped = true
infoLabel.Parent = infoFrame

-- Контейнер логов
local logsFrame = Instance.new("Frame")
logsFrame.Size = UDim2.new(1, -20, 1, -130)
logsFrame.Position = UDim2.new(0, 10, 0, 120)
logsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logsFrame.BorderSizePixel = 1
logsFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
logsFrame.Parent = mainFrame

local logsTitle = Instance.new("TextLabel")
logsTitle.Size = UDim2.new(1, 0, 0, 25)
logsTitle.Position = UDim2.new(0, 0, 0, 0)
logsTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
logsTitle.BorderSizePixel = 0
logsTitle.Text = "ЛОГИ АКТИВНОСТИ"
logsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
logsTitle.TextSize = 14
logsTitle.Font = Enum.Font.SourceSansBold
logsTitle.Parent = logsFrame

-- Скроллинг для логов
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -35)
scrollFrame.Position = UDim2.new(0, 5, 0, 30)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = logsFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scrollFrame

-- Функция логирования
local logCount = 0
local function addLog(message, logType)
    logCount = logCount + 1
    
    local logLabel = Instance.new("TextLabel")
    logLabel.Name = "Log_" .. logCount
    logLabel.Size = UDim2.new(1, -10, 0, 18)
    logLabel.BackgroundTransparency = 1
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.TextYAlignment = Enum.TextYAlignment.Center
    logLabel.Font = Enum.Font.Code
    logLabel.TextSize = 12
    logLabel.TextWrapped = true
    logLabel.LayoutOrder = logCount
    
    -- Цветовая схема
    if logType == "SUCCESS" then
        logLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        logLabel.Text = "[✓] " .. os.date("%H:%M:%S") .. " - " .. message
    elseif logType == "ERROR" then
        logLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        logLabel.Text = "[✗] " .. os.date("%H:%M:%S") .. " - " .. message
    elseif logType == "WARNING" then
        logLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        logLabel.Text = "[!] " .. os.date("%H:%M:%S") .. " - " .. message
    else
        logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        logLabel.Text = "[i] " .. os.date("%H:%M:%S") .. " - " .. message
    end
    
    logLabel.Parent = scrollFrame
    
    -- Автопрокрутка вниз
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
    
    -- Ограничение логов до 30
    if logCount > 30 then
        local oldLog = scrollFrame:FindFirstChild("Log_" .. (logCount - 30))
        if oldLog then
            oldLog:Destroy()
        end
    end
end

-- Начальные логи
addLog("FAST Server Hopper активирован!", "SUCCESS")
addLog("Целевая игра: " .. placeId, "INFO")
addLog("Текущий сервер исключен: " .. currentJobId, "INFO")

-- Остальные функции остаются без изменений
local serverCache = {}
local lastCacheTime = 0
local CACHE_DURATION = 10

local function getFastServerList()
    local currentTime = tick()
    if currentTime - lastCacheTime < CACHE_DURATION and #serverCache > 0 then
        addLog("Используем кешированные серверы", "INFO")
        return serverCache
    end
    
    addLog("Быстрое получение серверов...", "INFO")
    local startTime = tick()
    
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Desc&limit=50&excludeFullGames=true"
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)
    
    if success and result and result.data then
        serverCache = result.data
        lastCacheTime = currentTime
        local requestTime = math.round((tick() - startTime) * 1000)
        addLog("Получено " .. #serverCache .. " серверов за " .. requestTime .. "мс", "SUCCESS")
        return serverCache
    else
        addLog("Ошибка API, используем кеш", "ERROR")
        return serverCache
    end
end

local function getFastServer()
    local serverData = getFastServerList()
    if not serverData or #serverData == 0 then
        addLog("Нет доступных серверов", "ERROR")
        return nil
    end
    
    local fastServers = {}
    
    for _, server in pairs(serverData) do
        if server.id and 
           server.id ~= currentJobId and
           not visitedServers[server.id] and
           server.playing > 0 then
            
            local fillPercent = server.playing / server.maxPlayers
            local freeSlots = server.maxPlayers - server.playing
            
            if fillPercent <= 0.5 and freeSlots >= 8 then
                table.insert(fastServers, {
                    id = server.id,
                    priority = freeSlots * 10,
                    playing = server.playing,
                    maxPlayers = server.maxPlayers
                })
            elseif fillPercent <= 0.8 and freeSlots >= 3 then
                table.insert(fastServers, {
                    id = server.id,
                    priority = freeSlots * 5,
                    playing = server.playing,
                    maxPlayers = server.maxPlayers
                })
            elseif freeSlots >= 1 then
                table.insert(fastServers, {
                    id = server.id,
                    priority = freeSlots,
                    playing = server.playing,
                    maxPlayers = server.maxPlayers
                })
            end
        end
    end
    
    if #fastServers == 0 then
        visitedServers = {}
        visitedServers[currentJobId] = true
        addLog("Сброс истории посещенных серверов", "WARNING")
        return getFastServer()
    end
    
    table.sort(fastServers, function(a, b) return a.priority > b.priority end)
    
    local topChoice = math.min(5, #fastServers)
    local selected = fastServers[math.random(1, topChoice)]
    
    visitedServers[selected.id] = true
    addLog("Выбран сервер: " .. selected.id .. " [" .. selected.playing .. "/" .. selected.maxPlayers .. "]", "SUCCESS")
    
    return selected.id
end

local function instantHop()
    local startTime = tick()
    addLog(">>> НАЧИНАЕМ ПЕРЕХОД НА НОВЫЙ СЕРВЕР", "INFO")
    
    local serverId = getFastServer()
    
    if serverId then
        local findTime = math.round((tick() - startTime) * 1000)
        addLog("Сервер найден за " .. findTime .. "мс", "SUCCESS")
        addLog(">>> ВЫПОЛНЯЕМ ТЕЛЕПОРТАЦИЮ!", "SUCCESS")
        
        currentJobId = serverId
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    else
        addLog(">>> ВЫПОЛНЯЕМ ОБЫЧНЫЙ ТЕЛЕПОРТ", "WARNING")
        TeleportService:Teleport(placeId, player)
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    addLog("Телепорт неудачен: " .. tostring(errorMessage), "ERROR")
    teleportFailed = true
    addLog(">>> СЛЕДУЮЩИЙ ПЕРЕХОД ЧЕРЕЗ 2 СЕКУНДЫ", "WARNING")
end)

spawn(function()
    local quickStart = math.random(50, 200) / 1000
    addLog("Быстрый старт через " .. math.round(quickStart * 1000) .. "мс", "INFO")
    wait(quickStart)
    
    while true do
        if teleportFailed then
            wait(2)
            teleportFailed = false
            addLog(">>> ПОВТОРНАЯ ПОПЫТКА ПОСЛЕ ОШИБКИ", "WARNING")
        else
            wait(3.7)
            addLog(">>> ТАЙМЕР ИСТЕК - НАЧИНАЕМ ПЕРЕХОД", "INFO")
        end
        instantHop()
    end
end)
