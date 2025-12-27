--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                               ║
    ║   ███████╗ █████╗ ██╗   ██╗ █████╗  ██████╗ ███████╗ ██████╗██╗  ██╗███████╗ █████╗ ████████╗ ║
    ║   ██╔════╝██╔══██╗██║   ██║██╔══██╗██╔════╝ ██╔════╝██╔════╝██║  ██║██╔════╝██╔══██╗╚══██╔══╝ ║
    ║   ███████╗███████║██║   ██║███████║██║  ███╗█████╗  ██║     ███████║█████╗  ███████║   ██║    ║
    ║   ╚════██║██╔══██║╚██╗ ██╔╝██╔══██║██║   ██║██╔══╝  ██║     ██╔══██║██╔══╝  ██╔══██║   ██║    ║
    ║   ███████║██║  ██║ ╚████╔╝ ██║  ██║╚██████╔╝███████╗╚██████╗██║  ██║███████╗██║  ██║   ██║    ║
    ║   ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝    ║
    ║                                                                                               ║
    ║                              AIMBOT UNIVERSAL v8.0                                            ║
    ║                    Reescrita Completa - 100% Mobile Optimized                                 ║
    ║                                                                                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
    
    VERSÃO 8.0 - REESCRITA COMPLETA
    
    Correções baseadas em análise profunda:
    ✅ FOV centralizado EXATAMENTE no centro da tela
    ✅ Aimbot funcional com suavização correta
    ✅ Disparo automático que NÃO trava controles
    ✅ Bala mágica (Silent Aim) que NÃO trava câmera
    ✅ UI arrastável sem mover câmera do jogo
    ✅ Scroll que não interfere com controles
    ✅ Hitbox expander que não faz jogadores sumirem
    ✅ Todas as opções funcionais e responsivas
]]

--============================================================
-- VERIFICAÇÃO DE INSTÂNCIA ÚNICA
--============================================================
if getgenv and getgenv().SAVAGECHEATS_LOADED then
    warn("[SAVAGECHEATS_] Script já está em execução!")
    return
end
if getgenv then
    getgenv().SAVAGECHEATS_LOADED = true
end

--============================================================
-- SEÇÃO 1: SERVIÇOS
--============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local Teams = game:GetService("Teams")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--============================================================
-- SEÇÃO 2: CONFIGURAÇÃO
--============================================================
local Config = {
    -- Aimbot Principal
    AimbotAtivo = false,
    ParteAlvo = "Head",
    FOVRaio = 150,
    Suavizacao = 0.3,
    DistanciaMaxima = 1000,
    VerificarParedes = true,
    PularKnocked = true,
    ModoTime = "Inimigos",
    
    -- FOV Visual
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(255, 50, 50),
    FOVCorTravado = Color3.fromRGB(50, 255, 50),
    
    -- Disparo Automático
    DisparoAtivo = false,
    DisparoDelay = 0.15,
    DisparoApenasComAlvo = true,
    
    -- Silent Aim (Bala Mágica)
    SilentAimAtivo = false,
    SilentAimChance = 100,
    
    -- Hitbox Expander
    HitboxAtivo = false,
    HitboxTamanho = 3,
    HitboxParte = "Head",
    
    -- ESP
    ESPAtivo = false,
    ESPBox = true,
    ESPNome = true,
    ESPVida = true,
    ESPDistancia = true,
    ESPTracer = false,
}

--============================================================
-- SEÇÃO 3: ESTADO GLOBAL
--============================================================
local Estado = {
    Travado = false,
    AlvoAtual = nil,
    ParteAtual = nil,
    
    UIAberta = true,
    InteragindoUI = false,
    Arrastando = false,
    AbaAtual = "Aim",
    
    Rodando = true,
}

--============================================================
-- SEÇÃO 4: ARMAZENAMENTO
--============================================================
local Conexoes = {}
local ElementosESP = {}
local HitboxOriginais = {}
local FOVCircle = nil
local ScreenGui = nil
local MainFrame = nil

-- Hooks
local SilentAimHook = nil
local NamecallOriginal = nil

--============================================================
-- SEÇÃO 5: TEMA VISUAL
--============================================================
local Tema = {
    Fundo = Color3.fromRGB(20, 20, 20),
    FundoSecundario = Color3.fromRGB(30, 30, 30),
    FundoTerciario = Color3.fromRGB(40, 40, 40),
    Destaque = Color3.fromRGB(200, 50, 50),
    DestaqueHover = Color3.fromRGB(230, 70, 70),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Borda = Color3.fromRGB(200, 50, 50),
    Sucesso = Color3.fromRGB(50, 200, 50),
    Erro = Color3.fromRGB(200, 50, 50),
}


--============================================================
-- SEÇÃO 6: FUNÇÕES UTILITÁRIAS
--============================================================

-- Obter centro EXATO da tela
local function GetCentroTela()
    local viewport = Camera.ViewportSize
    return Vector2.new(viewport.X / 2, viewport.Y / 2)
end

-- Converter posição 3D para 2D
local function WorldToScreen(posicao3D)
    local pos, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(pos.X, pos.Y), visivel and pos.Z > 0
end

-- Distância 2D
local function Distancia2D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Distância 3D
local function Distancia3D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Verificar se personagem está vivo
local function EstaVivo(personagem)
    if not personagem then return false end
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Verificar se está knocked/downed
local function EstaKnocked(personagem)
    if not personagem then return false end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Physics or
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.Ragdoll then
            return true
        end
    end
    
    -- Verificar atributos comuns de knocked
    local atributos = {"Knocked", "Downed", "DBNO", "IsKnocked", "IsDowned", "isKnocked"}
    for _, attr in pairs(atributos) do
        if personagem:GetAttribute(attr) == true then
            return true
        end
    end
    
    -- Verificar valores em objetos
    for _, child in pairs(personagem:GetChildren()) do
        if child:IsA("BoolValue") then
            local nome = string.lower(child.Name)
            if string.find(nome, "knock") or string.find(nome, "down") then
                if child.Value == true then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Verificar se é do mesmo time
local function MesmoTime(jogador)
    if Config.ModoTime == "Todos" then
        return false -- Atacar todos
    end
    
    if Config.ModoTime == "Inimigos" then
        if LocalPlayer.Team and jogador.Team then
            return LocalPlayer.Team == jogador.Team
        end
        return false
    end
    
    -- Time específico selecionado para atacar
    if jogador.Team then
        return jogador.Team.Name ~= Config.ModoTime
    end
    
    return false
end

-- Verificar visibilidade (raycast)
local function PodeVer(origem, destino)
    if not Config.VerificarParedes then
        return true
    end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local direcao = destino - origem
    local resultado = Workspace:Raycast(origem, direcao, rayParams)
    
    if resultado then
        local hit = resultado.Instance
        -- Verificar se acertou um jogador
        local modelo = hit:FindFirstAncestorOfClass("Model")
        if modelo then
            local jogador = Players:GetPlayerFromCharacter(modelo)
            if jogador and jogador ~= LocalPlayer then
                return true
            end
        end
        return false
    end
    
    return true
end

-- Obter lista de times disponíveis
local function GetTimesDisponiveis()
    local lista = {"Inimigos", "Todos"}
    
    pcall(function()
        for _, team in pairs(Teams:GetTeams()) do
            table.insert(lista, team.Name)
        end
    end)
    
    return lista
end

--============================================================
-- SEÇÃO 7: SISTEMA DE SELEÇÃO DE ALVO
--============================================================

-- Obter parte do corpo alvo
local function ObterParteAlvo(personagem)
    local partesOrdem = {Config.ParteAlvo, "Head", "HumanoidRootPart", "UpperTorso", "Torso"}
    
    for _, nome in ipairs(partesOrdem) do
        local parte = personagem:FindFirstChild(nome)
        if parte and parte:IsA("BasePart") then
            return parte
        end
    end
    
    return nil
end

-- Encontrar melhor alvo
local function EncontrarMelhorAlvo()
    if not Config.AimbotAtivo then
        return nil, nil
    end
    
    local melhorAlvo = nil
    local melhorParte = nil
    local menorDistancia = Config.FOVRaio
    
    local centroTela = GetCentroTela()
    local posicaoCamera = Camera.CFrame.Position
    
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            local personagem = jogador.Character
            
            if personagem and EstaVivo(personagem) then
                -- Verificar time
                if MesmoTime(jogador) then
                    continue
                end
                
                -- Verificar knocked
                if Config.PularKnocked and EstaKnocked(personagem) then
                    continue
                end
                
                local parte = ObterParteAlvo(personagem)
                if parte then
                    local posicaoTela, visivel = WorldToScreen(parte.Position)
                    
                    if visivel then
                        local dist2D = Distancia2D(centroTela, posicaoTela)
                        local dist3D = Distancia3D(posicaoCamera, parte.Position)
                        
                        if dist2D < menorDistancia and dist3D <= Config.DistanciaMaxima then
                            -- Verificar visibilidade
                            if PodeVer(posicaoCamera, parte.Position) then
                                menorDistancia = dist2D
                                melhorAlvo = jogador
                                melhorParte = parte
                            end
                        end
                    end
                end
            end
        end
    end
    
    return melhorAlvo, melhorParte
end


--============================================================
-- SEÇÃO 8: SISTEMA DE MIRA
--============================================================

-- Aplicar mira com suavização
local function AplicarMira(posicaoAlvo)
    -- VERIFICAÇÕES DE SEGURANÇA
    if Estado.InteragindoUI then return end
    if Estado.Arrastando then return end
    if not Config.AimbotAtivo then return end
    
    local cframeAtual = Camera.CFrame
    local cframeAlvo = CFrame.new(cframeAtual.Position, posicaoAlvo)
    
    -- Aplicar suavização (0 = instantâneo, 1 = muito lento)
    local fator = math.clamp(1 - Config.Suavizacao, 0.1, 1)
    local novoCFrame = cframeAtual:Lerp(cframeAlvo, fator)
    
    Camera.CFrame = novoCFrame
end

--============================================================
-- SEÇÃO 9: SISTEMA DE DISPARO AUTOMÁTICO (SEGURO)
--============================================================

local UltimoDisparo = 0
local BotaoTiroCache = nil

-- Encontrar botão de tiro do jogo (mobile)
local function EncontrarBotaoTiro()
    if BotaoTiroCache and BotaoTiroCache.Parent then
        return BotaoTiroCache
    end
    
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    -- Nomes comuns de botões de tiro
    local nomesComuns = {
        "ShootButton", "FireButton", "AttackButton",
        "Shoot", "Fire", "Attack", "Trigger",
        "shoot", "fire", "attack", "trigger"
    }
    
    -- Procurar em TouchGui
    local touchGui = playerGui:FindFirstChild("TouchGui")
    if touchGui then
        for _, nome in pairs(nomesComuns) do
            local botao = touchGui:FindFirstChild(nome, true)
            if botao and (botao:IsA("ImageButton") or botao:IsA("TextButton")) then
                BotaoTiroCache = botao
                return botao
            end
        end
    end
    
    -- Procurar em toda a PlayerGui
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, nome in pairs(nomesComuns) do
                local botao = gui:FindFirstChild(nome, true)
                if botao and (botao:IsA("ImageButton") or botao:IsA("TextButton")) then
                    BotaoTiroCache = botao
                    return botao
                end
            end
        end
    end
    
    return nil
end

-- Executar disparo de forma SEGURA
local function ExecutarDisparo()
    if not Config.DisparoAtivo then return end
    if Estado.InteragindoUI then return end
    
    -- Verificar se deve atirar apenas com alvo
    if Config.DisparoApenasComAlvo and not Estado.Travado then
        return
    end
    
    -- Verificar delay
    local agora = tick()
    if agora - UltimoDisparo < Config.DisparoDelay then
        return
    end
    
    UltimoDisparo = agora
    
    -- Executar em thread separada para não bloquear
    task.spawn(function()
        -- Método 1: Tentar usar botão do jogo
        local botao = EncontrarBotaoTiro()
        if botao then
            pcall(function()
                -- Simular toque
                if firetouchinterest then
                    firetouchinterest(botao, Vector2.new(0, 0), 0)
                    task.wait(0.02)
                    firetouchinterest(botao, Vector2.new(0, 0), 1)
                    return
                end
            end)
        end
        
        -- Método 2: VirtualInputManager (mais seguro que mouse1click)
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            local centro = GetCentroTela()
            
            -- Enviar evento de mouse de forma assíncrona
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, true, game, 1)
            task.defer(function()
                VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, false, game, 1)
            end)
        end)
    end)
end

--============================================================
-- SEÇÃO 10: SILENT AIM (BALA MÁGICA) - IMPLEMENTAÇÃO CORRETA
--============================================================

-- Lista de palavras-chave que indicam Remotes de tiro
local PALAVRAS_TIRO = {
    "shoot", "fire", "attack", "damage", "hit", "bullet",
    "weapon", "gun", "projectile", "ray", "cast"
}

-- Verificar se é um Remote de tiro
local function EhRemoteDeTiro(nome)
    local nomeLower = string.lower(nome or "")
    for _, palavra in pairs(PALAVRAS_TIRO) do
        if string.find(nomeLower, palavra) then
            return true
        end
    end
    return false
end

-- Ativar Silent Aim
local function AtivarSilentAim()
    if SilentAimHook then return end
    
    local sucesso = pcall(function()
        local mt = getrawmetatable(game)
        NamecallOriginal = mt.__namecall
        
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            -- Só modificar se:
            -- 1. Silent Aim está ativo
            -- 2. Temos um alvo travado
            -- 3. É FireServer ou InvokeServer
            -- 4. O Remote parece ser de tiro
            if Config.SilentAimAtivo and Estado.Travado and Estado.ParteAtual then
                if method == "FireServer" or method == "InvokeServer" then
                    -- Verificar se é Remote de tiro pelo nome
                    local remoteName = self.Name or ""
                    
                    if EhRemoteDeTiro(remoteName) then
                        -- Verificar chance de hit
                        if math.random(1, 100) <= Config.SilentAimChance then
                            -- Modificar argumentos
                            local novosArgs = {}
                            for i, arg in pairs(args) do
                                if typeof(arg) == "Vector3" then
                                    novosArgs[i] = Estado.ParteAtual.Position
                                elseif typeof(arg) == "CFrame" then
                                    novosArgs[i] = Estado.ParteAtual.CFrame
                                else
                                    novosArgs[i] = arg
                                end
                            end
                            return NamecallOriginal(self, unpack(novosArgs))
                        end
                    end
                end
            end
            
            return NamecallOriginal(self, ...)
        end)
        
        setreadonly(mt, true)
        SilentAimHook = true
    end)
    
    if not sucesso then
        warn("[SAVAGECHEATS_] Falha ao ativar Silent Aim - executor pode não suportar hooks")
    end
end

-- Desativar Silent Aim
local function DesativarSilentAim()
    if not SilentAimHook then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = NamecallOriginal
        setreadonly(mt, true)
        SilentAimHook = nil
    end)
end


--============================================================
-- SEÇÃO 11: HITBOX EXPANDER (IMPLEMENTAÇÃO SEGURA)
--============================================================

-- Aplicar hitbox expandida
local function AplicarHitbox(jogador)
    if not Config.HitboxAtivo then return end
    if jogador == LocalPlayer then return end
    
    local personagem = jogador.Character
    if not personagem then return end
    
    local parte = personagem:FindFirstChild(Config.HitboxParte)
    if not parte or not parte:IsA("BasePart") then return end
    
    -- Salvar tamanho original
    if not HitboxOriginais[jogador] then
        HitboxOriginais[jogador] = {}
    end
    
    if not HitboxOriginais[jogador][Config.HitboxParte] then
        HitboxOriginais[jogador][Config.HitboxParte] = {
            Size = parte.Size,
            Transparency = parte.Transparency,
            CanCollide = parte.CanCollide
        }
    end
    
    -- Aplicar tamanho expandido (máximo de 5 para evitar bugs)
    local tamanho = math.clamp(Config.HitboxTamanho, 1, 5)
    local novoTamanho = Vector3.new(tamanho, tamanho, tamanho)
    
    pcall(function()
        parte.Size = novoTamanho
        parte.Transparency = 0.8
        parte.CanCollide = false
    end)
end

-- Restaurar hitbox original
local function RestaurarHitbox(jogador)
    if not HitboxOriginais[jogador] then return end
    
    local personagem = jogador.Character
    if not personagem then return end
    
    for nomeParte, dados in pairs(HitboxOriginais[jogador]) do
        local parte = personagem:FindFirstChild(nomeParte)
        if parte and parte:IsA("BasePart") then
            pcall(function()
                parte.Size = dados.Size
                parte.Transparency = dados.Transparency
                parte.CanCollide = dados.CanCollide
            end)
        end
    end
    
    HitboxOriginais[jogador] = nil
end

-- Restaurar todas as hitboxes
local function RestaurarTodasHitboxes()
    for jogador, _ in pairs(HitboxOriginais) do
        RestaurarHitbox(jogador)
    end
    HitboxOriginais = {}
end

-- Atualizar hitboxes de todos os jogadores
local function AtualizarHitboxes()
    if not Config.HitboxAtivo then
        RestaurarTodasHitboxes()
        return
    end
    
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            AplicarHitbox(jogador)
        end
    end
end

--============================================================
-- SEÇÃO 12: FOV CIRCLE
--============================================================

-- Criar FOV Circle
local function CriarFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
    end
    
    -- Verificar se Drawing está disponível
    if not Drawing then
        warn("[SAVAGECHEATS_] Drawing não disponível - FOV Circle desativado")
        return
    end
    
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 2
        FOVCircle.Filled = false
        FOVCircle.Transparency = 1
        FOVCircle.Color = Config.FOVCor
        FOVCircle.Radius = Config.FOVRaio
        FOVCircle.Visible = Config.FOVVisivel
        
        -- Posicionar no centro
        local centro = GetCentroTela()
        FOVCircle.Position = centro
    end)
end

-- Atualizar FOV Circle
local function AtualizarFOVCircle()
    if not FOVCircle then return end
    
    pcall(function()
        -- Centro EXATO da tela
        local centro = GetCentroTela()
        
        FOVCircle.Position = centro
        FOVCircle.Radius = Config.FOVRaio
        FOVCircle.Visible = Config.FOVVisivel and Config.AimbotAtivo
        
        -- Mudar cor quando travado
        if Estado.Travado then
            FOVCircle.Color = Config.FOVCorTravado
        else
            FOVCircle.Color = Config.FOVCor
        end
    end)
end

-- Destruir FOV Circle
local function DestruirFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
end

--============================================================
-- SEÇÃO 13: SISTEMA ESP
--============================================================

-- Criar ESP para jogador
local function CriarESPJogador(jogador)
    if jogador == LocalPlayer then return end
    if ElementosESP[jogador] then return end
    
    if not Drawing then return end
    
    local elementos = {}
    
    pcall(function()
        elementos.Box = Drawing.new("Square")
        elementos.Box.Thickness = 1
        elementos.Box.Filled = false
        elementos.Box.Transparency = 1
        elementos.Box.Visible = false
        
        elementos.Nome = Drawing.new("Text")
        elementos.Nome.Size = 14
        elementos.Nome.Center = true
        elementos.Nome.Outline = true
        elementos.Nome.Transparency = 1
        elementos.Nome.Visible = false
        
        elementos.Vida = Drawing.new("Text")
        elementos.Vida.Size = 12
        elementos.Vida.Center = true
        elementos.Vida.Outline = true
        elementos.Vida.Transparency = 1
        elementos.Vida.Visible = false
        
        elementos.Distancia = Drawing.new("Text")
        elementos.Distancia.Size = 12
        elementos.Distancia.Center = true
        elementos.Distancia.Outline = true
        elementos.Distancia.Transparency = 1
        elementos.Distancia.Visible = false
        
        elementos.Tracer = Drawing.new("Line")
        elementos.Tracer.Thickness = 1
        elementos.Tracer.Transparency = 1
        elementos.Tracer.Visible = false
    end)
    
    ElementosESP[jogador] = elementos
end

-- Atualizar ESP de um jogador
local function AtualizarESPJogador(jogador)
    local elementos = ElementosESP[jogador]
    if not elementos then return end
    
    -- Esconder se ESP desativado
    if not Config.ESPAtivo then
        for _, elem in pairs(elementos) do
            if elem then pcall(function() elem.Visible = false end) end
        end
        return
    end
    
    local personagem = jogador.Character
    if not personagem or not EstaVivo(personagem) then
        for _, elem in pairs(elementos) do
            if elem then pcall(function() elem.Visible = false end) end
        end
        return
    end
    
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    local head = personagem:FindFirstChild("Head")
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    
    if not rootPart or not humanoid then
        for _, elem in pairs(elementos) do
            if elem then pcall(function() elem.Visible = false end) end
        end
        return
    end
    
    local posicaoTela, visivel = WorldToScreen(rootPart.Position)
    if not visivel then
        for _, elem in pairs(elementos) do
            if elem then pcall(function() elem.Visible = false end) end
        end
        return
    end
    
    -- Determinar cor (inimigo = vermelho, aliado = verde)
    local cor = MesmoTime(jogador) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    
    -- Calcular tamanho da box baseado na distância
    local distancia = Distancia3D(Camera.CFrame.Position, rootPart.Position)
    local fator = 1000 / math.max(distancia, 1)
    local largura = math.clamp(fator * 4, 15, 80)
    local altura = math.clamp(fator * 5, 25, 120)
    
    pcall(function()
        -- Box
        if elementos.Box and Config.ESPBox then
            elementos.Box.Size = Vector2.new(largura, altura)
            elementos.Box.Position = Vector2.new(posicaoTela.X - largura/2, posicaoTela.Y - altura/2)
            elementos.Box.Color = cor
            elementos.Box.Visible = true
        elseif elementos.Box then
            elementos.Box.Visible = false
        end
        
        -- Nome
        if elementos.Nome and Config.ESPNome then
            elementos.Nome.Text = jogador.Name
            elementos.Nome.Position = Vector2.new(posicaoTela.X, posicaoTela.Y - altura/2 - 16)
            elementos.Nome.Color = cor
            elementos.Nome.Visible = true
        elseif elementos.Nome then
            elementos.Nome.Visible = false
        end
        
        -- Vida
        if elementos.Vida and Config.ESPVida then
            local vida = math.floor(humanoid.Health)
            local vidaMax = math.floor(humanoid.MaxHealth)
            local porcentagem = math.floor((vida / vidaMax) * 100)
            
            local corVida = Color3.fromRGB(255, 0, 0)
            if porcentagem > 70 then
                corVida = Color3.fromRGB(0, 255, 0)
            elseif porcentagem > 30 then
                corVida = Color3.fromRGB(255, 255, 0)
            end
            
            elementos.Vida.Text = string.format("%d HP (%d%%)", vida, porcentagem)
            elementos.Vida.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + altura/2 + 2)
            elementos.Vida.Color = corVida
            elementos.Vida.Visible = true
        elseif elementos.Vida then
            elementos.Vida.Visible = false
        end
        
        -- Distância
        if elementos.Distancia and Config.ESPDistancia then
            elementos.Distancia.Text = string.format("%.0fm", distancia)
            elementos.Distancia.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + altura/2 + 16)
            elementos.Distancia.Color = cor
            elementos.Distancia.Visible = true
        elseif elementos.Distancia then
            elementos.Distancia.Visible = false
        end
        
        -- Tracer
        if elementos.Tracer and Config.ESPTracer then
            local viewport = Camera.ViewportSize
            elementos.Tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
            elementos.Tracer.To = posicaoTela
            elementos.Tracer.Color = cor
            elementos.Tracer.Visible = true
        elseif elementos.Tracer then
            elementos.Tracer.Visible = false
        end
    end)
end

-- Remover ESP de jogador
local function RemoverESPJogador(jogador)
    local elementos = ElementosESP[jogador]
    if not elementos then return end
    
    for _, elem in pairs(elementos) do
        if elem then
            pcall(function() elem:Remove() end)
        end
    end
    
    ElementosESP[jogador] = nil
end

-- Atualizar ESP de todos
local function AtualizarESP()
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            if not ElementosESP[jogador] then
                CriarESPJogador(jogador)
            end
            AtualizarESPJogador(jogador)
        end
    end
end

-- Destruir todo ESP
local function DestruirESP()
    for jogador, _ in pairs(ElementosESP) do
        RemoverESPJogador(jogador)
    end
    ElementosESP = {}
end


--============================================================
-- SEÇÃO 14: SISTEMA DE UI (MOBILE-FRIENDLY)
--============================================================

-- Criar ScreenGui
local function CriarScreenGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SAVAGECHEATS_UI_" .. math.random(1000, 9999)
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    
    pcall(function()
        gui.Parent = CoreGui
    end)
    
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    return gui
end

-- Tornar frame arrastável SEM mover câmera
local function TornarArrastavel(frame, handle)
    local arrastando = false
    local posicaoInicial = nil
    local frameInicial = nil
    
    handle.InputBegan:Connect(function(input, processado)
        if processado then return end
        
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = true
            posicaoInicial = input.Position
            frameInicial = frame.Position
            
            Estado.Arrastando = true
            Estado.InteragindoUI = true
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = false
            
            task.delay(0.15, function()
                Estado.Arrastando = false
                Estado.InteragindoUI = false
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if arrastando then
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - posicaoInicial
                frame.Position = UDim2.new(
                    frameInicial.X.Scale,
                    frameInicial.X.Offset + delta.X,
                    frameInicial.Y.Scale,
                    frameInicial.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- Criar checkbox
local function CriarCheckbox(parent, texto, valorInicial, callback, posY)
    local container = Instance.new("Frame")
    container.Name = "Checkbox_" .. texto
    container.Size = UDim2.new(1, -10, 0, 30)
    container.Position = UDim2.new(0, 5, 0, posY)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local box = Instance.new("TextButton")
    box.Name = "Box"
    box.Size = UDim2.new(0, 22, 0, 22)
    box.Position = UDim2.new(0, 0, 0.5, -11)
    box.BackgroundColor3 = valorInicial and Tema.Destaque or Tema.FundoTerciario
    box.BorderSizePixel = 0
    box.Text = valorInicial and "✓" or ""
    box.TextColor3 = Tema.Texto
    box.TextSize = 16
    box.Font = Enum.Font.GothamBold
    box.AutoButtonColor = false
    box.Active = true
    box.Parent = container
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -32, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = texto
    label.TextColor3 = Tema.Texto
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valor = valorInicial
    
    box.MouseButton1Click:Connect(function()
        valor = not valor
        box.BackgroundColor3 = valor and Tema.Destaque or Tema.FundoTerciario
        box.Text = valor and "✓" or ""
        if callback then
            callback(valor)
        end
    end)
    
    -- Touch support
    box.TouchTap:Connect(function()
        valor = not valor
        box.BackgroundColor3 = valor and Tema.Destaque or Tema.FundoTerciario
        box.Text = valor and "✓" or ""
        if callback then
            callback(valor)
        end
    end)
    
    return container, function(novoValor)
        valor = novoValor
        box.BackgroundColor3 = valor and Tema.Destaque or Tema.FundoTerciario
        box.Text = valor and "✓" or ""
    end
end

-- Criar slider
local function CriarSlider(parent, texto, minimo, maximo, valorInicial, callback, posY)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. texto
    container.Size = UDim2.new(1, -10, 0, 50)
    container.Position = UDim2.new(0, 5, 0, posY)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.7, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = texto
    label.TextColor3 = Tema.Texto
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valorLabel = Instance.new("TextLabel")
    valorLabel.Name = "Valor"
    valorLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valorLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valorLabel.BackgroundTransparency = 1
    valorLabel.Text = string.format("[%d]", valorInicial)
    valorLabel.TextColor3 = Tema.TextoSecundario
    valorLabel.TextSize = 14
    valorLabel.Font = Enum.Font.Gotham
    valorLabel.TextXAlignment = Enum.TextXAlignment.Right
    valorLabel.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "SliderBg"
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0, 28)
    sliderBg.BackgroundColor3 = Tema.FundoTerciario
    sliderBg.BorderSizePixel = 0
    sliderBg.Active = true
    sliderBg.Parent = container
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = sliderBg
    
    local porcentagem = (valorInicial - minimo) / (maximo - minimo)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
    sliderFill.BackgroundColor3 = Tema.Destaque
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    local valor = valorInicial
    local arrastando = false
    
    local function AtualizarSlider(inputPos)
        local posRelativa = inputPos.X - sliderBg.AbsolutePosition.X
        local largura = sliderBg.AbsoluteSize.X
        local novaPorc = math.clamp(posRelativa / largura, 0, 1)
        
        valor = math.floor(minimo + (maximo - minimo) * novaPorc)
        sliderFill.Size = UDim2.new(novaPorc, 0, 1, 0)
        valorLabel.Text = string.format("[%d]", valor)
        
        if callback then
            callback(valor)
        end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = true
            Estado.InteragindoUI = true
            AtualizarSlider(input.Position)
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = false
            task.delay(0.1, function()
                Estado.InteragindoUI = false
            end)
        end
    end)
    
    sliderBg.InputChanged:Connect(function(input)
        if arrastando then
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseMovement then
                AtualizarSlider(input.Position)
            end
        end
    end)
    
    return container, function(novoValor)
        valor = novoValor
        local novaPorc = (valor - minimo) / (maximo - minimo)
        sliderFill.Size = UDim2.new(novaPorc, 0, 1, 0)
        valorLabel.Text = string.format("[%d]", valor)
    end
end

-- Criar dropdown
local function CriarDropdown(parent, texto, opcoes, valorInicial, callback, posY)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. texto
    container.Size = UDim2.new(1, -10, 0, 55)
    container.Position = UDim2.new(0, 5, 0, posY)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.ZIndex = 10
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = texto
    label.TextColor3 = Tema.Texto
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10
    label.Parent = container
    
    local botao = Instance.new("TextButton")
    botao.Name = "Botao"
    botao.Size = UDim2.new(1, 0, 0, 28)
    botao.Position = UDim2.new(0, 0, 0, 22)
    botao.BackgroundColor3 = Tema.FundoTerciario
    botao.BorderSizePixel = 0
    botao.Text = valorInicial .. " ▼"
    botao.TextColor3 = Tema.Texto
    botao.TextSize = 13
    botao.Font = Enum.Font.Gotham
    botao.AutoButtonColor = false
    botao.Active = true
    botao.ZIndex = 10
    botao.Parent = container
    
    local botaoCorner = Instance.new("UICorner")
    botaoCorner.CornerRadius = UDim.new(0, 4)
    botaoCorner.Parent = botao
    
    local listaFrame = Instance.new("Frame")
    listaFrame.Name = "Lista"
    listaFrame.Size = UDim2.new(1, 0, 0, #opcoes * 25)
    listaFrame.Position = UDim2.new(0, 0, 0, 52)
    listaFrame.BackgroundColor3 = Tema.FundoSecundario
    listaFrame.BorderSizePixel = 0
    listaFrame.Visible = false
    listaFrame.ZIndex = 100
    listaFrame.ClipsDescendants = true
    listaFrame.Parent = container
    
    local listaCorner = Instance.new("UICorner")
    listaCorner.CornerRadius = UDim.new(0, 4)
    listaCorner.Parent = listaFrame
    
    local listaStroke = Instance.new("UIStroke")
    listaStroke.Color = Tema.Destaque
    listaStroke.Thickness = 1
    listaStroke.Parent = listaFrame
    
    local valor = valorInicial
    local aberto = false
    
    for i, opcao in ipairs(opcoes) do
        local opcaoBotao = Instance.new("TextButton")
        opcaoBotao.Name = "Opcao_" .. opcao
        opcaoBotao.Size = UDim2.new(1, 0, 0, 25)
        opcaoBotao.Position = UDim2.new(0, 0, 0, (i-1) * 25)
        opcaoBotao.BackgroundTransparency = 1
        opcaoBotao.Text = opcao
        opcaoBotao.TextColor3 = Tema.Texto
        opcaoBotao.TextSize = 13
        opcaoBotao.Font = Enum.Font.Gotham
        opcaoBotao.AutoButtonColor = false
        opcaoBotao.Active = true
        opcaoBotao.ZIndex = 101
        opcaoBotao.Parent = listaFrame
        
        opcaoBotao.MouseEnter:Connect(function()
            opcaoBotao.BackgroundTransparency = 0.8
            opcaoBotao.BackgroundColor3 = Tema.Destaque
        end)
        
        opcaoBotao.MouseLeave:Connect(function()
            opcaoBotao.BackgroundTransparency = 1
        end)
        
        opcaoBotao.MouseButton1Click:Connect(function()
            valor = opcao
            botao.Text = opcao .. " ▼"
            listaFrame.Visible = false
            aberto = false
            if callback then
                callback(opcao)
            end
        end)
        
        opcaoBotao.TouchTap:Connect(function()
            valor = opcao
            botao.Text = opcao .. " ▼"
            listaFrame.Visible = false
            aberto = false
            if callback then
                callback(opcao)
            end
        end)
    end
    
    botao.MouseButton1Click:Connect(function()
        aberto = not aberto
        listaFrame.Visible = aberto
        Estado.InteragindoUI = aberto
    end)
    
    botao.TouchTap:Connect(function()
        aberto = not aberto
        listaFrame.Visible = aberto
        Estado.InteragindoUI = aberto
    end)
    
    return container, function(novoValor)
        valor = novoValor
        botao.Text = novoValor .. " ▼"
    end
end

-- Criar separador
local function CriarSeparador(parent, texto, posY)
    local sep = Instance.new("Frame")
    sep.Name = "Separador"
    sep.Size = UDim2.new(1, -10, 0, 25)
    sep.Position = UDim2.new(0, 5, 0, posY)
    sep.BackgroundTransparency = 1
    sep.Parent = parent
    
    local linha = Instance.new("Frame")
    linha.Size = UDim2.new(1, 0, 0, 1)
    linha.Position = UDim2.new(0, 0, 0.5, 0)
    linha.BackgroundColor3 = Tema.Destaque
    linha.BorderSizePixel = 0
    linha.Parent = sep
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 0, 16)
    label.Position = UDim2.new(0.5, -40, 0.5, -8)
    label.BackgroundColor3 = Tema.Fundo
    label.BorderSizePixel = 0
    label.Text = texto
    label.TextColor3 = Tema.Destaque
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.Parent = sep
    
    return sep
end


--============================================================
-- SEÇÃO 15: CRIAÇÃO DA UI PRINCIPAL
--============================================================

local function CriarUI()
    ScreenGui = CriarScreenGui()
    
    -- Frame principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    MainFrame.BackgroundColor3 = Tema.Fundo
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Tema.Borda
    mainStroke.Thickness = 2
    mainStroke.Parent = MainFrame
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundTransparency = 1
    titleBar.Active = true
    titleBar.Parent = MainFrame
    
    -- Botão minimizar
    local btnMin = Instance.new("TextButton")
    btnMin.Name = "Minimizar"
    btnMin.Size = UDim2.new(0, 25, 0, 25)
    btnMin.Position = UDim2.new(0, 5, 0, 5)
    btnMin.BackgroundColor3 = Tema.Destaque
    btnMin.BorderSizePixel = 0
    btnMin.Text = "−"
    btnMin.TextColor3 = Tema.Texto
    btnMin.TextSize = 18
    btnMin.Font = Enum.Font.GothamBold
    btnMin.AutoButtonColor = false
    btnMin.Active = true
    btnMin.Parent = titleBar
    
    local btnMinCorner = Instance.new("UICorner")
    btnMinCorner.CornerRadius = UDim.new(0, 4)
    btnMinCorner.Parent = btnMin
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Size = UDim2.new(1, -70, 1, 0)
    titulo.Position = UDim2.new(0, 35, 0, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "SAVAGECHEATS_"
    titulo.TextColor3 = Tema.Texto
    titulo.TextSize = 16
    titulo.Font = Enum.Font.GothamBold
    titulo.Parent = titleBar
    
    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Name = "Fechar"
    btnFechar.Size = UDim2.new(0, 25, 0, 25)
    btnFechar.Position = UDim2.new(1, -30, 0, 5)
    btnFechar.BackgroundColor3 = Tema.Destaque
    btnFechar.BorderSizePixel = 0
    btnFechar.Text = "×"
    btnFechar.TextColor3 = Tema.Texto
    btnFechar.TextSize = 18
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.AutoButtonColor = false
    btnFechar.Active = true
    btnFechar.Parent = titleBar
    
    local btnFecharCorner = Instance.new("UICorner")
    btnFecharCorner.CornerRadius = UDim.new(0, 4)
    btnFecharCorner.Parent = btnFechar
    
    -- Tornar arrastável
    TornarArrastavel(MainFrame, titleBar)
    
    -- Container de abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -20, 0, 35)
    tabContainer.Position = UDim2.new(0, 10, 0, 40)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = MainFrame
    
    local abas = {"Esp", "Aim", "Config"}
    local botoesAbas = {}
    local conteudoAbas = {}
    
    for i, nomeAba in ipairs(abas) do
        local btnAba = Instance.new("TextButton")
        btnAba.Name = "Tab_" .. nomeAba
        btnAba.Size = UDim2.new(1/#abas, -5, 1, 0)
        btnAba.Position = UDim2.new((i-1)/#abas, 2, 0, 0)
        btnAba.BackgroundColor3 = nomeAba == "Aim" and Tema.Destaque or Tema.FundoTerciario
        btnAba.BorderSizePixel = 0
        btnAba.Text = nomeAba
        btnAba.TextColor3 = Tema.Texto
        btnAba.TextSize = 14
        btnAba.Font = Enum.Font.GothamBold
        btnAba.AutoButtonColor = false
        btnAba.Active = true
        btnAba.Parent = tabContainer
        
        local btnAbaCorner = Instance.new("UICorner")
        btnAbaCorner.CornerRadius = UDim.new(0, 4)
        btnAbaCorner.Parent = btnAba
        
        botoesAbas[nomeAba] = btnAba
    end
    
    -- Container de conteúdo
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -90)
    contentContainer.Position = UDim2.new(0, 10, 0, 80)
    contentContainer.BackgroundColor3 = Tema.FundoSecundario
    contentContainer.BorderSizePixel = 0
    contentContainer.Active = true
    contentContainer.ClipsDescendants = true
    contentContainer.Parent = MainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = contentContainer
    
    -- Criar ScrollingFrame para cada aba
    for _, nomeAba in ipairs(abas) do
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Content_" .. nomeAba
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4
        scroll.ScrollBarImageColor3 = Tema.Destaque
        scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
        scroll.Visible = nomeAba == "Aim"
        scroll.Active = true
        scroll.Parent = contentContainer
        
        -- Bloquear scroll de mover câmera
        scroll.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                Estado.InteragindoUI = true
            end
        end)
        
        scroll.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                task.delay(0.15, function()
                    Estado.InteragindoUI = false
                end)
            end
        end)
        
        conteudoAbas[nomeAba] = scroll
    end
    
    -- Função para trocar aba
    local function TrocarAba(nomeAba)
        Estado.AbaAtual = nomeAba
        
        for nome, btn in pairs(botoesAbas) do
            btn.BackgroundColor3 = nome == nomeAba and Tema.Destaque or Tema.FundoTerciario
        end
        
        for nome, content in pairs(conteudoAbas) do
            content.Visible = nome == nomeAba
        end
    end
    
    -- Conectar botões de aba
    for nome, btn in pairs(botoesAbas) do
        btn.MouseButton1Click:Connect(function()
            TrocarAba(nome)
        end)
        btn.TouchTap:Connect(function()
            TrocarAba(nome)
        end)
    end
    
    --============================================================
    -- CONTEÚDO DA ABA AIM
    --============================================================
    local abaAim = conteudoAbas["Aim"]
    local posY = 10
    
    CriarCheckbox(abaAim, "Aimbot Ativo", Config.AimbotAtivo, function(v)
        Config.AimbotAtivo = v
        if not v then
            Estado.Travado = false
            Estado.AlvoAtual = nil
            Estado.ParteAtual = nil
        end
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Verificar Paredes", Config.VerificarParedes, function(v)
        Config.VerificarParedes = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Pular Knocked", Config.PularKnocked, function(v)
        Config.PularKnocked = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Mostrar FOV", Config.FOVVisivel, function(v)
        Config.FOVVisivel = v
    end, posY)
    posY = posY + 40
    
    CriarSeparador(abaAim, "AJUSTES", posY)
    posY = posY + 30
    
    CriarSlider(abaAim, "Raio FOV", 50, 500, Config.FOVRaio, function(v)
        Config.FOVRaio = v
    end, posY)
    posY = posY + 55
    
    CriarSlider(abaAim, "Suavização", 0, 100, math.floor(Config.Suavizacao * 100), function(v)
        Config.Suavizacao = v / 100
    end, posY)
    posY = posY + 55
    
    CriarSlider(abaAim, "Distância Máx", 100, 2000, Config.DistanciaMaxima, function(v)
        Config.DistanciaMaxima = v
    end, posY)
    posY = posY + 60
    
    CriarDropdown(abaAim, "Parte Alvo", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Config.ParteAlvo, function(v)
        Config.ParteAlvo = v
    end, posY)
    posY = posY + 65
    
    CriarDropdown(abaAim, "Modo Time", GetTimesDisponiveis(), Config.ModoTime, function(v)
        Config.ModoTime = v
    end, posY)
    posY = posY + 70
    
    abaAim.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    --============================================================
    -- CONTEÚDO DA ABA ESP
    --============================================================
    local abaEsp = conteudoAbas["Esp"]
    posY = 10
    
    CriarCheckbox(abaEsp, "ESP Ativo", Config.ESPAtivo, function(v)
        Config.ESPAtivo = v
        if not v then
            for _, jogador in pairs(Players:GetPlayers()) do
                if ElementosESP[jogador] then
                    for _, elem in pairs(ElementosESP[jogador]) do
                        if elem then pcall(function() elem.Visible = false end) end
                    end
                end
            end
        end
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Box", Config.ESPBox, function(v)
        Config.ESPBox = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Nome", Config.ESPNome, function(v)
        Config.ESPNome = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Vida", Config.ESPVida, function(v)
        Config.ESPVida = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Distância", Config.ESPDistancia, function(v)
        Config.ESPDistancia = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaEsp, "Tracer", Config.ESPTracer, function(v)
        Config.ESPTracer = v
    end, posY)
    posY = posY + 45
    
    CriarSeparador(abaEsp, "HITBOX", posY)
    posY = posY + 30
    
    CriarCheckbox(abaEsp, "Hitbox Expander", Config.HitboxAtivo, function(v)
        Config.HitboxAtivo = v
        if not v then
            RestaurarTodasHitboxes()
        end
    end, posY)
    posY = posY + 40
    
    CriarSlider(abaEsp, "Tamanho Hitbox", 1, 5, Config.HitboxTamanho, function(v)
        Config.HitboxTamanho = v
    end, posY)
    posY = posY + 60
    
    CriarDropdown(abaEsp, "Parte Hitbox", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Config.HitboxParte, function(v)
        Config.HitboxParte = v
        RestaurarTodasHitboxes()
    end, posY)
    posY = posY + 70
    
    abaEsp.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    --============================================================
    -- CONTEÚDO DA ABA CONFIG
    --============================================================
    local abaConfig = conteudoAbas["Config"]
    posY = 10
    
    CriarSeparador(abaConfig, "DISPARO", posY)
    posY = posY + 30
    
    CriarCheckbox(abaConfig, "Disparo Automático", Config.DisparoAtivo, function(v)
        Config.DisparoAtivo = v
    end, posY)
    posY = posY + 35
    
    CriarCheckbox(abaConfig, "Apenas com Alvo", Config.DisparoApenasComAlvo, function(v)
        Config.DisparoApenasComAlvo = v
    end, posY)
    posY = posY + 40
    
    CriarSlider(abaConfig, "Delay Disparo (ms)", 50, 500, math.floor(Config.DisparoDelay * 1000), function(v)
        Config.DisparoDelay = v / 1000
    end, posY)
    posY = posY + 60
    
    CriarSeparador(abaConfig, "BALA MÁGICA", posY)
    posY = posY + 30
    
    CriarCheckbox(abaConfig, "Silent Aim (Bala Mágica)", Config.SilentAimAtivo, function(v)
        Config.SilentAimAtivo = v
        if v then
            AtivarSilentAim()
        else
            DesativarSilentAim()
        end
    end, posY)
    posY = posY + 40
    
    CriarSlider(abaConfig, "Chance de Hit (%)", 1, 100, Config.SilentAimChance, function(v)
        Config.SilentAimChance = v
    end, posY)
    posY = posY + 65
    
    CriarSeparador(abaConfig, "SISTEMA", posY)
    posY = posY + 30
    
    -- Botão destruir
    local btnDestruir = Instance.new("TextButton")
    btnDestruir.Name = "Destruir"
    btnDestruir.Size = UDim2.new(1, -10, 0, 35)
    btnDestruir.Position = UDim2.new(0, 5, 0, posY)
    btnDestruir.BackgroundColor3 = Tema.Erro
    btnDestruir.BorderSizePixel = 0
    btnDestruir.Text = "DESTRUIR SCRIPT"
    btnDestruir.TextColor3 = Tema.Texto
    btnDestruir.TextSize = 14
    btnDestruir.Font = Enum.Font.GothamBold
    btnDestruir.AutoButtonColor = false
    btnDestruir.Active = true
    btnDestruir.Parent = abaConfig
    
    local btnDestruirCorner = Instance.new("UICorner")
    btnDestruirCorner.CornerRadius = UDim.new(0, 4)
    btnDestruirCorner.Parent = btnDestruir
    
    btnDestruir.MouseButton1Click:Connect(Destruir)
    btnDestruir.TouchTap:Connect(Destruir)
    
    posY = posY + 50
    
    abaConfig.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    --============================================================
    -- EVENTOS DE MINIMIZAR/FECHAR
    --============================================================
    
    local minimizado = false
    local tamanhoOriginal = MainFrame.Size
    
    btnMin.MouseButton1Click:Connect(function()
        minimizado = not minimizado
        if minimizado then
            MainFrame.Size = UDim2.new(0, 320, 0, 35)
            contentContainer.Visible = false
            tabContainer.Visible = false
            btnMin.Text = "+"
        else
            MainFrame.Size = tamanhoOriginal
            contentContainer.Visible = true
            tabContainer.Visible = true
            btnMin.Text = "−"
        end
    end)
    
    btnMin.TouchTap:Connect(function()
        minimizado = not minimizado
        if minimizado then
            MainFrame.Size = UDim2.new(0, 320, 0, 35)
            contentContainer.Visible = false
            tabContainer.Visible = false
            btnMin.Text = "+"
        else
            MainFrame.Size = tamanhoOriginal
            contentContainer.Visible = true
            tabContainer.Visible = true
            btnMin.Text = "−"
        end
    end)
    
    btnFechar.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        Estado.UIAberta = false
    end)
    
    btnFechar.TouchTap:Connect(function()
        MainFrame.Visible = false
        Estado.UIAberta = false
    end)
end


--============================================================
-- SEÇÃO 16: LOOP PRINCIPAL
--============================================================

local function LoopPrincipal()
    -- Atualizar FOV Circle
    AtualizarFOVCircle()
    
    -- Atualizar ESP
    if Config.ESPAtivo then
        AtualizarESP()
    end
    
    -- Atualizar Hitboxes
    if Config.HitboxAtivo then
        AtualizarHitboxes()
    end
    
    -- Sistema de Aimbot
    if Config.AimbotAtivo and not Estado.InteragindoUI and not Estado.Arrastando then
        local alvo, parte = EncontrarMelhorAlvo()
        
        if alvo and parte then
            Estado.Travado = true
            Estado.AlvoAtual = alvo
            Estado.ParteAtual = parte
            
            -- Aplicar mira
            AplicarMira(parte.Position)
        else
            Estado.Travado = false
            Estado.AlvoAtual = nil
            Estado.ParteAtual = nil
        end
    else
        Estado.Travado = false
        Estado.AlvoAtual = nil
        Estado.ParteAtual = nil
    end
    
    -- Disparo automático (em thread separada)
    if Config.DisparoAtivo then
        ExecutarDisparo()
    end
end

--============================================================
-- SEÇÃO 17: INICIALIZAÇÃO
--============================================================

local function Inicializar()
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Criar UI
    CriarUI()
    
    -- Criar ESP para jogadores existentes
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            CriarESPJogador(jogador)
        end
    end
    
    -- Conectar eventos de jogadores
    table.insert(Conexoes, Players.PlayerAdded:Connect(function(jogador)
        CriarESPJogador(jogador)
    end))
    
    table.insert(Conexoes, Players.PlayerRemoving:Connect(function(jogador)
        RemoverESPJogador(jogador)
        RestaurarHitbox(jogador)
    end))
    
    -- Loop principal
    table.insert(Conexoes, RunService.RenderStepped:Connect(LoopPrincipal))
    
    -- Ativar Silent Aim se configurado
    if Config.SilentAimAtivo then
        AtivarSilentAim()
    end
    
    print("[SAVAGECHEATS_] Script carregado com sucesso! v8.0")
end

--============================================================
-- SEÇÃO 18: DESTRUIÇÃO
--============================================================

function Destruir()
    Estado.Rodando = false
    
    -- Desconectar eventos
    for _, conexao in pairs(Conexoes) do
        if conexao then
            pcall(function() conexao:Disconnect() end)
        end
    end
    Conexoes = {}
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Restaurar hitboxes
    RestaurarTodasHitboxes()
    
    -- Desativar Silent Aim
    DesativarSilentAim()
    
    -- Destruir UI
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
    
    -- Limpar variável global
    if getgenv then
        getgenv().SAVAGECHEATS_LOADED = nil
    end
    
    print("[SAVAGECHEATS_] Script destruído!")
end

--============================================================
-- SEÇÃO 19: EXECUTAR
--============================================================

Inicializar()
