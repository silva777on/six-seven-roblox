--[[
    CapturarPet.server.lua

    O que este script faz:
    1. Fica "escutando" todos os Pets que existem dentro de workspace.Pets
    2. Quando um jogador toca em um Pet, o script:
       - Marca o Pet como "capturado" (evita capturar 2x com debounce)
       - Encontra a Base do jogador (procura em workspace.Bases um Model
         que tenha um atributo "Dono" igual ao jogador)
       - Usa TweenService pra mover o Pet suavemente até a base
       - Ao chegar na base, soma +1 no valor de pets do jogador
         (leaderstats.Pets) e destrói o modelo do Pet do mapa

    ESTRUTURA ESPERADA NO JOGO (ajuste os nomes conforme o seu jogo):

    workspace
     ├── Pets                (Folder com os Models dos pets soltos no mapa)
     │     ├── Pet1 (Model, com uma parte primária "PrimaryPart" ou "HumanoidRootPart"/"Handle")
     │     └── Pet2 (Model)
     └── Bases                (Folder com as bases dos jogadores)
           ├── Base1 (Model) -> tem um Attribute "Dono" (string) = Nome do jogador
           │     └── PontoDeEntrega (Part) -> onde o pet vai parar dentro da base
           └── Base2 (Model)

    Cada jogador precisa ter, ao entrar no jogo, um leaderstat chamado "Pets"
    (IntValue). Se você não tiver isso ainda, adicione o script auxiliar
    "Leaderstats.server.lua" (mandado separado) ou me avise que eu gero.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local PETS_FOLDER = workspace:WaitForChild("Pets")
local BASES_FOLDER = workspace:WaitForChild("Bases")

local TEMPO_VIAGEM = 2 -- segundos que o pet demora pra "andar" até a base
local DISTANCIA_CAPTURA = 6 -- estuda: raio de detecção por toque não precisa disso, é opcional

-- Debounce por pet (evita que 2 jogadores capturem o mesmo pet ao mesmo tempo)
local petsEmCaptura = {}

-- Acha a base do jogador procurando pelo Attribute "Dono"
local function encontrarBaseDoJogador(jogador)
	for _, base in ipairs(BASES_FOLDER:GetChildren()) do
		if base:GetAttribute("Dono") == jogador.Name then
			return base
		end
	end
	return nil
end

-- Pega a parte primária do modelo do pet (pra poder mover com Tween)
local function pegarParteDoPet(petModel)
	if petModel.PrimaryPart then
		return petModel.PrimaryPart
	end
	local parte = petModel:FindFirstChild("HumanoidRootPart") or petModel:FindFirstChild("Handle")
	if parte then
		petModel.PrimaryPart = parte
		return parte
	end
	-- fallback: pega a primeira BasePart que encontrar
	for _, filho in ipairs(petModel:GetDescendants()) do
		if filho:IsA("BasePart") then
			petModel.PrimaryPart = filho
			return filho
		end
	end
	return nil
end

-- Move o pet suavemente até o ponto de entrega da base
local function levarPetParaBase(petModel, base, jogador)
	local parte = pegarParteDoPet(petModel)
	if not parte then
		warn("Pet sem nenhuma parte válida:", petModel:GetFullName())
		return
	end

	local pontoEntrega = base:FindFirstChild("PontoDeEntrega")
	local destino = pontoEntrega and pontoEntrega.Position or base:GetPivot().Position

	-- Desliga colisão física pra não trombar em nada no caminho
	for _, descendente in ipairs(petModel:GetDescendants()) do
		if descendente:IsA("BasePart") then
			descendente.Anchored = true
			descendente.CanCollide = false
		end
	end

	local metaInfo = TweenInfo.new(TEMPO_VIAGEM, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(parte, metaInfo, {
		CFrame = CFrame.new(destino)
	})

	tween:Play()
	tween.Completed:Connect(function()
		-- Chegou na base: soma no contador do jogador e remove o pet do mapa
		local leaderstats = jogador:FindFirstChild("leaderstats")
		local statPets = leaderstats and leaderstats:FindFirstChild("Pets")
		if statPets then
			statPets.Value += 1
		end

		petModel:Destroy()
		petsEmCaptura[petModel] = nil
	end)
end

-- Conecta o evento de toque em um pet específico
local function conectarPet(petModel)
	local parte = pegarParteDoPet(petModel)
	if not parte then return end

	local conexao
	conexao = parte.Touched:Connect(function(hit)
		local personagem = hit:FindFirstAncestorOfClass("Model")
		if not personagem then return end

		local jogador = Players:GetPlayerFromCharacter(personagem)
		if not jogador then return end

		if petsEmCaptura[petModel] then return end -- já está sendo capturado
		petsEmCaptura[petModel] = true

		local base = encontrarBaseDoJogador(jogador)
		if not base then
			warn("Jogador " .. jogador.Name .. " não tem base configurada!")
			petsEmCaptura[petModel] = nil
			return
		end

		conexao:Disconnect() -- não precisa mais escutar toque nesse pet
		levarPetParaBase(petModel, base, jogador)
	end)
end

-- Conecta todos os pets que já existem no mapa
for _, petModel in ipairs(PETS_FOLDER:GetChildren()) do
	if petModel:IsA("Model") then
		conectarPet(petModel)
	end
end

-- Conecta pets que forem adicionados depois (spawn dinâmico)
PETS_FOLDER.ChildAdded:Connect(function(filho)
	if filho:IsA("Model") then
		-- pequeno delay pra garantir que todas as partes já carregaram
		task.wait(0.1)
		conectarPet(filho)
	end
end)
