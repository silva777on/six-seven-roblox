--[[
    SCRIPT SIMPLES PARA CAPTURAR PETS
    Game: [🍎] Capture e Domestique!
]]

print("🔄 INICIANDO SCRIPT...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- CRIAR MENU SIMPLES
-- ========================================
local function CriarMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SixSeven"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 250, 0, 180)
    frame.Position = UDim2.new(0.5, -125, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 12)
    
    local titulo = Instance.new("TextLabel")
    titulo.Parent = frame
    titulo.Size = UDim2.new(1, 0, 0, 35)
    titulo.BackgroundColor3 = Color3.fromRGB(80, 0, 200)
    titulo.BackgroundTransparency = 0.3
    titulo.Text = "✧ SIX SEVEN"
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.TextSize = 18
    titulo.Font = Enum.Font.GothamBold
    
    local botaoESP = Instance.new("TextButton")
    botaoESP.Parent = frame
    botaoESP.Size = UDim2.new(0.8, 0, 0, 30)
    botaoESP.Position = UDim2.new(0.1, 0, 0.3, 0)
    botaoESP.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    botaoESP.Text = "🔴 ESP (OFF)"
    botaoESP.TextColor3 = Color3.new(1, 1, 1)
    botaoESP.TextSize = 14
    botaoESP.Font = Enum.Font.GothamBold
    botaoESP.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = botaoESP
    espCorner.CornerRadius = UDim.new(0, 8)
    
    local botaoAuto = Instance.new("TextButton")
    botaoAuto.Parent = frame
    botaoAuto.Size = UDim2.new(0.8, 0, 0, 30)
    botaoAuto.Position = UDim2.new(0.1, 0, 0.55, 0)
    botaoAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    botaoAuto.Text = "🔴 AUTO (OFF)"
    botaoAuto.TextColor3 = Color3.new(1, 1, 1)
    botaoAuto.TextSize = 14
    botaoAuto.Font = Enum.Font.GothamBold
    botaoAuto.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = botaoAuto
    autoCorner.CornerRadius = UDim.new(0, 8)
    
    local status = Instance.new("TextLabel")
    status.Parent = frame
    status.Size = UDim2.new(0.9, 0, 0, 20)
    status.Position = UDim2.new(0.05, 0, 0.8, 0)
    status.BackgroundTransparency = 1
    status.Text = "📊 Pronto"
    status.TextColor3 = Color3.fromRGB(150, 150, 200)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    
    return gui, botaoESP, botaoAuto, status
end

local gui, btnESP, btnAuto, status = CriarMenu()

-- ========================================
-- VARIÁVEIS
-- ========================================
local espAtivo = false
local autoAtivo = false
local capturados = {}
local totalCapturados = 0
local processando = false

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function EncontrarPets()
    local pets = {}
    local char = Player.Character
    if not char then return pets end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= char and not Players:GetPlayerFromCharacter(obj) then
                local nome = obj.Name:lower()
                if not nome:find("base") and not nome:find("floor") and not nome:find("wall") then
                    if not nome:find("npc") and not nome:find("humano") and not nome:find("player") then
                        table.insert(pets, obj)
                    end
                end
            end
        end
    end
    return pets
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR (SIMPLES)
-- ========================================
local function CapturarPet(pet)
    if processando then return false end
    if capturados[pet] then return false end
    if not pet or not pet:IsA("Model") then return false end
    
    processando = true
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        processando = false
        return false 
    end
    
    print("🎯 CAPTURANDO: " .. pet.Name)
    status.Text = "🎯 Capturando: " .. pet.Name
    
    -- Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- Tenta capturar
    local sucesso = false
    
    -- Método 1: Remote
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            pcall(function()
                obj:FireServer("Capture", pet.Name, pet)
                print("📡 Remote enviado: " .. obj.Name)
                task.wait(0.3)
            end)
        end
    end
    
    -- Método 2: ProximityPrompt
    local prompt = pet:FindFirstChild("ProximityPrompt")
    if prompt then
        pcall(function()
            prompt:InputHoldBegin(Player)
            task.wait(0.3)
            prompt:InputHoldEnd(Player)
            print("🎯 Prompt ativado")
            task.wait(0.3)
        end)
    end
    
    -- Método 3: Clique
    local camera = Workspace.CurrentCamera
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            pcall(function()
                VirtualInputManager:SendMouseMovement(pos.X, pos.Y, Enum.VirtualKeyMode.Delta, game)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
                print("🖱️ Clique enviado")
                task.wait(0.2)
                
                -- Cliques rápidos
                for i = 1, 20 do
                    VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
                end
            end)
        end
    end
    
    -- Verifica se capturou
    local pasta = Player:FindFirstChild("Pets")
    if pasta and pasta:FindFirstChild(pet.Name) then
        capturados[pet] = true
        totalCapturados = totalCapturados + 1
        processando = false
        print("✅ CAPTUROU: " .. pet.Name)
        status.Text = "✅ Capturou: " .. pet.Name
        return true
    end
    
    processando = false
    print("❌ Falhou: " .. pet.Name)
    status.Text = "❌ Falhou: " .. pet.Name
    return false
end

-- ========================================
-- LOOP AUTO
-- ========================================
local function LoopAuto()
    while autoAtivo do
        if processando then
            task.wait(0.5)
        else
            local pets = EncontrarPets()
            local alvo = nil
            local distMin = math.huge
            
            for _, pet in pairs(pets) do
                if not capturados[pet] then
                    local hrp = pet:FindFirstChild("HumanoidRootPart")
                    if hrp and RootPart then
                        local dist = (RootPart.Position - hrp.Position).Magnitude
                        if dist < distMin then
                            distMin = dist
                            alvo = pet
                        end
                    end
                end
            end
            
            if alvo then
                CapturarPet(alvo)
            end
            task.wait(5)
        end
    end
end

-- ========================================
-- ESP
-- ========================================
local function AtualizarESP()
    if not espAtivo then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("ESP_Highlight") then
                obj.ESP_Highlight:Destroy()
            end
        end
        return
    end
    
    local pets = EncontrarPets()
    for _, pet in pairs(pets) do
        if pet and pet:IsA("Model") then
            local hrp = pet:FindFirstChild("HumanoidRootPart")
            if hrp then
                local highlight = pet:FindFirstChild("ESP_Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESP_Highlight"
                    highlight.Parent = pet
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.FillTransparency = 0.3
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0.1
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            end
        end
    end
end

-- ========================================
-- BOTÕES
-- ========================================
btnESP.MouseButton1Click:Connect(function()
    espAtivo = not espAtivo
    btnESP.Text = espAtivo and "🟢 ESP (ON)" or "🔴 ESP (OFF)"
    btnESP.BackgroundColor3 = espAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
    AtualizarESP()
    
    -- Loop do ESP
    task.spawn(function()
        while espAtivo do
            AtualizarESP()
            task.wait(1)
        end
    end)
end)

btnAuto.MouseButton1Click:Connect(function()
    autoAtivo = not autoAtivo
    btnAuto.Text = autoAtivo and "🟢 AUTO (ON)" or "🔴 AUTO (OFF)"
    btnAuto.BackgroundColor3 = autoAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
    status.Text = autoAtivo and "🔄 Auto ligado" or "⏹️ Auto desligado"
    
    if autoAtivo then
        task.spawn(LoopAuto)
    end
end)

-- ========================================
-- MONITORAMENTO
-- ========================================
task.spawn(function()
    while true do
        task.wait(2)
        local count = #EncontrarPets()
        if not autoAtivo and not processando then
            status.Text = "📊 Pets: " .. count .. " | Capturados: " .. totalCapturados
        end
    end
end)

print("========================================")
print("  ✅ SCRIPT PRONTO!")
print("  📌 Clique em ESP para ver os pets")
print("  📌 Clique em AUTO para capturar")
print("========================================")
