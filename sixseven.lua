local pet = script.Parent
local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.new(0, 150, 0, 50)
billboard.AlwaysOnTop = true -- Permite ver através das paredes
billboard.ExtentsOffset = Vector3.new(0, 3, 0) -- Fica acima do pet

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.Text = "⭐ PET MÍSTICO ⭐"
label.TextColor3 = Color3.fromRGB(255, 85, 255) -- Cor rosa/mística
label.BackgroundTransparency = 1
label.TextScaled = true

label.Parent = billboard
billboard.Parent = pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
