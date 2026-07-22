--[[
    SIX SEVEN - VERSÃO ULTRA SIMPLES (SEM ERROS)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO VERSÃO SIMPLES...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- VARIÁVEIS
-- ========================================
local autoAtivo = false
local capturados = {}
local total = 0
local processando = false
local espAtivo = false

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
-- FUNÇÃO PARA CLICAR
-- ========================================
local function Clicar()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
    end)
end

-- ========================================
-- FUNÇÃO PARA MOVER MOUSE
-- ========================================
local function MoverMouse(x, y)
    pcall(function()
        VirtualInputManager:SendMouseMovement(x, y, Enum.VirtualKeyMode.Delta, game)
    end)
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR (SIMPLES)
-- ========================================
local function CapturarPet(pet)
    if processando then return false end
    if capturados[pet] then return false end
    if not pet then return false end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    processando = true
    print("🎯 CAPTURANDO: " .. pet.Name)
    status.Text = "🎯 Capturando: " .. pet.Name
    
    -- 1. Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- 2. Tecla 1 (lasso)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end)
    task.wait(0.3)
    
    -- 3. Clica no centro (ativa lasso)
    local camera = Workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        MoverMouse(viewport.X/2, viewport.Y/2)
        task.wait(0.1)
        Clicar()
        task.wait(0.3)
    end
    
    -- 4. Mira no pet
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            MoverMouse(pos.X, pos.Y)
            task.wait(0.2)
        end
    end
    
    -- 5. Lança lasso
    Clicar()
    task.wait(0.5)
    
    -- 6. Clica 50x para encher a barra
    print("🔄 Enchendo barra...")
    for i = 1, 50 do
        Clicar()
        if i % 10 == 0 then
            print("  " .. i .. "/50 cliques")
        end
        task.wait(0.02)
    end
    
    task.wait(0.5)
    
    -- 7. Verifica se capturou
    local pasta = Player:FindFirstChild("Pets")
    if pasta then
        for _, p in pairs(pasta:GetChildren()) do
            if p.Name == pet.Name then
                capturados[pet] = true
                total = total + 1
                processando = false
                print("✅ CAPTUROU: " .. pet.Name)
                status.Text = "✅ Capturou: " .. pet.Name
                return true
            end
        end
    end
    
    if not pet.Parent then
        capturados[pet] = true
        total = total + 1
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
                task.wait(5)
            else
                status.Text = "⏳ Procurando pets..."
                task.wait(1)
            end
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
-- CRIAR MENU
-- ========================================
local function CriarMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SixSeven"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 240, 0, 180)
    frame.Position = UDim2.new(0.5, -120, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true
    
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
    
    -- Botão ESP
    local btnESP = Instance.new("TextButton")
    btnESP.Parent = frame
    btnESP.Size = UDim2.new(0.8, 0, 0, 30)
    btnESP.Position = UDim2.new(0.1, 0, 0.3, 0)
    btnESP.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnESP.Text = "🔴 ESP"
    btnESP.TextColor3 = Color3.new(1, 1, 1)
    btnESP.TextSize = 14
    btnESP.Font = Enum.Font.GothamBold
    btnESP.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = btnESP
    espCorner.CornerRadius = UDim.new(0, 8)
    
    -- Botão AUTO
    local btnAuto = Instance.new("TextButton")
    btnAuto.Parent = frame
    btnAuto.Size = UDim2.new(0.8, 0, 0, 30)
    btnAuto.Position = UDim2.new(0.1, 0, 0.55, 0)
    btnAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnAuto.Text = "🔴 AUTO"
    btnAuto.TextColor3 = Color3.new(1, 1, 1)
    btnAuto.TextSize = 14
    btnAuto.Font = Enum.Font.GothamBold
    btnAuto.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = btnAuto
    autoCorner.CornerRadius = UDim.new(0, 8)
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    statusLabel.Position = UDim2.new(0.05, 0, 0.8, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    
    -- Eventos
    btnESP.MouseButton1Click:Connect(function()
        espAtivo = not espAtivo
        btnESP.Text = espAtivo and "🟢 ESP" or "🔴 ESP"
        btnESP.BackgroundColor3 = espAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
        AtualizarESP()
        
        task.spawn(function()
            while espAtivo do
                AtualizarESP()
                task.wait(1)
            end
        end)
    end)
    
    btnAuto.MouseButton1Click:Connect(function()
        autoAtivo = not autoAtivo
        btnAuto.Text = autoAtivo and "🟢 AUTO" or "🔴 AUTO"
        btnAuto.BackgroundColor3 = autoAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
        statusLabel.Text = autoAtivo and "🔄 Auto ligado" or "⏹️ Auto desligado"
        
        if autoAtivo then
            task.spawn(LoopAuto)
        end
    end)
    
    -- Monitoramento
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #EncontrarPets()
            if not autoAtivo and not processando then
                statusLabel.Text = "📊 Pets: " .. count .. " | Capturados: " .. total
            end
        end
    end)
    
    return gui
end

-- ========================================
-- INICIAR
-- ========================================
print("========================================")
print("  ✅ SCRIPT CARREGADO!")
print("  📌 Clique em ESP para ver os pets")
print("  📌 Clique em AUTO para capturar")
print("========================================")

CriarMenu()
