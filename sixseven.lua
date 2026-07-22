--[[
    SIX SEVEN - ULTRA SIMPLES (APENAS CLICKS)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - ULTRA SIMPLES...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Config = {
    Delay = 5.0,
    TotalClicks = 80,
    ClickSpeed = 0.015,
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local espAtivo = false
local autoAtivo = false
local processando = false
local capturados = {}
local totalCapturados = 0
local menuAberto = true

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
                        if not nome:find("tree") and not nome:find("rock") then
                            if not nome:find("spawn") and not nome:find("platform") then
                                table.insert(pets, obj)
                            end
                        end
                    end
                end
            end
        end
    end
    return pets
end

-- ========================================
-- FUNÇÕES DE CLICK
-- ========================================
local function Clicar()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.015)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
    end)
end

local function MoverMouse(x, y)
    pcall(function()
        VirtualInputManager:SendMouseMovement(x, y, Enum.VirtualKeyMode.Delta, game)
    end)
end

local function PressionarTecla(tecla)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, tecla, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, tecla, false, game)
    end)
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR PET (SÓ CLICK)
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
    
    -- 1. Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- 2. Tecla 1 (lasso)
    PressionarTecla(Enum.KeyCode.One)
    task.wait(0.3)
    
    -- 3. Move mouse para o pet
    local camera = Workspace.CurrentCamera
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            MoverMouse(pos.X, pos.Y)
            task.wait(0.15)
        end
    end
    
    -- 4. Clica no pet (lança lasso)
    Clicar()
    task.wait(0.5)
    
    -- 5. Clica 80x na tela
    for i = 1, Config.TotalClicks do
        Clicar()
        if i % 10 == 0 then
            print("  " .. i .. "/" .. Config.TotalClicks)
        end
        task.wait(Config.ClickSpeed)
    end
    
    task.wait(0.5)
    
    -- 6. Verifica captura
    local pasta = Player:FindFirstChild("Pets")
    if pasta then
        for _, p in pairs(pasta:GetChildren()) do
            if p.Name == pet.Name then
                capturados[pet] = true
                totalCapturados = totalCapturados + 1
                processando = false
                print("✅ CAPTUROU: " .. pet.Name)
                status.Text = "✅ Capturou: " .. pet.Name
                return true
            end
        end
    end
    
    if not pet.Parent then
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
                task.wait(Config.Delay)
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
    frame.Size = UDim2.new(0, 240, 0, 190)
    frame.Position = UDim2.new(0.5, -120, 0.5, -95)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 12)
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Parent = frame
    titulo.Size = UDim2.new(1, -40, 0, 35)
    titulo.Position = UDim2.new(0, 10, 0, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "✧ SIX SEVEN"
    titulo.TextColor3 = Color3.fromRGB(200, 150, 255)
    titulo.TextSize = 18
    titulo.Font = Enum.Font.GothamBold
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Minimizar
    local btnMin = Instance.new("TextButton")
    btnMin.Parent = frame
    btnMin.Size = UDim2.new(0, 30, 0, 30)
    btnMin.Position = UDim2.new(1, -35, 0, 2)
    btnMin.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    btnMin.Text = "─"
    btnMin.TextColor3 = Color3.new(1, 1, 1)
    btnMin.TextSize = 18
    btnMin.Font = Enum.Font.GothamBold
    btnMin.BorderSizePixel = 0
    
    local minCorner = Instance.new("UICorner")
    minCorner.Parent = btnMin
    minCorner.CornerRadius = UDim.new(0, 6)
    
    -- Fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Parent = frame
    btnFechar.Size = UDim2.new(0, 30, 0, 30)
    btnFechar.Position = UDim2.new(1, -70, 0, 2)
    btnFechar.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    btnFechar.Text = "✕"
    btnFechar.TextColor3 = Color3.new(1, 1, 1)
    btnFechar.TextSize = 14
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.BorderSizePixel = 0
    
    local fecharCorner = Instance.new("UICorner")
    fecharCorner.Parent = btnFechar
    fecharCorner.CornerRadius = UDim.new(0, 6)
    
    -- Info
    local info = Instance.new("TextLabel")
    info.Parent = frame
    info.Size = UDim2.new(0.9, 0, 0, 20)
    info.Position = UDim2.new(0.05, 0, 0.18, 0)
    info.BackgroundTransparency = 1
    info.Text = "🖱️ " .. Config.TotalClicks .. " cliques/pet"
    info.TextColor3 = Color3.fromRGB(100, 200, 255)
    info.TextSize = 12
    info.Font = Enum.Font.Gotham
    
    -- Container
    local container = Instance.new("Frame")
    container.Parent = frame
    container.Size = UDim2.new(0.9, 0, 0.5, 0)
    container.Position = UDim2.new(0.05, 0, 0.28, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    
    -- ESP
    local btnESP = Instance.new("TextButton")
    btnESP.Parent = container
    btnESP.Size = UDim2.new(1, 0, 0, 30)
    btnESP.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnESP.Text = "🔴 ESP"
    btnESP.TextColor3 = Color3.new(1, 1, 1)
    btnESP.TextSize = 14
    btnESP.Font = Enum.Font.GothamBold
    btnESP.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = btnESP
    espCorner.CornerRadius = UDim.new(0, 8)
    
    -- AUTO
    local btnAuto = Instance.new("TextButton")
    btnAuto.Parent = container
    btnAuto.Size = UDim2.new(1, 0, 0, 30)
    btnAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnAuto.Text = "🔴 AUTO"
    btnAuto.TextColor3 = Color3.new(1, 1, 1)
    btnAuto.TextSize = 14
    btnAuto.Font = Enum.Font.GothamBold
    btnAuto.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = btnAuto
    autoCorner.CornerRadius = UDim.new(0, 8)
    
    -- TESTE
    local btnTeste = Instance.new("TextButton")
    btnTeste.Parent = container
    btnTeste.Size = UDim2.new(1, 0, 0, 30)
    btnTeste.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
    btnTeste.Text = "🎯 TESTAR"
    btnTeste.TextColor3 = Color3.new(1, 1, 1)
    btnTeste.TextSize = 14
    btnTeste.Font = Enum.Font.GothamBold
    btnTeste.BorderSizePixel = 0
    
    local testeCorner = Instance.new("UICorner")
    testeCorner.Parent = btnTeste
    testeCorner.CornerRadius = UDim.new(0, 8)
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    statusLabel.Position = UDim2.new(0.05, 0, 0.85, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    
    -- Botão flutuante
    local btnFloat = Instance.new("TextButton")
    btnFloat.Parent = gui
    btnFloat.Size = UDim2.new(0, 45, 0, 45)
    btnFloat.Position = UDim2.new(0.93, -22, 0.93, -22)
    btnFloat.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    btnFloat.Text = "✧"
    btnFloat.TextColor3 = Color3.new(1, 1, 1)
    btnFloat.TextSize = 24
    btnFloat.Font = Enum.Font.GothamBold
    btnFloat.BorderSizePixel = 0
    btnFloat.Visible = false
    
    local floatCorner = Instance.new("UICorner")
    floatCorner.Parent = btnFloat
    floatCorner.CornerRadius = UDim.new(1, 0)
    
    local function Minimizar()
        frame.Visible = false
        btnFloat.Visible = true
    end
    
    local function Abrir()
        frame.Visible = true
        btnFloat.Visible = false
    end
    
    btnMin.MouseButton1Click:Connect(Minimizar)
    btnFloat.MouseButton1Click:Connect(Abrir)
    btnFechar.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
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
    
    btnTeste.MouseButton1Click:Connect(function()
        print("🎯 TESTANDO CAPTURA...")
        local pets = EncontrarPets()
        if #pets > 0 then
            CapturarPet(pets[1])
        else
            print("❌ Nenhum pet encontrado!")
            statusLabel.Text = "❌ Nenhum pet"
        end
    end)
    
    -- Monitoramento
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #EncontrarPets()
            if not autoAtivo and not processando then
                statusLabel.Text = "📊 Pets: " .. count .. " | Capturados: " .. totalCapturados
            end
        end
    end)
    
    return gui
end

-- ========================================
-- INICIAR
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - ULTRA SIMPLES")
print("========================================")
print("  📌 SÓ CLICK:")
print("  1. Teleporta")
print("  2. Tecla 1")
print("  3. Clica no pet")
print("  4. 80 cliques na tela")
print("========================================")

CriarMenu()

print("✅ PRONTO!")
