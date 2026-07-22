--[[
    SIX SEVEN - CAPTURA COM BARRINHA (FUNCIONAL)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - BARRINHA...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Config = {
    Delay = 5.0,
    TotalClicks = 80,      -- Quantos cliques para encher a barra
    ClickSpeed = 0.015,    -- Velocidade dos cliques
    TeleportDelay = 0.3,
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local autoAtivo = false
local espAtivo = false
local processando = false
local capturados = {}
local totalCapturados = 0

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
                            table.insert(pets, obj)
                        end
                    end
                end
            end
        end
    end
    return pets
end

-- ========================================
-- FUNÇÃO PARA CLICAR NA TELA
-- ========================================
local function Clicar()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.015)
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
-- FUNÇÃO PARA PRESSIONAR TECLA
-- ========================================
local function PressionarTecla(tecla)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, tecla, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, tecla, false, game)
    end)
end

-- ========================================
-- FUNÇÃO PARA EQUIPAR LASSO (TECLA 1)
-- ========================================
local function EquiparLasso()
    print("🎯 Equipando lasso (Tecla 1)...")
    PressionarTecla(Enum.KeyCode.One)
    task.wait(0.3)
end

-- ========================================
-- FUNÇÃO PARA LANÇAR LASSO NO PET
-- ========================================
local function LancarLasso(pet)
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    print("🎯 Lançando lasso no pet: " .. pet.Name)
    
    -- Move o mouse para o pet
    local camera = Workspace.CurrentCamera
    if not camera then return false end
    
    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        -- Teleporta mais perto
        if RootPart then
            pcall(function()
                RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
            end)
            task.wait(0.3)
        end
        pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then return false end
    end
    
    -- Move o mouse e clica para lançar
    MoverMouse(pos.X, pos.Y)
    task.wait(0.15)
    Clicar() -- LANÇA O LASSO!
    task.wait(0.3)
    
    return true
end

-- ========================================
-- FUNÇÃO PARA CLICAR RÁPIDO (ENCHE A BARRINHA)
-- ========================================
local function EncherBarra()
    print("🖱️ Enchendo a barra de captura...")
    status.Text = "🔄 Enchendo barra..."
    
    -- Clica várias vezes rapidamente
    for i = 1, Config.TotalClicks do
        Clicar()
        
        -- Mostra progresso a cada 10 cliques
        if i % 10 == 0 then
            print("  📊 Progresso: " .. i .. "/" .. Config.TotalClicks)
        end
        
        task.wait(Config.ClickSpeed)
    end
    
    print("✅ Barra cheia!")
    status.Text = "✅ Barra cheia!"
    return true
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR PET
-- ========================================
local function CapturarPet(pet)
    if processando then return false end
    if capturados[pet] then return false end
    if not pet then return false end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    processando = true
    print("\n🎯 CAPTURANDO: " .. pet.Name)
    status.Text = "🎯 Capturando: " .. pet.Name
    
    -- 1. Teleporta para o pet
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- 2. Equipa o lasso (tecla 1)
    EquiparLasso()
    task.wait(0.2)
    
    -- 3. Lança o lasso no pet
    local sucesso = LancarLasso(pet)
    if not sucesso then
        print("❌ Falhou ao lançar lasso")
        processando = false
        status.Text = "❌ Falhou ao lançar"
        return false
    end
    
    task.wait(0.5)
    
    -- 4. CLICA RÁPIDO PARA ENCHER A BARRINHA!
    EncherBarra()
    
    task.wait(0.5)
    
    -- 5. Verifica se capturou
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
    
    -- Verifica se o pet foi destruído
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
    frame.Size = UDim2.new(0, 260, 0, 220)
    frame.Position = UDim2.new(0.5, -130, 0.5, -110)
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
    
    -- Informação da barra
    local info = Instance.new("TextLabel")
    info.Parent = frame
    info.Size = UDim2.new(0.9, 0, 0, 20)
    info.Position = UDim2.new(0.05, 0, 0.18, 0)
    info.BackgroundTransparency = 1
    info.Text = "🖱️ " .. Config.TotalClicks .. " cliques por pet"
    info.TextColor3 = Color3.fromRGB(100, 200, 255)
    info.TextSize = 12
    info.Font = Enum.Font.Gotham
    
    -- ESP
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
    
    -- AUTO
    local btnAuto = Instance.new("TextButton")
    btnAuto.Parent = frame
    btnAuto.Size = UDim2.new(0.8, 0, 0, 30)
    btnAuto.Position = UDim2.new(0.1, 0, 0.5, 0)
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
    btnTeste.Parent = frame
    btnTeste.Size = UDim2.new(0.8, 0, 0, 30)
    btnTeste.Position = UDim2.new(0.1, 0, 0.7, 0)
    btnTeste.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
    btnTeste.Text = "🎯 TESTAR CAPTURA"
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
    statusLabel.Position = UDim2.new(0.05, 0, 0.88, 0)
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
print("  ✧ SIX SEVEN - CAPTURA COM BARRINHA")
print("========================================")
print("  📌 COMO FUNCIONA:")
print("  1. Teleporta para o pet")
print("  2. Equipa lasso (tecla 1)")
print("  3. Clica no pet (lança lasso)")
print("  4. CLICA " .. Config.TotalClicks .. "x na tela")
print("  5. A barrinha enche → Pet capturado!")
print("========================================")

CriarMenu()

print("✅ SCRIPT CARREGADO!")
print("📌 Teste primeiro com o botão TESTAR CAPTURA")
