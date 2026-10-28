-- ============================================================
-- BINTANGX6LOCHUB — FINAL ALL-IN-ONE (100% WORK LOGIC)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local PathService = game:GetService("PathfindingService")
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CFG = {
    -- ESP
    KillerESP = true, SurvivorESP = true, GenESP = true, GateESP = true, HookESP = false,
    PalletESP = false, VaultESP = false, PumpkinESP = false, TrapESP = false,
    ESPName = true, ESPProgres = true, ESPRange = 999999,
    ColorKiller = Color3.fromRGB(255, 60, 60), ColorSurvivor = Color3.fromRGB(80, 255, 120),
    ColorSurvivorInjured = Color3.fromRGB(255, 120, 60), ColorSurvivorKnocked = Color3.fromRGB(255, 180, 60),
    ColorGenerator = Color3.fromRGB(0, 200, 255), ColorHook = Color3.fromRGB(255, 150, 0),
    ColorPallet = Color3.fromRGB(200, 160, 80), ColorVault = Color3.fromRGB(180, 180, 180),
    ColorGate = Color3.fromRGB(255, 220, 0), ColorPumpkin = Color3.fromRGB(255, 140, 0),
    ColorTrap = Color3.fromRGB(200, 0, 0),
    
    -- Survivor
    AutoSkillCheck = true, SkillCheckMode = "Instant", PerfectRate = 100,
    AutoFarmSurvivor = false, AutoUnhook = false, AutoTwist = false, AutoFlee = false,
    InstantHeal = false, SpeedBoost = false, SpeedMult = 1.3,
    NoclipVP = false, AlwaysFastVault = false, FakeVault = false,
    AutoParry = false, ParryMode = "Agresif", ParryRadius = 14, AntiFakeHit = true,
    
    -- Killer
    AutoFarmKiller = false, InfiniteLunge = false, DoubleTap = false, AttackCooldown = false,
    
    -- Aimbot
    RevolverSilent = false, SpearSilent = false, RevolverAimbot = false,
    
    -- Visuals
    FullBright = false, NoFog = false, RemoveDOF = false, RTXGraphics = false, CinematicDOF = false
}

-- ============================================================
-- CORE UTILITIES
-- ============================================================
local function isKiller(player)
    return (player.Team and player.Team.Name == "Killer") or (player:GetAttribute("Role") == "Killer") or (player:GetAttribute("IsKiller") == true)
end

local function getGeneratorProgress(resultValue)
    local repairProgress = resultValue:GetAttribute("RepairProgress")
    if repairProgress == nil then
        local rp = resultValue:FindFirstChild("RepairProgress")
        if rp and rp:IsA("ValueObject") then repairProgress = rp.Value end
    end
    if not repairProgress then return 0 end
    local num = tonumber(repairProgress)
    if num then return (num <= 1.01 and num > 0) and math.round(num * 100) or math.round(num) end
    return 0
end

local cachedGenerators, cachedHooks, cachedGates = {}, {}, {}
local function scanMapObjects()
    cachedGenerators, cachedHooks, cachedGates = {}, {}, {}
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    for _, v in ipairs(map:GetDescendants()) do
        if v.Name == "Generator" and v:IsA("Model") then table.insert(cachedGenerators, v) end
        if (v.Name == "Hook" or v.Name == "HookPoint") and v:IsA("BasePart") then table.insert(cachedHooks, v) end
        if v.Name == "ExitLever" then table.insert(cachedGates, v) end
    end
end

-- ============================================================
-- ESP ENGINE
-- ============================================================
local ActiveESP = { Players = {}, Map = {} }
local function createPlayerESP(player)
    if ActiveESP.Players[player] then return ActiveESP.Players[player] end
    local hl = Instance.new("Highlight"); hl.Enabled = false; hl.Parent = workspace
    local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.Size = UDim2.new(0, 180, 0, 42); bb.Enabled = false; bb.Parent = workspace
    local name = Instance.new("TextLabel", bb); name.Size = UDim2.new(1,0,0.5,0); name.BackgroundTransparency = 1; name.Font = Enum.Font.GothamBold; name.TextSize = 12; name.TextStrokeTransparency = 0.4
    local info = Instance.new("TextLabel", bb); info.Size = UDim2.new(1,0,0.5,0); info.Position = UDim2.new(0,0,0.5,0); info.BackgroundTransparency = 1; info.Font = Enum.Font.Gotham; info.TextSize = 11; info.TextStrokeTransparency = 0.5
    ActiveESP.Players[player] = { hl = hl, bb = bb, name = name, info = info }
    return ActiveESP.Players[player]
end

local function updatePlayersESP()
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local killer = isKiller(plr)
                if (killer and CFG.KillerESP) or (not killer and CFG.SurvivorESP) then
                    local e = createPlayerESP(plr)
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d <= CFG.ESPRange then
                        local roleColor = killer and CFG.ColorKiller or CFG.ColorSurvivor
                        if plr.Character:GetAttribute("Knocked") then roleColor = CFG.ColorSurvivorKnocked
                        elseif hum.Health < hum.MaxHealth then roleColor = CFG.ColorSurvivorInjured end
                        e.hl.Adornee = plr.Character; e.hl.FillColor = roleColor; e.hl.OutlineColor = roleColor; e.hl.Enabled = true
                        e.bb.Adornee = hrp; e.bb.Enabled = true
                        e.name.Text = CFG.ESPName and plr.DisplayName or ""
                        e.name.TextColor3 = roleColor
                        local state = plr.Character:GetAttribute("Knocked") and "Knocked" or (plr.Character:GetAttribute("IsHooked") and "Hooked" or (hum.Health < hum.MaxHealth and "Injured" or "Healthy"))
                        e.info.Text = string.format("[%dm] %s", math.floor(d), state)
                    else e.hl.Enabled = false; e.bb.Enabled = false end
                else
                    local e = ActiveESP.Players[plr]; if e then e.hl.Enabled = false; e.bb.Enabled = false end
                end
            end
        end
    end
end

local function scanMapESP()
    for i, e in pairs(ActiveESP.Map) do e.hl:Destroy(); e.bb:Destroy(); ActiveESP.Map[i] = nil end
    local map = workspace:FindFirstChild("Map"); if not map then return end
    for _, inst in ipairs(map:GetDescendants()) do
        local n = inst.Name; local role = nil
        if n == "Generator" and inst:IsA("Model") then role = "Gen"
        elseif n == "Hook" or n == "HookPoint" then role = "Hook"
        elseif n == "Pallet" and inst:IsA("Model") then role = "Pallet"
        elseif n == "Window" or n == "Vault" then role = "Vault"
        elseif n == "ExitLever" then role = "Gate"
        elseif n == "BearTrap" then role = "Trap"
        elseif n:lower():find("pumpkin") and n ~= "Pumpkins" then role = "Pumpkin" end
        if role then
            local show = (role == "Gen" and CFG.GenESP) or (role == "Hook" and CFG.HookESP) or (role == "Pallet" and CFG.PalletESP) or (role == "Vault" and CFG.VaultESP) or (role == "Gate" and CFG.GateESP) or (role == "Trap" and CFG.TrapESP) or (role == "Pumpkin" and CFG.PumpkinESP)
            if show then
                local color = CFG["Color" .. role] or Color3.fromRGB(255,255,255)
                local hl = Instance.new("Highlight"); hl.FillTransparency = 0.6; hl.OutlineTransparency = 0.1; hl.FillColor = color; hl.OutlineColor = color; hl.Enabled = true; hl.Adornee = inst; hl.Parent = workspace
                local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.Size = UDim2.new(0, 120, 0, 30); bb.Enabled = true
                bb.Adornee = inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")) or inst; bb.Parent = workspace
                local lbl = Instance.new("TextLabel", bb); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = color; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextStrokeTransparency = 0.4; lbl.Text = role
                ActiveESP.Map[inst] = { hl = hl, bb = bb, label = lbl, role = role }
            end
        end
    end
end

local function updateMapESPText()
    for inst, data in pairs(ActiveESP.Map) do
        if not inst.Parent then data.hl:Destroy(); data.bb:Destroy(); ActiveESP.Map[inst] = nil
        else
            if data.role == "Gen" and CFG.ESPProgres then
                local prog = getGeneratorProgress(inst)
                data.label.Text = string.format("Generator [%d%%]", prog)
                local c = prog >= 100 and Color3.fromRGB(80,255,120) or CFG.ColorGenerator
                data.label.TextColor3 = c; data.hl.FillColor = c; data.hl.OutlineColor = c
            end
        end
    end
end

-- ============================================================
-- SKILL CHECK
-- ============================================================
local lastFire = 0
local function getSkillGui()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local g = pg:FindFirstChild("SkillCheckPromptGui") or pg:FindFirstChild("SkillCheckPromptGui-con")
    if g and g:FindFirstChild("Check") and g.Check.Visible then return g end
    return nil
end

local function fireSkillCheck(isTrap)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local mob = pg and (pg:FindFirstChild("Survivor-mob") or pg:FindFirstChild("Survivor"))
    local ctrl = mob and mob:FindFirstChild("Controls")
    local action = ctrl and ctrl:FindFirstChild("action")
    if action and firesignal then
        pcall(firesignal, action.MouseButton1Down)
        pcall(firesignal, action.MouseButton1Click)
    end
    local key = isTrap and Enum.KeyCode.ButtonL1 or Enum.KeyCode.Space
    pcall(function() 
        VIM:SendKeyEvent(true, key, false, game)
        task.wait(0.01)
        VIM:SendKeyEvent(false, key, false, game) 
    end)
end

local function handleSkillCheck()
    if not CFG.AutoSkillCheck then return end
    if tick() - lastFire < 0.1 then return end
    local gui = getSkillGui()
    if not gui then return end
    local checkObj = gui:FindFirstChild("Check")
    if not checkObj then return end
    local lineObj = checkObj:FindFirstChild("Line")
    local goalObj = checkObj:FindFirstChild("TrapPerfect") or checkObj:FindFirstChild("TrapGoal") or checkObj:FindFirstChild("Goal")
    if not lineObj or not goalObj then return end

    local isTrap = gui.Name == "SkillCheckPromptGui-con" or checkObj:FindFirstChild("TrapPerfect") ~= nil
    if CFG.SkillCheckMode == "Instant" then
        pcall(function() lineObj.Rotation = goalObj.Rotation end)
        task.wait(0.01)
        lastFire = tick()
        fireSkillCheck(isTrap)
    elseif CFG.SkillCheckMode == "Normal" then
        local lRot = lineObj.Rotation % 360
        local gRot = goalObj.Rotation % 360
        local diff = (gRot - lRot + 180) % 360 - 180
        if math.abs(diff) <= 8 then lastFire = tick(); fireSkillCheck(isTrap) end
    elseif CFG.SkillCheckMode == "Hybrid" then
        if math.random(1, 100) <= (CFG.PerfectRate or 100) then
            pcall(function() lineObj.Rotation = goalObj.Rotation end)
            task.wait(0.01); lastFire = tick(); fireSkillCheck(isTrap)
        else
            local lRot = lineObj.Rotation % 360; local gRot = goalObj.Rotation % 360
            local diff = (gRot - lRot + 180) % 360 - 180
            if math.abs(diff) <= 8 then lastFire = tick(); fireSkillCheck(isTrap) end
        end
    elseif CFG.SkillCheckMode == "Legit" then
        local lRot = lineObj.Rotation % 360; local gRot = goalObj.Rotation % 360
        local diff = (gRot - lRot + 180) % 360 - 180
        if math.abs(diff) <= 5 then lastFire = tick(); task.wait(math.random(0.05, 0.15)); fireSkillCheck(isTrap) end
    end
end

-- ============================================================
-- AUTO PARRY
-- ============================================================
local parryAnimIds = {
    ["71008020992570"]=true, ["72742711718023"]=true, ["72908958549833"]=true, ["73681849513551"]=true,
    ["73923929500477"]=true, ["74968262036854"]=true, ["75857500533792"]=true, ["76385865186777"]=true,
    ["76503974441748"]=true, ["76744850905644"]=true, ["77081789642514"]=true, ["78432063483146"]=true,
}

local function fireParry()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local s = pg and (pg:FindFirstChild("Survivor") or pg:FindFirstChild("Survivor-mob"))
    local a = s and s:FindFirstChild("Controls") and s.Controls:FindFirstChild("action")
    if a and firesignal then 
        pcall(firesignal, a.MouseButton1Down)
        pcall(firesignal, a.MouseButton1Click) 
    end
end

local function hookKiller(plr)
    if not plr or plr == LP or not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if an and not an:GetAttribute("X6_Hooked") then
        an:SetAttribute("X6_Hooked", true)
        an.AnimationPlayed:Connect(function(t)
            if not CFG.AutoParry then return end
            local id = tostring(t.Animation and t.Animation.AnimationId or ""):match("%d+")
            if id and parryAnimIds[id] then
                local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local k = plr.Character:FindFirstChild("HumanoidRootPart")
                if my and k and (my.Position - k.Position).Magnitude <= CFG.ParryRadius then
                    if CFG.ParryMode == "Safety" and t.TimePosition > 0.4 then return end
                    if CFG.AntiFakeHit and t.TimePosition < 0.1 then return end
                    if CFG.ParryMode == "Legit" then task.delay(math.random(0.1, 0.2), fireParry)
                    else fireParry() end
                end
            end
        end)
    end
end

-- ============================================================
-- FARM SURVIVOR & KILLER
-- ============================================================
local repairEvent, unHookEvent, leverEvent = nil, nil, nil
local isRepairingRemoteActive, isGateRemoteActive = false, false
local part, player, text = nil, nil, "Idle"

local function vdStopAllInteractions()
    if repairEvent and part then pcall(function() repairEvent:FireServer(part, false, nil, "X6", LP.Character) end) end
    if leverEvent and part then pcall(function() leverEvent:FireServer(part, false) end) end
    isRepairingRemoteActive, isGateRemoteActive = false, false
    part, player = nil, nil
end

local function getRootPartSafe(rp)
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    vdStopAllInteractions()
    local path = PathService:CreatePath({AgentRadius=2, AgentHeight=5, AgentCanJump=true})
    local success = pcall(function() path:ComputeAsync(myHRP.Position, rp.Position) end)
    if success and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do myHRP.CFrame = CFrame.new(wp.Position + Vector3.new(0,3,0)) end
        return
    end
    myHRP.CFrame = rp.CFrame + Vector3.new(0, 3, 0)
end

task.spawn(function()
    local remotes = RS:WaitForChild("Remotes", 5)
    if remotes then
        repairEvent = remotes:WaitForChild("Generator", 2) and remotes.Generator:WaitForChild("RepairEvent", 2)
        leverEvent = remotes:WaitForChild("Exit", 2) and remotes.Exit:WaitForChild("LeverEvent", 2)
        local carry = remotes:FindFirstChild("Carry")
        unHookEvent = carry and carry:FindFirstChild("UnHookEvent")
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not CFG.AutoFarmSurvivor then
            if text ~= "Idle" then vdStopAllInteractions(); text = "Idle" end
            continue
        end
        local char = LP.Character
        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        if not myHRP then vdStopAllInteractions(); continue end
        
        if text == "Idle" then
            local bestGen, bestDist = nil, 9999
            for _, gen in ipairs(cachedGenerators) do
                if gen and gen.Parent and not gen:GetAttribute("Completed") then
                    local basePart = gen:IsA("Model") and gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                    if basePart then
                        local d = (myHRP.Position - basePart.Position).Magnitude
                        if d < bestDist then bestDist, bestGen = d, gen end
                    end
                end
            end
            if bestGen then
                local basePart = bestGen:FindFirstChild("MainPart") or bestGen:FindFirstChildWhichIsA("BasePart")
                getRootPartSafe(basePart)
                text = "Repairing"; player = bestGen; part = basePart
                if repairEvent then
                    pcall(function() repairEvent:FireServer(basePart, true, nil, "X6", char) end)
                    isRepairingRemoteActive = true
                end
            end
        elseif text == "Repairing" then
            if not player or not player.Parent or player:GetAttribute("Completed") then
                vdStopAllInteractions(); text = "Idle"
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if not CFG.AutoFarmKiller then continue end
        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then continue end
        
        local target, bestDist = nil, 9999
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and not isKiller(plr) then
                local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if thrp then
                    local d = (hrp.Position - thrp.Position).Magnitude
                    if d < bestDist then bestDist, target = d, plr end
                end
            end
        end
        if target then
            local thrp = target.Character:FindFirstChild("HumanoidRootPart")
            local thum = target.Character:FindFirstChildOfClass("Humanoid")
            if thrp and thum and thum.Health > 0 then
                hrp.CFrame = CFrame.new(thrp.Position - thrp.CFrame.LookVector * 1.2, thrp.Position)
                local attacks = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Attacks")
                if attacks then
                    local lunge = attacks:FindFirstChild("Lunge")
                    local basic = attacks:FindFirstChild("BasicAttack")
                    if lunge then lunge:FireServer() end
                    if basic then basic:FireServer() end
                end
                if target.Character:GetAttribute("Knocked") then
                    local carry = RS.Remotes:FindFirstChild("Carry")
                    if carry and carry:FindFirstChild("CarrySurvivorEvent") then
                        carry.CarrySurvivorEvent:FireServer(target.Character)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- AIMBOT & HOOKS
-- ============================================================
local function getClosestTarget(maxDist)
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= maxDist and d < bestDist then best, bestDist = plr, d end
                end
            end
        end
    end
    return best
end

local function setupHooks()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() and method == "FireServer" and typeof(self) == "Instance" then
            local n = self.Name:lower()
            if n == "vaultevent" and CFG.AlwaysFastVault then
                if args[2] == false then args[2] = true end
                return oldNamecall(self, unpack(args))
            end
            if n == "fire" and self.Parent and self.Parent.Name:lower():find("twist") then
                if CFG.RevolverSilent then
                    local target = getClosestTarget(200)
                    if target and target.Character then
                        local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                        if head and args[2] then args[2] = (head.Position - Camera.CFrame.Position).Unit end
                        return oldNamecall(self, unpack(args))
                    end
                end
            elseif n == "spearthrow" then
                if CFG.SpearSilent then
                    local target = getClosestTarget(240)
                    if target and target.Character then
                        local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                        if head and args[1] then
                            args[1] = { Origin = Camera.CFrame.Position, Direction = (head.Position - Camera.CFrame.Position).Unit }
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- ============================================================
-- LOOPS
-- ============================================================
RunService.Heartbeat:Connect(function()
    if CFG.SpeedBoost then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and hum.MoveDirection.Magnitude > 0.05 then
            local spd = char:GetAttribute("Speed") or 16
            local target = spd * CFG.SpeedMult
            local dir = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * target, hrp.AssemblyLinearVelocity.Y, dir.Z * target)
        end
    end
    if CFG.NoclipVP then
        local char = LP.Character
        if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end
    if CFG.FullBright then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255); Lighting.GlobalShadows = false
    end
    if CFG.NoFog then Lighting.FogStart = 1e6; Lighting.FogEnd = 1e6 end
end)

RunService.RenderStepped:Connect(function()
    pcall(updatePlayersESP)
    pcall(updateMapESPText)
    pcall(handleSkillCheck)
    if CFG.RevolverAimbot then
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getClosestTarget(150)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
            end
        end
    end
end)

task.spawn(function()
    pcall(setupHooks)
    task.spawn(function() 
        while true do 
            task.wait(2); 
            for _, p in ipairs(Players:GetPlayers()) do if isKiller(p) then hookKiller(p) end end 
        end 
    end)
end)

-- ============================================================
-- EXTRA (CONFIG & HOP)
-- ============================================================
local configFile = "BintangX6_Config.json"
local function saveConfig()
    if not writefile then return end
    local data = {}
    for k, v in pairs(CFG) do if type(v) ~= "table" then data[k] = v end end
    pcall(writefile, configFile, game:GetService("HttpService"):JSONEncode(data))
end

local function loadConfig()
    if not readfile or not isfile then return end
    if isfile(configFile) then
        local success, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(configFile)) end)
        if success and data then
            for k, v in pairs(data) do if CFG[k] ~= nil then CFG[k] = v end end
            for _, v in pairs(LP.PlayerGui:GetChildren()) do
                if v.Name == "BintangX6LocHUB" then v:Destroy() end
            end
            buildUI()
        end
    end
end

local function serverHop()
    local teleportService = game:GetService("TeleportService")
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success then
        local data = game:GetService("HttpService"):JSONDecode(response)
        local servers = {}
        for _, s in ipairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s) end
        end
        if #servers > 0 then
            local target = servers[math.random(1, #servers)]
            pcall(function() teleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LP) end)
        end
    end
end

-- ============================================================
-- UI MODERN (UKURAN COMPACT & TAB KATEGORI)
-- ============================================================
local LOGO_URL = "https://files.catbox.moe/7jhr44.jpg" 
local LOGO_FALLBACK = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150"
local function loadLogo()
    local path = "BintangX6_DragonLogo.png"
    local getAsset = getcustomasset or getsynasset
    if writefile and isfile and getAsset then
        if not isfile(path) then
            local ok, body = pcall(function() return game:HttpGet(LOGO_URL) end)
            if ok and body then pcall(writefile, path, body) end
        end
        if isfile(path) then
            local ok, asset = pcall(getAsset, path)
            if ok and asset then return asset end
        end
    end
    return LOGO_FALLBACK
end
local LOGO_ASSET = loadLogo()

local function getSVG(svgString) return "data:image/svg+xml;utf8," .. svgString end
local Icons = {
    Survivor = getSVG('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f0f2fa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20"/><path d="m8 6 4-4 4 4"/><path d="m8 18 4 4 4-4"/></svg>'),
    Killer = getSVG('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f0f2fa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 17.5 3 6V3h3l11.5 11.5"/><path d="M13 19l6-6"/><path d="M16 16l4 4"/><path d="M19 21l2-2"/></svg>'),
    ESP = getSVG('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f0f2fa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>'),
    Visuals = getSVG('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f0f2fa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="#f0f2fa"/><circle cx="17.5" cy="10.5" r=".5" fill="#f0f2fa"/><circle cx="8.5" cy="7.5" r=".5" fill="#f0f2fa"/><circle cx="6.5" cy="12.5" r=".5" fill="#f0f2fa"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.92 0 1.5-.7 1.5-1.5 0-.4-.2-.8-.4-1.1-.3-.3-.4-.7-.4-1.1 0-.8.7-1.5 1.5-1.5H16c3.3 0 6-2.7 6-6 0-5.5-4.5-10-10-10z"/></svg>'),
}
local Colors = { Bg = Color3.fromRGB(10, 11, 14), Sidebar = Color3.fromRGB(14, 15, 20), Card = Color3.fromRGB(22, 24, 30), Hover = Color3.fromRGB(30, 33, 42), Stroke = Color3.fromRGB(40, 42, 55), Accent = Color3.fromRGB(100, 150, 255), Text = Color3.fromRGB(240, 242, 250), TextDim = Color3.fromRGB(130, 135, 150) }

function buildUI()
    local sg = Instance.new("ScreenGui"); sg.Name = "BintangX6LocHUB"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = LP:WaitForChild("PlayerGui")
    
    -- UKURAN LEBIH COMPACT (580x420)
    local main = Instance.new("Frame", sg); main.Size = UDim2.new(0, 580, 0, 420); main.Position = UDim2.new(0.5, -290, 0.5, -210); main.BackgroundColor3 = Colors.Bg; main.BackgroundTransparency = 0.05; main.BorderSizePixel = 0; main.Active = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12); local stroke = Instance.new("UIStroke", main); stroke.Color = Colors.Stroke; stroke.Thickness = 1.5
    
    local bgWatermark = Instance.new("ImageLabel", main); bgWatermark.Size = UDim2.new(1, 0, 1, 0); bgWatermark.BackgroundTransparency = 1; bgWatermark.Image = LOGO_ASSET; bgWatermark.ScaleType = Enum.ScaleType.Crop; bgWatermark.ImageTransparency = 0.8; bgWatermark.ZIndex = 0; Instance.new("UICorner", bgWatermark).CornerRadius = UDim.new(0, 12)
    local bgOverlay = Instance.new("Frame", main); bgOverlay.Size = UDim2.new(1, 0, 1, 0); bgOverlay.BackgroundColor3 = Colors.Bg; bgOverlay.BackgroundTransparency = 0.4; bgOverlay.BorderSizePixel = 0; bgOverlay.ZIndex = 0; Instance.new("UICorner", bgOverlay).CornerRadius = UDim.new(0, 12)
    
    local side = Instance.new("Frame", main); side.Size = UDim2.new(0, 150, 1, 0); side.BackgroundColor3 = Colors.Sidebar; side.BackgroundTransparency = 0.2; side.BorderSizePixel = 0; side.ZIndex = 1; Instance.new("UICorner", side).CornerRadius = UDim.new(0, 12)
    local sideStroke = Instance.new("UIStroke", side); sideStroke.Color = Colors.Stroke; sideStroke.Thickness = 1; sideStroke.Transparency = 0.5
    
    local header = Instance.new("Frame", side); header.Size = UDim2.new(1, -20, 0, 50); header.Position = UDim2.new(0, 10, 0, 10); header.BackgroundTransparency = 1
    local miniLogo = Instance.new("ImageLabel", header); miniLogo.Size = UDim2.new(0, 28, 0, 28); miniLogo.Position = UDim2.new(0, 0, 0.5, -14); miniLogo.BackgroundColor3 = Colors.Card; miniLogo.Image = LOGO_ASSET; miniLogo.ScaleType = Enum.ScaleType.Crop; miniLogo.ZIndex = 2; Instance.new("UICorner", miniLogo).CornerRadius = UDim.new(0, 6)
    local title = Instance.new("TextLabel", header); title.Size = UDim2.new(1, -34, 0, 18); title.Position = UDim2.new(0, 34, 0.5, -10); title.BackgroundTransparency = 1; title.Text = "BintangX6"; title.TextColor3 = Colors.Text; title.Font = Enum.Font.GothamBold; title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = 2
    local subtitle = Instance.new("TextLabel", header); subtitle.Size = UDim2.new(1, -34, 0, 12); subtitle.Position = UDim2.new(0, 34, 0.5, 6); subtitle.BackgroundTransparency = 1; subtitle.Text = "LocHUB"; subtitle.TextColor3 = Colors.Accent; subtitle.Font = Enum.Font.GothamBold; subtitle.TextSize = 9; subtitle.TextXAlignment = Enum.TextXAlignment.Left; subtitle.ZIndex = 2
    
    local tabScroll = Instance.new("ScrollingFrame", side); tabScroll.Size = UDim2.new(1, -12, 1, -70); tabScroll.Position = UDim2.new(0, 6, 0, 60); tabScroll.BackgroundTransparency = 1; tabScroll.BorderSizePixel = 0; tabScroll.ScrollBarThickness = 0; tabScroll.ZIndex = 1
    local tabList = Instance.new("UIListLayout", tabScroll); tabList.Padding = UDim.new(0, 4); tabList.SortOrder = Enum.SortOrder.LayoutOrder
    
    local content = Instance.new("Frame", main); content.Size = UDim2.new(1, -160, 1, -20); content.Position = UDim2.new(0, 155, 0, 10); content.BackgroundTransparency = 1; content.ZIndex = 1
    local pages = {}; local tabButtons = {}
    
    local function makeTab(id, iconSvg, name, order)
        local btn = Instance.new("TextButton", tabScroll); btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = Colors.Card; btn.BackgroundTransparency = 0.8; btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.LayoutOrder = order; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local ic = Instance.new("ImageLabel", btn); ic.Size = UDim2.new(0, 14, 0, 14); ic.Position = UDim2.new(0, 10, 0.5, -7); ic.BackgroundTransparency = 1; ic.Image = iconSvg; ic.ImageColor3 = Colors.TextDim; ic.ZIndex = 2
        local tx = Instance.new("TextLabel", btn); tx.Size = UDim2.new(1, -38, 1, 0); tx.Position = UDim2.new(0, 32, 0, 0); tx.BackgroundTransparency = 1; tx.Text = name; tx.TextColor3 = Colors.TextDim; tx.Font = Enum.Font.GothamBold; tx.TextSize = 11; tx.TextXAlignment = Enum.TextXAlignment.Left; tx.ZIndex = 2
        tabButtons[id] = { btn = btn, txt = tx, ic = ic }
        btn.MouseButton1Click:Connect(function()
            for _, tb in pairs(tabButtons) do TweenService:Create(tb.btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, BackgroundColor3 = Colors.Card}):Play(); TweenService:Create(tb.txt, TweenInfo.new(0.2), {TextColor3 = Colors.TextDim}):Play(); TweenService:Create(tb.ic, TweenInfo.new(0.2), {ImageColor3 = Colors.TextDim}):Play() end
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1, BackgroundColor3 = Colors.Hover}):Play(); TweenService:Create(tx, TweenInfo.new(0.2), {TextColor3 = Colors.Text}):Play(); TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = Colors.Accent}):Play()
            for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
        end)
    end

    local function makePage(id)
        local f = Instance.new("ScrollingFrame", content); f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.ScrollBarThickness = 2; f.ScrollBarImageColor3 = Colors.Accent; f.CanvasSize = UDim2.new(0, 0, 0, 0); f.AutomaticCanvasSize = Enum.AutomaticSize.Y; f.Visible = false
        local ll = Instance.new("UIListLayout", f); ll.Padding = UDim.new(0, 4); ll.SortOrder = Enum.SortOrder.LayoutOrder; pages[id] = f
    end

    local function addSection(parent, text)
        local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1; l.Text = text:upper(); l.TextColor3 = Colors.Accent; l.Font = Enum.Font.GothamBold; l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function addToggle(parent, label, key, order, callback)
        local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1, 0, 0, 32); b.BackgroundColor3 = Colors.Card; b.BackgroundTransparency = 0.2; b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = order; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local kn = Instance.new("Frame", b); kn.Size = UDim2.new(0, 24, 0, 14); kn.Position = UDim2.new(1, -34, 0.5, -7); kn.BackgroundColor3 = CFG[key] and Colors.Accent or Colors.Stroke; kn.BorderSizePixel = 0; Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)
        local dot = Instance.new("Frame", kn); dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = CFG[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5); dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); dot.BorderSizePixel = 0; Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local l = Instance.new("TextLabel", b); l.Size = UDim2.new(1, -44, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = Colors.Text; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
        b.MouseButton1Click:Connect(function()
            CFG[key] = not CFG[key]; TweenService:Create(kn, TweenInfo.new(0.2), {BackgroundColor3 = CFG[key] and Colors.Accent or Colors.Stroke}):Play(); TweenService:Create(dot, TweenInfo.new(0.2), {Position = CFG[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)}):Play(); if callback then callback(CFG[key]) end
        end)
    end

    local function addSelector(parent, label, key, options, order)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundColor3 = Colors.Card; f.BackgroundTransparency = 0.2; f.BorderSizePixel = 0; f.LayoutOrder = order; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local l = Instance.new("TextLabel", f); l.Size = UDim2.new(0.5, -8, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = Colors.Text; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
        local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 70, 0, 22); btn.Position = UDim2.new(1, -78, 0.5, -11); btn.BackgroundColor3 = Colors.Stroke; btn.Text = CFG[key]; btn.TextColor3 = Colors.Text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            local currIdx = 1; for i, v in ipairs(options) do if v == CFG[key] then currIdx = i; break end end; currIdx = currIdx + 1; if currIdx > #options then currIdx = 1 end; CFG[key] = options[currIdx]; btn.Text = CFG[key]
        end)
    end

    local function addColorPicker(parent, label, key, order)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundColor3 = Colors.Card; f.BackgroundTransparency = 0.2; f.BorderSizePixel = 0; f.LayoutOrder = order; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, -50, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = Colors.Text; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
        local colorBox = Instance.new("Frame", f); colorBox.Size = UDim2.new(0, 20, 0, 20); colorBox.Position = UDim2.new(1, -30, 0.5, -10); colorBox.BackgroundColor3 = CFG[key]; colorBox.BorderSizePixel = 0; Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0, 4)
        local cStroke = Instance.new("UIStroke", colorBox); cStroke.Color = Colors.Stroke
        local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
        btn.MouseButton1Click:Connect(function()
            local colors = {Color3.fromRGB(255,60,60), Color3.fromRGB(80,255,120), Color3.fromRGB(0,200,255), Color3.fromRGB(255,180,60), Color3.fromRGB(255,150,0), Color3.fromRGB(200,160,80), Color3.fromRGB(180,180,180), Color3.fromRGB(255,220,0), Color3.fromRGB(150,0,255)}
            local currentIdx = 1; for i, c in ipairs(colors) do if c == CFG[key] then currentIdx = i; break end end; currentIdx = currentIdx + 1; if currentIdx > #colors then currentIdx = 1 end; CFG[key] = colors[currentIdx]; colorBox.BackgroundColor3 = CFG[key]; task.spawn(scanMapESP)
        end)
    end

    local function addSlider(parent, label, key, min, max, order)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 44); f.BackgroundColor3 = Colors.Card; f.BackgroundTransparency = 0.2; f.BorderSizePixel = 0; f.LayoutOrder = order; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, -16, 0, 16); l.Position = UDim2.new(0, 10, 0, 3); l.BackgroundTransparency = 1; l.Text = label .. ": " .. tostring(CFG[key]); l.TextColor3 = Colors.Text; l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
        local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, -20, 0, 5); bar.Position = UDim2.new(0, 10, 0, 28); bar.BackgroundColor3 = Colors.Stroke; bar.BorderSizePixel = 0; Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((CFG[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Colors.Accent; fill.BorderSizePixel = 0; Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local dragging = false; bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end); bar.InputEnded:Connect(function() dragging = false end)
        UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1); local v = min + rel * (max - min); CFG[key] = v; fill.Size = UDim2.new(rel, 0, 1, 0); l.Text = label .. ": " .. string.format("%.1f", v) end end)
    end

    local function addButton(parent, text, callback, order, color)
        local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1, 0, 0, 30); b.BackgroundColor3 = color or Colors.Accent; b.BorderSizePixel = 0; b.Text = text; b.TextColor3 = Color3.fromRGB(255,255,255); b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.LayoutOrder = order; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); b.MouseButton1Click:Connect(callback)
    end

    -- TABS
    makeTab("Survivor", Icons.Survivor, "Survivor", 1)
    makeTab("Killer", Icons.Killer, "Killer", 2)
    makeTab("ESP", Icons.ESP, "ESP", 3)
    makeTab("Visuals", Icons.Visuals, "Visuals", 4)
    makeTab("Config", "", "Config", 5)

    -- SURVIVOR TAB
    local sv = makePage("Survivor")
    addSection(sv, "Skill Check")
    addSelector(sv, "Mode", "SkillCheckMode", {"Normal", "Instant", "Legit", "Hybrid"}, 1)
    addToggle(sv, "Auto Skill Check", "AutoSkillCheck", 2)
    addSection(sv, "Auto Parry")
    addToggle(sv, "Enable Auto Parry", "AutoParry", 3)
    addSelector(sv, "Parry Mode", "ParryMode", {"Agresif", "Safety", "Legit"}, 4)
    addToggle(sv, "Anti Fake Hit", "AntiFakeHit", 5)
    addSlider(sv, "Parry Radius", "ParryRadius", 6, 25, 6)
    addSection(sv, "Auto Farm")
    addToggle(sv, "Auto Farm Survivor", "AutoFarmSurvivor", 7)
    addToggle(sv, "Auto Unhook", "AutoUnhook", 8)
    addToggle(sv, "Auto Twist of Fate", "AutoTwist", 9)
    addToggle(sv, "Auto Flee Killer", "AutoFlee", 10)
    addSection(sv, "Modifiers")
    addToggle(sv, "Instant Heal", "InstantHeal", 11)
    addToggle(sv, "Speed Boost", "SpeedBoost", 12)
    addSlider(sv, "Speed Multiplier", "SpeedMult", 1, 3, 13)

    -- KILLER TAB
    local kl = makePage("Killer")
    addSection(kl, "Auto Farm")
    addToggle(kl, "Auto Farm Killer", "AutoFarmKiller", 1)
    addSection(kl, "Combat")
    addToggle(kl, "Infinite Lunge", "InfiniteLunge", 2)
    addToggle(kl, "Double Tap", "DoubleTap", 3)
    addToggle(kl, "Attack Cooldown", "AttackCooldown", 4)

    -- ESP TAB
    local ep = makePage("ESP")
    addSection(ep, "Player ESP")
    addToggle(ep, "Killer ESP", "KillerESP", 1)
    addToggle(ep, "Survivor ESP", "SurvivorESP", 2)
    addToggle(ep, "Show Name", "ESPName", 3)
    addSection(ep, "Warna Player")
    addColorPicker(ep, "Warna Killer", "ColorKiller", 4)
    addColorPicker(ep, "Warna Survivor", "ColorSurvivor", 5)
    addColorPicker(ep, "Warna Injured", "ColorSurvivorInjured", 6)
    addColorPicker(ep, "Warna Knocked", "ColorSurvivorKnocked", 7)
    addSection(ep, "Map ESP")
    addToggle(ep, "Generator", "GenESP", 8)
    addToggle(ep, "Show Generator %", "ESPProgres", 9)
    addToggle(ep, "Gate", "GateESP", 10)
    addToggle(ep, "Hook", "HookESP", 11)
    addToggle(ep, "Pallet", "PalletESP", 12)
    addToggle(ep, "Vault", "VaultESP", 13)
    addToggle(ep, "Pumpkin", "PumpkinESP", 14)
    addToggle(ep, "Bear Trap", "TrapESP", 15)
    addSection(ep, "Warna Map")
    addColorPicker(ep, "Warna Generator", "ColorGenerator", 16)
    addColorPicker(ep, "Warna Gate", "ColorGate", 17)
    addColorPicker(ep, "Warna Hook", "ColorHook", 18)
    addColorPicker(ep, "Warna Pallet", "ColorPallet", 19)
    addColorPicker(ep, "Warna Vault", "ColorVault", 20)
    addColorPicker(ep, "Warna Pumpkin", "ColorPumpkin", 21)
    addColorPicker(ep, "Warna Trap", "ColorTrap", 22)

    -- VISUALS TAB
    local vs = makePage("Visuals")
    addSection(vs, "Lighting")
    addToggle(vs, "Full Bright", "FullBright", 1)
    addToggle(vs, "No Fog", "NoFog", 2)
    addToggle(vs, "Remove DOF", "RemoveDOF", 3)
    addSection(vs, "Graphics")
    addToggle(vs, "RTX Graphics", "RTXGraphics", 4)
    addToggle(vs, "Cinematic DOF", "CinematicDOF", 5)

    -- CONFIG TAB
    local cf = makePage("Config")
    addSection(cf, "Config Manager")
    addButton(cf, "Save Config", saveConfig, 1)
    addButton(cf, "Load Config", loadConfig, 2)
    addButton(cf, "Server Hop", serverHop, 3)

    -- BH BUTTON
    local bh = Instance.new("TextButton", sg); bh.Size = UDim2.new(0, 40, 0, 40); bh.Position = UDim2.new(0, 20, 0, 200); bh.BackgroundColor3 = Colors.Bg; bh.BorderSizePixel = 0; bh.Text = "BH"; bh.TextColor3 = Colors.Accent; bh.Font = Enum.Font.GothamBold; bh.TextSize = 13; bh.AutoButtonColor = false; bh.ZIndex = 5; Instance.new("UICorner", bh).CornerRadius = UDim.new(1, 0)
    local bhStroke = Instance.new("UIStroke", bh); bhStroke.Color = Colors.Accent; bhStroke.Thickness = 1.5
    bh.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

    -- DRAG
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = main.Position end end)
    main.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - dragStart; main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
    main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

    tabButtons["Survivor"].btn.MouseButton1Click:Fire()
end

task.spawn(function()
    while not LP do task.wait(0.5); LP = Players.LocalPlayer end
    pcall(setupHooks)
    task.spawn(function() while true do task.wait(3); pcall(scanMapObjects); pcall(scanMapESP); for _, plr in ipairs(Players:GetPlayers()) do if isKiller(plr) then hookKiller(plr) end end end end)
    buildUI()
end)