--[[
    Six Seven - Versão Definitiva (Todos os Pets)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN DEFINITIVO...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

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
        Delay = 2.0,
        Range = 100
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
local allPets = {}

-- ========================================
-- LISTA DE NPCS PARA IGNORAR
-- ========================================
local npcNames = {
    "npc", "humano", "personagem", "vendedor", "lojista", 
    "guarda", "civil", "aldeao", "comerciante", "treinador",
    "professor", "mestre", "ancião", "mercador", "homem", "mulher",
    "crianca", "adulto", "velho", "jovem"
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
-- FUNÇÃO PARA ENCONTRAR TODOS OS PETS
-- ========================================
local function FindAllPets()
    local pets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Procura por modelos com HumanoidRootPart
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            
            -- Ignora o jogador
            if obj == Character then continue end
            if obj == Player.Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            
            -- Ignora NPCs
            if IsNPC(obj) then continue end
            
            local name = obj.Name:lower()
            
            -- Ignora objetos do cenário
            if name:find("base") or name:find("floor") or name:find("wall") or name:find("ground") then
                continue
            end
            if name:find("tree") or name:find("rock") or name:find("stone") or name:find("grass") then
                continue
            end
            if name:find("house") or name:find("building") or name:find("fence") then
                continue
            end
            
            -- Verifica se tem partes (todo modelo tem)
            local hasParts = false
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("BasePart") then
                    hasParts = true
                    break
                end
            end
            
            if not hasParts then continue end
            
            -- Verifica se está perto (range)
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp and RootPart then
                local dist = (RootPart.Position - hrp.Position).Magnitude
                
                -- Adiciona se estiver dentro do range OU se estiver se movendo
                if dist < Settings.AutoCapture.Range then
                    table.insert(pets, obj)
                end
            end
        end
    end
    
    return pets
end

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PELO NOME (FALLBACK)
-- ========================================
local function FindPetsByName()
    local pets = {}
    
    -- Lista de palavras que indicam pet
    local petKeywords = {
        "capivara", "capy", "cavalo", "vaca", "boi", "ovelha", "cabra",
        "gato", "cachorro", "coelho", "pato", "galinha", "porco",
        "dragao", "fada", "elfo", "golem", "esqueleto", "zumbi",
        "lobo", "urso", "raposa", "veado", "javali", "onca",
        "papagaio", "tucano", "arara", "aguia", "falcão",
        "pet", "creature", "monster", "animal", "wild",
        "divino", "mistico", "chefe", "boss", "lendario", "epico",
        "capture", "domestique", "domestico", "selvagem"
    }
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj == Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            if IsNPC(obj) then continue end
            
            local name = obj.Name:lower()
            for _, keyword in pairs(petKeywords) do
                if name:find(keyword) then
                    table.insert(pets, obj)
                    break
                end
            end
        end
    end
    
    return pets
end

-- ========================================
-- FUNÇÃO COMBINADA
-- ========================================
local function GetAllPets()
    -- Primeiro tenta encontrar pelo nome (mais específico)
    local byName = FindPetsByName()
    
    -- Depois tenta encontrar por movimento
    local moving = FindAllPets()
    
    -- Combina as duas listas (sem duplicatas)
    local combined = {}
    local seen = {}
    
    for _, pet in pairs(byName) do
        if not seen[pet] then
            seen[pet] = true
            table.insert(combined, pet)
        end
    end
    
    for _, pet in pairs(moving) do
        if not seen[pet] then
            seen[pet] = true
            table.insert(combined, pet)
        end
    end
    
    return combined
end

-- ========================================
-- USAR LAÇO (SIMPLES)
-- ========================================
local function UseLasso()
    -- Tecla 1
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        return true
    end)
    
    -- Procura o laço
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("laço") or name:find("lasso") or name:find("corda") then
                    if Humanoid then
                        Humanoid:EquipTool(item)
                        task.wait(0.1)
                        item:Activate()
                        return true
                    end
                end
            end
        end
    end
    
    return false
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
            task.wait(0.05)
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
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Teleporta
    if RootPart then
        local targetPos = hrp.Position + Vector3.new(0, 2, 0)
        pcall(function()
            RootPart.CFrame = CFrame.new(targetPos)
        end)
        task.wait(0.2)
    end
    
    -- Usa laço
    UseLasso()
    task.wait(0.2)
    
    -- Clica
    local success = ClickOnPet(pet)
    task.wait(0.5)
    
    return success
end

-- ========================================
-- LEVAR À BASE
-- ========================================
local function BringPetToBase(pet)
    if not pet then return end
    
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("PlayerBase")
    if not base then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local basePos = base.Position + Vector3.new(0, 2, 0)
        pcall(function()
            RootPart.CFrame = CFrame.new(basePos)
            hrp.CFrame = CFrame.new(basePos)
        end)
        task.wait(0.2)
    end
    
    local releaseRemote = ReplicatedStorage:FindFirstChild("ReleasePet") 
        or ReplicatedStorage:FindFirstChild("DropPet")
    
    if releaseRemote then
        pcall(function() releaseRemote:FireServer(pet) end)
        task.wait(0.2)
    end
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        task.spawn(function()
            local pets = GetAllPets()
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
                print("🎯 Capturando: " .. target.Name)
                local success = CapturePet(target)
                if success then
                    capturedPets[target] = true
                    BringPetToBase(target)
                    print("✅ " .. target.Name .. " capturado!")
                end
                task.wait(Settings.AutoCapture.Delay)
            else
                task.wait(0.3)
            end
        end)
        task.wait(0.05)
    end
end

-- ========================================
-- ESP
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
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = hrp
    billboard.Size = UDim2.new(0, 120, 0, 25)
    billboard.Adornee = hrp
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.Text = pet.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    espObjects[pet] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label
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
    
    local pets = GetAllPets()
    for _, pet in pairs(pets) do
        if pet and pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            local hrp = pet.HumanoidRootPart
            if RootPart then
                local dist = (RootPart.Position - hrp.Position).Magnitude
                if dist <= Settings.ESP.MaxDistance then
                    CreateESP(pet)
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
    mainFrame.Size = UDim2.new(0, 280, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -140, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    title.BackgroundTransparency = 0.3
    title.Text = "✧ Six Seven"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 3)
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

    local content = Instance.new("Frame")
    content.Parent = mainFrame
    content.Size = UDim2.new(1, -20, 1, -45)
    content.Position = UDim2.new(0, 10, 0, 35)
    content.BackgroundTransparency = 1

    -- ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = content
    espBtn.Size = UDim2.new(1, 0, 0, 35)
    espBtn.Position = UDim2.new(0, 0, 0, 0)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    espBtn.Text = "🔴 ESP"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 15
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP" or "🔴 ESP"
        espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        if espActive then UpdateESP() else
            for pet, _ in pairs(espObjects) do RemoveESP(pet) end
            espObjects = {}
        end
    end)

    -- Auto
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = content
    autoBtn.Size = UDim2.new(1, 0, 0, 35)
    autoBtn.Position = UDim2.new(0, 0, 0, 40)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    autoBtn.Text = "🔴 Auto Capture"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 15
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 Auto Capture" or "🔴 Auto Capture"
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

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 80)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham

    -- Float
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 40, 0, 40)
    floatBtn.Position = UDim2.new(0.93, -20, 0.93, -20)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✧"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 22
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
            local count = #GetAllPets()
            statusLabel.Text = "📊 Pets: " .. count
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - DEFINITIVO")
print("========================================")

pcall(CreateMenu)
StartMonitoring()

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    print("🔄 Respawnou!")
end)

print("========================================")
print("  ✅ PRONTO!")
print("  📌 ESP: Liga/Desliga")
print("  📌 Auto: Teleporta + Laço + Clique")
print("========================================")
