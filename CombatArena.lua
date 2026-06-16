-- DDS Combat Arena ULTIMATE
-- Аимбот 10ms | Автострельба 50/сек | Стены | Spin Bot
-- Всё включено. Без меню.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Workspace = workspace

-- Настройки (меняй здесь)
local Settings = {
    Smooth = 0.01,        -- Наводка 10 мс
    Target = "Head",      -- Head / UpperTorso / HumanoidRootPart
    WallCheck = true,     -- Проверка стен
    Spin = true,          -- Крутилка
    SpinSpeed = 600,      -- Скорость крутилки
    ShootRate = 0.02,     -- 50 выстрелов/сек
    MaxDist = 300         -- Макс дистанция
}

-- Поиск RemoteEvent
local Remote = nil
local function FindRemote()
    local char = LocalPlayer.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("attack")) then
                return v
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            for _, v in pairs(tool:GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    return v
                end
            end
        end
    end
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("attack")) then
            return v
        end
    end
    return nil
end
Remote = FindRemote()

-- Функция выстрела
local function Shoot(targetPos)
    if not Remote then
        mouse1click()
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local origin = head.Position
    local target = targetPos or (Camera.CFrame.Position + Camera.CFrame.LookVector * 500)
    pcall(function()
        Remote:FireServer(target, (target - origin).Unit)
    end)
end

-- Поиск цели
local function GetTarget()
    local best = nil
    local bestDist = math.huge
    local char = LocalPlayer.Character
    if not char then return nil end
    local headPos = char:FindFirstChild("Head")
    if not headPos then return nil end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local humanoid = targetChar:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local targetPart = targetChar:FindFirstChild(Settings.Target) or targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        if Settings.WallCheck then
                            local ray = Ray.new(headPos.Position, (targetPart.Position - headPos.Position).Unit * 1000)
                            local hit = Workspace:FindPartOnRay(ray, char)
                            if hit and not hit:IsDescendantOf(targetChar) then
                                return nil
                            end
                        end
                        local dist = (targetPart.Position - headPos.Position).Magnitude
                        if dist < bestDist and dist < Settings.MaxDist then
                            bestDist = dist
                            best = targetPart
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Переменные для таймеров
local spinAngle = 0
local shootTimer = 0
local searchTimer = 0

-- Главный цикл
RunService.RenderStepped:Connect(function()
    local dt = RunService.RenderStepped:Wait()
    
    -- Spin Bot (крутилка)
    if Settings.Spin then
        spinAngle = spinAngle + Settings.SpinSpeed * dt
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
                end)
            end
        end
    end
    
    -- Поиск цели (раз в 100 мс)
    searchTimer = searchTimer + dt
    local target = nil
    if searchTimer >= 0.1 then
        searchTimer = 0
        target = GetTarget()
    end
    
    if target then
        -- Наведение
        local screenPos = Camera:WorldToScreenPoint(target.Position)
        if screenPos then
            local currentMouse = Vector2.new(Mouse.X, Mouse.Y)
            local targetMouse = Vector2.new(screenPos.X, screenPos.Y)
            local delta = (targetMouse - currentMouse) * Settings.Smooth
            if delta.Magnitude > 0.2 then
                pcall(function()
                    mousemoverel(delta.X, delta.Y)
                end)
            end
            
            -- Автострельба
            shootTimer = shootTimer + dt
            if shootTimer >= Settings.ShootRate then
                shootTimer = 0
                pcall(function()
                    Shoot(target.Position)
                end)
            end
        end
    end
end)

print("DDS ULTIMATE LOADED: 10ms aim | 50/s shoot | Spin ON | Walls ON")
