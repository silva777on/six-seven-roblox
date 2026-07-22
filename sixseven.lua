--[[
    Six Seven - Auto Farm Completo
    Game: [🍎] Capture e Domestique!
    Baseado na Wiki Oficial do jogo
]]

print("🔄 CARREGANDO SIX SEVEN - VERSÃO DEFINITIVA...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
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
        Delay = 3.0,
        TeleportDelay = 0.2,
        CaptureDelay = 0.5
    },
    ESP = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        MaxDistance = 200
    },
    Filtros = {
        IgnorarNPCs = true,
        IgnorarCapturados = true,
        PriorizarRaros = true,
        DistanciaMinima = 10,
        DistanciaMaxima = 100
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
local isCapturing = false
local totalCaptured = 0

-- ========================================
-- LISTA DE ANIMAIS POR RARIDADE
-- ========================================
local Animais = {
    Comuns = {"capivara", "galinha", "coelho", "pato"},
    Incomuns = {"ovelha", "lobo", "veado", "raposa"},
    Raros = {"aguia", "urso", "gato", "cachorro"},
    Misticos = {"dragao", "fada", "golem", "serpente"},
    Lendarios = {"fenix", "tita", "lobolunar", "fadasolar"}
}

local function GetRaridade(animal)
    local name = animal:lower()
    for _, a in pairs(Animais.Lendarios) do
        if name:find(a) then return "Lendario" end
    end
    for _, a in pairs(Animais.Misticos) do
        if name:find(a) then return "Mistico" end
    end
    for _, a in pairs(Animais.Raros) do
        if name:find(a) then return "Raro" end
    end
    for _, a in pairs(Animais.Incomuns) do
        if name:find(a) then return "Incomum" end
    end
    for _, a in pairs(Animais.Comuns) do
        if name:find(a) then return "Comum" end
    end
    return nil
end

local function IsNPC(obj)
    if not obj then return false end
    local name = obj.Name:lower()
    if name:find("npc") then return true end
    if name:find("humano") then return true end
    if name:find("personagem") then return true end
    if name:find("vendedor") then return true end
    if name:find("lojista") then return true end
    if name:find("guarda") then return true end
    if name:find("civil") then return true end
    if name:find("aldeao") then return true end
    if name:find("comerciante") then return true end
    if name:find("treinador") then return true end
    if name:find("coruja") then return true end
    if name:find("owl") then return true end
    return false
end

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function FindAllPets()
    local pets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            
            -- Ignora o jogador
            if obj == Character then continue end
            if obj == Player.Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            
            -- Ignora NPCs
            if Settings.Filtros.IgnorarNPCs and IsNPC(obj) then continue end
            
            local name = obj.Name:lower()
            
            -- Ignora objetos do cenário
            if name:find("base") then continue end
            if name:find("floor") then continue end
            if name:find("wall") then continue end
            if name:find("ground") then continue end
            if name:find("tree") then continue end
            if name:find("rock") then continue end
            if name:find("stone") then continue end
            if name:find("grass") then continue end
            
            -- Verifica se é um animal (tem Humanoid)
            if not obj:FindFirstChild("Humanoid") then continue end
            
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                local dist = (RootPart and RootPart.Position or Vector3.new(0,0,0) - currentPos).Magnitude
                
                -- Verifica distância
                if dist > Settings.Filtros.DistanciaMaxima then continue end
                if dist < Settings.Filtros.DistanciaMinima then continue end
                
                -- Verifica se está se movendo (animal vivo)
                if petPositions[obj] then
                    local oldPos = petPositions[obj]
                    local moveDist = (currentPos - oldPos).Magnitude
                    if moveDist > 0.05 then
                        table.insert(pets, obj)
                    end
                else
                    table.insert(pets, obj)
                end
                
                petPositions[obj] = currentPos
            end
        end
    end
    
    -- Ordena por raridade (prioriza os mais raros)
    if Settings.Filtros.PriorizarRaros then
        table.sort(pets, function(a, b)
            local ra = GetRaridade(a.Name) or "Comum"
            local rb = GetRaridade(b.Name) or "Comum"
            local ordem = {Lendario=5, Mistico=4, Raro=3, Incomum=2, Comum=1}
            return (ordem[ra] or 0) > (ordem[rb] or 0)
        end)
    end
    
    return pets
end

-- ========================================
-- FUNÇÃO PARA EQUIPAR O LAÇO
-- ========================================
local function EquipLasso()
    -- Procura no inventário
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("laço") or name:find("lasso") or name:find("corda") or name:find("capture") then
                    if Humanoid then
                        Humanoid:EquipTool(item)
                        print("🎯 Laço equipado!")
                        task.wait(0.15)
                        return true
                    end
                end
            end
        end
    end
    
    -- Procura no Character
    if Character then
        for _, item in pairs(Character:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("laço") or name:find("lasso") or name:find("corda") or name:find("capture") then
                    print("🎯 Laço já está na mão!")
                    return true
                end
            end
        end
    end
    
    -- Tenta a tecla 1
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        print("🎯 Tecla 1 pressionada!")
        return true
    end)
    
    return false
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR O PET
-- ========================================
local function CapturePet(pet)
    if not pet then return false end
    if isCapturing then return false end
    
    -- Verifica se já foi capturado
    if Settings.Filtros.IgnorarCapturados and capturedPets[pet] then
        return false
    end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    isCapturing = true
    
    print("🎯 Capturando: " .. pet.Name .. " (" .. (GetRaridade(pet.Name) or "Desconhecido") .. ")")
    
    -- Teleporta suavemente
    local targetPos = hrp.Position + Vector3.new(0, 3, 0)
    
    if RootPart then
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
    
    -- Equipa o laço
    EquipLasso()
    task.wait(0.2)
    
    -- Tenta capturar via Remote
    local remote = ReplicatedStorage:FindFirstChild("CapturePet")
        or ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Capture")
        or ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Capture")
        or ReplicatedStorage:FindFirstChild("RemoteEvent")
    
    if remote then
        pcall(function() 
            remote:FireServer(pet)
            print("📡 Captura via Remote: " .. pet.Name)
            task.wait(0.5)
            isCapturing = false
            return true
        end)
    end
    
    -- Fallback: clicar no pet com o laço
    local camera = workspace.CurrentCamera
    if camera then
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            pcall(function()
                local mouse = Player:GetMouse()
                if mouse then
                    mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
                    task.wait(0.1)
                    mouse.Button1Click()
                    print("🖱️ Clique no pet: " .. pet.Name)
                    task.wait(0.5)
                    isCapturing = false
                    return true
                end
            end)
        end
    end
    
    isCapturing = false
    return false
end

-- ========================================
-- FUNÇÃO PARA LEVAR PET À BASE
-- ========================================
local function BringPetToBase(pet)
    if not pet then return end
    
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("PlayerBase")
    if not base then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local basePos = base.Position + Vector3.new(0, 2, 0)
        
        if RootPart then
            local currentPos = RootPart.Position
            local dist = (currentPos - basePos).Magnitude
            
            if dist > 5 then
                local steps = math.min(math.floor(dist / 3), 5)
                for i = 1, steps do
                    local progress = i / steps
                    local newPos = currentPos:Lerp(basePos, progress)
                    pcall(function()
                        RootPart.CFrame = CFrame.new(newPos)
                    end)
                    task.wait(0.2)
                end
            end
        end
        
        pcall(function()
            RootPart.CFrame = CFrame.new(basePos)
            hrp.CFrame = CFrame.new(basePos)
        end)
        task.wait(0.3)
    end
    
    -- Tenta soltar o pet na base
    local releaseRemote = ReplicatedStorage:FindFirstChild("ReleasePet")
        or ReplicatedStorage:FindFirstChild("DropPet")
        or ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Release")
    
    if releaseRemote then
        pcall(function() 
            releaseRemote:FireServer(pet)
            print("📦 Pet solto na base!")
        end)
        task.wait(0.3)
    end
    
    totalCaptured = totalCaptured + 1
    print("📊 Total capturado: " .. totalCaptured)
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        task.spawn(function()
            if isCapturing then 
                task.wait(0.3)
                return 
            end
            
            local pets = FindAllPets()
            local target = nil
            local minDist = math.huge
            
            if #pets == 0 then
                task.wait(0.5)
                return
            end
            
            -- Encontra o pet mais próximo (ou mais raro)
            for _, pet in pairs(pets) do
                if not capturedPets[pet] then
                    local hrp = pet:FindFirstChild("HumanoidRootPart")
                    if hrp and RootPart then
                        local dist = (RootPart.Position - hrp.Position).Magnitude
                        if dist < minDist and dist >= Settings.Filtros.DistanciaMinima then
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
                    print("✅ " .. target.Name .. " capturado e enviado para a base!")
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
    if IsNPC(pet) then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Cores por raridade
    local raridade = GetRaridade(pet.Name)
    local cor = Settings.ESP.Color
    if raridade == "Comum" then cor = Color3.fromRGB(0, 255, 0)
    elseif raridade == "Incomum" then cor = Color3.fromRGB(0, 150, 255)
    elseif raridade == "Raro" then cor = Color3.fromRGB(150, 0, 255)
    elseif raridade == "Mistico" then cor = Color3.fromRGB(255, 215, 0)
    elseif raridade == "Lendario" then cor = Color3.fromRGB(255, 0, 0)
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = pet
    highlight.FillColor = cor
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = hrp
    billboard.Size = UDim2.new(0, 150, 0, 35)
    billboard.Adornee = hrp
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 0.6, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.Text = "🐾 " .. pet.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    local rarLabel = Instance.new("TextLabel")
    rarLabel.Parent = billboard
    rarLabel.Size = UDim2.new(1, 0, 0.4, 0)
    rarLabel.Position = UDim2.new(0, 0, 0.6, 0)
    rarLabel.BackgroundTransparency = 1
    rarLabel.Text = raridade or "?"
    rarLabel.TextColor3 = cor
    rarLabel.TextSize = 12
    rarLabel.Font = Enum.Font.GothamBold
    
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
        RarLabel = rarLabel,
        DistLabel = distLabel
    }
    
    print("✅ ESP criado para: " .. pet.Name .. " (" .. (raridade or "?") .. ")")
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
-- MENU
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 320, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -150)
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

    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 8)

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
    autoBtn.Text = "🔴 Auto"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 15
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0

    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 8)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 Auto" or "🔴 Auto"
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
    delayLabel.Size = UDim2.new(1, 0, 0, 20)
    delayLabel.Position = UDim2.new(0, 0, 0, 85)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    delayLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    delayLabel.TextSize = 13
    delayLabel.Font = Enum.Font.Gotham

    local delayBtn1 = Instance.new("TextButton")
    delayBtn1.Parent = content
    delayBtn1.Size = UDim2.new(0.33, -5, 0, 25)
    delayBtn1.Position = UDim2.new(0, 0, 0, 110)
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
    delayBtn2.Position = UDim2.new(0.33, 5, 0, 110)
    delayBtn2.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    delayBtn2.Text = "3s"
    delayBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn2.TextSize = 14
    delayBtn2.Font = Enum.Font.GothamBold
    delayBtn2.BorderSizePixel = 0

    local delayCorner2 = Instance.new("UICorner")
    delayCorner2.Parent = delayBtn2
    delayCorner2.CornerRadius = UDim.new(0, 5)

    local delayBtn3 = Instance.new("TextButton")
    delayBtn3.Parent = content
    delayBtn3.Size = UDim2.new(0.33, -5, 0, 25)
    delayBtn3.Position = UDim2.new(0.67, 5, 0, 110)
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
        Settings.AutoCapture.Delay = 3.0
        delayLabel.Text = "⏱️ Delay: 3.0s"
    end)

    delayBtn3.MouseButton1Click:Connect(function()
        Settings.AutoCapture.Delay = math.min(Settings.AutoCapture.Delay + 0.5, 5)
        delayLabel.Text = "⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s"
    end)

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 145)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Status: Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.Gotham

    -- Total capturado
    local totalLabel = Instance.new("TextLabel")
    totalLabel.Parent = content
    totalLabel.Size = UDim2.new(1, 0, 0, 20)
    totalLabel.Position = UDim2.new(0, 0, 0, 175)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = "🏆 Capturados: 0"
    totalLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    totalLabel.TextSize = 13
    totalLabel.Font = Enum.Font.Gotham

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

    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindAllPets()
            statusLabel.Text = "📊 Pets: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF")
            totalLabel.Text = "🏆 Capturados: " .. totalCaptured
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - VERSÃO DEFINITIVA")
print("========================================")

pcall(CreateMenu)

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
print("  📌 ESP: Mostra pets por raridade")
print("  📌 Auto: Captura automática")
print("  📌 Cores: 🟢Comum 🔵Incomum 🟣Raro 🟡Místico 🔴Lendário")
print("========================================")
