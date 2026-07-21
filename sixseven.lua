-- SCRIPT QUE DESTACA TUDO QUE TEM CLICKDETECTOR OU BILLBOARD
print("🔥 PROCURANDO OBJETOS INTERATIVOS...")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Lista para guardar os objetos encontrados
local foundObjects = {}
local highlightedObjects = {}

-- Função para destacar um objeto
local function HighlightObject(obj, color)
    if not obj then return end
    if highlightedObjects[obj] then return end
    
    pcall(function()
        local h = Instance.new("Highlight")
        h.Parent = obj
        h.FillColor = color or Color3.fromRGB(0, 255, 0)
        h.FillTransparency = 0.2
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = true
        highlightedObjects[obj] = h
        print("✅ Destacado: " .. obj.Name)
    end)
end

-- Procura por objetos com ClickDetector
print("")
print("🔍 1. PROCURANDO CLICKDETECTORS...")
local clickDetectors = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("ClickDetector") and obj.Parent then
        table.insert(clickDetectors, obj.Parent)
        print("   - ClickDetector em: " .. obj.Parent.Name)
        HighlightObject(obj.Parent, Color3.fromRGB(255, 0, 0))
    end
end

-- Procura por objetos com BillboardGui (nomes flutuantes)
print("")
print("🔍 2. PROCURANDO BILLBOARDGUIS...")
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") and obj.Parent then
        print("   - BillboardGui em: " .. obj.Parent.Name)
        table.insert(foundObjects, obj.Parent)
        HighlightObject(obj.Parent, Color3.fromRGB(0, 255, 0))
    end
end

-- Procura por objetos com nomes específicos
print("")
print("🔍 3. PROCURANDO POR NOMES DE PET...")
local petNames = {"Pet", "Creature", "Monster", "Animal", "Wild", "Capture", "Divino", "Mistico", "Chefe", "Boss"}
for _, name in pairs(petNames) do
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(name) then
            print("   - Encontrado: " .. obj.Name)
            HighlightObject(obj, Color3.fromRGB(0, 0, 255))
        end
    end
end

-- Procura por objetos com "Humanoid" (que não são players)
print("")
print("🔍 4. PROCURANDO HUMANOIDS (QUE NÃO SÃO PLAYERS)...")
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Humanoid") and obj.Parent then
        if obj.Parent ~= Player.Character then
            print("   - Humanoid em: " .. obj.Parent.Name)
            HighlightObject(obj.Parent, Color3.fromRGB(255, 255, 0))
        end
    end
end

-- Procura por objetos com "Model" que têm partes
print("")
print("🔍 5. PROCURANDO MODELOS COM PARTES...")
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and #obj:GetChildren() > 0 then
        local hasParts = false
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("BasePart") then
                hasParts = true
                break
            end
        end
        if hasParts and obj ~= Player.Character then
            -- Verifica se não é algo comum
            local name = obj.Name:lower()
            if not name:find("base") and not name:find("ground") and not name:find("wall") and not name:find("floor") then
                print("   - Modelo com partes: " .. obj.Name)
                HighlightObject(obj, Color3.fromRGB(255, 0, 255))
            end
        end
    end
end

print("")
print("========================================")
print("  ✅ DIAGNÓSTICO CONCLUÍDO")
print("========================================")
print("")
print("📊 Total de objetos destacados: " .. #highlightedObjects)
print("")
print("🎨 CORES:")
print("   🔴 Vermelho = ClickDetector")
print("   🟢 Verde = BillboardGui")
print("   🔵 Azul = Nome de pet")
print("   🟡 Amarelo = Humanoid (não player)")
print("   🟣 Roxo = Modelo com partes")
print("")
print("👀 Olhe ao redor e veja:")
print("   - Algum pet ficou destacado?")
print("   - Qual cor ele ficou?")
print("   - Qual o nome dele?")
print("========================================")
