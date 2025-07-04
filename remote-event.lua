-- Konfigurasi Awal
local _U = "_U" .. tostring(math.random(1e6))
local _V = {} -- Log entries
local _W = {logging = true, selectPart = false, selectGUI = false} -- Flags
local _X = {} -- UI references

-- Fungsi Helper
local function formatPath(instance)
    local parts = {}
    while instance do
        table.insert(parts, 1, instance.Name)
        instance = instance.Parent
    end
    return table.concat(parts, ".")
end

local function flattenTable(tbl, depth, maxDepth)
    if type(tbl) ~= "table" or depth > maxDepth then return tbl end
    local result = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            result[k] = flattenTable(v, depth + 1, maxDepth)
        else
            result[k] = v
        end
    end
    return result
end

local function copyToClipboard(text)
    local success, err = pcall(function()
        setclipboard(text)
    end)
    if not success then
        warn(err)
    end
end

local function formatDate()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

-- Fungsi Hook Remote
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(...)
    local args = {...}
    local self = args[1]
    local method = getnamecallmethod()

    if method == "FireServer" or method == "InvokeServer" then
        local name = self.Name
        local path = formatPath(self)
        local kind = self:IsA("RemoteEvent") and "RemoteEvent" or "RemoteFunction"
        local time = formatDate()
        local arguments = {}
        for i, arg in ipairs(args) do
            if i > 20 then
                table.insert(arguments, "..." .. (#args - 20))
                break
            end
            local argType = typeof(arg)
            local argValue = argType == "table" and flattenTable(arg, 1, 3) or tostring(arg)
            table.insert(arguments, {type = argType, value = argValue})
        end

        table.insert(_V, 1, {name = name, path = path, kind = kind, time = time, args = arguments})
        if #_V > 500 then
            table.remove(_V)
        end
    end

    return oldNamecall(unpack(args))
end)

setreadonly(mt, true)

-- Fungsi Create GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = _U

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame

    local closeButton = Instance.new("ImageButton")
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -28, 0, 8)
    closeButton.Image = "rbxassetid://7733764649"
    closeButton.BackgroundTransparency = 1
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        _X.icon.Visible = true
    end)
    closeButton.Parent = mainFrame

    local minimizeButton = Instance.new("ImageButton")
    minimizeButton.Size = UDim2.new(0, 24, 0, 24)
    minimizeButton.Position = UDim2.new(1, -58, 0, 8)
    minimizeButton.Image = "rbxassetid://7733770963"
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        _X.icon.Visible = true
    end)
    minimizeButton.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -64, 0, 32)
    title.Position = UDim2.new(0, 16, 0, 8)
    title.Text = "Remote Spy"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = mainFrame

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -16, 1, -112)
    scrollFrame.Position = UDim2.new(0, 8, 0, 48)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Parent = mainFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 8)
    uiListLayout.Parent = scrollFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -16, 0, 32)
    searchBox.Position = UDim2.new(0, 8, 0, 8)
    searchBox.PlaceholderText = "Search..."
    searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.Font = Enum.Font.SourceSans
    searchBox.TextSize = 16
    searchBox.Parent = mainFrame

    local clearButton = Instance.new("ImageButton")
    clearButton.Size = UDim2.new(0, 24, 0, 24)
    clearButton.Position = UDim2.new(1, -28, 0, 8)
    clearButton.Image = "rbxassetid://7733960981"
    clearButton.BackgroundTransparency = 1
    clearButton.MouseButton1Click:Connect(function()
        _V = {}
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end)
    clearButton.Parent = searchBox

    local exportButton = Instance.new("TextButton")
    exportButton.Size = UDim2.new(0, 80, 0, 32)
    exportButton.Position = UDim2.new(1, -104, 0, 8)
    exportButton.Text = "Export"
    exportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    exportButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    exportButton.BorderSizePixel = 0
    exportButton.Font = Enum.Font.SourceSans
    exportButton.TextSize = 16
    exportButton.MouseButton1Click:Connect(function()
        local logString = ""
        for _, log in ipairs(_V) do
            logString = logString .. string.format("%s (%s) - %s\n", log.name, log.path, log.time)
            for _, arg in ipairs(log.args) do
                logString = logString .. string.format("  %s: %s\n", arg.type, arg.value)
            end
            logString = logString .. "\n"
        end
        copyToClipboard(logString)
    end)
    exportButton.Parent = mainFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 80, 0, 32)
    toggleButton.Position = UDim2.new(1, -192, 0, 8)
    toggleButton.Text = "Toggle Log"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Font = Enum.Font.SourceSans
    toggleButton.TextSize = 16
    toggleButton.MouseButton1Click:Connect(function()
        _W.logging = not _W.logging
        toggleButton.Text = _W.logging and "Stop Log" or "Toggle Log"
    end)
    toggleButton.Parent = mainFrame

    local selectPartButton = Instance.new("TextButton")
    selectPartButton.Size = UDim2.new(0, 80, 0, 32)
    selectPartButton.Position = UDim2.new(1, -280, 0, 8)
    selectPartButton.Text = "Select Part"
    selectPartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectPartButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectPartButton.BorderSizePixel = 0
    selectPartButton.Font = Enum.Font.SourceSans
    selectPartButton.TextSize = 16
    selectPartButton.MouseButton1Click:Connect(function()
        _W.selectPart = not _W.selectPart
        selectPartButton.Text = _W.selectPart and "Stop Select Part" or "Select Part"
    end)
    selectPartButton.Parent = mainFrame

    local selectGUIButton = Instance.new("TextButton")
    selectGUIButton.Size = UDim2.new(0, 80, 0, 32)
    selectGUIButton.Position = UDim2.new(1, -368, 0, 8)
    selectGUIButton.Text = "Select GUI"
    selectGUIButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectGUIButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectGUIButton.BorderSizePixel = 0
    selectGUIButton.Font = Enum.Font.SourceSans
    selectGUIButton.TextSize = 16
    selectGUIButton.MouseButton1Click:Connect(function()
        _W.selectGUI = not _W.selectGUI
        selectGUIButton.Text = _W.selectGUI and "Stop Select GUI" or "Select GUI"
    end)
    selectGUIButton.Parent = mainFrame

    local function updateLogs()
        local searchTerm = searchBox.Text:lower()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child.Visible = string.find(child.Name:lower(), searchTerm) or searchTerm == ""
            end
        end
    end

    searchBox.Changed:Connect(function(prop)
        if prop == "Text" then
            updateLogs()
        end
    end)

    local function addLog(log)
        local logFrame = Instance.new("Frame")
        logFrame.Size = UDim2.new(1, 0, 0, 56)
        logFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        logFrame.BorderSizePixel = 0
        logFrame.Name = string.format("%s (%s) - %s", log.name, log.path, log.time)
        logFrame.Parent = scrollFrame

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = logFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.3, 0, 0, 28)
        nameLabel.Position = UDim2.new(0, 8, 0, 8)
        nameLabel.Text = log.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextSize = 16
        nameLabel.Parent = logFrame

        local pathLabel = Instance.new("TextLabel")
        pathLabel.Size = UDim2.new(0.4, 0, 0, 28)
        pathLabel.Position = UDim2.new(0.3, 8, 0, 8)
        pathLabel.Text = log.path
        pathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        pathLabel.BackgroundTransparency = 1
        pathLabel.Font = Enum.Font.SourceSans
        pathLabel.TextSize = 16
        pathLabel.Parent = logFrame

        local kindLabel = Instance.new("TextLabel")
        kindLabel.Size = UDim2.new(0.1, 0, 0, 28)
        kindLabel.Position = UDim2.new(0.7, 8, 0, 8)
        kindLabel.Text = log.kind
        kindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        kindLabel.BackgroundTransparency = 1
        kindLabel.Font = Enum.Font.SourceSans
        kindLabel.TextSize = 16
        kindLabel.Parent = logFrame

        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0.1, 0, 0, 28)
        timeLabel.Position = UDim2.new(0.8, 8, 0, 8)
        timeLabel.Text = log.time
        timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Font = Enum.Font.SourceSans
        timeLabel.TextSize = 16
        timeLabel.Parent = logFrame

        local argLabel = Instance.new("TextLabel")
        argLabel.Size = UDim2.new(0.9, 0, 0, 28)
        argLabel.Position = UDim2.new(0, 8, 0.5, 0)
        argLabel.Text = ""
        argLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        argLabel.BackgroundTransparency = 1
        argLabel.Font = Enum.Font.SourceSans
        argLabel.TextSize = 16
        argLabel.Parent = logFrame

        local args = ""
        for _, arg in ipairs(log.args) do
            args = args .. string.format("%s: %s, ", arg.type, arg.value)
        end
        argLabel.Text = args:sub(1, -3)

        local expandButton = Instance.new("ImageButton")
        expandButton.Size = UDim2.new(0, 24, 0, 24)
        expandButton.Position = UDim2.new(1, -28, 0.5, -12)
        expandButton.Image = "rbxassetid://7733764596"
        expandButton.BackgroundTransparency = 1
        expandButton.MouseButton1Click:Connect(function()
            local expandedFrame = Instance.new("Frame")
            expandedFrame.Size = UDim2.new(1, 0, 0, 0)
            expandedFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            expandedFrame.BorderSizePixel = 0
            expandedFrame.Visible = false
            expandedFrame.Parent = logFrame

            local uiListLayout = Instance.new("UIListLayout")
            uiListLayout.Padding = UDim.new(0, 8)
            uiListLayout.Parent = expandedFrame

            for _, arg in ipairs(log.args) do
                local argFrame = Instance.new("Frame")
                argFrame.Size = UDim2.new(1, 0, 0, 28)
                argFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                argFrame.BorderSizePixel = 0
                argFrame.Parent = expandedFrame

                local uiCorner = Instance.new("UICorner")
                uiCorner.CornerRadius = UDim.new(0, 8)
                uiCorner.Parent = argFrame

                local argTypeLabel = Instance.new("TextLabel")
                argTypeLabel.Size = UDim2.new(0.2, 0, 0, 28)
                argTypeLabel.Position = UDim2.new(0, 8, 0, 0)
                argTypeLabel.Text = arg.type
                argTypeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                argTypeLabel.BackgroundTransparency = 1
                argTypeLabel.Font = Enum.Font.SourceSans
                argTypeLabel.TextSize = 16
                argTypeLabel.Parent = argFrame

                local argValueLabel = Instance.new("TextLabel")
                argValueLabel.Size = UDim2.new(0.8, 0, 0, 28)
                argValueLabel.Position = UDim2.new(0.2, 8, 0, 0)
                argValueLabel.Text = arg.value
                argValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                argValueLabel.BackgroundTransparency = 1
                argValueLabel.Font = Enum.Font.SourceSans
                argValueLabel.TextSize = 16
                argValueLabel.Parent = argFrame
            end

            local copyPathButton = Instance.new("TextButton")
            copyPathButton.Size = UDim2.new(0, 80, 0, 32)
            copyPathButton.Position = UDim2.new(0, 8, 0, 8)
            copyPathButton.Text = "Copy Path"
            copyPathButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyPathButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            copyPathButton.BorderSizePixel = 0
            copyPathButton.Font = Enum.Font.SourceSans
            copyPathButton.TextSize = 16
            copyPathButton.MouseButton1Click:Connect(function()
                copyToClipboard(log.path)
            end)
            copyPathButton.Parent = expandedFrame

            local copyArgsButton = Instance.new("TextButton")
            copyArgsButton.Size = UDim2.new(0, 80, 0, 32)
            copyArgsButton.Position = UDim2.new(0, 96, 0, 8)
            copyArgsButton.Text = "Copy Args"
            copyArgsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyArgsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            copyArgsButton.BorderSizePixel = 0
            copyArgsButton.Font = Enum.Font.SourceSans
            copyArgsButton.TextSize = 16
            copyArgsButton.MouseButton1Click:Connect(function()
                local argsString = ""
                for _, arg in ipairs(log.args) do
                    argsString = argsString .. string.format("%s: %s, ", arg.type, arg.value)
                end
                copyToClipboard(argsString:sub(1, -3))
            end)
            copyArgsButton.Parent = expandedFrame

            local deleteButton = Instance.new("TextButton")
            deleteButton.Size = UDim2.new(0, 80, 0, 32)
            deleteButton.Position = UDim2.new(0, 184, 0, 8)
            deleteButton.Text = "Delete"
            deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            deleteButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            deleteButton.BorderSizePixel = 0
            deleteButton.Font = Enum.Font.SourceSans
            deleteButton.TextSize = 16
            deleteButton.MouseButton1Click:Connect(function()
                for i, v in ipairs(_V) do
                    if v == log then
                        table.remove(_V, i)
                        break
                    end
                end
                logFrame:Destroy()
            end)
            deleteButton.Parent = expandedFrame

            local uiPadding = Instance.new("UIPadding")
            uiPadding.PaddingTop = UDim.new(0, 8)
            uiPadding.PaddingBottom = UDim.new(0, 8)
            uiPadding.Parent = expandedFrame

            local function toggleExpand()
                expandedFrame.Visible = not expandedFrame.Visible
                expandButton.Rotation = expandedFrame.Visible and 90 or 0
            end

            expandButton.MouseButton1Click:Connect(toggleExpand)
            logFrame.MouseButton1Click:Connect(toggleExpand)
        end)
        expandButton.Parent = logFrame

        local function updateCanvasSize()
            local totalHeight = 0
            for _, child in ipairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") then
                    totalHeight = totalHeight + child.AbsoluteSize.Y + uiListLayout.Padding.Offset.Y
                end
            end
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        end

        logFrame.Changed:Connect(updateCanvasSize)
        updateCanvasSize()
    end

    local function refreshLogs()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        for _, log in ipairs(_V) do
            addLog(log)
        end
    end

    refreshLogs()
    _W.refreshLogs = refreshLogs

    -- Floating Icon
    local icon = Instance.new("ImageButton")
    icon.Size = UDim2.new(0, 48, 0, 48)
    icon.Position = UDim2.new(0, 16, 1, -64)
    icon.Image = "rbxassetid://7733764596"
    icon.BackgroundTransparency = 1
    icon.Visible = true
    icon.Draggable = true
    icon.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        icon.Visible = false
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(mainFrame, tweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0)})
        tween:Play()
    end)
    icon.Parent = screenGui

    _X.icon = icon

    -- Touch Support
    local function onTouchStarted(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local touchPos = input.Position
            local object = game:GetService("Players").LocalPlayer:GetMouse().Target
            if _W.selectPart and object and object:IsA("BasePart") then
                object.BrickColor = BrickColor.new("Bright red")
                local partPath = formatPath(object)
                local partInfo = Instance.new("TextLabel")
                partInfo.Size = UDim2.new(0.5, 0, 0, 32)
                partInfo.Position = UDim2.new(0.25, 0, 0.8, 0)
                partInfo.Text = partPath
                partInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
                partInfo.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                partInfo.BorderSizePixel = 0
                partInfo.Font = Enum.Font.SourceSans
                partInfo.TextSize = 16
                partInfo.Parent = screenGui
                wait(2)
                partInfo:Destroy()
                object.BrickColor = object.OriginalColor
            elseif _W.selectGUI and object and object:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) then
                local guiPath = formatPath(object)
                local guiInfo = Instance.new("TextLabel")
                guiInfo.Size = UDim2.new(0.5, 0, 0, 32)
                guiInfo.Position = UDim2.new(0.25, 0, 0.8, 0)
                guiInfo.Text = guiPath .. " (" .. object.ClassName .. ")"
                guiInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
                guiInfo.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                guiInfo.BorderSizePixel = 0
                guiInfo.Font = Enum.Font.SourceSans
                guiInfo.TextSize = 16
                guiInfo.Parent = screenGui
                wait(2)
                guiInfo:Destroy()
            end
        end
    end

    game:GetService("UserInputService").InputBegan:Connect(onTouchStarted)

    -- Drag Support
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function updateInput(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    local function finishDrag()
        dragging = false
        dragInput = nil
        dragStart = nil
        startPos = nil
    end

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    finishDrag()
                end
            end)
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)

    -- Initial Animation
    local initialTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local initialTween = game:GetService("TweenService"):Create(icon, initialTweenInfo, {Position = UDim2.new(0, 16, 1, -64)})
    initialTween:Play()
end

-- Fungsi Event Handler GUI
game:GetService("RunService").Heartbeat:Connect(function()
    if _W.logging then
        _W.refreshLogs()
    end
end)

-- Fungsi Select Part/GUI
createGUI()
