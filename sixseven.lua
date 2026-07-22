-- SCRIPT DE TESTE - COPIE E COLE
print("🔄 TESTANDO...")

local gui = Instance.new("ScreenGui")
gui.Name = "TestGUI"
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
frame.Visible = true

local label = Instance.new("TextLabel")
label.Parent = frame
label.Size = UDim2.new(1, 0, 1, 0)
label.Text = "✅ SCRIPT FUNCIONA!"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 30
label.Font = Enum.Font.GothamBold

print("✅ Se você viu um quadrado roxo, seu executor funciona!")
