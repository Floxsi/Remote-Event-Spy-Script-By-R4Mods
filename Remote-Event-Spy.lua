-- Bagian Konfigurasi Awal
local _U = {} -- Namespace untuk menyimpan fungsi dan variabel
_U.logs = {}
_U.maxLogs = 500
_U.isActive = true
_U.isSelectPartActive = false
_U.isSelectGUIActive = false
_U.searchTerm = ""
_U.isMinimized = false

-- Fungsi Helper
function _U.formatTime(t)
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

function _U.flattenTable(tbl, depth, maxDepth)
    if depth > maxDepth or type(tbl) ~= "table" then
        return tostring(tbl)
    end
    local result = "{"
    local count = 0
    for k, v in pairs(tbl) do
        count = count + 1
        if count > 20 then
            result = result .. ", ..."
            break
        end
        result = result .. tostring(k) .. ": " .. _U.flattenTable(v, depth + 1, maxDepth) .. ", "
    end
    if result:sub(-2) == ", " then
        result = result:sub(1, -3)
    end
    result = result .. "}"
    return result
end

function _U.copyToClipboard(str)
    pcall(function()
        setclipboard(str)
    end)
end

-- Fungsi Hook Remote
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(...)
    local args = {...}
    local self = args[1]
    local method = getnamecallmethod()

    if _U.isActive and (method == "FireServer" or method == "InvokeServer") then
        local name = self.Name
        local path = self:GetFullName()
        local time = os.date("*t")
        local formattedTime = _U.formatTime(time)
        local argsStr = _U.flattenTable(table.move(args, 2, #args, 1, {}), 1, 3)
        local logEntry = {
            name = name,
            path = path,
            type = method == "FireServer" and "RemoteEvent" or "RemoteFunction",
            time = formattedTime,
            args = argsStr,
            fullArgs = args
        }
        table.insert(_U.logs, logEntry)
        if #_U.logs > _U.maxLogs then
            table.remove(_U.logs, 1)
        end
        _U.updateLogDisplay()
    end

    return oldNamecall(unpack(args))
end)

-- Fungsi Create GUI
function _U.createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundTransparency = 1
    closeButton.Image = "rbxassetid://7733764649"
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    closeButton.Parent = mainFrame

    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -60, 0, 0)
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.Image = "rbxassetid://7733770963"
    minimizeButton.MouseButton1Click:Connect(function()
        _U.toggleMinimize(mainFrame)
    end)
    minimizeButton.Parent = mainFrame

    local scrollFrame = Instance.new("ScrollFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -60)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 10
    scrollFrame.Parent = mainFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = scrollFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -20, 0, 30)
    searchBox.Position = UDim2.new(0, 10, 0, 10)
    searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.PlaceholderText = "Search..."
    searchBox.ClearTextOnFocus = false
    searchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            _U.searchTerm = searchBox.Text
            _U.updateLogDisplay()
        end
    end)
    searchBox.Parent = mainFrame

    local toggleLoggingButton = Instance.new("TextButton")
    toggleLoggingButton.Size = UDim2.new(0, 100, 0, 30)
    toggleLoggingButton.Position = UDim2.new(0, 10, 0, 45)
    toggleLoggingButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleLoggingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLoggingButton.Text = _U.isActive and "Stop Logging" or "Start Logging"
    toggleLoggingButton.MouseButton1Click:Connect(function()
        _U.isActive = not _U.isActive
        toggleLoggingButton.Text = _U.isActive and "Stop Logging" or "Start Logging"
    end)
    toggleLoggingButton.Parent = mainFrame

    local clearLogButton = Instance.new("TextButton")
    clearLogButton.Size = UDim2.new(0, 100, 0, 30)
    clearLogButton.Position = UDim2.new(0, 120, 0, 45)
    clearLogButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    clearLogButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearLogButton.Text = "Clear Log"
    clearLogButton.MouseButton1Click:Connect(function()
        _U.logs = {}
        _U.updateLogDisplay()
    end)
    clearLogButton.Parent = mainFrame

    local exportLogButton = Instance.new("TextButton")
    exportLogButton.Size = UDim2.new(0, 100, 0, 30)
    exportLogButton.Position = UDim2.new(0, 230, 0, 45)
    exportLogButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    exportLogButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    exportLogButton.Text = "Export Log"
    exportLogButton.MouseButton1Click:Connect(function()
        local logString = ""
        for _, log in ipairs(_U.logs) do
            logString = logString .. string.format("%s [%s] %s: %s\n", log.time, log.type, log.name, log.args)
        end
        _U.copyToClipboard(logString)
    end)
    exportLogButton.Parent = mainFrame

    local selectPartButton = Instance.new("TextButton")
    selectPartButton.Size = UDim2.new(0, 100, 0, 30)
    selectPartButton.Position = UDim2.new(0, 10, 0, 85)
    selectPartButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectPartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectPartButton.Text = _U.isSelectPartActive and "Stop Select Part" or "Select Part"
    selectPartButton.MouseButton1Click:Connect(function()
        _U.isSelectPartActive = not _U.isSelectPartActive
        selectPartButton.Text = _U.isSelectPartActive and "Stop Select Part" or "Select Part"
    end)
    selectPartButton.Parent = mainFrame

    local selectGUIButton = Instance.new("TextButton")
    selectGUIButton.Size = UDim2.new(0, 100, 0, 30)
    selectGUIButton.Position = UDim2.new(0, 120, 0, 85)
    selectGUIButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectGUIButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectGUIButton.Text = _U.isSelectGUIActive and "Stop Select GUI" or "Select GUI"
    selectGUIButton.MouseButton1Click:Connect(function()
        _U.isSelectGUIActive = not _U.isSelectGUIActive
        selectGUIButton.Text = _U.isSelectGUIActive and "Stop Select GUI" or "Select GUI"
    end)
    selectGUIButton.Parent = mainFrame

    return mainFrame, scrollFrame
end

function _U.createFloatingIcon(screenGui)
    local floatIcon = Instance.new("ImageButton")
    floatIcon.Size = UDim2.new(0, 50, 0, 50)
    floatIcon.Position = UDim2.new(0.9, -50, 0.9, -50)
    floatIcon.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    floatIcon.Image = "rbxassetid://7733770963"
    floatIcon.Active = true
    floatIcon.Draggable = true
    floatIcon.MouseButton1Click:Connect(function()
        _U.toggleMinimize(nil)
    end)
    floatIcon.Parent = screenGui

    return floatIcon
end

function _U.toggleMinimize(mainFrame)
    if mainFrame then
        _U.isMinimized = not _U.isMinimized
        mainFrame.Visible = not _U.isMinimized
    else
        _U.isMinimized = false
        local screenGui = game.Players.LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui")
        if screenGui then
            local mainFrame = screenGui:FindFirstChildOfClass("Frame")
            if mainFrame then
                mainFrame.Visible = true
            end
        end
    end
end

function _U.updateLogDisplay()
    local screenGui = game.Players.LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui")
    if screenGui then
        local scrollFrame = screenGui:FindFirstChildOfClass("ScrollFrame")
        if scrollFrame then
            for _, child in ipairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            for _, log in ipairs(_U.logs) do
                if string.match(string.lower(log.path), string.lower(_U.searchTerm)) then
                    local logFrame = Instance.new("Frame")
                    logFrame.Size = UDim2.new(1, 0, 0, 50)
                    logFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    logFrame.BorderSizePixel = 0
                    logFrame.Parent = scrollFrame

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
                    nameLabel.Position = UDim2.new(0, 0, 0, 0)
                    nameLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nameLabel.Text = log.name
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.Parent = logFrame

                    local pathLabel = Instance.new("TextLabel")
                    pathLabel.Size = UDim2.new(0.4, 0, 1, 0)
                    pathLabel.Position = UDim2.new(0.3, 0, 0, 0)
                    pathLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    pathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    pathLabel.Text = log.path
                    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
                    pathLabel.Parent = logFrame

                    local typeLabel = Instance.new("TextLabel")
                    typeLabel.Size = UDim2.new(0.1, 0, 1, 0)
                    typeLabel.Position = UDim2.new(0.7, 0, 0, 0)
                    typeLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    typeLabel.Text = log.type
                    typeLabel.TextXAlignment = Enum.TextXAlignment.Center
                    typeLabel.Parent = logFrame

                    local timeLabel = Instance.new("TextLabel")
                    timeLabel.Size = UDim2.new(0.1, 0, 1, 0)
                    timeLabel.Position = UDim2.new(0.8, 0, 0, 0)
                    timeLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    timeLabel.Text = log.time
                    timeLabel.TextXAlignment = Enum.TextXAlignment.Center
                    timeLabel.Parent = logFrame

                    local argsLabel = Instance.new("TextLabel")
                    argsLabel.Size = UDim2.new(0.1, 0, 1, 0)
                    argsLabel.Position = UDim2.new(0.9, 0, 0, 0)
                    argsLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    argsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    argsLabel.Text = log.args
                    argsLabel.TextXAlignment = Enum.TextXAlignment.Left
                    argsLabel.Parent = logFrame

                    logFrame.MouseButton1Click:Connect(function()
                        _U.showDetailedLog(log)
                    end)
                end
            end
        end
    end
end

function _U.showDetailedLog(log)
    local screenGui = game.Players.LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui")
    if screenGui then
        local detailedFrame = Instance.new("Frame")
        detailedFrame.Size = UDim2.new(0.7, 0, 0.5, 0)
        detailedFrame.Position = UDim2.new(0.15, 0, 0.25, 0)
        detailedFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        detailedFrame.BorderSizePixel = 0
        detailedFrame.Active = true
        detailedFrame.Draggable = true
        detailedFrame.Parent = screenGui

        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -30, 0, 0)
        closeButton.BackgroundTransparency = 1
        closeButton.Image = "rbxassetid://7733764649"
        closeButton.MouseButton1Click:Connect(function()
            detailedFrame:Destroy()
        end)
        closeButton.Parent = detailedFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 0, 30)
        nameLabel.Position = UDim2.new(0, 10, 0, 10)
        nameLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Text = "Name: " .. log.name
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = detailedFrame

        local pathLabel = Instance.new("TextLabel")
        pathLabel.Size = UDim2.new(1, -20, 0, 30)
        pathLabel.Position = UDim2.new(0, 10, 0, 45)
        pathLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        pathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        pathLabel.Text = "Path: " .. log.path
        pathLabel.TextXAlignment = Enum.TextXAlignment.Left
        pathLabel.Parent = detailedFrame

        local typeLabel = Instance.new("TextLabel")
        typeLabel.Size = UDim2.new(1, -20, 0, 30)
        typeLabel.Position = UDim2.new(0, 10, 0, 80)
        typeLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        typeLabel.Text = "Type: " .. log.type
        typeLabel.TextXAlignment = Enum.TextXAlignment.Left
        typeLabel.Parent = detailedFrame

        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(1, -20, 0, 30)
        timeLabel.Position = UDim2.new(0, 10, 0, 115)
        timeLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timeLabel.Text = "Time: " .. log.time
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Parent = detailedFrame

        local argsLabel = Instance.new("TextLabel")
        argsLabel.Size = UDim2.new(1, -20, 0, 100)
        argsLabel.Position = UDim2.new(0, 10, 0, 150)
        argsLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        argsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        argsLabel.Text = "Args: " .. _U.flattenTable(log.fullArgs, 1, 5)
        argsLabel.TextXAlignment = Enum.TextXAlignment.Left
        argsLabel.TextWrapped = true
        argsLabel.Parent = detailedFrame

        local copyPathButton = Instance.new("TextButton")
        copyPathButton.Size = UDim2.new(0, 100, 0, 30)
        copyPathButton.Position = UDim2.new(0, 10, 0, 260)
        copyPathButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        copyPathButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyPathButton.Text = "Copy Path"
        copyPathButton.MouseButton1Click:Connect(function()
            _U.copyToClipboard(log.path)
        end)
        copyPathButton.Parent = detailedFrame

        local copyArgsButton = Instance.new("TextButton")
        copyArgsButton.Size = UDim2.new(0, 100, 0, 30)
        copyArgsButton.Position = UDim2.new(0, 120, 0, 260)
        copyArgsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        copyArgsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyArgsButton.Text = "Copy Args"
        copyArgsButton.MouseButton1Click:Connect(function()
            _U.copyToClipboard(_U.flattenTable(log.fullArgs, 1, 5))
        end)
        copyArgsButton.Parent = detailedFrame
    end
end

-- Fungsi Event Handler GUI
game.Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") then
        local mainFrame, scrollFrame = _U.createMainGUI()
        _U.createFloatingIcon(child)
        _U.updateLogDisplay()
    end
end)

-- Fungsi Select Part/GUI
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if _U.isSelectPartActive and input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local target = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(game:GetService("Workspace").CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y), {game.Players.LocalPlayer.Character})
            if target then
                local path = target:GetFullName()
                _U.showSelectedInfo(path, target.ClassName)
            end
        elseif _U.isSelectGUIActive and input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local target = game:GetService("GuiService"):FindPartOnScreenPoint(input.Position)
            if target and target:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) then
                local path = target:GetFullName()
                _U.showSelectedInfo(path, target.ClassName)
            end
        end
    end
end)

function _U.showSelectedInfo(path, className)
    local screenGui = game.Players.LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui")
    if screenGui then
        local infoFrame = Instance.new("Frame")
        infoFrame.Size = UDim2.new(0.5, 0, 0.2, 0)
        infoFrame.Position = UDim2.new(0.25, 0, 0.4, 0)
        infoFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        infoFrame.BorderSizePixel = 0
        infoFrame.Active = true
        infoFrame.Draggable = true
        infoFrame.Parent = screenGui

        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -30, 0, 0)
        closeButton.BackgroundTransparency = 1
        closeButton.Image = "rbxassetid://7733764649"
        closeButton.MouseButton1Click:Connect(function()
            infoFrame:Destroy()
        end)
        closeButton.Parent = infoFrame

        local pathLabel = Instance.new("TextLabel")
        pathLabel.Size = UDim2.new(1, -20, 0, 30)
        pathLabel.Position = UDim2.new(0, 10, 0, 10)
        pathLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        pathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        pathLabel.Text = "Path: " .. path
        pathLabel.TextXAlignment = Enum.TextXAlignment.Left
        pathLabel.Parent = infoFrame

        local classLabel = Instance.new("TextLabel")
        classLabel.Size = UDim2.new(1, -20, 0, 30)
        classLabel.Position = UDim2.new(0, 10, 0, 45)
        classLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        classLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        classLabel.Text = "Class: " .. className
        classLabel.TextXAlignment = Enum.TextXAlignment.Left
        classLabel.Parent = infoFrame

        local copyPathButton = Instance.new("TextButton")
        copyPathButton.Size = UDim2.new(0, 100, 0, 30)
        copyPathButton.Position = UDim2.new(0, 10, 0, 85)
        copyPathButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        copyPathButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyPathButton.Text = "Copy Path"
        copyPathButton.MouseButton1Click:Connect(function()
            _U.copyToClipboard(path)
        end)
        copyPathButton.Parent = infoFrame
    end
end
