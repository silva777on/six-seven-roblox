--[[
    SIX SEVEN - VERSÃO SIMPLES E FUNCIONAL
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Config = {
    TotalClicks = 80,
    Delay = 5.0,
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
-- FUNÇÕES DO JOGO
-- ========================================
local function EncontrarPets()
    local pets = {}
    local char = player.Character
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

local function CapturarPet(pet)
    if processando then return false end
    if capturados[pet] then return false end
    if not pet then return false end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    processando = true
    print("🎯 CAPTURANDO: " .. pet.Name)
    if statusLabel then statusLabel.Text = "🎯 " .. pet.Name end
    
    -- Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- Tecla 1
    PressionarTecla(Enum.KeyCode.One)
    task.wait(0.3)
    
    -- Move mouse para o pet
    local camera = Workspace.CurrentCamera
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            MoverMouse(pos.X, pos.Y)
            task.wait(0.15)
        end
    end
    
    -- Clica no pet
    Clicar()
    task.wait(0.5)
    
    -- Clica 80x
    for i = 1, Config.TotalClicks do
        Clicar()
        task.wait(Config.ClickSpeed)
    end
    
    task.wait(0.5)
    
    -- Verifica
    local pasta = player:FindFirstChild("Pets")
    if pasta then
        for _, p in pairs(pasta:GetChildren()) do
            if p.Name == pet.Name then
                capturados[pet] = true
                totalCapturados = totalCapturados + 1
                processando = false
                print("✅ CAPTUROU: " .. pet.Name)
                if statusLabel then statusLabel.Text = "✅ " .. pet.Name end
                return true
            end
        end
    end
    
    if not pet.Parent then
        capturados[pet] = true
        totalCapturados = totalCapturados + 1
        processando = false
        print("✅ CAPTUROU: " .. pet.Name)
        if statusLabel then statusLabel.Text = "✅ " .. pet.Name end
        return true
    end
    
    processando = false
    print("❌ Falhou: " .. pet.Name)
    if statusLabel then statusLabel.Text = "❌ " .. pet.Name end
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
    
    for _, pet in pairs(EncontrarPets()) do
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
-- CRIAR MENU SIMPLES
-- ========================================
local function CriarMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSeven"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    
    -- Frame principal
    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, 260, 0, 220)
    frame.Position = UDim2.new(0.5, -130, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    frame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = frame
    stroke.Color = Color3.fromRGB(138, 43, 226)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    
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
    
    -- Mininimizar
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
    btnMin.AutoButtonColor = false
    
    local minCorner = Instance.new("UICorner")
    minCorner.Parent = btnMin
    minCorner.CornerRadius = UDim.new(0, 6)
    
    -- Fechar
    local btnClose = Instance.new("TextButton")
    btnClose.Parent = frame
    btnClose.Size = UDim2.new(0, 30, 0, 30)
    btnClose.Position = UDim2.new(1, -70, 0, 2)
    btnClose.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    btnClose.Text = "✕"
    btnClose.TextColor3 = Color3.new(1, 1, 1)
    btnClose.TextSize = 14
    btnClose.Font = Enum.Font.GothamBold
    btnClose.BorderSizePixel = 0
    btnClose.AutoButtonColor = false
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = btnClose
    closeCorner.CornerRadius = UDim.new(0, 6)
    
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
    
    -- Container dos botões
    local container = Instance.new("Frame")
    container.Parent = frame
    container.Size = UDim2.new(0.9, 0, 0.5, 0)
    container.Position = UDim2.new(0.05, 0, 0.28, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    
    -- Botão ESP
    local btnESP = Instance.new("TextButton")
    btnESP.Parent = container
    btnESP.Size = UDim2.new(1, 0, 0, 35)
    btnESP.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnESP.Text = "🔴 ESP"
    btnESP.TextColor3 = Color3.new(1, 1, 1)
    btnESP.TextSize = 14
    btnESP.Font = Enum.Font.GothamBold
    btnESP.BorderSizePixel = 0
    btnESP.AutoButtonColor = false
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = btnESP
    espCorner.CornerRadius = UDim.new(0, 8)
    
    -- Botão AUTO
    local btnAuto = Instance.new("TextButton")
    btnAuto.Parent = container
    btnAuto.Size = UDim2.new(1, 0, 0, 35)
    btnAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnAuto.Text = "🔴 AUTO"
    btnAuto.TextColor3 = Color3.new(1, 1, 1)
    btnAuto.TextSize = 14
    btnAuto.Font = Enum.Font.GothamBold
    btnAuto.BorderSizePixel = 0
    btnAuto.AutoButtonColor = false
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = btnAuto
    autoCorner.CornerRadius = UDim.new(0, 8)
    
    -- Botão TESTE
    local btnTeste = Instance.new("TextButton")
    btnTeste.Parent = container
    btnTeste.Size = UDim2.new(1, 0, 0, 35)
    btnTeste.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
    btnTeste.Text = "🎯 TESTAR"
    btnTeste.TextColor3 = Color3.new(1, 1, 1)
    btnTeste.TextSize = 14
    btnTeste.Font = Enum.Font.GothamBold
    btnTeste.BorderSizePixel = 0
    btnTeste.AutoButtonColor = false
    
    local testeCorner = Instance.new("UICorner")
    testeCorner.Parent = btnTeste
    testeCorner.CornerRadius = UDim.new(0, 8)
    
    -- Status
    statusLabel = Instance.new("TextLabel")
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
    btnFloat.Parent = screenGui
    btnFloat.Size = UDim2.new(0, 45, 0, 45)
    btnFloat.Position = UDim2.new(0.93, -22, 0.93, -22)
    btnFloat.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    btnFloat.Text = "✧"
    btnFloat.TextColor3 = Color3.new(1, 1, 1)
    btnFloat.TextSize = 24
    btnFloat.Font = Enum.Font.GothamBold
    btnFloat.BorderSizePixel = 0
    btnFloat.Visible = false
    btnFloat.AutoButtonColor = false
    
    local floatCorner = Instance.new("UICorner")
    floatCorner.Parent = btnFloat
    floatCorner.CornerRadius = UDim.new(1, 0)
    
    -- Eventos dos botões
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
    
    -- Minimizar
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
    btnClose.MouseButton1Click:Connect(function()
        screenGui:Destroy()
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
    
    return screenGui
end

-- ========================================
-- INICIAR
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - SIMPLES")
print("========================================")
print("  📌 ESP: Ver pets")
print("  📌 AUTO: Capturar automático")
print("  📌 TESTAR: Testar captura")
print("========================================")

CriarMenu()

print("✅ SCRIPT CARREGADO!")
