--[[
    Six Seven - CAPTURA SIMPLES E FUNCIONAL
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - VERSÃO SIMPLES...")

local Players = game:GetService("Players")
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
        Delay = 5.0,
        TeleportDelay = 0.3,
        ClickSpeed = 0.05,
        TotalClicks = 20
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
local totalCaptured = 0
local isProcessing = false

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function FindAllPets()
    local pets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj == Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            
            local name = obj.Name:lower()
            if name:find("base") or name:find("floor") or name:find("wall") or name:find("ground") then
                continue
            end
            if name:find("npc") or name:find("humano") or name:find("personagem") then
                continue
            end
            
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(pets, obj)
                petPositions[obj] = hrp.Position
            end
        end
    end
    
    return pets
end

-- ========================================
-- TELEPORTE
-- ========================================
local function TeleportTo(targetPos)
    if not RootPart then return end
    
    pcall(function()
        RootPart.CFrame = CFrame.new(targetPos)
    end)
    task.wait(0.2)
end

-- ========================================
-- FUNÇÃO PARA CLICAR (SIMPLES E DIRETA)
-- ========================================
local function ClickOnPosition(screenX, screenY)
    pcall(function()
        -- Move o mouse
        VirtualInputManager:SendMouseMovement(screenX, screenY, Enum.VirtualKeyMode.Delta, game)
        task.wait(0.05)
        
        -- Clique
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
    end)
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR (MAIS SIMPLES)
-- ========================================
local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    if isProcessing then return false end
    if capturedPets[pet] then return false end
    
    isProcessing = true
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        isProcessing = false
        return false 
    end
    
    print("🎯 Capturando: " .. pet.Name)
    
    -- 1. Teleporta para perto do pet
    local targetPos = hrp.Position + Vector3.new(0, 2, 0)
    TeleportTo(targetPos)
    task.wait(0.3)
    
    -- 2. Tenta capturar via Remote (MÉTODO 1)
    local remote = ReplicatedStorage:FindFirstChild("PetEvent") 
        or ReplicatedStorage:FindFirstChild("CapturePet")
        or ReplicatedStorage:FindFirstChild("RemoteEvent")
    
    if remote then
        pcall(function()
            remote:FireServer("Capture", pet.Name, pet)
            print("📡 Remote enviado!")
            task.wait(0.5)
            
            -- Verifica se capturou
            local petsFolder = Player:FindFirstChild("Pets")
            if petsFolder and petsFolder:FindFirstChild(pet.Name) then
                capturedPets[pet] = true
                totalCaptured = totalCaptured + 1
                isProcessing = false
                print("✅ " .. pet.Name .. " capturado via Remote!")
                pet:Destroy()
                return true
            end
        end)
    end
    
    -- 3. Tenta interagir com o ProximityPrompt (MÉTODO 2)
    local prompt = pet:FindFirstChild("ProximityPrompt")
    if prompt then
        pcall(function()
            print("🔄 Usando ProximityPrompt...")
            prompt:InputHoldBegin(Player)
            task.wait(0.3)
            prompt:InputHoldEnd(Player)
            task.wait(0.5)
            
            -- Verifica se capturou
            local petsFolder = Player:FindFirstChild("Pets")
            if petsFolder and petsFolder:FindFirstChild(pet.Name) then
                capturedPets[pet] = true
                totalCaptured = totalCaptured + 1
                isProcessing = false
                print("✅ " .. pet.Name .. " capturado via Prompt!")
                pet:Destroy()
                return true
            end
        end)
    end
    
    -- 4. Tenta clicar no pet (MÉTODO 3)
    local camera = workspace.CurrentCamera
    if camera then
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            pcall(function()
                print("🔄 Clicando no pet...")
                ClickOnPosition(screenPos.X, screenPos.Y)
                task.wait(0.3)
                
                -- Clique rápido para encher a barra
                for i = 1, 15 do
                    ClickOnPosition(screenPos.X, screenPos.Y)
                    task.wait(0.03)
                end
                
                task.wait(0.5)
                
                -- Verifica se capturou
                local petsFolder = Player:FindFirstChild("Pets")
                if petsFolder and petsFolder:FindFirstChild(pet.Name) then
                    capturedPets[pet] = true
                    totalCaptured = totalCaptured + 1
                    isProcessing = false
                    print("✅ " .. pet.Name .. " capturado via Clique!")
                    pet:Destroy()
                    return true
                end
            end)
        end
    end
    
    isProcessing = false
    return false
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
        TeleportTo(base.Position + Vector3.new(0, 2, 0))
        pcall(function()
            hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        if isProcessing then 
            task.wait(0.5)
            goto continue
        end
        
        local pets = FindAllPets()
        local target = nil
        local minDist = math.huge
        
        if #pets == 0 then
            task.wait(0.5)
            goto continue
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
                BringPetToBase(target)
                print("✅ " .. target.Name .. " capturado!")
            end
            task.wait(Settings.AutoCapture.Delay)
        else
            task.wait(0.5)
        end
        
        ::continue::
        task.wait(0.1)
    end
end

-- ========================================
-- SISTEMA ESP (SIMPLES)
-- ========================================
local function CreateESP(pet)
    if not pet or espObjects[pet] then return end
    
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
    
    espObjects[pet] = highlight
end

local function RemoveESP(pet)
    if espObjects[pet] then
        espObjects[pet]:Destroy()
        espObjects[pet] = nil
    end
end

local function UpdateESP()
    if not espActive then
        for pet, _ in pairs(espObjects) do
            RemoveESP(pet)
        end
        return
    end
    
    local pets = FindAllPets()
    for _, pet in pairs(pets) do
        if pet and pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            if RootPart then
                local hrp = pet.HumanoidRootPart
                local dist = (RootPart.Position - hrp.Position).Magnitude
                if dist <= Settings.ESP.MaxDistance then
                    CreateESP(pet)
                else
                    RemoveESP(pet)
                end
            end
        end
    end
    
    -- Remove ESP de pets que não existem mais
    local currentPets = {}
    for _, pet in pairs(pets) do
        currentPets[pet] = true
    end
    for pet, _ in pairs(espObjects) do
        if not currentPets[pet] then
            RemoveESP(pet)
        end
    end
end

-- ========================================
-- MENU
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 300, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    title.BackgroundTransparency = 0.3
    title.Text = "✧ Six Seven"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold

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

    local content = Instance.new("Frame")
    content.Parent = mainFrame
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1

    -- ESP
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

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP: ON" or "🔴 ESP: OFF"
        espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        if espActive then UpdateESP() else
            for pet, _ in pairs(espObjects) do RemoveESP(pet) end
        end
    end)

    -- Auto
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

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 Auto: ON" or "🔴 Auto: OFF"
        autoBtn.BackgroundColor3 = autoCapture and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        if autoCapture then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoCaptureRunning = false
        end
    end)

    -- Delay
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Parent = content
    delayLabel.Size = UDim2.new(1, 0, 0, 25)
    delayLabel.Position = UDim2.new(0, 0, 0, 100)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    delayLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    delayLabel.TextSize = 14
    delayLabel.Font = Enum.Font.Gotham

    local delayBtn1 = Instance.new("TextButton")
    delayBtn1.Parent = content
    delayBtn1.Size = UDim2.new(0.33, -5, 0, 30)
    delayBtn1.Position = UDim2.new(0, 0, 0, 130)
    delayBtn1.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn1.Text = "⬅️"
    delayBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn1.TextSize = 18
    delayBtn1.Font = Enum.Font.GothamBold
    delayBtn1.BorderSizePixel = 0

    local delayBtn2 = Instance.new("TextButton")
    delayBtn2.Parent = content
    delayBtn2.Size = UDim2.new(0.34, -5, 0, 30)
    delayBtn2.Position = UDim2.new(0.33, 5, 0, 130)
    delayBtn2.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn2.Text = "5s"
    delayBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn2.TextSize = 14
    delayBtn2.Font = Enum.Font.GothamBold
    delayBtn2.BorderSizePixel = 0

    local delayBtn3 = Instance.new("TextButton")
    delayBtn3.Parent = content
    delayBtn3.Size = UDim2.new(0.33, -5, 0, 30)
    delayBtn3.Position = UDim2.new(0.67, 5, 0, 130)
    delayBtn3.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn3.Text = "➡️"
    delayBtn3.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn3.TextSize = 18
    delayBtn3.Font = Enum.Font.GothamBold
    delayBtn3.BorderSizePixel = 0

    delayBtn1.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = math.max(Settings.AutoCapture.Delay - 0.5, 0.5)
        delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    end)

    delayBtn2.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = 5.0
        delayLabel.Text = "⏱️ Delay: 5.0s"
    end)

    delayBtn3.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = math.min(Settings.AutoCapture.Delay + 0.5, 5)
        delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    end)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 170)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Status: Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.Gotham

    -- Float
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

    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindAllPets()
            statusLabel.Text = "📊 Pets: " .. count .. " | Capturados: " .. totalCaptured
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - CAPTURA SIMPLES")
print("========================================")
print("  📖 3 MÉTODOS DE CAPTURA:")
print("  1. 📡 Remote Event")
print("  2. 🎯 ProximityPrompt")
print("  3. 🖱️ Clique no pet")
print("========================================")

pcall(CreateMenu)

-- Monitoramento
task.spawn(function()
    while true do
        task.wait(0.5)
        if espActive then
            UpdateESP()
        end
    end
end)

-- Monitorar novos pets
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
            if espActive then
                task.wait(0.1)
                UpdateESP()
            end
        end
    end
end)

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    print("🔄 Respawnou!")
end)

print("========================================")
print("  ✅ PRONTO!")
print("  📌 Ative o ESP para ver os pets")
print("  📌 Ative o Auto para capturar")
print("========================================")
