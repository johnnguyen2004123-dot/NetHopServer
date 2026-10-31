-- NetRobloc (file chạy chính). Chỉ cần execute file này, Auto Execute tự hoạt động.
local SRC = [==[
local P, TS, HS, RS = game:GetService("Players"), game:GetService("TeleportService"), game:GetService("HttpService"), game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = P.LocalPlayer

-- Chờ game load xong (quan trọng khi auto execute sau khi hop)
if not game:IsLoaded() then game.Loaded:Wait() end
while not LP do task.wait() LP = P.LocalPlayer end

-- ===================================================
-- 0. CÀI ĐẶT (lưu lại để giữ nguyên sau mỗi lần hop)
-- ===================================================
local env = (getgenv and getgenv()) or _G
local SETTINGS_FILE = "NetRobloc_settings.json"
-- Script do Auto Execute chạy lại sau khi hop sẽ có cờ NetRoblocResume = true
local Resume = (env.NetRoblocResume == true)
env.NetRoblocResume = nil

-- Theo dõi mọi kết nối để nút X có thể tắt sạch script
local Conns = {}
local function On(signal, fn)
    local c = signal:Connect(fn)
    Conns[#Conns + 1] = c
    return c
end
local Gui
local function Cleanup()
    for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    Conns = {}
    if Gui then pcall(function() Gui:Destroy() end) end
end
-- Nếu script đang chạy bản cũ thì tắt bản cũ trước (tránh chạy trùng)
if type(env.NetRoblocCleanup) == "function" then pcall(env.NetRoblocCleanup) end

-- Cấu hình auto hop
local AUTO_STOP_PLAYERS = 3                     -- server có <= 3 người thì auto dừng lại
local AUTO_MAX_TARGET   = AUTO_STOP_PLAYERS + 1 -- auto chỉ tìm server DƯỚI số này (tức <= 3 người)
local autoParked = false                        -- true = đang bật nhưng đã dừng vì server đủ ít người

local Settings = { autoHop = false, closed = false }   -- vừa execute tay: Auto Tìm Server Ít Người mặc định TẮT

if Resume then   -- vừa được auto execute sau khi hop: giữ nguyên trạng thái bật/tắt trước đó
    local loaded
    if type(env.NetRoblocSettings) == "table" then loaded = env.NetRoblocSettings end
    if not loaded and readfile and isfile and isfile(SETTINGS_FILE) then
        local ok, d = pcall(function() return HS:JSONDecode(readfile(SETTINGS_FILE)) end)
        if ok and type(d) == "table" then loaded = d end
    end
    if loaded and type(loaded.autoHop) == "boolean" then Settings.autoHop = loaded.autoHop end
    -- Người dùng đã bấm X ở lần trước -> không tự hiện lại sau khi đổi server
    if loaded and loaded.closed == true then return end
end
env.NetRoblocCleanup = Cleanup

local function SaveSettings()
    env.NetRoblocSettings = Settings
    if writefile then pcall(writefile, SETTINGS_FILE, HS:JSONEncode(Settings)) end
end

-- Nút X: tắt hẳn script (dừng auto hop, huỷ auto execute, xoá UI)
local function Shutdown()
    Settings.autoHop = false
    Settings.closed = true
    SaveSettings()
    pcall(function()
        local c = clear_teleport_queue or (syn and syn.clear_teleport_queue)
        if c then c() end
    end)
    env.NetRoblocCleanup = nil
    Cleanup()
end

-- Xoá GUI cũ nếu script bị chạy 2 lần (vd: autoexec + queue_on_teleport) để không bị trùng
do
    local parents = {}
    pcall(function() if gethui then table.insert(parents, gethui()) end end)
    pcall(function() table.insert(parents, game:GetService("CoreGui")) end)
    pcall(function() table.insert(parents, LP:FindFirstChild("PlayerGui")) end)
    for _, parent in ipairs(parents) do
        pcall(function()
            for _, nm in ipairs({ "NetRobloc", "NetRobloc V2" }) do
                local old = parent:FindFirstChild(nm)
                if old then old:Destroy() end
            end
        end)
    end
end

-- ===================================================
-- 1. UI
-- ===================================================
Gui = Instance.new("ScreenGui")
Gui.Name = "NetRobloc V2"
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
Frame.Size = UDim2.new(0, 360, 0, 314)
Frame.Position = UDim2.new(0.5, -180, 1, -329) -- Vị trí ban đầu (kéo được)
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
MyAvatar.Size = UDim2.new(0, 56, 0, 56)
MyAvatar.Position = UDim2.new(1, -70, 0, 26)
MyAvatar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MyAvatar.BorderSizePixel = 0
MyAvatar.Image = AvatarURL(LP.UserId)
Instance.new("UICorner", MyAvatar).CornerRadius = UDim.new(1, 0)
local MyAvatarStroke = Instance.new("UIStroke", MyAvatar)
MyAvatarStroke.Thickness = 2

-- Nút X (góc trên phải): tắt script
local XBtn = Instance.new("TextButton", Frame)
XBtn.Name = "CloseScript"
XBtn.Size = UDim2.new(0, 22, 0, 22)
XBtn.Position = UDim2.new(1, -28, 0, 4)
XBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
XBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
XBtn.Text = "X"
XBtn.TextSize = 14
XBtn.Font = Enum.Font.SourceSansBold
XBtn.ZIndex = 5
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(0, 6)
XBtn.MouseButton1Click:Connect(Shutdown)

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

On(UIS.InputChanged, function(input)
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

-- Nút Auto Tìm Server Ít Người (bật/tắt)
local AutoBtn = Instance.new("TextButton", Frame)
AutoBtn.Size = UDim2.new(0, 320, 0, 38)
AutoBtn.Position = UDim2.new(0.5, -160, 0, 128)
AutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBtn.TextSize = 16
AutoBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", AutoBtn).CornerRadius = UDim.new(0, 6)
AutoBtn.TextScaled = true
Instance.new("UITextSizeConstraint", AutoBtn).MaxTextSize = 16

local ON_COLOR, OFF_COLOR = Color3.fromRGB(30, 110, 60), Color3.fromRGB(110, 40, 40)
local function AutoLabel()
    local st = "TẮT"
    if Settings.autoHop then st = autoParked and ("BẬT • đã dừng (≤" .. AUTO_STOP_PLAYERS .. " người)") or "BẬT" end
    return "🎃Auto Tìm Server Ít Người: " .. st
end
local function UpdateToggleUI()
    AutoBtn.Text = AutoLabel()
    AutoBtn.BackgroundColor3 = Settings.autoHop and ON_COLOR or OFF_COLOR
end
UpdateToggleUI()

-- Nút Join Discord (nằm dưới nút Hop)
local DISCORD_INVITE = "https://discord.gg/5vppsXWTqg" -- << THAY LINK DISCORD CỦA BẠN VÀO ĐÂY
local DISCORD_CODE = DISCORD_INVITE:match("discord%.gg/(%w+)") or DISCORD_INVITE:match("discord%.com/invite/(%w+)")

local DcBtn = Instance.new("TextButton", Frame)
DcBtn.Size = UDim2.new(0, 320, 0, 38)
DcBtn.Position = UDim2.new(0.5, -160, 0, 172)
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
ListBtn.Position = UDim2.new(0.5, -160, 0, 216)
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

On(P.PlayerAdded, RefreshList)
On(P.PlayerRemoving, function()
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
    On(UIS.InputChanged, function(input)
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
On(RS.RenderStepped, function(delta)
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
local BTN_HOP_TEXT = "🎃Hop Server Ít Người"

local lastBtn = Btn
On(TS.TeleportInitFailed, function()
    lastBtn.Text = " Thử Server khác..."
end)

-- Cấu hình hop
local MAX_PAGES = 8           -- quét tối đa bao nhiêu trang (mỗi trang 100 server)
local MAX_TARGET = 2          -- chỉ vào server DƯỚI số người này (2 = server chỉ có 1 người)
local ALLOW_FALLBACK = false  -- false = chỉ vào server 1 người; true = không có thì vào server ít người nhất tìm được

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
local tried = {}   -- server đã thử vào (tránh lặp lại khi teleport lỗi)

-- ===================================================
-- AUTO EXECUTE (tự chạy lại script sau khi sang server mới)
-- ===================================================
-- Không cần cài gì thêm: script tự mang theo mã nguồn của chính nó (xem file NetRobloc.lua) và xếp vào queue_on_teleport.
-- (Tuỳ chọn) nếu muốn tải bản mới từ mạng mỗi lần hop thì dán link RAW vào đây:
local SCRIPT_URL  = ""
local SCRIPT_FILE = "NetRobloc.lua"   -- dự phòng: nếu có file này trong workspace thì dùng

local AUTO_EXECUTE = true   -- luôn tự chạy lại script sau khi hop
local queued = false

-- Dấu mở/đóng chuỗi dài, ghép từ ký tự để không làm vỡ chính mã nguồn khi nhúng
local LS_OPEN  = "[" .. string.rep("=", 2) .. "["
local LS_CLOSE = "]" .. string.rep("=", 2) .. "]"

local function BuildQueueCode()
    local pre = "local g = (getgenv and getgenv()) or _G; g.NetRoblocResume = true; "
    if SCRIPT_URL ~= "" then
        return pre .. 'loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()'
    end
    local src = env.NetRoblocSource
    if type(src) == "string" and #src > 0 then
        return pre .. "local SRC = " .. LS_OPEN .. "\n" .. src .. "\n" .. LS_CLOSE
            .. "; g.NetRoblocSource = SRC; local f, e = loadstring(SRC); if f then f() else warn(e) end"
    end
    if readfile and isfile and isfile(SCRIPT_FILE) then
        return pre .. 'loadstring(readfile("' .. SCRIPT_FILE .. '"))()'
    end
    return nil
end

local function EnsureAutoExecQueue(showError)
    if not AUTO_EXECUTE or queued then return end
    local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

    local function warnUser(msg)
        warn("[NetRobloc] Auto Execute: " .. msg)
        if showError then
            StatusLabel.Text = "Auto Execute: " .. msg
            task.delay(15, function() if StatusLabel.Parent then StatusLabel.Text = "" end end)
        end
    end

    if not q then return warnUser("executor không hỗ trợ queue_on_teleport (hãy bỏ script vào thư mục autoexec)") end

    local code = BuildQueueCode()
    if not code then return warnUser("không lấy được mã nguồn script, hãy chạy đúng file NetRobloc.lua") end

    local ok, err = pcall(q, code)
    if ok then queued = true else warnUser("queue_on_teleport lỗi: " .. tostring(err)) end
end

-- button: nút đang bấm | idleText: chữ gốc của nút
-- maxPages: số trang quét | maxTarget: chỉ lấy server DƯỚI số người này
-- fallback: nếu không có server phù hợp thì có vào server ít người nhất không
local function HopServer(button, idleText, maxPages, maxTarget, fallback, isAuto)
    if isRunning then return end
    isRunning = true
    lastBtn = button
    -- Huỷ nếu đã bấm X, hoặc (với auto) đã tắt Auto giữa chừng
    local function Aborted() return (not Gui.Parent) or (isAuto and not Settings.autoHop) end
    local function Finish()
        isRunning = false
        if Gui.Parent then
            button.Text = (type(idleText) == "function") and idleText() or idleText
        end
    end
    button.Text = " Đang quét Server..."

    local currentJob = game.JobId
    local validServers = {}   -- mọi server còn chỗ
    local lowServers = {}     -- server dưới maxTarget người
    local seen = {}
    local cursor = nil
    local fails = 0

    local page = 0
    while page < maxPages do
        if Aborted() then break end
        page += 1
        button.Text = " Đang quét Server... (" .. page .. "/" .. maxPages .. ")"
        local result = GetServers(cursor)
        if result and result.data then
            local sawHigher = false
            for _, sv in ipairs(result.data) do
                if sv.id ~= currentJob and not seen[sv.id] and not tried[sv.id]
                    and type(sv.playing) == "number" and type(sv.maxPlayers) == "number"
                    and sv.playing < sv.maxPlayers and sv.playing > 0 then
                    seen[sv.id] = true
                    table.insert(validServers, sv)
                    if sv.playing < maxTarget then
                        table.insert(lowServers, sv)
                    else
                        sawHigher = true
                    end
                end
            end
            cursor = result.nextPageCursor
            if not cursor then break end

            -- Danh sách sắp xếp tăng dần: gặp server >= maxTarget thì phía sau không còn server ít người nữa
            if not fallback and sawHigher then break end
        else
            -- bị giới hạn tốc độ: đợi rồi thử lại đúng trang này (tối đa 3 lần)
            fails += 1
            page -= 1
            if fails >= 3 then break end
            task.wait(1.5)
        end

        -- Đủ server ít người thì dừng quét sớm
        if #lowServers >= 5 then break end

        task.wait(0.25)
    end

    if Aborted() then return Finish() end

    local pool = lowServers
    if #pool == 0 and fallback then
        pool = validServers
    end

    if #pool > 0 then
        table.sort(pool, function(a, b) return a.playing < b.playing end)

        local poolSize = math.min(5, #pool)
        local target = pool[math.random(1, poolSize)]

        button.Text = " Vô Server: " .. target.playing .. "/" .. target.maxPlayers .. " người"
        tried[target.id] = true
        EnsureAutoExecQueue(true)   -- đảm bảo script tự chạy lại ở server mới
        task.wait(0.5)
        if Aborted() then return Finish() end

        local tpOK = pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, target.id, LP)
        end)

        if not tpOK then
            button.Text = "Lỗi kết nối, thử lại..."
            task.wait(1)
        end
    else
        tried = {}  -- không còn server nào để thử -> xoá danh sách đã thử để quét lại từ đầu
        button.Text = " Không có server dưới " .. maxTarget .. " người!"
        task.wait(1.5)
    end

    Finish()
end

-- Nút 🎃Hop Server Ít Người: bấm 1 lần = hop 1 lần
Btn.MouseButton1Click:Connect(function()
    HopServer(Btn, BTN_HOP_TEXT, MAX_PAGES, MAX_TARGET, ALLOW_FALLBACK)
end)

-- ===================================================
-- 3B. DANH SÁCH SERVER ÍT NGƯỜI (bấm vào server để vào)
-- ===================================================
local SV_LIST_MAX = 3   -- chỉ hiện server có <= 3 người

local SvBtn = Instance.new("TextButton", Frame)
SvBtn.Size = UDim2.new(0, 320, 0, 38)
SvBtn.Position = UDim2.new(0.5, -160, 0, 260)
SvBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SvBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
SvBtn.Text = "🌐 Danh Sách Server Ít Người"
SvBtn.TextSize = 16
SvBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", SvBtn).CornerRadius = UDim.new(0, 6)

local SvPanel = Instance.new("Frame", Gui)
SvPanel.Name = "ServerListPanel"
SvPanel.AnchorPoint = Vector2.new(0.5, 0.5)
SvPanel.Size = UDim2.new(0, 400, 0.8, 0)
SvPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
SvPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SvPanel.BorderSizePixel = 0
SvPanel.Active = true
SvPanel.Visible = false
Instance.new("UICorner", SvPanel).CornerRadius = UDim.new(0, 10)
Instance.new("UISizeConstraint", SvPanel).MaxSize = Vector2.new(400, 560)
local SvStroke = Instance.new("UIStroke", SvPanel)
SvStroke.Thickness = 2

local SvTitle = Instance.new("TextLabel", SvPanel)
SvTitle.Size = UDim2.new(1, -150, 0, 36)
SvTitle.Position = UDim2.new(0, 12, 0, 4)
SvTitle.BackgroundTransparency = 1
SvTitle.TextXAlignment = Enum.TextXAlignment.Left
SvTitle.TextSize = 18
SvTitle.Font = Enum.Font.SourceSansBold
SvTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SvTitle.Text = "🌐 Server ≤" .. SV_LIST_MAX .. " người"

local SvRefresh = Instance.new("TextButton", SvPanel)
SvRefresh.Size = UDim2.new(0, 84, 0, 32)
SvRefresh.Position = UDim2.new(1, -132, 0, 6)
SvRefresh.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
SvRefresh.TextColor3 = Color3.fromRGB(255, 255, 255)
SvRefresh.Text = "🔄 Quét lại"
SvRefresh.TextSize = 14
SvRefresh.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", SvRefresh).CornerRadius = UDim.new(0, 6)

local SvClose = Instance.new("TextButton", SvPanel)
SvClose.Size = UDim2.new(0, 32, 0, 32)
SvClose.Position = UDim2.new(1, -40, 0, 6)
SvClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
SvClose.TextColor3 = Color3.fromRGB(255, 255, 255)
SvClose.Text = "X"
SvClose.TextSize = 16
SvClose.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", SvClose).CornerRadius = UDim.new(0, 6)

local SvList = Instance.new("ScrollingFrame", SvPanel)
SvList.Size = UDim2.new(1, -16, 1, -70)
SvList.Position = UDim2.new(0, 8, 0, 46)
SvList.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
SvList.BorderSizePixel = 0
SvList.ScrollBarThickness = 6
SvList.CanvasSize = UDim2.new(0, 0, 0, 0)
SvList.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", SvList).CornerRadius = UDim.new(0, 6)
local SvLayout = Instance.new("UIListLayout", SvList)
SvLayout.Padding = UDim.new(0, 3)
SvLayout.SortOrder = Enum.SortOrder.LayoutOrder
local SvPad = Instance.new("UIPadding", SvList)
SvPad.PaddingTop, SvPad.PaddingLeft, SvPad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)

local SvHint = Instance.new("TextLabel", SvPanel)
SvHint.Size = UDim2.new(1, 0, 0, 20)
SvHint.Position = UDim2.new(0, 0, 1, -22)
SvHint.BackgroundTransparency = 1
SvHint.Text = "Bấm vào server để vào"
SvHint.TextColor3 = Color3.fromRGB(150, 150, 150)
SvHint.TextSize = 13
SvHint.Font = Enum.Font.SourceSans

local function SvStatus(t)
    if SvHint.Parent then SvHint.Text = t end
end

local function ClearSvRows()
    for _, c in ipairs(SvList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
end

-- Vào server được chọn
local function JoinServer(sv)
    if isRunning then SvStatus("Đang hop server, đợi chút...") return end
    isRunning = true
    SvStatus("Đang vào server " .. sv.playing .. "/" .. sv.maxPlayers .. " người...")
    tried[sv.id] = true
    EnsureAutoExecQueue(true)
    task.wait(0.3)
    local ok = pcall(function()
        TS:TeleportToPlaceInstance(game.PlaceId, sv.id, LP)
    end)
    if not ok then SvStatus("Lỗi kết nối, thử server khác") end
    task.wait(5)   -- đợi teleport, tránh auto hop chen ngang
    isRunning = false
    SvStatus("Bấm vào server để vào")
end

local svScanning = false
local function RefreshServers()
    if svScanning then return end
    svScanning = true
    SvRefresh.Text = "⏳ Đang quét"
    ClearSvRows()

    local found, seen = {}, {}
    local cursor, fails, page = nil, 0, 0
    while page < MAX_PAGES and Gui.Parent do
        page += 1
        SvStatus("Đang quét server... (" .. page .. "/" .. MAX_PAGES .. ")")
        local result = GetServers(cursor)
        if result and result.data then
            local sawHigher = false
            for _, sv in ipairs(result.data) do
                if type(sv.playing) == "number" and type(sv.maxPlayers) == "number" then
                    if sv.playing > SV_LIST_MAX then
                        sawHigher = true
                    elseif sv.id ~= game.JobId and not seen[sv.id]
                        and sv.playing > 0 and sv.playing < sv.maxPlayers then
                        seen[sv.id] = true
                        table.insert(found, sv)
                    end
                end
            end
            cursor = result.nextPageCursor
            -- Danh sách xếp tăng dần: gặp server đông hơn thì phía sau không còn server ít người
            if not cursor or sawHigher then break end
        else
            fails += 1
            page -= 1
            if fails >= 3 then break end
            task.wait(1.5)
        end
        task.wait(0.25)
    end
    if not Gui.Parent then return end

    table.sort(found, function(a, b)
        if a.playing ~= b.playing then return a.playing < b.playing end
        return (a.ping or 9999) < (b.ping or 9999)
    end)

    SvTitle.Text = "🌐 Server ≤" .. SV_LIST_MAX .. " người (" .. #found .. ")"

    if #found == 0 then
        local Empty = Instance.new("TextLabel", SvList)
        Empty.Size = UDim2.new(1, 0, 0, 50)
        Empty.BackgroundTransparency = 1
        Empty.TextColor3 = Color3.fromRGB(200, 200, 200)
        Empty.TextSize = 15
        Empty.Font = Enum.Font.SourceSansSemibold
        Empty.TextWrapped = true
        Empty.Text = "Không tìm thấy server ≤" .. SV_LIST_MAX .. " người. Bấm \"Quét lại\" để thử lại."
    end

    for i, sv in ipairs(found) do
        local Row = Instance.new("TextButton", SvList)
        Row.Size = UDim2.new(1, 0, 0, 52)
        Row.LayoutOrder = i
        Row.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        Row.TextColor3 = Color3.fromRGB(255, 255, 255)
        Row.TextXAlignment = Enum.TextXAlignment.Left
        Row.TextSize = 15
        Row.Font = Enum.Font.SourceSansSemibold
        local pingText = sv.ping and (" • Ping " .. math.floor(sv.ping) .. "ms") or ""
        Row.Text = "👥 " .. sv.playing .. "/" .. sv.maxPlayers .. " người" .. pingText
            .. "\nID: " .. string.sub(sv.id, 1, 8) .. "…  (bấm để vào)"
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
        Instance.new("UIPadding", Row).PaddingLeft = UDim.new(0, 12)
        Row.MouseButton1Click:Connect(function() JoinServer(sv) end)
    end

    SvStatus(#found > 0 and "Bấm vào server để vào" or "Không có server phù hợp")
    SvRefresh.Text = "🔄 Quét lại"
    svScanning = false
end

SvBtn.MouseButton1Click:Connect(function()
    SvPanel.Visible = not SvPanel.Visible
    if SvPanel.Visible then task.spawn(RefreshServers) end
end)
SvRefresh.MouseButton1Click:Connect(function() task.spawn(RefreshServers) end)
SvClose.MouseButton1Click:Connect(function() SvPanel.Visible = false end)

-- Viền cầu vồng giống các bảng khác
On(RS.Heartbeat, function() SvStroke.Color = Stroke.Color end)

-- Kéo thả bảng (chuột + cảm ứng)
do
    local dragging, dragStart, startPos
    SvPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, SvPanel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    On(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            SvPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ===================================================
-- 4. AUTO TÌM SERVER ÍT NGƯỜI: server có > 3 người -> tự hop; server <= 3 người -> dừng (không hop nữa)
-- ===================================================
local AUTO_START_DELAY = 5    -- đợi 5s sau khi vào server rồi mới auto hop
local AUTO_RETRY_DELAY = 5    -- delay 5s giữa các lần auto hop

AutoBtn.MouseButton1Click:Connect(function()
    Settings.autoHop = not Settings.autoHop
    SaveSettings()
    UpdateToggleUI()
end)

SaveSettings()
EnsureAutoExecQueue(true)   -- xếp hàng ngay khi chạy, phòng trường hợp bạn tự đổi server

task.spawn(function()
    task.wait(AUTO_START_DELAY)
    while Gui.Parent do
        local count = #P:GetPlayers()

        -- Server <= 3 người: auto đứng yên (vẫn BẬT). Nếu server đông lên > 3 người thì tự hop tiếp.
        local parked = Settings.autoHop and count <= AUTO_STOP_PLAYERS
        if parked ~= autoParked then
            autoParked = parked
            if not isRunning then UpdateToggleUI() end
        end

        if Settings.autoHop and not isRunning and count > AUTO_STOP_PLAYERS then
            HopServer(AutoBtn, AutoLabel, MAX_PAGES, AUTO_MAX_TARGET, false, true)
            if Settings.autoHop and Gui.Parent then task.wait(AUTO_RETRY_DELAY) end
        end
        task.wait(1)
    end
end)
]==]
local g = (getgenv and getgenv()) or _G
g.NetRoblocSource = SRC
local f, e = loadstring(SRC)
if f then f() else warn("[NetRobloc] Lỗi nạp script: " .. tostring(e)) end
