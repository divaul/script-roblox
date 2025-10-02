--== Avatar + Accessory Copier (LocalScript) ==--
-- Usage: host raw and run with loadstring(game:HttpGet("RAW_URL"))()
-- Put/run this as a LocalScript (StarterGui or loaded via executor)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("Script must run in a client (LocalScript) context.")
    return
end

-- UI builder (expanded with toggles)
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AvatarCopierUI"
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame", screenGui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 420, 0, 190)
    frame.Position = UDim2.new(0.5, -210, 0.12, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(24,24,24)
    frame.BorderSizePixel = 0
    local uiCorner = Instance.new("UICorner", frame); uiCorner.CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "Avatar & Accessory Copier"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    local inputBox = Instance.new("TextBox", frame)
    inputBox.Size = UDim2.new(1, -20, 0, 36)
    inputBox.Position = UDim2.new(0, 10, 0, 48)
    inputBox.PlaceholderText = "Masukkan username / profile link / userId"
    inputBox.Text = ""
    inputBox.Font = Enum.Font.SourceSans
    inputBox.TextSize = 18
    inputBox.ClearTextOnFocus = false
    inputBox.BackgroundTransparency = 0.15
    inputBox.BackgroundColor3 = Color3.fromRGB(16,16,16)
    inputBox.TextColor3 = Color3.fromRGB(240,240,240)
    inputBox.TextXAlignment = Enum.TextXAlignment.Left

    local copyBtn = Instance.new("TextButton", frame)
    copyBtn.Size = UDim2.new(0, 150, 0, 36)
    copyBtn.Position = UDim2.new(0, 10, 0, 96)
    copyBtn.Text = "Copy Avatar"
    copyBtn.Font = Enum.Font.SourceSansBold
    copyBtn.TextSize = 18
    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
    copyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local btnCorner = Instance.new("UICorner", copyBtn)

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -180, 0, 36)
    status.Position = UDim2.new(0, 170, 0, 96)
    status.Text = "Ready"
    status.Font = Enum.Font.SourceSans
    status.TextSize = 16
    status.TextColor3 = Color3.fromRGB(200,200,200)
    status.BackgroundTransparency = 1
    status.TextXAlignment = Enum.TextXAlignment.Left

    -- Toggles: Copy Accessories, Clear existing accessories, Mode
    local function makeToggle(labelText, posX, posY)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0, 180, 0, 20)
        lbl.Position = UDim2.new(0, posX, 0, posY)
        lbl.Text = labelText
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 60, 0, 20)
        btn.Position = UDim2.new(0, posX + 190, 0, posY)
        btn.Text = "ON"
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(30,150,50)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        local corner = Instance.new("UICorner", btn)
        return lbl, btn
    end

    local lbl1, toggleAccessories = makeToggle("Copy Accessories", 10, 140)
    local lbl2, toggleClear = makeToggle("Clear Current Accessories", 220, 140)

    -- Mode dropdown-ish (simple button cycle)
    local modeLabel = Instance.new("TextLabel", frame)
    modeLabel.Size = UDim2.new(0, 200, 0, 18)
    modeLabel.Position = UDim2.new(0, 10, 0, 73)
    modeLabel.Text = "Mode: Full Avatar"
    modeLabel.Font = Enum.Font.SourceSans
    modeLabel.TextSize = 14
    modeLabel.TextColor3 = Color3.fromRGB(200,200,200)
    modeLabel.BackgroundTransparency = 1
    modeLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- initial states
    local state = {
        copyAccessories = true,
        clearAccessories = true,
        mode = "Full", -- "Full" or "AccessoriesOnly"
    }

    toggleAccessories.MouseButton1Click:Connect(function()
        state.copyAccessories = not state.copyAccessories
        toggleAccessories.Text = state.copyAccessories and "ON" or "OFF"
        toggleAccessories.BackgroundColor3 = state.copyAccessories and Color3.fromRGB(30,150,50) or Color3.fromRGB(140,30,30)
    end)
    toggleClear.MouseButton1Click:Connect(function()
        state.clearAccessories = not state.clearAccessories
        toggleClear.Text = state.clearAccessories and "ON" or "OFF"
        toggleClear.BackgroundColor3 = state.clearAccessories and Color3.fromRGB(30,150,50) or Color3.fromRGB(140,30,30)
    end)

    -- mode toggle (small button on title)
    local modeBtn = Instance.new("TextButton", frame)
    modeBtn.Size = UDim2.new(0, 110, 0, 20)
    modeBtn.Position = UDim2.new(1, -120, 0, 12)
    modeBtn.AnchorPoint = Vector2.new(1, 0)
    modeBtn.Text = "Mode: Full"
    modeBtn.Font = Enum.Font.SourceSans
    modeBtn.TextSize = 14
    modeBtn.BackgroundTransparency = 0.15
    modeBtn.TextColor3 = Color3.fromRGB(220,220,220)
    local mbCorner = Instance.new("UICorner", modeBtn)
    modeBtn.MouseButton1Click:Connect(function()
        if state.mode == "Full" then
            state.mode = "AccessoriesOnly"
            modeBtn.Text = "Mode: Accessories"
        else
            state.mode = "Full"
            modeBtn.Text = "Mode: Full"
        end
    end)

    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return {
        ScreenGui = screenGui,
        Input = inputBox,
        Button = copyBtn,
        Status = status,
        State = state
    }
end

-- Parse input like previous script
local function parseInputToUserId(input)
    input = tostring(input):gsub("^%s*(.-)%s*$", "%1")
    if input == "" then return nil, "Input kosong" end
    local maybeId = tonumber(input)
    if maybeId then return maybeId, nil end
    local digits = input:match("(%d+)")
    if digits then return tonumber(digits), nil end
    local ok, res = pcall(function() return Players:GetUserIdFromNameAsync(input) end)
    if ok and type(res) == "number" then return res, nil
    else return nil, ("Gagal menemukan userId untuk username '%s'"):format(input) end
end

-- Remove accessory instances from a character
local function clearAccessoriesFromCharacter(character)
    if not character then return end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") then
            child:Destroy()
        end
    end
end

-- Add accessories from a model (result of GetCharacterAppearanceAsync) to target humanoid
local function addAccessoriesFromModelToHumanoid(model, targetHumanoid)
    if not model or not targetHumanoid then return false, "Model atau humanoid invalid" end
    local added = 0
    for _, obj in ipairs(model:GetChildren()) do
        if obj:IsA("Accessory") then
            local ok, err = pcall(function()
                local clone = obj:Clone()
                -- Humanoid:AddAccessory expects Accessory instance (it will parent to character)
                targetHumanoid:AddAccessory(clone)
            end)
            if ok then
                added = added + 1
            else
                -- ignore failed accessory adds but keep trying others
                -- print("Accessory add failed:", err)
            end
        end
    end
    return true, ("Accessories added: %d"):format(added)
end

-- Apply humanoid description (body/shirt/pants/etc)
local function applyHumanoidDescription(desc)
    if not desc then return false, "HumanoidDescription kosong" end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, "Humanoid tidak ditemukan" end
    local ok, err = pcall(function() humanoid:ApplyDescription(desc) end)
    if not ok then return false, ("Gagal apply description: %s"):format(tostring(err)) end
    return true, "HumanoidDescription diterapkan"
end

-- Main copy function combining description + accessories
local function copyAvatarAndAccessories(input, ui)
    ui.Status.Text = "Memproses input..."
    local userId, perr = parseInputToUserId(input)
    if not userId then ui.Status.Text = "Error: "..(perr or "invalid input"); return end

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then ui.Status.Text = "Error: Humanoid lokal tidak ditemukan"; return end

    local state = ui.State

    -- If mode Full or AccessoriesOnly logic
    if state.mode == "Full" then
        ui.Status.Text = "Mengambil HumanoidDescription..."
        local okDesc, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
        if okDesc and desc and state.copyAccessories then
            -- apply description first (so body/shirts set), then accessories add
            local applied, msg = applyHumanoidDescription(desc)
            if applied then
                ui.Status.Text = "HumanoidDescription diterapkan. Mengambil accessories..."
            else
                ui.Status.Text = "Warning: "..tostring(msg).." - akan tetap mencoba ambil accessories."
            end
        elseif okDesc and desc then
            local applied, msg = applyHumanoidDescription(desc)
            ui.Status.Text = applied and "HumanoidDescription diterapkan." or ("Gagal apply: "..tostring(msg))
            -- if accessories not requested, return
            if not state.copyAccessories then return end
        else
            ui.Status.Text = "Gagal mendapatkan HumanoidDescription; tetap mencoba ambil accessories..."
        end
    end

    if state.copyAccessories then
        ui.Status.Text = "Mengambil appearance + accessories dari server..."
        local okModel, modelOrErr = pcall(function() return Players:GetCharacterAppearanceAsync(userId) end)
        if not okModel or not modelOrErr then
            ui.Status.Text = "Gagal mendapatkan appearance: "..tostring(modelOrErr)
            return
        end

        -- Optionally clear existing accessories
        if state.clearAccessories then
            ui.Status.Text = "Menghapus accessories lokal..."
            pcall(function() clearAccessoriesFromCharacter(character) end)
        end

        ui.Status.Text = "Menambahkan accessories ke karakter..."
        local okAdd, addMsg = pcall(function()
            return addAccessoriesFromModelToHumanoid(modelOrErr, humanoid)
        end)
        if okAdd then
            ui.Status.Text = "Selesai: "..tostring(addMsg)
        else
            ui.Status.Text = "Gagal menambahkan accessories: "..tostring(addMsg)
        end
    else
        ui.Status.Text = "Selesai (Accessories di-skip)."
    end
end

-- Setup UI and bind
local ui = createUI()
ui.Button.MouseButton1Click:Connect(function()
    ui.Button.AutoButtonColor = false
    ui.Button.Text = "Processing..."
    ui.Button.Active = false
    local ok, err = pcall(function()
        copyAvatarAndAccessories(ui.Input.Text, ui)
    end)
    if not ok then
        ui.Status.Text = "Terjadi error: "..tostring(err)
    end
    ui.Button.Text = "Copy Avatar"
    ui.Button.AutoButtonColor = true
    ui.Button.Active = true
end)

-- End of script
