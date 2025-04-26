local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESP Settings
local ESP_ENABLED = false
local SKELETON_ENABLED = false
local CORNER_BOX_ENABLED = false
local FOV_RADIUS = 500
local ARROW_SIZE = 15
local SKELETON_THICKNESS = 2
local CORNER_SIZE = 10
local TEAM_CHECK = false
local UPDATE_INTERVAL = 0.3
local MAX_DISTANCE = 500
local POSITION_CHANGE_THRESHOLD = 5
local ESP_COLOR = Color3.fromRGB(255, 0, 0) -- Red to match the GUI theme

-- Table for ESP data
local espData = {} -- {player = {arrow, skeletonLines = {}, cornerLines = {}, rootPart, lastPosition, lastUpdate}}

-- Helper function to create or reuse Drawing objects
local function getOrCreateDrawing(player, type, key, properties)
    local playerData = espData[player]
    if not playerData then
        return nil
    end
    if not playerData[key] then
        local success, obj = pcall(function()
            local drawing = Drawing.new(type)
            for prop, value in pairs(properties) do
                drawing[prop] = value
            end
            return drawing
        end)
        if success then
            playerData[key] = obj
        else
            warn("Failed to create Drawing object: " .. tostring(obj))
            return nil
        end
    end
    return playerData[key]
end

-- Helper function to check if a player is in FOV
local function isInFOV(position)
    local success, screenPos, onScreen = pcall(function()
        local pos, visible = Camera:WorldToViewportPoint(position)
        return pos, visible
    end)
    if not success then
        warn("Error in isInFOV: " .. tostring(screenPos))
        return false, Vector2.zero, false
    end
    if onScreen then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        return distance <= FOV_RADIUS, screenPos, onScreen
    end
    return false, screenPos, onScreen
end

-- Helper function to cache character parts
local function cacheCharacterParts(character)
    local parts = {}
    local requiredParts = {
        "Head",
        "UpperTorso", "Torso",
        "LowerTorso",
        "LeftUpperLeg", "LeftLowerLeg",
        "RightUpperLeg", "RightLowerLeg",
        "LeftUpperArm", "LeftLowerArm",
        "RightUpperArm", "RightLowerArm",
        "HumanoidRootPart"
    }
    for _, partName in ipairs(requiredParts) do
        local part = character:FindFirstChild(partName)
        if part then
            parts[partName] = part
        end
    end
    return parts
end

-- Helper function to update skeleton
local function updateSkeleton(player, character, parts, color)
    local playerData = espData[player]
    if not playerData then
        return
    end
    local bones = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LowerTorso", "RightUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"UpperTorso", "LeftUpperArm"},
        {"UpperTorso", "RightUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"RightUpperArm", "RightLowerArm"}
    }

    if not playerData.skeletonLines then
        playerData.skeletonLines = {}
    end

    for i, bone in ipairs(bones) do
        local part1 = parts[bone[1]]
        local part2 = parts[bone[2]]
        if part1 and part2 then
            local line = getOrCreateDrawing(player, "Line", "skeleton_" .. i, {
                Thickness = SKELETON_THICKNESS,
                Color = color,
                Visible = false
            })
            if line then
                local pos1, pos2 = Camera:WorldToViewportPoint(part1.Position), Camera:WorldToViewportPoint(part2.Position)
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = SKELETON_ENABLED and ESP_ENABLED
                playerData.skeletonLines[i] = line
            end
        end
    end
end

-- Helper function to update corner box
local function updateCornerBox(player, headPos, torsoPos, color)
    local playerData = espData[player]
    if not playerData then
        return
    end
    local headScreenPos, headOnScreen = Camera:WorldToViewportPoint(headPos)
    local torsoScreenPos, torsoOnScreen = Camera:WorldToViewportPoint(torsoPos)
    
    if not playerData.cornerLines then
        playerData.cornerLines = {}
    end

    if headOnScreen and torsoOnScreen then
        local minX = math.min(headScreenPos.X, torsoScreenPos.X)
        local maxX = math.max(headScreenPos.X, torsoScreenPos.X)
        local minY = math.min(headScreenPos.Y, torsoScreenPos.Y)
        local maxY = math.max(headScreenPos.Y, torsoScreenPos.Y)
        
        local cornerLines = {
            {{minX, minY, minX + CORNER_SIZE, minY}, {minX, minY, minX, minY + CORNER_SIZE}},
            {{maxX - CORNER_SIZE, minY, maxX, minY}, {maxX, minY, maxX, minY + CORNER_SIZE}},
            {{minX, maxY - CORNER_SIZE, minX, maxY}, {minX, maxY, minX + CORNER_SIZE, maxY}},
            {{maxX - CORNER_SIZE, maxY, maxX, maxY}, {maxX, maxY - CORNER_SIZE, maxX, maxY}}
        }
        
        for i, lineData in ipairs(cornerLines) do
            for j, points in ipairs(lineData) do
                local key = "corner_" .. i .. "_" .. j
                local line = getOrCreateDrawing(player, "Line", key, {
                    From = Vector2.new(points[1], points[2]),
                    To = Vector2.new(points[3], points[4]),
                    Thickness = 2,
                    Color = color,
                    Visible = false
                })
                if line then
                    line.From = Vector2.new(points[1], points[2])
                    line.To = Vector2.new(points[3], points[4])
                    line.Visible = CORNER_BOX_ENABLED and ESP_ENABLED
                    playerData.cornerLines[key] = line
                end
            end
        end
    end
end

-- Helper function to update off-screen arrow
local function updateOffScreenArrow(player, position, color)
    local playerData = espData[player]
    if not playerData then
        return
    end
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local direction = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Unit
        local arrowPos = screenCenter + direction * (FOV_RADIUS - 20)
        local arrowEnd = arrowPos + direction * ARROW_SIZE
        
        local arrow = getOrCreateDrawing(player, "Line", "arrow", {
            From = arrowPos,
            To = arrowEnd,
            Thickness = 2,
            Color = color,
            Visible = true
        })
        if arrow then
            arrow.From = arrowPos
            arrow.To = arrowEnd
            arrow.Visible = ESP_ENABLED
        end
    elseif playerData.arrow then
        playerData.arrow.Visible = false
    end
end

-- Main ESP function
local function updateESP()
    -- Clean up invalid players
    for player, data in pairs(espData) do
        if not player.Parent or not player.Character then
            if data.arrow then
                data.arrow:Remove()
            end
            for _, line in pairs(data.skeletonLines or {}) do
                line:Remove()
            end
            for _, line in pairs(data.cornerLines or {}) do
                line:Remove()
            end
            espData[player] = nil
        end
    end

    local localCharacter = LocalPlayer.Character
    if not localCharacter then
        return
    end
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        return
    end
    local localPos = localRoot.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end

        if TEAM_CHECK and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            continue
        end

        local character = player.Character
        if not character then
            continue
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if not (humanoid and humanoid.Health > 0 and rootPart and head and torso) then
            continue
        end

        local distance = (rootPart.Position - localPos).Magnitude
        if distance > MAX_DISTANCE then
            if espData[player] then
                if espData[player].arrow then
                    espData[player].arrow.Visible = false
                end
                for _, line in pairs(espData[player].skeletonLines or {}) do
                    line.Visible = false
                end
                for _, line in pairs(espData[player].cornerLines or {}) do
                    line.Visible = false
                end
            end
            continue
        end

        if not espData[player] then
            espData[player] = {
                arrow = nil,
                skeletonLines = {},
                cornerLines = {},
                rootPart = rootPart,
                parts = cacheCharacterParts(character),
                lastPosition = rootPart.Position,
                lastUpdate = 0
            }
        end

        local playerData = espData[player]
        local currentTime = tick()
        if currentTime - playerData.lastUpdate < UPDATE_INTERVAL then
            continue
        end

        local currentPos = rootPart.Position
        if (currentPos - playerData.lastPosition).Magnitude < POSITION_CHANGE_THRESHOLD then
            continue
        end
        playerData.lastPosition = currentPos
        playerData.lastUpdate = currentTime

        local inFOV, screenPos, onScreen = isInFOV(rootPart.Position)
        local color = inFOV and Color3.fromRGB(0, 255, 0) or ESP_COLOR
        updateOffScreenArrow(player, rootPart.Position, color)
        if onScreen then
            if SKELETON_ENABLED then
                updateSkeleton(player, character, playerData.parts, color)
            end
            if CORNER_BOX_ENABLED then
                updateCornerBox(player, head.Position, torso.Position, color)
            end
        end
    end
end

-- GUI Creation
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MinimalESP"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not ScreenGui.Parent then
        warn("PlayerGui not found!")
        return nil
    end
    print("ScreenGui created successfully")

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 600, 0, 400)
    Frame.Position = UDim2.new(0.5, -300, 0.5, -200)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    Frame.ClipsDescendants = true
    print("Main Frame created")

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.2, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "S"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    TitleLabel.TextSize = 24
    TitleLabel.Font = Enum.Font.SourceSansPro
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar
    print("Title Bar created")

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 14
    CloseButton.Font = Enum.Font.SourceSansPro
    CloseButton.Parent = TitleBar
    print("Close Button created")

    -- Dragging Logic
    local dragging = false
    local dragStart, startPos
    local dragConnection
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            dragConnection = UserInputService.InputChanged:Connect(function(dragInput)
                if dragging and dragInput.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = dragInput.Position - dragStart
                    Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if dragConnection then
                dragConnection:Disconnect()
                dragConnection = nil
            end
        end
    end)
    print("Dragging logic set up")

    -- Tab Bar (Left Side)
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 150, 1, -40)
    TabBar.Position = UDim2.new(0, 0, 0, 40)
    TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Frame

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Vertical
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabBar
    print("Tab Bar created")

    -- Tab Content Container
    local TabContent = Instance.new("Frame")
    TabContent.Size = UDim2.new(1, -150, 1, -40)
    TabContent.Position = UDim2.new(0, 150, 0, 40)
    TabContent.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TabContent.BorderSizePixel = 0
    TabContent.Parent = Frame
    print("Tab Content container created")

    -- Tab Management
    local tabs = {}
    local currentTab = nil

    local function createTab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 40)
        TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabButton.TextSize = 16
        TabButton.Font = Enum.Font.SourceSansPro
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Parent = TabBar

        local TabFrame = Instance.new("Frame")
        TabFrame.Size = UDim2.new(1, 0, 1, 0)
        TabFrame.BackgroundTransparency = 1
        TabFrame.Parent = TabContent
        TabFrame.Visible = false

        local TabContentLayout = Instance.new("UIListLayout")
        TabContentLayout.Padding = UDim.new(0, 10)
        TabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabContentLayout.Parent = TabFrame

        local tab = {button = TabButton, frame = TabFrame}
        tabs[name] = tab

        TabButton.MouseButton1Click:Connect(function()
            if currentTab ~= tab then
                if currentTab then
                    currentTab.button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    currentTab.button.TextColor3 = Color3.fromRGB(150, 150, 150)
                    currentTab.frame.Visible = false
                end
                tab.button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                tab.button.TextColor3 = Color3.fromRGB(255, 255, 255)
                tab.frame.Visible = true
                currentTab = tab
                print("Switched to tab: " .. name)
            end
        end)

        return TabFrame
    end

    -- Helper function to create a toggle button
    local function createToggle(parent, labelText, initialState, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.Parent = parent

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = labelText
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 16
        Label.Font = Enum.Font.SourceSansPro
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = ToggleFrame

        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0, 20, 0, 20)
        ToggleButton.Position = UDim2.new(1, -30, 0.5, -10)
        ToggleButton.BackgroundColor3 = initialState and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 0)
        ToggleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.BorderSizePixel = 2
        ToggleButton.Text = ""
        ToggleButton.Parent = ToggleFrame

        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(1, 0)
        ToggleCorner.Parent = ToggleButton

        ToggleButton.MouseButton1Click:Connect(function()
            initialState = not initialState
            ToggleButton.BackgroundColor3 = initialState and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 0)
            callback(initialState)
            print(labelText .. " toggled to: " .. tostring(initialState))
        end)

        return ToggleButton
    end

    -- Helper function to create a slider
    local function createSlider(parent, labelText, minValue, maxValue, initialValue, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(1, 0, 0, 40)
        SliderFrame.BackgroundTransparency = 1
        SliderFrame.Parent = parent

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.7, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = labelText .. ": " .. initialValue
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 16
        Label.Font = Enum.Font.SourceSansPro
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = SliderFrame

        local Slider = Instance.new("TextButton")
        Slider.Size = UDim2.new(0.5, 0, 0, 10)
        Slider.Position = UDim2.new(0.5, 0, 0, 25)
        Slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Slider.Text = ""
        Slider.Parent = SliderFrame

        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((initialValue - minValue) / (maxValue - minValue), 0, 1, 0)
        SliderFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        SliderFill.BorderSizePixel = 0
        SliderFill.Parent = Slider

        local draggingSlider = false
        local sliderConnection
        Slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
                sliderConnection = UserInputService.InputChanged:Connect(function(dragInput)
                    if draggingSlider and dragInput.UserInputType == Enum.UserInputType.MouseMovement then
                        local mouseX = dragInput.Position.X
                        local sliderX = Slider.AbsolutePosition.X
                        local sliderWidth = Slider.AbsoluteSize.X
                        if sliderWidth > 0 then
                            local t = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
                            local value = math.floor(minValue + (t * (maxValue - minValue)))
                            SliderFill.Size = UDim2.new(t, 0, 1, 0)
                            Label.Text = labelText .. ": " .. value
                            callback(value)
                            print(labelText .. " set to: " .. value)
                        end
                    end
                end)
            end
        end)
        Slider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = false
                if sliderConnection then
                    sliderConnection:Disconnect()
                    sliderConnection = nil
                end
            end
        end)

        return SliderFrame
    end

    -- Combat Tab
    local CombatTab = createTab("Combat")

    createToggle(CombatTab, "Enable ESP", ESP_ENABLED, function(state)
        ESP_ENABLED = state
    end)

    createToggle(CombatTab, "Team Check", TEAM_CHECK, function(state)
        TEAM_CHECK = state
    end)

    createSlider(CombatTab, "Max Distance", 100, 1000, MAX_DISTANCE, function(value)
        MAX_DISTANCE = value
    end)
    print("Combat Tab created")

    -- Visuals Tab
    local VisualsTab = createTab("Visuals")

    createToggle(VisualsTab, "Skeleton", SKELETON_ENABLED, function(state)
        SKELETON_ENABLED = state
    end)

    createToggle(VisualsTab, "Corner Box", CORNER_BOX_ENABLED, function(state)
        CORNER_BOX_ENABLED = state
    end)

    createSlider(VisualsTab, "FOV Radius", 100, 1000, FOV_RADIUS, function(value)
        FOV_RADIUS = value
    end)
    print("Visuals Tab created")

    -- Misc Tab
    local MiscTab = createTab("Misc")

    createSlider(MiscTab, "Update Interval", 1, 10, UPDATE_INTERVAL * 10, function(value)
        UPDATE_INTERVAL = value / 10
    end)
    print("Misc Tab created")

    -- Set default tab
    tabs["Combat"].button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    tabs["Combat"].button.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabs["Combat"].frame.Visible = true
    currentTab = tabs["Combat"]
    print("Default tab set to Combat")

    -- Close Logic
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        print("GUI closed")
    end)

    -- Keybind to Toggle GUI Visibility
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.E then
            ScreenGui.Enabled = not ScreenGui.Enabled
            print("GUI visibility toggled to: " .. tostring(ScreenGui.Enabled))
        end
    end)

    -- Cleanup
    ScreenGui.Destroying:Connect(function()
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        for _, data in pairs(espData) do
            if data.arrow then
                data.arrow:Remove()
            end
            for _, line in pairs(data.skeletonLines or {}) do
                line:Remove()
            end
            for _, line in pairs(data.cornerLines or {}) do
                line:Remove()
            end
        end
        espData = {}
        print("GUI destroyed, cleaned up ESP data")
    end)

    return ScreenGui
end

-- Render loop
local lastUpdate = 0
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then
        return
    end
    local currentTime = tick()
    if currentTime - lastUpdate >= UPDATE_INTERVAL then
        lastUpdate = currentTime
        local success, err = pcall(updateESP)
        if not success then
            warn("Error in updateESP: " .. tostring(err))
        end
    end
end)
print("Render loop started")

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(player)
    if espData[player] then
        if espData[player].arrow then
            espData[player].arrow:Remove()
        end
        for _, line in pairs(espData[player].skeletonLines or {}) do
            line:Remove()
        end
        for _, line in pairs(espData[player].cornerLines or {}) do
            line:Remove()
        end
        espData[player] = nil
    end
    if player == LocalPlayer then
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        for _, data in pairs(espData) do
            if data.arrow then
                data.arrow:Remove()
            end
            for _, line in pairs(data.skeletonLines or {}) do
                line:Remove()
            end
            for _, line in pairs(data.cornerLines or {}) do
                line:Remove()
            end
        end
        espData = {}
        print("Local player removed, cleaned up all ESP data")
    end
end)

-- Initialize GUI
local screenGui
local success, err = pcall(function()
    screenGui = createGUI()
end)
if not success then
    warn("Failed to create GUI: " .. tostring(err))
elseif not screenGui then
    warn("GUI creation failed, check logs for details.")
else
    print("GUI successfully initialized")
end
