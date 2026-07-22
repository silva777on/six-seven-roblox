--[[
    SIX SEVEN - VERSÃO ULTRA SIMPLES
    Game: [🍎] Capture e Domestique!
]]

print("🔄 INICIANDO...")

-- ========================================
-- BIBLIOTECAS
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- VARIAVEIS
-- ========================================
local auto = false
local esp = false
local captured = {}
local total = 0
local processando = false

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function FindPets()
    local pets = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                local nome = obj.Name:lower()
                if not nome:find("base") and not nome:find("floor") and not nome:find("wall") then
                    if not nome:find("npc") and not nome:find("humano") then
                        table.insert(pets, obj)
                    end
                end
            end
        end
    end
    return pets
end

-- ========================================
-- TELEPORTAR
-- ========================================
local function Teleport(pos)
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(pos)
        end)
    end
end

-- ========================================
-- FUNÇÃO PARA CLICAR
-- ========================================
local function Click()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
    end)
end

-- ========================================
-- FUNÇÃO PARA CLICAR NO PET
-- ========================================
local function ClickOnPet(pet)
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    pcall(function()
        VirtualInputManager:SendMouseMovement(pos.X, pos.Y, Enum.VirtualKeyMode.Delta, game)
        task.wait(0.05)
        Click()
    end)
    
    return true
end

-- ========================================
-- CAPTURAR PET (SIMPLES)
-- ========================================
local function Capture(pet)
    if processando then return false end
    if captured[pet] then return false end
    if not pet or not pet:IsA("Model") then return false end
    
    processando = true
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        processando = false
        return false 
    end
    
    print("🎯 CAPTURANDO: " .. pet.Name)
    
    -- 1. Teleporta
    Teleport(hrp.Position + Vector3.new(0, 3, 0))
    task.wait(0.3)
    
    -- 2. Tenta Remote
    local remote = ReplicatedStorage:FindFirstChild("PetEvent") 
        or ReplicatedStorage:FindFirstChild("Capture")
        or ReplicatedStorage:FindFirstChild("RemoteEvent")
    
    if remote then
        pcall(function()
            remote:FireServer("Capture", pet.Name, pet)
            print("📡 Remote enviado")
            task.wait(0.5)
        end)
    end
    
    -- 3. Tenta ProximityPrompt
    local prompt = pet:FindFirstChild("ProximityPrompt")
    if prompt then
        pcall(function()
            prompt:InputHoldBegin(Player)
            task.wait(0.3)
            prompt:InputHoldEnd(Player)
            print("🎯 Prompt ativado")
        end)
    end
    
    -- 4. Clica no pet
    ClickOnPet(pet)
    task.wait(0.2)
    
    -- 5. Cliques rapidos
    for i = 1, 20 do
        Click()
        task.wait(0.03)
    end
    
    -- 6. Verifica se capturou
    local folder = Player:FindFirstChild("Pets")
    if folder and folder:FindFirstChild(pet.Name) then
        captured[pet] = true
        total = total + 1
        processando = false
        print("✅ CAPTUROU: " .. pet.Name)
        return true
    end
    
    processando = false
    return false
end

-- ========================================
-- LOOP AUTO
-- ========================================
local function AutoLoop()
    while auto do
        if processando then
            task.wait(0.5)
        else
            local pets = FindPets()
            local alvo = nil
            local distMin = math.huge
            
            for _, pet in pairs(pets) do
                if not captured[pet] then
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
                Capture(alvo)
            end
            task.wait(5)
        end
    end
end

-- ========================================
-- CRIAR MENU (MUITO SIMPLES)
-- ========================================
local function CriarMenu()
    print("🎨 CRIANDO MENU...")
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "SixSeven"
    gui.ResetOnSpawn = false
    
    -- Tenta diferentes parents
    local success, err = pcall(function()
        gui.Parent = CoreGui
    end)
    
    if not success then
        pcall(function()
            gui.Parent = Player:WaitForChild("PlayerGui")
        end)
    end
    
    if not gui.Parent then
        print("❌ ERRO: Não foi possível criar a GUI")
        return
    end
    
    print("✅ GUI criada em: " .. gui.Parent.Name)
    
    -- Frame principal
    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 280, 0, 200)
    frame.Position = UDim2.new(0.5, -140, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 12)
    
    -- Titulo
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(80, 0, 200)
    title.BackgroundTransparency = 0.3
    title.Text = "✧ SIX SEVEN"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.Parent = title
    titleCorner.CornerRadius = UDim.new(0, 12)
    
    -- Botão ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = frame
    espBtn.Size = UDim2.new(0.9, 0, 0, 35)
    espBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
    espBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    espBtn.Text = "🔴 ESP"
    espBtn.TextColor3 = Color3.new(1, 1, 1)
    espBtn.TextSize = 16
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 8)
    
    -- Botão Auto
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = frame
    autoBtn.Size = UDim2.new(0.9, 0, 0, 35)
    autoBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
    autoBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    autoBtn.Text = "🔴 AUTO"
    autoBtn.TextColor3 = Color3.new(1, 1, 1)
    autoBtn.TextSize = 16
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 8)
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Parent = frame
    status.Size = UDim2.new(0.9, 0, 0, 25)
    status.Position = UDim2.new(0.05, 0, 0.7, 0)
    status.BackgroundTransparency = 1
    status.Text = "📊 Pronto"
    status.TextColor3 = Color3.fromRGB(150, 150, 200)
    status.TextSize = 13
    status.Font = Enum.Font.Gotham
    
    -- Funções dos botões
    espBtn.MouseButton1Click:Connect(function()
        esp = not esp
        espBtn.Text = esp and "🟢 ESP" or "🔴 ESP"
        espBtn.BackgroundColor3 = esp and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
        
        if esp then
            -- Cria ESP para todos os pets
            task.spawn(function()
                while esp do
                    for _, pet in pairs(FindPets()) do
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
                                    highlight.Enabled = true
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            -- Remove ESP
            for _, pet in pairs(workspace:GetDescendants()) do
                if pet:IsA("Model") then
                    local highlight = pet:FindFirstChild("ESP_Highlight")
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
        end
    end)
    
    autoBtn.MouseButton1Click:Connect(function()
        auto = not auto
        autoBtn.Text = auto and "🟢 AUTO" or "🔴 AUTO"
        autoBtn.BackgroundColor3 = auto and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
        
        if auto then
            task.spawn(AutoLoop)
            status.Text = "🔄 Auto ligado"
        else
            status.Text = "⏹️ Auto desligado"
        end
    end)
    
    -- Atualiza status
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindPets()
            status.Text = "📊 Pets: " .. count .. " | Capturados: " .. total
        end
    end)
    
    print("✅ MENU CRIADO COM SUCESSO!")
    return gui
end

-- ========================================
-- INICIAR
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - ULTRA SIMPLES")
print("========================================")
print("  📌 Clique em ESP para ver os pets")
print("  📌 Clique em AUTO para capturar")
print("========================================")

-- Cria o menu
task.wait(0.5)
local gui = CriarMenu()

if gui then
    print("✅ SCRIPT PRONTO!")
else
    print("❌ ERRO AO CRIAR MENU!")
    print("📌 Tente executar novamente")
end

-- Monitora respawn
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    print("🔄 Respawnou!")
end)

print("========================================")
print("  ✅ FINALIZADO!")
print("========================================")
