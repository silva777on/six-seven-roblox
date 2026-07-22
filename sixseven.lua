-- Exemplo simples de GUI em Roblox (LocalScript, dentro de StarterGui/StarterPlayerScripts)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- 1. Criar o container principal da interface
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MeuPrimeiroGUI"
screenGui.Parent = Player:WaitForChild("PlayerGui")

-- 2. Criar um frame (janela) para organizar o conteúdo
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- 3. Criar o botão
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 40)
button.Position = UDim2.new(0.5, -75, 0.5, -20)
button.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
button.Text = "Clique aqui"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

-- 4. Conectar a ação ao clique
local cliques = 0
button.MouseButton1Click:Connect(function()
    cliques = cliques + 1
    button.Text = "Cliques: " .. cliques
    print("Botão clicado! Total:", cliques)
end)
