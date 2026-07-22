--[[
    SISTEMA COMPLETO DE CAPTURA DE PETS
    - Servidor: Gerencia os pets
    - Cliente: Interface e interação
    - Pet: Script de captura
]]

-- ========================================
-- PARTE 1: SERVIDOR (Rodando no ServerScriptService)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Criar o evento se não existir
local PetEvent
if not ReplicatedStorage:FindFirstChild("PetEvent") then
    PetEvent = Instance.new("RemoteEvent")
    PetEvent.Name = "PetEvent"
    PetEvent.Parent = ReplicatedStorage
else
    PetEvent = ReplicatedStorage:FindFirstChild("PetEvent")
end

-- Quando um jogador entra, cria a pasta Pets
Players.PlayerAdded:Connect(function(player)
    local pets = Instance.new("Folder")
    pets.Name = "Pets"
    pets.Parent = player
    print("📁 Pasta Pets criada para: " .. player.Name)
end)

-- Evento de captura
PetEvent.OnServerEvent:Connect(function(player, action, petName, petModel)
    if action == "Capture" then
        local pets = player:FindFirstChild("Pets")
        
        if pets then
            -- Verifica se já tem esse pet
            local alreadyHas = false
            for _, pet in pairs(pets:GetChildren()) do
                if pet.Name == petName then
                    alreadyHas = true
                    break
                end
            end
            
            if not alreadyHas then
                -- Cria o pet
                local pet = Instance.new("StringValue")
                pet.Name = petName
                pet.Value = petName
                pet.Parent = pets
                
                print("🐾 " .. player.Name .. " capturou " .. petName)
                
                -- Envia notificação para o jogador
                local success, err = pcall(function()
                    local args = {
                        [1] = "Chat",
                        [2] = "📢 " .. player.Name .. " capturou " .. petName .. "!"
                    }
                    PetEvent:FireClient(player, "Notification", "✅ Pet capturado: " .. petName)
                end)
            else
                print("⚠️ " .. player.Name .. " já tem o pet " .. petName)
            end
        end
    end
    
    -- Ação para soltar pet
    if action == "Release" then
        local pets = player:FindFirstChild("Pets")
        if pets then
            local pet = pets:FindFirstChild(petName)
            if pet then
                pet:Destroy()
                print("📦 " .. player.Name .. " soltou " .. petName)
            end
        end
    end
    
    -- Ação para listar pets
    if action == "ListPets" then
        local pets = player:FindFirstChild("Pets")
        if pets then
            local petList = {}
            for _, pet in pairs(pets:GetChildren()) do
                table.insert(petList, pet.Name)
            end
            PetEvent:FireClient(player, "PetList", petList)
        end
    end
end)

print("✅ SISTEMA DE PETS INICIADO!")


-- ========================================
-- PARTE 2: SCRIPT DO PET (Colocar dentro de cada pet)
-- ========================================

--[[
    Coloque este script dentro de cada PET (Model)
    Exemplo: workspace.PetModel.Script
]]

local pet = script.Parent
local prompt = pet:WaitForChild("ProximityPrompt")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetEvent = ReplicatedStorage:WaitForChild("PetEvent")

-- Quando o jogador interage com o pet
prompt.Triggered:Connect(function(player)
    -- Verifica se o jogador já tem esse pet
    local pets = player:FindFirstChild("Pets")
    local alreadyHas = false
    
    if pets then
        for _, p in pairs(pets:GetChildren()) do
            if p.Name == pet.Name then
                alreadyHas = true
                break
            end
        end
    end
    
    if alreadyHas then
        -- Já tem esse pet
        local success, err = pcall(function()
            PetEvent:FireServer("Notification", "⚠️ Você já tem " .. pet.Name)
        end)
        print("⚠️ " .. player.Name .. " já tem " .. pet.Name)
        return
    end
    
    -- Captura o pet
    PetEvent:FireServer("Capture", pet.Name, pet)
    
    -- Animação de captura
    pet:FindFirstChild("HumanoidRootPart"):Destroy()
    
    -- Destroi o pet após 1 segundo
    task.wait(1)
    pet:Destroy()
end)

print("✅ PET " .. pet.Name .. " PRONTO PARA CAPTURA!")


-- ========================================
-- PARTE 3: INTERFACE DO JOGADOR (LocalScript dentro de StarterGui)
-- ========================================

local player = game.Players.LocalPlayer
local gui = script.Parent

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetEvent = ReplicatedStorage:WaitForChild("PetEvent")

-- Verifica se a GUI já existe
local existingGUI = player.PlayerGui:FindFirstChild("PetGUI")
if existingGUI then
    existingGUI:Destroy()
end

-- Cria a GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 350)
frame.Position = UDim2.new(0, 20, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Cantos arredondados
local frameCorner = Instance.new("UICorner")
frameCorner.Parent = frame
frameCorner.CornerRadius = UDim.new(0, 12)

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(120, 0, 255)
title.BackgroundTransparency = 0.3
title.Text = "🐾 MEUS PETS"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.Parent = title
titleCorner.CornerRadius = UDim.new(0, 12)

-- Lista de pets
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 10, 0, 60)
list.Size = UDim2.new(1, -20, 1, -120)
list.BackgroundTransparency = 1
list.Parent = frame
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = Color3.fromRGB(120, 0, 255)

-- Container para os pets
local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, 0)
container.BackgroundTransparency = 1
container.Parent = list

-- Layout dos pets
local layout = Instance.new("UIListLayout")
layout.Parent = container
layout.SortOrder = Enum.SortOrder.Name
layout.Padding = UDim.new(0, 5)

-- Botões inferiores
local buttonFrame = Instance.new("Frame")
buttonFrame.Position = UDim2.new(0, 10, 1, -50)
buttonFrame.Size = UDim2.new(1, -20, 0, 40)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = frame

-- Botão Atualizar
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.48, -5, 1, 0)
refreshBtn.Position = UDim2.new(0, 0, 0, 0)
refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
refreshBtn.Text = "🔄 Atualizar"
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.TextSize = 14
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = buttonFrame

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
captureBtn.Parent = buttonFrame

local captureCorner = Instance.new("UICorner")
captureCorner.Parent = captureBtn
captureCorner.CornerRadius = UDim.new(0, 8)

-- Label de status
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
        emptyLabel.Text = "❌ Nenhum pet capturado"
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
        petLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
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
    
    statusLabel.Text = "📊 " .. #petList .. " pets"
end

-- Função para capturar o pet mais próximo
local function CaptureNearestPet()
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
end

-- Atualiza a lista
local function RefreshPets()
    statusLabel.Text = "🔄 Atualizando..."
    PetEvent:FireServer("ListPets")
end

-- Recebe a lista de pets do servidor
PetEvent.OnClientEvent:Connect(function(action, data)
    if action == "PetList" then
        UpdatePetList(data)
        statusLabel.Text = "✅ Atualizado!"
        task.wait(1)
        statusLabel.Text = "📊 " .. #data .. " pets"
    end
    
    if action == "Notification" then
        statusLabel.Text = data
        task.wait(2)
        RefreshPets()
    end
end)

-- Botões
refreshBtn.MouseButton1Click:Connect(RefreshPets)
captureBtn.MouseButton1Click:Connect(CaptureNearestPet)

-- Atualiza automaticamente a cada 5 segundos
task.spawn(function()
    while true do
        task.wait(5)
        if screenGui and screenGui.Parent then
            RefreshPets()
        else
            break
        end
    end
end)

-- Atualiza quando um pet é capturado
local playerPets = player:WaitForChild("Pets")
playerPets.ChildAdded:Connect(function()
    RefreshPets()
end)
playerPets.ChildRemoved:Connect(function()
    RefreshPets()
end)

-- Inicializa
task.wait(1)
RefreshPets()

print("✅ GUI DE PETS INICIADA!")
