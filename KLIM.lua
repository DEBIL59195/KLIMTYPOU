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
titleLabel.Text = "SERVER HOPPER LOGS"
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

addLog("Smart Server Hopper запущен!", "SUCCESS")
addLog("Account ID: " .. accountId, "INFO")
addLog("Текущий сервер JobId: " .. currentJobId, "INFO")

local function getServerList()
    addLog("Получаем список серверов (лимит 50)...", "INFO")
    local allServers = {}
    local cursor = nil
    
    for i = 1, 6 do
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Desc&limit=50&excludeFullGames=true"
            if cursor then
                url = url .. "&cursor=" .. cursor
            end
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            return data
        end)
        
        if success and result and result.data then
            for _, server in pairs(result.data) do
                table.insert(allServers, server)
            end
            cursor = result.nextPageCursor
            if not cursor or #allServers >= 200 then break end
            wait(0.3)
        else
            addLog("Ошибка получения страницы " .. i, "ERROR")
            break
        end
    end
    
    addLog("Получено серверов: " .. #allServers, "SUCCESS")
    return allServers
end

local function getOptimalServer()
    addLog("Поиск оптимального сервера...", "INFO")
    local serverData = getServerList()
    if not serverData or #serverData == 0 then
        addLog("Данные серверов недоступны", "ERROR")
        return nil
    end
    
    local lowFillServers = {}
    local mediumFillServers = {}
    local highFillServers = {}
    
    for _, server in pairs(serverData) do
        if server.id and 
           server.id ~= currentJobId and
           not visitedServers[server.id] and
           server.playing > 0 then
            
            local fillPercent = server.playing / server.maxPlayers
            local freeSlots = server.maxPlayers - server.playing
            
            local serverInfo = {
                id = server.id,
                priority = freeSlots + math.random(1, 5),
                playing = server.playing,
                maxPlayers = server.maxPlayers,
                fillPercent = fillPercent
            }
            
            if fillPercent <= 0.4 and freeSlots >= 10 then
                table.insert(lowFillServers, serverInfo)
            elseif fillPercent <= 0.7 and freeSlots >= 5 then
                table.insert(mediumFillServers, serverInfo)
            elseif fillPercent < 0.95 and freeSlots >= 1 then
                table.insert(highFillServers, serverInfo)
            end
        end
    end
    
    local targetList = {}
    if #lowFillServers > 0 then
        targetList = lowFillServers
        addLog("Используем серверы с низкой заполненностью: " .. #lowFillServers, "SUCCESS")
    elseif #mediumFillServers > 0 then
        targetList = mediumFillServers
        addLog("Используем серверы со средней заполненностью: " .. #mediumFillServers, "WARNING")
    else
        targetList = highFillServers
        addLog("Используем серверы с высокой заполненностью: " .. #highFillServers, "WARNING")
    end
    
    if #targetList == 0 then
        addLog("Очищаем историю посещений", "WARNING")
        visitedServers = {}
        visitedServers[currentJobId] = true
        
        for _, server in pairs(serverData) do
            if server.id and 
               server.id ~= currentJobId and
               server.playing > 0 and 
               server.playing < server.maxPlayers then
                
                table.insert(targetList, {
                    id = server.id,
                    priority = server.maxPlayers - server.playing,
                    playing = server.playing,
                    maxPlayers = server.maxPlayers
                })
            end
        end
    end
    
    if #targetList > 0 then
        table.sort(targetList, function(a, b)
            return a.priority > b.priority
        end)
        
        local topCount = math.min(8, #targetList)
        local selectedIndex = math.random(1, topCount)
        local selectedServer = targetList[selectedIndex]
        
        visitedServers[selectedServer.id] = true
        
        addLog("Выбран сервер: " .. selectedServer.id, "SUCCESS")
        addLog("Игроков: " .. selectedServer.playing .. "/" .. selectedServer.maxPlayers, "INFO")
        addLog("Позиция: " .. selectedIndex .. " из топ-" .. topCount, "INFO")
        
        return selectedServer.id
    end
    
    addLog("Подходящие серверы не найдены", "ERROR")
    return nil
end

local function smartServerHop()
    addLog("Начинаем умную смену сервера...", "INFO")
    local serverId = getOptimalServer()
    
    if serverId then
        addLog("Телепортируемся на сервер: " .. serverId, "SUCCESS")
        currentJobId = serverId
        
        local teleportDelay = math.random(200, 800) / 1000
        addLog("Задержка телепортации: " .. teleportDelay .. "с", "INFO")
        wait(teleportDelay)
        
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    else
        addLog("Используем обычную телепортацию", "WARNING")
        TeleportService:Teleport(placeId, player)
    end
end

spawn(function()
    local initialDelay = math.random(1, 4)
    addLog("Начальная задержка: " .. initialDelay .. "с", "INFO")
    wait(initialDelay)
    
    while true do
        wait(7)
        addLog("Таймер истек, ищем новый сервер", "INFO")
        smartServerHop()
    end
end)

addLog("Смена сервера каждые 7 секунд", "INFO")
addLog("Лимит API: 50 серверов за запрос", "INFO")
