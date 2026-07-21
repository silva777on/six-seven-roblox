-- SCRIPT QUE DETECTA POR NOME (qualquer nome que você colocar)
print("🔍 DIGITE O NOME DO PET QUE VOCÊ VÊ:")

-- Substitua "PET" pelo nome que você vê no jogo
local NOME_DO_PET = "PET"  -- <--- MUDE AQUI!

print("Procurando por: " .. NOME_DO_PET)

local encontrados = 0

for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and obj.Name:find(NOME_DO_PET) then
        encontrados = encontrados + 1
        print("✅ Encontrado: " .. obj.Name)
        
        -- Destaca
        pcall(function()
            local h = Instance.new("Highlight")
            h.Parent = obj
            h.FillColor = Color3.fromRGB(0, 255, 0)
            h.FillTransparency = 0.2
            h.OutlineColor = Color3.fromRGB(255, 255, 0)
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled = true
        end)
    end
end

print("Total encontrados: " .. encontrados)
