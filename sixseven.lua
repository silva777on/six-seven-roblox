--[[
    Six Seven - Versão Mobile
    Game: [🍎] Capture e Domestique!
]]

print("🚀 CARREGANDO SIX SEVEN MOBILE...")

-- ========================================
-- PROCURA TUDO QUE É CLICÁVEL
-- ========================================
local function FindClickableObjects()
    local objects = {}
    
    -- Procura por qualquer coisa com ClickDetector
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") and obj.Parent then
            table.insert(objects, obj.Parent)
            print("🔍 ClickDetector encontrado em: " .. obj.Parent.Name)
        end
    end
    
    -- Procura por qualquer coisa com BillboardGui
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") and obj.Parent then
            table.insert(objects, obj.Parent)
            print("🔍 BillboardGui encontrado em: " .. obj.Parent.Name)
        end
    end
    
    return objects
end

-- ========================================
-- ESP
-- ========================================
local espObjects = {}
local espActive = false

local function CreateESP(obj)
    if not obj or espObjects[obj] then return end
    
    pcall(function()
        local h = Instance.new("Highlight")
        h.Parent = obj
        h.FillColor = Color3.fromRGB(0, 255, 0)
        h.FillTransparency = 0.2
        h.OutlineColor = Color3.fromRGB(255, 255, 0)
        h.OutlineTransparency = 0.1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = true
        espObjects[obj] = h
        print("✅ ESP criado para: " .. obj.Name)
    end)
end

local function RemoveESP(obj)
    if espObjects[obj] then
        pcall(function() espObjects[obj]:Destroy() end)
        espObjects[obj] = nil
    end
end

-- ========================================
-- AUTO CAPTURE
-- ========================================
local autoCapture = false
local autoRunning = false

local function ClickOnObject(obj)
    pcall(function()
        -- Tenta clicar via mouse
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        if mouse and obj:FindFirstChild("HumanoidRootPart") then
            local hrp = obj.HumanoidRootPart
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
                mouse.Button1Click()
                print("🖱️ Clique executado em: " .. obj.Name)
            end
        end
    end)
end

-- ========================================
-- CRIAR MENU SIMPLES
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenMobile"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
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
    title.Text = "✧ Six Seven"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 18
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
        
        if espActive then
            print("✅ ESP ATIVADO!")
            local objects = FindClickableObjects()
            for _, obj in pairs(objects) do
                CreateESP(obj)
            end
        else
            print("⏹️ ESP DESATIVADO!")
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
        
        if autoCapture then
            print("✅ AUTO CAPTURE ATIVADO!")
            if not autoRunning then
                autoRunning = true
                task.spawn(function()
                    while autoCapture and autoRunning do
                        local objects = FindClickableObjects()
                        if #objects > 0 then
                            print("🎯 Tentando capturar: " .. objects[1].Name)
                            ClickOnObject(objects[1])
                            task.wait(2)
                        else
                            print("⏳ Nenhum objeto encontrado...")
                            task.wait(1)
                        end
                    end
                end)
            end
        else
            print("⏹️ AUTO CAPTURE DESATIVADO!")
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
            local count = #FindClickableObjects()
            statusLabel.Text = "📊 Objetos: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF")
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN MOBILE")
print("========================================")

-- Cria o menu
local success, err = pcall(CreateMenu)
if success then
    print("✅ Menu criado com sucesso!")
else
    print("❌ Erro ao criar menu: " .. tostring(err))
end

-- Procura objetos iniciais
local initialObjects = FindClickableObjects()
print("🔍 Encontrados " .. #initialObjects .. " objetos interativos")

print("========================================")
print("  ✅ PRONTO PARA USAR!")
print("  📌 Clique em ESP para ligar")
print("  📌 Clique em Auto para ligar")
print("========================================")
