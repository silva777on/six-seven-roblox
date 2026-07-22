local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinhaGUI"
screenGui.Parent = Player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0.5, -110, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Botão que chama uma função com contador
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 40)
button.Position = UDim2.new(0.5, -80, 0, 20)
button.Text = "Executar ação"
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.new(1,1,1)
button.BackgroundColor3 = Color3.fromRGB(80, 130, 220)
button.Parent = frame

local function minhaFuncao()
    print("Função executada em:", os.date("%H:%M:%S"))
end

button.MouseButton1Click:Connect(minhaFuncao)

-- Toggle (liga/desliga) — padrão comum em GUIs de automação legítimas
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 160, 0, 40)
toggle.Position = UDim2.new(0.5, -80, 0, 70)
toggle.Text = "Toggle: OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
toggle.Parent = frame

local ligado = false
toggle.MouseButton1Click:Connect(function()
    ligado = not ligado
    toggle.Text = ligado and "Toggle: ON" or "Toggle: OFF"
    toggle.BackgroundColor3 = ligado and Color3.fromRGB(60,180,60) or Color3.fromRGB(180,60,60)
end)
