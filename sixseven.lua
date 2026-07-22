-- SIX SEVEN - VERSÃO COMPLETA COM + E -
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
    countdownTime = 5,
    petsCapturados = {}
}

local espObjects = {}
local petPositions = {}

-- ===== FUNÇÃO PARA ENCONTRAR PETS (SÓ OS QUE SE MOVEM) =====
local function FindPets()
    local pets = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj == Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            
            local name = obj.Name:lower()
            if name:find("base") or name:find("floor") or name:find("wall") then continue end
            if name:find("npc") or name:find("humano") or name:find("personagem") then continue end
            if name:find("coruja") or name:find("owl") then continue end
            
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                
                -- Verifica se o pet se moveu
                if petPositions[obj] then
                    local oldPos = petPositions[obj]
                    local dist = (currentPos - oldPos).Magnitude
                    if dist > 0.1 then
                        table.insert(pets, obj)
                    end
                else
                    table.insert(pets, obj)
                end
                
                petPositions[obj] = currentPos
            end
        end
    end
    return pets
end

-- ===== FUNÇÕES DE VELOCIDADE E PULO =====
local function ApplySpeed()
    if Humanoid then
        Humanoid.WalkSpeed = 16 + (config.speed / 100) * 84
    end
end

local function ApplyJump()
    if Humanoid then
        Humanoid.JumpPower = 50 + (config.jump / 100) * 50
    end
end

-- ===== TELEPORTE =====
local function TeleportTo(pos)
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(pos)
        end)
        task.wait(0.2)
    end
end

-- ===== CLICAR NO PET =====
local function ClickPet(pet)
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local cam = workspace.CurrentCamera
    if not cam then return false end
    
    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    local success = false
    pcall(function()
        local mouse = Player:GetMouse()
        if mouse then
            mouse.Move(Vector2.new(pos.X, pos.Y))
            task.wait(0.1)
            mouse.Button1Click()
            success = true
        end
    end)
    return success
end

-- ===== CAPTURAR PET =====
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

-- ===== SISTEMA ESP =====
local function CreateESP(pet)
    if espObjects[pet] then return end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = pet
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = hrp
    billboard.Size = UDim2.new(0, 120, 0, 25)
    billboard.Adornee = hrp
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.Text = "🐾 " .. pet.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    espObjects[pet] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label
    }
end

local function RemoveESP(pet)
    if espObjects[pet] then
        if espObjects[pet].Highlight then espObjects[pet].Highlight:Destroy() end
        if espObjects[pet].Billboard then espObjects[pet].Billboard:Destroy() end
        espObjects[pet] = nil
    end
end

local function UpdateESP()
    if not config.espOn then
        for pet, _ in pairs(espObjects) do
            RemoveESP(pet)
        end
        espObjects = {}
        return
    end
    
    local pets = FindPets()
    for _, pet in pairs(pets) do
        if pet and pet:IsA("Model") then
            CreateESP(pet)
        end
    end
    
    -- Remove ESP de pets que não existem mais
    local currentPets = {}
    for _, pet in pairs(pets) do
        currentPets[pet] = true
    end
    for pet, _ in pairs(espObjects) do
        if not currentPets[pet] or not pet:IsA("Model") then
            RemoveESP(pet)
        end
    end
end

-- ===== CRIAR MENU COM + E - =====
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSeven"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    
    -- Frame principal
    local main = Instance.new("Frame")
    main.Parent = screenGui
    main.Size = UDim2.new(0, 210, 0, 310)
    main.Position = UDim2.new(0.02, 0, 0.5, -155)
    main.BackgroundColor3 = Color3.fromRGB(12, 10, 22)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.Parent = main
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = main
    stroke.Color = Color3.fromRGB(138, 43, 226)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Parent = main
    title.Size = UDim2.new(1, -50, 0, 30)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✦ SIX SEVEN"
    title.TextColor3 = Color3.fromRGB(180, 150, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Fechar
    local close = Instance.new("TextButton")
    close.Parent = main
    close.Size = UDim2.new(0, 22, 0, 22)
    close.Position = UDim2.new(1, -26, 0, 4)
    close.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 12
    close.Font = Enum.Font.GothamBold
    close.BorderSizePixel = 0
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = close
    closeCorner.CornerRadius = UDim.new(0, 5)
    
    -- Separador
    local sep = Instance.new("Frame")
    sep.Parent = main
    sep.Size = UDim2.new(0.9, 0, 0, 1)
    sep.Position = UDim2.new(0.05, 0, 0.12, 0)
    sep.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    sep.BackgroundTransparency = 0.5
    
    -- Container
    local container = Instance.new("Frame")
    container.Parent = main
    container.Size = UDim2.new(0.92, 0, 0.75, 0)
    container.Position = UDim2.new(0.04, 0, 0.16, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- ===== FUNÇÃO PARA CRIAR LINHA COM + E - =====
    local function CreateSlider(labelText, defaultValue, minVal, maxVal, step, callback)
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundTransparency = 1
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(200, 200, 255)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Botão -
        local btnMinus = Instance.new("TextButton")
        btnMinus.Parent = frame
        btnMinus.Size = UDim2.new(0, 22, 0, 22)
        btnMinus.Position = UDim2.new(0.6, 0, 0.5, -11)
        btnMinus.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
        btnMinus.Text = "−"
        btnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnMinus.TextSize = 16
        btnMinus.Font = Enum.Font.GothamBold
        btnMinus.BorderSizePixel = 0
        
        local minusCorner = Instance.new("UICorner")
        minusCorner.Parent = btnMinus
        minusCorner.CornerRadius = UDim.new(0, 4)
        
        -- Valor
        local valueBox = Instance.new("TextBox")
        valueBox.Parent = frame
        valueBox.Size = UDim2.new(0, 35, 0, 22)
        valueBox.Position = UDim2.new(0.74, 0, 0.5, -11)
        valueBox.BackgroundColor3 = Color3.fromRGB(30, 28, 55)
        valueBox.Text = tostring(defaultValue)
        valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueBox.TextSize = 12
        valueBox.Font = Enum.Font.GothamBold
        valueBox.TextXAlignment = Enum.TextXAlignment.Center
        valueBox.BorderSizePixel = 0
        valueBox.ClearTextOnFocus = false
        
        local valueCorner = Instance.new("UICorner")
        valueCorner.Parent = valueBox
        valueCorner.CornerRadius = UDim.new(0, 4)
        
        -- Botão +
        local btnPlus = Instance.new("TextButton")
        btnPlus.Parent = frame
        btnPlus.Size = UDim2.new(0, 22, 0, 22)
        btnPlus.Position = UDim2.new(0.88, 0, 0.5, -11)
        btnPlus.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
        btnPlus.Text = "+"
        btnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnPlus.TextSize = 16
        btnPlus.Font = Enum.Font.GothamBold
        btnPlus.BorderSizePixel = 0
        
        local plusCorner = Instance.new("UICorner")
        plusCorner.Parent = btnPlus
        plusCorner.CornerRadius = UDim.new(0, 4)
        
        local currentValue = defaultValue
        
        local function UpdateValue(newValue)
            newValue = math.round(math.clamp(newValue, minVal, maxVal) / step) * step
            if step < 1 then
                newValue = math.round(newValue * 2) / 2
            end
            currentValue = newValue
            valueBox.Text = tostring(newValue)
            callback(newValue)
        end
        
        btnMinus.MouseButton1Click:Connect(function()
            UpdateValue(currentValue - step)
        end)
        
        btnPlus.MouseButton1Click:Connect(function()
            UpdateValue(currentValue + step)
        end)
        
        valueBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local num = tonumber(valueBox.Text)
                if num then
                    UpdateValue(num)
                else
                    valueBox.Text = tostring(currentValue)
                end
            end
        end)
        
        return frame
    end
    
    -- ===== SLIDERS =====
    -- Velocidade
    CreateSlider("🏃 Velocidade", config.speed, 0, 100, 5, function(v)
        config.speed = v
        ApplySpeed()
    end)
    
    -- Pulo
    CreateSlider("🦘 Pulo", config.jump, 0, 100, 5, function(v)
        config.jump = v
        ApplyJump()
    end)
    
    -- Tempo (1-5 segundos, passo 0.5)
    CreateSlider("⏱️ Tempo (1-5s)", config.countdownTime, 1, 5, 0.5, function(v)
        config.countdownTime = v
        print("⏱️ Tempo ajustado: " .. v .. "s")
    end)
    
    -- ===== BOTÃO ESP =====
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
        if config.espOn then
            UpdateESP()
        else
            for pet, _ in pairs(espObjects) do
                RemoveESP(pet)
            end
            espObjects = {}
        end
    end)
    
    -- ===== BOTÃO AUTO =====
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
    local countdownLabel = nil
    
    autoBtn.MouseButton1Click:Connect(function()
        config.autoOn = not config.autoOn
        autoBtn.Text = config.autoOn and "🟢 AUTO: ON" or "🔴 AUTO: OFF"
        autoBtn.BackgroundColor3 = config.autoOn and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(60, 50, 120)
        
        if config.autoOn and not autoRunning then
            autoRunning = true
            config.petsCapturados = {}
            
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
    
    -- ===== CONTADOR NA TELA =====
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
    
    -- ===== STATUS =====
    local status = Instance.new("TextLabel")
    status.Parent = main
    status.Size = UDim2.new(0.9, 0, 0, 18)
    status.Position = UDim2.new(0.05, 0, 0.9, 0)
    status.BackgroundTransparency = 1
    status.Text = "📊 Pronto"
    status.TextColor3 = Color3.fromRGB(150, 150, 200)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    
    -- ===== BOTÃO FLUTUANTE =====
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
    
    -- ===== ATUALIZA STATUS E ESP =====
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #FindPets()
            status.Text = "📊 Pets: " .. count .. " | ESP: " .. (config.espOn and "ON" or "OFF")
            
            -- Atualiza ESP automaticamente
            if config.espOn then
                UpdateESP()
            end
        end
    end)
    
    -- Monitora novos pets
    workspace.DescendantAdded:Connect(function(obj)
        if config.espOn and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                task.wait(0.1)
                UpdateESP()
            end
        end
    end)
    
    print("✅ MENU CRIADO!")
    return screenGui
end

-- ===== INICIAR =====
print("========================================")
print("  ✧ SIX SEVEN - COMPLETO")
print("========================================")
print("  ✅ Botões + e - para ajustar")
print("  ✅ ESP destaca pets em movimento")
print("  ✅ Tempo ajustável de 1 a 5 segundos")
print("========================================")

local success, err = pcall(CreateMenu)
if success then
    print("✅ Menu criado!")
else
    print("❌ Erro: " .. tostring(err))
end

task.wait(0.5)
ApplySpeed()
ApplyJump()

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    Humanoid = newChar:FindFirstChild("Humanoid")
    task.wait(0.5)
    ApplySpeed()
    ApplyJump()
end)

print("✅ SIX SEVEN PRONTO!")
