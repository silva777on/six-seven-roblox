--[[
    SIX SEVEN - SCRIPT COMPLETO (BASEADO NO VÍDEO)
    Game: [🍎] Capture e Domestique!
    Funcionalidades: Auto Catch, Teleport, Auto Place, Auto Collect, Auto Buy
]]

print("🔄 CARREGANDO SIX SEVEN - COMPLETO...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    -- Auto Catch
    AutoCatch = false,
    Rarity = "All", -- All, Common, Uncommon, Rare, Epic, Legendary, Mythic
    TeleportTo = nil,
    
    -- Automations
    AutoCollectCash = false,
    AutoEnterance = false,
    AutoBuyEgg = false,
    AutoBuyFood = false,
    AutoFeedPets = false,
    AutoBuyBuildings = false,
    AutoOptimizePen = false,
    AutoPlacePets = false,
    
    -- Settings
    Delay = 5.0,
    TotalClicks = 50,
    ClickSpeed = 0.02,
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local capturados = {}
local totalCapturados = 0
local processando = false
local espAtivo = false
local autoRodando = false

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
-- FUNÇÕES DE CLIQUE E TECLA
-- ========================================
local function Clicar()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.02)
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
-- FUNÇÃO PARA ENCONTRAR BOTÃO NA UI
-- ========================================
local function EncontrarBotao(nome)
    local guis = {CoreGui, Player:FindFirstChild("PlayerGui")}
    
    for _, gui in pairs(guis) do
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    if obj.Visible then
                        local texto = obj.Text and obj.Text:lower() or ""
                        local nomeObj = obj.Name:lower()
                        
                        if texto:find(nome) or nomeObj:find(nome) then
                            return obj
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ========================================
-- FUNÇÃO PARA CLICAR EM BOTÃO
-- ========================================
local function ClicarBotao(botao)
    if not botao then return false end
    
    pcall(function()
        botao:FireServer()
        return true
    end)
    
    pcall(function()
        botao:Click()
        return true
    end)
    
    local absPos = botao.AbsolutePosition
    local absSize = botao.AbsoluteSize
    
    if absPos and absSize and absSize.X > 0 then
        local x = absPos.X + absSize.X / 2
        local y = absPos.Y + absSize.Y / 2
        
        pcall(function()
            MoverMouse(x, y)
            task.wait(0.1)
            Clicar()
            return true
        end)
    end
    
    return false
end

-- ========================================
-- TELEPORTE PARA ÁREAS
-- ========================================
local function TeleportarPara(destino)
    print("🚀 Teleportando para: " .. destino)
    status.Text = "🚀 Teleportando..."
    
    local areas = {
        ["Main"] = "Main",
        ["Cave"] = "Cave",
        ["Island"] = "Island",
    }
    
    -- Tenta encontrar o destino no workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("Model") then
            local nome = obj.Name:lower()
            if nome:find(destino:lower()) or nome:find("spawn") or nome:find("teleport") then
                if obj:IsA("Part") and obj.Position then
                    pcall(function()
                        RootPart.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
                    end)
                    task.wait(0.3)
                    print("✅ Teleportado para: " .. obj.Name)
                    return true
                end
            end
        end
    end
    
    -- Fallback: teleporta para o centro do mapa
    pcall(function()
        RootPart.CFrame = CFrame.new(0, 10, 0)
    end)
    return true
end

-- ========================================
-- AUTO CATCH (CAPTURA AUTOMÁTICA)
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
    
    -- Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- Interage (tecla E)
    PressionarTecla(Enum.KeyCode.E)
    task.wait(0.3)
    
    -- Clica no pet
    local camera = Workspace.CurrentCamera
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            MoverMouse(pos.X, pos.Y)
            task.wait(0.1)
            Clicar()
            task.wait(0.3)
        end
    end
    
    -- Clica em "Place in Pen" ou "Farm Pet"
    local botao = EncontrarBotao("place") or EncontrarBotao("pen") or EncontrarBotao("farm") or EncontrarBotao("capture")
    if botao then
        ClicarBotao(botao)
        task.wait(0.3)
    end
    
    -- Clica repetidamente
    for i = 1, Config.TotalClicks do
        Clicar()
        if i % 10 == 0 then
            print("  📊 " .. i .. "/" .. Config.TotalClicks)
        end
        task.wait(Config.ClickSpeed)
    end
    
    task.wait(0.5)
    
    -- Verifica captura
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
-- AUTO PLACE PETS (COLOCAR PETS NO RECINTO)
-- ========================================
local function AutoPlacePets()
    print("🏠 Auto Place Pets...")
    status.Text = "🏠 Colocando pets..."
    
    -- Procura botão "Place in Pen"
    local botao = EncontrarBotao("place") or EncontrarBotao("pen")
    if botao then
        ClicarBotao(botao)
        task.wait(0.5)
    end
    
    -- Tenta clicar nos pets para colocar
    for _, pet in pairs(capturados) do
        if pet and pet:IsA("Model") then
            local hrp = pet:FindFirstChild("HumanoidRootPart")
            if hrp then
                local camera = Workspace.CurrentCamera
                if camera then
                    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        MoverMouse(pos.X, pos.Y)
                        task.wait(0.1)
                        Clicar()
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end

-- ========================================
-- AUTO COLLECT CASH (COLETAR DINHEIRO)
-- ========================================
local function AutoCollectCash()
    print("💰 Auto Collect Cash...")
    status.Text = "💰 Coletando dinheiro..."
    
    -- Procura botões de coleta
    local botoes = {
        EncontrarBotao("collect"),
        EncontrarBotao("cash"),
        EncontrarBotao("money"),
        EncontrarBotao("claim")
    }
    
    for _, botao in pairs(botoes) do
        if botao then
            ClicarBotao(botao)
            task.wait(0.3)
        end
    end
    
    -- Tenta tecla para coletar
    PressionarTecla(Enum.KeyCode.Q)
    task.wait(0.3)
end

-- ========================================
-- AUTO BUY EGG (COMPRAR OVOS)
-- ========================================
local function AutoBuyEgg()
    print("🥚 Auto Buy Egg...")
    status.Text = "🥚 Comprando ovos..."
    
    local botao = EncontrarBotao("egg") or EncontrarBotao("buy")
    if botao then
        ClicarBotao(botao)
        task.wait(0.5)
    end
end

-- ========================================
-- AUTO BUY FOOD (COMPRAR COMIDA)
-- ========================================
local function AutoBuyFood()
    print("🍖 Auto Buy Food...")
    status.Text = "🍖 Comprando comida..."
    
    local botao = EncontrarBotao("food") or EncontrarBotao("buy") or EncontrarBotao("shop")
    if botao then
        ClicarBotao(botao)
        task.wait(0.5)
    end
end

-- ========================================
-- AUTO FEED PETS (ALIMENTAR PETS)
-- ========================================
local function AutoFeedPets()
    print("🍽️ Auto Feed Pets...")
    status.Text = "🍽️ Alimentando pets..."
    
    local botao = EncontrarBotao("feed") or EncontrarBotao("food")
    if botao then
        ClicarBotao(botao)
        task.wait(0.5)
    end
end

-- ========================================
-- AUTO BUY BUILDINGS (COMPRAR CONSTRUÇÕES)
-- ========================================
local function AutoBuyBuildings()
    print("🏗️ Auto Buy Buildings...")
    status.Text = "🏗️ Comprando construções..."
    
    local botao = EncontrarBotao("build") or EncontrarBotao("buy") or EncontrarBotao("shop")
    if botao then
        ClicarBotao(botao)
        task.wait(0.5)
    end
end

-- ========================================
-- AUTO OPTIMIZE PEN (OTIMIZAR RECINTO)
-- ========================================
local function AutoOptimizePen()
    print("📐 Auto Optimize Pen...")
    status.Text = "📐 Otimizando recinto..."
    
    local botao = EncontrarBotao("optimize") or EncontrarBotao("upgrade") or EncontrarBotao("pen")
    if botao then
        ClicarBotao(botao)
        task.wait(0.5)
    end
end

-- ========================================
-- LOOP AUTO COMPLETO
-- ========================================
local function LoopAuto()
    while autoRodando do
        if processando then
            task.wait(0.5)
        else
            -- 1. Auto Collect Cash
            if Config.AutoCollectCash then
                AutoCollectCash()
            end
            
            -- 2. Auto Buy Egg
            if Config.AutoBuyEgg then
                AutoBuyEgg()
            end
            
            -- 3. Auto Buy Food
            if Config.AutoBuyFood then
                AutoBuyFood()
            end
            
            -- 4. Auto Feed Pets
            if Config.AutoFeedPets then
                AutoFeedPets()
            end
            
            -- 5. Auto Buy Buildings
            if Config.AutoBuyBuildings then
                AutoBuyBuildings()
            end
            
            -- 6. Auto Optimize Pen
            if Config.AutoOptimizePen then
                AutoOptimizePen()
            end
            
            -- 7. Auto Place Pets
            if Config.AutoPlacePets then
                AutoPlacePets()
            end
            
            -- 8. Auto Catch
            if Config.AutoCatch then
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
            end
            
            task.wait(Config.Delay)
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
-- CRIAR MENU COMPLETO
-- ========================================
local function CriarMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SixSeven"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 300, 0, 450)
    frame.Position = UDim2.new(0.5, -150, 0.5, -225)
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
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = btnClose
    closeCorner.CornerRadius = UDim.new(0, 6)
    
    -- Container
    local container = Instance.new("ScrollingFrame")
    container.Parent = frame
    container.Size = UDim2.new(0.95, 0, 0.8, 0)
    container.Position = UDim2.new(0.025, 0, 0.1, 0)
    container.BackgroundTransparency = 1
    container.CanvasSize = UDim2.new(0, 0, 0, 600)
    container.ScrollBarThickness = 4
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    
    -- Criar botão toggle
    local function CriarToggle(texto, variavel, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = container
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
        btn.Text = "🔴 " .. texto
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        btnCorner.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            variavel = not variavel
            btn.Text = variavel and "🟢 " .. texto or "🔴 " .. texto
            btn.BackgroundColor3 = variavel and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(50, 50, 120)
            if callback then callback(variavel) end
        end)
        
        return btn
    end
    
    -- Criar botão normal
    local function CriarBotao(texto, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = container
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 140)
        btn.Text = texto
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        btnCorner.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Título da seção
    local function CriarSecao(texto)
        local label = Instance.new("TextLabel")
        label.Parent = container
        label.Size = UDim2.new(1, 0, 0, 25)
        label.BackgroundTransparency = 1
        label.Text = "─── " .. texto .. " ───"
        label.TextColor3 = Color3.fromRGB(200, 150, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
    end
    
    -- ========================================
    -- SEÇÃO: AUTO CATCH
    -- ========================================
    CriarSecao("AUTO CATCH")
    
    local btnAutoCatch = CriarToggle("Auto Catch", Config.AutoCatch, function(val)
        Config.AutoCatch = val
        if val then
            autoRodando = true
            task.spawn(LoopAuto)
        else
            autoRodando = false
        end
    end)
    
    -- Raridade
    local function CriarDropdown(texto, opcoes)
        local dropdown = Instance.new("TextButton")
        dropdown.Parent = container
        dropdown.Size = UDim2.new(1, 0, 0, 25)
        dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
        dropdown.Text = "📋 " .. texto .. ": " .. opcoes[1]
        dropdown.TextColor3 = Color3.new(1, 1, 1)
        dropdown.TextSize = 12
        dropdown.Font = Enum.Font.Gotham
        dropdown.BorderSizePixel = 0
        
        local dropdownCorner = Instance.new("UICorner")
        dropdownCorner.Parent = dropdown
        dropdownCorner.CornerRadius = UDim.new(0, 6)
        
        local selected = 1
        dropdown.MouseButton1Click:Connect(function()
            selected = selected % #opcoes + 1
            dropdown.Text = "📋 " .. texto .. ": " .. opcoes[selected]
            Config.Rarity = opcoes[selected]
        end)
        
        return dropdown
    end
    
    CriarDropdown("Raridade", {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"})
    
    CriarBotao("🚀 Teleport", function()
        -- Abre opções de teleporte
        local areas = {"Main", "Cave", "Island", "Forest", "Desert"}
        for i, area in pairs(areas) do
            task.spawn(function()
                TeleportarPara(area)
                task.wait(0.5)
            end)
        end
    end)
    
    -- ========================================
    -- SEÇÃO: AUTOMATIONS
    -- ========================================
    CriarSecao("AUTOMATIONS")
    
    CriarToggle("Auto Collect Cash", Config.AutoCollectCash, function(val)
        Config.AutoCollectCash = val
    end)
    
    CriarToggle("Auto Enterance", Config.AutoEnterance, function(val)
        Config.AutoEnterance = val
    end)
    
    CriarToggle("Auto Buy Egg", Config.AutoBuyEgg, function(val)
        Config.AutoBuyEgg = val
    end)
    
    CriarToggle("Auto Buy Food", Config.AutoBuyFood, function(val)
        Config.AutoBuyFood = val
    end)
    
    CriarToggle("Auto Feed Pets", Config.AutoFeedPets, function(val)
        Config.AutoFeedPets = val
    end)
    
    CriarToggle("Auto Buy Buildings", Config.AutoBuyBuildings, function(val)
        Config.AutoBuyBuildings = val
    end)
    
    CriarToggle("Auto Optimize Pen", Config.AutoOptimizePen, function(val)
        Config.AutoOptimizePen = val
    end)
    
    CriarToggle("Auto Place Pets", Config.AutoPlacePets, function(val)
        Config.AutoPlacePets = val
    end)
    
    -- ========================================
    -- SEÇÃO: ESP
    -- ========================================
    CriarSecao("ESP")
    
    CriarToggle("ESP", espAtivo, function(val)
        espAtivo = val
        AtualizarESP()
        
        task.spawn(function()
            while espAtivo do
                AtualizarESP()
                task.wait(1)
            end
        end)
    end)
    
    -- ========================================
    -- STATUS
    -- ========================================
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.Size = UDim2.new(0.95, 0, 0, 20)
    statusLabel.Position = UDim2.new(0.025, 0, 0.92, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    
    -- ========================================
    -- BOTÃO FLUTUANTE
    -- ========================================
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
        gui:Destroy()
    end)
    
    -- Monitoramento
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #EncontrarPets()
            statusLabel.Text = "📊 Pets: " .. count .. " | Capturados: " .. totalCapturados
        end
    end)
    
    return gui
end

-- ========================================
-- INICIAR
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - SCRIPT COMPLETO")
print("========================================")
print("  📌 FUNCIONALIDADES:")
print("  - Auto Catch com seleção de raridade")
print("  - Teleport para áreas")
print("  - Auto Collect Cash")
print("  - Auto Buy Egg/Food")
print("  - Auto Feed Pets")
print("  - Auto Buy Buildings")
print("  - Auto Optimize Pen")
print("  - Auto Place Pets")
print("  - ESP")
print("========================================")

CriarMenu()

print("✅ SCRIPT COMPLETO CARREGADO!")
