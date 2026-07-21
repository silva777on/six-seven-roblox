--[[
    Six Seven - Auto Farm & ESP
    Game: [🍎] Capture e Domestique!
]]

local Settings = {
    AutoCapture = { Enabled = false, Delay = 1.5 },
    ESP = {
        Divinos = { Enabled = false, Color = Color3.fromRGB(255, 215, 0), MaxDistance = 150 },
        Misticos = { Enabled = false, Color = Color3.fromRGB(148, 0, 211), MaxDistance = 150 },
        Chefes = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), MaxDistance = 150 }
    }
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

local autoCaptureRunning = false
local capturedPets = {}
local petList = {}
local petESP = {}

local function GetPetType(pet)
    if not pet then return nil end
    local name = pet.Name:lower()
    if name:find("divino") or name:find("lendario") then return "Divinos"
    elseif name:find("mistico") or name:find("epico") then return "Misticos"
    elseif name:find("chefe") or name:find("boss") then return "Chefes" end
    return nil
end

local function GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

local function CapturePet(pet)
    if not pet or not pet:IsA("Model") then return false end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if RootPart then
        local targetPos = hrp.Position + Vector3.new(0, 3, 0)
        pcall(function() RootPart.CFrame = CFrame.new(targetPos) end)
        task.wait(0.1)
    end
    local remote = ReplicatedStorage:FindFirstChild("CapturePet") or (ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("Capture"))
    if remote then
        pcall(function() remote:FireServer(pet) end)
        task.wait(0.5)
        return true
    end
    return false
end

local function BringPetToBase(pet)
    if not pet then return end
    local base = workspace:FindFirstChild("Base") or workspace:FindFirstChild("PlayerBase")
    if not base then return end
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if hrp then
        local basePos = base.Position + Vector3.new(0, 2, 0)
        pcall(function() hrp.CFrame = CFrame.new(basePos) end)
        task.wait(0.2)
    end
    local releaseRemote = ReplicatedStorage:FindFirstChild("ReleasePet")
    if releaseRemote then
        pcall(function() releaseRemote:FireServer(pet) end)
        task.wait(0.3)
    end
end

local function AutoCaptureLoop()
    while autoCaptureRunning and Settings.AutoCapture.Enabled do
        task.spawn(function()
            local pets = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
                    if v.Name:find("Pet") or v.Name:find("Creature") then
                        if not capturedPets[v] then
                            table.insert(pets, v)
                        end
                    end
                end
            end
            if #pets == 0 then
                task.wait(1)
                return
            end
            local target = nil
            local minDist = math.huge
            for _, pet in ipairs(pets) do
                local hrp = pet:FindFirstChild("HumanoidRootPart")
                if hrp and RootPart then
                    local dist = GetDistance(RootPart.Position, hrp.Position)
                    if dist < minDist then
                        minDist = dist
                        target = pet
                    end
                end
            end
            if target then
                local success = CapturePet(target)
                if success then
                    capturedPets[target] = true
                    BringPetToBase(target)
                end
            end
            task.wait(Settings.AutoCapture.Delay)
        end)
        task.wait(0.1)
    end
end

local function CreateESPObject(pet, typeName)
    if not pet or not pet:IsA("Model") then return end
    local config = Settings.ESP[typeName]
    if not config or not config.Enabled then return end
    if petESP[pet] then return end
    local highlight = Instance.new("Highlight")
    highlight.Parent = pet
    highlight.FillColor = config.Color
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    petESP[pet] = highlight
end

local function UpdateESPVisibility()
    for pet, highlight in pairs(petESP) do
        if pet and pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            local dist = GetDistance(RootPart and RootPart.Position, pet.HumanoidRootPart.Position)
            local petType = GetPetType(pet)
            local config = petType and Settings.ESP[petType]
            if config and config.Enabled then
                highlight.Enabled = dist <= config.MaxDistance
            else
                highlight.Enabled = false
            end
        end
    end
end

local function OnPetAdded(pet)
    if pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
        if pet.Name:find("Pet") or pet.Name:find("Creature") then
            table.insert(petList, pet)
            local petType = GetPetType(pet)
            if petType and Settings.ESP[petType].Enabled then
                CreateESPObject(pet, petType)
            end
        end
    end
end

local function SetupPetDetection()
    for _, pet in pairs(workspace:GetDescendants()) do
        if pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            if pet.Name:find("Pet") or pet.Name:find("Creature") then
                table.insert(petList, pet)
            end
        end
    end
    workspace.DescendantAdded:Connect(OnPetAdded)
    task.spawn(function()
        while true do
            task.wait(0.5)
            UpdateESPVisibility()
        end
    end)
end

local function CreateGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SixSevenGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 400, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.Parent = mainFrame
    corner.CornerRadius = UDim.new(0, 12)

    local border = Instance.new("Frame")
    border.Parent = mainFrame
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 2
    border.BorderColor3 = Color3.fromRGB(120, 80, 220)

    local titleBar = Instance.new("Frame")
    titleBar.Parent = mainFrame
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0

    local titleCorner = Instance.new("UICorner")
    titleCorner.Parent = titleBar
    titleCorner.CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel")
    title.Parent = titleBar
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Six Seven"
    title.TextColor3 = Color3.fromRGB(190, 160, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local minBtn = Instance.new("TextButton")
    minBtn.Parent = titleBar
    minBtn.Size = UDim2.new(0, 35, 1, 0)
    minBtn.Position = UDim2.new(1, -75, 0, 0)
    minBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
    minBtn.BackgroundTransparency = 0.4
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 22
    minBtn.BorderSizePixel = 0
    minBtn.Font = Enum.Font.Gotham

    local minCorner = Instance.new("UICorner")
    minCorner.Parent = minBtn
    minCorner.CornerRadius = UDim.new(0, 6)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = titleBar
    closeBtn.Size = UDim2.new(0, 35, 1, 0)
    closeBtn.Position = UDim2.new(1, -35, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BackgroundTransparency = 0.4
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.Gotham

    local closeCorner = Instance.new("UICorner")
    closeCorner.Parent = closeBtn
    closeCorner.CornerRadius = UDim.new(0, 6)

    local tabContainer = Instance.new("Frame")
    tabContainer.Parent = mainFrame
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 45)
    tabContainer.BackgroundTransparency = 1

    local tabs = {"Auto Farm", "ESP"}
    local tabButtons = {}
    local tabContents = {}

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Parent = tabContainer
        btn.Size = UDim2.new(1 / #tabs, 0, 1, 0)
        btn.Position = UDim2.new((i - 1) / #tabs, 0, 0, 0)
        btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(120, 80, 220) or Color3.fromRGB(30, 28, 50)
        btn.BackgroundTransparency = 0.3
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(230, 230, 255)
        btn.TextSize = 15
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        btnCorner.CornerRadius = UDim.new(0, 6)
        tabButtons[name] = btn
    end

    local contentContainer = Instance.new("Frame")
    contentContainer.Parent = mainFrame
    contentContainer.Size = UDim2.new(1, -20, 1, -100)
    contentContainer.Position = UDim2.new(0, 10, 0, 90)
    contentContainer.BackgroundTransparency = 1

    local function CreateToggle(parent, text, default, callback)
        local container = Instance.new("Frame")
        container.Parent = parent
        container.Size = UDim2.new(1, 0, 0, 40)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel")
        label.Parent = container
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Parent = container
        toggleBtn.Size = UDim2.new(0, 55, 0, 28)
        toggleBtn.Position = UDim2.new(1, -60, 0, 6)
        toggleBtn.BackgroundColor3 = default and Color3.fromRGB(120, 80, 220) or Color3.fromRGB(60, 60, 80)
        toggleBtn.Text = default and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 13
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.BorderSizePixel = 0
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.Parent = toggleBtn
        toggleCorner.CornerRadius = UDim.new(1, 0)
        local state = default
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(120, 80, 220) or Color3.fromRGB(60, 60, 80)
            toggleBtn.Text = state and "ON" or "OFF"
            if callback then callback(state) end
        end)
        return toggleBtn
    end

    local function CreateSlider(parent, text, min, max, default, callback)
        local container = Instance.new("Frame")
        container.Parent = parent
        container.Size = UDim2.new(1, 0, 0, 55)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel")
        label.Parent = container
        label.Size = UDim2.new(1, 0, 0, 22)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(default)
        label.TextColor3 = Color3.fromRGB(220, 220, 255)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        local slider = Instance.new("Frame")
        slider.Parent = container
        slider.Size = UDim2.new(1, 0, 0, 5)
        slider.Position = UDim2.new(0, 0, 0, 28)
        slider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        slider.BorderSizePixel = 0
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.Parent = slider
        sliderCorner.CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.Parent = slider
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
        fill.BorderSizePixel = 0
        local fillCorner = Instance.new("UICorner")
        fillCorner.Parent = fill
        fillCorner.CornerRadius = UDim.new(1, 0)
        local handle = Instance.new("TextButton")
        handle.Parent = slider
        handle.Size = UDim2.new(0, 16, 0, 16)
        handle.Position = UDim2.new((default - min) / (max - min), -8, 0, -5.5)
        handle.BackgroundColor3 = Color3.fromRGB(160, 130, 255)
        handle.Text = ""
        handle.BorderSizePixel = 0
        local handleCorner = Instance.new("UICorner")
        handleCorner.Parent = handle
        handleCorner.CornerRadius = UDim.new(1, 0)
        local value = default
        local dragging = false
        handle.MouseButton1Down:Connect(function()
            dragging = true
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position.X
                local sliderPos = slider.AbsolutePosition.X
                local sliderWidth = slider.AbsoluteSize.X
                if sliderWidth > 0 then
                    local percent = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
                    value = min + (max - min) * percent
                    value = math.round(value * 10) / 10
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    handle.Position = UDim2.new(percent, -8, 0, -5.5)
                    label.Text = text .. ": " .. tostring(value)
                    if callback then callback(value) end
                end
            end
        end)
        return container
    end

    local autoContent = Instance.new("ScrollingFrame")
    autoContent.Parent = contentContainer
    autoContent.Size = UDim2.new(1, 0, 1, 0)
    autoContent.BackgroundTransparency = 1
    autoContent.ScrollBarThickness = 4
    autoContent.CanvasSize = UDim2.new(0, 0, 0, 250)

    local autoToggle = CreateToggle(autoContent, "Auto Capturar Pets", false, function(state)
        Settings.AutoCapture.Enabled = state
        if state then
            if not autoCaptureRunning then
                autoCaptureRunning = true
                task.spawn(AutoCaptureLoop)
            end
        else
            autoCaptureRunning = false
        end
    end)

    local delaySlider = CreateSlider(autoContent, "Delay entre capturas", 0.5, 5, 1.5, function(value)
        Settings.AutoCapture.Delay = value
    end)

    local rareToggle = CreateToggle(autoContent, "Priorizar pets raros", true)
    local ignoreToggle = CreateToggle(autoContent, "Ignorar pets capturados", true)

    tabContents["Auto Farm"] = autoContent

    local espContent = Instance.new("ScrollingFrame")
    espContent.Parent = contentContainer
    espContent.Size = UDim2.new(1, 0, 1, 0)
    espContent.BackgroundTransparency = 1
    espContent.ScrollBarThickness = 4
    espContent.CanvasSize = UDim2.new(0, 0, 0, 300)
    espContent.Visible = false

    local divinoToggle = CreateToggle(espContent, "ESP Divinos", false, function(state)
        Settings.ESP.Divinos.Enabled = state
        if state then
            for _, pet in pairs(petList) do
                local petType = GetPetType(pet)
                if petType == "Divinos" then
                    CreateESPObject(pet, petType)
                end
            end
        else
            for pet, highlight in pairs(petESP) do
                if GetPetType(pet) == "Divinos" then
                    highlight:Destroy()
                    petESP[pet] = nil
                end
            end
        end
    end)

    local divinoDist = CreateSlider(espContent, "Distancia Divinos", 50, 300, 150, function(value)
        Settings.ESP.Divinos.MaxDistance = value
    end)

    local misticoToggle = CreateToggle(espContent, "ESP Misticos", false, function(state)
        Settings.ESP.Misticos.Enabled = state
        if state then
            for _, pet in pairs(petList) do
                local petType = GetPetType(pet)
                if petType == "Misticos" then
                    CreateESPObject(pet, petType)
                end
            end
        else
            for pet, highlight in pairs(petESP) do
                if GetPetType(pet) == "Misticos" then
                    highlight:Destroy()
                    petESP[pet] = nil
                end
            end
        end
    end)

    local misticoDist = CreateSlider(espContent, "Distancia Misticos", 50, 300, 150, function(value)
        Settings.ESP.Misticos.MaxDistance = value
    end)

    local chefeToggle = CreateToggle(espContent, "ESP Chefes", false, function(state)
        Settings.ESP.Chefes.Enabled = state
        if state then
            for _, pet in pairs(petList) do
                local petType = GetPetType(pet)
                if petType == "Chefes" then
                    CreateESPObject(pet, petType)
                end
            end
        else
            for pet, highlight in pairs(petESP) do
                if GetPetType(pet) == "Chefes" then
                    highlight:Destroy()
                    petESP[pet] = nil
                end
            end
        end
    end)

    local chefeDist = CreateSlider(espContent, "Distancia Chefes", 50, 300, 150, function(value)
        Settings.ESP.Chefes.MaxDistance = value
    end)

    tabContents["ESP"] = espContent

    local function SwitchTab(tabName)
        for name, content in pairs(tabContents) do
            content.Visible = (name == tabName)
        end
        for name, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(120, 80, 220) or Color3.fromRGB(30, 28, 50)
        end
    end

    for name, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            SwitchTab(name)
        end)
    end

    local floatBtn = Instance.new("TextButton")
    floatBtn.Parent = screenGui
    floatBtn.Size = UDim2.new(0, 55, 0, 55)
    floatBtn.Position = UDim2.new(0.93, -27, 0.93, -27)
    floatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatBtn.Text = "+"
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.TextSize = 30
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

    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        floatBtn.Visible = true
    end)

    closeBtn.MouseButton1Click:Connect(CloseMenu)
    floatBtn.MouseButton1Click:Connect(OpenMenu)

    return screenGui
end

pcall(CreateGUI)
pcall(SetupPetDetection)

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
end)

print("Six Seven carregado com sucesso!")
