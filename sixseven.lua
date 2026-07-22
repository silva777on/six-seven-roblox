--[[
    SCRIPT DE TESTE PARA O JOGO
    Vamos descobrir como capturar os pets
]]

print("🔄 INICIANDO DIAGNÓSTICO...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

-- ========================================
-- PASSO 1: CRIAR GUI DE TESTE
-- ========================================
local function CriarGUI()
    print("📌 PASSO 1: Criando GUI...")
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DiagnosticoGUI"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
    frame.BackgroundTransparency = 0.1
    frame.Active = true
    frame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 12)
    
    local titulo = Instance.new("TextLabel")
    titulo.Parent = frame
    titulo.Size = UDim2.new(1, 0, 0, 40)
    titulo.BackgroundColor3 = Color3.fromRGB(80, 0, 200)
    titulo.BackgroundTransparency = 0.3
    titulo.Text = "🔍 DIAGNÓSTICO"
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.TextSize = 20
    titulo.Font = Enum.Font.GothamBold
    
    local texto = Instance.new("TextLabel")
    texto.Parent = frame
    texto.Size = UDim2.new(1, -20, 1, -60)
    texto.Position = UDim2.new(0, 10, 0, 50)
    texto.BackgroundTransparency = 1
    texto.Text = "Carregando..."
    texto.TextColor3 = Color3.fromRGB(200, 200, 255)
    texto.TextSize = 14
    texto.Font = Enum.Font.Gotham
    texto.TextXAlignment = Enum.TextXAlignment.Left
    texto.TextYAlignment = Enum.TextYAlignment.Top
    texto.TextWrapped = true
    
    local function AtualizarTexto(msg)
        texto.Text = texto.Text .. "\n" .. msg
        print(msg)
    end
    
    return gui, AtualizarTexto
end

local gui, log = CriarGUI()

-- ========================================
-- PASSO 2: ANALISAR O JOGO
-- ========================================
log("📌 PASSO 2: Analisando o jogo...")

-- Verifica o nome do jogo
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
log("🎮 Jogo: " .. gameName)

-- ========================================
-- PASSO 3: PROCURAR PETS
-- ========================================
log("📌 PASSO 3: Procurando pets...")

local function EncontrarPets()
    local pets = {}
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= Player.Character and not Players:GetPlayerFromCharacter(obj) then
                local nome = obj.Name:lower()
                if not nome:find("base") and not nome:find("floor") and not nome:find("wall") then
                    if not nome:find("npc") and not nome:find("humano") then
                        table.insert(pets, obj)
                        count = count + 1
                    end
                end
            end
        end
    end
    
    return pets, count
end

local pets, totalPets = EncontrarPets()
log("🐾 Pets encontrados: " .. totalPets)

for i, pet in pairs(pets) do
    log("  - " .. pet.Name)
end

-- ========================================
-- PASSO 4: ANALISAR O RECURSOS
-- ========================================
log("📌 PASSO 4: Analisando recursos...")

-- Verifica ReplicatedStorage
log("📡 ReplicatedStorage:")
for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    log("  - " .. obj.Name .. " (" .. obj.ClassName .. ")")
end

-- Verifica os pets individualmente
if #pets > 0 then
    local pet = pets[1]
    log("🔍 Analisando pet: " .. pet.Name)
    for _, obj in pairs(pet:GetChildren()) do
        log("  - " .. obj.Name .. " (" .. obj.ClassName .. ")")
    end
end

-- ========================================
-- PASSO 5: TESTAR CAPTURA
-- ========================================
log("📌 PASSO 5: Testando captura...")

local function TestarCaptura(pet)
    if not pet then 
        log("❌ Nenhum pet para testar")
        return 
    end
    
    log("🎯 Testando captura em: " .. pet.Name)
    
    -- Tenta Remote
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            log("📡 Tentando: " .. obj.Name)
            pcall(function()
                obj:FireServer("Capture", pet.Name, pet)
                log("  ✅ Enviado para: " .. obj.Name)
            end)
        end
    end
    
    -- Tenta ProximityPrompt
    local prompt = pet:FindFirstChild("ProximityPrompt")
    if prompt then
        log("🎯 Tentando ProximityPrompt...")
        pcall(function()
            prompt:InputHoldBegin(Player)
            task.wait(0.3)
            prompt:InputHoldEnd(Player)
            log("  ✅ Prompt ativado!")
        end)
    end
    
    -- Tenta clicar
    log("🖱️ Tentando clicar...")
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local camera = Workspace.CurrentCamera
        if camera then
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local VirtualInputManager = game:GetService("VirtualInputManager")
                pcall(function()
                    VirtualInputManager:SendMouseMovement(pos.X, pos.Y, Enum.VirtualKeyMode.Delta, game)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, false, game, 0)
                    log("  ✅ Clique enviado!")
                end)
            end
        end
    end
end

-- Testa com o primeiro pet
if #pets > 0 then
    TestarCaptura(pets[1])
else
    log("❌ Nenhum pet encontrado para testar")
end

-- ========================================
-- PASSO 6: BOTÕES DE AÇÃO
-- ========================================
log("📌 PASSO 6: Criando botões...")

local function CriarBotao(frame, texto, y, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Size = UDim2.new(0.8, 0, 0, 35)
    btn.Position = UDim2.new(0.1, 0, y, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btn.Text = texto
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.Parent = btn
    corner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Botão para capturar pet mais próximo
CriarBotao(gui, "🎯 Capturar Pet Mais Próximo", 0.80, function()
    log("🎯 Capturando pet mais próximo...")
    local pets, _ = EncontrarPets()
    local alvo = nil
    local distMin = math.huge
    local char = Player.Character
    
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, pet in pairs(pets) do
                local hrp = pet:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < distMin then
                        distMin = dist
                        alvo = pet
                    end
                end
            end
        end
    end
    
    if alvo then
        log("🎯 Alvo: " .. alvo.Name .. " (Distância: " .. math.floor(distMin) .. "m)")
        TestarCaptura(alvo)
    else
        log("❌ Nenhum pet próximo!")
    end
end)

-- Botão para listar pets
CriarBotao(gui, "🔄 Atualizar Lista", 0.90, function()
    log("🔄 Atualizando...")
    local pets, total = EncontrarPets()
    log("🐾 Pets encontrados: " .. total)
    for _, pet in pairs(pets) do
        log("  - " .. pet.Name)
    end
end)

-- ========================================
-- FINALIZAR
-- ========================================
log("========================================")
log("✅ DIAGNÓSTICO COMPLETO!")
log("📌 O que fazer agora:")
log("  1. Veja o que aparece acima")
log("  2. Clique em 'Capturar Pet Mais Próximo'")
log("  3. Veja no console (F9) o que acontece")
log("========================================")

print("✅ SCRIPT DE DIAGNÓSTICO FINALIZADO!")
