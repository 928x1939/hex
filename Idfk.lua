-- ⚙️ Essentials
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Mouse = game.Players.LocalPlayer:GetMouse()
local LocalPlayer = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Settings
local aimAssistEnabled = false
local aimLockEnabled = false
local thirdPersonEnabled = false
local autoWallEnabled = true
local ESPEnabled = true
local smoothness = 0.1
local aimRadius = 150 -- Radius für Aim Lock (beim Zielerkennung)
local fov = 80 -- FOV für Aim Assist

-- Drawing objects für ESP
local espBoxes = {}
local healthBars = {}
local nameTags = {}

-- Helper function für Third Person
local function setThirdPerson()
    if thirdPersonEnabled then
        Camera.CameraSubject = nil -- Kamera folgt dem Charakter nicht mehr
        Camera.FieldOfView = 90 -- Kamera FOV ändern
    else
        Camera.CameraSubject = LocalPlayer.Character.HumanoidRootPart
        Camera.FieldOfView = 70 -- Standard FOV
    end
end

-- Funktionen für ESP
local function createESP(player)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Color3.fromRGB(255, 255, 0)
    box.Visible = false
    table.insert(espBoxes, box)

    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 2
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false
    table.insert(healthBars, healthBar)

    local nameTag = Drawing.new("Text")
    nameTag.Size = 18
    nameTag.Center = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Outline = true
    nameTag.Visible = false
    table.insert(nameTags, nameTag)
end

-- Funktion für Aim Assist
local function aimAssist()
    local closestTarget = nil
    local closestDistance = aimRadius

    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= LocalPlayer and enemy.Character and enemy.Character:FindFirstChild("Head") then
            local pos, visible = Camera:WorldToViewportPoint(enemy.Character.Head.Position)
            local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

            if visible and distance < closestDistance then
                closestDistance = distance
                closestTarget = enemy
            end
        end
    end

    -- Smooth Aim lock
    if closestTarget then
        local targetHeadPos = Camera:WorldToScreenPoint(closestTarget.Character.Head.Position)
        local moveTo = Vector2.new(targetHeadPos.X, targetHeadPos.Y)

        -- Smooth Movement
        mousemoveabs(
            (moveTo.X - Mouse.X) * smoothness,
            (moveTo.Y - Mouse.Y) * smoothness
        )
    end
end

-- Auto Wall Funktion
local function autoWall(target)
    if not autoWallEnabled or not target.Character then return false end

    -- Überprüfe ob der Feind hinter einer Wand ist
    local headPosition = target.Character.Head.Position
    local startPos = Camera.CFrame.Position
    local direction = (headPosition - startPos).unit
    local raycastResult = workspace:Raycast(startPos, direction * 500)

    -- Sicherstellen, dass die Raycast-Prüfung korrekt funktioniert
    if raycastResult and raycastResult.Instance then
        -- Wenn es eine Wand ist, die das Ziel blockiert
        return raycastResult.Instance.Name == "Wall" or raycastResult.Instance.Name == "Part"
    end
    return false
end

-- Toggle für Third Person
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        thirdPersonEnabled = not thirdPersonEnabled
        setThirdPerson()
    end
end)

-- Toggle für Aim Lock
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.C then
        aimLockEnabled = not aimLockEnabled
    end
end)

-- Haupt-Loop für das Skript
RunService.RenderStepped:Connect(function()
    -- Aim Assist aktivieren
    if aimLockEnabled then
        aimAssist()
    end

    -- Auto Wall aktivieren
    if autoWallEnabled then
        for _, enemy in ipairs(Players:GetPlayers()) do
            if enemy ~= LocalPlayer and enemy.Character and autoWall(enemy) then
                -- Wenn der Feind hinter einer Wand ist, schießen (Simulation)
                -- Hier könnte die Schusslogik implementiert werden
            end
        end
    end

    -- ESP aktivieren
    if ESPEnabled then
        for i, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local pos, visible = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                if visible then
                    espBoxes[i].Visible = true
                    espBoxes[i].Size = Vector2.new(50, 100)
                    espBoxes[i].Position = Vector2.new(pos.X - 25, pos.Y - 50)

                    nameTags[i].Visible = true
                    nameTags[i].Text = player.Name
                    nameTags[i].Position = Vector2.new(pos.X, pos.Y - 60)

                    local health = player.Character.Humanoid.Health
                    healthBars[i].Visible = true
                    healthBars[i].From = Vector2.new(pos.X - 25, pos.Y + 50)
                    healthBars[i].To = Vector2.new(pos.X - 25, pos.Y + 50 + (health / 100) * 50)
                else
                    espBoxes[i].Visible = false
                    nameTags[i].Visible = false
                    healthBars[i].Visible = false
                end
            end
        end
    end
end)

