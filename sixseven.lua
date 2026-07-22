--[[
    Six Seven - Clique Rápido (VERSÃO SIMPLES)
    Game: [🍎] Capture e Domestique!
    Use comandos no chat!
]]

print("🔄 CARREGANDO SIX SEVEN - CLIQUE RÁPIDO...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ChatService = game:GetService("TextChatService") or game:GetService("Chat")

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
        ClickSpeed = 0.02,
        TotalClicks = 30
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
-- FUNÇÃO PARA EQUIPAR O LAÇO
-- ========================================
local function EquipLasso()
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
-- FUNÇÃO PARA ATIVAR O LAÇO
-- ========================================
local function ActivateLasso()
    pcall(function()
        local tool = Humanoid and Humanoid:FindFirstChild("ActiveTool")
        if tool then
            tool:Activate()
            print("🎯 Laço ativado!")
            task.wait(0.1)
            return true
        end
    end)
    
    return true
end

-- ========================================
-- FUNÇÃO PARA LANÇAR O LAÇO
-- ========================================
local function ThrowLasso(pet)
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    EquipLasso()
    task.wait(0.2)
    
    ActivateLasso()
    task.wait(0.2)
    
    local remote = ReplicatedStorage:FindFirstChild("CapturePet")
        or ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Capture")
        or ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Capture")
        or ReplicatedStorage:FindFirstChild("RemoteEvent")
    
    if remote then
        pcall(function() 
            remote:FireServer(pet)
            print("📡 Laço lançado via Remote!")
            task.wait(0.5)
            return true
        end)
    end
    
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
            print("🎯 Laço lançado no pet: " .. pet.Name)
            task.wait(0.5)
            return true
        end
    end)
    
    return true
}

-- ========================================
-- FUNÇÃO PARA CLICAR RÁPIDO
-- ========================================
local function RapidClick()
    print("🖱️ Iniciando cliques rápidos...")
    
    for i = 1, Settings.AutoCapture.TotalClicks do
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
            task.wait(Settings.AutoCapture.ClickSpeed)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
            
            if i % 10 == 0 then
                print("🖱️ Cliques: " .. i .. "/" .. Settings.AutoCapture.TotalClicks)
            end
        end)
    end
    
    print("✅ Cliques concluídos!")
    return true
end

-- ========================================
-- CAPTURAR PET
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
    
    local targetPos = hrp.Position + Vector3.new(0, 3, 0)
    SmoothTeleport(targetPos)
    task.wait(0.3)
    
    local success = ThrowLasso(pet)
    if not success then
        isProcessing = false
        return false
    end
    
    task.wait(0.5)
    
    print("🔄 Enchendo a barra de captura...")
    RapidClick()
    
    task.wait(1.0)
    
    isProcessing = false
    return true
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
        or ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("Release")
    
    if releaseRemote then
        pcall(function() 
            releaseRemote:FireServer(pet) 
            print("📦 Pet solto na base!")
        end)
        task.wait(0.3)
    end
    
    totalCaptured = totalCaptured + 1
    print("🏆 Total capturado: " .. totalCaptured)
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        task.spawn(function()
            if isProcessing then 
                task.wait(0.5)
                return 
            end
            
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
-- SISTEMA ESP (SIMPLIFICADO)
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
    
    espObjects[pet] = {
        Highlight = highlight
    }
    
    print("✅ ESP criado para: " .. pet.Name)
end

local function RemoveESP(pet)
    if espObjects[pet] then
        if espObjects[pet].Highlight then espObjects[pet].Highlight:Destroy() end
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
-- COMANDOS NO CHAT
-- ========================================
local function SendMessage(text)
    pcall(function()
        local chat = game:GetService("TextChatService")
        if chat and chat.TextChannels then
            local channel = chat.TextChannels:FindFirstChild("General") or chat.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(text)
                return
            end
        end
    end)
    
    -- Fallback: print no console
    print("📢 " .. text)
end

local function ShowHelp()
    print("========================================")
    print("  ✧ SIX SEVEN - COMANDOS")
    print("========================================")
    print("  !esp      - Ligar/Desligar ESP")
    print("  !auto     - Ligar/Desligar Auto Capture")
    print("  !delay X  - Mudar delay (ex: !delay 3)")
    print("  !status   - Mostrar status atual")
    print("  !help     - Mostrar esta mensagem")
    print("========================================")
    
    SendMessage("✧ Comandos: !esp, !auto, !delay X, !status, !help")
end

-- Processa comandos
local function ProcessCommand(msg)
    local cmd = msg:lower()
    
    if cmd == "!help" then
        ShowHelp()
        return true
    end
    
    if cmd == "!esp" then
        espActive = not espActive
        if espActive then 
            UpdateESP()
            print("🟢 ESP ATIVADO")
            SendMessage("🟢 ESP ATIVADO")
        else
            for pet, _ in pairs(espObjects) do RemoveESP(pet) end
            espObjects = {}
            print("🔴 ESP DESATIVADO")
            SendMessage("🔴 ESP DESATIVADO")
        end
        return true
    end
    
    if cmd == "!auto" then
        autoCapture = not autoCapture
        if autoCapture then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
            print("🟢 AUTO CAPTURE ATIVADO")
            SendMessage("🟢 AUTO CAPTURE ATIVADO")
        else
            autoCaptureRunning = false
            print("🔴 AUTO CAPTURE DESATIVADO")
            SendMessage("🔴 AUTO CAPTURE DESATIVADO")
        end
        return true
    end
    
    if cmd:match("^!delay") then
        local delay = tonumber(cmd:match("!(%d+)"))
        if delay then
            Settings.AutoCapture.Delay = math.max(delay, 0.5)
            print("⏱️ Delay alterado para: " .. Settings.AutoCapture.Delay .. "s")
            SendMessage("⏱️ Delay: " .. Settings.AutoCapture.Delay .. "s")
        end
        return true
    end
    
    if cmd == "!status" then
        local petCount = #FindAllPets()
        print("========================================")
        print("  📊 STATUS")
        print("  ESP: " .. (espActive and "🟢 ON" or "🔴 OFF"))
        print("  Auto Capture: " .. (autoCapture and "🟢 ON" or "🔴 OFF"))
        print("  Delay: " .. Settings.AutoCapture.Delay .. "s")
        print("  Pets encontrados: " .. petCount)
        print("  Total capturado: " .. totalCaptured)
        print("========================================")
        SendMessage("📊 ESP: " .. (espActive and "ON" or "OFF") .. " | Auto: " .. (autoCapture and "ON" or "OFF") .. " | Pets: " .. petCount)
        return true
    end
    
    return false
end

-- ========================================
-- MONITORAR CHAT
-- ========================================
local function SetupChatListener()
    -- Tenta diferentes formas de ouvir chat
    pcall(function()
        local chat = game:GetService("TextChatService")
        if chat and chat.TextChannels then
            local channel = chat.TextChannels:FindFirstChild("General") or chat.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel.MessageReceived:Connect(function(msg)
                    if msg.Text then
                        ProcessCommand(msg.Text)
                    end
                end)
                print("✅ Chat listener configurado (TextChatService)")
                return
            end
        end
    end)
    
    -- Fallback: Player.Chatted
    pcall(function()
        Player.Chatted:Connect(function(msg)
            ProcessCommand(msg)
        end)
        print("✅ Chat listener configurado (Player.Chatted)")
    end)
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - CLIQUE RÁPIDO")
print("========================================")
print("  📖 COMANDOS NO CHAT:")
print("  !esp      - Ligar/Desligar ESP")
print("  !auto     - Ligar/Desligar Auto Capture")
print("  !delay X  - Mudar delay")
print("  !status   - Mostrar status")
print("  !help     - Ajuda")
print("========================================")
print("  🖱️ " .. Settings.AutoCapture.TotalClicks .. " cliques em " .. Settings.AutoCapture.ClickSpeed .. "s")
print("========================================")

-- Configura listener de chat
SetupChatListener()

-- Monitoramento de pets
task.spawn(function()
    while true do
        task.wait(0.5)
        if espActive then
            UpdateESP()
        end
    end
end)

-- Monitorar respawn
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

-- Monitorar novos pets
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
            local name = obj.Name:lower()
            if not name:find("npc") and not name:find("humano") and not name:find("personagem") then
                print("🔍 Novo pet: " .. obj.Name)
                if espActive then
                    task.wait(0.1)
                    UpdateESP()
                end
            end
        end
    end
end)

print("========================================")
print("  ✅ PRONTO! Use os comandos no chat!")
print("  📌 Digite !help para ver os comandos")
print("========================================")

-- Mostra ajuda automaticamente
ShowHelp()
