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
    ║                              AIMBOT UNIVERSAL v7.0                                            ║
    ║                         100% Otimizado para Mobile                                            ║
    ║                                                                                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
    
    CORREÇÕES DA v7:
    - UI com posicionamento manual (sem UIListLayout que causava conflitos)
    - Scroll funciona sem mover câmera
    - Todos os elementos visíveis e clicáveis
    - Baseado na v4 funcional com melhorias
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

-- Configuração
local Config = {
    -- Aimbot
    AimbotAtivo = true,
    ParteAlvo = "Head",
    FOVRaio = 150,
    FOVVisivel = true,
    FOVCor = Color3.fromRGB(255, 50, 50),
    FOVCorTravado = Color3.fromRGB(50, 255, 50),
    Suavizacao = 0.5,
    SuavizacaoAtiva = true,
    DistanciaMaxima = 1000,
    IgnorarParedes = false,
    PularKnocked = true,
    
    -- Times
    ModoTime = "Inimigos",
    
    -- Disparo
    DisparoAutomatico = false,
    DelayDisparo = 0.1,
    
    -- Bala Mágica
    BalaMagica = false,
    
    -- Predição
    PredicaoAtiva = false,
    ForcaPredicao = 0.15,
    
    -- Hitbox
    HitboxAtivo = false,
    HitboxParte = "Head",
    HitboxTamanho = 10,
    
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

-- Estado
local Estado = {
    Travado = false,
    AlvoAtual = nil,
    ParteAtual = nil,
    InteragindoComUI = false,
    Arrastando = false,
    UIVisivel = true,
    AbaAtual = "Aim",
}

-- Armazenamento
local Conexoes = {}
local ElementosESP = {}
local TamanhosOriginais = {}
local FOVCircle = nil
local ScreenGui = nil

-- ZIndex base para UI
local ZIndexBase = 100

-- Cores do tema
local Cores = {
    Fundo = Color3.fromRGB(25, 25, 25),
    FundoSecundario = Color3.fromRGB(35, 35, 35),
    FundoTerciario = Color3.fromRGB(45, 45, 45),
    Destaque = Color3.fromRGB(200, 50, 50),
    DestaqueClaro = Color3.fromRGB(255, 70, 70),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Borda = Color3.fromRGB(60, 60, 60),
}


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 2: FUNÇÕES UTILITÁRIAS
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarDrawing(tipo, propriedades)
    local sucesso, objeto = pcall(function()
        local obj = Drawing.new(tipo)
        for prop, valor in pairs(propriedades) do
            obj[prop] = valor
        end
        return obj
    end)
    return sucesso and objeto or nil
end

local function GetCentroTela()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(viewport.X / 2, (viewport.Y / 2) + inset.Y)
end

local function WorldToScreen(posicao3D)
    local pos, visivel = Camera:WorldToViewportPoint(posicao3D)
    return Vector2.new(pos.X, pos.Y), visivel and pos.Z > 0
end

local function Distancia2D(p1, p2)
    return (p1 - p2).Magnitude
end

local function Distancia3D(p1, p2)
    return (p1 - p2).Magnitude
end

local function EstaVivo(personagem)
    if not personagem then return false end
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.Health > 0
end

local function EstaKnocked(personagem)
    if not personagem then return false end
    
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if humanoid:GetState() == Enum.HumanoidStateType.Physics or
           humanoid:GetState() == Enum.HumanoidStateType.FallingDown or
           humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
            return true
        end
    end
    
    -- Verificar atributos comuns
    for _, nome in pairs({"Knocked", "Downed", "DBNO", "IsKnocked", "IsDowned"}) do
        local valor = personagem:GetAttribute(nome)
        if valor == true then return true end
    end
    
    return false
end

local function GetTimesDisponiveis()
    local times = {"Inimigos", "Todos"}
    
    for _, team in pairs(game:GetService("Teams"):GetTeams()) do
        table.insert(times, team.Name)
    end
    
    return times
end

local function MesmoTime(jogador)
    if Config.ModoTime == "Todos" then
        return false
    end
    
    if Config.ModoTime == "Inimigos" then
        if LocalPlayer.Team and jogador.Team then
            return LocalPlayer.Team == jogador.Team
        end
        return false
    end
    
    -- Time específico selecionado
    if jogador.Team then
        return jogador.Team.Name == Config.ModoTime
    end
    
    return false
end

local function VerificarVisibilidade(origem, destino)
    if Config.IgnorarParedes then
        return true
    end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local direcao = (destino - origem)
    local resultado = Workspace:Raycast(origem, direcao, rayParams)
    
    if resultado then
        local hit = resultado.Instance
        local jogadorAlvo = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
        return jogadorAlvo ~= nil
    end
    
    return true
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 3: SISTEMA DE SELEÇÃO DE ALVO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function ObterParteAlvo(personagem)
    local partes = {Config.ParteAlvo, "Head", "HumanoidRootPart", "UpperTorso", "Torso"}
    
    for _, nome in ipairs(partes) do
        local parte = personagem:FindFirstChild(nome)
        if parte and parte:IsA("BasePart") then
            return parte
        end
    end
    
    return nil
end

local function EncontrarMelhorAlvo()
    local melhorAlvo = nil
    local melhorParte = nil
    local menorDistancia = Config.FOVRaio
    
    local centroTela = GetCentroTela()
    
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
                        local distancia2D = Distancia2D(centroTela, posicaoTela)
                        local distancia3D = Distancia3D(Camera.CFrame.Position, parte.Position)
                        
                        if distancia2D < menorDistancia and distancia3D <= Config.DistanciaMaxima then
                            -- Verificar visibilidade
                            if VerificarVisibilidade(Camera.CFrame.Position, parte.Position) then
                                menorDistancia = distancia2D
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

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 4: SISTEMA DE MIRA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function PreverPosicao(personagem, parte)
    if not Config.PredicaoAtiva or not parte then
        return parte.Position
    end
    
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return parte.Position
    end
    
    local velocidade = rootPart.AssemblyLinearVelocity
    local predicao = velocidade * Config.ForcaPredicao
    
    return parte.Position + predicao
end

local function MirarEm(posicaoAlvo)
    if Estado.InteragindoComUI or Estado.Arrastando then
        return
    end
    
    local novaCFrame
    
    if Config.SuavizacaoAtiva and Config.Suavizacao > 0 then
        local cframeAtual = Camera.CFrame
        local cframeAlvo = CFrame.new(cframeAtual.Position, posicaoAlvo)
        
        local fator = 1 - Config.Suavizacao
        novaCFrame = cframeAtual:Lerp(cframeAlvo, fator)
    else
        novaCFrame = CFrame.new(Camera.CFrame.Position, posicaoAlvo)
    end
    
    Camera.CFrame = novaCFrame
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 5: SISTEMA DE DISPARO INTELIGENTE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local UltimoDisparo = 0

local function TentarDisparo()
    local agora = tick()
    if agora - UltimoDisparo < Config.DelayDisparo then
        return false
    end
    
    -- Método 1: mouse1click
    pcall(function()
        mouse1click()
    end)
    
    -- Método 2: VirtualInputManager
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.01)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
    
    UltimoDisparo = agora
    return true
end

local function ExecutarDisparo()
    if not Config.DisparoAutomatico then return end
    if not Estado.Travado then return end
    if Estado.InteragindoComUI then return end
    
    task.spawn(function()
        TentarDisparo()
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 6: SISTEMA BALA MÁGICA
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local BalaMagicaHook = nil
local MetatableOriginal = nil

local function AtivarBalaMagica()
    if BalaMagicaHook then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        MetatableOriginal = mt.__namecall
        
        setreadonly(mt, false)
        
        BalaMagicaHook = function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            if Estado.Travado and Estado.ParteAtual then
                if method == "FireServer" or method == "InvokeServer" then
                    for i, arg in pairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = Estado.ParteAtual.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = Estado.ParteAtual.CFrame
                        end
                    end
                    return MetatableOriginal(self, unpack(args))
                end
            end
            
            return MetatableOriginal(self, ...)
        end
        
        mt.__namecall = newcclosure(BalaMagicaHook)
        setreadonly(mt, true)
    end)
end

local function DesativarBalaMagica()
    if not BalaMagicaHook then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = MetatableOriginal
        setreadonly(mt, true)
        BalaMagicaHook = nil
    end)
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 7: HITBOX EXPANDER
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function AtualizarHitbox()
    if not Config.HitboxAtivo then return end
    
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            local personagem = jogador.Character
            if personagem then
                local parte = personagem:FindFirstChild(Config.HitboxParte)
                if parte and parte:IsA("BasePart") then
                    -- Salvar tamanho original
                    if not TamanhosOriginais[jogador] then
                        TamanhosOriginais[jogador] = {}
                    end
                    if not TamanhosOriginais[jogador][Config.HitboxParte] then
                        TamanhosOriginais[jogador][Config.HitboxParte] = parte.Size
                    end
                    
                    -- Aplicar novo tamanho
                    local novoTamanho = Vector3.new(Config.HitboxTamanho, Config.HitboxTamanho, Config.HitboxTamanho)
                    if parte.Size ~= novoTamanho then
                        parte.Size = novoTamanho
                        parte.Transparency = 0.7
                        parte.CanCollide = false
                    end
                end
            end
        end
    end
end

local function RestaurarHitbox()
    for jogador, partes in pairs(TamanhosOriginais) do
        if jogador.Character then
            for nomeParte, tamanhoOriginal in pairs(partes) do
                local parte = jogador.Character:FindFirstChild(nomeParte)
                if parte and parte:IsA("BasePart") then
                    parte.Size = tamanhoOriginal
                    parte.Transparency = 0
                end
            end
        end
    end
    TamanhosOriginais = {}
end


--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                    SEÇÃO 8: SISTEMA FOV CIRCLE
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function CriarFOVCircle()
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
    
    elementos.Box = CriarDrawing("Square", {
        Thickness = 1,
        Filled = false,
        Transparency = 1,
        Visible = false
    })
    
    elementos.Nome = CriarDrawing("Text", {
        Size = 14,
        Center = true,
        Outline = true,
        Transparency = 1,
        Visible = false
    })
    
    elementos.Vida = CriarDrawing("Text", {
        Size = 12,
        Center = true,
        Outline = true,
        Transparency = 1,
        Visible = false
    })
    
    elementos.Distancia = CriarDrawing("Text", {
        Size = 12,
        Center = true,
        Outline = true,
        Transparency = 1,
        Visible = false
    })
    
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
    
    if not Config.ESPAtivo then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    local personagem = jogador.Character
    if not personagem or not EstaVivo(personagem) then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    local rootPart = personagem:FindFirstChild("HumanoidRootPart")
    local head = personagem:FindFirstChild("Head")
    local humanoid = personagem:FindFirstChildOfClass("Humanoid")
    
    if not rootPart or not head or not humanoid then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    local posicaoTela, visivel = WorldToScreen(rootPart.Position)
    if not visivel then
        for _, elem in pairs(elementos) do
            if elem then elem.Visible = false end
        end
        return
    end
    
    local cor = MesmoTime(jogador) and Config.ESPCorAliado or Config.ESPCorInimigo
    local distancia = Distancia3D(Camera.CFrame.Position, rootPart.Position)
    local fator = 1000 / distancia
    local largura = math.clamp(fator * 4, 20, 100)
    local altura = math.clamp(fator * 5, 30, 150)
    
    if elementos.Box and Config.ESPBox then
        elementos.Box.Size = Vector2.new(largura, altura)
        elementos.Box.Position = Vector2.new(posicaoTela.X - largura/2, posicaoTela.Y - altura/2)
        elementos.Box.Color = cor
        elementos.Box.Visible = true
    elseif elementos.Box then
        elementos.Box.Visible = false
    end
    
    if elementos.Nome and Config.ESPNome then
        elementos.Nome.Text = jogador.Name
        elementos.Nome.Position = Vector2.new(posicaoTela.X, posicaoTela.Y - altura/2 - 18)
        elementos.Nome.Color = cor
        elementos.Nome.Visible = true
    elseif elementos.Nome then
        elementos.Nome.Visible = false
    end
    
    if elementos.Vida and Config.ESPVida then
        local vida = math.floor(humanoid.Health)
        local vidaMax = math.floor(humanoid.MaxHealth)
        local porcentagem = math.floor((vida / vidaMax) * 100)
        
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
    
    if elementos.Distancia and Config.ESPDistancia then
        elementos.Distancia.Text = string.format("%.0fm", distancia)
        elementos.Distancia.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + altura/2 + 16)
        elementos.Distancia.Color = cor
        elementos.Distancia.Visible = true
    elseif elementos.Distancia then
        elementos.Distancia.Visible = false
    end
    
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
                            SEÇÃO 10: SISTEMA DE UI - POSICIONAMENTO MANUAL
    ════════════════════════════════════════════════════════════════════════════════════════════
    
    UI com posicionamento manual para evitar conflitos com UIListLayout.
    Cada elemento tem posição Y definida manualmente.
]]

local MainFrame = nil
local ContentFrames = {}

-- Função para tornar frame arrastável
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

-- Criar checkbox com posição Y manual
local function CriarCheckbox(parent, texto, posicaoY, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Checkbox_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 30)
    container.ZIndex = ZIndexBase + 1
    
    local checkbox = Instance.new("TextButton")
    checkbox.Name = "Box"
    checkbox.Parent = container
    checkbox.BackgroundColor3 = valorInicial and Cores.Destaque or Cores.FundoTerciario
    checkbox.BorderSizePixel = 0
    checkbox.Position = UDim2.new(0, 0, 0.5, -10)
    checkbox.Size = UDim2.new(0, 20, 0, 20)
    checkbox.Text = valorInicial and "✓" or ""
    checkbox.TextColor3 = Cores.Texto
    checkbox.TextSize = 14
    checkbox.Font = Enum.Font.GothamBold
    checkbox.ZIndex = ZIndexBase + 2
    checkbox.Active = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = checkbox
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 30, 0, 0)
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 1
    
    local ativo = valorInicial
    
    local function atualizar()
        checkbox.BackgroundColor3 = ativo and Cores.Destaque or Cores.FundoTerciario
        checkbox.Text = ativo and "✓" or ""
    end
    
    checkbox.MouseButton1Click:Connect(function()
        ativo = not ativo
        atualizar()
        if callback then callback(ativo) end
    end)
    
    checkbox.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    
    checkbox.MouseLeave:Connect(function()
        task.delay(0.1, function()
            if not Estado.Arrastando then
                Estado.InteragindoComUI = false
            end
        end)
    end)
    
    return container, function(novoValor)
        ativo = novoValor
        atualizar()
    end
end

-- Criar slider com posição Y manual
local function CriarSlider(parent, texto, posicaoY, min, max, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 45)
    container.ZIndex = ZIndexBase + 1
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(0.7, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 1
    
    local valorLabel = Instance.new("TextLabel")
    valorLabel.Name = "Valor"
    valorLabel.Parent = container
    valorLabel.BackgroundTransparency = 1
    valorLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valorLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valorLabel.Font = Enum.Font.GothamBold
    valorLabel.Text = "[" .. tostring(valorInicial) .. "]"
    valorLabel.TextColor3 = Cores.TextoSecundario
    valorLabel.TextSize = 14
    valorLabel.TextXAlignment = Enum.TextXAlignment.Right
    valorLabel.ZIndex = ZIndexBase + 1
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "Background"
    sliderBg.Parent = container
    sliderBg.BackgroundColor3 = Cores.FundoTerciario
    sliderBg.BorderSizePixel = 0
    sliderBg.Position = UDim2.new(0, 0, 0, 22)
    sliderBg.Size = UDim2.new(1, 0, 0, 10)
    sliderBg.ZIndex = ZIndexBase + 1
    sliderBg.Active = true
    
    local cornerBg = Instance.new("UICorner")
    cornerBg.CornerRadius = UDim.new(0, 5)
    cornerBg.Parent = sliderBg
    
    local porcentagem = (valorInicial - min) / (max - min)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Cores.Destaque
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new(porcentagem, 0, 1, 0)
    sliderFill.ZIndex = ZIndexBase + 2
    
    local cornerFill = Instance.new("UICorner")
    cornerFill.CornerRadius = UDim.new(0, 5)
    cornerFill.Parent = sliderFill
    
    local arrastando = false
    
    local function atualizarSlider(inputPos)
        local posRelativa = (inputPos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        posRelativa = math.clamp(posRelativa, 0, 1)
        
        local valor = math.floor(min + (max - min) * posRelativa)
        
        sliderFill.Size = UDim2.new(posRelativa, 0, 1, 0)
        valorLabel.Text = "[" .. tostring(valor) .. "]"
        
        if callback then callback(valor) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            Estado.InteragindoComUI = true
            Estado.Arrastando = true
            atualizarSlider(input.Position)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                          input.UserInputType == Enum.UserInputType.Touch) then
            atualizarSlider(input.Position)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            if arrastando then
                arrastando = false
                task.delay(0.1, function()
                    Estado.Arrastando = false
                    Estado.InteragindoComUI = false
                end)
            end
        end
    end)
    
    return container
end

-- Criar dropdown com posição Y manual
local function CriarDropdown(parent, texto, posicaoY, opcoes, valorInicial, callback)
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. texto
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0, 10, 0, posicaoY)
    container.Size = UDim2.new(1, -20, 0, 55)
    container.ZIndex = ZIndexBase + 10
    container.ClipsDescendants = false
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = container
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextColor3 = Cores.Texto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = ZIndexBase + 10
    
    local botao = Instance.new("TextButton")
    botao.Name = "Botao"
    botao.Parent = container
    botao.BackgroundColor3 = Cores.FundoTerciario
    botao.BorderSizePixel = 0
    botao.Position = UDim2.new(0, 0, 0, 20)
    botao.Size = UDim2.new(1, 0, 0, 28)
    botao.Font = Enum.Font.Gotham
    botao.Text = valorInicial or opcoes[1] or "Selecione"
    botao.TextColor3 = Cores.Texto
    botao.TextSize = 13
    botao.ZIndex = ZIndexBase + 11
    botao.Active = true
    
    local botaoCorner = Instance.new("UICorner")
    botaoCorner.CornerRadius = UDim.new(0, 4)
    botaoCorner.Parent = botao
    
    local seta = Instance.new("TextLabel")
    seta.Parent = botao
    seta.BackgroundTransparency = 1
    seta.Position = UDim2.new(1, -25, 0, 0)
    seta.Size = UDim2.new(0, 20, 1, 0)
    seta.Font = Enum.Font.GothamBold
    seta.Text = "▼"
    seta.TextColor3 = Cores.Destaque
    seta.TextSize = 12
    seta.ZIndex = ZIndexBase + 12
    
    local lista = Instance.new("Frame")
    lista.Name = "Lista"
    lista.Parent = container
    lista.BackgroundColor3 = Cores.Fundo
    lista.BorderSizePixel = 0
    lista.Position = UDim2.new(0, 0, 0, 50)
    lista.Size = UDim2.new(1, 0, 0, #opcoes * 26 + 4)
    lista.Visible = false
    lista.ZIndex = ZIndexBase + 50
    lista.ClipsDescendants = true
    
    local listaCorner = Instance.new("UICorner")
    listaCorner.CornerRadius = UDim.new(0, 4)
    listaCorner.Parent = lista
    
    local listaBorder = Instance.new("UIStroke")
    listaBorder.Color = Cores.Destaque
    listaBorder.Thickness = 1
    listaBorder.Parent = lista
    
    local aberto = false
    local valorAtual = valorInicial or opcoes[1]
    
    for i, opcao in ipairs(opcoes) do
        local opcaoBotao = Instance.new("TextButton")
        opcaoBotao.Parent = lista
        opcaoBotao.BackgroundColor3 = Cores.FundoSecundario
        opcaoBotao.BackgroundTransparency = 0.3
        opcaoBotao.BorderSizePixel = 0
        opcaoBotao.Position = UDim2.new(0, 2, 0, (i-1) * 26 + 2)
        opcaoBotao.Size = UDim2.new(1, -4, 0, 24)
        opcaoBotao.Font = Enum.Font.Gotham
        opcaoBotao.Text = opcao
        opcaoBotao.TextColor3 = Cores.Texto
        opcaoBotao.TextSize = 12
        opcaoBotao.ZIndex = ZIndexBase + 51
        opcaoBotao.Active = true
        
        local opcaoCorner = Instance.new("UICorner")
        opcaoCorner.CornerRadius = UDim.new(0, 3)
        opcaoCorner.Parent = opcaoBotao
        
        opcaoBotao.MouseEnter:Connect(function()
            opcaoBotao.BackgroundTransparency = 0
            opcaoBotao.BackgroundColor3 = Cores.Destaque
            Estado.InteragindoComUI = true
        end)
        
        opcaoBotao.MouseLeave:Connect(function()
            opcaoBotao.BackgroundTransparency = 0.3
            opcaoBotao.BackgroundColor3 = Cores.FundoSecundario
        end)
        
        opcaoBotao.MouseButton1Click:Connect(function()
            valorAtual = opcao
            botao.Text = opcao
            lista.Visible = false
            aberto = false
            seta.Text = "▼"
            
            if callback then
                callback(opcao)
            end
        end)
    end
    
    botao.MouseButton1Click:Connect(function()
        aberto = not aberto
        lista.Visible = aberto
        seta.Text = aberto and "▲" or "▼"
    end)
    
    botao.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    
    botao.MouseLeave:Connect(function()
        task.delay(0.1, function()
            if not Estado.Arrastando then
                Estado.InteragindoComUI = false
            end
        end)
    end)
    
    return container
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
    MainFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
    MainFrame.Size = UDim2.new(0, 350, 0, 420)
    MainFrame.Active = true
    MainFrame.ZIndex = ZIndexBase
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    
    local mainBorder = Instance.new("UIStroke")
    mainBorder.Color = Cores.Destaque
    mainBorder.Thickness = 2
    mainBorder.Parent = MainFrame
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = MainFrame
    titleBar.BackgroundColor3 = Cores.FundoSecundario
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.ZIndex = ZIndexBase + 1
    
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
    titleFix.ZIndex = ZIndexBase + 1
    
    -- Botão minimizar
    local btnMinimizar = Instance.new("TextButton")
    btnMinimizar.Parent = titleBar
    btnMinimizar.BackgroundColor3 = Cores.Destaque
    btnMinimizar.BorderSizePixel = 0
    btnMinimizar.Position = UDim2.new(0, 8, 0.5, -10)
    btnMinimizar.Size = UDim2.new(0, 20, 0, 20)
    btnMinimizar.Font = Enum.Font.GothamBold
    btnMinimizar.Text = "−"
    btnMinimizar.TextColor3 = Cores.Texto
    btnMinimizar.TextSize = 16
    btnMinimizar.ZIndex = ZIndexBase + 3
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
    titulo.ZIndex = ZIndexBase + 2
    
    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Parent = titleBar
    btnFechar.BackgroundColor3 = Cores.Destaque
    btnFechar.BorderSizePixel = 0
    btnFechar.Position = UDim2.new(1, -28, 0.5, -10)
    btnFechar.Size = UDim2.new(0, 20, 0, 20)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.Text = "×"
    btnFechar.TextColor3 = Cores.Texto
    btnFechar.TextSize = 18
    btnFechar.ZIndex = ZIndexBase + 3
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
    tabContainer.Size = UDim2.new(1, -20, 0, 32)
    tabContainer.ZIndex = ZIndexBase + 1
    
    -- Abas
    local abas = {"Esp", "Aim", "Config"}
    local botaoAbas = {}
    
    for i, nomeAba in ipairs(abas) do
        local botaoAba = Instance.new("TextButton")
        botaoAba.Name = "Tab_" .. nomeAba
        botaoAba.Parent = tabContainer
        botaoAba.BackgroundColor3 = nomeAba == Estado.AbaAtual and Cores.Destaque or Cores.FundoSecundario
        botaoAba.BorderSizePixel = 0
        botaoAba.Position = UDim2.new((i-1) / #abas, 3, 0, 0)
        botaoAba.Size = UDim2.new(1 / #abas, -6, 1, 0)
        botaoAba.Font = Enum.Font.GothamBold
        botaoAba.Text = nomeAba
        botaoAba.TextColor3 = Cores.Texto
        botaoAba.TextSize = 14
        botaoAba.ZIndex = ZIndexBase + 2
        botaoAba.Active = true
        
        local botaoCorner = Instance.new("UICorner")
        botaoCorner.CornerRadius = UDim.new(0, 6)
        botaoCorner.Parent = botaoAba
        
        botaoAbas[nomeAba] = botaoAba
        
        botaoAba.MouseButton1Click:Connect(function()
            Estado.AbaAtual = nomeAba
            
            -- Atualizar visual das abas
            for nome, btn in pairs(botaoAbas) do
                btn.BackgroundColor3 = nome == nomeAba and Cores.Destaque or Cores.FundoSecundario
            end
            
            -- Mostrar/esconder conteúdo
            for nome, frame in pairs(ContentFrames) do
                frame.Visible = nome == nomeAba
            end
        end)
        
        botaoAba.MouseEnter:Connect(function()
            Estado.InteragindoComUI = true
        end)
        
        botaoAba.MouseLeave:Connect(function()
            task.delay(0.1, function()
                if not Estado.Arrastando then
                    Estado.InteragindoComUI = false
                end
            end)
        end)
    end
    
    -- Área de conteúdo principal
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Parent = MainFrame
    contentArea.BackgroundColor3 = Cores.FundoSecundario
    contentArea.BorderSizePixel = 0
    contentArea.Position = UDim2.new(0, 10, 0, 78)
    contentArea.Size = UDim2.new(1, -20, 1, -88)
    contentArea.ZIndex = ZIndexBase + 1
    contentArea.ClipsDescendants = true
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = contentArea
    
    -- Criar frames de conteúdo para cada aba
    for _, nomeAba in ipairs(abas) do
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "Content_" .. nomeAba
        scrollFrame.Parent = contentArea
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ScrollBarImageColor3 = Cores.Destaque
        scrollFrame.Visible = nomeAba == Estado.AbaAtual
        scrollFrame.ZIndex = ZIndexBase + 2
        scrollFrame.Active = true
        scrollFrame.ScrollingEnabled = true
        scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Never
        scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        
        ContentFrames[nomeAba] = scrollFrame
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA AIM (Padrão)
    -- ═══════════════════════════════════════════════════════════════════════
    local abaAim = ContentFrames["Aim"]
    local posY = 5
    
    CriarCheckbox(abaAim, "Aimbot Ativo", posY, Config.AimbotAtivo, function(v)
        Config.AimbotAtivo = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Mostrar FOV", posY, Config.FOVVisivel, function(v)
        Config.FOVVisivel = v
    end)
    posY = posY + 35
    
    CriarSlider(abaAim, "Raio FOV", posY, 50, 500, Config.FOVRaio, function(v)
        Config.FOVRaio = v
    end)
    posY = posY + 50
    
    CriarSlider(abaAim, "Suavização", posY, 0, 100, Config.Suavizacao * 100, function(v)
        Config.Suavizacao = v / 100
    end)
    posY = posY + 50
    
    CriarCheckbox(abaAim, "Suavização Ativa", posY, Config.SuavizacaoAtiva, function(v)
        Config.SuavizacaoAtiva = v
    end)
    posY = posY + 35
    
    CriarDropdown(abaAim, "Parte Alvo", posY, {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Config.ParteAlvo, function(v)
        Config.ParteAlvo = v
    end)
    posY = posY + 65
    
    CriarCheckbox(abaAim, "Ignorar Paredes", posY, Config.IgnorarParedes, function(v)
        Config.IgnorarParedes = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaAim, "Pular Knocked", posY, Config.PularKnocked, function(v)
        Config.PularKnocked = v
    end)
    posY = posY + 35
    
    CriarSlider(abaAim, "Distância Máx", posY, 100, 2000, Config.DistanciaMaxima, function(v)
        Config.DistanciaMaxima = v
    end)
    posY = posY + 50
    
    -- Atualizar CanvasSize
    abaAim.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA ESP
    -- ═══════════════════════════════════════════════════════════════════════
    local abaESP = ContentFrames["Esp"]
    posY = 5
    
    CriarCheckbox(abaESP, "ESP Ativo", posY, Config.ESPAtivo, function(v)
        Config.ESPAtivo = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaESP, "Mostrar Box", posY, Config.ESPBox, function(v)
        Config.ESPBox = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaESP, "Mostrar Nome", posY, Config.ESPNome, function(v)
        Config.ESPNome = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaESP, "Mostrar Vida", posY, Config.ESPVida, function(v)
        Config.ESPVida = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaESP, "Mostrar Distância", posY, Config.ESPDistancia, function(v)
        Config.ESPDistancia = v
    end)
    posY = posY + 35
    
    CriarCheckbox(abaESP, "Mostrar Tracer", posY, Config.ESPTracer, function(v)
        Config.ESPTracer = v
    end)
    posY = posY + 35
    
    -- Atualizar CanvasSize
    abaESP.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- CONTEÚDO DA ABA CONFIG
    -- ═══════════════════════════════════════════════════════════════════════
    local abaConfig = ContentFrames["Config"]
    posY = 5
    
    CriarDropdown(abaConfig, "Modo Time", posY, GetTimesDisponiveis(), Config.ModoTime, function(v)
        Config.ModoTime = v
    end)
    posY = posY + 65
    
    CriarCheckbox(abaConfig, "Disparo Automático", posY, Config.DisparoAutomatico, function(v)
        Config.DisparoAutomatico = v
    end)
    posY = posY + 35
    
    CriarSlider(abaConfig, "Delay Disparo (ms)", posY, 50, 500, Config.DelayDisparo * 1000, function(v)
        Config.DelayDisparo = v / 1000
    end)
    posY = posY + 50
    
    CriarCheckbox(abaConfig, "Bala Mágica", posY, Config.BalaMagica, function(v)
        Config.BalaMagica = v
        if v then
            AtivarBalaMagica()
        else
            DesativarBalaMagica()
        end
    end)
    posY = posY + 35
    
    CriarCheckbox(abaConfig, "Predição Movimento", posY, Config.PredicaoAtiva, function(v)
        Config.PredicaoAtiva = v
    end)
    posY = posY + 35
    
    CriarSlider(abaConfig, "Força Predição", posY, 0, 50, Config.ForcaPredicao * 100, function(v)
        Config.ForcaPredicao = v / 100
    end)
    posY = posY + 50
    
    CriarCheckbox(abaConfig, "Hitbox Expander", posY, Config.HitboxAtivo, function(v)
        Config.HitboxAtivo = v
        if not v then
            RestaurarHitbox()
        end
    end)
    posY = posY + 35
    
    CriarDropdown(abaConfig, "Parte Hitbox", posY, {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Config.HitboxParte, function(v)
        RestaurarHitbox()
        Config.HitboxParte = v
    end)
    posY = posY + 65
    
    CriarSlider(abaConfig, "Tamanho Hitbox", posY, 5, 30, Config.HitboxTamanho, function(v)
        Config.HitboxTamanho = v
    end)
    posY = posY + 50
    
    -- Atualizar CanvasSize
    abaConfig.CanvasSize = UDim2.new(0, 0, 0, posY + 20)
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- EVENTOS DOS BOTÕES
    -- ═══════════════════════════════════════════════════════════════════════
    
    btnMinimizar.MouseButton1Click:Connect(function()
        Estado.UIVisivel = not Estado.UIVisivel
        contentArea.Visible = Estado.UIVisivel
        tabContainer.Visible = Estado.UIVisivel
        
        if Estado.UIVisivel then
            MainFrame.Size = UDim2.new(0, 350, 0, 420)
            btnMinimizar.Text = "−"
        else
            MainFrame.Size = UDim2.new(0, 350, 0, 35)
            btnMinimizar.Text = "+"
        end
    end)
    
    btnFechar.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = not ScreenGui.Enabled
    end)
    
    -- Eventos de interação
    btnMinimizar.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    btnMinimizar.MouseLeave:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
    
    btnFechar.MouseEnter:Connect(function()
        Estado.InteragindoComUI = true
    end)
    btnFechar.MouseLeave:Connect(function()
        task.delay(0.1, function()
            Estado.InteragindoComUI = false
        end)
    end)
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
    if Config.HitboxAtivo then
        AtualizarHitbox()
    end
    
    -- Sistema de Aimbot
    if Config.AimbotAtivo and not Estado.InteragindoComUI then
        local alvo, parte = EncontrarMelhorAlvo()
        
        if alvo and parte then
            Estado.Travado = true
            Estado.AlvoAtual = alvo
            Estado.ParteAtual = parte
            
            -- Calcular posição alvo (com predição se ativo)
            local posicaoAlvo = PreverPosicao(alvo.Character, parte)
            
            -- Mirar no alvo
            MirarEm(posicaoAlvo)
            
            -- Disparo automático
            if Config.DisparoAutomatico then
                ExecutarDisparo()
            end
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
end

--[[
    ════════════════════════════════════════════════════════════════════════════════════════════
                                SEÇÃO 13: INICIALIZAÇÃO E DESTRUIÇÃO
    ════════════════════════════════════════════════════════════════════════════════════════════
]]

local function Inicializar()
    -- Criar FOV Circle
    CriarFOVCircle()
    
    -- Criar UI
    CriarUI()
    
    -- Criar ESP para jogadores existentes
    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            CriarESPParaJogador(jogador)
        end
    end
    
    -- Conexão para novos jogadores
    table.insert(Conexoes, Players.PlayerAdded:Connect(function(jogador)
        CriarESPParaJogador(jogador)
    end))
    
    -- Conexão para jogadores saindo
    table.insert(Conexoes, Players.PlayerRemoving:Connect(function(jogador)
        RemoverESPJogador(jogador)
        TamanhosOriginais[jogador] = nil
    end))
    
    -- Loop principal
    table.insert(Conexoes, RunService.RenderStepped:Connect(LoopPrincipal))
    
    -- Atualizar times quando mudam
    table.insert(Conexoes, game:GetService("Teams").ChildAdded:Connect(function()
        -- Atualizar dropdown de times se necessário
    end))
    
    print("[SAVAGECHEATS_] Script iniciado com sucesso!")
    print("[SAVAGECHEATS_] v7.0 - UI com posicionamento manual")
end

local function Destruir()
    -- Desconectar todas as conexões
    for _, conexao in pairs(Conexoes) do
        pcall(function() conexao:Disconnect() end)
    end
    Conexoes = {}
    
    -- Destruir FOV Circle
    DestruirFOVCircle()
    
    -- Destruir ESP
    DestruirESP()
    
    -- Restaurar Hitbox
    RestaurarHitbox()
    
    -- Desativar Bala Mágica
    DesativarBalaMagica()
    
    -- Destruir UI
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
    
    -- Limpar flag
    if getgenv then
        getgenv().SAVAGECHEATS_RUNNING = false
    end
    
    print("[SAVAGECHEATS_] Script destruído!")
end

-- Expor função de destruição
if getgenv then
    getgenv().SAVAGECHEATS_DESTRUIR = Destruir
end

-- Iniciar
Inicializar()
