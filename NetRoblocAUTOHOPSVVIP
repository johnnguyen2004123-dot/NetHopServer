local P, TS, HS, RS = game:GetService("Players"), game:GetService("TeleportService"), game:GetService("HttpService"), game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = P.LocalPlayer

-- ===================================================
-- 1. UI
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
Frame.Size = UDim2.new(0, 360, 0, 226)
Frame.Position = UDim2.new(0.5, -180, 1, -241) -- Vị trí ban đầu (kéo được)
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
HubTitle.Size = UDim2.new(1, -164, 0, 28)
HubTitle.Position = UDim2.new(0, 84, 0, 8)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "NetRobloc"
HubTitle.TextSize = 22
HubTitle.Font = Enum.Font.SourceSansBold

-- Label Tên Người Chơi (Màu Cầu Vồng)
local PlayerLabel = Instance.new("TextLabel", Frame)
PlayerLabel.Size = UDim2.new(1, -164, 0, 22)
PlayerLabel.Position = UDim2.new(0, 84, 0, 38)
PlayerLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Text = "Player: " .. LP.DisplayName .. " (@" .. LP.Name .. ")"
PlayerLabel.TextSize = 15
PlayerLabel.Font = Enum.Font.SourceSansSemibold

-- Label Thời Gian (Màu Trắng)
local TimeLabel = Instance.new("TextLabel", Frame)
TimeLabel.Size = UDim2.new(1, -164, 0, 20)
TimeLabel.Position = UDim2.new(0, 84, 0, 62)
TimeLabel.BackgroundTransparency = 1
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.TextSize = 14
TimeLabel.Font = Enum.Font.SourceSans

-- Ảnh logo (góc trái)
local IMAGE_ID  = "0"  -- << ĐỔI: ID ảnh Roblox (số), ví dụ "1234567890"
local IMAGE_URL = "https://files.catbox.moe/xymm7j.jpg"   -- << HOẶC dán link ảnh trực tiếp (.png/.jpg), cần executor hỗ trợ writefile/getcustomasset

-- Nền ảnh (ảnh logo phủ kín khung, phủ lớp đen mờ để chữ dễ đọc)
local BG_DARKNESS = 0.75 -- 0 = ảnh rõ nhất, 1 = đen hoàn toàn (nên để 0.7 - 0.85)

local Bg = Instance.new("ImageLabel", Frame)
Bg.Name = "BgImage"
Bg.Size = UDim2.new(1, 0, 1, 0)
Bg.Position = UDim2.new(0, 0, 0, 0)
Bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Bg.BorderSizePixel = 0
Bg.ScaleType = Enum.ScaleType.Crop
Bg.ImageTransparency = BG_DARKNESS
Bg.ZIndex = 0
Bg.Active = false

local BgCorner = Instance.new("UICorner", Bg)
BgCorner.CornerRadius = UDim.new(0, 10)

local Logo = Instance.new("ImageLabel", Frame)
Logo.Size = UDim2.new(0, 64, 0, 64)
Logo.Position = UDim2.new(0, 10, 0, 10)
Logo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Logo.BorderSizePixel = 0
Logo.ScaleType = Enum.ScaleType.Crop

local LogoCorner = Instance.new("UICorner", Logo)
LogoCorner.CornerRadius = UDim.new(1, 0) -- ảnh tròn (đổi thành UDim.new(0, 8) nếu muốn bo góc vuông)

local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Thickness = 2

-- Chữ "NR" hiện tạm trong lúc ảnh đang tải (hoặc khi ảnh không tải được)
local LogoText = Instance.new("TextLabel", Logo)
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "NR"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 22
LogoText.Font = Enum.Font.SourceSansBold

-- Dòng báo lỗi logo hiện ngay dưới menu (tự mất sau 20 giây)
local StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Size = UDim2.new(1, 0, 0, 34)
StatusLabel.Position = UDim2.new(0, 0, 1, 4)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextWrapped = true
StatusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.Text = ""

-- Tải ảnh từ link (có thử lại + dự phòng). Trả về asset hoặc nil + lý do
local function DownloadImage(url, fileName)
    if not (writefile and getcustomasset) then
        return nil, "Executor không hỗ trợ writefile/getcustomasset"
    end

    local data
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 100 then
        data = res
    else
        -- dự phòng: dùng request/http_request nếu HttpGet bị lỗi
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            local ok2, r = pcall(function() return req({Url = url, Method = "GET"}) end)
            if ok2 and r and type(r.Body) == "string" and #r.Body > 100 then
                data = r.Body
            end
        end
    end
    if not data then
        return nil, "Không tải được ảnh từ link (HttpGet/request bị chặn hoặc link hỏng)"
    end

    if isfile and delfile and isfile(fileName) then pcall(delfile, fileName) end -- xoá file cũ tránh bị cache hỏng
    local okW, errW = pcall(writefile, fileName, data)
    if not okW then return nil, "writefile lỗi: " .. tostring(errW) end
    task.wait(0.3) -- đợi file ghi xong
    if isfile and not isfile(fileName) then return nil, "File ảnh không được lưu vào workspace" end

    local okA, asset = pcall(getcustomasset, fileName)
    if not okA or not asset or asset == "" then
        return nil, "getcustomasset lỗi: " .. tostring(asset)
    end
    return asset
end

task.spawn(function()
    local asset, lastErr

    if IMAGE_URL ~= "" then
        for attempt = 1, 3 do
            asset, lastErr = DownloadImage(IMAGE_URL, "NetRobloc_logo_v2.jpg")
            if asset then break end
            task.wait(1)
        end
    end

    if not asset and IMAGE_ID ~= "0" then
        asset = "rbxassetid://" .. IMAGE_ID
    end

    if asset then
        Logo.Image = asset
        Bg.Image = asset
        LogoText:Destroy()
    else
        local reason = tostring(lastErr or "chưa đặt IMAGE_URL/IMAGE_ID")
        warn("[NetRobloc] Không hiện được logo: " .. reason)
        LogoText.Text = "✖"
        LogoText.TextColor3 = Color3.fromRGB(255, 90, 90)
        StatusLabel.Text = "Logo lỗi: " .. reason
        task.delay(20, function() if StatusLabel.Parent then StatusLabel.Text = "" end end)
    end
end)

-- Avatar Roblox của bạn (góc phải)
local function AvatarURL(userId)
    return "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
end

local MyAvatar = Instance.new("ImageLabel", Frame)
MyAvatar.Name = "MyAvatar"
MyAvatar.Size = UDim2.new(0, 64, 0, 64)
MyAvatar.Position = UDim2.new(1, -74, 0, 10)
MyAvatar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MyAvatar.BorderSizePixel = 0
MyAvatar.Image = AvatarURL(LP.UserId)
Instance.new("UICorner", MyAvatar).CornerRadius = UDim.new(1, 0)
local MyAvatarStroke = Instance.new("UIStroke", MyAvatar)
MyAvatarStroke.Thickness = 2

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

-- Hop Server
local Btn = Instance.new("TextButton", Frame)
Btn.Size = UDim2.new(0, 320, 0, 38)
Btn.Position = UDim2.new(0.5, -160, 0, 84)
Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Btn.TextColor3 = Color3.fromRGB(0, 255, 127)
Btn.Text = "🎃Hop Server Ít Người"
Btn.TextSize = 16
Btn.Font = Enum.Font.SourceSansBold

local BtnCorner = Instance.new("UICorner", Btn)
BtnCorner.CornerRadius = UDim.new(0, 6)

-- Nút Join Discord (nằm dưới nút Hop)
local DISCORD_INVITE = "https://discord.gg/5vppsXWTqg" -- << THAY LINK DISCORD CỦA BẠN VÀO ĐÂY
local DISCORD_CODE = DISCORD_INVITE:match("discord%.gg/(%w+)") or DISCORD_INVITE:match("discord%.com/invite/(%w+)")

local DcBtn = Instance.new("TextButton", Frame)
DcBtn.Size = UDim2.new(0, 320, 0, 38)
DcBtn.Position = UDim2.new(0.5, -160, 0, 128)
DcBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- màu Discord
DcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DcBtn.Text = "💬 Join Discord có script free"
DcBtn.TextSize = 16
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
-- DANH SÁCH NGƯỜI CHƠI TRONG SERVER
-- ===================================================
local ListBtn = Instance.new("TextButton", Frame)
ListBtn.Size = UDim2.new(0, 320, 0, 38)
ListBtn.Position = UDim2.new(0.5, -160, 0, 172)
ListBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ListBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
ListBtn.Text = "👥 Danh Sách Người Chơi"
ListBtn.TextSize = 16
ListBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", ListBtn).CornerRadius = UDim.new(0, 6)

local Panel = Instance.new("Frame", Gui)
Panel.Name = "PlayerListPanel"
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.Size = UDim2.new(0, 400, 0.8, 0)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Panel.BorderSizePixel = 0
Panel.Active = true
Panel.Visible = false
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
local PanelLimit = Instance.new("UISizeConstraint", Panel)
PanelLimit.MaxSize = Vector2.new(400, 560) -- giới hạn để không tràn màn hình
local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Thickness = 2

local PanelTitle = Instance.new("TextLabel", Panel)
PanelTitle.Size = UDim2.new(1, -50, 0, 36)
PanelTitle.Position = UDim2.new(0, 12, 0, 4)
PanelTitle.BackgroundTransparency = 1
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.TextSize = 20
PanelTitle.Font = Enum.Font.SourceSansBold
PanelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)

local CloseBtn = Instance.new("TextButton", Panel)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "X"
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local ListFrame = Instance.new("ScrollingFrame", Panel)
ListFrame.Size = UDim2.new(1, -16, 1, -70)
ListFrame.Position = UDim2.new(0, 8, 0, 46)
ListFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 6
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)
local Layout = Instance.new("UIListLayout", ListFrame)
Layout.Padding = UDim.new(0, 3)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
local Pad = Instance.new("UIPadding", ListFrame)
Pad.PaddingTop, Pad.PaddingLeft, Pad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)

local Hint = Instance.new("TextLabel", Panel)
Hint.Size = UDim2.new(1, 0, 0, 20)
Hint.Position = UDim2.new(0, 0, 1, -22)
Hint.BackgroundTransparency = 1
Hint.Text = "Bấm vào tên để copy @username"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 13
Hint.Font = Enum.Font.SourceSans

local function RefreshList()
    for _, c in ipairs(ListFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local players = P:GetPlayers()
    table.sort(players, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    PanelTitle.Text = "👥 Người chơi (" .. #players .. "/" .. P.MaxPlayers .. ")"

    for i, pl in ipairs(players) do
        local Row = Instance.new("TextButton", ListFrame)
        Row.Size = UDim2.new(1, 0, 0, 56)
        Row.LayoutOrder = i
        Row.BackgroundColor3 = (pl == LP) and Color3.fromRGB(20, 70, 40) or Color3.fromRGB(38, 38, 38)
        Row.TextColor3 = Color3.fromRGB(255, 255, 255)
        Row.TextXAlignment = Enum.TextXAlignment.Left
        Row.TextSize = 15
        Row.Font = Enum.Font.SourceSansSemibold
        Row.Text = pl.DisplayName .. "\n@" .. pl.Name .. ((pl == LP) and "   ← Bạn" or "")
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
        local RowPad = Instance.new("UIPadding", Row)
        RowPad.PaddingLeft = UDim.new(0, 66) -- chừa chỗ cho avatar

        -- Avatar Roblox của từng người
        local Av = Instance.new("ImageLabel", Row)
        Av.Size = UDim2.new(0, 46, 0, 46)
        Av.Position = UDim2.new(0, -60, 0.5, -23) -- bù lại PaddingLeft
        Av.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        Av.BorderSizePixel = 0
        Av.Image = AvatarURL(pl.UserId)
        Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)

        Row.MouseButton1Click:Connect(function()
            if setclipboard then
                pcall(setclipboard, pl.Name)
                local old = Row.Text
                Row.Text = "  ✅ Đã copy: " .. pl.Name
                task.wait(1)
                if Row.Parent then Row.Text = old end
            end
        end)
    end
end

P.PlayerAdded:Connect(RefreshList)
P.PlayerRemoving:Connect(function()
    task.wait(0.1) -- đợi người chơi thoát khỏi danh sách rồi mới cập nhật
    RefreshList()
end)
RefreshList()

ListBtn.MouseButton1Click:Connect(function()
    Panel.Visible = not Panel.Visible
    if Panel.Visible then RefreshList() end
end)
CloseBtn.MouseButton1Click:Connect(function() Panel.Visible = false end)

-- Kéo thả bảng danh sách (chuột + cảm ứng)
do
    local dragging, dragStart, startPos
    Panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, Panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ===================================================
-- 2. RGB
-- ===================================================
local hue = 0
RS.RenderStepped:Connect(function(delta)
    -- Hiệu ứng cầu vồng (xoay màu liên tục)
    hue = (hue + delta * 0.3) % 1
    local rainbowColor = Color3.fromHSV(hue, 0.8, 1)

    HubTitle.TextColor3 = rainbowColor
    PlayerLabel.TextColor3 = rainbowColor
    Stroke.Color = rainbowColor
    PanelStroke.Color = rainbowColor
    MyAvatarStroke.Color = rainbowColor
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

local MAX_PAGES = 3         -- quét bao nhiêu trang (như bản gốc: 3 trang, mỗi trang 100 server)
local MAX_TARGET = 2        -- chỉ vào server DƯỚI số người này (2 = server có 1 người)
local ALLOW_FALLBACK = true  -- true = nếu không có server dưới MAX_TARGET người thì vào server ít người nhất tìm được

local function GetServers(cursor)
    -- Giữ nguyên cách lấy server của bản gốc (roproxy trước, roblox dự phòng)
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
    local validServers = {}   -- mọi server còn chỗ
    local lowServers = {}     -- server dưới MAX_TARGET người
    local seen = {}
    local cursor = nil

    for page = 1, MAX_PAGES do
        Btn.Text = " Đang quét Server... (" .. page .. "/" .. MAX_PAGES .. ")"
        local result = GetServers(cursor)
        if result and result.data then
            for _, sv in ipairs(result.data) do
                if sv.id ~= currentJob and not seen[sv.id]
                    and type(sv.playing) == "number" and type(sv.maxPlayers) == "number"
                    and sv.playing < sv.maxPlayers and sv.playing > 0 then
                    seen[sv.id] = true
                    table.insert(validServers, sv)
                    if sv.playing < MAX_TARGET then
                        table.insert(lowServers, sv)
                    end
                end
            end
            cursor = result.nextPageCursor
            if not cursor then break end
        else
            task.wait(1) -- bị giới hạn tốc độ, đợi rồi thử lại trang này
        end

        -- Đủ server ít người thì dừng quét sớm
        if #lowServers >= 5 then break end

        task.wait(0.25)
    end

    local pool = lowServers
    if #pool == 0 and ALLOW_FALLBACK then
        pool = validServers
    end

    if #pool > 0 then
        table.sort(pool, function(a, b) return a.playing < b.playing end)

        local poolSize = math.min(5, #pool)
        local target = pool[math.random(1, poolSize)]

        Btn.Text = " Vô Server: " .. target.playing .. "/" .. target.maxPlayers .. " người"
        task.wait(0.5)
        
        local tpOK = pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, target.id, LP)
        end)

        if not tpOK then
            Btn.Text = "Lỗi kết nối, thử lại..."
            task.wait(1)
        end
    else
        Btn.Text = " Không có server dưới " .. MAX_TARGET .. " người!"
        task.wait(1)
    end

    isRunning = false
    Btn.Text = "🎃 Hop Server Ít Người"
end

Btn.MouseButton1Click:Connect(SafeHop)
