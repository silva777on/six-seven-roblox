-- TESTE DE CAPTURA
print("🔍 TESTE DE CAPTURA - MANUAL")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

print("\n📡 REMOTES ENCONTRADOS:")
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("  - " .. obj:GetFullName())
    end
end

print("\n🖱️ BOTÕES NA UI:")
local guis = {CoreGui, player:FindFirstChild("PlayerGui")}
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

print("\n✅ TESTE FINALIZADO!")
print("📌 Me diga o que apareceu acima")
