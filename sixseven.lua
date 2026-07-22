--[[
    SIX SEVEN - COMPLETO (Versão Compacta)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - COMPACTO...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
        TeleportDelay = 0.3
    },
    ESP = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        MaxDistance = 200
    },
    Speed = {
        Value = 16,
        Max = 100
    },
    Jump = {
        Value = 50,
        Max = 100
    }
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
local petList = {}
local menuAberto = true

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
    local speed = 16 + (Settings.Speed.Value / 100) * 84
    Humanoid.WalkSpeed = speed
end

local function AtualizarJump()
    if not Humanoid then return end
    local jump = 50 + (Settings.Jump.Value / 100) * 50
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
    
    pcall(function()
        local mouse = Player:GetMouse()
        if mouse then
            mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
            task.wait(0.1)
            mouse.Button1Click()
            return true
        end
    end)
    
    return false
end

-- ========================================
-- CAPTURAR PET
-- ========================================
local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
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
        end)
        task.wait(0.3)
    end
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        task.spawn(function()
            local pets = FindAllPets()
            local target = nil
            local minDist = math.huge
            
            if #pets == 0 then
                task.wait(0.5)
                return
            end
            
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
                end
                task.wait(Settings.AutoCapture.Delay)
            else
                task.wait(0.5)
            end
        end)
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
    petList = pets
    
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
-- CRIAR SLIDER COMPACTO
-- ========================================
local function CreateSlider(parent, labelText, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.5, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(0.2, 0, 0, 18)
    valueLabel.Position = UDim2.new(0.8, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = frame
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0, 22)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
    sliderBg.BorderSizePixel = 0
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.Parent = sliderBg
    sliderCorner.CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Parent = sliderBg
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    fill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.Parent = fill
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Parent = sliderBg
    sliderBtn.Size = UDim2.new(0, 14, 0, 14)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
    sliderBtn.Text = ""
    sliderBtn.BorderSizePixel = 0
    sliderBtn.AutoButtonColor = false
    
    local sliderCorner2 = Instance.new("UICorner")
    sliderCorner2.Parent = sliderBtn
    sliderCorner2.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function UpdateSlider(input)
        local pos = input.Position.X - sliderBg.AbsolutePosition.X
        local width = sliderBg.AbsoluteSize.X
        if width <= 0 then return end
        local percent = math.clamp(pos / width, 0, 1)
        local value = math.round(min + percent * (max - min))
        
        fill.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -7, 0.5, -7)
        valueLabel.Text = tostring(value)
        
        callback(value)
    end
    
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateSlider(input)
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input)
        end
    end)
    
    return frame
end

-- ========================================
-- MENU COMPACTO
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    -- Frame principal (menor e com transparência)
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 230, 0, 280)
    mainFrame.Position = UDim2.new(0.02, 0, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = true
    mainFrame.ClipsDescendants = true

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
    title.Size = UDim2.new(1, -60, 0, 32)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✧ SIX SEVEN"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Botão Minimizar
    local minBtn = Instance.new("TextButton")
    minBtn.Parent = mainFrame
    minBtn.Size = UDim2.new(0, 24, 0, 24)
    minBtn.Position = UDim2.new(1, -54, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    minBtn.Text = "─"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 16
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.AutoButtonColor = false
    
    local minCorner = Instance.new("UICorner")
    minCorner.Parent = minBtn
    minCorner.CornerRadius = UDim.new(0, 5)

    -- Botão Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    
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
    sep.BorderSizePixel = 0

    -- Container dos conteúdos
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Parent = mainFrame
    contentContainer.Size = UDim2.new(1, -10, 1, -50)
    contentContainer.Position = UDim2.new(0, 5, 0, 38)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 3
    contentContainer.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y

    local content = Instance.new("Frame")
    content.Parent = contentContainer
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = content
    contentLayout.Padding = UDim.new(0, 5)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========================================
    -- SLIDERS
    -- ========================================
    CreateSlider(content, "🏃 Velocidade", 0, 100, 16, function(value)
        Settings.Speed.Value = value
        AtualizarVelocidade()
    end)

    CreateSlider(content, "🦘 Pulo", 0, 100, 50, function(value)
        Settings.Jump.Value = value
        AtualizarJump()
    end)

    -- ========================================
    -- BOTÕES (linha dupla)
    -- ========================================
    -- ESP
    local espFrame = Instance.new("Frame")
    espFrame.Parent = content
    espFrame.Size = UDim2.new(1, 0, 0, 30)
    espFrame.BackgroundTransparency = 1

    local espLabel = Instance.new("TextLabel")
    espLabel.Parent = espFrame
    espLabel.Size = UDim2.new(0.5, 0, 1, 0)
    espLabel.BackgroundTransparency = 1
    espLabel.Text = "🔍 ESP"
    espLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    espLabel.TextSize = 13
    espLabel.Font = Enum.Font.GothamBold
    espLabel.TextXAlignment = Enum.TextXAlignment.Left

    local espBtn = Instance.new("TextButton")
    espBtn.Parent = espFrame
    espBtn.Size = UDim2.new(0, 70, 0, 26)
    espBtn.Position = UDim2.new(0.7, 0, 0.5, -13)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    espBtn.Text = "🔴 OFF"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 12
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0
    espBtn.AutoButtonColor = false
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 6)

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ON" or "🔴 OFF"
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

    -- AUTO
    local autoFrame = Instance.new("Frame")
    autoFrame.Parent = content
    autoFrame.Size = UDim2.new(1, 0, 0, 30)
    autoFrame.BackgroundTransparency = 1

    local autoLabel = Instance.new("TextLabel")
    autoLabel.Parent = autoFrame
    autoLabel.Size = UDim2.new(0.5, 0, 1, 0)
    autoLabel.BackgroundTransparency = 1
    autoLabel.Text = "🎯 Auto Capture"
    autoLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    autoLabel.TextSize = 13
    autoLabel.Font = Enum.Font.GothamBold
    autoLabel.TextXAlignment = Enum.TextXAlignment.Left

    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = autoFrame
    autoBtn.Size = UDim2.new(0, 70, 0, 26)
    autoBtn.Position = UDim2.new(0.7, 0, 0.5, -13)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    autoBtn.Text = "🔴 OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 12
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    autoBtn.AutoButtonColor = false
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 6)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 ON" or "🔴 OFF"
        autoBtn.BackgroundColor3 = autoCapture and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 120)
        if autoCapture then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoCaptureRunning = false
        end
    end)

    -- ========================================
    -- STATUS
    -- ========================================
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
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
    floatBtn.AutoButtonColor = false

    local floatCorner = Instance.new("UICorner")
    floatCorner.Parent = floatBtn
    floatCorner.CornerRadius = UDim.new(1, 0)

    local function OpenMenu()
        mainFrame.Visible = true
        floatBtn.Visible = false
        menuAberto = true
    end

    local function CloseMenu()
        mainFrame.Visible = false
        floatBtn.Visible = true
        menuAberto = false
    end

    minBtn.MouseButton1Click:Connect(CloseMenu)
    floatBtn.MouseButton1Click:Connect(OpenMenu)
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Atualiza status
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindAllPets()
            statusLabel.Text = "📊 Pets: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF")
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - COMPACTO")
print("========================================")
print("  📌 Menu menor e no canto")
print("  📌 Velocidade e Pulo")
print("  📌 ESP e Auto Capture")
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
