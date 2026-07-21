-- SCRIPT QUE MONITORA NOVOS OBJETOS
print("🔥 MONITORANDO O MAPA EM TEMPO REAL...")

local function OnNewObject(obj)
    if obj:IsA("Model") then
        print("📦 NOVO MODELO: " .. obj.Name)
        
        -- Tenta destacar automaticamente
        pcall(function()
            local h = Instance.new("Highlight")
            h.Parent = obj
            h.FillColor = Color3.fromRGB(0, 255, 0)
            h.FillTransparency = 0.2
            h.OutlineColor = Color3.fromRGB(255, 255, 255)
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled = true
            print("   ✅ DESTACADO: " .. obj.Name)
        end)
    end
end

-- Conecta o evento
workspace.DescendantAdded:Connect(OnNewObject)

print("")
print("🔍 AGORA ANDE PELO MAPA E PROCURE PETS")
print("   - Quando um pet aparecer, ele será destacado")
print("   - Olhe no console para ver o nome")
print("")
print("🔄 O script está monitorando...")
print("   Pressione F9 para ver o console")
