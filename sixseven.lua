-- SIX SEVEN - VERSÃO SIMPLIFICADA
-- Cole este script inteiro em um LocalScript

print("🚀 INICIANDO SIX SEVEN...")

-- ===== SERVIÇOS =====
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

-- ===== CONFIGURAÇÕES =====
local config = {
    speed = 16,
    jump = 50,
    espOn = false,
    autoOn = false,
    countdownTime = 5, -- 1 a 5 segundos
    petsCapturados = {}
}

-- ===== FUNÇÕES =====
local function FindPets()
    local pets = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                local name = obj.Name:lower()
                if not name:find("base") and not name:find("floor") and not name:find("wall") then
                    if not name:find("npc") and not name:find("humano") then
                        table.insert(pets, obj)
                    end
                end
            end
        end
    end
    return pets
end

local function TeleportTo(pos)
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(pos)
        end)
        task.wait(0.2)
    end
end

local function ClickPet(pet)
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local cam = workspace.CurrentCamera
    if not cam then return false end
    
    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    pcall(function()
        local mouse = Player:GetMouse()
        if mouse then
            mouse.Move(Vector2.new(pos.X, pos.Y))
            task.wait(0.1)
            mouse.Button1Click()
        end
    end)
    return true
end

local function CapturePet(pet)
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    print("🎯 Capturando: " .. pet.Name)
    TeleportTo(hrp.Position + Vector3.new(0, 3, 0))
    local ok = ClickPet(pet)
    task.wait(1)
    return ok
end

-- ===== CRIAR MENU =====
local function CreateMenu()
    -- Tela principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSeven"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    
    -- Frame principal
    local main = Instance.new("Frame")
    main.Parent = screenGui
    main.Size = UDim2.new(0, 200, 0, 280)
    main.Position = UDim2.new(0.02, 0, 0.5, -140)
    main.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = main
    corner.CornerRadius = UDim.new(0, 10)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Parent = main
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✦ SIX SEVEN"
    title.TextColor3 = Color3.fromRGB(180, 150, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    
    -- Fechar
    local close = Instance.new("TextButton")
    close.Parent = main
    close.Size = UDim2.new(0, 24, 0, 24)
    close.Position = UDim2.new(1, -28, 0, 3)
    close.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 14
    close.Font = Enum.Font.GothamBold
    close.BorderSizePixel = 0
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = close
    closeCorner.CornerRadius = UDim.new(0, 5)
    
    -- Container
    local container = Instance.new("Frame")
    container.Parent = main
    container.Size = UDim2.new(0.9, 0, 0.75, 0)
    container.Position = UDim2.new(0.05, 0, 0.13, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Helper: criar linha com label e input
    local function MakeRow(labelText, defaultVal, callback)
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.BackgroundTransparency = 1
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(200, 200, 255)
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local box = Instance.new("TextBox")
        box.Parent = frame
        box.Size = UDim2.new(0, 50, 0, 24)
        box.Position = UDim2.new(0.7, 0, 0.5, -12)
        box.BackgroundColor3 = Color3.fromRGB(30, 28, 50)
        box.Text = tostring(defaultVal)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.TextSize = 13
        box.Font = Enum.Font.GothamBold
        box.TextXAlignment = Enum.TextXAlignment.Center
        box.BorderSizePixel = 0
        
        local boxCorner = Instance.new("UICorner")
        boxCorner.Parent = box
        boxCorner.CornerRadius = UDim.new(0, 4)
        
        box.FocusLost:Connect(function()
            local num = tonumber(box.Text)
            if num then
                callback(num)
            else
                box.Text = tostring(defaultVal)
            end
        end)
        
        return frame
    end
    
    -- Velocidade
    MakeRow("🏃 Velocidade", config.speed, function(v)
        config.speed = math.clamp(v, 0, 100)
        if Humanoid then Humanoid.WalkSpeed = 16 + (config.speed / 100) * 84 end
    end)
    
    -- Pulo
    MakeRow("🦘 Pulo", config.jump, function(v)
        config.jump = math.clamp(v, 0, 100)
        if Humanoid then Humanoid.JumpPower = 50 + (config.jump / 100) * 50 end
    end)
    
    -- Tempo (1-5 segundos)
    MakeRow("⏱️ Tempo (1-5s)", config.countdownTime, function(v)
        config.countdownTime = math.clamp(v, 1, 5)
        print("⏱️ Tempo ajustado: " .. config.countdownTime .. "s")
    end)
    
    -- Botão ESP
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = container
    espBtn.Size = UDim2.new(1, 0, 0, 28)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 120)
    espBtn.Text = "🔴 ESP: OFF"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 13
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 5)
    
    espBtn.MouseButton1Click:Connect(function()
        config.espOn = not config.espOn
        espBtn.Text = config.espOn and "🟢 ESP: ON" or "🔴 ESP: OFF"
        espBtn.BackgroundColor3 = config.espOn and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(60, 50, 120)
    end)
    
    -- Botão AUTO
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = container
    autoBtn.Size = UDim2.new(1, 0, 0, 28)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 120)
    autoBtn.Text = "🔴 AUTO: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 13
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 5)
    
    local autoRunning = false
    
    autoBtn.MouseButton1Click:Connect(function()
        config.autoOn = not config.autoOn
        autoBtn.Text = config.autoOn and "🟢 AUTO: ON" or "🔴 AUTO: OFF"
        autoBtn.BackgroundColor3 = config.autoOn and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(60, 50, 120)
        
        if config.autoOn and not autoRunning then
            autoRunning = true
            task.spawn(function()
                while config.autoOn and autoRunning do
                    local pets = FindPets()
                    local target = nil
                    local minDist = math.huge
                    
                    for _, pet in pairs(pets) do
                        if not config.petsCapturados[pet] then
                            local hrp = pet:FindFirstChild("HumanoidRootPart")
                            if hrp and RootPart then
                                local dist = (RootPart.Position - hrp.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    target = pet
                                end
                            end
                        end
                    end
                    
                    if target then
                        local ok = CapturePet(target)
                        if ok then
                            config.petsCapturados[target] = true
                            print("✅ " .. target.Name .. " capturado!")
                            
                            -- Mostra contador
                            if countdownLabel then
                                countdownLabel.Parent.Visible = true
                                for i = config.countdownTime, 1, -1 do
                                    if not config.autoOn then break end
                                    countdownLabel.Text = "⏳ " .. i .. "s"
                                    task.wait(1)
                                end
                                countdownLabel.Parent.Visible = false
                            end
                        end
                        task.wait(1)
                    else
                        task.wait(0.5)
                    end
                end
            end)
        elseif not config.autoOn then
            autoRunning = false
        end
    end)
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Parent = main
    status.Size = UDim2.new(0.9, 0, 0, 18)
    status.Position = UDim2.new(0.05, 0, 0.9, 0)
    status.BackgroundTransparency = 1
    status.Text = "📊 Pronto"
    status.TextColor3 = Color3.fromRGB(150, 150, 200)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    
    -- Contador na tela
    local countFrame = Instance.new("Frame")
    countFrame.Parent = screenGui
    countFrame.Size = UDim2.new(0, 140, 0, 70)
    countFrame.Position = UDim2.new(0.5, -70, 0.5, -35)
    countFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    countFrame.BackgroundTransparency = 0.7
    countFrame.BorderSizePixel = 0
    countFrame.Visible = false
    countFrame.ZIndex = 999
    
    local countCorner = Instance.new("UICorner")
    countCorner.Parent = countFrame
    countCorner.CornerRadius = UDim.new(0, 12)
    
    local countStroke = Instance.new("UIStroke")
    countStroke.Parent = countFrame
    countStroke.Color = Color3.fromRGB(255, 200, 50)
    countStroke.Thickness = 2
    
    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Parent = countFrame
    countdownLabel.Size = UDim2.new(1, 0, 1, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "⏳ 5s"
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownLabel.TextSize = 40
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.TextScaled = true
    
    -- Botão flutuante (minimizar)
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 36, 0, 36)
    floatBtn.Position = UDim2.new(0.02, 0, 0.5, 20)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✦"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 20
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.BorderSizePixel = 0
    floatBtn.Visible = false
    
    local floatCorner = Instance.new("UICorner")
    floatCorner.Parent = floatBtn
    floatCorner.CornerRadius = UDim.new(1, 0)
    
    close.MouseButton1Click:Connect(function()
        main.Visible = false
        floatBtn.Visible = true
    end)
    
    floatBtn.MouseButton1Click:Connect(function()
        main.Visible = true
        floatBtn.Visible = false
    end)
    
    -- Atualiza status
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindPets()
            status.Text = "📊 Pets: " .. count .. " | ESP: " .. (config.espOn and "ON" or "OFF")
        end
    end)
    
    print("✅ MENU CRIADO!")
    return screenGui
end

-- ===== INICIAR =====
print("========================================")
print("  ✧ SIX SEVEN - SIMPLIFICADO")
print("========================================")
print("  ✅ Script carregado!")
print("  📌 Ajuste o tempo entre 1-5 segundos")
print("========================================")

-- Criar menu com segurança
local success, err = pcall(CreateMenu)
if success then
    print("✅ Menu criado com sucesso!")
else
    print("❌ Erro ao criar menu: " .. tostring(err))
end

-- Aplicar velocidade e pulo
task.wait(0.5)
if Humanoid then
    Humanoid.WalkSpeed = 16 + (config.speed / 100) * 84
    Humanoid.JumpPower = 50 + (config.jump / 100) * 50
end

-- Recarregar ao renascer
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    task.wait(0.5)
    if Humanoid then
        Humanoid.WalkSpeed = 16 + (config.speed / 100) * 84
        Humanoid.JumpPower = 50 + (config.jump / 100) * 50
    end
end)

print("✅ SIX SEVEN PRONTO!")
