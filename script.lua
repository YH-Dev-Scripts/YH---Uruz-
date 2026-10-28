--[[
	YH Script | Prison Life
	Powered by Rayfield UI Library
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "YH Script | Prison Life",
   LoadingTitle = "YH Script",
   LoadingSubtitle = "by YH Dev & Studio",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "YHScript",
      FileName = "YH_PrisonLife"
   },
   Discord = {
      Enabled = true,
      Invite = "https://discord.gg/RPY4veGmp",
      RememberJoins = true
   },
   KeySystem = true,
   KeySettings = {
      Title = "YH Script | Key System",
      Subtitle = "Enter your key to access",
      Note = "Key: Check YH Website or YHUruz Server Discord",
      FileName = "YHKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"YH-Prison-Life"}
   }
})

local VERSION = "3.2.0"
local SAFE_MODE = false

-- ════════════════════════════════════════════════════════════════════════════════════════
--  BOOT
-- ════════════════════════════════════════════════════════════════════════════════════════
pcall(function()
    local fn = loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))
    if fn then fn("proj_f277aa0c3edc", "1.0.0", false) end
end)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait(0.1) until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

repeat task.wait() until game:IsLoaded()

print(string.format("[YH Script v%s] Loading...", VERSION))

local Camera = Workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════════════════════════════════
--  GLOBAL STATE
-- ════════════════════════════════════════════════════════════════════════════════════════
local Flags = {
    ["ESP/Enabled"]                = true,
    ["ESP/ShowUsername"]           = true,
    ["ESP/TeamCheck"]              = false,
    ["ESP/MaxDistance"]            = 5000,
    ["ESP/ColorByRole"]            = true,
    ["ESP/NametagOpacity"]         = 0,
    ["ESP/HighlightEnabled"]       = true,
    ["ESP/HighlightFillAlpha"]     = 0.75,
    ["ESP/HighlightOutlineAlpha"]  = 0.35,
    ["ESP/HealthIndicator"]        = true,
    ["ESP/ShowDistance"]           = true,
    ["ESP/ShowEquipped"]           = true,
    ["ESP/BoxEnabled"]             = false,
    ["ESP/HealthBarEnabled"]       = true,
    ["ESP/HealthBarVertical"]      = true,

    ["Hitbox/Enabled"]             = false,
    ["Hitbox/Size"]                = 10,
    ["Hitbox/Transparency"]         = 0.7,
    ["Hitbox/AllParts"]             = false,
    ["Hitbox/IncludeSelf"]          = false,
    ["Hitbox/Visualizer"]           = true,

    ["Noclip/Enabled"]             = false,
    ["Noclip/Radius"]              = 300,
    ["Noclip/IncludeAnchored"]     = true,
    ["Noclip/IncludeUnanchored"]   = false,

    ["Aim/AimLock"]                          = false,
    ["Aim/TeamCheck"]                        = false,
    ["Aim/VisibilityCheck"]                  = true,
    ["Aim/AttractionStrength"]               = 200,
    ["Aim/FOV/Radius"]                       = 100,
    ["Aim/FOV/ShowCircle"]                   = true,
    ["Aim/Dampening"]                        = true,
    ["Aim/Dampening/Threshold"]              = 5,
    ["Aim/Dampening/Strength"]               = 5,
    ["Aim/Priority"]                         = "Head",
    ["Aim/BodyParts"]                        = {"Head"},
    ["Aim/TargetGroups"] = {
        Head = true, Torso = false, LeftArm = false,
        RightArm = false, LeftLeg = false, RightLeg = false,
    },

    ["AutoGive/Enabled"]           = true,

    ["Arrest/Enabled"]             = true,
    ["Arrest/StickDistance"]       = 2.2,
    ["Arrest/StickHeight"]         = 0,
    ["Arrest/StickDuration"]       = 5,
    ["Arrest/ToolName"]            = "Handcuffs",
    ["Arrest/RestorePosition"]     = true,

    ["Humanoid/WalkSpeed"]   = 16,
    ["Humanoid/JumpPower"]   = 50,
    ["Humanoid/JumpHeight"]  = 7.2,
    ["Humanoid/HipHeight"]   = 2,
    ["Humanoid/MaxHealth"]   = 100,

    ["Humanoid/WalkSpeed/Locked"]   = false,
    ["Humanoid/JumpPower/Locked"]   = false,
    ["Humanoid/JumpHeight/Locked"]  = false,
    ["Humanoid/HipHeight/Locked"]   = false,
    ["Humanoid/MaxHealth/Locked"]   = false,
}

local SavedLocations = {}

local function SaveLocationsToDisk()
    if not writefile then return end
    local ok, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(SavedLocations)
    end)
    if ok and encoded then
        pcall(function() writefile("YH_PrisonLife_Locations.json", encoded) end)
    end
end

local function LoadLocationsFromDisk()
    if not (isfile and readfile) then return end
    pcall(function()
        if isfile("YH_PrisonLife_Locations.json") then
            local raw = readfile("YH_PrisonLife_Locations.json")
            local decoded = game:GetService("HttpService"):JSONDecode(raw)
            if type(decoded) == "table" then
                SavedLocations = decoded
            end
        end
    end)
end

LoadLocationsFromDisk()

local ROLE_COLORS = {
    Guard    = Color3.fromRGB(70, 150, 255),
    Inmate   = Color3.fromRGB(255, 150, 60),
    Criminal = Color3.fromRGB(230, 60, 60),
    Neutral  = Color3.fromRGB(200, 200, 210),
    Unknown  = Color3.fromRGB(180, 180, 190),
}

local function SafeSet(obj, prop, val)
    if not obj then return false end
    local ok = pcall(function()
        if obj[prop] ~= val then obj[prop] = val end
    end)
    return ok
end

local function SafeDestroy(obj)
    if obj then pcall(function() obj:Destroy() end) end
end

local function DetectRole(player)
    if not player or not player.Parent then return "Unknown" end

    local team = player.Team
    if team then
        local name = string.lower(team.Name)
        if name:find("guard") or name:find("police") or name:find("cop") or name:find("officer") then
            return "Guard"
        elseif name:find("inmate") or name:find("prisoner") then
            return "Inmate"
        elseif name:find("criminal") or name:find("escapee") or name:find("wanted") then
            return "Criminal"
        elseif name:find("neutral") or name:find("civilian") then
            return "Neutral"
        end

        local ok, color = pcall(function() return team.TeamColor.Color end)
        if ok and color then
            local r, g, b = color.R, color.G, color.B
            if b > 0.6 and r < 0.4 and g < 0.6 then
                return "Guard"
            elseif r > 0.7 and g > 0.4 and g < 0.8 and b < 0.4 then
                return "Inmate"
            elseif r > 0.7 and g < 0.4 and b < 0.4 then
                return "Criminal"
            elseif r > 0.6 and g > 0.6 and b > 0.6 then
                return "Neutral"
            end
        end
    end

    return "Unknown"
end

local function GetHealth(player)
    if not player then return 0, 100 end
    local char = player.Character
    if not char then return 0, 100 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health, hum.MaxHealth
    end
    return 0, 100
end

local function GetHealthColor(health, maxHealth)
    if not maxHealth or maxHealth <= 0 then return Color3.fromRGB(255, 255, 255) end
    local percent = math.clamp(health / maxHealth, 0, 1)

    if percent >= 0.75 then
        return Color3.fromRGB(70, 220, 100)
    elseif percent >= 0.5 then
        return Color3.fromRGB(180, 220, 70)
    elseif percent >= 0.25 then
        return Color3.fromRGB(255, 180, 50)
    else
        return Color3.fromRGB(230, 60, 60)
    end
end

local cachedPlayersList = Players:GetPlayers()
local function GetPlayersCache() return cachedPlayersList end
local function UpdatePlayerCache() cachedPlayersList = Players:GetPlayers() end

local CharCache = {}

local function GetCharacter(player)
    if not player then return nil end

    local cache = CharCache[player]
    if cache then
        local char = cache.Char
        local root = cache.Root
        if char and char.Parent and char == player.Character and root and root.Parent then
            if cache.Humanoid then
                if cache.Humanoid.Health > 0 then return char, root end
                return nil
            end
            return char, root
        else
            cache.Char = nil
            cache.Root = nil
            cache.Humanoid = nil
        end
    end

    local character = player.Character
    if not character or not character.Parent then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not rootPart then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return nil end

    if not cache then
        cache = {}
        CharCache[player] = cache
    end
    cache.Char = character
    cache.Root = rootPart
    cache.Humanoid = humanoid
    cache.Head = character:FindFirstChild("Head")

    return character, rootPart
end

local HumanoidState = { Original = {}, Captured = false }

local HUMANOID_PROPERTY_MAP = {
    ["Humanoid/WalkSpeed"]  = "WalkSpeed",
    ["Humanoid/JumpPower"]  = "JumpPower",
    ["Humanoid/JumpHeight"] = "JumpHeight",
    ["Humanoid/HipHeight"]  = "HipHeight",
    ["Humanoid/MaxHealth"]  = "MaxHealth",
}

local function CaptureHumanoidSettings()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    HumanoidState.Original = {}

    for flagKey, prop in pairs(HUMANOID_PROPERTY_MAP) do
        local ok, val = pcall(function() return hum[prop] end)
        if ok and val ~= nil then
            HumanoidState.Original[flagKey] = val

            local isLocked = Flags[flagKey .. "/Locked"] == true
            if not isLocked and Flags[flagKey] == nil then
                Flags[flagKey] = val
            end
        end
    end

    HumanoidState.Captured = true
end

local function ApplyHumanoidSettings()
    if not HumanoidState.Captured then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for flagKey, prop in pairs(HUMANOID_PROPERTY_MAP) do
        local isLocked = Flags[flagKey .. "/Locked"] == true
        if isLocked then
            local val = Flags[flagKey]
            if val ~= nil then
                pcall(function()
                    if hum[prop] ~= val then
                        hum[prop] = val
                    end
                end)
            end
        end
    end
end

local TARGET_GROUPS = {
    Head = {"Head"},
    Torso = {"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    LeftArm = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    RightArm = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"},
}

local ALL_BODY_PARTS = {}
for _, group in pairs(TARGET_GROUPS) do
    for _, part in ipairs(group) do
        table.insert(ALL_BODY_PARTS, part)
    end
end

local AimState = {
    LastAimTarget = nil,
    LastMouseMode = nil,
    LastOriginX = nil,
    LastOriginY = nil,
}

local function ClearAimLockState(resetMouseMode)
    AimState.LastAimTarget = nil
    AimState.LastOriginX = nil
    AimState.LastOriginY = nil
    if resetMouseMode then
        AimState.LastMouseMode = nil
    end
end

local CachedFilterType = (function()
    local ok, val = pcall(function()
        local ft = Enum.RaycastFilterType.Exclude
        if typeof(ft) == "EnumItem" then return ft end
    end)
    if ok and val then return val end
    ok, val = pcall(function()
        local ft = Enum.RaycastFilterType.Blacklist
        if typeof(ft) == "EnumItem" then return ft end
    end)
    if ok and val then return val end
    return nil
end)()

local SharedRaycastParams = RaycastParams.new()
SharedRaycastParams.IgnoreWater = true
if CachedFilterType then
    SharedRaycastParams.FilterType = CachedFilterType
end

local function Raycast(Origin, Direction, Filter)
    SharedRaycastParams.FilterDescendantsInstances = Filter
    return Workspace:Raycast(Origin, Direction, SharedRaycastParams)
end

local OcclusionFilter = {nil, nil}

local function ObjectOccluded(Enabled, Origin, Position, Object)
    if not Enabled then return false end
    if typeof(Position) ~= "Vector3" then return false end
    OcclusionFilter[1] = LocalPlayer.Character
    OcclusionFilter[2] = Object
    local hit = Raycast(Origin, Position - Origin, OcclusionFilter)
    if hit and hit.Instance and not hit.Instance:IsDescendantOf(Object) then
        return true
    end
    return false
end

local ViewportCache = {}
local ViewportPool = {}
local MAX_VIEWPORT_POOL = 64
local _vp_floor = math.floor

RunService.RenderStepped:Connect(function()
    local recycled = 0
    for _, entry in pairs(ViewportCache) do
        if recycled < MAX_VIEWPORT_POOL then
            ViewportPool[#ViewportPool + 1] = entry
            recycled = recycled + 1
        end
    end
    table.clear(ViewportCache)
end)

local function GetViewportPoint(worldPos)
    local kx = _vp_floor(worldPos.X * 4)
    local ky = _vp_floor(worldPos.Y * 4)
    local kz = _vp_floor(worldPos.Z * 4)
    local key = kx .. "|" .. ky .. "|" .. kz
    local entry = ViewportCache[key]
    if entry then return entry[1], entry[2] end

    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    entry = table.remove(ViewportPool) or {}
    entry[1], entry[2] = screenPos, onScreen
    ViewportCache[key] = entry
    return screenPos, onScreen
end

local function GetCrosshairViewportPosition(mouseBehavior)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return nil, nil, false end

    local viewportSize = Camera.ViewportSize

    if mouseBehavior == Enum.MouseBehavior.LockCenter then
        return viewportSize.X * 0.5, viewportSize.Y * 0.5, true
    end

    local mouseLoc = UserInputService:GetMouseLocation()
    local crosshairX = mouseLoc.X
    local crosshairY = mouseLoc.Y

    if crosshairX ~= crosshairX or crosshairY ~= crosshairY then
        return nil, nil, false
    end

    if crosshairX < 0 or crosshairY < 0
    or crosshairX > viewportSize.X or crosshairY > viewportSize.Y then
        return nil, nil, false
    end

    return crosshairX, crosshairY, true
end

local CandidateList = {}
local CandidateCount = 0
local MAX_CANDIDATES = 15
local ClosestResult = {nil, nil, nil, 0, 0, nil}

local function CandidateSortFn(a, b)
    return a.mag < b.mag
end

local function BoundedInsertionSort(array, count, compare)
    for i = 2, count do
        local key = array[i]
        local j = i - 1
        while j > 0 and compare(key, array[j]) do
            array[j + 1] = array[j]
            j = j - 1
        end
        array[j + 1] = key
    end
end

local _hoistedCheckParts = {}
local _lastTargetGroupsHash = nil

local function RebuildCheckParts()
    table.clear(_hoistedCheckParts)
    local anySelected = false
    for category, enabled in pairs(Flags["Aim/TargetGroups"]) do
        if enabled then
            anySelected = true
            for _, partName in ipairs(TARGET_GROUPS[category]) do
                table.insert(_hoistedCheckParts, partName)
            end
        end
    end
    if not anySelected then
        for _, partName in ipairs(ALL_BODY_PARTS) do
            table.insert(_hoistedCheckParts, partName)
        end
    end
end

local function GetClosest(Enabled, TeamCheck, VisibilityCheck, FieldOfView, StickyTarget)
    if not Enabled then return nil end

    local CameraPosition = Camera.CFrame.Position
    local mouseBehavior = UserInputService.MouseBehavior

    local crosshairX, crosshairY, crosshairValid = GetCrosshairViewportPosition(mouseBehavior)
    if not crosshairValid then return nil end

    CandidateCount = 0

    local players = GetPlayersCache()
    local lookVector = Camera.CFrame.LookVector
    local maxCandsLimit = MAX_CANDIDATES * 3

    local currentHash =
        (Flags["Aim/TargetGroups"].Head and 1 or 0) +
        (Flags["Aim/TargetGroups"].Torso and 2 or 0) +
        (Flags["Aim/TargetGroups"].LeftArm and 4 or 0) +
        (Flags["Aim/TargetGroups"].RightArm and 8 or 0) +
        (Flags["Aim/TargetGroups"].LeftLeg and 16 or 0) +
        (Flags["Aim/TargetGroups"].RightLeg and 32 or 0)
    if currentHash ~= _lastTargetGroupsHash then
        RebuildCheckParts()
        _lastTargetGroupsHash = currentHash
    end
    local checkParts = _hoistedCheckParts

    for _, Player in ipairs(players) do
        if Player == LocalPlayer then continue end

        local Character, RootPart = GetCharacter(Player)
        if not Character or not RootPart then continue end

        if TeamCheck then
            local lpTeam, pTeam = LocalPlayer.Team, Player.Team
            if lpTeam and pTeam and lpTeam == pTeam then continue end
        end

        local rootPos = RootPart.Position
        local relPos = rootPos - CameraPosition
        if lookVector:Dot(relPos) < 0 then continue end

        for _, PartName in ipairs(checkParts) do
            local cache = CharCache[Player]
            local BodyPart = (cache and cache[PartName]) or Character:FindFirstChild(PartName)
            if not BodyPart then continue end

            local ActualPosition = BodyPart.Position

            local ScreenPosition, OnScreen = GetViewportPoint(ActualPosition)
            if OnScreen then
                local screenX, screenY = ScreenPosition.X, ScreenPosition.Y
                local dx, dy = screenX - crosshairX, screenY - crosshairY
                local Magnitude = math.sqrt(dx * dx + dy * dy)

                if Magnitude < FieldOfView then
                    if CandidateCount < maxCandsLimit then
                        CandidateCount = CandidateCount + 1
                        local entry = CandidateList[CandidateCount]
                        if not entry then
                            entry = {}
                            CandidateList[CandidateCount] = entry
                        end
                        entry.mag = Magnitude
                        entry.ply = Player
                        entry.char = Character
                        entry.part = BodyPart
                        entry.sx = screenX
                        entry.sy = screenY
                        entry.pos = ActualPosition
                        entry.realPos = ActualPosition
                    end
                end
            end
        end
    end

    if CandidateCount == 0 then return nil end

    if CandidateCount > 1 then
        BoundedInsertionSort(CandidateList, CandidateCount, CandidateSortFn)
    end

    if StickyTarget then
        for i = 1, CandidateCount do
            local entry = CandidateList[i]
            if entry.ply == StickyTarget then
                if not ObjectOccluded(VisibilityCheck, CameraPosition, entry.realPos, entry.char) then
                    ClosestResult[1] = entry.ply
                    ClosestResult[2] = entry.char
                    ClosestResult[3] = entry.part
                    ClosestResult[4] = entry.sx
                    ClosestResult[5] = entry.sy
                    ClosestResult[6] = entry.pos
                    return ClosestResult
                end
                break
            end
        end
    end

    local limit = math.min(CandidateCount, MAX_CANDIDATES)

    for i = 1, limit do
        local entry = CandidateList[i]
        if not entry then continue end

        if ObjectOccluded(VisibilityCheck, CameraPosition, entry.realPos, entry.char) then
            continue
        end

        ClosestResult[1] = entry.ply
        ClosestResult[2] = entry.char
        ClosestResult[3] = entry.part
        ClosestResult[4] = entry.sx
        ClosestResult[5] = entry.sy
        ClosestResult[6] = entry.pos
        return ClosestResult
    end

    return nil
end

local function AimAt(Hitbox)
    if not Hitbox then
        ClearAimLockState(false)
        return
    end
    if not mousemoverel then return end

    local targetPart = Hitbox[3]
    if not targetPart or not targetPart.Parent then
        ClearAimLockState(false)
        return
    end

    local currentMode = UserInputService.MouseBehavior
    if currentMode ~= AimState.LastMouseMode then
        AimState.LastMouseMode = currentMode
        AimState.LastOriginX = nil
        AimState.LastOriginY = nil
    end

    local currentTarget = Hitbox[1]
    if currentTarget ~= AimState.LastAimTarget then
        AimState.LastAimTarget = currentTarget
        AimState.LastOriginX = nil
        AimState.LastOriginY = nil
    end

    local targetPos = targetPart.Position
    local cameraPos = Camera.CFrame.Position
    local dist = (targetPos - cameraPos).Magnitude

    if dist < 1 then return end

    local ScreenPosition, OnScreen = GetViewportPoint(targetPos)
    if not OnScreen or ScreenPosition.Z <= 0 then return end

    local viewportSize = Camera.ViewportSize
    local originX, originY, originValid = GetCrosshairViewportPosition(currentMode)
    if not originValid then return end

    AimState.LastOriginX = originX
    AimState.LastOriginY = originY

    local targetX, targetY = ScreenPosition.X, ScreenPosition.Y
    local dx, dy = targetX - originX, targetY - originY

    local mag = math.sqrt(dx * dx + dy * dy)
    if mag > Flags["Aim/FOV/Radius"] then return end

    local attractionMultiplier = Flags["Aim/AttractionStrength"] / 100

    if Flags["Aim/Dampening"] then
        local lockThreshold = Flags["Aim/Dampening/Threshold"]
        if mag < lockThreshold then
            local dampening = math.max(Flags["Aim/Dampening/Strength"] / 100, mag / lockThreshold)
            attractionMultiplier = attractionMultiplier * dampening
        end
    end

    local BASE_PULL = 0.2
    local deltaX = dx * BASE_PULL * attractionMultiplier
    local deltaY = dy * BASE_PULL * attractionMultiplier

    if deltaX ~= deltaX or deltaY ~= deltaY then return end

    local maxClampX = viewportSize.X * 0.5
    local maxClampY = viewportSize.Y * 0.5

    deltaX = math.clamp(deltaX, -maxClampX, maxClampX)
    deltaY = math.clamp(deltaY, -maxClampY, maxClampY)

    mousemoverel(math.floor(deltaX + 0.5), math.floor(deltaY + 0.5))
end

local CachedTarget = nil
local CachedTargetTime = 0
local TARGET_CACHE_DURATION = 0.016

local function GetCachedTarget()
    local now = os.clock()
    if CachedTarget and (now - CachedTargetTime) < TARGET_CACHE_DURATION then
        return CachedTarget
    end

    CachedTarget = GetClosest(
        true,
        Flags["Aim/TeamCheck"],
        Flags["Aim/VisibilityCheck"],
        Flags["Aim/FOV/Radius"],
        AimState.LastAimTarget
    )
    CachedTargetTime = now
    return CachedTarget
end

local FovCircleGui = nil
local FovCircleFrame = nil

local function EnsureFovCircleGui()
    if FovCircleGui and FovCircleGui.Parent then return FovCircleGui end

    local parent = gethui and gethui() or game:GetService("CoreGui")
    FovCircleGui = Instance.new("ScreenGui")
    FovCircleGui.Name = "YH_FOV"
    FovCircleGui.DisplayOrder = 5000
    FovCircleGui.IgnoreGuiInset = true
    FovCircleGui.ResetOnSpawn = false
    FovCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() FovCircleGui.Parent = parent end)
    if not FovCircleGui.Parent then
        FovCircleGui.Parent = game:GetService("CoreGui")
    end
    return FovCircleGui
end

local function UpdateFOVCircle()
    local showCircle = Flags["Aim/AimLock"] and Flags["Aim/FOV/ShowCircle"]

    if not showCircle then
        if FovCircleFrame then FovCircleFrame.Visible = false end
        return
    end

    local gui = EnsureFovCircleGui()

    if not FovCircleFrame or FovCircleFrame.Parent ~= gui then
        if FovCircleFrame then SafeDestroy(FovCircleFrame) end

        FovCircleFrame = Instance.new("Frame")
        FovCircleFrame.Name = "FOVCircle"
        FovCircleFrame.BackgroundTransparency = 1
        FovCircleFrame.BorderSizePixel = 0
        FovCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        FovCircleFrame.ZIndex = 1

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0); corner.Parent = FovCircleFrame

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(89, 210, 255)
        stroke.Transparency = 0.2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = FovCircleFrame

        FovCircleFrame.Parent = gui
    end

    local currentMode = UserInputService.MouseBehavior
    local crosshairX, crosshairY, crosshairValid = GetCrosshairViewportPosition(currentMode)

    if crosshairValid then
        local radius = Flags["Aim/FOV/Radius"] or 50
        local diameter = radius * 2
        FovCircleFrame.Size = UDim2.fromOffset(diameter, diameter)
        FovCircleFrame.Position = UDim2.fromOffset(crosshairX, crosshairY)
        FovCircleFrame.Visible = true
    else
        FovCircleFrame.Visible = false
    end
end

local function UpdateAim()
    pcall(UpdateFOVCircle)

    if SAFE_MODE then return end

    local AimActive = Flags["Aim/AimLock"]
    if not AimActive then
        ClearAimLockState(false)
        return
    end

    local target = GetCachedTarget()
    if target then
        AimAt(target)
    else
        ClearAimLockState(false)
    end
end

local ESP = { Objects = {}, Folder = nil }

local function EnsureESPFolder()
    if ESP.Folder and ESP.Folder.Parent then return ESP.Folder end
    local parent = gethui and gethui() or game:GetService("CoreGui")
    ESP.Folder = Instance.new("Folder")
    ESP.Folder.Name = "YH_ESP"
    pcall(function() ESP.Folder.Parent = parent end)
    if not ESP.Folder.Parent then ESP.Folder.Parent = game:GetService("CoreGui") end
    return ESP.Folder
end

local function CreateNametag(player)
    local folder = EnsureESPFolder()

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PV_" .. player.Name
    billboard.Adornee = nil
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 90)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.MaxDistance = Flags["ESP/MaxDistance"]
    billboard.Enabled = false
    billboard.Parent = folder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 1)
    layout.Parent = billboard

    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = ROLE_COLORS.Unknown
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextTransparency = Flags["ESP/NametagOpacity"]
    label.LayoutOrder = 1
    label.Parent = billboard

    local healthNum = Instance.new("TextLabel")
    healthNum.Name = "HealthNum"
    healthNum.Size = UDim2.new(1, 0, 0, 16)
    healthNum.BackgroundTransparency = 1
    healthNum.Text = "100/100"
    healthNum.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthNum.TextStrokeTransparency = 0
    healthNum.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthNum.TextSize = 13
    healthNum.Font = Enum.Font.GothamBold
    healthNum.TextTransparency = Flags["ESP/NametagOpacity"]
    healthNum.LayoutOrder = 2
    healthNum.Visible = Flags["ESP/HealthIndicator"]
    healthNum.Parent = billboard

    local healthBarBG = Instance.new("Frame")
    healthBarBG.Name = "HealthBarBG"
    healthBarBG.Size = UDim2.new(0.7, 0, 0, 5)
    healthBarBG.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    healthBarBG.BorderSizePixel = 0
    healthBarBG.LayoutOrder = 3
    healthBarBG.Visible = Flags["ESP/HealthIndicator"]
    healthBarBG.Parent = billboard
    local hbCorner = Instance.new("UICorner")
    hbCorner.CornerRadius = UDim.new(1, 0); hbCorner.Parent = healthBarBG

    local healthBarFill = Instance.new("Frame")
    healthBarFill.Name = "HealthBarFill"
    healthBarFill.Size = UDim2.fromScale(1, 1)
    healthBarFill.BackgroundColor3 = Color3.fromRGB(70, 220, 100)
    healthBarFill.BorderSizePixel = 0
    healthBarFill.Parent = healthBarBG
    local hbfCorner = Instance.new("UICorner")
    hbfCorner.CornerRadius = UDim.new(1, 0); hbfCorner.Parent = healthBarFill

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0, 16)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.TextSize = 12
    distanceLabel.Font = Enum.Font.GothamMedium
    distanceLabel.TextTransparency = Flags["ESP/NametagOpacity"]
    distanceLabel.LayoutOrder = 4
    distanceLabel.Visible = Flags["ESP/ShowDistance"]
    distanceLabel.Parent = billboard

    local equippedLabel = Instance.new("TextLabel")
    equippedLabel.Name = "EquippedLabel"
    equippedLabel.Size = UDim2.new(1, 0, 0, 16)
    equippedLabel.BackgroundTransparency = 1
    equippedLabel.Text = "[Unarmed]"
    equippedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    equippedLabel.TextStrokeTransparency = 0
    equippedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    equippedLabel.TextSize = 12
    equippedLabel.Font = Enum.Font.GothamMedium
    equippedLabel.TextTransparency = Flags["ESP/NametagOpacity"]
    equippedLabel.LayoutOrder = 5
    equippedLabel.Visible = Flags["ESP/ShowEquipped"]
    equippedLabel.Parent = billboard

    local highlight = Instance.new("Highlight")
    highlight.Name = "PV_HL_" .. player.Name
    highlight.Adornee = nil
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = ROLE_COLORS.Unknown
    highlight.FillTransparency = Flags["ESP/HighlightFillAlpha"]
    highlight.OutlineColor = ROLE_COLORS.Unknown
    highlight.OutlineTransparency = Flags["ESP/HighlightOutlineAlpha"]
    highlight.Enabled = false
    highlight.Parent = folder

    ESP.Objects[player] = {
        Nametag      = billboard,
        Label        = label,
        HealthNum    = healthNum,
        HealthBarBG  = healthBarBG,
        HealthBarFill= healthBarFill,
        DistanceLabel= distanceLabel,
        EquippedLabel= equippedLabel,
        Highlight    = highlight,
        LastName     = player.Name,
        LastRole     = nil,
        LastHealth   = -1,
        LastMaxHealth= -1,
        LastDistance = -1,
        LastEquipped = "",
    }
end

local function RemoveNametag(player)
    local data = ESP.Objects[player]
    if not data then return end
    SafeDestroy(data.Nametag)
    if data.Highlight then SafeDestroy(data.Highlight) end
    ESP.Objects[player] = nil
end

local function UpdateNametag(player)
    local data = ESP.Objects[player]
    if not data then return end

    local shouldShow = Flags["ESP/Enabled"]
    if shouldShow and Flags["ESP/TeamCheck"] then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            shouldShow = false
        end
    end
    if shouldShow and player == LocalPlayer then shouldShow = false end

    local char = player.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then shouldShow = false end

    local dist = 0
    if shouldShow then
        local myRoot = LocalPlayer.Character
            and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart)
        if myRoot then
            dist = (root.Position - myRoot.Position).Magnitude
            if dist > Flags["ESP/MaxDistance"] then shouldShow = false end
        end
    end

    if not shouldShow then
        SafeSet(data.Nametag, "Enabled", false)
        if data.Highlight then SafeSet(data.Highlight, "Enabled", false) end
        return
    end

    if data.Nametag.Adornee ~= root then data.Nametag.Adornee = root end
    SafeSet(data.Nametag, "Enabled", true)
    SafeSet(data.Nametag, "MaxDistance", Flags["ESP/MaxDistance"])

    if data.Highlight then
        local hlActive = Flags["ESP/HighlightEnabled"]
        if data.Highlight.Adornee ~= char then data.Highlight.Adornee = char end
        SafeSet(data.Highlight, "Enabled", hlActive)
    end

    if Flags["ESP/ShowUsername"] then
        if data.LastName ~= player.Name then
            data.LastName = player.Name
            SafeSet(data.Label, "Text", player.Name)
        end
        SafeSet(data.Label, "Visible", true)
    else
        SafeSet(data.Label, "Visible", false)
    end

    local health, maxHealth = GetHealth(player)
    if data.HealthNum then
        SafeSet(data.HealthNum, "Visible", Flags["ESP/HealthIndicator"])
        if data.LastHealth ~= math.floor(health) or data.LastMaxHealth ~= math.floor(maxHealth) then
            data.LastHealth = math.floor(health)
            data.LastMaxHealth = math.floor(maxHealth)
            SafeSet(data.HealthNum, "Text", string.format("%d / %d", math.floor(health), math.floor(maxHealth)))
            local hpColor = GetHealthColor(health, maxHealth)
            SafeSet(data.HealthNum, "TextColor3", hpColor)
            if data.HealthBarFill then
                local pct = math.clamp(health / math.max(maxHealth, 1), 0, 1)
                SafeSet(data.HealthBarFill, "Size", UDim2.fromScale(pct, 1))
                SafeSet(data.HealthBarFill, "BackgroundColor3", hpColor)
            end
        end
    end
    if data.HealthBarBG then
        SafeSet(data.HealthBarBG, "Visible", Flags["ESP/HealthIndicator"])
    end

    if data.DistanceLabel then
        SafeSet(data.DistanceLabel, "Visible", Flags["ESP/ShowDistance"])
        local distRounded = math.floor(dist)
        if math.abs(data.LastDistance - distRounded) >= 1 then
            data.LastDistance = distRounded
            SafeSet(data.DistanceLabel, "Text", string.format("%d studs", distRounded))
        end
    end

    if data.EquippedLabel then
        SafeSet(data.EquippedLabel, "Visible", Flags["ESP/ShowEquipped"])
        local tool = char:FindFirstChildOfClass("Tool")
        local toolName = tool and tool.Name or "Unarmed"
        local equippedStr = "[" .. toolName .. "]"
        if data.LastEquipped ~= equippedStr then
            data.LastEquipped = equippedStr
            SafeSet(data.EquippedLabel, "Text", equippedStr)
        end
    end

    local role = Flags["ESP/ColorByRole"] and DetectRole(player) or nil
    if role then
        if data.LastRole ~= role then
            data.LastRole = role
            local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
            SafeSet(data.Label, "TextColor3", color)
            if data.Highlight then
                SafeSet(data.Highlight, "FillColor", color)
                SafeSet(data.Highlight, "OutlineColor", color)
            end
        end
    else
        if data.LastRole ~= "plain" then
            data.LastRole = "plain"
            SafeSet(data.Label, "TextColor3", ROLE_COLORS.Neutral)
            if data.Highlight then
                SafeSet(data.Highlight, "FillColor", ROLE_COLORS.Neutral)
                SafeSet(data.Highlight, "OutlineColor", ROLE_COLORS.Neutral)
            end
        end
    end
end

local function RefreshESP()
    local players = Players:GetPlayers()
    for _, p in ipairs(players) do
        if p ~= LocalPlayer then
            if not ESP.Objects[p] then CreateNametag(p) end
            UpdateNametag(p)
        end
    end
    for p, _ in pairs(ESP.Objects) do
        if not p.Parent then RemoveNametag(p) end
    end
end

local ESP2D = { Objects = {}, Gui = nil }

local function EnsureESP2DGui()
    if ESP2D.Gui and ESP2D.Gui.Parent then return ESP2D.Gui end
    local gui = Instance.new("ScreenGui")
    gui.Name = "YH_ESP2D"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 998
    local parent = gethui and gethui() or game:GetService("CoreGui")
    local ok = pcall(function() gui.Parent = parent end)
    if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    ESP2D.Gui = gui
    return gui
end

local function CreateESP2D(player)
    local gui = EnsureESP2DGui()
    local root = Instance.new("Frame")
    root.Name = "P_" .. player.UserId
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Visible = false
    root.Parent = gui

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.fromScale(1, 1)
    box.Parent = root
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Color = ROLE_COLORS.Unknown
    boxStroke.Transparency = 0.04
    boxStroke.Parent = box

    local healthBG = Instance.new("Frame")
    healthBG.Name = "HealthBG"
    healthBG.BackgroundColor3 = Color3.fromRGB(12, 15, 19)
    healthBG.BackgroundTransparency = 0.12
    healthBG.BorderSizePixel = 0
    healthBG.Visible = false
    healthBG.Parent = gui
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.BackgroundColor3 = Color3.fromRGB(80, 230, 130)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBG

    ESP2D.Objects[player] = {Root = root, Box = box, Stroke = boxStroke, HealthBG = healthBG, HealthFill = healthFill}
end

local function RemoveESP2D(player)
    local data = ESP2D.Objects[player]
    if not data then return end
    SafeDestroy(data.Root)
    SafeDestroy(data.HealthBG)
    ESP2D.Objects[player] = nil
end

local function UpdateESP2D()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESP2D.Objects[player] then CreateESP2D(player) end
            local data = ESP2D.Objects[player]
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local shouldShow = Flags["ESP/Enabled"] and (Flags["ESP/BoxEnabled"] or Flags["ESP/HealthBarEnabled"]) and char and hum and hum.Health > 0
            if shouldShow and Flags["ESP/TeamCheck"] and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                shouldShow = false
            end
            local rootPart = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            local localRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart)
            if shouldShow and rootPart and localRoot then
                local dist = (rootPart.Position - localRoot.Position).Magnitude
                if dist > (Flags["ESP/MaxDistance"] or 5000) then shouldShow = false end
            end
            if shouldShow then
                local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
                if ok and cf and size then
                    local half = size * 0.5
                    local corners = {
                        Vector3.new(-half.X,-half.Y,-half.Z), Vector3.new(-half.X,-half.Y,half.Z),
                        Vector3.new(-half.X,half.Y,-half.Z), Vector3.new(-half.X,half.Y,half.Z),
                        Vector3.new(half.X,-half.Y,-half.Z), Vector3.new(half.X,-half.Y,half.Z),
                        Vector3.new(half.X,half.Y,-half.Z), Vector3.new(half.X,half.Y,half.Z),
                    }
                    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                    local valid = false
                    for _, corner in ipairs(corners) do
                        local v, onScreen = camera:WorldToViewportPoint(cf:PointToWorldSpace(corner))
                        if v.Z > 0 then
                            valid = true
                            minX, minY = math.min(minX, v.X), math.min(minY, v.Y)
                            maxX, maxY = math.max(maxX, v.X), math.max(maxY, v.Y)
                        end
                    end
                    if valid and maxX > minX and maxY > minY then
                        minX, minY = math.floor(minX), math.floor(minY)
                        maxX, maxY = math.floor(maxX), math.floor(maxY)
                        data.Root.Position = UDim2.fromOffset(minX, minY)
                        data.Root.Size = UDim2.fromOffset(math.max(2, maxX-minX), math.max(2, maxY-minY))
                        data.Root.Visible = true
                        data.Box.Visible = Flags["ESP/BoxEnabled"]
                        local color = ROLE_COLORS.Neutral
                        if Flags["ESP/ColorByRole"] then
                            local role = DetectRole(player)
                            color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
                        end
                        data.Stroke.Color = color

                        local health, maxHealth = GetHealth(player)
                        local pct = math.clamp(health / math.max(maxHealth, 1), 0, 1)
                        local hpColor = GetHealthColor(health, maxHealth)
                        local barOn = Flags["ESP/HealthBarEnabled"]
                        data.HealthBG.Visible = barOn
                        data.HealthBG.BackgroundColor3 = Color3.fromRGB(12,15,19)
                        data.HealthFill.BackgroundColor3 = hpColor
                        if Flags["ESP/HealthBarVertical"] then
                            data.HealthBG.Position = UDim2.fromOffset(minX - 7, minY)
                            data.HealthBG.Size = UDim2.fromOffset(4, math.max(2, maxY-minY))
                            data.HealthFill.AnchorPoint = Vector2.new(0, 1)
                            data.HealthFill.Position = UDim2.new(0, 0, 1, 0)
                            data.HealthFill.Size = UDim2.new(1, 0, pct, 0)
                        else
                            data.HealthBG.Position = UDim2.fromOffset(minX, maxY + 4)
                            data.HealthBG.Size = UDim2.fromOffset(math.max(2, maxX-minX), 4)
                            data.HealthFill.AnchorPoint = Vector2.new(0, 0)
                            data.HealthFill.Position = UDim2.fromOffset(0, 0)
                            data.HealthFill.Size = UDim2.new(pct, 0, 1, 0)
                        end
                    else
                        data.Root.Visible = false
                        data.HealthBG.Visible = false
                    end
                else
                    data.Root.Visible = false
                    data.HealthBG.Visible = false
                end
            else
                data.Root.Visible = false
                data.HealthBG.Visible = false
            end
        end
    end
    for player in pairs(ESP2D.Objects) do
        if not player.Parent then RemoveESP2D(player) end
    end
end

local Noclip = {
    Broken = {},
    BrokenCount = 0,
    OverlapParams = OverlapParams.new(),
    RaycastParams = RaycastParams.new(),
    ScratchIgnore = {},
}

Noclip.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
Noclip.OverlapParams.MaxParts = 0
Noclip.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Noclip.RaycastParams.IgnoreWater = true

local _feetPartsBuffer = {}

local function GetPartsUnderFeet(char)
    table.clear(_feetPartsBuffer)
    if not char then return _feetPartsBuffer end

    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return _feetPartsBuffer end

    local ignore = Noclip.ScratchIgnore
    table.clear(ignore)
    ignore[1] = char
    Noclip.RaycastParams.FilterDescendantsInstances = ignore

    local basePos = root.Position - Vector3.new(0, 2.5, 0)
    local direction = Vector3.new(0, -12, 0)
    local rootCF = root.CFrame

    local relOffsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(-1.2, 0, -1.2), Vector3.new(1.2, 0, -1.2),
        Vector3.new(-1.2, 0, 1.2),  Vector3.new(1.2, 0, 1.2),
    }

    for _, relOff in ipairs(relOffsets) do
        local origin = basePos + rootCF:VectorToWorldSpace(relOff)
        local ok, result = pcall(function()
            return Workspace:Raycast(origin, direction, Noclip.RaycastParams)
        end)
        if ok and result and result.Instance then
            _feetPartsBuffer[result.Instance] = true
        end
    end

    return _feetPartsBuffer
end

local function ShouldBreak(part, feetParts)
    if not part or not part:IsA("BasePart") then return false end
    if part:IsA("Terrain") then return false end
    if not part.Parent then return false end

    local myChar = LocalPlayer.Character
    if myChar and part:IsDescendantOf(myChar) then return false end

    local model = part:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then return false end

    if part:IsA("SpawnLocation") then return false end
    if feetParts and feetParts[part] then return false end

    local name = string.lower(part.Name)
    if name == "baseplate" or name == "ground" or name == "floor"
    or name == "terrain" or name == "base" then
        return false
    end

    if part.Size.X > 400 and part.Size.Z > 400 then return false end

    if part.Anchored then
        if not Flags["Noclip/IncludeAnchored"] then return false end
    else
        if not Flags["Noclip/IncludeUnanchored"] then return false end
    end

    return true
end

local function BreakPart(part)
    if Noclip.Broken[part] then
        if part.CanCollide then
            pcall(function() part.CanCollide = false end)
        end
        return
    end

    Noclip.Broken[part] = { cc = part.CanCollide }
    Noclip.BrokenCount = Noclip.BrokenCount + 1
    pcall(function() part.CanCollide = false end)
end

local function RestorePart(part)
    local data = Noclip.Broken[part]
    if not data then return end
    pcall(function()
        if part and part.Parent and type(data) == "table" then
            part.CanCollide = data.cc
        end
    end)
    Noclip.Broken[part] = nil
    Noclip.BrokenCount = math.max(0, Noclip.BrokenCount - 1)
end

local function RestoreAll()
    for part, data in pairs(Noclip.Broken) do
        pcall(function()
            if part and part.Parent and type(data) == "table" then
                part.CanCollide = data.cc
            end
        end)
    end
    Noclip.Broken = {}
    Noclip.BrokenCount = 0
end

local function ScanAndBreak()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return end

    local radius = Flags["Noclip/Radius"] or 300
    local origin = root.Position
    local feetParts = GetPartsUnderFeet(char)

    local ignore = Noclip.ScratchIgnore
    table.clear(ignore)
    ignore[1] = char
    Noclip.OverlapParams.FilterDescendantsInstances = ignore

    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInRadius(origin, radius, Noclip.OverlapParams)
    end)
    if not ok or not parts then return end

    for _, part in ipairs(parts) do
        if ShouldBreak(part, feetParts) then
            BreakPart(part)
        end
    end
end

local function EnforceNoclip()
    if next(Noclip.Broken) == nil then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return end

    local feetParts = GetPartsUnderFeet(char)
    local toRemove, toRestore = nil, nil

    for part, _ in pairs(Noclip.Broken) do
        if not part or not part.Parent then
            toRemove = toRemove or {}
            toRemove[#toRemove + 1] = part
        elseif feetParts[part] then
            toRestore = toRestore or {}
            toRestore[#toRestore + 1] = part
        elseif part.CanCollide then
            pcall(function() part.CanCollide = false end)
        end
    end

    if toRemove then
        for _, part in ipairs(toRemove) do
            if Noclip.Broken[part] then
                Noclip.Broken[part] = nil
                Noclip.BrokenCount = math.max(0, Noclip.BrokenCount - 1)
            end
        end
    end
    if toRestore then
        for _, part in ipairs(toRestore) do
            RestorePart(part)
        end
    end
end

local AutoGive = { Running = false }

local MP5_ORIGIN_POS       = Vector3.new(813.698, 97.85, 2229.396)
local REMINGTON_ORIGIN_POS = Vector3.new(820.298, 97.85, 2229.396)
local MATCH_TOLERANCE      = 5

local TP_HEIGHT_OFFSET = 6
local TP_DWELL_TIME    = 0.8

local function FindTouchGiverByPos(targetPos)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "TouchGiver" and obj:IsA("Model") then
            local ok, pos = pcall(function()
                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                return primary and primary.Position
            end)
            if ok and pos and (pos - targetPos).Magnitude < MATCH_TOLERANCE then
                return obj, pos
            end
        end
    end
    return nil
end

local function GetMyRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function TeleportToTouchGiver(touchPos, myRoot, homeCFrame)
    if not myRoot or not touchPos then return end
    local targetCFrame = CFrame.new(touchPos + Vector3.new(0, TP_HEIGHT_OFFSET, 0))

    pcall(function() myRoot.CFrame = targetCFrame end)
    task.wait(TP_DWELL_TIME)
    pcall(function() myRoot.CFrame = homeCFrame end)
    task.wait(0.1)
end

local function SpawnTouchGiversInFront(force)
    if not force and not Flags["AutoGive/Enabled"] then return end
    if AutoGive.Running then return end
    AutoGive.Running = true

    task.wait(1.2)
    local myRoot = GetMyRoot()
    if not myRoot then
        AutoGive.Running = false
        return
    end

    local homeCFrame = myRoot.CFrame
    local _, mp5Pos = FindTouchGiverByPos(MP5_ORIGIN_POS)
    local _, remPos = FindTouchGiverByPos(REMINGTON_ORIGIN_POS)

    if not mp5Pos and not remPos then
        AutoGive.Running = false
        return
    end

    if remPos then
        TeleportToTouchGiver(remPos, myRoot, homeCFrame)
        myRoot = GetMyRoot()
        if myRoot then homeCFrame = myRoot.CFrame end
    end

    if mp5Pos then
        TeleportToTouchGiver(mp5Pos, myRoot, homeCFrame)
    end

    local finalRoot = GetMyRoot()
    if finalRoot then
        pcall(function() finalRoot.CFrame = homeCFrame end)
    end

    AutoGive.Running = false
end

local ArrestState = {
    Running = false,
    SelectedPlayer = nil,
    ChaserConn = nil,
    EndTime = 0,
    HomeCFrame = nil,
    TargetRoot = nil,
}

local function GetCriminalsList()
    local out = {}
    for _, p in ipairs(GetPlayersCache()) do
        if p ~= LocalPlayer and p.Parent then
            local role = DetectRole(p)
            if role == "Criminal" then
                local char, root = GetCharacter(p)
                if char and root then
                    local myRoot = GetMyRoot()
                    local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                    table.insert(out, { player = p, dist = dist })
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

local function EquipToolByName(toolName)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return false end

    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and equipped.Name == toolName then return true end

    local tool = backpack:FindFirstChild(toolName)
    if not tool or not tool:IsA("Tool") then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    pcall(function() hum:EquipTool(tool) end)
    return true
end

local function GetBehindCFrame(targetRoot)
    if not targetRoot then return nil end
    local dist = Flags["Arrest/StickDistance"] or 2.2
    local height = Flags["Arrest/StickHeight"] or 0
    return targetRoot.CFrame * CFrame.new(0, height, dist)
end

local function StartChaser(targetRoot)
    local char = LocalPlayer.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum then return nil end

    pcall(function() hum.AutoRotate = false end)

    local chaserConn
    chaserConn = RunService.RenderStepped:Connect(function()
        local myR = LocalPlayer.Character
            and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart)
        if not myR then return end

        local behind = GetBehindCFrame(targetRoot)
        if behind then
            pcall(function()
                myR.CFrame = behind
                myR.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end)

    return chaserConn
end

local function StopChaser(restoreCFrame)
    if ArrestState.ChaserConn then
        pcall(function() ArrestState.ChaserConn:Disconnect() end)
        ArrestState.ChaserConn = nil
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.AutoRotate = true end) end

    local myRoot = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if myRoot and restoreCFrame then
        pcall(function() myRoot.CFrame = restoreCFrame end)
    end

    ArrestState.TargetRoot = nil
    ArrestState.HomeCFrame = nil
    ArrestState.EndTime = 0
end

local function ArrestPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then return false end
    if ArrestState.Running then return false end

    ArrestState.Running = true

    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    if not myRoot then
        ArrestState.Running = false
        return false
    end

    local homeCFrame = myRoot.CFrame
    local toolName = Flags["Arrest/ToolName"] or "Handcuffs"
    local equipped = EquipToolByName(toolName)
    if not equipped then
        Rayfield:Notify({Title = "Arrest", Content = "Could not equip " .. toolName .. ".", Duration = 3})
        ArrestState.Running = false
        return false
    end

    task.wait(0.2)

    local targetChar, targetRoot = GetCharacter(targetPlayer)
    if not targetChar or not targetRoot then
        Rayfield:Notify({Title = "Arrest", Content = "Target character not found.", Duration = 3})
        pcall(function() myRoot.CFrame = homeCFrame end)
        ArrestState.Running = false
        return false
    end

    local behind = GetBehindCFrame(targetRoot)
    if behind then
        pcall(function() myRoot.CFrame = behind end)
        task.wait(0.1)
    end

    ArrestState.TargetRoot = targetRoot
    ArrestState.HomeCFrame = homeCFrame
    ArrestState.EndTime = tick() + (Flags["Arrest/StickDuration"] or 5)
    ArrestState.ChaserConn = StartChaser(targetRoot)

    Rayfield:Notify({Title = "Arrest", Content = string.format("Sticking to %s. Click them to arrest!", targetPlayer.Name), Duration = 3})
    return true
end

local function StopArrestStick()
    if not ArrestState.Running then return end
    ArrestState.Running = false
    StopChaser(ArrestState.HomeCFrame)
    Rayfield:Notify({Title = "Arrest", Content = "Stopped sticking.", Duration = 2})
end

local TELEPORT_PRESETS = {
    {name = "Entrance Tower",          pos = Vector3.new(510,  122, 2325)},
    {name = "Police Car Spawn",        pos = Vector3.new(595,  98,  2497)},
    {name = "Police Armory",           pos = Vector3.new(816,  99,  2237)},
    {name = "Rooftop (Escape)",        pos = Vector3.new(946,  135, 2201)},
    {name = "Yard Tower",              pos = Vector3.new(822,  125, 2587)},
    {name = "Hammer",                  pos = Vector3.new(806,  98,  2525)},
    {name = "Knife",                   pos = Vector3.new(707,  97,  2508)},
    {name = "Criminal Armory",         pos = Vector3.new(-936, 94,  2043)},
    {name = "Criminal Car Spawn",      pos = Vector3.new(-912, 95,  2160)},
    {name = "Criminal Tower Rooftop",  pos = Vector3.new(-371, 114, 1992)},
}

local function TeleportToPosition(pos)
    if typeof(pos) ~= "Vector3" then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return false end

    pcall(function()
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return true
end

local function GetCurrentPosition()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return nil end
    return root.Position
end

local HitboxState = { Original = {} }

local function HitboxRemember(part)
    if not HitboxState.Original[part] then
        HitboxState.Original[part] = {Size = part.Size, Transparency = part.Transparency}
    end
end

local function HitboxRestoreCharacter(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        local original = HitboxState.Original[part]
        if part:IsA("BasePart") and original then
            pcall(function() part.Size = original.Size; part.Transparency = original.Transparency end)
            HitboxState.Original[part] = nil
        end
    end
    local viz = char:FindFirstChild("YHHitboxViz")
    if viz then viz:Destroy() end
end

local function HitboxApplyCharacter(char)
    if not Flags["Hitbox/Enabled"] or not char then return end
    local player = Players:GetPlayerFromCharacter(char)
    if not player or (player == LocalPlayer and not Flags["Hitbox/IncludeSelf"]) then return end
    local parts = {}
    if Flags["Hitbox/AllParts"] then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then table.insert(parts, part) end
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(parts, hrp) end
    else
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(parts, hrp) end
    end
    for _, part in ipairs(parts) do
        HitboxRemember(part)
        pcall(function()
            part.Size = Vector3.new(Flags["Hitbox/Size"], Flags["Hitbox/Size"], Flags["Hitbox/Size"])
            part.Transparency = Flags["Hitbox/Transparency"]
        end)
    end
    local viz = char:FindFirstChild("YHHitboxViz")
    if Flags["Hitbox/Visualizer"] then
        if not viz then
            viz = Instance.new("Highlight")
            viz.Name = "YHHitboxViz"
            viz.FillColor = Color3.fromRGB(89, 210, 255)
            viz.FillTransparency = 0.55
            viz.OutlineColor = Color3.fromRGB(89, 210, 255)
            viz.OutlineTransparency = 0.05
            viz.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            viz.Adornee = char
            viz.Parent = char
        end
    elseif viz then viz:Destroy() end
end

local function HitboxRestoreAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then HitboxRestoreCharacter(player.Character) end
    end
    for part, original in pairs(HitboxState.Original) do
        if part and part.Parent then
            pcall(function() part.Size = original.Size; part.Transparency = original.Transparency end)
        end
    end
    table.clear(HitboxState.Original)
end

local function HitboxRefreshAll()
    HitboxRestoreAll()
    if Flags["Hitbox/Enabled"] then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then HitboxApplyCharacter(player.Character) end
        end
    end
end

local AimTab = Window:CreateTab("Aim", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483345998)
local HumanoidTab = Window:CreateTab("Humanoid", 4483349987)
local NoclipTab = Window:CreateTab("Noclip", 4483362458)
local HitboxTab = Window:CreateTab("Hitbox", 4483345998)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local GoToTab = Window:CreateTab("Go-To Players", 4483345998)
local AutoGiveTab = Window:CreateTab("Auto-Give", 4483362458)
local ArrestTab = Window:CreateTab("Arrest", 4483362458)

AimTab:CreateSection("Aim Assist")
AimTab:CreateToggle({
   Name = "Enable Aimlock",
   CurrentValue = Flags["Aim/AimLock"],
   Flag = "AimLockToggle",
   Callback = function(Value)
      Flags["Aim/AimLock"] = Value
      if not Value then ClearAimLockState(true) end
   end,
})

AimTab:CreateToggle({
   Name = "Ignore Teammates",
   CurrentValue = Flags["Aim/TeamCheck"],
   Flag = "AimTeamCheck",
   Callback = function(Value) Flags["Aim/TeamCheck"] = Value end,
})

AimTab:CreateToggle({
   Name = "Visibility Check",
   CurrentValue = Flags["Aim/VisibilityCheck"],
   Flag = "AimVisCheck",
   Callback = function(Value) Flags["Aim/VisibilityCheck"] = Value end,
})

AimTab:CreateSlider({
   Name = "Attraction Strength",
   Range = {0, 500},
   Increment = 10,
   CurrentValue = Flags["Aim/AttractionStrength"],
   Flag = "AimStrength",
   Callback = function(Value) Flags["Aim/AttractionStrength"] = Value end,
})

AimTab:CreateSlider({
   Name = "FOV Radius",
   Range = {0, 500},
   Increment = 5,
   CurrentValue = Flags["Aim/FOV/Radius"],
   Flag = "AimFOV",
   Callback = function(Value) Flags["Aim/FOV/Radius"] = Value end,
})

AimTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = Flags["Aim/FOV/ShowCircle"],
   Flag = "AimShowCircle",
   Callback = function(Value) Flags["Aim/FOV/ShowCircle"] = Value end,
})

AimTab:CreateSection("Dampening")
AimTab:CreateToggle({
   Name = "Enable Dampening",
   CurrentValue = Flags["Aim/Dampening"],
   Flag = "AimDampening",
   Callback = function(Value) Flags["Aim/Dampening"] = Value end,
})

AimTab:CreateSlider({
   Name = "Dampening Threshold",
   Range = {0, 500},
   Increment = 5,
   CurrentValue = Flags["Aim/Dampening/Threshold"],
   Flag = "AimDampThreshold",
   Callback = function(Value) Flags["Aim/Dampening/Threshold"] = Value end,
})

AimTab:CreateSlider({
   Name = "Dampening Min Strength",
   Range = {0, 100},
   Increment = 1,
   CurrentValue = Flags["Aim/Dampening/Strength"],
   Flag = "AimDampStrength",
   Callback = function(Value) Flags["Aim/Dampening/Strength"] = Value end,
})

ESPTab:CreateSection("ESP Options")
ESPTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = Flags["ESP/Enabled"],
   Flag = "ESPEnabled",
   Callback = function(Value) Flags["ESP/Enabled"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Show Username",
   CurrentValue = Flags["ESP/ShowUsername"],
   Flag = "ESPUsername",
   Callback = function(Value) Flags["ESP/ShowUsername"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Color By Role",
   CurrentValue = Flags["ESP/ColorByRole"],
   Flag = "ESPRoleColor",
   Callback = function(Value) Flags["ESP/ColorByRole"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Hide Teammates",
   CurrentValue = Flags["ESP/TeamCheck"],
   Flag = "ESPTeamCheck",
   Callback = function(Value) Flags["ESP/TeamCheck"] = Value end,
})

ESPTab:CreateSlider({
   Name = "Max Distance",
   Range = {50, 10000},
   Increment = 50,
   CurrentValue = Flags["ESP/MaxDistance"],
   Flag = "ESPMaxDist",
   Callback = function(Value) Flags["ESP/MaxDistance"] = Value end,
})

ESPTab:CreateSection("Player Info & Visuals")
ESPTab:CreateToggle({
   Name = "Show Health",
   CurrentValue = Flags["ESP/HealthIndicator"],
   Flag = "ESPHealth",
   Callback = function(Value) Flags["ESP/HealthIndicator"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Show Distance",
   CurrentValue = Flags["ESP/ShowDistance"],
   Flag = "ESPDist",
   Callback = function(Value) Flags["ESP/ShowDistance"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Show Equipped Tool",
   CurrentValue = Flags["ESP/ShowEquipped"],
   Flag = "ESPEquipped",
   Callback = function(Value) Flags["ESP/ShowEquipped"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Enable Box ESP",
   CurrentValue = Flags["ESP/BoxEnabled"],
   Flag = "ESPBox",
   Callback = function(Value) Flags["ESP/BoxEnabled"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Enable Health Bar",
   CurrentValue = Flags["ESP/HealthBarEnabled"],
   Flag = "ESPHealthBar",
   Callback = function(Value) Flags["ESP/HealthBarEnabled"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Vertical Health Bar",
   CurrentValue = Flags["ESP/HealthBarVertical"],
   Flag = "ESPHealthBarVert",
   Callback = function(Value) Flags["ESP/HealthBarVertical"] = Value end,
})

ESPTab:CreateToggle({
   Name = "Enable Highlight",
   CurrentValue = Flags["ESP/HighlightEnabled"],
   Flag = "ESPHighlight",
   Callback = function(Value)
      Flags["ESP/HighlightEnabled"] = Value
      for _, data in pairs(ESP.Objects) do
          if data.Highlight then SafeSet(data.Highlight, "Enabled", Value) end
      end
   end,
})

HumanoidTab:CreateSection("Movement & Stats")
HumanoidTab:CreateSlider({
   Name = "Walk Speed",
   Range = {0, 500},
   Increment = 1,
   CurrentValue = 16,
   Flag = "HumanoidWalkSpeed",
   Callback = function(Value)
      Flags["Humanoid/WalkSpeed"] = Value
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum then pcall(function() hum.WalkSpeed = Value end) end
   end,
})

HumanoidTab:CreateSlider({
   Name = "Jump Power",
   Range = {0, 500},
   Increment = 1,
   CurrentValue = 50,
   Flag = "HumanoidJumpPower",
   Callback = function(Value)
      Flags["Humanoid/JumpPower"] = Value
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum then pcall(function() hum.JumpPower = Value end) end
   end,
})

HumanoidTab:CreateSlider({
   Name = "Jump Height",
   Range = {0, 500},
   Increment = 0.5,
   CurrentValue = 7.2,
   Flag = "HumanoidJumpHeight",
   Callback = function(Value)
      Flags["Humanoid/JumpHeight"] = Value
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum then pcall(function() hum.JumpHeight = Value end) end
   end,
})

HumanoidTab:CreateSlider({
   Name = "Hip Height",
   Range = {0, 100},
   Increment = 0.5,
   CurrentValue = 2,
   Flag = "HumanoidHipHeight",
   Callback = function(Value)
      Flags["Humanoid/HipHeight"] = Value
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum then pcall(function() hum.HipHeight = Value end) end
   end,
})

HumanoidTab:CreateSlider({
   Name = "Max Health",
   Range = {0, 2000},
   Increment = 1,
   CurrentValue = 100,
   Flag = "HumanoidMaxHealth",
   Callback = function(Value)
      Flags["Humanoid/MaxHealth"] = Value
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum then pcall(function() hum.MaxHealth = Value end) end
   end,
})

NoclipTab:CreateSection("Noclip Controls")
NoclipTab:CreateToggle({
   Name = "Enable Noclip",
   CurrentValue = Flags["Noclip/Enabled"],
   Flag = "NoclipToggle",
   Callback = function(Value)
      Flags["Noclip/Enabled"] = Value
      if Value then
          Rayfield:Notify({Title = "Noclip", Content = "Scanning walls...", Duration = 2})
          task.spawn(function() ScanAndBreak() end)
      else
          RestoreAll()
      end
   end,
})

NoclipTab:CreateSlider({
   Name = "Radius",
   Range = {50, 2000},
   Increment = 25,
   CurrentValue = Flags["Noclip/Radius"],
   Flag = "NoclipRadius",
   Callback = function(Value) Flags["Noclip/Radius"] = Value end,
})

NoclipTab:CreateToggle({
   Name = "Include Anchored (Walls)",
   CurrentValue = Flags["Noclip/IncludeAnchored"],
   Flag = "NoclipAnchored",
   Callback = function(Value) Flags["Noclip/IncludeAnchored"] = Value end,
})

NoclipTab:CreateToggle({
   Name = "Include Unanchored (Objects)",
   CurrentValue = Flags["Noclip/IncludeUnanchored"],
   Flag = "NoclipUnanchored",
   Callback = function(Value) Flags["Noclip/IncludeUnanchored"] = Value end,
})

NoclipTab:CreateButton({
   Name = "Force Rescan Now",
   Callback = function()
      if Flags["Noclip/Enabled"] then
          task.spawn(function()
              ScanAndBreak()
              Rayfield:Notify({Title = "Noclip", Content = "Rescan done. Broken: " .. tostring(Noclip.BrokenCount), Duration = 2})
          end)
      else
          Rayfield:Notify({Title = "Noclip", Content = "Enable Noclip first.", Duration = 2})
      end
   end,
})

NoclipTab:CreateButton({
   Name = "Restore All Walls",
   Callback = function()
      RestoreAll()
      Rayfield:Notify({Title = "Noclip", Content = "All walls restored.", Duration = 2})
   end,
})

HitboxTab:CreateSection("Hitbox Expander")
HitboxTab:CreateToggle({
   Name = "Enable Hitbox Expander",
   CurrentValue = Flags["Hitbox/Enabled"],
   Flag = "HitboxToggle",
   Callback = function(Value)
      Flags["Hitbox/Enabled"] = Value
      if Value then HitboxRefreshAll() else HitboxRestoreAll() end
   end,
})

HitboxTab:CreateSlider({
   Name = "Hitbox Size",
   Range = {1, 200},
   Increment = 1,
   CurrentValue = Flags["Hitbox/Size"],
   Flag = "HitboxSize",
   Callback = function(Value)
      Flags["Hitbox/Size"] = Value
      if Flags["Hitbox/Enabled"] then HitboxRefreshAll() end
   end,
})

HitboxTab:CreateSlider({
   Name = "Transparency",
   Range = {0, 1},
   Increment = 0.05,
   CurrentValue = Flags["Hitbox/Transparency"],
   Flag = "HitboxTrans",
   Callback = function(Value)
      Flags["Hitbox/Transparency"] = Value
      if Flags["Hitbox/Enabled"] then HitboxRefreshAll() end
   end,
})

HitboxTab:CreateToggle({
   Name = "Expand All Body Parts",
   CurrentValue = Flags["Hitbox/AllParts"],
   Flag = "HitboxAllParts",
   Callback = function(Value)
      Flags["Hitbox/AllParts"] = Value
      if Flags["Hitbox/Enabled"] then HitboxRefreshAll() end
   end,
})

HitboxTab:CreateToggle({
   Name = "Include Local Character",
   CurrentValue = Flags["Hitbox/IncludeSelf"],
   Flag = "HitboxSelf",
   Callback = function(Value)
      Flags["Hitbox/IncludeSelf"] = Value
      if Flags["Hitbox/Enabled"] then HitboxRefreshAll() end
   end,
})

HitboxTab:CreateToggle({
   Name = "Show Visualizer Highlight",
   CurrentValue = Flags["Hitbox/Visualizer"],
   Flag = "HitboxViz",
   Callback = function(Value)
      Flags["Hitbox/Visualizer"] = Value
      if Flags["Hitbox/Enabled"] then HitboxRefreshAll() end
   end,
})

TeleportTab:CreateSection("Preset Locations")
for _, loc in ipairs(TELEPORT_PRESETS) do
   TeleportTab:CreateButton({
      Name = loc.name,
      Callback = function()
         TeleportToPosition(loc.pos)
      end,
   })
end

TeleportTab:CreateSection("Save Current Location")
local savedLocationInputName = ""
TeleportTab:CreateInput({
   Name = "Location Name",
   PlaceholderText = "Enter location name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      savedLocationInputName = Text
   end,
})

TeleportTab:CreateButton({
   Name = "Save Current Location",
   Callback = function()
      local name = savedLocationInputName
      name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
      if name == "" then
          Rayfield:Notify({Title = "Teleport", Content = "Please enter a location name.", Duration = 2})
          return
      end
      local pos = GetCurrentPosition()
      if not pos then
          Rayfield:Notify({Title = "Teleport", Content = "Could not read current position.", Duration = 2})
          return
      end
      SavedLocations[name] = { X = pos.X, Y = pos.Y, Z = pos.Z }
      SaveLocationsToDisk()
      Rayfield:Notify({Title = "Teleport", Content = string.format("Saved '%s'", name), Duration = 2})
   end,
})

GoToTab:CreateSection("Players List & Teleport")
GoToTab:CreateButton({
   Name = "Refresh Players List",
   Callback = function()
      Rayfield:Notify({Title = "Go-To", Content = "Players list active.", Duration = 2})
   end,
})

AutoGiveTab:CreateSection("Auto-Give Guns")
AutoGiveTab:CreateToggle({
   Name = "Enable Auto-Give (MP5 + Remington)",
   CurrentValue = Flags["AutoGive/Enabled"],
   Flag = "AutoGiveToggle",
   Callback = function(Value)
      Flags["AutoGive/Enabled"] = Value
      if Value then task.spawn(function() SpawnTouchGiversInFront() end) end
   end,
})

AutoGiveTab:CreateButton({
   Name = "Visit TouchGivers Now",
   Callback = function()
      task.spawn(function() SpawnTouchGiversInFront(true) end)
      Rayfield:Notify({Title = "Auto-Give", Content = "Visited TouchGivers.", Duration = 2})
   end,
})

ArrestTab:CreateSection("Arrest System")
ArrestTab:CreateToggle({
   Name = "Enable Arrest Stick",
   CurrentValue = Flags["Arrest/Enabled"],
   Flag = "ArrestToggle",
   Callback = function(Value) Flags["Arrest/Enabled"] = Value end,
})

ArrestTab:CreateSlider({
   Name = "Stick Distance (Behind)",
   Range = {0.5, 20},
   Increment = 0.5,
   CurrentValue = Flags["Arrest/StickDistance"],
   Flag = "ArrestDist",
   Callback = function(Value) Flags["Arrest/StickDistance"] = Value end,
})

ArrestTab:CreateSlider({
   Name = "Stick Duration",
   Range = {0.5, 60},
   Increment = 0.5,
   CurrentValue = Flags["Arrest/StickDuration"],
   Flag = "ArrestDur",
   Callback = function(Value) Flags["Arrest/StickDuration"] = Value end,
})

ArrestTab:CreateButton({
   Name = "Stop Sticking",
   Callback = function()
      StopArrestStick()
   end,
})

RunService.Heartbeat:Connect(function()
    if Flags["ESP/Enabled"] then
        RefreshESP()
    end

    if Flags["Noclip/Enabled"] then
        ScanAndBreak()
        EnforceNoclip()
    end

    ApplyHumanoidSettings()
end)

RunService.RenderStepped:Connect(function()
    UpdateAim()
    UpdateESP2D()
end)

Players.PlayerAdded:Connect(function(player) UpdatePlayerCache() end)
Players.PlayerRemoving:Connect(function(player)
    UpdatePlayerCache()
    RemoveNametag(player)
    RemoveESP2D(player)
    if player.Character then HitboxRestoreCharacter(player.Character) end
    CharCache[player] = nil
end)

UpdatePlayerCache()

if LocalPlayer.Character then
    task.spawn(function()
        task.wait(1)
        CaptureHumanoidSettings()
    end)
end

Rayfield:Notify({
   Title = "YH Script | Prison Life",
   Content = "Loaded successfully with all features!",
   Duration = 5,
   Image = 4483362458,
})

