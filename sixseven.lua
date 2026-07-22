--[[
    SIX SEVEN - SCRIPT INTELIGENTE
    Descobre automaticamente como capturar
]]

print("🔄 CARREGANDO SCRIPT INTELIGENTE...")

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

-- ========================================
-- VARIÁVEIS
-- ========================================
local autoAtivo = false
local capturados = {}
local total = 0
local processando = false
local espAtivo = false
local modoCaptura = "desconhecido"

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
-- FUNÇÕES DE CLIQUE
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
-- FUNÇÃO PARA ENCONTRAR BOTÕES NA UI
-- ========================================
local function EncontrarTodosBotoes()
    local botoes = {}
    local guis = {CoreGui, Player:FindFirstChild("PlayerGui")}
    
    for _, gui in pairs(guis) do
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    if obj.Visible then
                        table.insert(botoes, {
                            objeto = obj,
                            nome = obj.Name,
                            texto = obj.Text or "",
                            pos = obj.AbsolutePosition,
                            size = obj.AbsoluteSize
                        })
                    end
                end
            end
        end
    end
    return botoes
end

-- ========================================
-- FUNÇÃO PARA CLICAR EM BOTÃO POR TEXTO
-- ========================================
local function ClicarBotaoPorTexto(texto)
    local botoes = EncontrarTodosBotoes()
    for _, btn in pairs(botoes) do
        if btn.texto:lower():find(texto:lower()) or btn.nome:lower():find(texto:lower()) then
            pcall(function()
                btn.objeto:FireServer()
                return true
            end)
            pcall(function()
                btn.objeto:Click()
                return true
            end)
            
            if btn.pos and btn.size then
                local x = btn.pos.X + btn.size.X / 2
                local y = btn.pos.Y + btn.size.Y / 2
                pcall(function()
                    MoverMouse(x, y)
                    task.wait(0.1)
                    Clicar()
                    return true
                end)
            end
            return true
        end
    end
    return false
end

-- ========================================
-- DESCOBRIR MODO DE CAPTURA
-- ========================================
local function DescobrirModoCaptura()
    print("🔍 Descobrindo modo de captura...")
    
    -- Verifica se tem ProximityPrompt
    local pets = EncontrarPets()
    if #pets > 0 then
        local pet = pets[1]
        local prompt = pet:FindFirstChild("ProximityPrompt")
        if prompt then
            print("✅ Modo de captura: PROXIMITY PROMPT (tecla E)")
            return "prompt"
        end
    end
    
    -- Verifica se tem Remote Events de captura
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local nome = obj.Name:lower()
            if nome:find("capture") or nome:find("pet") or nome:find("catch") then
                print("✅ Modo de captura: REMOTE EVENT (" .. obj.Name .. ")")
                return "remote"
            end
        end
    end
    
    -- Verifica botões na UI
    local botoes = EncontrarTodosBotoes()
    for _, btn in pairs(botoes) do
        local texto = btn.texto:lower()
        if texto:find("capture") or texto:find("catch") or texto:find("pegar") or texto:find("farm") then
            print("✅ Modo de captura: UI BUTTON (" .. btn.texto .. ")")
            return "ui"
        end
    end
    
    print("⚠️ Modo de captura: CLICK (padrão)")
    return "click"
end

-- ========================================
-- CAPTURAR PET (AUTOMÁTICO)
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
    
    local camera = Workspace.CurrentCamera
    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    
    -- MODO 1: PROXIMITY PROMPT
    if modoCaptura == "prompt" then
        print("📌 Usando Proximity Prompt...")
        local prompt = pet:FindFirstChild("ProximityPrompt")
        if prompt then
            pcall(function()
                prompt:InputHoldBegin(Player)
                task.wait(0.3)
                prompt:InputHoldEnd(Player)
                print("✅ Prompt ativado")
            end)
        end
    end
    
    -- MODO 2: REMOTE EVENT
    if modoCaptura == "remote" then
        print("📌 Usando Remote Event...")
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local nome = obj.Name:lower()
                if nome:find("capture") or nome:find("pet") or nome:find("catch") then
                    pcall(function()
                        obj:FireServer("Capture", pet.Name, pet)
                        print("✅ Remote enviado: " .. obj.Name)
                    end)
                end
            end
        end
    end
    
    -- MODO 3: UI BUTTON
    if modoCaptura == "ui" then
        print("📌 Usando UI Button...")
        local textos = {"capture", "catch", "pegar", "farm", "pet", "place"}
        for _, texto in pairs(textos) do
            if ClicarBotaoPorTexto(texto) then
                print("✅ Botão clicado: " .. texto)
                break
            end
        end
    end
    
    -- MODO 4: CLICK (padrão)
    print("📌 Usando Click...")
    if onScreen then
        MoverMouse(pos.X, pos.Y)
        task.wait(0.1)
        Clicar()
        task.wait(0.3)
    end
    
    -- Clica repetidamente para encher a barra
    print("🖱️ Enchendo barra...")
    for i = 1, 50 do
        Clicar()
        if i % 10 == 0 then
            print("  📊 " .. i .. "/50")
        end
        task.wait(0.02)
    end
    
    task.wait(0.5)
    
    -- Verifica captura
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
    frame.Size = UDim2.new(0, 260, 0, 250)
    frame.Position = UDim2.new(0.5, -130, 0.5, -125)
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
    
    -- Status do modo
    local modoLabel = Instance.new("TextLabel")
    modoLabel.Parent = frame
    modoLabel.Size = UDim2.new(0.9, 0, 0, 20)
    modoLabel.Position = UDim2.new(0.05, 0, 0.18, 0)
    modoLabel.BackgroundTransparency = 1
    modoLabel.Text = "🔍 Modo: " .. modoCaptura
    modoLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    modoLabel.TextSize = 12
    modoLabel.Font = Enum.Font.Gotham
    
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
    
    local btnTeste = Instance.new("TextButton")
    btnTeste.Parent = frame
    btnTeste.Size = UDim2.new(0.8, 0, 0, 30)
    btnTeste.Position = UDim2.new(0.1, 0, 0.7, 0)
    btnTeste.BackgroundColor3 = Color3.fromRGB(180, 120, 40)
    btnTeste.Text = "🔍 TESTAR CAPTURA"
    btnTeste.TextColor3 = Color3.new(1, 1, 1)
    btnTeste.TextSize = 14
    btnTeste.Font = Enum.Font.GothamBold
    btnTeste.BorderSizePixel = 0
    
    local testeCorner = Instance.new("UICorner")
    testeCorner.Parent = btnTeste
    testeCorner.CornerRadius = UDim.new(0, 8)
    
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
        print("🔍 TESTANDO CAPTURA...")
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
print("  🔍 SCRIPT INTELIGENTE")
print("========================================")

-- Descobre o modo de captura
modoCaptura = DescobrirModoCaptura()
print("📌 Modo de captura detectado: " .. modoCaptura)

CriarMenu()

print("========================================")
print("  ✅ SCRIPT CARREGADO!")
print("  📌 Modo: " .. modoCaptura)
print("  📌 Clique em TESTAR CAPTURA")
print("  📌 Veja o console (F9)")
print("========================================")
