--[[
    SISTEMA COMPLETO DE CAPTURA DE PETS - VERSÃO SIMPLES
    Copie e cole cada parte no lugar certo!
]]

-- ========================================
-- PARTE 1: SERVIDOR (ServerScriptService)
-- Nome do script: PetSystem
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Cria o evento se não existir
local PetEvent = Instance.new("RemoteEvent")
PetEvent.Name = "PetEvent"
PetEvent.Parent = ReplicatedStorage

-- Cria a pasta Pets para cada jogador
Players.PlayerAdded:Connect(function(player)
    local pets = Instance.new("Folder")
    pets.Name = "Pets"
    pets.Parent = player
    print("📁 Pasta Pets criada para: " .. player.Name)
end)

-- Evento de captura
PetEvent.OnServerEvent:Connect(function(player, action, petName, petModel)
    print("📡 Evento recebido:", action, petName)
    
    if action == "Capture" then
        local pets = player:FindFirstChild("Pets")
        
        if pets then
            -- Verifica se já tem esse pet
            local alreadyHas = pets:FindFirstChild(petName)
            
            if not alreadyHas then
                -- Cria o pet
                local pet = Instance.new("StringValue")
                pet.Name = petName
                pet.Value = petName
                pet.Parent = pets
                
                print("🐾 " .. player.Name .. " capturou " .. petName)
                
                -- Notifica o jogador
                PetEvent:FireClient(player, "Notification", "✅ Você capturou " .. petName .. "!")
                
                -- Atualiza a lista
                local petList = {}
                for _, p in pairs(pets:GetChildren()) do
                    table.insert(petList, p.Name)
                end
                PetEvent:FireClient(player, "PetList", petList)
            else
                print("⚠️ " .. player.Name .. " já tem " .. petName)
                PetEvent:FireClient(player, "Notification", "⚠️ Você já tem " .. petName)
            end
        end
    end
    
    if action == "ListPets" then
        local pets = player:FindFirstChild("Pets")
        if pets then
            local petList = {}
            for _, p in pairs(pets:GetChildren()) do
                table.insert(petList, p.Name)
            end
            PetEvent:FireClient(player, "PetList", petList)
        end
    end
end)

print("✅ SISTEMA DE PETS INICIADO!")


-- ========================================
-- PARTE 2: SCRIPT DO PET (Dentro de cada pet)
-- Coloque este script dentro de cada PET no workspace
-- ========================================

local pet = script.Parent
local prompt = pet:WaitForChild("ProximityPrompt")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetEvent = ReplicatedStorage:WaitForChild("PetEvent")

prompt.Triggered:Connect(function(player)
    print("🔄 " .. player.Name .. " interagiu com " .. pet.Name)
    
    -- Verifica se o jogador já tem esse pet
    local pets = player:FindFirstChild("Pets")
    if pets and pets:FindFirstChild(pet.Name) then
        print("⚠️ " .. player.Name .. " já tem " .. pet.Name)
        return
    end
    
    -- Captura o pet
    PetEvent:FireServer("Capture", pet.Name, pet)
    
    -- Efeito visual
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Transparency = 0.5
        hrp.BrickColor = BrickColor.new("Bright green")
    end
    
    -- Destroi o pet após 1 segundo
    task.wait(1)
    pet:Destroy()
end)

print("✅ PET " .. pet.Name .. " PRONTO!")


-- ========================================
-- PARTE 3: INTERFACE DO JOGADOR (StarterGui)
-- Nome do script: PetGUI (LocalScript)
-- ========================================

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetEvent = ReplicatedStorage:WaitForChild("PetEvent")

-- Espera o personagem carregar
repeat task.wait() until player.Character

print("🔄 Iniciando GUI...")

-- Cria a GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Cantos
local corner = Instance.new("UICorner")
corner.Parent = frame
corner.CornerRadius = UDim.new(0, 12)

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
title.BackgroundTransparency = 0.3
title.Text = "🐾 MEUS PETS"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.Parent = title
titleCorner.CornerRadius = UDim.new(0, 12)

-- Lista de pets (ScrollingFrame)
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 10, 0, 55)
list.Size = UDim2.new(1, -20, 1, -120)
list.BackgroundTransparency = 1
list.Parent = frame
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = Color3.fromRGB(100, 0, 200)

-- Container para os pets
local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, 0)
container.BackgroundTransparency = 1
container.Parent = list

-- Layout
local layout = Instance.new("UIListLayout")
layout.Parent = container
layout.SortOrder = Enum.SortOrder.Name
layout.Padding = UDim.new(0, 5)

-- Frame dos botões
local btnFrame = Instance.new("Frame")
btnFrame.Position = UDim2.new(0, 10, 1, -50)
btnFrame.Size = UDim2.new(1, -20, 0, 40)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = frame

-- Botão Atualizar
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.48, -5, 1, 0)
refreshBtn.Position = UDim2.new(0, 0, 0, 0)
refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
refreshBtn.Text = "🔄 Atualizar"
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.TextSize = 14
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = btnFrame

local refreshCorner = Instance.new("UICorner")
refreshCorner.Parent = refreshBtn
refreshCorner.CornerRadius = UDim.new(0, 8)

-- Botão Capturar
local captureBtn = Instance.new("TextButton")
captureBtn.Size = UDim2.new(0.48, -5, 1, 0)
captureBtn.Position = UDim2.new(0.52, 5, 0, 0)
captureBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
captureBtn.Text = "🎯 Capturar"
captureBtn.TextColor3 = Color3.new(1, 1, 1)
captureBtn.TextSize = 14
captureBtn.Font = Enum.Font.GothamBold
captureBtn.BorderSizePixel = 0
captureBtn.Parent = btnFrame

local captureCorner = Instance.new("UICorner")
captureCorner.Parent = captureBtn
captureCorner.CornerRadius = UDim.new(0, 8)

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Position = UDim2.new(0, 10, 1, -25)
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "📊 Pronto"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = frame

-- Função para atualizar a lista
local function UpdatePetList(petList)
    print("🔄 Atualizando lista...")
    
    -- Limpa o container
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    if not petList or #petList == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 40)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "❌ Nenhum pet"
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.TextSize = 16
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Parent = container
        statusLabel.Text = "📊 0 pets"
        return
    end
    
    -- Cria os labels
    for _, petName in pairs(petList) do
        local petLabel = Instance.new("TextLabel")
        petLabel.Size = UDim2.new(1, 0, 0, 35)
        petLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 70)
        petLabel.BackgroundTransparency = 0.3
        petLabel.Text = "🐾 " .. petName
        petLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        petLabel.TextSize = 14
        petLabel.Font = Enum.Font.Gotham
        petLabel.Parent = container
        
        local petCorner = Instance.new("UICorner")
        petCorner.Parent = petLabel
        petCorner.CornerRadius = UDim.new(0, 8)
    end
    
    -- Ajusta o canvas
    list.CanvasSize = UDim2.new(0, 0, 0, #petList * 40 + 10)
    statusLabel.Text = "📊 " .. #petList .. " pets"
end

-- Função para atualizar
local function RefreshPets()
    statusLabel.Text = "🔄 Atualizando..."
    PetEvent:FireServer("ListPets")
end

-- Eventos do servidor
PetEvent.OnClientEvent:Connect(function(action, data)
    print("📡 Evento recebido:", action)
    
    if action == "PetList" then
        UpdatePetList(data)
        statusLabel.Text = "✅ Atualizado!"
        task.wait(1)
        local count = data and #data or 0
        statusLabel.Text = "📊 " .. count .. " pets"
    end
    
    if action == "Notification" then
        statusLabel.Text = data
        print("📢", data)
        task.wait(2)
        RefreshPets()
    end
end)

-- Botão de capturar
captureBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = "🎯 Procurando pets..."
    
    local nearestPet = nil
    local nearestDist = math.huge
    
    -- Procura por pets no workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("ProximityPrompt") then
            if obj ~= player.Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local charHrp = player.Character.HumanoidRootPart
                    local dist = (charHrp.Position - hrp.Position).Magnitude
                    
                    if dist < nearestDist and dist < 50 then
                        nearestDist = dist
                        nearestPet = obj
                    end
                end
            end
        end
    end
    
    if nearestPet then
        statusLabel.Text = "🎯 Capturando: " .. nearestPet.Name
        
        -- Teleporta para o pet
        local charHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if charHrp then
            local hrp = nearestPet:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targetPos = hrp.Position + Vector3.new(0, 3, 0)
                charHrp.CFrame = CFrame.new(targetPos)
                task.wait(0.5)
            end
        end
        
        -- Tenta ativar o prompt
        local prompt = nearestPet:FindFirstChild("ProximityPrompt")
        if prompt then
            prompt:InputHoldBegin(player)
            task.wait(0.5)
            prompt:InputHoldEnd(player)
            statusLabel.Text = "✅ Capturando..."
        end
    else
        statusLabel.Text = "❌ Nenhum pet próximo!"
    end
end)

-- Botão de atualizar
refreshBtn.MouseButton1Click:Connect(RefreshPets)

-- Observa a pasta Pets
local playerPets = player:WaitForChild("Pets")
playerPets.ChildAdded:Connect(function()
    print("➕ Pet adicionado!")
    RefreshPets()
end)
playerPets.ChildRemoved:Connect(function()
    print("➖ Pet removido!")
    RefreshPets()
end)

-- Inicializa
task.wait(0.5)
RefreshPets()

print("✅ GUI DE PETS INICIADA!")
print("📌 Use os botões para capturar e atualizar")
