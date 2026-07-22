--[[
    SIX SEVEN - CLIQUE AUTOMÁTICO NA TELA
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - CLIQUE NA TELA...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- VARIÁVEIS
-- ========================================
local autoAtivo = false
local autoRodando = false
local processando = false
local capturados = {}
local totalCapturados = 0
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
-- FUNÇÃO PARA CLICAR NA TELA (EM QUALQUER LUGAR)
-- ========================================
local function ClicarNaTela()
    pcall(function()
        -- Clica na posição atual do mouse
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
    end)
end

-- ========================================
-- FUNÇÃO PARA CLICAR REPETIDAMENTE (ENCHE A BARRA)
-- ========================================
local function ClicarRepetidamente(vezes)
    print("🖱️ Clicando " .. vezes .. " vezes na tela...")
    
    for i = 1, vezes do
        ClicarNaTela()
        
        -- Mostra progresso a cada 10 cliques
        if i % 10 == 0 then
            print("  📊 Progresso: " .. i .. "/" .. vezes)
        end
        
        task.wait(0.02) -- Velocidade dos cliques
    end
    
    print("✅ " .. vezes .. " cliques concluídos!")
    return true
end

-- ========================================
-- FUNÇÃO PARA CAPTURAR PET
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
    
    -- 1. Teleporta para o pet
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- 2. CLICA NO PET (para abrir a UI de captura)
    print("🖱️ Clicando no pet para abrir a UI...")
    local camera = Workspace.CurrentCamera
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            pcall(function()
                -- Move o mouse para o pet
                VirtualInputManager:SendMouseMovement(pos.X, pos.Y, Enum.VirtualKeyMode.Delta, game)
                task.wait(0.1)
                
                -- Clica no pet
                VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
                print("  ✅ Clique no pet enviado")
            end)
        else
            -- Se o pet não está na tela, teleporta mais perto
            pcall(function()
                RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
            end)
            task.wait(0.3)
            
            -- Tenta clicar novamente
            local newPos, newOnScreen = camera:WorldToViewportPoint(hrp.Position)
            if newOnScreen then
                VirtualInputManager:SendMouseMovement(newPos.X, newPos.Y, Enum.VirtualKeyMode.Delta, game)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
            end
        end
    end
    
    task.wait(0.5)
    
    -- 3. CLICA REPETIDAMENTE NA TELA (ENCHE A BARRA!)
    print("🔄 Enchendo a barra de captura...")
    ClicarRepetidamente(40) -- 40 cliques para encher a barra
    
    task.wait(0.5)
    
    -- 4. Verifica se capturou
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
    
    -- Verifica se o pet foi destruído (capturado)
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
    
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(base.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
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
                task.wait(5) -- Delay entre capturas
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
    frame.Size = UDim2.new(0, 260, 0, 200)
    frame.Position = UDim2.new(0.5, -130, 0.5, -100)
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
    
    return gui, btnESP, btnAuto, statusLabel
end

local gui, btnESP, btnAuto, status = CriarMenu()

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
    print("🔄 Respawnou!")
end)

print("========================================")
print("  ✅ SCRIPT PRONTO!")
print("  📌 ESP: Mostra os pets")
print("  📌 AUTO: Clica no pet → Clica na tela 40x")
print("  📌 A barra vai encher sozinha!")
print("========================================")
