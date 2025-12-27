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
    ║                              AIMBOT UNIVERSAL v6.0                                            ║
    ║                         100% Otimizado para Mobile                                            ║
    ║                                                                                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
    
    CORREÇÕES DA v6:
    - UI não move câmera ao arrastar/scroll (TextButton como bloqueador)
    - Disparo automático inteligente multi-método
    - Bala mágica não trava câmera
    - Ignorar paredes só funciona quando ativado
    - Hitbox Expander funcional
    - FOV centralizado corretamente
]]

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 1: SERVIÇOS E VARIÁVEIS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Verificar se já está rodando
if getgenv and getgenv().SAVAGECHEATS_RUNNING then
    warn("[SAVAGECHEATS_] Script já está rodando!")
    return
end

if getgenv then
    getgenv().SAVAGECHEATS_RUNNING = true
end

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

-- Variáveis locais
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Função para criar Drawing (compatibilidade)
local function CriarDrawing(tipo, propriedades)
    local sucesso, objeto = pcall(function()
        local obj = Drawing.new(tipo)
        for prop, valor in pairs(propriedades or {}) do
            obj[prop] = valor
        end
        return obj
    end)
    return sucesso and objeto or nil
end

-- Tabela de Configuração
local Config = {
    -- Aimbot
    AimbotAtivo = false,
    ParteAlvo = "Head",
    FOVRaio = 150,
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(255, 50, 50),
    FOVCorTravado = Color3.fromRGB(50, 255, 50),
    Suavizacao = 0.5,
    SuavizacaoAtiva = true,
    DistanciaMaxima = 1000,
    
    -- Times
    ModoTime = "Inimigos",
    TimeEspecifico = nil,
    PularKnocked = true,
    VerificarVisibilidade = true,
    
    -- Disparo
    DisparoAutomatico = false,
    DelayDisparo = 0.1,
    MetodoDisparo = "Auto",
    
    -- Bala Mágica
    BalaMagica = false,
    
    -- Ignorar Paredes
    IgnorarParedes = false,
    
    -- Predição
    PredicaoAtiva = false,
    ForcaPredicao = 0.15,
    
    -- Hitbox Expander
    HitboxAtivo = false,
    HitboxParte = "Head",
    HitboxTamanho = 10,
    HitboxTransparencia = 0.5,
    
    -- ESP
    ESPAtivo = false,
    ESPBox = true,
    ESPNome = true,
    ESPVida = true,
    ESPDistancia = true,
    ESPTracer = false,
    ESPCorInimigo = Color3.fromRGB(255, 50, 50),
    ESPCorAliado = Color3.fromRGB(50, 255, 50),
}

-- Tabela de Estado
local Estado = {
    Travado = false,
    AlvoAtual = nil,
    ParteAtual = nil,
    InteragindoComUI = false,
    Arrastando = false,
    UltimoDisparo = 0,
    UIVisivel = true,
    AbaAtual = "Aim",
}

-- Conexões e elementos
local Conexoes = {}
local ElementosESP = {}

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 2: FUNÇÕES UTILITÁRIAS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Obter centro exato da tela (considerando GuiInset)
local function GetCentroTela()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X / 2, (viewport.Y + inset.Y) / 2)
end

-- Converter posição 3D para 2D na tela
local function WorldToScreen(posicao3D)
    local posicaoTela, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(posicaoTela.X, posicaoTela.Y), visivel and posicaoTela.Z > 0
end

-- Calcular distância 2D
local function Distancia2D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Calcular distância 3D
local function Distancia3D(p1, p2)
    return (p1 - p2).Magnitude
end

-- Verificar se personagem está vivo
local function EstaVivo(personagem)
    if not personagem then return false end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    
    -- Verificar knocked (para jogos que usam)
    if Config.PularKnocked then
        local knocked = personagem:FindFirstChild("Knocked") or 
                       personagem:FindFirstChild("Downed") or
                       personagem:FindFirstChild("DBNO")
        if knocked and (knocked.Value == true or knocked.Value == 1) then
            return false
        end
        
        -- Verificar estado do humanoid
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Dead then
            return false
        end
    end
    
    return true
end

-- Verificar se jogador é do mesmo time
local function MesmoTime(jogador)
    if not jogador or not LocalPlayer then return false end
    
    -- Verificar Team
    if jogador.Team and LocalPlayer.Team then
        return jogador.Team == LocalPlayer.Team
    end
    
    -- Verificar TeamColor
    if jogador.TeamColor and LocalPlayer.TeamColor then
        return jogador.TeamColor == LocalPlayer.TeamColor
    end
    
    -- Verificar atributos customizados
    local teamAttr = jogador:GetAttribute("Team") or jogador:GetAttribute("team")
    local myTeamAttr = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("team")
    if teamAttr and myTeamAttr then
        return teamAttr == myTeamAttr
    end
    
    return false
end

-- Verificar se jogador deve ser alvo
local function DeveSerAlvo(jogador)
    if jogador == LocalPlayer then return false end
    
    if Config.ModoTime == "Inimigos" then
        return not MesmoTime(jogador)
    elseif Config.ModoTime == "Todos" then
        return true
    elseif Config.ModoTime == "TimeEspecifico" and Config.TimeEspecifico then
        if jogador.Team then
            return jogador.Team.Name == Config.TimeEspecifico
        end
        return false
    end
    
    return true
end

-- Obter parte do corpo alvo
local function GetParteAlvo(personagem)
    if not personagem then return nil end
    
    local parte = personagem:FindFirstChild(Config.ParteAlvo)
    if parte then return parte end
    
    -- Fallbacks
    local fallbacks = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}
    for _, nome in ipairs(fallbacks) do
        parte = personagem:FindFirstChild(nome)
        if parte then return parte end
    end
    
    return nil
end

-- Verificar linha de visão (raycast)
local function TemLinhaDeVisao(origem, destino)
    -- Se ignorar paredes está ativo, sempre retorna true
    if Config.IgnorarParedes then
        return true
    end
    
    -- Se verificação de visibilidade está desativada
    if not Config.VerificarVisibilidade then
        return true
    end
    
    local direcao = destino - origem
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local resultado = Workspace:Raycast(origem, direcao, params)
    
    if resultado then
        -- Verificar se atingiu o alvo ou algo próximo
        local distanciaTotal = direcao.Magnitude
        local distanciaHit = (resultado.Position - origem).Magnitude
        
        -- Se o hit está muito próximo do destino, considera visível
        if distanciaTotal - distanciaHit < 5 then
            return true
        end
        
        -- Verificar se é parte de um personagem
        local hitPart = resultado.Instance
        if hitPart and hitPart.Parent then
            local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                return true
            end
        end
        
        return false
    end
    
    return true
end

-- Obter todos os times disponíveis
local function GetTimesDisponiveis()
    local times = {"Inimigos", "Todos"}
    
    -- Adicionar times do jogo
    for _, team in pairs(game:GetService("Teams"):GetTeams()) do
        table.insert(times, team.Name)
    end
    
    return times
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 3: SISTEMA DE SELEÇÃO DE ALVO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function EncontrarMelhorAlvo()
    local melhorAlvo = nil
    local melhorParte = nil
    local menorDistancia = math.huge
    local centro = GetCentroTela()
    
    for _, jogador in pairs(Players:GetPlayers()) do
        -- Pular se for o próprio jogador
        if jogador == LocalPlayer then continue end
        
        -- Verificar se deve ser alvo (time)
        if not DeveSerAlvo(jogador) then continue end
        
        -- Verificar personagem
        local personagem = jogador.Character
        if not personagem then continue end
        
        -- Verificar se está vivo
        if not EstaVivo(personagem) then continue end
        
        -- Obter parte alvo
        local parte = GetParteAlvo(personagem)
        if not parte then continue end
        
        -- Converter para posição na tela
        local posicaoTela, visivel = WorldToScreen(parte.Position)
        if not visivel then continue end
        
        -- Verificar distância 3D
        local distancia3D = Distancia3D(Camera.CFrame.Position, parte.Position)
        if distancia3D > Config.DistanciaMaxima then continue end
        
        -- Verificar linha de visão (respeitando Config.IgnorarParedes)
        if not TemLinhaDeVisao(Camera.CFrame.Position, parte.Position) then
            continue
        end
        
        -- Calcular distância 2D do centro da tela
        local distancia2D = Distancia2D(posicaoTela, centro)
        
        -- Verificar se está dentro do FOV
        if distancia2D <= Config.FOVRaio then
            if distancia2D < menorDistancia then
                menorDistancia = distancia2D
                melhorAlvo = jogador
                melhorParte = parte
            end
        end
    end
    
    return melhorAlvo, melhorParte
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 4: SISTEMA DE MIRA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

-- Predição de movimento
local function PreverPosicao(personagem, parte)
    if not Config.PredicaoAtiva or not parte then
        return parte.Position
    end
    
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return parte.Position
    end
    
    -- Obter velocidade do alvo
    local velocidade = rootPart.AssemblyLinearVelocity
    
    -- Aplicar predição
    local predicao = velocidade * Config.ForcaPredicao
    
    return parte.Position + predicao
end

-- Aplicar mira com suavização
local function MirarEm(posicaoAlvo)
    if not posicaoAlvo then return end
    
    -- NÃO mirar se estiver interagindo com UI
    if Estado.InteragindoComUI then return end
    if Estado.Arrastando then return end
    
    local posicaoCamera = Camera.CFrame.Position
    local cframeAlvo = CFrame.lookAt(posicaoCamera, posicaoAlvo)
    
    if Config.SuavizacaoAtiva and Config.Suavizacao > 0 then
        -- Suavização: quanto maior o valor, mais lento
        local fatorLerp = 1 - math.clamp(Config.Suavizacao, 0, 0.95)
        Camera.CFrame = Camera.CFrame:Lerp(cframeAlvo, fatorLerp)
    else
        Camera.CFrame = cframeAlvo
    end
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                            SEÇÃO 5: SISTEMA DE DISPARO INTELIGENTE
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    Sistema multi-método que detecta automaticamente a melhor forma de disparar
    em cada jogo, sem travar controles.
]]

local BotaoTiroCache = nil
local MetodoDisparoCache = nil
local DisparoEmAndamento = false

-- Detectar botão de tiro na UI do jogo
local function DetectarBotaoTiro()
    -- Usar cache se válido
    if BotaoTiroCache and BotaoTiroCache.Parent and BotaoTiroCache.Visible then
        return BotaoTiroCache
    end
    
    -- Nomes comuns de botões de tiro
    local nomesComuns = {
        "shoot", "fire", "attack", "trigger", "gun", "weapon",
        "atirar", "disparar", "tiro", "arma", "bullet", "shot"
    }
    
    -- Procurar na PlayerGui
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("GuiButton") and gui.Visible then
            local nome = gui.Name:lower()
            for _, nomeComum in pairs(nomesComuns) do
                if nome:find(nomeComum) then
                    BotaoTiroCache = gui
                    return gui
                end
            end
        end
    end
    
    return nil
end

-- Métodos de disparo disponíveis
local MetodosDisparo = {
    -- Método 1: Simular clique no botão de tiro do jogo
    BotaoUI = function()
        local botao = DetectarBotaoTiro()
        if not botao then return false end
        
        local sucesso = pcall(function()
            if firetouchinterest then
                firetouchinterest(botao, botao, 0) -- TouchBegan
                task.wait(0.02)
                firetouchinterest(botao, botao, 1) -- TouchEnded
            elseif fireclick then
                fireclick(botao)
            else
                return false
            end
        end)
        
        return sucesso
    end,
    
    -- Método 2: mouse1press/release (mais compatível)
    Mouse1Press = function()
        if not mouse1press or not mouse1release then
            return false
        end
        
        local sucesso = pcall(function()
            mouse1press()
            task.wait(0.02)
            mouse1release()
        end)
        
        return sucesso
    end,
    
    -- Método 3: mouse1click simples
    Mouse1Click = function()
        if not mouse1click then
            return false
        end
        
        local sucesso = pcall(function()
            mouse1click()
        end)
        
        return sucesso
    end,
    
    -- Método 4: VirtualInputManager (último recurso, pode causar problemas)
    VIM = function()
        local sucesso = pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            local centro = GetCentroTela()
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, true, game, 1)
            task.wait(0.02)
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, false, game, 1)
        end)
        
        return sucesso
    end
}

-- Ordem de prioridade dos métodos
local OrdemMetodos = {"BotaoUI", "Mouse1Press", "Mouse1Click", "VIM"}

-- Executar disparo com sistema inteligente
local function ExecutarDisparo()
    -- Verificações de segurança
    if not Config.DisparoAutomatico then return end
    if not Config.AimbotAtivo then return end
    if not Estado.Travado then return end
    if not Estado.AlvoAtual then return end
    if Estado.InteragindoComUI then return end
    if Estado.Arrastando then return end
    if DisparoEmAndamento then return end
    
    -- Verificar delay
    local agora = tick()
    if agora - Estado.UltimoDisparo < Config.DelayDisparo then
        return
    end
    
    Estado.UltimoDisparo = agora
    DisparoEmAndamento = true
    
    -- Executar em thread separada para não bloquear
    task.spawn(function()
        local disparou = false
        
        -- Se temos um método em cache que funcionou, usar ele
        if MetodoDisparoCache and MetodosDisparo[MetodoDisparoCache] then
            disparou = pcall(function()
                return MetodosDisparo[MetodoDisparoCache]()
            end)
        end
        
        -- Se não funcionou, tentar todos os métodos
        if not disparou then
            for _, nomeMetodo in ipairs(OrdemMetodos) do
                local sucesso, resultado = pcall(function()
                    return MetodosDisparo[nomeMetodo]()
                end)
                
                if sucesso and resultado then
                    MetodoDisparoCache = nomeMetodo
                    disparou = true
                    break
                end
            end
        end
        
        task.wait(0.03)
        DisparoEmAndamento = false
    end)
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 6: SISTEMA DE BALA MÁGICA
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    Sistema de silent aim que redireciona balas para o alvo sem mover a câmera.
    Usa hook de __index no Mouse para não interferir nos controles.
]]

local BalaMagicaAtiva = false
local HookOriginal = nil
local MetatableOriginal = nil

local function AtivarBalaMagica()
    if BalaMagicaAtiva then return end
    
    local sucesso = pcall(function()
        MetatableOriginal = getrawmetatable(game)
        if not MetatableOriginal then return end
        
        -- Salvar função original
        HookOriginal = MetatableOriginal.__index
        
        -- Desproteger metatable
        if setreadonly then
            setreadonly(MetatableOriginal, false)
        end
        
        -- Criar novo hook
        MetatableOriginal.__index = newcclosure(function(self, key)
            -- Verificar se é o Mouse e estamos buscando Hit ou Target
            if self == Mouse then
                if Estado.Travado and Estado.ParteAtual and Config.BalaMagica then
                    if key == "Hit" then
                        return CFrame.new(Estado.ParteAtual.Position)
                    elseif key == "Target" then
                        return Estado.ParteAtual
                    elseif key == "X" or key == "Y" then
                        local pos = WorldToScreen(Estado.ParteAtual.Position)
                        return key == "X" and pos.X or pos.Y
                    elseif key == "UnitRay" then
                        local origem = Camera.CFrame.Position
                        local direcao = (Estado.ParteAtual.Position - origem).Unit
                        return Ray.new(origem, direcao)
                    end
                end
            end
            
            return HookOriginal(self, key)
        end)
        
        -- Reproteger metatable
        if setreadonly then
            setreadonly(MetatableOriginal, true)
        end
    end)
    
    if sucesso then
        BalaMagicaAtiva = true
    end
end

local function DesativarBalaMagica()
    if not BalaMagicaAtiva then return end
    
    pcall(function()
        if MetatableOriginal and HookOriginal then
            if setreadonly then
                setreadonly(MetatableOriginal, false)
            end
            
            MetatableOriginal.__index = HookOriginal
            
            if setreadonly then
                setreadonly(MetatableOriginal, true)
            end
        end
    end)
    
    BalaMagicaAtiva = false
    HookOriginal = nil
    MetatableOriginal = nil
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 7: SISTEMA DE HITBOX EXPANDER
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    Aumenta o tamanho das hitboxes dos inimigos para facilitar acertos.
]]

local TamanhosOriginais = {}
local HitboxExpandido = false

local function ExpandirHitbox()
    if not Config.HitboxAtivo then return end
    
    for _, jogador in pairs(Players:GetPlayers()) do
        -- Pular próprio jogador
        if jogador == LocalPlayer then continue end
        
        -- Verificar se deve ser alvo
        if not DeveSerAlvo(jogador) then continue end
        
        local personagem = jogador.Character
        if not personagem then continue end
        
        -- Obter parte para expandir
        local parte = personagem:FindFirstChild(Config.HitboxParte)
        if not parte or not parte:IsA("BasePart") then continue end
        
        -- Salvar tamanho original (se ainda não salvou)
        if not TamanhosOriginais[jogador] then
            TamanhosOriginais[jogador] = {
                Size = parte.Size,
                Transparency = parte.Transparency,
                CanCollide = parte.CanCollide
            }
        end
        
        -- Expandir
        local tamanho = Config.HitboxTamanho
        parte.Size = Vector3.new(tamanho, tamanho, tamanho)
        parte.Transparency = Config.HitboxTransparencia
        parte.CanCollide = false
    end
    
    HitboxExpandido = true
end

local function RestaurarHitbox()
    for jogador, dados in pairs(TamanhosOriginais) do
        if jogador and jogador.Character then
            local parte = jogador.Character:FindFirstChild(Config.HitboxParte)
            if parte and parte:IsA("BasePart") then
                parte.Size = dados.Size
                parte.Transparency = dados.Transparency
                parte.CanCollide = dados.CanCollide
            end
        end
    end
    
    TamanhosOriginais = {}
    HitboxExpandido = false
end

-- Atualizar hitbox (chamado no loop)
local function AtualizarHitbox()
    if Config.HitboxAtivo then
        ExpandirHitbox()
    elseif HitboxExpandido then
        RestaurarHitbox()
    end
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 8: SISTEMA FOV CIRCLE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local FOVCircle = nil

local function CriarFOVCircle()
    -- Destruir existente
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
    end
    
    FOVCircle = CriarDrawing("Circle", {
        Radius = Config.FOVRaio,
        Thickness = 2,
        Color = Config.FOVCor,
        Filled = false,
        Transparency = 1,
        Visible = Config.FOVVisivel
    })
end

local function AtualizarFOVCircle()
    if not FOVCircle then return end
    
    local centro = GetCentroTela()
    
    FOVCircle.Position = centro
    FOVCircle.Radius = Config.FOVRaio
    FOVCircle.Visible = Config.FOVVisivel and Config.AimbotAtivo
    
    -- Mudar cor se travado
    if Estado.Travado then
        FOVCircle.Color = Config.FOVCorTravado
    else
        FOVCircle.Color = Config.FOVCor
    end
end

local function DestruirFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                        SEÇÃO 9: SISTEMA ESP
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarESPParaJogador(jogador)
    if jogador == LocalPlayer then return end
    if ElementosESP[jogador] then return end
    
    local elementos = {}
    
    -- Box
    elementos.Box = CriarDrawing("Square", {
        Thickness = 1,
        Filled = false,
        Transparency = 1,
        Visible = false
    })
    
    -- Nome
    elementos.Nome = CriarDrawing("Text", {
        Size = 14,
        Center = true,
        Outline = true,
        Transparency = 1,
        Visible = false
    })
    
    -- Vida
    elementos.Vida = CriarDrawing("Text", {
        Size = 12,
        Center = true,
        Outline = true,
        Transparency = 1,
        Visible = false
    })
    
    -- Distância
    elementos.Distancia = CriarDrawing("Text", {
        Size = 12,
        Center = true,
        Outline = true,
        Transparency = 1,
        Visible = false
    })
    
    -- Tracer
    elementos.Tracer = CriarDrawing("Line", {
        Thickness = 1,
        Transparency = 1,
        Visible = false
    })
    
    ElementosESP[jogador] = elementos
end

local function AtualizarESPJogador(jogador)
    local elementos = ElementosESP[jogador]
    if not elementos then return end
    
    -- Verificar se ESP está ativo
    if not Config.ESPAtivo then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    -- Verificar personagem
    local personagem = jogador.Character
    if not personagem then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    -- Verificar se está vivo
    if not EstaVivo(personagem) then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    -- Obter partes necessárias
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    local head = personagem:FindFirstChild("Head")
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    
    if not rootPart or not head or not humanoid then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    -- Verificar visibilidade na tela
    local posicaoTela, visivel = WorldToScreen(rootPart.Position)
    if not visivel then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    -- Determinar cor (inimigo ou aliado)
    local cor = MesmoTime(jogador) and Config.ESPCorAliado or Config.ESPCorInimigo
    
    -- Calcular tamanho do box baseado na distância
    local distancia = Distancia3D(Camera.CFrame.Position, rootPart.Position)
    local fator = 1000 / distancia
    local largura = math.clamp(fator * 4, 20, 100)
    local altura = math.clamp(fator * 5, 30, 150)
    
    -- Atualizar Box
    if elementos.Box and Config.ESPBox then
        elementos.Box.Size = Vector2.new(largura, altura)
        elementos.Box.Position = Vector2.new(posicaoTela.X - largura/2, posicaoTela.Y - altura/2)
        elementos.Box.Color = cor
        elementos.Box.Visible = true
    elseif elementos.Box then
        elementos.Box.Visible = false
    end
    
    -- Atualizar Nome
    if elementos.Nome and Config.ESPNome then
        elementos.Nome.Text = jogador.Name
        elementos.Nome.Position = Vector2.new(posicaoTela.X, posicaoTela.Y - altura/2 - 18)
        elementos.Nome.Color = cor
        elementos.Nome.Visible = true
    elseif elementos.Nome then
        elementos.Nome.Visible = false
    end
    
    -- Atualizar Vida
    if elementos.Vida and Config.ESPVida then
        local vida = math.floor(humanoid.Health)
        local vidaMax = math.floor(humanoid.MaxHealth)
        local porcentagem = math.floor((vida / vidaMax) * 100)
        
        -- Cor baseada na vida
        local corVida
        if porcentagem > 70 then
            corVida = Color3.fromRGB(0, 255, 0)
        elseif porcentagem > 30 then
            corVida = Color3.fromRGB(255, 255, 0)
        else
            corVida = Color3.fromRGB(255, 0, 0)
        end
        
        elementos.Vida.Text = string.format("%d HP (%d%%)", vida, porcentagem)
        elementos.Vida.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + altura/2 + 2)
        elementos.Vida.Color = corVida
        elementos.Vida.Visible = true
    elseif elementos.Vida then
        elementos.Vida.Visible = false
    end
    
    -- Atualizar Distância
    if elementos.Distancia and Config.ESPDistancia then
        elementos.Distancia.Text = string.format("%.0fm", distancia)
        elementos.Distancia.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + altura/2 + 16)
        elementos.Distancia.Color = cor
        elementos.Distancia.Visible = true
    elseif elementos.Distancia then
        elementos.Distancia.Visible = false
    end
    
    -- Atualizar Tracer
    if elementos.Tracer and Config.ESPTracer then
        local viewport = Camera.ViewportSize
        elementos.Tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
        elementos.Tracer.To = posicaoTela
        elementos.Tracer.Color = cor
        elementos.Tracer.Visible = true
    elseif elementos.Tracer then
        elementos.Tracer.Visible = false
    end
end

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

local function AtualizarESP()
    -- Criar ESP para novos jogadores
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            if not ElementosESP[jogador] then
                CriarESPParaJogador(jogador)
            end
            AtualizarESPJogador(jogador)
        end
    end
end

local function DestruirESP()
    for jogador, _ in pairs(ElementosESP) do
        RemoverESPJogador(jogador)
    end
    ElementosESP = {}
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                            SEÇÃO 10: SISTEMA DE UI - CORRIGIDO PARA MOBILE
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    UI customizada com bloqueio de input que não move a câmera do jogo.
    Usa TextButton transparente como camada de bloqueio.
]]

local UI = {}
local ScreenGui = nil
local MainFrame = nil
local ContentFrame = nil
local DropdownsAbertos = {}

-- Cores do tema
local Cores = {
    Fundo = Color3.fromRGB(25, 25, 25),
    FundoSecundario = Color3.fromRGB(35, 35, 35),
    Borda = Color3.fromRGB(60, 60, 60),
    Vermelho = Color3.fromRGB(200, 50, 50),
    VermelhoClaro = Color3.fromRGB(255, 70, 70),
    VermelhoEscuro = Color3.fromRGB(150, 30, 30),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Verde = Color3.fromRGB(50, 200, 50),
}

-- Função para tornar frame arrastável SEM mover câmera
local function TornarArrastavel(frame, handle)
    local arrastando = false
    local posicaoInicial
    local frameInicial
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = true
            Estado.Arrastando = true
            Estado.InteragindoComUI = true
            posicaoInicial = input.Position
            frameInicial = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    arrastando = false
                    task.delay(0.1, function()
                        Estado.Arrastando = false
                        Estado.InteragindoComUI = false
                    end)
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.Touch or 
                          input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - posicaoInicial
            frame.Position = UDim2.new(
                frameInicial.X.Scale,
                frameInicial.X.Offset + delta.X,
                frameInicial.Y.Scale,
                frameInicial.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.Touch or 
                          input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - posicaoInicial
            frame.Position = UDim2.new(
                frameInicial.X.Scale,
                frameInicial.X.Offset + delta.X,
                frameInicial.Y.Scale,
                frameInicial.Y.Offset + delta.Y
            )
        end
    end)
end

-- Criar checkbox
local function CriarCheckbox(parent, texto, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Checkbox_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -10, 0, 30)
    
    -- Bloqueador de input
    local bloqueador = Instance.new("TextButton")
    bloqueador.Parent = container
    bloqueador.BackgroundTransparency = 1
    bloqueador.Size = UDim2.new(1, 0, 1, 0)
    bloqueador.Text = ""
    bloqueador.ZIndex = 1
    bloqueador.Active = true
    bloqueador.AutoButtonColor = false
    
    bloqueador.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    bloqueador.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    -- Box do checkbox
    local box = Instance.new("Frame")
    box.Parent = container
    box.BackgroundColor3 = Cores.FundoSecundario
    box.BorderSizePixel = 0
    box.Position = UDim2.new(0, 5, 0.5, -10)
    box.Size = UDim2.new(0, 20, 0, 20)
    box.ZIndex = 2
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box
    
    local boxBorder = Instance.new("UIStroke")
    boxBorder.Color = Cores.Borda
    boxBorder.Thickness = 1
    boxBorder.Parent = box
    
    -- Check mark
    local check = Instance.new("TextLabel")
    check.Parent = box
    check.BackgroundTransparency = 1
    check.Size = UDim2.new(1, 0, 1, 0)
    check.Font = Enum.Font.GothamBold
    check.Text = "✓"
    check.TextColor3 = Cores.Vermelho
    check.TextSize = 16
    check.Visible = valorInicial
    check.ZIndex = 3
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 35, 0, 0)
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    
    -- Estado
    local ativo = valorInicial
    
    -- Botão invisível para clique
    local botao = Instance.new("TextButton")
    botao.Parent = container
    botao.BackgroundTransparency = 1
    botao.Size = UDim2.new(1, 0, 1, 0)
    botao.Text = ""
    botao.ZIndex = 4
    botao.Active = true
    botao.AutoButtonColor = false
    
    botao.MouseButton1Click:Connect(function()
        ativo = not ativo
        check.Visible = ativo
        boxBorder.Color = ativo and Cores.Vermelho or Cores.Borda
        if callback then
            callback(ativo)
        end
    end)
    
    botao.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    botao.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    return {
        SetValue = function(valor)
            ativo = valor
            check.Visible = valor
            boxBorder.Color = valor and Cores.Vermelho or Cores.Borda
        end,
        GetValue = function()
            return ativo
        end
    }
end

-- Criar slider
local function CriarSlider(parent, texto, min, max, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -10, 0, 50)
    
    -- Bloqueador de input
    local bloqueador = Instance.new("TextButton")
    bloqueador.Parent = container
    bloqueador.BackgroundTransparency = 1
    bloqueador.Size = UDim2.new(1, 0, 1, 0)
    bloqueador.Text = ""
    bloqueador.ZIndex = 1
    bloqueador.Active = true
    bloqueador.AutoButtonColor = false
    
    bloqueador.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    bloqueador.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    
    -- Valor
    local valorLabel = Instance.new("TextLabel")
    valorLabel.Parent = container
    valorLabel.BackgroundTransparency = 1
    valorLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valorLabel.Size = UDim2.new(0.4, -5, 0, 20)
    valorLabel.Font = Enum.Font.GothamBold
    valorLabel.Text = tostring(valorInicial)
    valorLabel.TextColor3 = Cores.Vermelho
    valorLabel.TextSize = 14
    valorLabel.TextXAlignment = Enum.TextXAlignment.Right
    valorLabel.ZIndex = 2
    
    -- Barra de fundo
    local barraFundo = Instance.new("Frame")
    barraFundo.Parent = container
    barraFundo.BackgroundColor3 = Cores.FundoSecundario
    barraFundo.BorderSizePixel = 0
    barraFundo.Position = UDim2.new(0, 5, 0, 28)
    barraFundo.Size = UDim2.new(1, -10, 0, 12)
    barraFundo.ZIndex = 2
    
    local barraFundoCorner = Instance.new("UICorner")
    barraFundoCorner.CornerRadius = UDim.new(0, 6)
    barraFundoCorner.Parent = barraFundo
    
    -- Barra de preenchimento
    local porcentagem = (valorInicial - min) / (max - min)
    local barraPreenchimento = Instance.new("Frame")
    barraPreenchimento.Parent = barraFundo
    barraPreenchimento.BackgroundColor3 = Cores.Vermelho
    barraPreenchimento.BorderSizePixel = 0
    barraPreenchimento.Size = UDim2.new(porcentagem, 0, 1, 0)
    barraPreenchimento.ZIndex = 3
    
    local barraPreenchimentoCorner = Instance.new("UICorner")
    barraPreenchimentoCorner.CornerRadius = UDim.new(0, 6)
    barraPreenchimentoCorner.Parent = barraPreenchimento
    
    -- Estado
    local valor = valorInicial
    local arrastando = false
    
    local function AtualizarSlider(inputPos)
        local posX = inputPos.X
        local barraPos = barraFundo.AbsolutePosition.X
        local barraSize = barraFundo.AbsoluteSize.X
        
        local porcentagem = math.clamp((posX - barraPos) / barraSize, 0, 1)
        valor = math.floor(min + (max - min) * porcentagem)
        
        barraPreenchimento.Size = UDim2.new(porcentagem, 0, 1, 0)
        valorLabel.Text = tostring(valor)
        
        if callback then
            callback(valor)
        end
    end
    
    -- Botão para interação
    local botao = Instance.new("TextButton")
    botao.Parent = barraFundo
    botao.BackgroundTransparency = 1
    botao.Size = UDim2.new(1, 0, 1, 0)
    botao.Text = ""
    botao.ZIndex = 4
    botao.Active = true
    botao.AutoButtonColor = false
    
    botao.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = true
            Estado.InteragindoComUI = true
            Estado.Arrastando = true
            AtualizarSlider(input.Position)
        end
    end)
    
    botao.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = false
            task.delay(0.1, function()
                Estado.InteragindoComUI = false
                Estado.Arrastando = false
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.Touch or 
                          input.UserInputType == Enum.UserInputType.MouseMovement) then
            AtualizarSlider(input.Position)
        end
    end)
    
    return {
        SetValue = function(novoValor)
            valor = math.clamp(novoValor, min, max)
            local porcentagem = (valor - min) / (max - min)
            barraPreenchimento.Size = UDim2.new(porcentagem, 0, 1, 0)
            valorLabel.Text = tostring(valor)
        end,
        GetValue = function()
            return valor
        end
    }
end

-- Criar dropdown
local function CriarDropdown(parent, texto, opcoes, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -10, 0, 55)
    container.ClipsDescendants = false
    container.ZIndex = 5
    
    -- Bloqueador de input
    local bloqueador = Instance.new("TextButton")
    bloqueador.Parent = container
    bloqueador.BackgroundTransparency = 1
    bloqueador.Size = UDim2.new(1, 0, 0, 55)
    bloqueador.Text = ""
    bloqueador.ZIndex = 1
    bloqueador.Active = true
    bloqueador.AutoButtonColor = false
    
    bloqueador.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    bloqueador.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    
    -- Botão principal
    local botaoPrincipal = Instance.new("TextButton")
    botaoPrincipal.Parent = container
    botaoPrincipal.BackgroundColor3 = Cores.FundoSecundario
    botaoPrincipal.BorderSizePixel = 0
    botaoPrincipal.Position = UDim2.new(0, 5, 0, 23)
    botaoPrincipal.Size = UDim2.new(1, -10, 0, 28)
    botaoPrincipal.Font = Enum.Font.Gotham
    botaoPrincipal.Text = valorInicial or opcoes[1] or "Selecione"
    botaoPrincipal.TextColor3 = Cores.Texto
    botaoPrincipal.TextSize = 13
    botaoPrincipal.ZIndex = 3
    botaoPrincipal.Active = true
    botaoPrincipal.AutoButtonColor = false
    
    local botaoCorner = Instance.new("UICorner")
    botaoCorner.CornerRadius = UDim.new(0, 4)
    botaoCorner.Parent = botaoPrincipal
    
    local botaoBorder = Instance.new("UIStroke")
    botaoBorder.Color = Cores.Borda
    botaoBorder.Thickness = 1
    botaoBorder.Parent = botaoPrincipal
    
    -- Seta
    local seta = Instance.new("TextLabel")
    seta.Parent = botaoPrincipal
    seta.BackgroundTransparency = 1
    seta.Position = UDim2.new(1, -25, 0, 0)
    seta.Size = UDim2.new(0, 20, 1, 0)
    seta.Font = Enum.Font.GothamBold
    seta.Text = "▼"
    seta.TextColor3 = Cores.Vermelho
    seta.TextSize = 12
    seta.ZIndex = 4
    
    -- Lista de opções (inicialmente invisível)
    local lista = Instance.new("Frame")
    lista.Parent = container
    lista.BackgroundColor3 = Cores.Fundo
    lista.BorderSizePixel = 0
    lista.Position = UDim2.new(0, 5, 0, 53)
    lista.Size = UDim2.new(1, -10, 0, #opcoes * 28)
    lista.Visible = false
    lista.ZIndex = 100  -- ZIndex muito alto para ficar na frente
    lista.ClipsDescendants = true
    
    local listaCorner = Instance.new("UICorner")
    listaCorner.CornerRadius = UDim.new(0, 4)
    listaCorner.Parent = lista
    
    local listaBorder = Instance.new("UIStroke")
    listaBorder.Color = Cores.Vermelho
    listaBorder.Thickness = 1
    listaBorder.Parent = lista
    
    -- Estado
    local aberto = false
    local valorAtual = valorInicial or opcoes[1]
    
    -- Criar opções
    for i, opcao in ipairs(opcoes) do
        local opcaoBotao = Instance.new("TextButton")
        opcaoBotao.Parent = lista
        opcaoBotao.BackgroundColor3 = Cores.FundoSecundario
        opcaoBotao.BackgroundTransparency = 0.5
        opcaoBotao.BorderSizePixel = 0
        opcaoBotao.Position = UDim2.new(0, 2, 0, (i-1) * 28 + 2)
        opcaoBotao.Size = UDim2.new(1, -4, 0, 26)
        opcaoBotao.Font = Enum.Font.Gotham
        opcaoBotao.Text = opcao
        opcaoBotao.TextColor3 = Cores.Texto
        opcaoBotao.TextSize = 13
        opcaoBotao.ZIndex = 101
        opcaoBotao.Active = true
        opcaoBotao.AutoButtonColor = false
        
        local opcaoCorner = Instance.new("UICorner")
        opcaoCorner.CornerRadius = UDim.new(0, 3)
        opcaoCorner.Parent = opcaoBotao
        
        opcaoBotao.MouseEnter:Connect(function()
            opcaoBotao.BackgroundTransparency = 0
            opcaoBotao.BackgroundColor3 = Cores.Vermelho
        end)
        
        opcaoBotao.MouseLeave:Connect(function()
            opcaoBotao.BackgroundTransparency = 0.5
            opcaoBotao.BackgroundColor3 = Cores.FundoSecundario
        end)
        
        opcaoBotao.MouseButton1Click:Connect(function()
            valorAtual = opcao
            botaoPrincipal.Text = opcao
            lista.Visible = false
            aberto = false
            seta.Text = "▼"
            
            if callback then
                callback(opcao)
            end
        end)
        
        opcaoBotao.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseButton1 then
                Estado.InteragindoComUI = true
            end
        end)
        
        opcaoBotao.InputEnded:Connect(function()
            task.delay(0.1, function()
                Estado.InteragindoComUI = false
            end)
        end)
    end
    
    -- Toggle dropdown
    botaoPrincipal.MouseButton1Click:Connect(function()
        aberto = not aberto
        lista.Visible = aberto
        seta.Text = aberto and "▲" or "▼"
        
        -- Fechar outros dropdowns
        if aberto then
            for _, dropdown in pairs(DropdownsAbertos) do
                if dropdown ~= lista and dropdown.Visible then
                    dropdown.Visible = false
                end
            end
        end
    end)
    
    botaoPrincipal.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    botaoPrincipal.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    table.insert(DropdownsAbertos, lista)
    
    return {
        SetValue = function(novoValor)
            valorAtual = novoValor
            botaoPrincipal.Text = novoValor
        end,
        GetValue = function()
            return valorAtual
        end,
        SetOptions = function(novasOpcoes)
            -- Limpar opções antigas
            for _, child in pairs(lista:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Atualizar tamanho
            lista.Size = UDim2.new(1, -10, 0, #novasOpcoes * 28)
            
            -- Criar novas opções
            for i, opcao in ipairs(novasOpcoes) do
                local opcaoBotao = Instance.new("TextButton")
                opcaoBotao.Parent = lista
                opcaoBotao.BackgroundColor3 = Cores.FundoSecundario
                opcaoBotao.BackgroundTransparency = 0.5
                opcaoBotao.BorderSizePixel = 0
                opcaoBotao.Position = UDim2.new(0, 2, 0, (i-1) * 28 + 2)
                opcaoBotao.Size = UDim2.new(1, -4, 0, 26)
                opcaoBotao.Font = Enum.Font.Gotham
                opcaoBotao.Text = opcao
                opcaoBotao.TextColor3 = Cores.Texto
                opcaoBotao.TextSize = 13
                opcaoBotao.ZIndex = 101
                
                local opcaoCorner = Instance.new("UICorner")
                opcaoCorner.CornerRadius = UDim.new(0, 3)
                opcaoCorner.Parent = opcaoBotao
                
                opcaoBotao.MouseButton1Click:Connect(function()
                    valorAtual = opcao
                    botaoPrincipal.Text = opcao
                    lista.Visible = false
                    aberto = false
                    seta.Text = "▼"
                    
                    if callback then
                        callback(opcao)
                    end
                end)
            end
        end
    }
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 11: CRIAÇÃO DA UI PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarUI()
    -- Destruir UI existente
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
    
    -- Criar ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGECHEATS_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    
    -- Tentar colocar no CoreGui
    local sucesso = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    
    if not sucesso then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Frame principal
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Cores.Fundo
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    MainFrame.Size = UDim2.new(0, 350, 0, 400)
    MainFrame.Active = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    
    local mainBorder = Instance.new("UIStroke")
    mainBorder.Color = Cores.Vermelho
    mainBorder.Thickness = 2
    mainBorder.Parent = MainFrame
    
    -- BLOQUEADOR DE INPUT PRINCIPAL (TextButton transparente)
    local inputBlocker = Instance.new("TextButton")
    inputBlocker.Name = "InputBlocker"
    inputBlocker.Parent = MainFrame
    inputBlocker.BackgroundTransparency = 1
    inputBlocker.Size = UDim2.new(1, 0, 1, 0)
    inputBlocker.Text = ""
    inputBlocker.ZIndex = 1
    inputBlocker.Active = true
    inputBlocker.AutoButtonColor = false
    
    inputBlocker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    inputBlocker.InputEnded:Connect(function()
        task.delay(0.1, function()
            if not Estado.Arrastando then
                Estado.InteragindoComUI = false
            end
        end)
    end)
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = MainFrame
    titleBar.BackgroundColor3 = Cores.FundoSecundario
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.ZIndex = 2
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Corrigir cantos inferiores
    local titleFix = Instance.new("Frame")
    titleFix.Parent = titleBar
    titleFix.BackgroundColor3 = Cores.FundoSecundario
    titleFix.BorderSizePixel = 0
    titleFix.Position = UDim2.new(0, 0, 1, -8)
    titleFix.Size = UDim2.new(1, 0, 0, 8)
    titleFix.ZIndex = 2
    
    -- Botão minimizar
    local btnMinimizar = Instance.new("TextButton")
    btnMinimizar.Parent = titleBar
    btnMinimizar.BackgroundColor3 = Cores.Vermelho
    btnMinimizar.BorderSizePixel = 0
    btnMinimizar.Position = UDim2.new(0, 8, 0.5, -10)
    btnMinimizar.Size = UDim2.new(0, 20, 0, 20)
    btnMinimizar.Font = Enum.Font.GothamBold
    btnMinimizar.Text = "−"
    btnMinimizar.TextColor3 = Cores.Texto
    btnMinimizar.TextSize = 16
    btnMinimizar.ZIndex = 3
    btnMinimizar.Active = true
    
    local btnMinCorner = Instance.new("UICorner")
    btnMinCorner.CornerRadius = UDim.new(0, 4)
    btnMinCorner.Parent = btnMinimizar
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Parent = titleBar
    titulo.BackgroundTransparency = 1
    titulo.Position = UDim2.new(0, 35, 0, 0)
    titulo.Size = UDim2.new(1, -70, 1, 0)
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = "SAVAGECHEATS_"
    titulo.TextColor3 = Cores.Texto
    titulo.TextSize = 16
    titulo.ZIndex = 3
    
    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Parent = titleBar
    btnFechar.BackgroundColor3 = Cores.Vermelho
    btnFechar.BorderSizePixel = 0
    btnFechar.Position = UDim2.new(1, -28, 0.5, -10)
    btnFechar.Size = UDim2.new(0, 20, 0, 20)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.Text = "×"
    btnFechar.TextColor3 = Cores.Texto
    btnFechar.TextSize = 18
    btnFechar.ZIndex = 3
    btnFechar.Active = true
    
    local btnFecharCorner = Instance.new("UICorner")
    btnFecharCorner.CornerRadius = UDim.new(0, 4)
    btnFecharCorner.Parent = btnFechar
    
    -- Tornar arrastável pela barra de título
    TornarArrastavel(MainFrame, titleBar)
    
    -- Container de abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = MainFrame
    tabContainer.BackgroundTransparency = 1
    tabContainer.Position = UDim2.new(0, 10, 0, 40)
    tabContainer.Size = UDim2.new(1, -20, 0, 35)
    tabContainer.ZIndex = 2
    
    -- Abas
    local abas = {"Esp", "Aim", "Config"}
    local botaoAbas = {}
    local conteudoAbas = {}
    
    for i, nomeAba in ipairs(abas) do
        local botaoAba = Instance.new("TextButton")
        botaoAba.Name = "Tab_" .. nomeAba
        botaoAba.Parent = tabContainer
        botaoAba.BackgroundColor3 = nomeAba == Estado.AbaAtual and Cores.Vermelho or Cores.FundoSecundario
        botaoAba.BorderSizePixel = 0
        botaoAba.Position = UDim2.new((i-1) / #abas, 3, 0, 0)
        botaoAba.Size = UDim2.new(1 / #abas, -6, 1, 0)
        botaoAba.Font = Enum.Font.GothamBold
        botaoAba.Text = nomeAba
        botaoAba.TextColor3 = Cores.Texto
        botaoAba.TextSize = 14
        botaoAba.ZIndex = 3
        botaoAba.Active = true
        
        local botaoCorner = Instance.new("UICorner")
        botaoCorner.CornerRadius = UDim.new(0, 6)
        botaoCorner.Parent = botaoAba
        
        botaoAbas[nomeAba] = botaoAba
        
        botaoAba.MouseButton1Click:Connect(function()
            Estado.AbaAtual = nomeAba
            
            -- Atualizar visual das abas
            for nome, btn in pairs(botaoAbas) do
                btn.BackgroundColor3 = nome == nomeAba and Cores.Vermelho or Cores.FundoSecundario
            end
            
            -- Mostrar/esconder conteúdo
            for nome, conteudo in pairs(conteudoAbas) do
                conteudo.Visible = nome == nomeAba
            end
        end)
        
        botaoAba.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseButton1 then
                Estado.InteragindoComUI = true
            end
        end)
        
        botaoAba.InputEnded:Connect(function()
            task.delay(0.1, function()
                Estado.InteragindoComUI = false
            end)
        end)
    end
    
    -- Área de conteúdo
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainFrame
    ContentFrame.BackgroundColor3 = Cores.FundoSecundario
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Position = UDim2.new(0, 10, 0, 80)
    ContentFrame.Size = UDim2.new(1, -20, 1, -90)
    ContentFrame.ZIndex = 2
    ContentFrame.ClipsDescendants = true
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = ContentFrame
    
    -- Criar conteúdo de cada aba
    for _, nomeAba in ipairs(abas) do
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "Content_" .. nomeAba
        scrollFrame.Parent = ContentFrame
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ScrollBarImageColor3 = Cores.Vermelho
        scrollFrame.Visible = nomeAba == Estado.AbaAtual
        scrollFrame.ZIndex = 3
        scrollFrame.Active = true
        scrollFrame.ScrollingEnabled = true
        
        -- Bloqueador de scroll
        local scrollBlocker = Instance.new("TextButton")
        scrollBlocker.Parent = scrollFrame
        scrollBlocker.BackgroundTransparency = 1
        scrollBlocker.Size = UDim2.new(1, 0, 1, 0)
        scrollBlocker.Text = ""
        scrollBlocker.ZIndex = 1
        scrollBlocker.Active = true
        scrollBlocker.AutoButtonColor = false
        
        scrollBlocker.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or
               input.UserInputType == Enum.UserInputType.MouseButton1 then
                Estado.InteragindoComUI = true
            end
        end)
        
        scrollBlocker.InputEnded:Connect(function()
            task.delay(0.1, function()
                Estado.InteragindoComUI = false
            end)
        end)
        
        local layout = Instance.new("UIListLayout")
        layout.Parent = scrollFrame
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        -- Padding
        local padding = Instance.new("UIPadding")
        padding.Parent = scrollFrame
        padding.PaddingTop = UDim.new(0, 5)
        padding.PaddingLeft = UDim.new(0, 5)
        padding.PaddingRight = UDim.new(0, 5)
        
        -- Atualizar CanvasSize automaticamente
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        conteudoAbas[nomeAba] = scrollFrame
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA ESP
    -- ═══════════════════════════════════════════════════════════════════════
    local abaESP = conteudoAbas["Esp"]
    
    CriarCheckbox(abaESP, "ESP Ativo", Config.ESPAtivo, function(valor)
        Config.ESPAtivo = valor
    end)
    
    CriarCheckbox(abaESP, "Mostrar Box", Config.ESPBox, function(valor)
        Config.ESPBox = valor
    end)
    
    CriarCheckbox(abaESP, "Mostrar Nome", Config.ESPNome, function(valor)
        Config.ESPNome = valor
    end)
    
    CriarCheckbox(abaESP, "Mostrar Vida", Config.ESPVida, function(valor)
        Config.ESPVida = valor
    end)
    
    CriarCheckbox(abaESP, "Mostrar Distância", Config.ESPDistancia, function(valor)
        Config.ESPDistancia = valor
    end)
    
    CriarCheckbox(abaESP, "Mostrar Tracer", Config.ESPTracer, function(valor)
        Config.ESPTracer = valor
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA AIM
    -- ═══════════════════════════════════════════════════════════════════════
    local abaAim = conteudoAbas["Aim"]
    
    CriarCheckbox(abaAim, "Aimbot Ativo", Config.AimbotAtivo, function(valor)
        Config.AimbotAtivo = valor
        if not valor then
            Estado.Travado = false
            Estado.AlvoAtual = nil
            Estado.ParteAtual = nil
        end
    end)
    
    CriarCheckbox(abaAim, "Mostrar FOV", Config.FOVVisivel, function(valor)
        Config.FOVVisivel = valor
    end)
    
    CriarSlider(abaAim, "Tamanho FOV", 50, 500, Config.FOVRaio, function(valor)
        Config.FOVRaio = valor
    end)
    
    CriarCheckbox(abaAim, "Suavização Ativa", Config.SuavizacaoAtiva, function(valor)
        Config.SuavizacaoAtiva = valor
    end)
    
    CriarSlider(abaAim, "Força Suavização", 0, 95, math.floor(Config.Suavizacao * 100), function(valor)
        Config.Suavizacao = valor / 100
    end)
    
    CriarDropdown(abaAim, "Parte Alvo", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Config.ParteAlvo, function(valor)
        Config.ParteAlvo = valor
    end)
    
    CriarCheckbox(abaAim, "Ignorar Paredes", Config.IgnorarParedes, function(valor)
        Config.IgnorarParedes = valor
    end)
    
    CriarCheckbox(abaAim, "Pular Knocked", Config.PularKnocked, function(valor)
        Config.PularKnocked = valor
    end)
    
    CriarSlider(abaAim, "Distância Máxima", 100, 2000, Config.DistanciaMaxima, function(valor)
        Config.DistanciaMaxima = valor
    end)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA CONFIG
    -- ═══════════════════════════════════════════════════════════════════════
    local abaConfig = conteudoAbas["Config"]
    
    CriarDropdown(abaConfig, "Modo Time", GetTimesDisponiveis(), Config.ModoTime, function(valor)
        Config.ModoTime = valor
    end)
    
    CriarCheckbox(abaConfig, "Disparo Automático", Config.DisparoAutomatico, function(valor)
        Config.DisparoAutomatico = valor
    end)
    
    CriarSlider(abaConfig, "Delay Disparo (ms)", 50, 500, math.floor(Config.DelayDisparo * 1000), function(valor)
        Config.DelayDisparo = valor / 1000
    end)
    
    CriarCheckbox(abaConfig, "Bala Mágica", Config.BalaMagica, function(valor)
        Config.BalaMagica = valor
        if valor then
            AtivarBalaMagica()
        else
            DesativarBalaMagica()
        end
    end)
    
    CriarCheckbox(abaConfig, "Predição de Movimento", Config.PredicaoAtiva, function(valor)
        Config.PredicaoAtiva = valor
    end)
    
    CriarSlider(abaConfig, "Força Predição", 5, 50, math.floor(Config.ForcaPredicao * 100), function(valor)
        Config.ForcaPredicao = valor / 100
    end)
    
    CriarCheckbox(abaConfig, "Hitbox Expander", Config.HitboxAtivo, function(valor)
        Config.HitboxAtivo = valor
        if not valor then
            RestaurarHitbox()
        end
    end)
    
    CriarDropdown(abaConfig, "Parte Hitbox", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Config.HitboxParte, function(valor)
        Config.HitboxParte = valor
        if Config.HitboxAtivo then
            RestaurarHitbox()
        end
    end)
    
    CriarSlider(abaConfig, "Tamanho Hitbox", 5, 30, Config.HitboxTamanho, function(valor)
        Config.HitboxTamanho = valor
        if Config.HitboxAtivo then
            RestaurarHitbox()
        end
    end)
    
    -- Eventos dos botões
    btnMinimizar.MouseButton1Click:Connect(function()
        Estado.UIVisivel = not Estado.UIVisivel
        ContentFrame.Visible = Estado.UIVisivel
        tabContainer.Visible = Estado.UIVisivel
        
        if Estado.UIVisivel then
            MainFrame.Size = UDim2.new(0, 350, 0, 400)
            btnMinimizar.Text = "−"
        else
            MainFrame.Size = UDim2.new(0, 350, 0, 35)
            btnMinimizar.Text = "+"
        end
    end)
    
    btnMinimizar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    btnMinimizar.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    btnFechar.MouseButton1Click:Connect(function()
        Destruir()
    end)
    
    btnFechar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            Estado.InteragindoComUI = true
        end
    end)
    
    btnFechar.InputEnded:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    return ScreenGui
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 12: LOOP PRINCIPAL
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function LoopPrincipal()
    -- Atualizar FOV Circle
    AtualizarFOVCircle()
    
    -- Atualizar ESP
    AtualizarESP()
    
    -- Atualizar Hitbox
    AtualizarHitbox()
    
    -- NÃO processar aimbot se estiver interagindo com UI
    if Estado.InteragindoComUI or Estado.Arrastando then
        return
    end
    
    -- Verificar se aimbot está ativo
    if not Config.AimbotAtivo then
        Estado.Travado = false
        Estado.AlvoAtual = nil
        Estado.ParteAtual = nil
        return
    end
    
    -- Verificar se o personagem local existe
    if not LocalPlayer.Character then
        Estado.Travado = false
        Estado.AlvoAtual = nil
        Estado.ParteAtual = nil
        return
    end
    
    -- Encontrar melhor alvo
    local alvo, parte = EncontrarMelhorAlvo()
    
    if alvo and parte then
        Estado.Travado = true
        Estado.AlvoAtual = alvo
        Estado.ParteAtual = parte
        
        -- Calcular posição alvo (com predição se ativo)
        local posicaoAlvo = PreverPosicao(alvo.Character, parte)
        
        -- Aplicar mira (se não estiver usando bala mágica pura)
        if not Config.BalaMagica then
            MirarEm(posicaoAlvo)
        end
        
        -- Executar disparo automático
        ExecutarDisparo()
    else
        Estado.Travado = false
        Estado.AlvoAtual = nil
        Estado.ParteAtual = nil
    end
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 13: INICIALIZAÇÃO E DESTRUIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Inicializar()
    -- Criar UI
    CriarUI()
    
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Criar ESP para jogadores existentes
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            CriarESPParaJogador(jogador)
        end
    end
    
    -- Conectar evento de novo jogador
    table.insert(Conexoes, Players.PlayerAdded:Connect(function(jogador)
        CriarESPParaJogador(jogador)
    end))
    
    -- Conectar evento de jogador saindo
    table.insert(Conexoes, Players.PlayerRemoving:Connect(function(jogador)
        RemoverESPJogador(jogador)
        TamanhosOriginais[jogador] = nil
    end))
    
    -- Conectar loop principal
    table.insert(Conexoes, RunService.RenderStepped:Connect(LoopPrincipal))
    
    -- Mensagem de sucesso
    print("═══════════════════════════════════════════════════")
    print("   SAVAGECHEATS_ Aimbot v6.0 carregado com sucesso!")
    print("   100% Otimizado para Mobile")
    print("═══════════════════════════════════════════════════")
end

function Destruir()
    -- Desconectar todas as conexões
    for _, conexao in pairs(Conexoes) do
        pcall(function() conexao:Disconnect() end)
    end
    Conexoes = {}
    
    -- Destruir UI
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Desativar Bala Mágica
    DesativarBalaMagica()
    
    -- Restaurar Hitbox
    RestaurarHitbox()
    
    -- Limpar flag global
    if getgenv then
        getgenv().SAVAGECHEATS_RUNNING = false
    end
    
    print("[SAVAGECHEATS_] Script descarregado!")
end

-- Iniciar
Inicializar()

-- Retornar funções para controle externo
return {
    Config = Config,
    Estado = Estado,
    Destruir = Destruir,
}
