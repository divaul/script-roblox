-- Avatar + Accessory Copier with polished UI
-- LocalScript: letakkan di StarterGui atau jalankan via loadstring(game:HttpGet("RAW_URL"))()
-- Fitur: draggable titlebar, minimize, close, rapi & modern UI, copy avatar + accessories (from luar server)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("Script harus dijalankan sebagai LocalScript (client).")
    return
end

-- Safely remove old GUI if present
if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MoziIHub_AvatarCopier") then
    LocalPlayer.PlayerGui.MoziIHub_AvatarCopier:Destroy()
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MoziIHub_AvatarCopier"
    screenGui.DisplayOrder = 1000
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 460, 0, 220)
    mainFrame.Position = UDim2.new(0.5, -230, 0.12, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 23)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = mainFrame

    -- subtle outline
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(40, 40, 45)
    frameStroke.Transparency = 0
    frameStroke.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Text = "Avatar & Accessory Copier"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextColor3 = Color3.fromRGB(240,240,240)
    titleText.BackgroundTransparency = 1
    titleText.Size = UDim2.new(0.7, -12, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- small subtitle
    local subText = Instance.new("TextLabel")
    subText.Name = "Sub"
    subText.Text = "copy humanoid description & accessories — works with users outside the map"
    subText.Font = Enum.Font.Gotham
    subText.TextSize = 12
    subText.TextColor3 = Color3.fromRGB(170,170,180)
    subText.BackgroundTransparency = 1
    subText.Size = UDim2.new(0.9, -12, 0, 16)
    subText.Position = UDim2.new(0, 12, 1, -18)
    subText.TextXAlignment = Enum.TextXAlignment.Left
    subText.Parent = titleBar

    -- Right-side action buttons (minimize & close)
    local function makeTitleButton(symbol, name)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 34, 0, 24)
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, -8 - ((name == "Close") and 0 or 40), 0.5, 0)
        btn.BackgroundTransparency = 0.12
        btn.BackgroundColor3 = Color3.fromRGB(36, 39, 46)
        btn.Text = symbol
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 18
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.Parent = titleBar
        local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0,6)
        local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(28,28,30); stroke.Transparency = 0.5
        return btn
    end

    local minimizeBtn = makeTitleButton("—", "Minimize")
    local closeBtn = makeTitleButton("✕", "Close")

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 0
    content.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
    content.BorderSizePixel = 0
    content.Size = UDim2.new(1, -24, 1, -56)
    content.Position = UDim2.new(0, 12, 0, 44)
    content.Parent = mainFrame
    local contentCorner = Instance.new("UICorner", content); contentCorner.CornerRadius = UDim.new(0,10)

    -- Layout inside content
    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,10)

    -- Top row: Input + Copy Button
    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, 0, 0, 48)
    topRow.BackgroundTransparency = 1
    topRow.LayoutOrder = 1
    topRow.Parent = content

    local inputBox = Instance.new("TextBox")
    inputBox.Name = "Input"
    inputBox.PlaceholderText = "username OR profile link OR userId"
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 16
    inputBox.ClearTextOnFocus = false
    inputBox.BackgroundColor3 = Color3.fromRGB(14,17,22)
    inputBox.Size = UDim2.new(0.66, 0, 1, 0)
    inputBox.Position = UDim2.new(0,0,0,0)
    inputBox.TextColor3 = Color3.fromRGB(230,230,230)
    inputBox.Parent = topRow
    local inpCorner = Instance.new("UICorner", inputBox); inpCorner.CornerRadius = UDim.new(0,8)
    local inpStroke = Instance.new("UIStroke", inputBox); inpStroke.Color = Color3.fromRGB(36,36,40); inpStroke.Transparency = 0.6

    local copyBtn = Instance.new("TextButton")
    copyBtn.Name = "CopyBtn"
    copyBtn.Text = "Copy Avatar"
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 16
    copyBtn.Size = UDim2.new(0.32, -8, 1, 0)
    copyBtn.Position = UDim2.new(0.68, 8, 0, 0)
    copyBtn.BackgroundColor3 = Color3.fromRGB(42, 120, 217)
    copyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    copyBtn.Parent = topRow
    local copyCorner = Instance.new("UICorner", copyBtn); copyCorner.CornerRadius = UDim.new(0,8)

    -- Middle row: toggles
    local midRow = Instance.new("Frame")
    midRow.Size = UDim2.new(1, 0, 0, 56)
    midRow.BackgroundTransparency = 1
    midRow.LayoutOrder = 2
    midRow.Parent = content

    local function makeToggle(parent, x, y, labelText, initial)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.5, -8, 1, 0)
        container.Position = UDim2.new(x, 0, y, 0)
        container.BackgroundTransparency = 1
        container.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.68, 0, 1, 0)
        lbl.Position = UDim2.new(0,0,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.Text = labelText
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.28, 0, 0.62, 0)
        btn.Position = UDim2.new(0.72, -4, 0.19, 0)
        btn.BackgroundColor3 = initial and Color3.fromRGB(34,170,92) or Color3.fromRGB(120,32,32)
        btn.Text = initial and "ON" or "OFF"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(240,240,240)
        btn.Parent = container
        local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0,6)

        return {Label = lbl, Button = btn}
    end

    local t1 = makeToggle(midRow, 0, 0, "Copy Accessories", true)
    local t2 = makeToggle(midRow, 0.5, 0, "Clear Current Accessories", true)

    -- Mode selector
    local modeRow = Instance.new("Frame")
    modeRow.Size = UDim2.new(1,0,0,34)
    modeRow.BackgroundTransparency = 1
    modeRow.LayoutOrder = 3
    modeRow.Parent = content

    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0.6,0,1,0)
    modeLabel.Position = UDim2.new(0,0,0,0)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.Text = "Mode: Full Avatar"
    modeLabel.TextSize = 14
    modeLabel.TextColor3 = Color3.fromRGB(200,200,200)
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = modeRow

    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.36,0,1,0)
    modeBtn.Position = UDim2.new(0.64,0,0,0)
    modeBtn.Text = "Toggle Mode"
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 14
    modeBtn.BackgroundColor3 = Color3.fromRGB(60,60,66)
    modeBtn.TextColor3 = Color3.fromRGB(240,240,240)
    modeBtn.Parent = modeRow
    local modeCorner = Instance.new("UICorner", modeBtn); modeCorner.CornerRadius = UDim.new(0,8)

    -- Status row
    local statusRow = Instance.new("Frame")
    statusRow.Size = UDim2.new(1,0,0,36)
    statusRow.BackgroundTransparency = 1
    statusRow.LayoutOrder = 4
    statusRow.Parent = content

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1,0,1,0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Ready"
    statusLabel.TextSize = 14
    statusLabel.TextColor3 = Color3.fromRGB(190,190,190)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusRow

    -- Small hint
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1,0,0,18)
    hintLabel.BackgroundTransparency = 1
    hintLabel.LayoutOrder = 5
    hintLabel.Font = Enum.Font.Gotham
    hintLabel.TextSize = 12
    hintLabel.TextColor3 = Color3.fromRGB(150,150,160)
    hintLabel.Text = 'Usage: username OR "https://www.roblox.com/users/123/profile" OR id'
    hintLabel.Parent = content

    -- Attach everything
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Return references for logic
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        TitleBar = titleBar,
        Minimize = minimizeBtn,
        Close = closeBtn,
        Content = content,
        Input = inputBox,
        CopyBtn = copyBtn,
        Toggle_CopyAccessories = t1.Button,
        Toggle_ClearAccessories = t2.Button,
        ModeBtn = modeBtn,
        ModeLabel = modeLabel,
        StatusLabel = statusLabel,
    }
end

-- Helper: draggable titlebar
local function makeDraggable(frame, dragGui)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragGui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragGui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Parsing input
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

-- Accessories helper
local function clearAccessoriesFromCharacter(character)
    if not character then return end
    for _, c in ipairs(character:GetChildren()) do
        if c:IsA("Accessory") then c:Destroy() end
    end
end

local function addAccessoriesFromModelToHumanoid(model, targetHumanoid)
    if not model or not targetHumanoid then return false, "Model atau humanoid invalid" end
    local added = 0
    for _, obj in ipairs(model:GetChildren()) do
        if obj:IsA("Accessory") then
            local ok, err = pcall(function()
                local clone = obj:Clone()
                targetHumanoid:AddAccessory(clone)
            end)
            if ok then added = added + 1 end
        end
    end
    return true, ("Accessories added: %d"):format(added)
end

local function applyHumanoidDescription(desc)
    if not desc then return false, "HumanoidDescription kosong" end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, "Humanoid tidak ditemukan" end
    local ok, err = pcall(function() humanoid:ApplyDescription(desc) end)
    if not ok then return false, ("Gagal apply description: %s"):format(tostring(err)) end
    return true, "HumanoidDescription diterapkan"
end

-- Main copy logic
local function copyAvatarAndAccessories(userInput, uiRefs)
    uiRefs.StatusLabel.Text = "Memproses..."
    local userId, perr = parseInputToUserId(userInput)
    if not userId then uiRefs.StatusLabel.Text = "Error: "..(perr or "invalid input"); return end

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then uiRefs.StatusLabel.Text = "Error: Humanoid lokal tidak ditemukan"; return end

    local copyAccessories = (uiRefs.Toggle_CopyAccessories.Text == "ON")
    local clearAccessories = (uiRefs.Toggle_ClearAccessories.Text == "ON")
    local modeFull = (uiRefs.ModeLabel.Text:match("Full"))

    if modeFull then
        uiRefs.StatusLabel.Text = "Mengambil HumanoidDescription..."
        local okDesc, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
        if okDesc and desc then
            local applied, msg = applyHumanoidDescription(desc)
            uiRefs.StatusLabel.Text = applied and "HumanoidDescription diterapkan." or ("Warning: "..tostring(msg))
        else
            uiRefs.StatusLabel.Text = "Gagal mengambil HumanoidDescription; melanjutkan ke accessories..."
        end
    end

    if copyAccessories then
        uiRefs.StatusLabel.Text = "Mengambil appearance & accessories..."
        local okModel, modelOrErr = pcall(function() return Players:GetCharacterAppearanceAsync(userId) end)
        if not okModel or not modelOrErr then
            uiRefs.StatusLabel.Text = "Gagal mendapatkan appearance: "..tostring(modelOrErr)
            return
        end

        if clearAccessories then
            uiRefs.StatusLabel.Text = "Menghapus accessories lokal..."
            pcall(function() clearAccessoriesFromCharacter(character) end)
        end

        uiRefs.StatusLabel.Text = "Menambahkan accessories ke karakter..."
        local okAdd, addMsg = pcall(function() return addAccessoriesFromModelToHumanoid(modelOrErr, humanoid) end)
        if okAdd then uiRefs.StatusLabel.Text = "Selesai: "..tostring(addMsg)
        else uiRefs.StatusLabel.Text = "Gagal menambahkan accessories: "..tostring(addMsg) end
    else
        if not modeFull then
            uiRefs.StatusLabel.Text = "Mode AccessoriesOnly tapi Copy Accessories OFF — tidak ada yang dilakukan."
        else
            uiRefs.StatusLabel.Text = "Selesai (accessories di-skip)."
        end
    end
end

-- Build UI and wire interactions
local ui = createUI()

-- Make draggable
makeDraggable(ui.MainFrame, ui.TitleBar)

-- Minimize behavior using tween
local minimized = false
local content = ui.Content
local fullSize = ui.MainFrame.Size
local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

ui.Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        ui.Minimize.Text = "+"
        local t = TweenService:Create(content, tweenInfo, {Size = UDim2.new(1, -24, 0, 0)})
        t:Play()
        ui.MainFrame.Size = UDim2.new(ui.MainFrame.Size.X.Scale, ui.MainFrame.Size.X.Offset, 0, 64)
    else
        ui.Minimize.Text = "—"
        local t = TweenService:Create(content, tweenInfo, {Size = UDim2.new(1, -24, 1, -56)})
        t:Play()
        ui.MainFrame.Size = fullSize
    end
end)

ui.Close.MouseButton1Click:Connect(function()
    if ui.ScreenGui and ui.ScreenGui.Parent then ui.ScreenGui:Destroy() end
end)

-- Toggle buttons logic
local function flipToggle(btn)
    local isOn = (btn.Text == "ON")
    if isOn then
        btn.Text = "OFF"
        btn.BackgroundColor3 = Color3.fromRGB(120,32,32)
    else
        btn.Text = "ON"
        btn.BackgroundColor3 = Color3.fromRGB(34,170,92)
    end
end

ui.Toggle_CopyAccessories.MouseButton1Click:Connect(function() flipToggle(ui.Toggle_CopyAccessories) end)
ui.Toggle_ClearAccessories.MouseButton1Click:Connect(function() flipToggle(ui.Toggle_ClearAccessories) end)

-- Mode toggle
ui.ModeBtn.MouseButton1Click:Connect(function()
    if ui.ModeLabel.Text:match("Full") then
        ui.ModeLabel.Text = "Mode: Accessories Only"
    else
        ui.ModeLabel.Text = "Mode: Full Avatar"
    end
end)

-- Copy button action
ui.CopyBtn.MouseButton1Click:Connect(function()
    ui.CopyBtn.Active = false
    local prevText = ui.CopyBtn.Text
    ui.CopyBtn.Text = "Processing..."
    local ok, err = pcall(function()
        copyAvatarAndAccessories(ui.Input.Text, ui)
    end)
    if not ok then ui.StatusLabel.Text = "Terjadi error: "..tostring(err) end
    ui.CopyBtn.Text = prevText
    ui.CopyBtn.Active = true
end)

-- Auto-apply on respawn option: optional (commented - user can enable)
--[=[
LocalPlayer.CharacterAdded:Connect(function()
    -- Optionally re-apply last copied avatar here
end)
]=]

-- End of script
