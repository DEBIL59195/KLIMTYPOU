local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local placeId = 109983668079237
local visitedServers = {}
local currentJobId = game.JobId
local player = Players.LocalPlayer
local accountId = player.UserId .. "_" .. tick()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopperLogs"
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "FAST SERVER HOPPER"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.Code
titleLabel.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "LogsFrame"
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
scrollFrame.BorderSizePixel = 1
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scrollFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = mainFrame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local logCount = 0
local function addLog(message, logType)
    logCount = logCount + 1
    
    local logLabel = Instance.new("TextLabel")
    logLabel.Name = "Log_" .. logCount
    logLabel.Size = UDim2.new(1, -10, 0, 20)
    logLabel.BackgroundTransparency = 1
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.TextYAlignment = Enum.TextYAlignment.Center
    logLabel.Font = Enum.Font.Code
    logLabel.TextSize = 12
    logLabel.AutomaticSize = Enum.AutomaticSize.Y
    logLabel.TextWrapped = true
    logLabel.LayoutOrder = logCount
    
    if logType == "INFO" then
        logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        logLabel.Text = "[INFO] " .. os.date("%H:%M:%S") .. " - " .. message
    elseif logType == "SUCCESS" then
        logLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        logLabel.Text = "[SUCCESS] " .. os.date("%H:%M:%S") .. " - " .. message
    elseif logType == "WARNING" then
        logLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        logLabel.Text = "[WARNING] " .. os.date("%H:%M:%S") .. " - " .. message
    elseif logType == "ERROR" then
        logLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        logLabel.Text = "[ERROR] " .. os.date("%H:%M:%S") .. " - " .. message
    end
    
    logLabel.Parent = scrollFrame
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
    
    if logCount > 50 then
        local oldestLog = scrollFrame:FindFirstChild("Log_" .. (logCount - 50))
        if oldestLog then
            oldestLog:Destroy()
        end
    end
end

addLog("FAST Server Hopper активирован!", "SUCCESS")
addLog("Account: " .. accountId, "INFO")

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
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
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
        addLog("Сброс истории", "WARNING")
        return getFastServer()
    end
    
    table.sort(fastServers, function(a, b) return a.priority > b.priority end)
    
    local topChoice = math.min(5, #fastServers)
    local selected = fastServers[math.random(1, topChoice)]
    
    visitedServers[selected.id] = true
    addLog("Сервер: " .. selected.id .. " [" .. selected.playing .. "/" .. selected.maxPlayers .. "]", "SUCCESS")
    
    return selected.id
end

local function instantHop()
    local startTime = tick()
    addLog(">>> БЫСТРЫЙ ХОП НАЧАТ", "INFO")
    
    local serverId = getFastServer()
    
    if serverId then
        local findTime = math.round((tick() - startTime) * 1000)
        addLog("Сервер найден за " .. findTime .. "мс", "SUCCESS")
        addLog(">>> ТЕЛЕПОРТ!", "SUCCESS")
        
        currentJobId = serverId
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    else
        addLog(">>> ОБЫЧНЫЙ ТЕЛЕПОРТ", "WARNING")
        TeleportService:Teleport(placeId, player)
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    addLog("Телепорт неудачен: " .. tostring(errorMessage), "ERROR")
    wait(2)
    addLog(">>> ПОВТОРНАЯ ПОПЫТКА", "WARNING")
    instantHop()
end)

spawn(function()
    local quickStart = math.random(50, 200) / 1000
    addLog("Быстрый старт через " .. quickStart .. "с", "INFO")
    wait(quickStart)
    
    while true do
        wait(3.7)
        addLog(">>> ТАЙМЕР ИСТЕК", "INFO")
        instantHop()
    end
end)

addLog("Переходы каждые 3.7 секунды", "INFO")
addLog("Кеширование: " .. CACHE_DURATION .. "с", "INFO")
addLog("Максимум логов: 50", "INFO")
addLog("Текущий сервер исключен: " .. currentJobId, "INFO")
