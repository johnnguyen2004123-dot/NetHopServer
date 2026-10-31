-- NetRobloc (bản thông báo): chỉ giữ giao diện, logo, chữ và nút dẫn tới bản V2.
local P  = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")
local LP = P.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end
while not LP do task.wait() LP = P.LocalPlayer end

local env = (getgenv and getgenv()) or _G

-- ===================================================
-- CẤU HÌNH
-- ===================================================
local V2_URL = "https://netrobloc.pages.dev"
local NOTICE_TEXT = "Đã có bản Hop Server v2, bạn vui lòng hãy đi lấy bản mới để có trải nghiệm tốt hơn"
local BUTTON_TEXT = "Lấy bản V2"

local IMAGE_ID  = "0"   -- ID ảnh Roblox (số), dùng khi tải link ảnh thất bại
local IMAGE_URL = "https://files.catbox.moe/xymm7j.jpg"
local BG_DARKNESS = 0.75 -- 0 = ảnh rõ nhất, 1 = đen hoàn toàn

-- ===================================================
-- QUẢN LÝ KẾT NỐI / DỌN DẸP
-- ===================================================
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

-- Tắt bản cũ đang chạy (nếu có) để không bị trùng
if type(env.NetRoblocCleanup) == "function" then pcall(env.NetRoblocCleanup) end
env.NetRoblocCleanup = Cleanup

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
-- UI
-- ===================================================
Gui = Instance.new("ScreenGui")
Gui.Name = "NetRobloc V2"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okParent = pcall(function()
    Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okParent or not Gui.Parent then
    Gui.Parent = LP:WaitForChild("PlayerGui")
end

-- Khung chính (kéo được)
local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 360, 0, 236)
Frame.Position = UDim2.new(0.5, -180, 1, -251)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(255, 255, 255)

-- Ảnh nền (logo phủ kín khung, phủ lớp đen mờ)
local Bg = Instance.new("ImageLabel", Frame)
Bg.Name = "BgImage"
Bg.Size = UDim2.new(1, 0, 1, 0)
Bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Bg.BorderSizePixel = 0
Bg.ScaleType = Enum.ScaleType.Crop
Bg.ImageTransparency = BG_DARKNESS
Bg.ZIndex = 0
Bg.Active = false
Instance.new("UICorner", Bg).CornerRadius = UDim.new(0, 10)

-- Tiêu đề NetRobloc (cầu vồng)
local HubTitle = Instance.new("TextLabel", Frame)
HubTitle.Size = UDim2.new(1, -164, 0, 28)
HubTitle.Position = UDim2.new(0, 84, 0, 8)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "NetRobloc"
HubTitle.TextSize = 22
HubTitle.Font = Enum.Font.SourceSansBold

-- Tên người chơi (cầu vồng)
local PlayerLabel = Instance.new("TextLabel", Frame)
PlayerLabel.Size = UDim2.new(1, -164, 0, 22)
PlayerLabel.Position = UDim2.new(0, 84, 0, 38)
PlayerLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Text = "Player: " .. LP.DisplayName .. " (@" .. LP.Name .. ")"
PlayerLabel.TextSize = 15
PlayerLabel.Font = Enum.Font.SourceSansSemibold

-- Thời gian
local TimeLabel = Instance.new("TextLabel", Frame)
TimeLabel.Size = UDim2.new(1, -164, 0, 20)
TimeLabel.Position = UDim2.new(0, 84, 0, 62)
TimeLabel.BackgroundTransparency = 1
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.TextSize = 14
TimeLabel.Font = Enum.Font.SourceSans

-- Logo (góc trái)
local Logo = Instance.new("ImageLabel", Frame)
Logo.Size = UDim2.new(0, 64, 0, 64)
Logo.Position = UDim2.new(0, 10, 0, 10)
Logo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Logo.BorderSizePixel = 0
Logo.ScaleType = Enum.ScaleType.Crop
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)
local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Thickness = 2

local LogoText = Instance.new("TextLabel", Logo)
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "NR"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 22
LogoText.Font = Enum.Font.SourceSansBold

-- Tải ảnh logo từ link (thử lại + dự phòng)
local function DownloadImage(url, fileName)
    if not (writefile and getcustomasset) then return nil end
    local data
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 100 then
        data = res
    else
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            local ok2, r = pcall(function() return req({ Url = url, Method = "GET" }) end)
            if ok2 and r and type(r.Body) == "string" and #r.Body > 100 then data = r.Body end
        end
    end
    if not data then return nil end
    if isfile and delfile and isfile(fileName) then pcall(delfile, fileName) end
    if not pcall(writefile, fileName, data) then return nil end
    task.wait(0.3)
    if isfile and not isfile(fileName) then return nil end
    local okA, asset = pcall(getcustomasset, fileName)
    if okA and asset and asset ~= "" then return asset end
    return nil
end

task.spawn(function()
    local asset
    if IMAGE_URL ~= "" then
        for _ = 1, 3 do
            asset = DownloadImage(IMAGE_URL, "NetRobloc_logo_v2.jpg")
            if asset then break end
            task.wait(1)
        end
    end
    if not asset and IMAGE_ID ~= "0" then asset = "rbxassetid://" .. IMAGE_ID end
    if asset and Gui.Parent then
        Logo.Image = asset
        Bg.Image = asset
        LogoText:Destroy()
    end
end)

-- Avatar Roblox (góc phải)
local MyAvatar = Instance.new("ImageLabel", Frame)
MyAvatar.Name = "MyAvatar"
MyAvatar.Size = UDim2.new(0, 56, 0, 56)
MyAvatar.Position = UDim2.new(1, -70, 0, 26)
MyAvatar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MyAvatar.BorderSizePixel = 0
MyAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150"
Instance.new("UICorner", MyAvatar).CornerRadius = UDim.new(1, 0)
local MyAvatarStroke = Instance.new("UIStroke", MyAvatar)
MyAvatarStroke.Thickness = 2

-- Nút X (đóng bảng)
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
XBtn.MouseButton1Click:Connect(function()
    env.NetRoblocCleanup = nil
    Cleanup()
end)

-- Thông báo
local Notice = Instance.new("TextLabel", Frame)
Notice.Name = "Notice"
Notice.Size = UDim2.new(0, 320, 0, 72)
Notice.Position = UDim2.new(0.5, -160, 0, 92)
Notice.BackgroundTransparency = 1
Notice.Text = NOTICE_TEXT
Notice.TextColor3 = Color3.fromRGB(255, 255, 255)
Notice.TextWrapped = true
Notice.TextSize = 17
Notice.Font = Enum.Font.SourceSansBold
Notice.TextXAlignment = Enum.TextXAlignment.Center
Notice.TextYAlignment = Enum.TextYAlignment.Center

-- Nút Lấy bản V2
local GetBtn = Instance.new("TextButton", Frame)
GetBtn.Name = "GetV2"
GetBtn.Size = UDim2.new(0, 320, 0, 38)
GetBtn.Position = UDim2.new(0.5, -160, 0, 178)
GetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
GetBtn.TextColor3 = Color3.fromRGB(0, 255, 127)
GetBtn.Text = BUTTON_TEXT
GetBtn.TextSize = 16
GetBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", GetBtn).CornerRadius = UDim.new(0, 6)

local busy = false
GetBtn.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true

    -- Thử mở thẳng trình duyệt (tuỳ executor hỗ trợ)
    local opened = pcall(function() GS:OpenBrowserWindow(V2_URL) end)

    -- Luôn copy link vào clipboard để dự phòng
    local copied = false
    if setclipboard then copied = pcall(setclipboard, V2_URL) end

    if opened then
        GetBtn.Text = "✅ Đang mở trình duyệt..."
    elseif copied then
        GetBtn.Text = "✅ Đã copy link, hãy dán vào trình duyệt!"
    else
        GetBtn.Text = "Hãy vào: netrobloc.pages.dev"
    end

    task.wait(2.5)
    if GetBtn.Parent then GetBtn.Text = BUTTON_TEXT end
    busy = false
end)

-- Kéo thả di chuyển (chuột + cảm ứng)
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
On(UIS.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Hiệu ứng cầu vồng + đồng hồ
local hue = 0
On(RS.RenderStepped, function(delta)
    hue = (hue + delta * 0.3) % 1
    local c = Color3.fromHSV(hue, 0.8, 1)
    HubTitle.TextColor3 = c
    PlayerLabel.TextColor3 = c
    Stroke.Color = c
    MyAvatarStroke.Color = c
    LogoStroke.Color = c
    TimeLabel.Text = " Thời gian: " .. os.date("%X")
end)
