-- ... (código anterior do script) ...

-- ===== DENTRO DA FUNÇÃO CreateMenu() =====
-- Procure por este bloco de código que cria o título e substitua ou adicione as linhas novas.

-- Título (original)
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

-- !! PARTE NOVA 1: ÍCONE AO LADO DO TÍTULO !!
local iconImage = Instance.new("ImageLabel")
iconImage.Parent = main
iconImage.Size = UDim2.new(0, 28, 0, 28) -- Tamanho do quadrado
iconImage.Position = UDim2.new(0, 35, 0, 1) -- Posição ao lado do texto
iconImage.BackgroundTransparency = 1
iconImage.Image = "rbxassetid://AQUI_O_NOVO_ASSET_ID" -- <--- COLE O ID AQUI
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.ZIndex = 2

-- !! PARTE NOVA 2: IMAGEM DE FUNDO (ÁREA ROXA) !!
local backgroundImage = Instance.new("ImageLabel")
backgroundImage.Parent = main
backgroundImage.Size = UDim2.new(1, 0, 1, 0) -- Ocupa todo o frame
backgroundImage.Position = UDim2.new(0, 0, 0, 0)
backgroundImage.BackgroundTransparency = 1
backgroundImage.Image = "rbxassetid://AQUI_O_NOVO_ASSET_ID" -- <--- COLE O MESMO ID AQUI
backgroundImage.ImageTransparency = 0.85 -- Deixa bem transparente para não atrapalhar os textos
backgroundImage.ScaleType = Enum.ScaleType.Fit
backgroundImage.ZIndex = 0 -- Fica atrás de todos os outros elementos

-- ... (resto do script) ...
