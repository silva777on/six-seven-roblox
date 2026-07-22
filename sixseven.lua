--[[
	SxONE - Interface (UI Shell)
	--------------------------------------------------
	Local: StarterGui > SxONE (LocalScript)
 
	Este script contém APENAS a interface visual do SxONE:
	- Janela principal roxa/preta, com cantos arredondados e brilho
	- Arrastável
	- Botões de Minimizar e Fechar com animação
	- Sistema de abas (placeholders, sem lógica de gameplay)
	- Sistema de notificações reutilizável
 
	Não contém nenhuma lógica de ESP, automação de captura,
	RemoteEvents ou qualquer interação com o jogo.
	Use as funções expostas (SxONE.Notify, SxONE.RegisterTab, etc)
	para conectar suas próprias funcionalidades legítimas depois.
--]]
 
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
--=====================================================
-- CONFIGURAÇÃO DE TEMA
--=====================================================
 
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
 
--=====================================================
-- UTILITÁRIOS
--=====================================================
 
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
 
local function addGradient(parent, colorSequence, rotation)
	create("UIGradient", {
		Color = colorSequence,
		Rotation = rotation or 0,
		Parent = parent,
	})
end
 
--=====================================================
-- SCREEN GUI RAIZ
--=====================================================
 
local screenGui = create("ScreenGui", {
	Name = "SxONE",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})
 
--=====================================================
-- JANELA PRINCIPAL
--=====================================================
 
local mainFrame = create("Frame", {
	Name = "MainFrame",
	Size = UDim2.fromOffset(560, 380),
	Position = UDim2.new(0.5, -280, 0.5, -190),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = screenGui,
})
addCorner(mainFrame, UDim.new(0, 14))
addStroke(mainFrame, Theme.Purple, 1.5, 0.3)
 
-- Brilho suave de fundo (glow)
local glow = create("ImageLabel", {
	Name = "Glow",
	BackgroundTransparency = 1,
	Image = "rbxassetid://5028857084", -- glow radial padrão
	ImageColor3 = Theme.Purple,
	ImageTransparency = 0.85,
	Size = UDim2.fromOffset(900, 900),
	Position = UDim2.new(0.5, -450, 0.5, -450),
	ZIndex = 0,
	Parent = mainFrame,
})
 
--=====================================================
-- TOPBAR (título + arrastar + minimizar/fechar)
--=====================================================
 
local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	Parent = mainFrame,
})
addCorner(topBar, UDim.new(0, 14))
 
-- Corrige o corner "vazando" na parte de baixo da topbar
create("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = topBar,
})
 
local logoDot = create("Frame", {
	Size = UDim2.fromOffset(10, 10),
	Position = UDim2.new(0, 16, 0.5, -5),
	BackgroundColor3 = Theme.PurpleNeon,
	Parent = topBar,
})
addCorner(logoDot, UDim.new(1, 0))
 
local titleLabel = create("TextLabel", {
	Name = "Title",
	Text = "SxONE",
	Font = Theme.Font,
	TextSize = 18,
	TextColor3 = Theme.TextWhite,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 34, 0, 0),
	Size = UDim2.new(0, 200, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topBar,
})
 
local subtitleLabel = create("TextLabel", {
	Name = "Subtitle",
	Text = "painel de desenvolvimento",
	Font = Theme.FontRegular,
	TextSize = 11,
	TextColor3 = Theme.TextGray,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 90, 0, 1),
	Size = UDim2.new(0, 220, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topBar,
})
 
-- Botão Fechar
local closeBtn = create("TextButton", {
	Name = "CloseButton",
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
 
-- Botão Minimizar
local minimizeBtn = create("TextButton", {
	Name = "MinimizeButton",
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
 
local function hoverEffect(button, hoverColor, normalColor)
	button.MouseEnter:Connect(function()
		tween(button, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor })
	end)
	button.MouseLeave:Connect(function()
		tween(button, TweenInfo.new(0.15), { BackgroundColor3 = normalColor })
	end)
end
 
hoverEffect(closeBtn, Theme.Danger, Theme.PanelAlt)
hoverEffect(minimizeBtn, Theme.Purple, Theme.PanelAlt)
 
--=====================================================
-- SIDEBAR (ABAS)
--=====================================================
 
local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 140, 1, -46),
	Position = UDim2.new(0, 0, 0, 46),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	Parent = mainFrame,
})
 
local sidebarList = create("UIListLayout", {
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
 
--=====================================================
-- ÁREA DE CONTEÚDO
--=====================================================
 
local contentArea = create("Frame", {
	Name = "Content",
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
 
--=====================================================
-- SISTEMA DE NOTIFICAÇÕES
--=====================================================
 
local notifHolder = create("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.fromOffset(280, 400),
	BackgroundTransparency = 1,
	Parent = screenGui,
})
local notifList = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = notifHolder,
})
 
local function notify(title, message, kind, duration)
	kind = kind or "info" -- info | success | error
	duration = duration or 3.5
 
	local color = Theme.Purple
	if kind == "success" then
		color = Theme.Success
	elseif kind == "error" then
		color = Theme.Danger
	end
 
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
 
	local bar = create("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = color,
		Parent = notif,
	})
	addCorner(bar, UDim.new(1, 0))
 
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
	tween(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.05,
		Position = UDim2.new(0, 0, 0, 0),
	})
 
	task.delay(duration, function()
		local fadeOut = tween(notif, TweenInfo.new(0.25), {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 30, 0, 0),
		})
		fadeOut.Completed:Wait()
		notif:Destroy()
	end)
end
 
--=====================================================
-- SISTEMA DE ABAS (placeholders)
--=====================================================
 
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
 
-- Cria uma aba nova: retorna o Frame de conteúdo para você preencher depois
local function registerTab(name, order)
	local btn = create("TextButton", {
		Name = name .. "Button",
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
		Name = name .. "Page",
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
 
-- Helper para adicionar um toggle simples (ON/OFF) dentro de uma aba
-- callback(state:boolean) é chamado quando o usuário alterna
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
 
--=====================================================
-- ARRASTAR JANELA
--=====================================================
 
do
	local dragging = false
	local dragStart, startPos
 
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
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
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end
 
--=====================================================
-- MINIMIZAR / FECHAR
--=====================================================
 
local minimized = false
local expandedSize = mainFrame.Size
 
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		tween(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Size = UDim2.fromOffset(expandedSize.X.Offset, 46),
		})
		sidebar.Visible = false
		contentArea.Visible = false
	else
		tween(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Size = expandedSize,
		})
		task.delay(0.25, function()
			sidebar.Visible = true
			contentArea.Visible = true
		end)
	end
end)
 
closeBtn.MouseButton1Click:Connect(function()
	local closeTween = tween(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.fromOffset(0, 0),
		Position = mainFrame.Position + UDim2.fromOffset(mainFrame.Size.X.Offset / 2, mainFrame.Size.Y.Offset / 2),
	})
	closeTween.Completed:Wait()
	screenGui:Destroy()
end)
 
--=====================================================
-- ANIMAÇÃO DE ABERTURA
--=====================================================
 
mainFrame.Size = UDim2.fromOffset(0, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = expandedSize,
	Position = UDim2.new(0.5, -expandedSize.X.Offset / 2, 0.5, -expandedSize.Y.Offset / 2),
})
 
--=====================================================
-- EXEMPLO DE USO (abas vazias, prontas para você conectar
-- suas próprias funcionalidades legítimas)
--=====================================================
 
local homePage = registerTab("Início", 1)
create("TextLabel", {
	Text = "Bem-vindo ao SxONE.\nEsta é apenas a interface — conecte suas próprias funções aqui.",
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
 
local settingsPage = registerTab("Configurações", 2)
addToggle(settingsPage, "Exemplo de opção", false, function(state)
	notify("Configuração", state and "Ativado" or "Desativado", state and "success" or "info")
end)
 
--=====================================================
-- API PÚBLICA (para você expandir depois)
--=====================================================
 
local SxONE = {
	Notify = notify,
	RegisterTab = registerTab,
	AddToggle = addToggle,
	Theme = Theme,
}
 
_G.SxONE = SxONE
 
notify("SxONE", "Interface carregada com sucesso.", "success")
 
return SxONE
