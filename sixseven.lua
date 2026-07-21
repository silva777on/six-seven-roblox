--[[
    Six Seven - DETECÇÃO UNIVERSAL
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- FUNÇÃO QUE DETECTA QUALQUER MODELO COM HUMANOID
-- ========================================
local function FindAllCreatures()
    local creatures = {}
    
    -- Procura por TODOS os modelos com HumanoidRootPart e Humanoid
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
            -- Ignora o próprio jogador
            if obj ~= Character and obj.Parent ~= Player and obj.Name ~= Player.Name then
                -- Ignora objetos comuns (como NPCs se tiver)
                local name = obj.Name:lower()
                if not name:find("npc") and not name:find("player") and not name:find("base") then
                    table.insert(creatures, obj)
                    print("🐾 Encontrado:", obj.Name)
                end
            end
        end
    end
    
    return creatures
end

-- ========================================
-- ESP SIMPLES
-- ========================================
local espObjects = {}
local espActive = false

local function CreateESP(pet)
    if not pet or not pet:IsA("Model") then return end
    if espObjects[pet] then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = pet
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    espObjects[pet] = highlight
    print("✅ ESP criado para:", pet.Name)
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
        espObjects = {}
        return
    end
    
    local creatures = FindAllCreatures()
    
    for _, creature in pairs(creatures) do
        if creature and creature:IsA("Model") and creature:FindFirstChild("HumanoidRootPart") then
            CreateESP(creature)
        end
    end
    
    -- Remove ESP de criaturas que não existem mais
    local currentCreatures = {}
    for _, c in pairs(creatures) do
        currentCreatures[c] = true
    end
    for pet, _ in pairs(espObjects) do
        if not currentCreatures[pet] or not pet:IsA("Model") then
            RemoveESP(pet)
        end
    end
end

-- ========================================
-- AUTO CAPTURE SIMPLES
-- ========================================
local autoCapture = false
local autoCaptureRunning = false
local capturedPets = {}

local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    if RootPart then
        local targetPos = hrp.Position + Vector3.new(0, 3, 0)
        pcall(function() RootPart.CFrame = CFrame.new(targetPos) end)
        task.wait(0.1)
    end
    
    -- Tenta diferentes formas de capturar
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("CapturePet")
    if remote then
        pcall(function() remote:FireServer(pet) end)
        task.wait(0.5)
        return true
    end
    
    return true
end

local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        task.spawn(function()
            local creatures = FindAllCreatures()
            local target = nil
            local minDist = math.huge
            
            for _, creature in pairs(creatures) do
                if not capturedPets[creature] then
                    local hrp = creature:FindFirstChild("HumanoidRootPart")
                    if hrp and RootPart then
                        local dist = (RootPart.Position - hrp.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            target = creature
                        end
                    end
                end
            end
            
            if target then
                print("🎯 Capturando:", target.Name)
                local success = CapturePet(target)
                if success then
                    capturedPets[target] = true
                    print("✅ Capturado!")
                end
                task.wait(1.5)
            else
                task.wait(0.5)
            end
        end)
        task.wait(0.1)
    end
end

-- ========================================
-- GUI
-- ========================================
local function CreateGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 350, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -150)
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
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    title.BackgroundTransparency = 0.3
    title.Text = "✧ Six Seven"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold

    local titleCorner = Instance.new("UICorner")
    titleCorner.Parent = title
    titleCorner.CornerRadius = UDim.new(0, 12)

    -- Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.Gotham
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = closeBtn
    closeCorner.CornerRadius = UDim.new(1, 0)

    local content = Instance.new("Frame")
    content.Parent = mainFrame
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 50)
    content.BackgroundTransparency = 1

    -- Botão ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = content
    espBtn.Size = UDim2.new(1, 0, 0, 45)
    espBtn.Position = UDim2.new(0, 0, 0, 0)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    espBtn.Text = "🔴 ESP: DESLIGADO"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 16
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 8)

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP: LIGADO" or "🔴 ESP: DESLIGADO"
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
    autoBtn.Size = UDim2.new(1, 0, 0, 45)
    autoBtn.Position = UDim2.new(0, 0, 0, 55)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    autoBtn.Text = "🔴 Auto Capture: DESLIGADO"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 16
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 8)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 Auto Capture: LIGADO" or "🔴 Auto Capture: DESLIGADO"
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

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 0, 110)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Status: Procurando..."
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 50, 0, 50)
    floatBtn.Position = UDim2.new(0.93, -25, 0.93, -25)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✧"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 28
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
            task.wait(1)
            local count = #FindAllCreatures()
            statusLabel.Text = "📊 Criaturas encontradas: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF")
        end
    end)

    -- Atualiza ESP automaticamente
    task.spawn(function()
        while true do
            task.wait(0.5)
            if espActive then
                UpdateESP()
            end
        end
    end)

    print("✅ GUI criada!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - DETECÇÃO UNIVERSAL")
print("========================================")

-- Executa diagnóstico primeiro
local creatures = FindAllCreatures()
print("🔍 Encontrados " .. #creatures .. " modelos com Humanoid no mapa!")

if #creatures == 0 then
    print("⚠️ Nenhum pet encontrado! Verifique:")
    print("   1 - Você está perto de algum pet?")
    print("   2 - Os pets têm 'Humanoid' e 'HumanoidRootPart'?")
    print("   3 - Execute o script de diagnóstico para ver os nomes")
end

for _, c in pairs(creatures) do
    print("   - " .. c.Name)
end

-- Cria GUI
pcall(CreateGUI)

-- Atualiza personagem
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    print("🔄 Respawnou!")
end)

print("========================================")
print("✅ PRONTO!")
print("📌 Clique em 'ESP' para ligar")
print("📌 Clique em 'Auto Capture' para ligar")
print("========================================")
