local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Variablen für Funktionen
local spinbotEnabled = false
local silentAimEnabled = false
local ragebotEnabled = false
local targetPlayer = nil

-- 📢 Funktionen

-- 🎯 Spinbot Funktion
local function startSpinbot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        while spinbotEnabled do
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(10), 0)
            wait(0.05)
        end
    end
end

-- 🎯 Silent Aim (Aimbot ohne den Cursor zu bewegen)
local function startSilentAim()
    while silentAimEnabled do
        targetPlayer = getClosestTarget()
        if targetPlayer then
            local targetHead = targetPlayer.Character:FindFirstChild("Head")
            if targetHead then
                Mouse.MoveTo(targetHead.Position)
            end
        end
        wait(0.1)
    end
end

-- 🎯 Ragebot (Aggressive Aimbot, klickt automatisch)
local function startRagebot()
    while ragebotEnabled do
        targetPlayer = getClosestTarget()
        if targetPlayer then
            local targetHead = targetPlayer.Character:FindFirstChild("Head")
            if targetHead then
                -- Angreifen
                Mouse1Click()
            end
        end
        wait(0.1)
    end
end

-- Funktion zum Finden des nächsten Ziels (Enemy)
local function getClosestTarget()
    local closest = nil
    local shortestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local part = player.Character:FindFirstChild("Head")
            if part then
                local screenPos = Camera:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

-- Toggle Funktionen für Buttons
local function toggleSpinbot()
    spinbotEnabled = not spinbotEnabled
    if spinbotEnabled then
        startSpinbot()
    end
end

local function toggleSilentAim()
    silentAimEnabled = not silentAimEnabled
    if silentAimEnabled then
        startSilentAim()
    end
end

local function toggleRagebot()
    ragebotEnabled = not ragebotEnabled
    if ragebotEnabled then
        startRagebot()
    end
end

-- 🧳 Key Bindings (z.B. "H" für Spinbot, "J" für Silent Aim)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.H then
        toggleSpinbot()
    elseif input.KeyCode == Enum.KeyCode.J then
        toggleSilentAim()
    elseif input.KeyCode == Enum.KeyCode.K then
        toggleRagebot()
    end
end)

-- Feature: Anti Aim / Fake Aim Funktion (Optional hinzufügen)
local function antiAim()
    -- Anti Aim Logik kann hier implementiert werden
end

-- Hauptloop: Alle Features laufen lassen
RunService.RenderStepped:Connect(function()
    if spinbotEnabled then
        startSpinbot()
    end
    if silentAimEnabled then
        startSilentAim()
    end
    if ragebotEnabled then
        startRagebot()
    end
end)

