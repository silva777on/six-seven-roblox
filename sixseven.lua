--[[
    Six Seven - Auto Farm Completo (Laço + Captura Automática)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - AUTO FARM COMPLETO...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
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
        Delay = 1.5,          -- Tempo entre capturas (ajustável)
        TeleportDelay = 0.2    -- Velocidade do teleporte
    },
    ESP = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        MaxDistance = 200
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

-- ========================================
-- LISTA DE NPCS PARA IGNORAR
-- ========================================
local npcNames = {
    "npc", "humano", "personagem", "vendedor", "lojista", 
    "guarda", "civil", "aldeao", "comerciante", "treinador",
    "professor", "mestre", "ancião", "mercador", "coruja", "owl"
}

local function IsNPC(obj)
    if not obj then return false end
    local name = obj.Name:lower()
    for _, npc in pairs(npcNames) do
        if name:find(npc) then
            return true
        end
    end
    return false
end

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
            if IsNPC(obj) then continue end
            
            local name = obj.Name:lower()
            if name:find("base") or name:find("floor") or name:find("wall") or name:find("ground") then
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
-- FUNÇÃO PARA EQUIPAR O LAÇO (SLOT 1)
-- ========================================
local function EquipLasso()
    -- Tenta encontrar o laço no inventário
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("laço") or name:find("lasso") or name:find("corda") or name:find("capture") then
                    if Humanoid then
                        Humanoid:EquipTool(item)
                        print("🎯 Laço equipado!")
                        task.wait(0.2)
                        return true
                    end
                end
            end
        end
    end
    
    -- Se não achou no backpack, tenta a tecla 1
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        print("🎯 Tecla 1 pressionada!")
        return true
    end)
    
    return false
end

-- ========================================
-- FUNÇÃO PARA LANÇAR O LAÇO NO PET
-- ========================================
local function ThrowLasso(pet)
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- 1. Equipa o laço
    EquipLasso()
    task.wait(0.2)
    
    -- 2. Ativa o laço (prepara para lançar)
    pcall(function()
        -- Tenta ativar o laço via tool
        local tool = Humanoid and Humanoid:FindFirstChild("ActiveTool")
        if tool then
            tool:Activate()
            print("🎯 Laço ativado!")
        end
    end)
    task.wait(0.1)
    
    -- 3. Clica no pet para lançar o laço
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then 
        -- Se não está na tela, teleporta mais perto
        return false 
    end
    
    pcall(function()
        local mouse = Player:GetMouse()
        if mouse then
            mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
            task.wait(0.1)
            mouse.Button1Click()
            print("🎯 Laço lançado em: " .. pet.Name)
            return true
        end
    end)
    
    -- 4. Tenta via Remote (fallback)
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("CapturePet") 
            or ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Capture")
            or ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Capture")
        
        if remote then
            remote:FireServer(pet)
            print("📡 Captura via Remote: " .. pet.Name)
            return true
        end
    end)
    
    return true
end

-- ========================================
-- TELEPORTE SUAVE ATÉ O PET
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
-- CAPTURAR PET (COMPLETO)
-- ========================================
local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    print("🎯 Capturando: " .. pet.Name)
    
    -- Teleporta suavemente até o pet
    local targetPos = hrp.Position + Vector3.new(0, 3, 0)
    SmoothTeleport(targetPos)
    
    -- Espera um pouco
    task.wait(0.3)
    
    -- Lança o laço no pet
    local success = ThrowLasso(pet)
    
    -- Aguarda a captura
    task.wait(1.0)
    
    return success
end

-- ========================================
-- LEVAR PET À BASE (AUTOMÁTICO)
-- ========================================
local function BringPetToBase(pet)
    if not pet then return end
    
    -- Encontra a base do jogador
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("PlayerBase")
    if not base then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local basePos = base.Position + Vector3.new(0, 2, 0)
        
        -- Teleporta o pet para a base
        pcall(function()
            hrp.CFrame = CFrame.new(basePos)
        end)
        task.wait(0.3)
        
        -- Teleporta o jogador para a base também
        pcall(function()
            RootPart.CFrame = CFrame.new(basePos)
        end)
        task.wait(0.3)
    end
    
    -- Tenta soltar o pet na base (automático)
    local releaseRemote = ReplicatedStorage:FindFirstChild("ReleasePet")
        or ReplicatedStorage:FindFirstChild("DropPet")
        or ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Release")
    
    if releaseRemote then
        pcall(function() 
            releaseRemote:FireServer(pet) 
            print("📦 Pet solto na base automaticamente!")
        end)
        task.wait(0.3)
    end
end

-- ========================================
-- LOOP DE AUTO CAPTURE
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
            
            -- Encontra o pet mais próximo
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
                -- Captura o pet
                local success = CapturePet(target)
                if success then
                    capturedPets[target] = true
                    -- Leva o pet para a base
                    BringPetToBase(target)
                    print("✅ " .. target.Name .. " capturado e enviado para a base!")
                end
                
                -- Aguarda o delay antes de procurar o próximo
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
    
    print("✅ ESP criado para: " .. pet.Name)
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
                if not IsNPC(obj) then
                    print("🔍 Novo pet detectado: " .. obj.Name)
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
-- CRIAR MENU
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 320, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 12)

    -- Título
    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    title.BackgroundTransparency = 0.3
    title.Text = "✧ Six Seven"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold

    local titleCorner = Instance.new("UICorner")
    titleCorner.Parent = title
    titleCorner.CornerRadius = UDim.new(0, 12)

    -- Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0

    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = closeBtn
    closeCorner.CornerRadius = UDim.new(1, 0)

    -- Container
    local content = Instance.new("Frame")
    content.Parent = mainFrame
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1

    -- Botão ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = content
    espBtn.Size = UDim2.new(1, 0, 0, 40)
    espBtn.Position = UDim2.new(0, 0, 0, 0)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    espBtn.Text = "🔴 ESP: OFF"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 16
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0

    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 8)

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP: ON" or "🔴 ESP: OFF"
        espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        print("ESP:", espActive and "ON" or "OFF")
        if espActive then
            UpdateESP()
        else
            for pet, _ in pairs(espObjects) do
                RemoveESP(pet)
            end
            espObjects = {}
        end
    end)

    -- Botão Auto Capture
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = content
    autoBtn.Size = UDim2.new(1, 0, 0, 40)
    autoBtn.Position = UDim2.new(0, 0, 0, 50)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    autoBtn.Text = "🔴 Auto: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 16
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0

    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 8)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 Auto: ON" or "🔴 Auto: OFF"
        autoBtn.BackgroundColor3 = autoCapture and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        print("Auto Capture:", autoCapture and "ON" or "OFF")
        if autoCapture then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoCaptureRunning = false
        end
    end)

    -- Controle de Delay
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Parent = content
    delayLabel.Size = UDim2.new(1, 0, 0, 20)
    delayLabel.Position = UDim2.new(0, 0, 0, 100)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    delayLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    delayLabel.TextSize = 13
    delayLabel.Font = Enum.Font.Gotham

    -- Botões de Delay
    local delayBtn1 = Instance.new("TextButton")
    delayBtn1.Parent = content
    delayBtn1.Size = UDim2.new(0.33, -5, 0, 25)
    delayBtn1.Position = UDim2.new(0, 0, 0, 125)
    delayBtn1.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn1.Text = "⬅️"
    delayBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn1.TextSize = 16
    delayBtn1.Font = Enum.Font.GothamBold
    delayBtn1.BorderSizePixel = 0

    local delayCorner1 = Instance.new("UICorner")
    delayCorner1.Parent = delayBtn1
    delayCorner1.CornerRadius = UDim.new(0, 5)

    local delayBtn2 = Instance.new("TextButton")
    delayBtn2.Parent = content
    delayBtn2.Size = UDim2.new(0.34, -5, 0, 25)
    delayBtn2.Position = UDim2.new(0.33, 5, 0, 125)
    delayBtn2.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn2.Text = "🔄"
    delayBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn2.TextSize = 16
    delayBtn2.Font = Enum.Font.GothamBold
    delayBtn2.BorderSizePixel = 0

    local delayCorner2 = Instance.new("UICorner")
    delayCorner2.Parent = delayBtn2
    delayCorner2.CornerRadius = UDim.new(0, 5)

    local delayBtn3 = Instance.new("TextButton")
    delayBtn3.Parent = content
    delayBtn3.Size = UDim2.new(0.33, -5, 0, 25)
    delayBtn3.Position = UDim2.new(0.67, 5, 0, 125)
    delayBtn3.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn3.Text = "➡️"
    delayBtn3.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn3.TextSize = 16
    delayBtn3.Font = Enum.Font.GothamBold
    delayBtn3.BorderSizePixel = 0

    local delayCorner3 = Instance.new("UICorner")
    delayCorner3.Parent = delayBtn3
    delayCorner3.CornerRadius = UDim.new(0, 5)

    delayBtn1.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = math.max(Settings.AutoCapture.Delay - 0.5, 0.5)
        delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    end)

    delayBtn2.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = 1.5
        delayLabel.Text = "⏱️ Delay: 1.5s"
    end)

    delayBtn3.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = math.min(Settings.AutoCapture.Delay + 0.5, 5)
        delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    end)

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 0, 160)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Status: Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.Gotham

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 45, 0, 45)
    floatBtn.Position = UDim2.new(0.93, -22, 0.93, -22)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✧"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 24
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
print("  ✧ SIX SEVEN - AUTO FARM COMPLETO")
print("========================================")

pcall(CreateMenu)
StartMonitoring()

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    print("🔄 Respawnou!")
    task.wait(1)
    if espActive then
        UpdateESP()
    end
end)

print("========================================")
print("  ✅ PRONTO!")
print("  📌 ESP: Mostra pets")
print("  📌 Auto: Teleporta → Laço → Captura → Base")
print("  📌 Delay: Ajuste o tempo entre capturas")
print("========================================")
