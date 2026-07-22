-- Script com mensagens no chat
print("📱 TESTANDO SCRIPT...")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Função para enviar mensagem no chat
local function SendChatMessage(msg)
    pcall(function()
        local chat = game:GetService("TextChatService")
        if chat and chat.TextChannels then
            local channel = chat.TextChannels:FindFirstChild("General") or chat.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(msg)
                return
            end
        end
    end)
    
    -- Fallback
    pcall(function()
        game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents"):FindFirstChild("SayMessageRequest"):FireServer(msg, "All")
    end)
end

-- Envia mensagem de teste
SendChatMessage("✅ SCRIPT CARREGADO NO CELULAR!")
SendChatMessage("📱 Use os comandos no chat: !auto, !esp, !help")
print("✅ Script rodando!")

-- Mostra no chat
SendChatMessage("🔍 Digite !help no chat para ver os comandos")
