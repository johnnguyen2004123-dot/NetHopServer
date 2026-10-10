local P, TS, HS, RS = game:GetService("Players"), game:GetService("TeleportService"), game:GetService("HttpService"), game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = P.LocalPlayer

-- ===================================================
-- 1. TẠO GIAO DIỆN (UI) CỐ ĐỊNH Ở DƯỚI MÀN HÌNH
-- ===================================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "NetRobloc"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Thử nhiều nơi gắn UI để chạy được trên nhiều executor
local okParent = pcall(function()
    Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okParent or not Gui.Parent then
    Gui.Parent = LP:WaitForChild("PlayerGui")
end

-- Frame Chính (Cố định ở giữa dưới màn hình)
local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 280, 0, 150)
Frame.Position = UDim2.new(0.5, -140, 1, -165) -- Vị trí ban đầu (kéo được)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true -- CHO PHÉP KÉO DI CHUYỂN

local Corner = Instance.new("UICorner", Frame)
Corner.CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(255, 255, 255)

-- Label DKHUB (Màu Cầu Vồng)
local HubTitle = Instance.new("TextLabel", Frame)
HubTitle.Size = UDim2.new(1, -68, 0, 25)
HubTitle.Position = UDim2.new(0, 64, 0, 5)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "NetRobloc"
HubTitle.TextSize = 18
HubTitle.Font = Enum.Font.SourceSansBold

-- Label Tên Người Chơi (Màu Cầu Vồng)
local PlayerLabel = Instance.new("TextLabel", Frame)
PlayerLabel.Size = UDim2.new(1, -68, 0, 20)
PlayerLabel.Position = UDim2.new(0, 64, 0, 30)
PlayerLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Text = "Player: " .. LP.DisplayName .. " (@" .. LP.Name .. ")"
PlayerLabel.TextSize = 13
PlayerLabel.Font = Enum.Font.SourceSansSemibold

-- Label Thời Gian (Màu Trắng)
local TimeLabel = Instance.new("TextLabel", Frame)
TimeLabel.Size = UDim2.new(1, -68, 0, 18)
TimeLabel.Position = UDim2.new(0, 64, 0, 50)
TimeLabel.BackgroundTransparency = 1
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.TextSize = 12
TimeLabel.Font = Enum.Font.SourceSans

-- Ảnh logo (góc trái)
local IMAGE_ID  = "0"  -- << ĐỔI: ID ảnh Roblox (số), ví dụ "1234567890"
local IMAGE_URL = "https://files.catbox.moe/xymm7j.jpg"   -- << HOẶC dán link ảnh trực tiếp (.png/.jpg), cần executor hỗ trợ writefile/getcustomasset

local Logo = Instance.new("ImageLabel", Frame)
Logo.Size = UDim2.new(0, 52, 0, 52)
Logo.Position = UDim2.new(0, 8, 0, 10)
Logo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Logo.BorderSizePixel = 0
Logo.ScaleType = Enum.ScaleType.Crop

local LogoCorner = Instance.new("UICorner", Logo)
LogoCorner.CornerRadius = UDim.new(1, 0) -- ảnh tròn (đổi thành UDim.new(0, 8) nếu muốn bo góc vuông)

local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Thickness = 2

if IMAGE_URL ~= "" and writefile and getcustomasset then
    task.spawn(function()
        pcall(function()
            writefile("NetRobloc_logo.jpg", game:HttpGet(IMAGE_URL))
            Logo.Image = getcustomasset("NetRobloc_logo.jpg")
        end)
    end)
elseif IMAGE_ID ~= "0" then
    Logo.Image = "rbxassetid://" .. IMAGE_ID
end

-- Kéo thả di chuyển (chuột + cảm ứng)
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Nút Hop Server
local Btn = Instance.new("TextButton", Frame)
Btn.Size = UDim2.new(0, 240, 0, 32)
Btn.Position = UDim2.new(0.5, -120, 0, 70)
Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Btn.TextColor3 = Color3.fromRGB(0, 255, 127)
Btn.Text = "⚡ Hop Server Ít Người"
Btn.TextSize = 14
Btn.Font = Enum.Font.SourceSansBold

local BtnCorner = Instance.new("UICorner", Btn)
BtnCorner.CornerRadius = UDim.new(0, 6)

-- Nút Join Discord (nằm dưới nút Hop)
local DISCORD_INVITE = "https://discord.gg/5vppsXWTqg" -- << THAY LINK DISCORD CỦA BẠN VÀO ĐÂY
local DISCORD_CODE = DISCORD_INVITE:match("discord%.gg/(%w+)") or DISCORD_INVITE:match("discord%.com/invite/(%w+)")

local DcBtn = Instance.new("TextButton", Frame)
DcBtn.Size = UDim2.new(0, 240, 0, 32)
DcBtn.Position = UDim2.new(0.5, -120, 0, 108)
DcBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- màu Discord
DcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DcBtn.Text = "💬 Join Discord"
DcBtn.TextSize = 14
DcBtn.Font = Enum.Font.SourceSansBold

local DcCorner = Instance.new("UICorner", DcBtn)
DcCorner.CornerRadius = UDim.new(0, 6)

local dcBusy = false
DcBtn.MouseButton1Click:Connect(function()
    if dcBusy then return end
    dcBusy = true

    -- Thử mở thẳng app Discord (nếu executor hỗ trợ request)
    local opened = false
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req and DISCORD_CODE then
        opened = pcall(function()
            req({
                Url = "http://127.0.0.1:6463/rpc?v=1",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Origin"] = "https://discord.com"
                },
                Body = HS:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    args = { code = DISCORD_CODE },
                    nonce = HS:GenerateGUID(false)
                })
            })
        end)
    end

    -- Luôn copy link vào clipboard để dự phòng
    local copied = false
    if setclipboard then
        copied = pcall(setclipboard, DISCORD_INVITE)
    end

    if opened then
        DcBtn.Text = "✅ Đang mở Discord..."
    elseif copied then
        DcBtn.Text = "✅ Đã copy link Discord!"
    else
        DcBtn.Text = "❌ Không copy được link"
    end

    task.wait(2)
    DcBtn.Text = "💬 Join Discord"
    dcBusy = false
end)

-- ===================================================
-- 2. VÒNG LẶP ĐỔI MÀU CẦU VỒNG & CẬP NHẬT THỜI GIAN
-- ===================================================
local hue = 0
RS.RenderStepped:Connect(function(delta)
    -- Hiệu ứng cầu vồng (xoay màu liên tục)
    hue = (hue + delta * 0.3) % 1
    local rainbowColor = Color3.fromHSV(hue, 0.8, 1)

    HubTitle.TextColor3 = rainbowColor
    PlayerLabel.TextColor3 = rainbowColor
    Stroke.Color = rainbowColor
    LogoStroke.Color = rainbowColor

    -- Cập nhật đồng hồ thời gian thực
    TimeLabel.Text = " Thời gian: " .. os.date("%X")
end)

-- ===================================================
-- 3. HÀM HOP SERVER ÍT NGƯỜI (100% CHẮC CHẮN)
-- ===================================================
TS.TeleportInitFailed:Connect(function()
    Btn.Text = " Thử Server khác..."
end)

local function GetServers(cursor)
    local urls = {
        "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor and "&cursor=" .. cursor or ""),
        "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor and "&cursor=" .. cursor or "")
    }
    
    for _, url in ipairs(urls) do
        local success, raw = pcall(function() return game:HttpGet(url) end)
        if success and raw and #raw > 10 then
            local parsed, data = pcall(function() return HS:JSONDecode(raw) end)
            if parsed and data and data.data then
                return data
            end
        end
    end
    return nil
end

local isRunning = false
local function SafeHop()
    if isRunning then return end
    isRunning = true
    Btn.Text = " Đang quét Server..."

    local currentJob = game.JobId
    local validServers = {}
    local cursor = ""

    for page = 1, 3 do
        local result = GetServers(cursor ~= "" and cursor or nil)
        if result and result.data then
            for _, s in ipairs(result.data) do
                if s.id ~= currentJob and type(s.playing) == "number" and s.playing < s.maxPlayers and s.playing > 0 then
                    table.insert(validServers, s)
                end
            end
            if result.nextPageCursor then
                cursor = result.nextPageCursor
            else
                break
            end
        end
        task.wait(0.1)
    end

    if #validServers > 0 then
        table.sort(validServers, function(a, b) return a.playing < b.playing end)

        local poolSize = math.min(5, #validServers)
        local target = validServers[math.random(1, poolSize)]

        Btn.Text = " Vô Server: " .. target.playing .. "/" .. target.maxPlayers .. " người"
        
        local tpOK = pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, target.id, LP)
        end)

        if not tpOK then
            Btn.Text = "Lỗi kết nối, thử lại..."
            task.wait(1)
        end
    else
        Btn.Text = " Không tìm thấy Server!"
        task.wait(1)
    end

    isRunning = false
    Btn.Text = "⚡ Hop Server Ít Người"
end

Btn.MouseButton1Click:Connect(SafeHop)