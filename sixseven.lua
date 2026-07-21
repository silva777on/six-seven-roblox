-- LISTA TUDO NO JOGO
print("========================================")
print("  📋 LISTANDO TODOS OS OBJETOS")
print("========================================")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function ListAllObjects()
    local total = 0
    local models = {}
    
    -- Primeiro, lista todas as pastas principais
    print("")
    print("📁 PASTAS PRINCIPAIS:")
    for _, child in pairs(workspace:GetChildren()) do
        print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
    end
    
    print("")
    print("🔍 PROCURANDO MODELOS COM PARTES...")
    print("")
    
    -- Procura por modelos que têm partes (BasePart)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hasParts = false
            local partNames = {}
            
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("BasePart") then
                    hasParts = true
                    table.insert(partNames, child.Name)
                end
            end
            
            if hasParts then
                total = total + 1
                local isPlayer = (obj == Player.Character)
                local parentName = obj.Parent and obj.Parent.Name or "N/A"
                
                print("📦 #" .. total .. " - " .. obj.Name)
                print("   📂 Pai: " .. parentName)
                print("   👤 É jogador? " .. tostring(isPlayer))
                print("   🧩 Partes: " .. table.concat(partNames, ", "))
                
                -- Verifica se tem Humanoid
                if obj:FindFirstChild("Humanoid") then
                    print("   ❤️ Tem Humanoid: SIM")
                end
                
                -- Verifica se tem ClickDetector
                if obj:FindFirstChild("ClickDetector") then
                    print("   🖱️ Tem ClickDetector: SIM")
                end
                
                -- Verifica se tem BillboardGui
                if obj:FindFirstChild("BillboardGui") then
                    print("   📝 Tem BillboardGui: SIM")
                end
                
                print("")
            end
        end
    end
    
    print("========================================")
    print("  📊 TOTAL DE MODELOS: " .. total)
    print("========================================")
    print("")
    print("👀 Procure por nomes que parecem pets:")
    print("   - Divino, Mistico, Chefe, Boss")
    print("   - Pet, Creature, Monster")
    print("   - Animal, Wild, Capture")
    print("")
    print("📌 Me diga quais nomes você vê!")
end

-- Executa
pcall(ListAllObjects)

-- Tenta encontrar remotas também
print("")
print("🔍 PROCURANDO REMOTES...")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("📡 Remote: " .. obj.Name)
    end
end

print("")
print("========================================")
print("  ✅ LISTAGEM CONCLUÍDA")
print("========================================")
