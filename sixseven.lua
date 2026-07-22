--[[
    MenuCaptura.client.lua

    Onde colocar: StarterPlayerScripts (dentro de StarterPlayer)
    (tem que ser um LocalScript)

    O que faz:
    - Cria um botão simples na tela ("Captura: DESLIGADA")
    - Ao clicar, manda um evento pro servidor ligando/desligando
      a captura automática de pets daquele jogador
    - Muda a cor e o texto do botão conforme o estado
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jogadorLocal = Players.LocalPlayer

-- Espera o RemoteEvent que o script do servidor cria automaticamente
local remoteToggle = ReplicatedStorage:WaitForChild("ToggleCaptura")

-- Monta a interface
local telaGui = Instance.new("ScreenGui")
telaGui.Name = "MenuCaptura"
telaGui.ResetOnSpawn = false
telaGui.Parent = jogadorLocal:WaitForChild("PlayerGui")

local botao = Instance.new("TextButton")
botao.Name = "BotaoCaptura"
botao.Size = UDim2.new(0, 220, 0, 50)
botao.Position = UDim2.new(0, 20, 1, -80) -- canto inferior esquerdo
botao.AnchorPoint = Vector2.new(0, 0)
botao.BackgroundColor3 = Color3.fromRGB(180, 40, 40) -- vermelho = desligado
botao.Text = "Captura: DESLIGADA"
botao.TextColor3 = Color3.fromRGB(255, 255, 255)
botao.Font = Enum.Font.GothamBold
botao.TextSize = 18
botao.BorderSizePixel = 0
botao.Parent = telaGui

local cantoArredondado = Instance.new("UICorner")
cantoArredondado.CornerRadius = UDim.new(0, 10)
cantoArredondado.Parent = botao

local ativado = false

local function atualizarVisual()
	if ativado then
		botao.BackgroundColor3 = Color3.fromRGB(40, 160, 70) -- verde = ligado
		botao.Text = "Captura: LIGADA"
	else
		botao.BackgroundColor3 = Color3.fromRGB(180, 40, 40) -- vermelho = desligado
		botao.Text = "Captura: DESLIGADA"
	end
end

botao.MouseButton1Click:Connect(function()
	ativado = not ativado
	atualizarVisual()
	remoteToggle:FireServer()
end)
