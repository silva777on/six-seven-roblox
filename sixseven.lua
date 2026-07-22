--[[
    SIX SEVEN - COMPLETO (Com Teleporte para Ilhas)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN - COMPLETO...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Settings = {
    AutoCapture = { 
        Enabled = false, 
        Delay = 5.0,
        TeleportDelay = 0.3
    },
    ESP = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        MaxDistance = 200
    },
    Speed = 16,
    Jump = 50
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local espActive = false
local autoCapture = false
local autoCaptureRunning = false
local capturedPets = {}
local espObjects = {}
local petPositions = {}
local menuAberto = true

-- ========================================
-- LISTA DE ILHAS
-- ========================================
local Ilhas = {
    "Docas Perdidas",
    "Profundezas Esquecidas",
    "Ilha do Safari",
    "Ilha da Caveira",
    "Ilha do Vulcão",
    "Ilha das Abelhas",
    "Ilha da Caverna"
}

-- ========================================
-- FUNÇÃO PARA ENCONTRAR PETS
-- ========================================
local function FindAllPets()
    local pets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj == Character then continue end
            if obj == Player.Character then continue end
            if Players:GetPlayerFromCharacter(obj) then continue end
            
            local name = obj.Name:lower()
            if name:find("base") or name:find("floor") or name:find("wall") or name:find("ground") then
                continue
            end
            if name:find("npc") or name:find("humano") or name:find("personagem") then
                continue
            end
            if name:find("coruja") or name:find("owl") then
                continue
            end
            
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                
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

-- ========================================
-- FUNÇÃO PARA ENCONTRAR NOME DA ILHA NA TELA
-- ========================================
local function EncontrarIlhaNaTela(nomeIlha)
    print("🔍 Procurando ilha: " .. nomeIlha)
    
    -- Procura no workspace por partes com o nome da ilha
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("Model") then
            local nome = obj.Name
            if nome and nome:find(nomeIlha) then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if hrp then
                    local camera = Workspace.CurrentCamera
                    if camera then
                        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            print("✅ Encontrou: " .. nome .. " na tela")
                            return pos.X, pos.Y
                        end
                    end
                end
            end
        end
    end
    
    -- Tenta encontrar pela posição no mapa
    print("⚠️ Não encontrou na tela, tentando por posição...")
    return nil, nil
end

-- ========================================
-- FUNÇÃO PARA CLICAR NO BOTÃO "SIM"
-- ========================================
local function ClicarSim()
    print("✅ Clicando em SIM...")
    
    -- Procura botão "Sim" na UI
    local guis = {CoreGui, Player:FindFirstChild("PlayerGui")}
    
    for _, gui in pairs(guis) do
        if gui then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    if obj.Visible then
                        local texto = obj.Text and obj.Text:lower() or ""
                        local nome = obj.Name:lower()
                        
                        if texto:find("sim") or texto:find("yes") or 
                           nome:find("sim") or nome:find("yes") or
                           nome:find("confirm") or nome:find("accept") then
                            
                            -- Tenta clicar no botão
                            pcall(function()
                                obj:FireServer()
                                return true
                            end)
                            
                            pcall(function()
                                obj:Click()
                                return true
                            end)
                            
                            -- Clica com o mouse
                            local absPos = obj.AbsolutePosition
                            local absSize = obj.AbsoluteSize
                            
                            if absPos and absSize and absSize.X > 0 then
                                local x = absPos.X + absSize.X / 2
                                local y = absPos.Y + absSize.Y / 2
                                
                                MoverMouse(x, y)
                                task.wait(0.1)
                                Clicar()
                                print("✅ Clicou em SIM!")
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Fallback: clicar no centro da tela
    local camera = Workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        MoverMouse(viewport.X/2, viewport.Y/2)
        task.wait(0.1)
        Clicar()
        print("✅ Clicou no centro (fallback)")
        return true
    end
    
    return false
end

-- ========================================
-- FUNÇÃO PARA TELEPORTAR PARA ILHA
-- ========================================
local function TeleportarParaIlha(nomeIlha)
    print("\n🚀 TELEPORTANDO PARA: " .. nomeIlha)
    statusLabel.Text = "🚀 Teleportando para: " .. nomeIlha
    
    -- 1. Encontra a ilha na tela
    local x, y = EncontrarIlhaNaTela(nomeIlha)
    
    if x and y then
        -- Move o mouse para a ilha
        MoverMouse(x, y)
        task.wait(0.2)
        
        -- Clica na ilha
        Clicar()
        task.wait(0.5)
        
        -- Clica em SIM na confirmação
        ClicarSim()
        task.wait(0.5)
        
        print("✅ Teleportando para: " .. nomeIlha)
        statusLabel.Text = "✅ Teleportado para: " .. nomeIlha
        return true
    else
        -- Fallback: tenta teleportar via Remote
        print("⚠️ Tentando teleport via Remote...")
        
        local remote = ReplicatedStorage:FindFirstChild("Teleport")
            or ReplicatedStorage:FindFirstChild("TeleportEvent")
            or ReplicatedStorage:FindFirstChild("IslandTeleport")
        
        if remote then
            pcall(function()
                remote:FireServer(nomeIlha)
                print("✅ Remote enviado: " .. remote.Name)
                return true
            end)
        end
        
        -- Fallback: tenta tecla
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
            print("✅ Tecla T pressionada")
            return true
        end)
        
        statusLabel.Text = "❌ Falhou: " .. nomeIlha
        return false
    end
end

-- ========================================
-- FUNÇÕES DE VELOCIDADE E JUMP
-- ========================================
local function AtualizarVelocidade()
    if not Humanoid then return end
    local speed = 16 + (Settings.Speed / 100) * 84
    Humanoid.WalkSpeed = speed
end

local function AtualizarJump()
    if not Humanoid then return end
    local jump = 50 + (Settings.Jump / 100) * 50
    Humanoid.JumpPower = jump
end

-- ========================================
-- TELEPORTE SUAVE
-- ========================================
local function SmoothTeleport(targetPos)
    if not RootPart then return end
    
    local currentPos = RootPart.Position
    local dist = (currentPos - targetPos).Magnitude
    
    if dist > 5 then
        local steps = math.min(math.floor(dist / 3), 5)
        for i = 1, steps do
            local progress = i / steps
            local newPos = currentPos:Lerp(targetPos, progress)
            pcall(function()
                RootPart.CFrame = CFrame.new(newPos)
            end)
            task.wait(Settings.AutoCapture.TeleportDelay)
        end
    end
    
    pcall(function()
        RootPart.CFrame = CFrame.new(targetPos)
    end)
    task.wait(0.2)
end

-- ========================================
-- CLICAR NO PET
-- ========================================
local function ClickOnPet(pet)
    if not pet then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end
    
    pcall(function()
        local mouse = Player:GetMouse()
        if mouse then
            mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
            task.wait(0.1)
            mouse.Button1Click()
            return true
        end
    end)
    
    return false
end

-- ========================================
-- CAPTURAR PET
-- ========================================
local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local targetPos = hrp.Position + Vector3.new(0, 3, 0)
    SmoothTeleport(targetPos)
    
    local success = ClickOnPet(pet)
    task.wait(1.0)
    
    return success
end

-- ========================================
-- LEVAR PET À BASE
-- ========================================
local function BringPetToBase(pet)
    if not pet then return end
    
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("PlayerBase")
    if not base then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local basePos = base.Position + Vector3.new(0, 2, 0)
        SmoothTeleport(basePos)
        pcall(function()
            hrp.CFrame = CFrame.new(basePos)
        end)
        task.wait(0.3)
    end
    
    local releaseRemote = ReplicatedStorage:FindFirstChild("ReleasePet")
        or ReplicatedStorage:FindFirstChild("DropPet")
    
    if releaseRemote then
        pcall(function() 
            releaseRemote:FireServer(pet) 
        end)
        task.wait(0.3)
    end
end

-- ========================================
-- LOOP AUTO CAPTURE
-- ========================================
local function AutoCaptureLoop()
    while autoCapture and autoCaptureRunning do
        task.spawn(function()
            local pets = FindAllPets()
            local target = nil
            local minDist = math.huge
            
            if #pets == 0 then
                task.wait(0.5)
                return
            end
            
            for _, pet in pairs(pets) do
                if not capturedPets[pet] then
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
                local success = CapturePet(target)
                if success then
                    capturedPets[target] = true
                    BringPetToBase(target)
                    print("✅ " .. target.Name .. " capturado!")
                end
                task.wait(Settings.AutoCapture.Delay)
            else
                task.wait(0.5)
            end
        end)
        task.wait(0.1)
    end
end

-- ========================================
-- SISTEMA ESP
-- ========================================
local function CreateESP(pet)
    if not pet or not pet:IsA("Model") then return end
    if espObjects[pet] then return end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = pet
    highlight.FillColor = Settings.ESP.Color
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = hrp
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.Adornee = hrp
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.Text = "🐾 " .. pet.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Parent = billboard
    distLabel.Size = UDim2.new(1, 0, 0, 20)
    distLabel.Position = UDim2.new(0, 0, 1, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.Gotham
    
    espObjects[pet] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        DistLabel = distLabel
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
    if not espActive then
        for pet, _ in pairs(espObjects) do
            RemoveESP(pet)
        end
        espObjects = {}
        return
    end
    
    local pets = FindAllPets()
    
    for _, pet in pairs(pets) do
        if pet and pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            local hrp = pet.HumanoidRootPart
            if RootPart then
                local dist = (RootPart.Position - hrp.Position).Magnitude
                if dist <= Settings.ESP.MaxDistance then
                    CreateESP(pet)
                    if espObjects[pet] and espObjects[pet].DistLabel then
                        espObjects[pet].DistLabel.Text = math.floor(dist) .. "m"
                    end
                else
                    RemoveESP(pet)
                end
            end
        end
    end
    
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

-- ========================================
-- MONITORAMENTO
-- ========================================
local function StartMonitoring()
    task.spawn(function()
        while true do
            task.wait(0.5)
            if espActive then
                UpdateESP()
            end
        end
    end)
    
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                local name = obj.Name:lower()
                if not name:find("npc") and not name:find("humano") and not name:find("personagem") then
                    if espActive then
                        task.wait(0.1)
                        UpdateESP()
                    end
                end
            end
        end
    end)
end

-- ========================================
-- CRIAR CAMPO EDITÁVEL
-- ========================================
local function CreateEditableField(parent, labelText, defaultValue, minValue, maxValue, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.35, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btnMinus = Instance.new("TextButton")
    btnMinus.Parent = frame
    btnMinus.Size = UDim2.new(0, 22, 0, 22)
    btnMinus.Position = UDim2.new(0.65, 0, 0.5, -11)
    btnMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    btnMinus.Text = "−"
    btnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMinus.TextSize = 16
    btnMinus.Font = Enum.Font.GothamBold
    btnMinus.BorderSizePixel = 0
    
    local minusCorner = Instance.new("UICorner")
    minusCorner.Parent = btnMinus
    minusCorner.CornerRadius = UDim.new(0, 4)

    local textBox = Instance.new("TextBox")
    textBox.Parent = frame
    textBox.Size = UDim2.new(0, 35, 0, 22)
    textBox.Position = UDim2.new(0.77, 0, 0.5, -11)
    textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    textBox.Text = tostring(defaultValue)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 13
    textBox.Font = Enum.Font.GothamBold
    textBox.TextXAlignment = Enum.TextXAlignment.Center
    textBox.BorderSizePixel = 0
    textBox.ClearTextOnFocus = false
    
    local textCorner = Instance.new("UICorner")
    textCorner.Parent = textBox
    textCorner.CornerRadius = UDim.new(0, 4)

    local btnPlus = Instance.new("TextButton")
    btnPlus.Parent = frame
    btnPlus.Size = UDim2.new(0, 22, 0, 22)
    btnPlus.Position = UDim2.new(0.9, 0, 0.5, -11)
    btnPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
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
        newValue = math.round(math.clamp(newValue, minValue, maxValue))
        currentValue = newValue
        textBox.Text = tostring(newValue)
        callback(newValue)
    end

    btnMinus.MouseButton1Click:Connect(function()
        UpdateValue(currentValue - 5)
    end)

    btnPlus.MouseButton1Click:Connect(function()
        UpdateValue(currentValue + 5)
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(textBox.Text)
            if num then
                UpdateValue(num)
            else
                textBox.Text = tostring(currentValue)
            end
        end
    end)

    return frame
end

-- ========================================
-- MENU COMPLETO
-- ========================================
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 230, 0, 400)
    mainFrame.Position = UDim2.new(0.02, 0, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = mainFrame
    stroke.Color = Color3.fromRGB(138, 43, 226)
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, -50, 0, 30)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✧ SIX SEVEN"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -26, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = closeBtn
    closeCorner.CornerRadius = UDim.new(0, 5)

    local sep = Instance.new("Frame")
    sep.Parent = mainFrame
    sep.Size = UDim2.new(0.9, 0, 0, 1)
    sep.Position = UDim2.new(0.05, 0, 0.13, 0)
    sep.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    sep.BackgroundTransparency = 0.5

    -- Container com scroll
    local container = Instance.new("ScrollingFrame")
    container.Parent = mainFrame
    container.Size = UDim2.new(1, -10, 1, -60)
    container.Position = UDim2.new(0, 5, 0, 45)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 4
    container.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y

    local content = Instance.new("Frame")
    content.Parent = container
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = content
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========================================
    -- VELOCIDADE E JUMP
    -- ========================================
    CreateEditableField(content, "🏃 Velocidade", Settings.Speed, 0, 100, function(value)
        Settings.Speed = value
        AtualizarVelocidade()
    end)

    CreateEditableField(content, "🦘 Pulo", Settings.Jump, 0, 100, function(value)
        Settings.Jump = value
        AtualizarJump()
    end)

    -- ========================================
    -- ESP
    -- ========================================
    local espBtn = Instance.new("TextButton")
    espBtn.Parent = content
    espBtn.Size = UDim2.new(1, 0, 0, 28)
    espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    espBtn.Text = "🔴 ESP: OFF"
    espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espBtn.TextSize = 13
    espBtn.Font = Enum.Font.GothamBold
    espBtn.BorderSizePixel = 0
    
    local espCorner = Instance.new("UICorner")
    espCorner.Parent = espBtn
    espCorner.CornerRadius = UDim.new(0, 5)

    espBtn.MouseButton1Click:Connect(function()
        espActive = not espActive
        espBtn.Text = espActive and "🟢 ESP: ON" or "🔴 ESP: OFF"
        espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 120)
        if espActive then
            UpdateESP()
        else
            for pet, _ in pairs(espObjects) do
                RemoveESP(pet)
            end
            espObjects = {}
        end
    end)

    -- ========================================
    -- AUTO CAPTURE
    -- ========================================
    local autoBtn = Instance.new("TextButton")
    autoBtn.Parent = content
    autoBtn.Size = UDim2.new(1, 0, 0, 28)
    autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    autoBtn.Text = "🔴 AUTO: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 13
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.Parent = autoBtn
    autoCorner.CornerRadius = UDim.new(0, 5)

    autoBtn.MouseButton1Click:Connect(function()
        autoCapture = not autoCapture
        autoBtn.Text = autoCapture and "🟢 AUTO: ON" or "🔴 AUTO: OFF"
        autoBtn.BackgroundColor3 = autoCapture and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(60, 60, 120)
        if autoCapture then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoCaptureRunning = false
        end
    end)

    -- ========================================
    -- SEÇÃO: TELEPORTE PARA ILHAS
    -- ========================================
    local teleportLabel = Instance.new("TextLabel")
    teleportLabel.Parent = content
    teleportLabel.Size = UDim2.new(1, 0, 0, 20)
    teleportLabel.BackgroundTransparency = 1
    teleportLabel.Text = "─── 🚀 TELEPORTE ───"
    teleportLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
    teleportLabel.TextSize = 12
    teleportLabel.Font = Enum.Font.GothamBold
    teleportLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Botões para cada ilha
    for _, nomeIlha in pairs(Ilhas) do
        local btn = Instance.new("TextButton")
        btn.Parent = content
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
        btn.Text = "🌍 " .. nomeIlha
        btn.TextColor3 = Color3.fromRGB(200, 200, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        btnCorner.CornerRadius = UDim.new(0, 5)

        btn.MouseButton1Click:Connect(function()
            task.spawn(function()
                TeleportarParaIlha(nomeIlha)
            end)
        end)
    end

    -- ========================================
    -- STATUS
    -- ========================================
    statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = mainFrame
    statusLabel.Size = UDim2.new(0.9, 0, 0, 18)
    statusLabel.Position = UDim2.new(0.05, 0, 0.92, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 38, 0, 38)
    floatBtn.Position = UDim2.new(0.02, 0, 0.5, 20)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "✧"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 20
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
            local count = #FindAllPets()
            statusLabel.Text = "📊 Pets: " .. count .. " | ESP: " .. (espActive and "ON" or "OFF")
        end
    end)

    print("✅ MENU CRIADO!")
    return screenGui
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - COMPLETO")
print("========================================")
print("  📌 Velocidade e Pulo (editável)")
print("  📌 ESP e Auto Capture")
print("  📌 Teleporte para Ilhas")
print("========================================")

pcall(CreateMenu)
StartMonitoring()

task.wait(0.5)
AtualizarVelocidade()
AtualizarJump()

Player.CharacterAdded:Connect(function(newChar)
    Character
