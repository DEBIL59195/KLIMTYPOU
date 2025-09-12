local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local placeId = 109983668079237
local visitedServers = {}
local currentJobId = game.JobId -- Получаем ID текущего сервера
local player = Players.LocalPlayer

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopperLogs"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Главный фрейм по центру экрана
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui

-- Заголовок
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

-- ScrollingFrame для логов
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

-- UIListLayout для автоматического размещения логов
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scrollFrame

-- Кнопка закрытия
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

-- Функция для добавления логов
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
    
    -- Цвета для разных типов логов
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
    
    -- Автоматическая прокрутка вниз
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
    
    -- Ограничение количества логов (оставляем только последние 50)
    if logCount > 50 then
        local oldestLog = scrollFrame:FindFirstChild("Log_" .. (logCount - 50))
        if oldestLog then
            oldestLog:Destroy()
        end
    end
end

-- Начальные логи
addLog("Server Hopper запущен!", "SUCCESS")
addLog("Текущий сервер JobId: " .. currentJobId, "INFO")
addLog("Смена сервера каждые 7 секунд", "INFO")
addLog("Исключаем текущий сервер: " .. currentJobId, "INFO")

local function getServerList()
    addLog("Получаем список серверов...", "INFO")
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=25"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        return data
    end)
    
    if success then
        addLog("Список серверов успешно получен", "SUCCESS")
        return result
    else
        addLog("Не удалось получить список серверов", "ERROR")
        return nil
    end
end

local function getRandomServer()
    addLog("Поиск доступного сервера...", "INFO")
    local serverData = getServerList()
    if not serverData or not serverData.data then
        addLog("Данные серверов недоступны", "ERROR")
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
    
    addLog("Найдено доступных серверов: " .. #availableServers, "INFO")
    
    -- Если подходящих серверов нет, очищаем историю (кроме текущего)
    if #availableServers == 0 then
        addLog("Очищаем историю посещенных серверов", "WARNING")
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
        addLog("После очистки найдено серверов: " .. #availableServers, "INFO")
    end
    
    if #availableServers > 0 then
        local randomIndex = math.random(1, #availableServers)
        local selectedServer = availableServers[randomIndex]
        visitedServers[selectedServer] = true
        addLog("Выбран сервер: " .. selectedServer .. " из " .. #availableServers .. " доступных", "SUCCESS")
        return selectedServer
    end
    
    addLog("Подходящие серверы не найдены", "WARNING")
    return nil
end

local function serverHop()
    addLog("Начинаем смену сервера...", "INFO")
    local serverId = getRandomServer()
    
    if serverId then
        addLog("Телепортируемся на сервер: " .. serverId, "SUCCESS")
        -- Обновляем текущий JobId для следующей итерации
        currentJobId = serverId
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    else
        addLog("Не найден подходящий сервер, используем обычный телепорт", "WARNING")
        TeleportService:Teleport(placeId, player)
    end
end

-- Основной цикл
spawn(function()
    while true do
        wait(7)
        addLog("Таймер истек, ищем новый сервер", "INFO")
        serverHop()
    end
end)
