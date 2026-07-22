--[[
    SIX SEVEN - COMPLETO (Com Seletor de Tempo 1-5s)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Settings = {
    AutoCapture = { 
        Enabled = false, 
        Delay = 5.0,
        TeleportDelay = 0.3,
        CountdownTime = 5
    },
    ESP = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        MaxDistance = 200
    },
    Speed = 16,
    Jump = 50
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local espActive = false
local autoCapture = false
local autoCaptureRunning = false
local capturedPets = {}
local espObjects = {}
local petPositions = {}
local countdownActive = false
local countdownLabel = nil

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function FindAllPets()
    local pets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj == Character then continue end
            if obj == Player.Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            
            local name = obj.Name:lower()
            if name:find("base") or name:find("floor") or name:find("wall") or name:find("ground") then
                continue
            end
            if name:find("npc") or name:find("humano") or name:find("personagem") then
                continue
            end
            if name:find("coruja") or name:find("owl") then
                continue
            end
            
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                
                if petPositions[obj] then
                    local oldPos = petPositions[obj]
                    local dist = (currentPos - oldPos).Magnitude
                    if dist > 0.1 then
                        table.insert(pets, obj)
                    end
                else
                    table.insert(pets, obj)
                end
                
                petPositions[obj] = currentPos
            end
        end
    end
    
    return pets
end

-- ========================================
-- FUNÇÕES DE VELOCIDADE E JUMP
-- ========================================
local function AtualizarVelocidade()
    if not Humanoid then return end
    local speed = 16 + (Settings.Speed / 100) * 84
    Humanoid.WalkSpeed = speed
end

local function AtualizarJump()
    if not Humanoid then return end
    local jump = 50 + (Settings.Jump / 100) * 50
    Humanoid.JumpPower = jump
end

-- ========================================
-- TELEPORTE SUAVE
-- ========================================
local function SmoothTeleport(targetPos)
    if not RootPart then return end
    
    local currentPos = RootPart.Position
    local dist = (currentPos - targetPos).Magnitude
    
    if dist > 5 then
        local steps = math.min(math.floor(dist / 3), 5)
        for i = 1, steps do
            local progress = i / steps
            local newPos = currentPos:Lerp(targetPos, progress)
            pcall(function()
                RootPart.CFrame = CFrame.new(newPos)
            end)
            task.wait(Settings.AutoCapture.TeleportDelay)
        end
    end
    
    pcall(function()
        RootPart.CFrame = CFrame.new(targetPos)
    end)
    task.wait(0.2)
end

-- ========================================
-- CLICAR NO PET
-- ========================================
local function ClickOnPet(pet)
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    local success = false
    pcall(function()
        local mouse = Player:GetMouse()
        if mouse then
            mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
            task.wait(0.1)
            mouse.Button1Click()
            success = true
        end
    end)
    
    return success
end

-- ========================================
-- CAPTURAR PET
-- ========================================
local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    print("🎯 Capturando: " .. pet.Name)
    
    local targetPos = hrp.Position + Vector3.new(0, 3, 0)
    SmoothTeleport(targetPos)
    
    local success = ClickOnPet(pet)
    task.wait(1.0)
    
    return success
end

-- ========================================
-- LEVAR PET À BASE
-- ========================================
local function BringPetToBase(pet)
    if not pet then return end
    
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("PlayerBase")
    if not base then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local basePos = base.Position + Vector3.new(0, 2, 0)
        SmoothTeleport(basePos)
        pcall(function()
            hrp.CFrame = CFrame.new(basePos)
        end)
        task.wait(0.3)
    end
    
    local releaseRemote = ReplicatedStorage:FindFirstChild("ReleasePet")
        or ReplicatedStorage:FindFirstChild("DropPet")
    
    if releaseRemote then
        pcall(function() 
            releaseRemote:FireServer(pet) 
            print("📦 Pet solto na base!")
        end)
        task.wait(0.3)
    end
end

-- ========================================
-- MOSTRAR CONTADOR NA TELA
-- ========================================
local function ShowCountdown(seconds)
    if not countdownLabel then return end
    
    countdownActive = true
    countdownLabel.Visible = true
    
    for i = seconds, 1, -1 do
        if not autoCapture or not autoCaptureRunning then
            countdownActive = false
            countdownLabel.Visible = false
            return
        end
        countdownLabel.Text = "⏳ " .. i .. "s"
        task.wait(1)
    end
    
    countdownActive = false
    countdownLabel.Visible = false
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        local pets = FindAllPets()
        local target = nil
        local minDist = math.huge
        
        if #pets == 0 then
            task.wait(0.5)
        else
            for _, pet in pairs(pets) do
                if not capturedPets[pet] then
                    local hrp = pet:FindFirstChild("HumanoidRootPart")
                    if hrp and RootPart then
                        local dist = (RootPart.Position - hrp.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            target = pet
                        end
                    end
                end
            end
            
            if target then
                local success = CapturePet(target)
                if success then
                    capturedPets[target] = true
                    BringPetToBase(target)
                    print("✅ " .. target.Name .. " capturado!")
                    
                    if autoCapture and autoCaptureRunning then
                        ShowCountdown(Settings.AutoCapture.CountdownTime)
                    end
                end
                task.wait(Settings.AutoCapture.Delay)
            else
                task.wait(0.5)
            end
        end
        task.wait(0.1)
    end
end

-- ========================================
-- SISTEMA ESP
-- ========================================
local function CreateESP(pet)
    if not pet or not pet:IsA("Model") then return end
    if espObjects[pet] then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = pet
    highlight.FillColor = Settings.ESP.Color
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = hrp
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.Adornee = hrp
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.Text = "🐾 " .. pet.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Parent = billboard
    distLabel.Size = UDim2.new(1, 0, 0, 20)
    distLabel.Position = UDim2.new(0, 0, 1, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.Gotham
    
    espObjects[pet] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        DistLabel = distLabel
    }
end

local function RemoveESP(pet)
    if espObjects[pet] then
        if espObjects[pet].Highlight then espObjects[pet].Highlight:Destroy() end
        if espObjects[pet].Billboard then espObjects[pet].Billboard:Destroy() end
        espObjects[pet] = nil
    end
end

local function UpdateESP()
    if not espActive then
        for pet, _ in pairs(espObjects) do
            RemoveESP(pet)
        end
        espObjects = {}
        return
    end
    
    local pets = FindAllPets()
    
    for _, pet in pairs(pets) do
        if pet and pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            local hrp = pet.HumanoidRootPart
            if RootPart then
                local dist = (RootPart.Position - hrp.Position).Magnitude
                if dist <= Settings.ESP.MaxDistance then
                    CreateESP(pet)
                    if espObjects[pet] and espObjects[pet].DistLabel then
                        espObjects[pet].DistLabel.Text = math.floor(dist) .. "m"
                    end
                else
                    RemoveESP(pet)
                end
            end
        end
    end
    
    local currentPets = {}
    for _, pet in pairs(pets) do
        currentPets[pet] = true
    end
    for pet, _ in pairs(espObjects) do
        if not currentPets[pet] or not pet:IsA("Model") then
            RemoveESP(pet)
        end
    end
end

-- ========================================
-- MONITORAMENTO
-- ========================================
local function StartMonitoring()
    task.spawn(function()
        while true do
            task.wait(0.5)
            if espActive then
                UpdateESP()
            end
        end
    end)
    
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                local name = obj.Name:lower()
                if not name:find("npc") and not name:find("humano") and not name:find("personagem") then
                    if espActive then
                        task.wait(0.1)
                        UpdateESP()
                    end
                end
            end
        end
    end)
end

-- ========================================
-- CRIAR MENU SIMPLIFICADO
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 220, 0, 320)
    mainFrame.Position = UDim2.new(0.02, 0, 0.5, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = mainFrame
    stroke.Color = Color3.fromRGB(138, 43, 226)
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    -- Título
    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, -50, 0, 30)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✧ SIX SEVEN"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -26, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = closeBtn
    closeCorner.CornerRadius = UDim.new(0, 5)

    -- Separador
    local sep = Instance.new("Frame")
    sep.Parent = mainFrame
    sep.Size = UDim2.new(0.9, 0, 0, 1)
    sep.Position = UDim2.new(0.05, 0, 0.12, 0)
    sep.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    sep.BackgroundTransparency = 0.5

    -- Container
    local container = Instance.new("Frame")
    container.Parent = mainFrame
    container.Size = UDim2.new(0.9, 0, 0.7, 0)
    container.Position = UDim2.new(0.05, 0, 0.16, 0)
    container.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Velocidade
    local speedFrame = Instance.new("Frame")
    speedFrame.Parent = container
    speedFrame.Size = UDim2.new(1, 0, 0, 32)
    speedFrame.BackgroundTransparency = 1
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Parent = speedFrame
    speedLabel.Size = UDim2.new(0.4, 0, 1, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "🏃 Velocidade"
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    speedLabel.TextSize = 12
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local speedBox = Instance.new("TextBox")
    speedBox.Parent = speedFrame
    speedBox.Size = UDim2.new(0, 40, 0, 24)
    speedBox.Position = UDim2.new(0.7, 0, 0.5, -12)
    speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    speedBox.Text = tostring(Settings.Speed)
    speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedBox.TextSize = 13
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextXAlignment = Enum.TextXAlignment.Center
    speedBox.BorderSizePixel = 0
    
    speedBox.FocusLost:Connect(function()
        local num = tonumber(speedBox.Text)
        if num then
            Settings.Speed = math.clamp(num, 0, 100)
            speedBox.Text = tostring(Settings.Speed)
            AtualizarVelocidade()
        else
            speedBox.Text = tostring(Settings.Speed)
        end
    end)

    -- Pulo
    local jumpFrame = Instance.new("Frame")
    jumpFrame.Parent = container
    jumpFrame.Size = UDim2.new(1, 0, 0, 32)
    jumpFrame.BackgroundTransparency = 1
    
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Parent = jumpFrame
    jumpLabel.Size = UDim2.new(0.4, 0, 1, 0)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.Text = "🦘 Pulo"
    jumpLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    jumpLabel.TextSize = 12
    jumpLabel.Font = Enum.Font.GothamBold
    jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local jumpBox = Instance.new("TextBox")
    jumpBox.Parent = jumpFrame
    jumpBox.Size = UDim2.new(0, 40, 0, 24)
    jumpBox.Position = UDim2.new(0.7, 0, 0.5, -12)
    jumpBox.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    jumpBox.Text = tostring(Settings.Jump)
    jumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpBox.TextSize = 13
    jumpBox.Font = Enum.Font.GothamBold
    jumpBox.TextXAlignment = Enum.TextXAlignment.Center
    jumpBox.BorderSizePixel = 0
    
    jumpBox.FocusLost:Connect(function()
        local num = tonumber(jumpBox.Text)
        if num then
            Settings.Jump = math.clamp(num, 0, 100)
            jumpBox.Text = tostring(Settings.Jump)
            AtualizarJump()
        else
            jumpBox.Text = tostring(Settings.Jump)
        end
    end)

    -- Botão ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = container
    espBtn.Size = UDim2.new(1, 0, 0, 28)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    espBtn.Text = "🔴 ESP: OFF"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 13
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 5)

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP: ON" or "🔴 ESP: OFF"
        espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 120)
        if espActive then
            UpdateESP()
        else
            for pet, _ in pairs(espObjects) do
                RemoveESP(pet)
            end
            espObjects = {}
        end
    end)

    -- Botão AUTO
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = container
    autoBtn.Size = UDim2.new(1, 0, 0, 28)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    autoBtn.Text = "🔴 AUTO: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 13
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 5)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 AUTO: ON" or "🔴 AUTO: OFF"
        autoBtn.BackgroundColor3 = autoCapture and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 120)
        if autoCapture then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoCaptureRunning = false
            countdownActive = false
            if countdownLabel then
                countdownLabel.Visible = false
            end
        end
    end)

    -- Seletor de Tempo
    local timeFrame = Instance.new("Frame")
    timeFrame.Parent = container
    timeFrame.Size = UDim2.new(1, 0, 0, 32)
    timeFrame.BackgroundTransparency = 1
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Parent = timeFrame
    timeLabel.Size = UDim2.new(0.5, 0, 1, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "⏱️ Tempo entre pets"
    timeLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    timeLabel.TextSize = 12
    timeLabel.Font = Enum.Font.GothamBold
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local timeBox = Instance.new("TextBox")
    timeBox.Parent = timeFrame
    timeBox.Size = UDim2.new(0, 40, 0, 24)
    timeBox.Position = UDim2.new(0.7, 0, 0.5, -12)
    timeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    timeBox.Text = tostring(Settings.AutoCapture.CountdownTime) .. "s"
    timeBox.TextColor3 = Color3.fromRGB(255, 200, 100)
    timeBox.TextSize = 13
    timeBox.Font = Enum.Font.GothamBold
    timeBox.TextXAlignment = Enum.TextXAlignment.Center
    timeBox.BorderSizePixel = 0
    
    timeBox.FocusLost:Connect(function()
        local num = tonumber(string.match(timeBox.Text, "([%d.]+)"))
        if num then
            Settings.AutoCapture.CountdownTime = math.clamp(num, 1, 5)
            timeBox.Text = tostring(Settings.AutoCapture.CountdownTime) .. "s"
            print("⏱️ Tempo ajustado para: " .. Settings.AutoCapture.CountdownTime .. "s")
        else
            timeBox.Text = tostring(Settings.AutoCapture.CountdownTime) .. "s"
        end
    end)

    -- Contador na tela
    local countdownFrame = Instance.new("Frame")
    countdownFrame.Parent = screenGui
    countdownFrame.Size = UDim2.new(0, 150, 0, 80)
    countdownFrame.Position = UDim2.new(0.5, -75, 0.5, -40)
    countdownFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    countdownFrame.BackgroundTransparency = 0.7
    countdownFrame.BorderSizePixel = 0
    countdownFrame.Visible = false
    countdownFrame.ZIndex = 999

    local countdownCorner = Instance.new("UICorner")
    countdownCorner.Parent = countdownFrame
    countdownCorner.CornerRadius = UDim.new(0, 15)

    local countdownStroke = Instance.new("UIStroke")
    countdownStroke.Parent = countdownFrame
    countdownStroke.Color = Color3.fromRGB(255, 200, 50)
    countdownStroke.Thickness = 2

    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Parent = countdownFrame
    countdownLabel.Size = UDim2.new(1, 0, 1, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "⏳ 5s"
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownLabel.TextSize = 40
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.TextScaled = true

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = mainFrame
    statusLabel.Size = UDim2.new(0.9, 0, 0, 18)
    statusLabel.Position = UDim2.new(0.05, 0, 0.9, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 38, 0, 38)
    floatBtn.Position = UDim2.new(0.02, 0, 0.5, 20)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✧"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 20
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.BorderSizePixel = 0
    floatBtn.Visible = false

    local floatCorner = Instance.new("UICorner")
    floatCorner.Parent = floatBtn
    floatCorner.CornerRadius = UDim.new(1, 0)

    local function OpenMenu()
        mainFrame.Visible = true
        floatBtn.Visible = false
    end

    local function CloseMenu()
        mainFrame.Visible = false
        floatBtn.Visible = true
    end

    closeBtn.MouseButton1Click:Connect(CloseMenu)
    floatBtn.MouseButton1Click:Connect(OpenMenu)

    -- Atualiza status
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindAllPets()
            local counterText = ""
            if autoCapture then
                counterText = " | ⏱️ " .. Settings.AutoCapture.CountdownTime .. "s"
            end
            statusLabel.Text = "📊 Pets: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF") .. counterText
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN")
print("========================================")
print("  📌 Seletor de tempo: 1s a 5s")
print("  📌 Digite o valor e aperte Enter")
print("========================================")

pcall(CreateMenu)
StartMonitoring()

task.wait(0.5)
AtualizarVelocidade()
AtualizarJump()

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    task.wait(1)
    AtualizarVelocidade()
    AtualizarJump()
    if espActive then
        UpdateESP()
    end
end)

print("========================================")
print("  ✅ PRONTO!")
print("========================================")
