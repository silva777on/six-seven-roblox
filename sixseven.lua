--[[
    Six Seven - Modo Caça
    Game: [🍎] Capture e Domestique!
]]

print("🚀 CARREGANDO MODO CAÇA...")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- ========================================
-- VARIÁVEIS
-- ========================================
local espActive = false
local espObjects = {}
local petPositions = {}

-- ========================================
-- FUNÇÃO PARA ENCONTRAR TUDO QUE NÃO É ESTÁTICO
-- ========================================
local function FindDynamicObjects()
    local objects = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Verifica se é um modelo
        if obj:IsA("Model") then
            -- Ignora o próprio jogador
            if obj == Player.Character then
                continue
            end
            
            -- Ignora objetos com nomes de placa ou fixos
            local name = obj.Name:lower()
            if name:find("placa") or name:find("sign") or name:find("wall") or name:find("floor") or name:find("ground") or name:find("base") then
                continue
            end
            
            -- Verifica se tem partes (quase todo modelo tem)
            local hasParts = false
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("BasePart") then
                    hasParts = true
                    break
                end
            end
            
            if hasParts then
                table.insert(objects, obj)
            end
        end
    end
    
    return objects
end

-- ========================================
-- FUNÇÃO PARA VERIFICAR SE ESTÁ SE MOVENDO
-- ========================================
local function IsMoving(obj)
    if not obj then return false end
    local hrp = obj:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Guarda posição anterior
    if not petPositions[obj] then
        petPositions[obj] = hrp.Position
        return false
    end
    
    local oldPos = petPositions[obj]
    local newPos = hrp.Position
    local distance = (oldPos - newPos).Magnitude
    
    -- Atualiza posição
    petPositions[obj] = newPos
    
    -- Se moveu mais de 0.5 unidades, está se movendo
    return distance > 0.5
end

-- ========================================
-- ESP
-- ========================================
local function CreateESP(obj, color)
    if not obj or espObjects[obj] then return end
    
    pcall(function()
        local h = Instance.new("Highlight")
        h.Parent = obj
        h.FillColor = color or Color3.fromRGB(0, 255, 0)
        h.FillTransparency = 0.2
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.OutlineTransparency = 0.1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = true
        espObjects[obj] = h
        print("✅ Destacado: " .. obj.Name)
    end)
end

local function RemoveESP(obj)
    if espObjects[obj] then
        pcall(function() espObjects[obj]:Destroy() end)
        espObjects[obj] = nil
    end
end

local function UpdateESP()
    if not espActive then
        for obj, _ in pairs(espObjects) do
            RemoveESP(obj)
        end
        espObjects = {}
        return
    end
    
    -- Encontra todos os objetos
    local objects = FindDynamicObjects()
    
    -- Para cada objeto, verifica se está se movendo
    for _, obj in pairs(objects) do
        if obj and obj:IsA("Model") then
            -- Se está se movendo, destaca em VERMELHO
            if IsMoving(obj) then
                CreateESP(obj, Color3.fromRGB(255, 0, 0))
            else
                -- Se não está se movendo, destaca em VERDE (possível pet parado)
                CreateESP(obj, Color3.fromRGB(0, 255, 0))
            end
        end
    end
    
    -- Remove ESP de objetos que não existem mais
    local currentObjects = {}
    for _, obj in pairs(objects) do
        currentObjects[obj] = true
    end
    for obj, _ in pairs(espObjects) do
        if not currentObjects[obj] or not obj:IsA("Model") then
            RemoveESP(obj)
        end
    end
end

-- ========================================
-- AUTO CAPTURE (MODO CLICK)
-- ========================================
local autoCapture = false
local autoRunning = false

local function TryCapture(obj)
    if not obj then return false end
    
    pcall(function()
        -- Tenta encontrar o ponto de clique
        local hrp = obj:FindFirstChild("HumanoidRootPart")
        if hrp then
            local mouse = Player:GetMouse()
            if mouse then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
                    task.wait(0.1)
                    mouse.Button1Click()
                    print("🖱️ Clique em: " .. obj.Name)
                    return true
                end
            end
        end
    end)
    return false
end

local function AutoCaptureLoop()
    while autoCapture and autoRunning do
        task.spawn(function()
            local objects = FindDynamicObjects()
            local target = nil
            local minDist = math.huge
            
            -- Pega o objeto mais próximo
            for _, obj in pairs(objects) do
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        target = obj
                    end
                end
            end
            
            if target then
                print("🎯 Tentando capturar: " .. target.Name)
                TryCapture(target)
                task.wait(2)
            else
                task.wait(1)
            end
        end)
        task.wait(0.1)
    end
end

-- ========================================
-- CRIAR MENU
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenMobile"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 300, 0, 220)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -110)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 12)

    -- Título
    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    title.BackgroundTransparency = 0.3
    title.Text = "✧ Six Seven - Caça"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold

    local titleCorner = Instance.new("UICorner")
    titleCorner.Parent = title
    titleCorner.CornerRadius = UDim.new(0, 12)

    -- Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0

    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = closeBtn
    closeCorner.CornerRadius = UDim.new(1, 0)

    -- Container
    local content = Instance.new("Frame")
    content.Parent = mainFrame
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1

    -- Botão ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = content
    espBtn.Size = UDim2.new(1, 0, 0, 40)
    espBtn.Position = UDim2.new(0, 0, 0, 0)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    espBtn.Text = "🔴 ESP: OFF"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 16
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0

    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 8)

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP: ON" or "🔴 ESP: OFF"
        espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        print("ESP:", espActive and "ON" or "OFF")
        if espActive then
            UpdateESP()
        else
            for obj, _ in pairs(espObjects) do
                RemoveESP(obj)
            end
            espObjects = {}
        end
    end)

    -- Botão Auto Capture
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = content
    autoBtn.Size = UDim2.new(1, 0, 0, 40)
    autoBtn.Position = UDim2.new(0, 0, 0, 50)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    autoBtn.Text = "🔴 Auto: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 16
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0

    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 8)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 Auto: ON" or "🔴 Auto: OFF"
        autoBtn.BackgroundColor3 = autoCapture and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 100)
        print("Auto Capture:", autoCapture and "ON" or "OFF")
        if autoCapture then
            if not autoRunning then
                autoRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoRunning = false
        end
    end)

    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = content
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 0, 100)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Status: Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.Gotham

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 45, 0, 45)
    floatBtn.Position = UDim2.new(0.93, -22, 0.93, -22)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✧"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 24
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.BorderSizePixel = 0
    floatBtn.Visible = false

    local floatCorner = Instance.new("UICorner")
    floatCorner.Parent = floatBtn
    floatCorner.CornerRadius = UDim.new(1, 0)

    local function OpenMenu()
        mainFrame.Visible = true
        floatBtn.Visible = false
    end

    local function CloseMenu()
        mainFrame.Visible = false
        floatBtn.Visible = true
    end

    closeBtn.MouseButton1Click:Connect(CloseMenu)
    floatBtn.MouseButton1Click:Connect(OpenMenu)

    -- Atualiza status
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindDynamicObjects()
            statusLabel.Text = "📊 Objetos: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF")
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- LOOP DE ATUALIZAÇÃO
-- ========================================
task.spawn(function()
    while true do
        task.wait(1)
        if espActive then
            UpdateESP()
        end
    end
end)

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - MODO CAÇA")
print("========================================")

-- Cria o menu
pcall(CreateMenu)

-- Conta objetos iniciais
local objects = FindDynamicObjects()
print("🔍 Encontrados " .. #objects .. " objetos no mapa")
print("   🔴 Vermelho = se movendo")
print("   🟢 Verde = parado")

print("========================================")
print("  ✅ PRONTO!")
print("  📌 Ligue o ESP para ver os objetos")
print("  📌 Objetos em movimento ficam VERMELHOS")
print("========================================")
