-- Avatar + Accessory Copier (Full — Prefilled Target & Auto-Run)
-- LocalScript: letakkan di StarterGui atau host dan jalankan via loadstring(game:HttpGet("RAW_URL"))()
-- Tujuan: menyalin HumanoidDescription + Accessories dari target user (pre-filled) dengan optimasi fit & UI rapi (minimize/close), menyimpan lastCopiedUserId, dan opsi auto-run.
-- Target yang diminta: https://www.roblox.com/users/2678001507/profile
-- IMPORTANT: Jalankan ini sebagai LocalScript di client (StarterGui). Jangan gunakan untuk impersonasi di server publik.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("Script harus dijalankan sebagai LocalScript (client).")
    return
end

-- ----------------------
-- Configuration
-- ----------------------
local DEFAULT_TARGET = "https://www.roblox.com/users/8021014052/profile?friendshipSourceType=PlayerSearch" -- user yang diminta
local AUTO_RUN_ON_LOAD = true -- jika true, script akan otomatis mencoba copy target saat load (set false jika tidak mau auto-run)
local MAX_RETRIES_APPLY = 3

-- ----------------------
-- Helpers & Robustness
-- ----------------------
local function safeWaitForChild(parent, name, timeout)
    timeout = timeout or 4
    local t0 = tick()
    while tick() - t0 < timeout do
        local c = parent:FindFirstChild(name)
        if c then return c end
        RunService.Heartbeat:Wait()
    end
    return nil
end

local function tryPcall(fn)
    local ok, res = pcall(fn)
    if ok then return true, res end
    return false, res
end

-- Attachment map to create missing attachments to improve fit
local attachmentMap = {
    HatAttachment = "Head",
    HairAttachment = "Head",
    FaceFrontAttachment = "Head",
    FaceCenterAttachment = "Head",
    NeckAttachment = "UpperTorso",
    LeftShoulderAttachment = "LeftUpperArm",
    RightShoulderAttachment = "RightUpperArm",
    WaistCenterAttachment = "LowerTorso",
    WaistBackAttachment = "LowerTorso",
    RootAttachment = "HumanoidRootPart",
}

local function ensureAttachment(character, attName)
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local found = part:FindFirstChild(attName)
            if found and found:IsA("Attachment") then return found end
        end
    end
    local mapTo = attachmentMap[attName]
    if mapTo then
        local targetPart = character:FindFirstChild(mapTo)
        if not targetPart then
            -- try alternative names
            local alt = mapTo:gsub("UpperArm", "Arm")
            targetPart = character:FindFirstChild(alt)
        end
        if targetPart and targetPart:IsA("BasePart") then
            local att = Instance.new("Attachment")
            att.Name = attName
            att.Parent = targetPart
            return att
        end
    end
    return nil
end

local function waitAccessoryReady(accessory, timeout)
    timeout = timeout or 6
    local t0 = tick()
    while tick() - t0 < timeout do
        local handle = accessory:FindFirstChildWhichIsA("BasePart") or accessory:FindFirstChild("Handle")
        if handle then return true end
        RunService.Heartbeat:Wait()
    end
    return false
end

local function clearAccessoriesFromCharacter(character)
    if not character then return end
    for _, c in ipairs(character:GetChildren()) do
        if c:IsA("Accessory") then
            pcall(function() c:Destroy() end)
        end
    end
end

local function addAccessoriesFromModelToHumanoid(model, humanoid)
    if not model or not humanoid then return false, "Model or humanoid missing" end
    local character = humanoid.Parent
    local added = 0
    for _, obj in ipairs(model:GetChildren()) do
        if obj:IsA("Accessory") then
            local ok, err = pcall(function()
                local clone = obj:Clone()
                clone.Name = (clone.Name .. "_copied_") .. tostring(math.random(1000,9999))
                -- ensure attachments exist in target character for common names
                for _, att in ipairs(clone:GetDescendants()) do
                    if att:IsA("Attachment") then
                        pcall(function() ensureAttachment(character, att.Name) end)
                    end
                end
                waitAccessoryReady(clone)
                humanoid:AddAccessory(clone)
            end)
            if ok then added = added + 1 end
        end
    end
    return true, ("Accessories added: %d"):format(added)
end

local function applyHumanoidDescriptionOptimally(desc)
    if not desc then return false, "No HumanoidDescription" end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, "Local humanoid not found" end

    local lastErr
    for i = 1, MAX_RETRIES_APPLY do
        local ok, err = pcall(function() humanoid:ApplyDescription(desc) end)
        if ok then
            for _=1,8 do RunService.Heartbeat:Wait() end -- allow replication
            return true, "Applied HumanoidDescription"
        else
            lastErr = err
            RunService.Heartbeat:Wait()
        end
    end
    return false, ("Failed to apply HumanoidDescription: %s"):format(tostring(lastErr))
end

local function parseInputToUserId(input)
    input = tostring(input or ""):gsub("^%s*(.-)%s*$", "%1")
    if input == "" then return nil, "Input kosong" end
    local maybeId = tonumber(input)
    if maybeId then return maybeId, nil end
    local digits = input:match("(%d+)")
    if digits then return tonumber(digits), nil end
    local ok, res = pcall(function() return Players:GetUserIdFromNameAsync(input) end)
    if ok and type(res) == "number" then return res, nil end
    return nil, ("Gagal menemukan userId untuk username '%s'"):format(input)
end

-- ----------------------
-- UI (Polished: Minimize + Close)
-- ----------------------
local function createUI()
    -- If an old GUI exists, destroy it (safety)
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MoziIHub_AvatarCopier") then
        LocalPlayer.PlayerGui.MoziIHub_AvatarCopier:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MoziIHub_AvatarCopier"
    screenGui.DisplayOrder = 1000
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0,480,0,220)
    main.Position = UDim2.new(0.5,-240,0.12,0)
    main.AnchorPoint = Vector2.new(0.5,0)
    main.BackgroundColor3 = Color3.fromRGB(14,17,23)
    main.BorderSizePixel = 0
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(36,36,40); stroke.Transparency = 0.1

    -- Titlebar
    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1,0,0,44)
    titleBar.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(0.7, -12,1,0)
    title.Position = UDim2.new(0,12,0,0)
    title.Text = "Avatar & Accessory Copier — Optimized"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.BackgroundTransparency = 1

    local subtitle = Instance.new("TextLabel", titleBar)
    subtitle.Size = UDim2.new(0.98, -12,0,16)
    subtitle.Position = UDim2.new(0,12,1,-18)
    subtitle.Text = "Copy target: "..DEFAULT_TARGET..""
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = Color3.fromRGB(170,170,180)
    subtitle.BackgroundTransparency = 1
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimize & Close
    local function makeTitleBtn(sym, xOffset)
        local b = Instance.new("TextButton", titleBar)
        b.Size = UDim2.new(0,34,0,26)
        b.AnchorPoint = Vector2.new(1,0.5)
        b.Position = UDim2.new(1, xOffset, 0.5, 0)
        b.Text = sym
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 18
        b.BackgroundTransparency = 0.12
        b.BackgroundColor3 = Color3.fromRGB(36,39,46)
        b.TextColor3 = Color3.fromRGB(230,230,230)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        return b
    end

    local minimizeBtn = makeTitleBtn("—", -8)
    local closeBtn = makeTitleBtn("✕", -52)

    -- Content area
    local content = Instance.new("Frame", main)
    content.Size = UDim2.new(1,-24,1,-64)
    content.Position = UDim2.new(0,12,0,56)
    content.BackgroundColor3 = Color3.fromRGB(20,24,30)
    Instance.new("UICorner", content).CornerRadius = UDim.new(0,10)

    -- Input + copy button
    local input = Instance.new("TextBox", content)
    input.Size = UDim2.new(0.64, -8, 0, 40)
    input.Position = UDim2.new(0,8,0,8)
    input.PlaceholderText = "username | profile link | userId"
    input.Font = Enum.Font.Gotham
    input.TextSize = 16
    input.Text = DEFAULT_TARGET
    input.ClearTextOnFocus = false
    input.BackgroundColor3 = Color3.fromRGB(14,17,22)
    Instance.new("UICorner", input).CornerRadius = UDim.new(0,8)

    local copyBtn = Instance.new("TextButton", content)
    copyBtn.Size = UDim2.new(0.34, 0, 0, 40)
    copyBtn.Position = UDim2.new(0.66, 8, 0, 8)
    copyBtn.Text = "Copy Avatar"
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 16
    copyBtn.BackgroundColor3 = Color3.fromRGB(42,120,217)
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,8)

    -- Toggles
    local t1 = Instance.new("TextButton", content)
    t1.Size = UDim2.new(0.48, -6, 0, 32)
    t1.Position = UDim2.new(0,8,0,56)
    t1.Text = "Copy Accessories: ON"
    t1.Font = Enum.Font.Gotham
    Instance.new("UICorner", t1).CornerRadius = UDim.new(0,8)
    t1.BackgroundColor3 = Color3.fromRGB(34,170,92)

    local t2 = Instance.new("TextButton", content)
    t2.Size = UDim2.new(0.48, -6, 0, 32)
    t2.Position = UDim2.new(0.52, 0, 0, 56)
    t2.Text = "Clear Current: ON"
    t2.Font = Enum.Font.Gotham
    Instance.new("UICorner", t2).CornerRadius = UDim.new(0,8)
    t2.BackgroundColor3 = Color3.fromRGB(34,170,92)

    local optimizeBtn = Instance.new("TextButton", content)
    optimizeBtn.Size = UDim2.new(1, -16, 0, 32)
    optimizeBtn.Position = UDim2.new(0,8,0,100)
    optimizeBtn.Text = "Optimize Fit: ON"
    optimizeBtn.Font = Enum.Font.Gotham
    Instance.new("UICorner", optimizeBtn).CornerRadius = UDim.new(0,8)
    optimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,66)

    local status = Instance.new("TextLabel", content)
    status.Size = UDim2.new(1, -16, 0, 34)
    status.Position = UDim2.new(0,8,0,140)
    status.Text = "Ready"
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(200,200,200)
    status.BackgroundTransparency = 1

    -- Reapply & Save
    local reapplyBtn = Instance.new("TextButton", content)
    reapplyBtn.Size = UDim2.new(0.48, -6, 0, 30)
    reapplyBtn.Position = UDim2.new(0,8,1,-36)
    reapplyBtn.Text = "Reapply Last"
    reapplyBtn.Font = Enum.Font.Gotham
    Instance.new("UICorner", reapplyBtn).CornerRadius = UDim.new(0,8)
    reapplyBtn.BackgroundColor3 = Color3.fromRGB(46,46,52)

    local autoLabel = Instance.new("TextLabel", content)
    autoLabel.Size = UDim2.new(0.48, -6, 0, 30)
    autoLabel.Position = UDim2.new(0.52, 0, 1, -36)
    autoLabel.Text = "Auto-Run: " .. (AUTO_RUN_ON_LOAD and "ON" or "OFF")
    autoLabel.Font = Enum.Font.Gotham
    autoLabel.TextXAlignment = Enum.TextXAlignment.Right
    autoLabel.TextColor3 = Color3.fromRGB(160,160,160)
    autoLabel.BackgroundTransparency = 1

    return {
        ScreenGui = screenGui,
        Main = main,
        TitleBar = titleBar,
        Minimize = minimizeBtn,
        Close = closeBtn,
        Input = input,
        CopyBtn = copyBtn,
        ToggleCopyAccessories = t1,
        ToggleClear = t2,
        OptimizeBtn = optimizeBtn,
        Status = status,
        ReapplyBtn = reapplyBtn,
        AutoLabel = autoLabel,
    }
end

-- Draggable helper
local UserInputService = game:GetService("UserInputService")
local function makeDraggable(frame, dragArea)
    local dragging = false
    local dragStart, startPos
    local dragInput
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ----------------------
-- Core flow using the UI
-- ----------------------
local ui = createUI()
makeDraggable(ui.Main, ui.TitleBar)

-- Toggle behavior
local function flipTextBtn(btn, prefix)
    if btn.Text:find("ON") then
        btn.Text = prefix .. ": OFF"
        btn.BackgroundColor3 = Color3.fromRGB(120,32,32)
    else
        btn.Text = prefix .. ": ON"
        btn.BackgroundColor3 = Color3.fromRGB(34,170,92)
    end
end

ui.ToggleCopyAccessories.MouseButton1Click:Connect(function() flipTextBtn(ui.ToggleCopyAccessories, "Copy Accessories") end)
ui.ToggleClear.MouseButton1Click:Connect(function() flipTextBtn(ui.ToggleClear, "Clear Current") end)
ui.OptimizeBtn.MouseButton1Click:Connect(function()
    if ui.OptimizeBtn.Text:find("ON") then
        ui.OptimizeBtn.Text = "Optimize Fit: OFF"
        ui.OptimizeBtn.BackgroundColor3 = Color3.fromRGB(90,40,40)
    else
        ui.OptimizeBtn.Text = "Optimize Fit: ON"
        ui.OptimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,66)
    end
end)

-- Minimize & Close
local minimized = false
local fullSize = ui.Main.Size
ui.Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        ui.Minimize.Text = "+"
        ui.Main.Size = UDim2.new(ui.Main.Size.X.Scale, ui.Main.Size.X.Offset, 0, 64)
    else
        ui.Minimize.Text = "—"
        ui.Main.Size = fullSize
    end
end)
ui.Close.MouseButton1Click:Connect(function() if ui.ScreenGui and ui.ScreenGui.Parent then ui.ScreenGui:Destroy() end end)

-- storage for last copied
local lastCopiedUserId = nil

-- Main copy function
local function copyAvatarAndAccessoriesByInput(inputText)
    ui.Status.Text = "Parsing input..."
    local userId, perr = parseInputToUserId(inputText)
    if not userId then ui.Status.Text = "Error: "..(perr or "Invalid input"); return end

    lastCopiedUserId = userId
    ui.Status.Text = "Fetching HumanoidDescription..."

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then ui.Status.Text = "Error: Local humanoid not found"; return end

    local doCopyAccessories = ui.ToggleCopyAccessories.Text:find("ON") and true or false
    local doClear = ui.ToggleClear.Text:find("ON") and true or false
    local doOptimize = ui.OptimizeBtn.Text:find("ON") and true or false

    -- 1) HumanoidDescription
    local okDesc, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
    if okDesc and desc then
        ui.Status.Text = "Applying HumanoidDescription..."
        local applied, msg = applyHumanoidDescriptionOptimally(desc)
        ui.Status.Text = applied and "Description applied" or ("Apply failed: "..tostring(msg))
        if doOptimize then
            -- Attempt small waits & heuristics (ApplyDescription usually sufficient)
            for _=1,6 do RunService.Heartbeat:Wait() end
        end
    else
        ui.Status.Text = "Failed to fetch HumanoidDescription; will still try accessories."
    end

    -- 2) Accessories
    if doCopyAccessories then
        ui.Status.Text = "Fetching appearance & accessories..."
        local okModel, modelOrErr = pcall(function() return Players:GetCharacterAppearanceAsync(userId) end)
        if not okModel or not modelOrErr then
            ui.Status.Text = "Failed to fetch appearance: "..tostring(modelOrErr)
            return
        end

        if doClear then
            ui.Status.Text = "Clearing existing accessories..."
            pcall(function() clearAccessoriesFromCharacter(character) end)
        end

        ui.Status.Text = "Adding accessories..."
        local okAdd, addMsg = pcall(function() return addAccessoriesFromModelToHumanoid(modelOrErr, humanoid) end)
        if okAdd then ui.Status.Text = "Done: "..tostring(addMsg) else ui.Status.Text = "Add failed: "..tostring(addMsg) end
    else
        ui.Status.Text = "Accessory copy skipped by toggle."
    end
end

-- Bind UI
ui.CopyBtn.MouseButton1Click:Connect(function()
    ui.CopyBtn.Active = false
    local prev = ui.CopyBtn.Text
    ui.CopyBtn.Text = "Processing..."
    local ok, err = pcall(function() copyAvatarAndAccessoriesByInput(ui.Input.Text) end)
    if not ok then ui.Status.Text = "Unexpected error: "..tostring(err) end
    ui.CopyBtn.Text = prev
    ui.CopyBtn.Active = true
end)

ui.ReapplyBtn.MouseButton1Click:Connect(function()
    if lastCopiedUserId then
        ui.Status.Text = "Reapplying last copied avatar..."
        copyAvatarAndAccessoriesByInput(tostring(lastCopiedUserId))
    else
        ui.Status.Text = "No last copied user saved yet."
    end
end)

-- Auto-run on load if configured
if AUTO_RUN_ON_LOAD then
    spawn(function()
        -- small delay to ensure PlayerGui ready and character loaded
        wait(0.6)
        if ui and ui.Input then ui.Input.Text = DEFAULT_TARGET end
        wait(0.8)
        pcall(function()
            ui.Status.Text = "Auto-run: copying target..."
            copyAvatarAndAccessoriesByInput(DEFAULT_TARGET)
        end)
    end)
end

-- End of script
