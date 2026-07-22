-- SCRIPT DE TESTE
print("🔍 TESTE DE CAPTURA...")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

-- 1. MOSTRA TODOS OS REMOTES
print("\n📡 REMOTES ENCONTRADOS:")
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("  - " .. obj:GetFullName())
    end
end

-- 2. MOSTRA TODOS OS BOTÕES DA UI
print("\n🖱️ BOTÕES NA UI:")
local guis = {CoreGui, Player:FindFirstChild("PlayerGui")}
for _, gui in pairs(guis) do
    if gui then
        for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if obj.Visible then
                    print("  - " .. obj:GetFullName())
                    print("    Texto: " .. (obj.Text or "sem texto"))
                end
            end
        end
    end
end

-- 3. MOSTRA ESTRUTURA DO PRIMEIRO PET
print("\n🐾 ESTRUTURA DO PET:")
for _, obj in pairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        if obj ~= Player.Character and not Players:GetPlayerFromCharacter(obj) then
            print("  Nome: " .. obj.Name)
            for _, child in pairs(obj:GetChildren()) do
                print("    - " .. child.Name .. " (" .. child.ClassName .. ")")
            end
            break
        end
    end
end

print("\n✅ TESTE FINALIZADO!")
print("📌 Copie e cole o que apareceu acima")
