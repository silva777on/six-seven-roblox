--[[
    SIX SEVEN - COMPLETO (Menu Bonito + Funcionalidades)
    Game: [🍎] Capture e Domestique!
]]

print("🔄 CARREGANDO SIX SEVEN COMPLETO...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- CONFIGURAÇÕES
-- ========================================
local Config = {
    TotalClicks = 80,
    Delay = 5.0,
    ClickSpeed = 0.015,
}

-- ========================================
-- VARIÁVEIS
-- ========================================
local espAtivo = false
local autoAtivo = false
local processando = false
local capturados = {}
local totalCapturados = 0

-- ========================================
-- TEMA DO MENU
-- ========================================
local Theme = {
    Background     = Color3.fromRGB(12, 10, 18),
    Panel          = Color3.fromRGB(20, 16, 30),
    PanelAlt       = Color3.fromRGB(26, 20, 38),
    Purple         = Color3.fromRGB(138, 43, 226),
    PurpleNeon     = Color3.fromRGB(170, 90, 255),
    PurpleDark     = Color3.fromRGB(60, 30, 90),
    TextWhite      = Color3.fromRGB(240, 240, 245),
    TextGray       = Color3.fromRGB(170, 170, 180),
    Danger         = Color3.fromRGB(255, 80, 90),
    Success        = Color3.fromRGB(120, 220, 150),
    CornerRadius   = UDim.new(0, 12),
    Font           = Enum.Font.GothamSemibold,
    FontRegular    = Enum.Font.Gotham,
}

-- ========================================
-- FUNÇÕES DE CRIAÇÃO DE UI
-- ========================================
local function create(className, props, children)
    local inst = Instance.new(className)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function addCorner(parent, radius)
    create("UICorner", { CornerRadius = radius or Theme.CornerRadius, Parent = parent })
end

local function addStroke(parent, color, thickness, transparency)
    create("UIStroke", {
        Color = color or Theme.Purple,
        Thickness = thickness or 1,
        Transparency = transparency or 0.4,
        Parent = parent,
    })
end

-- ========================================
-- FUNÇÕES DE CLICK
-- ========================================
local function Clicar()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, 0, true, game, 0)
        task.wait(0.015)
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
-- FUNÇÕES DO JOGO
-- ========================================
local function EncontrarPets()
    local pets = {}
    local char = player.Character
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

local function CapturarPet(pet)
    if processando then return false end
    if capturados[pet] then return false end
    if not pet then return false end
    
    local hrp = pet:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    processando = true
    print("🎯 CAPTURANDO: " .. pet.Name)
    statusLabel.Text = "🎯 " .. pet.Name
    
    -- Teleporta
    if RootPart then
        pcall(function()
            RootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
        end)
        task.wait(0.3)
    end
    
    -- Tecla 1 (lasso)
    PressionarTecla(Enum.KeyCode.One)
    task.wait(0.3)
    
    -- Move mouse para o pet
    local camera = Workspace.CurrentCamera
    if camera then
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            MoverMouse(pos.X, pos.Y)
            task.wait(0.15)
        end
    end
    
    -- Clica no pet (lança lasso)
    Clicar()
    task.wait(0.5)
    
    -- Clica 80x para encher a barra
    for i = 1, Config.TotalClicks do
        Clicar()
        task.wait(Config.ClickSpeed)
    end
    
    task.wait(0.5)
    
    -- Verifica captura
    local pasta = player:FindFirstChild("Pets")
    if pasta then
        for _, p in pairs(pasta:GetChildren()) do
            if p.Name == pet.Name then
                capturados[pet] = true
                totalCapturados = totalCapturados + 1
                processando = false
                print("✅ CAPTUROU: " .. pet.Name)
                statusLabel.Text = "✅ " .. pet.Name
                Notify("Sucesso", "Capturou " .. pet.Name, "success")
                return true
            end
        end
    end
    
    if not pet.Parent then
        capturados[pet] = true
        totalCapturados = totalCapturados + 1
        processando = false
        print("✅ CAPTUROU: " .. pet.Name)
        statusLabel.Text = "✅ " .. pet.Name
        Notify("Sucesso", "Capturou " .. pet.Name, "success")
        return true
    end
    
    processando = false
    print("❌ Falhou: " .. pet.Name)
    statusLabel.Text = "❌ " .. pet.Name
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
                task.wait(Config.Delay)
            else
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
    
    for _, pet in pairs(EncontrarPets()) do
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
-- SISTEMA DE NOTIFICAÇÕES
-- ========================================
local notifHolder
local function Notify(title, message, kind, duration)
    kind = kind or "info"
    duration = duration or 3.5
    
    if not notifHolder then return end
    
    local color = Theme.Purple
    if kind == "success" then color = Theme.Success
    elseif kind == "error" then color = Theme.Danger end
    
    local notif = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.05,
        Parent = notifHolder,
    })
    addCorner(notif, UDim.new(0, 10))
    addStroke(notif, color, 1, 0.2)
    
    create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = notif,
    })
    
    create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = color,
        Parent = notif,
    })
    
    create("TextLabel", {
        Text = title,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextWhite,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 16),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })
    
    create("TextLabel", {
        Text = message,
        Font = Theme.FontRegular,
        TextSize = 12,
        TextColor3 = Theme.TextGray,
        BackgroundTransparency = 1,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -10, 0, 0),
        Position = UDim2.new(0, 8, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })
    
    notif.BackgroundTransparency = 1
    notif.Position = UDim2.new(1, 30, 0, 0)
    tween(notif, TweenInfo.new(0.25), {
        BackgroundTransparency = 0.05,
        Position = UDim2.new(0, 0, 0, 0),
    })
    
    task.delay(duration, function()
        local fade = tween(notif, TweenInfo.new(0.25), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 30, 0, 0),
        })
        fade.Completed:Wait()
        notif:Destroy()
    end)
end

-- ========================================
-- CRIAR MENU
-- ========================================
local function CriarMenu()
    local screenGui = create("ScreenGui", {
        Name = "SixSeven",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui,
    })
    
    -- Janela principal
    local mainFrame = create("Frame", {
        Size = UDim2.fromOffset(480, 380),
        Position = UDim2.new(0.5, -240, 0.5, -190),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    addCorner(mainFrame, UDim.new(0, 14))
    addStroke(mainFrame, Theme.Purple, 1.5, 0.3)
    
    -- Glow
    create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Theme.Purple,
        ImageTransparency = 0.85,
        Size = UDim2.fromOffset(900, 900),
        Position = UDim2.new(0.5, -450, 0.5, -450),
        ZIndex = 0,
        Parent = mainFrame,
    })
    
    -- TopBar
    local topBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    addCorner(topBar, UDim.new(0, 14))
    
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = topBar,
    })
    
    -- Logo
    create("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(0, 16, 0.5, -5),
        BackgroundColor3 = Theme.PurpleNeon,
        Parent = topBar,
    })
    
    -- Título
    create("TextLabel", {
        Text = "SIX SEVEN",
        Font = Theme.Font,
        TextSize = 18,
        TextColor3 = Theme.TextWhite,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })
    
    -- Botão Minimizar
    local minimizeBtn = create("TextButton", {
        Text = "—",
        Font = Theme.Font,
        TextSize = 16,
        TextColor3 = Theme.TextGray,
        BackgroundColor3 = Theme.PanelAlt,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        AutoButtonColor = false,
        Parent = topBar,
    })
    addCorner(minimizeBtn, UDim.new(0, 8))
    
    -- Botão Fechar
    local closeBtn = create("TextButton", {
        Text = "✕",
        Font = Theme.Font,
        TextSize = 16,
        TextColor3 = Theme.TextGray,
        BackgroundColor3 = Theme.PanelAlt,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -38, 0.5, -14),
        AutoButtonColor = false,
        Parent = topBar,
    })
    addCorner(closeBtn, UDim.new(0, 8))
    
    -- Sidebar
    local sidebar = create("Frame", {
        Size = UDim2.new(0, 140, 1, -46),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = sidebar,
    })
    
    -- Área de conteúdo
    local contentArea = create("Frame", {
        Size = UDim2.new(1, -140, 1, -46),
        Position = UDim2.new(0, 140, 0, 46),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        Parent = contentArea,
    })
    
    -- Notificações
    notifHolder = create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(280, 400),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notifHolder,
    })
    
    -- Sistema de abas
    local tabs = {}
    local tabButtons = {}
    local activeTab = nil
    
    local function selectTab(name)
        if activeTab == name then return end
        activeTab = name
        
        for tabName, page in pairs(tabs) do
            page.Visible = (tabName == name)
        end
        
        for tabName, btn in pairs(tabButtons) do
            if tabName == name then
                tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.PurpleDark })
                btn.UIStroke.Transparency = 0
            else
                tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel })
                btn.UIStroke.Transparency = 1
            end
        end
    end
    
    local function registerTab(name, order)
        local btn = create("TextButton", {
            Text = "  " .. name,
            Font = Theme.FontRegular,
            TextSize = 13,
            TextColor3 = Theme.TextWhite,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = Theme.Panel,
            Size = UDim2.new(1, 0, 0, 34),
            AutoButtonColor = false,
            LayoutOrder = order or 0,
            Parent = sidebar,
        })
        addCorner(btn, UDim.new(0, 8))
        local stroke = create("UIStroke", {
            Color = Theme.PurpleNeon,
            Thickness = 1,
            Transparency = 1,
            Parent = btn,
        })
        
        local page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Purple,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
            Visible = false,
            Parent = contentArea,
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })
        
        tabs[name] = page
        tabButtons[name] = btn
        
        btn.MouseButton1Click:Connect(function()
            selectTab(name)
        end)
        
        if not activeTab then
            selectTab(name)
        end
        
        return page
    end
    
    local function addToggle(page, labelText, default, callback)
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.PanelAlt,
            Parent = page,
        })
        addCorner(row, UDim.new(0, 8))
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = row,
        })
        
        create("TextLabel", {
            Text = labelText,
            Font = Theme.FontRegular,
            TextSize = 13,
            TextColor3 = Theme.TextWhite,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        
        local toggleBg = create("TextButton", {
            Text = "",
            Size = UDim2.fromOffset(42, 22),
            Position = UDim2.new(1, -42, 0.5, -11),
            BackgroundColor3 = default and Theme.Purple or Theme.PanelAlt,
            AutoButtonColor = false,
            Parent = row,
        })
        addCorner(toggleBg, UDim.new(1, 0))
        addStroke(toggleBg, Theme.Purple, 1, 0.3)
        
        local knob = create("Frame", {
            Size = UDim2.fromOffset(16, 16),
            Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = Theme.TextWhite,
            Parent = toggleBg,
        })
        addCorner(knob, UDim.new(1, 0))
        
        local state = default or false
        
        toggleBg.MouseButton1Click:Connect(function()
            state = not state
            tween(knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            })
            tween(toggleBg, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Theme.Purple or Theme.PanelAlt,
            })
            if callback then
                callback(state)
            end
        end)
        
        return row
    end
    
    -- ========================================
    -- CRIAR ABAS
    -- ========================================
    
    -- Aba Principal
    local homePage = registerTab("Início", 1)
    create("TextLabel", {
        Text = "SIX SEVEN - Painel de Controle\n\nAtive as funções abaixo:",
        Font = Theme.FontRegular,
        TextSize = 13,
        TextColor3 = Theme.TextGray,
        BackgroundTransparency = 1,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 60),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = homePage,
    })
    
    local statusLabel = create("TextLabel", {
        Text = "📊 Pronto",
        Font = Theme.FontRegular,
        TextSize = 12,
        TextColor3 = Theme.TextGray,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = homePage,
    })
    
    -- Aba Configurações
    local settingsPage = registerTab("Configurações", 2)
    
    -- Toggle ESP
    addToggle(settingsPage, "ESP (Ver Pets)", false, function(state)
        espAtivo = state
        AtualizarESP()
        Notify("ESP", state and "Ativado" or "Desativado", state and "success" or "info")
        
        if espAtivo then
            task.spawn(function()
                while espAtivo do
                    AtualizarESP()
                    task.wait(1)
                end
            end)
        end
    end)
    
    -- Toggle AUTO
    addToggle(settingsPage, "Auto Capture", false, function(state)
        autoAtivo = state
        Notify("Auto Capture", state and "Ativado" or "Desativado", state and "success" or "info")
        if state then
            task.spawn(LoopAuto)
        end
    end)
    
    -- ========================================
    -- ARRASTAR JANELA
    -- ========================================
    local dragging = false
    local dragStart, startPos
    
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ========================================
    -- MINIMIZAR / FECHAR
    -- ========================================
    local minimized = false
    local expandedSize = mainFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(mainFrame, TweenInfo.new(0.25), { Size = UDim2.fromOffset(expandedSize.X.Offset, 46) })
            sidebar.Visible = false
            contentArea.Visible = false
        else
            tween(mainFrame, TweenInfo.new(0.25), { Size = expandedSize })
            task.delay(0.25, function()
                sidebar.Visible = true
                contentArea.Visible = true
            end)
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        local closeTween = tween(mainFrame, TweenInfo.new(0.2), {
            Size = UDim2.fromOffset(0, 0),
            Position = mainFrame.Position + UDim2.fromOffset(mainFrame.Size.X.Offset / 2, mainFrame.Size.Y.Offset / 2),
        })
        closeTween.Completed:Wait()
        screenGui:Destroy()
    end)
    
    -- ========================================
    -- ANIMAÇÃO DE ABERTURA
    -- ========================================
    mainFrame.Size = UDim2.fromOffset(0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = expandedSize,
        Position = UDim2.new(0.5, -expandedSize.X.Offset / 2, 0.5, -expandedSize.Y.Offset / 2),
    })
    
    -- ========================================
    -- MONITORAMENTO
    -- ========================================
    task.spawn(function()
        while true do
            task.wait(2)
            local count = #EncontrarPets()
            if not autoAtivo and not processando then
                statusLabel.Text = "📊 Pets: " .. count .. " | Capturados: " .. totalCapturados
            end
        end
    end)
    
    Notify("Six Seven", "Script carregado com sucesso!", "success")
    
    return screenGui
end

-- ========================================
-- INICIAR
-- ========================================
print("========================================")
print("  ✧ SIX SEVEN - COMPLETO")
print("========================================")
print("  📌 Menu com abas")
print("  📌 ESP para ver pets")
print("  📌 Auto Capture")
print("========================================")

CriarMenu()

print("✅ SCRIPT CARREGADO!")
