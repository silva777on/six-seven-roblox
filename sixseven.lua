--[[
    SIX SEVEN - CAPTURA POR UI (FUNCIONAL)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - CAPTURA UI...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Config = {
    Delay = 5.0,
    ClickSpeed = 0.02,
    TotalClicks = 30
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local espAtivo = false
local autoAtivo = false
local autoRodando = false
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
                        if not nome:find("coruja") and not nome:find("owl") then
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
-- FUNÇÃO PARA ENCONTRAR BOTÃO DE CAPTURA NA UI
-- ========================================
local function EncontrarBotaoCaptura()
    -- Procura em todas as GUIs
    local guis = {
        CoreGui,
        Player:FindFirstChild("PlayerGui"),
        game:GetService("StarterGui")
    }
    
    for _, gui in pairs(guis) do
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local nome = obj.Name:lower()
                    local texto = obj.Text and obj.Text:lower() or ""
                    
                    -- Palavras-chave do botão de captura
                    if nome:find("capture") or nome:find("catch") or nome:find("pegar") or 
                       texto:find("capture") or texto:find("catch") or texto:find("pegar") or
                       texto:find("pegar") or texto:find("agarrar") or texto:find("coletar") then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

-- ========================================
-- FUNÇÃO PARA CLICAR NO BOTÃO
-- ========================================
local function ClicarBotao(botao)
    if not botao then return false end
    
    pcall(function()
        botao:FireServer()
        print("🔥 Botão clicado via FireServer")
        return true
    end)
    
    pcall(function()
        botao:Click()
        print("🔥 Botão clicado via Click()")
        return true
    end)
    
    -- Simula clique no botão
    local absPos = botao.AbsolutePosition
    local absSize = botao.AbsoluteSize
    
    if absPos and absSize then
        local x = absPos.X + absSize.X / 2
        local y = absPos.Y + absSize.Y / 2
        
        pcall(function()
            VirtualInputManager:SendMouseMovement(x, y, Enum.VirtualKeyMode.Delta, game)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
            print("🔥 Botão clicado via mouse")
            return true
        end)
    end
    
    return false
end

-- ========================================
-- FUNÇÃO PARA ENCONTRAR E CLICAR NO BOTÃO CAPTURAR
-- ========================================
local function ClicarCapturar()
    print("🔍 Procurando botão de captura...")
    
    -- Tenta encontrar o botão
    local botao = EncontrarBotaoCaptura()
    if botao then
        print("✅ Botão encontrado: " .. botao.Name)
        return ClicarBotao(botao)
    end
    
    -- Se não encontrou, tenta clicar no centro da tela (onde geralmente fica)
    print("🔍 Botão não encontrado, tentando clique no centro...")
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            VirtualInputManager:SendMouseMovement(viewport.X/2, viewport.Y/2, Enum.VirtualKeyMode.Delta, game)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
            print("🔥 Clique no centro da tela")
            return true
        end
    end)
    
    return false
end

-- ========================================
-- FUNÇÃO PARA PRESSIONAR TECLA E (INTERAGIR)
-- ========================================
local function PressionarTeclaInteracao()
    print("⌨️ Pressionando tecla E...")
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        return true
    end)
    return true
end

-- ========================================
-- FUNÇÃO PARA CLICAR RÁPIDO (ENCHE A BARRA)
-- ========================================
local function CliqueRapido()
    print("🖱️ Iniciando cliques rápidos...")
    
    -- Encontra a posição do mouse
    local posX, posY = UserInputService:GetMouseLocation()
    
    for i = 1, Config.TotalClicks do
        pcall(function()
            -- Clica onde o mouse está
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
            task.wait(Config.ClickSpeed)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
            
            if i % 10 == 0 then
                print("🖱️ Cliques: " .. i .. "/" .. Config.TotalClicks)
            end
        end)
    end
    
    print("✅ Cliques rápidos concluídos!")
    return true
end

-- ========================================
-- FUNÇÃO PRINCIPAL DE CAPTURA (OTIMIZADA)
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
    
    -- 1. Teleporta para o pet
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- 2. Interage com o pet (tecla E)
    PressionarTeclaInteracao()
    task.wait(0.3)
    
    -- 3. Clica no botão de captura da UI
    ClicarCapturar()
    task.wait(0.3)
    
    -- 4. Clique rápido para encher a barra
    CliqueRapido()
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
-- LEVAR PET À BASE
-- ========================================
local function LevarPetBase(pet)
    if not pet then return end
    
    local base = Workspace:FindFirstChild("Base") or Workspace:FindFirstChild("PlayerBase")
    if not base then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- Tenta soltar
    local release = ReplicatedStorage:FindFirstChild("ReleasePet")
        or ReplicatedStorage:FindFirstChild("DropPet")
    
    if release then
        pcall(function()
            release:FireServer(pet)
            print("📦 Pet solto na base")
        end)
    end
end

-- ========================================
-- LOOP AUTO
-- ========================================
local function LoopAuto()
    while autoAtivo and autoRodando do
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
                local sucesso = CapturarPet(alvo)
                if sucesso then
                    LevarPetBase(alvo)
                end
                task.wait(Config.Delay)
            else
                status.Text = "⏳ Procurando pets..."
                task.wait(0.5)
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
    
    -- Botão minimizar
    local btnMinimizar = Instance.new("TextButton")
    btnMinimizar.Parent = frame
    btnMinimizar.Size = UDim2.new(0, 30, 0, 30)
    btnMinimizar.Position = UDim2.new(1, -35, 0, 2)
    btnMinimizar.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    btnMinimizar.Text = "─"
    btnMinimizar.TextColor3 = Color3.new(1, 1, 1)
    btnMinimizar.TextSize = 18
    btnMinimizar.Font = Enum.Font.GothamBold
    btnMinimizar.BorderSizePixel = 0
    
    local minCorner = Instance.new("UICorner")
    minCorner.Parent = btnMinimizar
    minCorner.CornerRadius = UDim.new(0, 6)
    
    -- Botão fechar
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
    
    -- Container dos botões
    local container = Instance.new("Frame")
    container.Parent = frame
    container.Size = UDim2.new(0.9, 0, 0.55, 0)
    container.Position = UDim2.new(0.05, 0, 0.25, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    
    -- Botão ESP
    local btnESP = Instance.new("TextButton")
    btnESP.Name = "BtnESP"
    btnESP.Parent = container
    btnESP.Size = UDim2.new(1, 0, 0, 35)
    btnESP.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnESP.Text = "🔴 ESP (OFF)"
    btnESP.TextColor3 = Color3.new(1, 1, 1)
    btnESP.TextSize = 14
    btnESP.Font = Enum.Font.GothamBold
    btnESP.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = btnESP
    espCorner.CornerRadius = UDim.new(0, 8)
    
    -- Botão AUTO
    local btnAuto = Instance.new("TextButton")
    btnAuto.Name = "BtnAuto"
    btnAuto.Parent = container
    btnAuto.Size = UDim2.new(1, 0, 0, 35)
    btnAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnAuto.Text = "🔴 AUTO (OFF)"
    btnAuto.TextColor3 = Color3.new(1, 1, 1)
    btnAuto.TextSize = 14
    btnAuto.Font = Enum.Font.GothamBold
    btnAuto.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = btnAuto
    autoCorner.CornerRadius = UDim.new(0, 8)
    
    -- Botão TESTE
    local btnTeste = Instance.new("TextButton")
    btnTeste.Name = "BtnTeste"
    btnTeste.Parent = container
    btnTeste.Size = UDim2.new(1, 0, 0, 35)
    btnTeste.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
    btnTeste.Text = "🔍 TESTAR UI"
    btnTeste.TextColor3 = Color3.new(1, 1, 1)
    btnTeste.TextSize = 14
    btnTeste.Font = Enum.Font.GothamBold
    btnTeste.BorderSizePixel = 0
    
    local testeCorner = Instance.new("UICorner")
    testeCorner.Parent = btnTeste
    testeCorner.CornerRadius = UDim.new(0, 8)
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
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
    btnFloat.Name = "FloatButton"
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
    
    -- Funções
    local function Minimizar()
        frame.Visible = false
        btnFloat.Visible = true
    end
    
    local function Abrir()
        frame.Visible = true
        btnFloat.Visible = false
    end
    
    btnMinimizar.MouseButton1Click:Connect(Minimizar)
    btnFloat.MouseButton1Click:Connect(Abrir)
    btnFechar.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    return gui, btnESP, btnAuto, btnTeste, statusLabel
end

local gui, btnESP, btnAuto, btnTeste, status = CriarMenu()

-- ========================================
-- EVENTOS DOS BOTÕES
-- ========================================

-- ESP
btnESP.MouseButton1Click:Connect(function()
    espAtivo = not espAtivo
    btnESP.Text = espAtivo and "🟢 ESP (ON)" or "🔴 ESP (OFF)"
    btnESP.BackgroundColor3 = espAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
    AtualizarESP()
    
    task.spawn(function()
        while espAtivo do
            AtualizarESP()
            task.wait(1)
        end
    end)
end)

-- AUTO
btnAuto.MouseButton1Click:Connect(function()
    autoAtivo = not autoAtivo
    btnAuto.Text = autoAtivo and "🟢 AUTO (ON)" or "🔴 AUTO (OFF)"
    btnAuto.BackgroundColor3 = autoAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
    status.Text = autoAtivo and "🔄 Auto ligado" or "⏹️ Auto desligado"
    
    if autoAtivo then
        autoRodando = true
        task.spawn(LoopAuto)
    else
        autoRodando = false
    end
end)

-- BOTÃO TESTE (Encontra e mostra botões da UI)
btnTeste.MouseButton1Click:Connect(function()
    print("🔍 PROCURANDO BOTÕES NA UI...")
    status.Text = "🔍 Procurando botões..."
    
    local guis = {CoreGui, Player:FindFirstChild("PlayerGui")}
    local encontrados = 0
    
    for _, gui in pairs(guis) do
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    encontrados = encontrados + 1
                    print("  - " .. obj:GetFullName())
                    print("    Texto: " .. (obj.Text or "sem texto"))
                    print("    Visível: " .. tostring(obj.Visible))
                    
                    -- Tenta clicar em cada botão encontrado
                    if obj.Visible and obj.AbsoluteSize and obj.AbsoluteSize.X > 0 then
                        pcall(function()
                            local absPos = obj.AbsolutePosition
                            local absSize = obj.AbsoluteSize
                            local x = absPos.X + absSize.X / 2
                            local y = absPos.Y + absSize.Y / 2
                            
                            VirtualInputManager:SendMouseMovement(x, y, Enum.VirtualKeyMode.Delta, game)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
                            task.wait(0.02)
                            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
                            print("    ✅ Cliquei no botão!")
                        end)
                    end
                end
            end
        end
    end
    
    print("✅ Total de botões encontrados: " .. encontrados)
    status.Text = "✅ " .. encontrados .. " botões encontrados"
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

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    print("🔄 Respawnou!")
end)

print("========================================")
print("  ✅ SCRIPT PRONTO!")
print("  📌 Clique em TESTAR UI para ver os botões")
print("  📌 Depois ligue o AUTO")
print("========================================")
