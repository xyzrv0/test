local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Attrixx/FreeScripts/main/YTUILib1.lua"))():init("Combat Arena")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local DrawingESP = {}

-- Chams settings
local chamsEnabled = false
local chamsTransparency = 0.5
local chamsColor = Color3.fromRGB(255, 0, 0)
local chamsType = "Glow"
local visibleOnlyMode = false

-- ESP settings
local espEnabled = false
local espColor = Color3.fromRGB(255, 0, 0)
local maxBoxSize = Vector2.new(80, 120)
local minBoxSize = Vector2.new(20, 40)
local maxESPDistance = 150

-- Utility: check visibility
local function isPlayerVisible(player)
    local character = player.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local cam = Workspace.CurrentCamera
    if not hrp or not cam then return false end

    local origin = cam.CFrame.Position
    local direction = (hrp.Position - origin).Unit * (hrp.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        return raycastResult.Instance:IsDescendantOf(character)
    else
        return true
    end
end

-- Chams
local function applyChamsToPlayer(player)
    if player == LocalPlayer then return end

    local character = player.Character
    if not character then return end

    local highlight = character:FindFirstChild("ChamsHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ChamsHighlight"
        highlight.Adornee = character
        highlight.Parent = character
    end

    if visibleOnlyMode and not isPlayerVisible(player) then
        highlight.Enabled = false
        return
    else
        highlight.Enabled = chamsEnabled
    end

    if chamsType == "Glow" then
        highlight.FillColor = chamsColor
        highlight.FillTransparency = chamsTransparency
        highlight.OutlineColor = chamsColor
        highlight.OutlineTransparency = chamsTransparency
    elseif chamsType == "Outline" then
        highlight.FillColor = chamsColor
        highlight.FillTransparency = 0.9
        highlight.OutlineColor = chamsColor
        highlight.OutlineTransparency = chamsTransparency
    end
end

local function removeChamsFromPlayer(player)
    local character = player.Character
    if character then
        local highlight = character:FindFirstChild("ChamsHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

local function updateAllChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if chamsEnabled then
                applyChamsToPlayer(player)
            else
                removeChamsFromPlayer(player)
            end
        end
    end
end

-- ESP Drawing
local function createBox(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = espColor
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false

    local outline = Drawing.new("Square")
    outline.Visible = false
    outline.Color = Color3.new(0,0,0)
    outline.Thickness = 2
    outline.Transparency = 1
    outline.Filled = false

    DrawingESP[player] = {box = box, outline = outline}
end

local function removeBox(player)
    if DrawingESP[player] then
        DrawingESP[player].box:Remove()
        DrawingESP[player].outline:Remove()
        DrawingESP[player] = nil
    end
end

local function updateBox(player)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    local cam = Workspace.CurrentCamera
    local drawingData = DrawingESP[player]

    if not (character and hrp and humanoid and humanoid.Health > 0 and cam and drawingData) then
        if drawingData then
            drawingData.box.Visible = false
            drawingData.outline.Visible = false
        end
        return
    end

    local distance = (cam.CFrame.Position - hrp.Position).Magnitude
    if distance > maxESPDistance then
        drawingData.box.Visible = false
        drawingData.outline.Visible = false
        return
    end

    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        drawingData.box.Visible = false
        drawingData.outline.Visible = false
        return
    end

    local distanceRatio = math.clamp(1 - (distance / maxESPDistance), 0, 1)
    local sizeX = minBoxSize.X + (maxBoxSize.X - minBoxSize.X) * distanceRatio
    local sizeY = minBoxSize.Y + (maxBoxSize.Y - minBoxSize.Y) * distanceRatio
    local size = Vector2.new(sizeX, sizeY)
    local topLeft = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)

    drawingData.box.Size = size
    drawingData.box.Position = topLeft
    drawingData.box.Color = espColor
    drawingData.box.Visible = espEnabled

    drawingData.outline.Size = size + Vector2.new(4, 4)
    drawingData.outline.Position = topLeft - Vector2.new(2, 2)
    drawingData.outline.Visible = espEnabled
end

-- ESP update loop
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not DrawingESP[player] then
                createBox(player)
            end
            if espEnabled then
                updateBox(player)
            else
                DrawingESP[player].box.Visible = false
                DrawingESP[player].outline.Visible = false
            end
        end
    end
end)

-- Player Events
Players.PlayerRemoving:Connect(function(player)
    removeBox(player)
    removeChamsFromPlayer(player)
end)

-- Handles chams/ESP when player joins or respawns
local function setupPlayer(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function()
        task.wait(1)
        if chamsEnabled then applyChamsToPlayer(player) end
        if not DrawingESP[player] then createBox(player) end
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

-- UI Setup
local Tab = Library:Tab("Visuals")
local ChamSection = Tab:Section("Chams")

ChamSection:Toggle("Enable Chams", false, function(v)
    chamsEnabled = v
    updateAllChams()
end)

ChamSection:Slider("Chams Transparency", 0, 50, 100, function(v)
    chamsTransparency = 1 - (v / 100)
    updateAllChams()
end)

ChamSection:Dropdown("Chams Color", {"Red", "Orange", "Yellow", "Green", "Teal", "Cyan", "Hot Pink", "Purple", "White", "Black"}, "Red", function(v)
    local colors = {
        Red = Color3.fromRGB(255,0,0),
        Orange = Color3.fromRGB(255,165,0),
        Yellow = Color3.fromRGB(255,255,0),
        Green = Color3.fromRGB(50,205,50),
        Teal = Color3.fromRGB(102,255,204),
        Cyan = Color3.fromRGB(0,255,255),
        ["Hot Pink"] = Color3.fromRGB(255,20,147),
        Purple = Color3.fromRGB(128,0,128),
        White = Color3.fromRGB(255,255,255),
        Black = Color3.fromRGB(0,0,0),
    }
    chamsColor = colors[v] or chamsColor
    updateAllChams()
end)

ChamSection:Dropdown("Chams Type", {"Glow", "Outline"}, "Glow", function(v)
    chamsType = v
    updateAllChams()
end)

ChamSection:Toggle("Visible Only", false, function(v)
    visibleOnlyMode = v
    updateAllChams()
end)

-- ESP Section
local ESPSection = Tab:Section("ESP")

ESPSection:Toggle("Enable ESP", false, function(v)
    espEnabled = v
end)

ESPSection:Dropdown("ESP Color", {"Red", "Orange", "Yellow", "Green", "Teal", "Cyan", "Hot Pink", "Purple", "White", "Black"}, "Red", function(v)
    local colors = {
        Red = Color3.fromRGB(255,0,0),
        Orange = Color3.fromRGB(255,165,0),
        Yellow = Color3.fromRGB(255,255,0),
        Green = Color3.fromRGB(50,205,50),
        Teal = Color3.fromRGB(102,255,204),
        Cyan = Color3.fromRGB(0,255,255),
        ["Hot Pink"] = Color3.fromRGB(255,20,147),
        Purple = Color3.fromRGB(128,0,128),
        White = Color3.fromRGB(255,255,255),
        Black = Color3.fromRGB(0,0,0),
    }
    espColor = colors[v] or espColor
end)

-- UI toggle (Insert key)
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        for _, ui in ipairs(CoreGui:GetChildren()) do
            if ui:IsA("ScreenGui") and ui.Name == "Combat Arena" then
                ui.Enabled = not ui.Enabled
            end
        end
    end
end)
