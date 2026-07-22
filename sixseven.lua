--[[
    SIX SEVEN - ANALISADOR E CAPTURADOR
    Vamos descobrir como o jogo realmente captura
]]

print("🔍 INICIANDO ANALISADOR...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

-- ========================================
-- ANALISAR O JOGO
-- ========================================
print("📡 ANALISANDO RECURSOS DO JOGO...")

-- 1. Ver todos os Remotes
print("\n📡 REMOTES ENCONTRADOS:")
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("  - " .. obj:GetFullName())
    end
end

-- 2. Ver estrutura dos pets
local pets = {}
for _, obj in pairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
            table.insert(pets, obj)
        end
    end
end

if #pets > 0 then
    print("\n🐾 ESTRUTURA DO PET:")
    local pet = pets[1]
    print("  Nome: " .. pet.Name)
    for _, child in pairs(pet:GetChildren()) do
        print("    - " .. child.Name .. " (" .. child.ClassName .. ")")
    end
end

-- ========================================
-- CRIAR GUI DE TESTE
-- ========================================
local function CriarGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "Capturador"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 300, 0, 350)
    frame.Position = UDim2.new(0.5, -150, 0.5, -175)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 12)
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Parent = frame
    titulo.Size = UDim2.new(1, 0, 0, 35)
    titulo.BackgroundColor3 = Color3.fromRGB(80, 0, 200)
    titulo.BackgroundTransparency = 0.3
    titulo.Text = "🎯 CAPTURADOR"
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.TextSize = 18
    titulo.Font = Enum.Font.GothamBold
    
    -- Botões
    local botoes = {}
    local y = 50
    
    local function CriarBotao(texto, cor, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = frame
        btn.Size = UDim2.new(0.8, 0, 0, 35)
        btn.Position = UDim2.new(0.1, 0, y/350, 0)
        btn.BackgroundColor3 = cor or Color3.fromRGB(50, 50, 120)
        btn.Text = texto
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        btnCorner.CornerRadius = UDim.new(0, 8)
        
        btn.MouseButton1Click:Connect(callback)
        table.insert(botoes, btn)
        y = y + 45
        return btn
    end
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Parent = frame
    status.Size = UDim2.new(0.9, 0, 0, 30)
    status.Position = UDim2.new(0.05, 0, 0.85, 0)
    status.BackgroundTransparency = 1
    status.Text = "📊 Pronto"
    status.TextColor3 = Color3.fromRGB(150, 150, 200)
    status.TextSize = 13
    status.Font = Enum.Font.Gotham
    status.TextWrapped = true
    
    return gui, status, botoes
end

local gui, status, botoes = CriarGUI()

-- ========================================
-- VARIÁVEIS
-- ========================================
local capturados = {}
local total = 0
local processando = false
local autoAtivo = false

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function EncontrarPets()
    local lista = {}
    local char = Player.Character
    if not char then return lista end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= char and not Players:GetPlayerFromCharacter(obj) then
                local nome = obj.Name:lower()
                if not nome:find("base") and not nome:find("floor") and not nome:find("wall") then
                    if not nome:find("npc") and not nome:find("humano") and not nome:find("player") then
                        table.insert(lista, obj)
                    end
                end
            end
        end
    end
    return lista
end

-- ========================================
-- MÉTODO 1: CAPTURA POR REMOTE
-- ========================================
local function CapturarPorRemote(pet)
    print("📡 Tentando Remote...")
    
    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            table.insert(remotes, obj)
        end
    end
    
    for _, remote in pairs(remotes) do
        local nome = remote.Name:lower()
        if nome:find("pet") or nome:find("capture") or nome:find("catch") then
            pcall(function()
                remote:FireServer("Capture", pet.Name, pet)
                print("  ✅ Remote enviado: " .. remote.Name)
                task.wait(0.3)
                return true
            end)
        end
    end
    return false
end

-- ========================================
-- MÉTODO 2: CAPTURA POR PROXIMITYPROMPT
-- ========================================
local function CapturarPorPrompt(pet)
    print("🎯 Tentando ProximityPrompt...")
    
    local prompt = pet:FindFirstChild("ProximityPrompt")
    if prompt then
        pcall(function()
            prompt:InputHoldBegin(Player)
            task.wait(0.5)
            prompt:InputHoldEnd(Player)
            print("  ✅ Prompt ativado")
            return true
        end)
    end
    return false
end

-- ========================================
-- MÉTODO 3: CAPTURA POR CLIQUE
-- ========================================
local function CapturarPorClique(pet)
    print("🖱️ Tentando clique...")
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local camera = Workspace.CurrentCamera
    if not camera then return false end
    
    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    pcall(function()
        -- Move o mouse
        VirtualInputManager:SendMouseMovement(pos.X, pos.Y, Enum.VirtualKeyMode.Delta, game)
        task.wait(0.1)
        
        -- Clique
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
        print("  ✅ Clique enviado")
        return true
    end)
    
    return false
end

-- ========================================
-- MÉTODO 4: CAPTURA POR CLIQUE RÁPIDO
-- ========================================
local function CapturarPorCliqueRapido(pet)
    print("⚡ Tentando clique rápido...")
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local camera = Workspace.CurrentCamera
    if not camera then return false end
    
    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    pcall(function()
        -- Move o mouse
        VirtualInputManager:SendMouseMovement(pos.X, pos.Y, Enum.VirtualKeyMode.Delta, game)
        task.wait(0.1)
        
        -- Clica várias vezes
        for i = 1, 30 do
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
        end
        print("  ✅ 30 cliques enviados")
        return true
    end)
    
    return false
end

-- ========================================
-- MÉTODO 5: CAPTURA POR TECLA
-- ========================================
local function CapturarPorTecla(pet)
    print("⌨️ Tentando tecla...")
    
    pcall(function()
        -- Tenta E
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        print("  ✅ Tecla E pressionada")
        return true
    end)
    
    return false
end

-- ========================================
-- FUNÇÃO PRINCIPAL DE CAPTURA
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
    
    print("\n🎯 CAPTURANDO: " .. pet.Name)
    status.Text = "🎯 Capturando: " .. pet.Name
    
    -- Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- Tenta todos os métodos
    local metodos = {
        { nome = "Remote", func = CapturarPorRemote },
        { nome = "Prompt", func = CapturarPorPrompt },
        { nome = "Clique", func = CapturarPorClique },
        { nome = "Clique Rápido", func = CapturarPorCliqueRapido },
        { nome = "Tecla", func = CapturarPorTecla }
    }
    
    local capturou = false
    for _, metodo in pairs(metodos) do
        print("🔄 Testando método: " .. metodo.nome)
        local sucesso = metodo.func(pet)
        if sucesso then
            print("✅ Método " .. metodo.nome .. " funcionou!")
            capturou = true
            break
        end
        task.wait(0.2)
    end
    
    task.wait(0.5)
    
    -- Verifica se capturou
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
    print("❌ FALHOU: " .. pet.Name)
    status.Text = "❌ Falhou: " .. pet.Name
    return false
end

-- ========================================
-- CAPTURAR PET MAIS PRÓXIMO
-- ========================================
local function CapturarProximo()
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
    else
        status.Text = "❌ Nenhum pet próximo"
        print("❌ Nenhum pet próximo")
    end
end

-- ========================================
-- LOOP AUTO
-- ========================================
local function LoopAuto()
    while autoAtivo do
        if processando then
            task.wait(0.5)
        else
            CapturarProximo()
            task.wait(5)
        end
    end
end

-- ========================================
-- CRIAR BOTÕES
-- ========================================
local function CriarBotoes()
    local y = 50
    
    -- Botão Capturar
    local btnCapturar = Instance.new("TextButton")
    btnCapturar.Parent = gui
    btnCapturar.Size = UDim2.new(0.8, 0, 0, 35)
    btnCapturar.Position = UDim2.new(0.1, 0, y/350, 0)
    btnCapturar.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    btnCapturar.Text = "🎯 CAPTURAR PRÓXIMO"
    btnCapturar.TextColor3 = Color3.new(1, 1, 1)
    btnCapturar.TextSize = 14
    btnCapturar.Font = Enum.Font.GothamBold
    btnCapturar.BorderSizePixel = 0
    
    local corner1 = Instance.new("UICorner")
    corner1.Parent = btnCapturar
    corner1.CornerRadius = UDim.new(0, 8)
    
    btnCapturar.MouseButton1Click:Connect(CapturarProximo)
    
    y = y + 45
    
    -- Botão Auto
    local btnAuto = Instance.new("TextButton")
    btnAuto.Parent = gui
    btnAuto.Size = UDim2.new(0.8, 0, 0, 35)
    btnAuto.Position = UDim2.new(0.1, 0, y/350, 0)
    btnAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnAuto.Text = "🔴 AUTO (OFF)"
    btnAuto.TextColor3 = Color3.new(1, 1, 1)
    btnAuto.TextSize = 14
    btnAuto.Font = Enum.Font.GothamBold
    btnAuto.BorderSizePixel = 0
    
    local corner2 = Instance.new("UICorner")
    corner2.Parent = btnAuto
    corner2.CornerRadius = UDim.new(0, 8)
    
    btnAuto.MouseButton1Click:Connect(function()
        autoAtivo = not autoAtivo
        btnAuto.Text = autoAtivo and "🟢 AUTO (ON)" or "🔴 AUTO (OFF)"
        btnAuto.BackgroundColor3 = autoAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
        status.Text = autoAtivo and "🔄 Auto ligado" or "⏹️ Auto desligado"
        
        if autoAtivo then
            task.spawn(LoopAuto)
        end
    end)
    
    y = y + 45
    
    -- Botão ESP
    local espAtivo = false
    local btnESP = Instance.new("TextButton")
    btnESP.Parent = gui
    btnESP.Size = UDim2.new(0.8, 0, 0, 35)
    btnESP.Position = UDim2.new(0.1, 0, y/350, 0)
    btnESP.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btnESP.Text = "🔴 ESP (OFF)"
    btnESP.TextColor3 = Color3.new(1, 1, 1)
    btnESP.TextSize = 14
    btnESP.Font = Enum.Font.GothamBold
    btnESP.BorderSizePixel = 0
    
    local corner3 = Instance.new("UICorner")
    corner3.Parent = btnESP
    corner3.CornerRadius = UDim.new(0, 8)
    
    btnESP.MouseButton1Click:Connect(function()
        espAtivo = not espAtivo
        btnESP.Text = espAtivo and "🟢 ESP (ON)" or "🔴 ESP (OFF)"
        btnESP.BackgroundColor3 = espAtivo and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
        
        if espAtivo then
            task.spawn(function()
                while espAtivo do
                    for _, pet in pairs(EncontrarPets()) do
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
                    task.wait(1)
                end
            end)
        else
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("ESP_Highlight") then
                    obj.ESP_Highlight:Destroy()
                end
            end
        end
    end)
    
    return btnCapturar, btnAuto, btnESP
end

local btnCapturar, btnAuto, btnESP = CriarBotoes()

-- ========================================
-- MONITORAMENTO
-- ========================================
task.spawn(function()
    while true do
        task.wait(2)
        local count = #EncontrarPets()
        if not autoAtivo and not processando then
            status.Text = "📊 Pets: " .. count .. " | Capturados: " .. total
        end
    end
end)

print("========================================")
print("  ✅ ANALISADOR PRONTO!")
print("  📌 Clique em CAPTURAR PRÓXIMO")
print("  📌 Veja no console o que acontece")
print("  📌 Me diga qual método funcionou!")
print("========================================")
