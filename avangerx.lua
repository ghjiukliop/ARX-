-- Anime Rangers X Script

-- Tải thư viện Fluent từ Arise
local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Lỗi khi tải thư viện Fluent: " .. tostring(err))
    -- Thử tải từ URL dự phòng
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()
        SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
end

if not Fluent then
    error("Không thể tải thư viện Fluent. Vui lòng kiểm tra kết nối internet hoặc executor.")
    return
end

-- Utility function để kiểm tra và lấy service/object một cách an toàn
local function safeGetService(serviceName)
    local service = nil
    pcall(function()
        service = game:GetService(serviceName)
    end)
    return service
end

-- Utility function để kiểm tra và lấy child một cách an toàn
local function safeGetChild(parent, childName, waitTime)
    if not parent then return nil end
    
    local child = nil
    waitTime = waitTime or 1
    
    local success = pcall(function()
        child = parent:FindFirstChild(childName)
        if not child and waitTime > 0 then
            child = parent:WaitForChild(childName, waitTime)
        end
    end)
    
    return child
end

-- Utility function để lấy đường dẫn đầy đủ một cách an toàn
local function safeGetPath(startPoint, path, waitTime)
    waitTime = waitTime or 1
    local current = startPoint
    
    for _, name in ipairs(path) do
        if not current then return nil end
        current = safeGetChild(current, name, waitTime)
    end
    
    return current
end

-- Hệ thống lưu trữ cấu hình
local ConfigSystem = {}
ConfigSystem.FileName = "HTHubARConfig_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    -- Các cài đặt mặc định
    UITheme = "Dark",
    
    -- Cài đặt Shop/Summon
    SummonAmount = "x1",
    SummonBanner = "Standard",
    AutoSummon = false,
    
    -- Cài đặt Quest
    AutoClaimQuest = false,
    
    -- Cài đặt Story
    SelectedMap = "OnePiece",
    SelectedChapter = "Chapter1",
    SelectedDifficulty = "Normal",
    FriendOnly = false,
    AutoJoinMap = false,
    StoryTimeDelay = 5,
    
    -- Cài đặt Ranger Stage
    SelectedRangerMap = "OnePiece",
    SelectedAct = "RangerStage1",
    RangerFriendOnly = false,
    AutoJoinRanger = false,
    RangerTimeDelay = 5,
    
    -- Cài đặt Boss Event
    AutoBossEvent = false,
    BossEventTimeDelay = 5
}
ConfigSystem.CurrentConfig = {}

-- Hàm để lưu cấu hình
ConfigSystem.SaveConfig = function()
    local success, err = pcall(function()
        writefile(ConfigSystem.FileName, game:GetService("HttpService"):JSONEncode(ConfigSystem.CurrentConfig))
    end)
    
    if success then
        print("Đã lưu cấu hình thành công!")
    else
        warn("Lưu cấu hình thất bại:", err)
    end
end

-- Hàm để tải cấu hình
ConfigSystem.LoadConfig = function()
    local success, content = pcall(function()
        if isfile(ConfigSystem.FileName) then
            return readfile(ConfigSystem.FileName)
        end
        return nil
    end)
    
    if success and content then
        local data = game:GetService("HttpService"):JSONDecode(content)
        ConfigSystem.CurrentConfig = data
        return true
    else
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
        return false
    end
end

-- Tải cấu hình khi khởi động
ConfigSystem.LoadConfig()

-- Biến toàn cục để theo dõi UI
local OpenUI = nil
local isMinimized = false

-- Biến lưu trạng thái Summon
local selectedSummonAmount = ConfigSystem.CurrentConfig.SummonAmount or "x1"
local selectedSummonBanner = ConfigSystem.CurrentConfig.SummonBanner or "Standard"
local autoSummonEnabled = ConfigSystem.CurrentConfig.AutoSummon or false
local autoSummonLoop = nil

-- Biến lưu trạng thái Quest
local autoClaimQuestEnabled = ConfigSystem.CurrentConfig.AutoClaimQuest or false
local autoClaimQuestLoop = nil

-- Mapping giữa tên hiển thị và tên thật của map
local mapNameMapping = {
    ["Voocha Village"] = "OnePiece",
    ["Green Planet"] = "Namek",
    ["Demon Forest"] = "DemonSlayer",
    ["Leaf Village"] = "Naruto",
    ["Z City"] = "OPM"
}

-- Mapping ngược lại để hiển thị tên cho người dùng
local reverseMapNameMapping = {}
for display, real in pairs(mapNameMapping) do
    reverseMapNameMapping[real] = display
end

-- Biến lưu trạng thái Story
local selectedMap = ConfigSystem.CurrentConfig.SelectedMap or "OnePiece"
local selectedDisplayMap = reverseMapNameMapping[selectedMap] or "Voocha Village"
local selectedChapter = ConfigSystem.CurrentConfig.SelectedChapter or "Chapter1"
local selectedDifficulty = ConfigSystem.CurrentConfig.SelectedDifficulty or "Normal"
local friendOnly = ConfigSystem.CurrentConfig.FriendOnly or false
local autoJoinMapEnabled = ConfigSystem.CurrentConfig.AutoJoinMap or false
local autoJoinMapLoop = nil

-- Biến lưu trạng thái Ranger Stage
local selectedRangerMap = ConfigSystem.CurrentConfig.SelectedRangerMap or "OnePiece"
local selectedRangerDisplayMap = reverseMapNameMapping[selectedRangerMap] or "Voocha Village"
local selectedAct = ConfigSystem.CurrentConfig.SelectedAct or "RangerStage1"
local rangerFriendOnly = ConfigSystem.CurrentConfig.RangerFriendOnly or false
local autoJoinRangerEnabled = ConfigSystem.CurrentConfig.AutoJoinRanger or false
local autoJoinRangerLoop = nil

-- Biến lưu trạng thái Boss Event
local autoBossEventEnabled = ConfigSystem.CurrentConfig.AutoBossEvent or false
local autoBossEventLoop = nil

-- Biến lưu trạng thái Time Delay
local storyTimeDelay = ConfigSystem.CurrentConfig.StoryTimeDelay or 5
local rangerTimeDelay = ConfigSystem.CurrentConfig.RangerTimeDelay or 5
local bossEventTimeDelay = ConfigSystem.CurrentConfig.BossEventTimeDelay or 5

-- Thông tin người chơi
local playerName = game:GetService("Players").LocalPlayer.Name

-- Tạo Window
local Window = Fluent:CreateWindow({
    Title = "HT Hub | Anime Rangers X",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = ConfigSystem.CurrentConfig.UITheme or "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tạo tab Info
local InfoTab = Window:AddTab({
    Title = "Info",
    Icon = "rbxassetid://7733964719"
})

-- Tạo tab Play
local PlayTab = Window:AddTab({
    Title = "Play",
    Icon = "rbxassetid://7743878070"
})

-- Tạo tab Shop
local ShopTab = Window:AddTab({
    Title = "Shop",
    Icon = "rbxassetid://7734056747"
})

-- Tạo tab Settings
local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon = "rbxassetid://6031280882"
})

-- Tạo logo UI để mở lại khi đã thu nhỏ
local function CreateLogoUI()
    local UI = Instance.new("ScreenGui")
    local Button = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")
    
    -- Kiểm tra môi trường
    if syn and syn.protect_gui then
        syn.protect_gui(UI)
        UI.Parent = game:GetService("CoreGui")
    elseif gethui then
        UI.Parent = gethui()
    else
        UI.Parent = game:GetService("CoreGui")
    end
    
    UI.Name = "AnimeRangersLogo"
    UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.ResetOnSpawn = false
    
    Button.Name = "LogoButton"
    Button.Parent = UI
    Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Button.BackgroundTransparency = 0.2
    Button.Position = UDim2.new(0.9, -25, 0.1, 0)
    Button.Size = UDim2.new(0, 50, 0, 50)
    Button.Image = "rbxassetid://10723424401"
    Button.ImageTransparency = 0.1
    Button.Active = true
    Button.Draggable = true
    
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Button
    
    -- Ẩn logo ban đầu
    UI.Enabled = false
    
    -- Khi click vào logo
    Button.MouseButton1Click:Connect(function()
        UI.Enabled = false
        isMinimized = false
        
        -- Hiển thị lại UI chính
        if Window and Window.Minimize then
            Window.Minimize()
        end
    end)
    
    return UI
end

-- Ghi đè hàm minimize mặc định của thư viện
local oldMinimize = Window.Minimize
Window.Minimize = function()
    isMinimized = not isMinimized
    
    -- Đảm bảo logo đã được tạo
    if not OpenUI then
        OpenUI = CreateLogoUI()
    end
    
    -- Hiển thị/ẩn logo dựa vào trạng thái
    if OpenUI then
        OpenUI.Enabled = isMinimized
        
        -- Đảm bảo logo vẫn hiển thị (phòng trường hợp bị ẩn do lỗi)
        if isMinimized then
            spawn(function()
                wait(0.5) -- Đợi một chút để đảm bảo UI đã được cập nhật
                if OpenUI and isMinimized then
                    OpenUI.Enabled = true
                end
            end)
        end
    end
    
    -- Gọi hàm minimize gốc
    oldMinimize()
end

-- Bắt sự kiện phím để kích hoạt minimize
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
        Window.Minimize()
    end
end)

-- Thêm section thông tin trong tab Info
local InfoSection = InfoTab:AddSection("Thông tin")

InfoSection:AddParagraph({
    Title = "Anime Rangers X",
    Content = "Phiên bản: 1.0.0\nTrạng thái: Hoạt động"
})

InfoSection:AddParagraph({
    Title = "Người phát triển",
    Content = "Script được phát triển bởi HT Hub"
})

-- Kiểm tra xem người chơi đã ở trong map chưa
local function isPlayerInMap()
    local player = game:GetService("Players").LocalPlayer
    if not player then return false end
    
    -- Kiểm tra UnitsFolder
    local unitsFolder = player:FindFirstChild("UnitsFolder")
    if unitsFolder then
        return true
    end
    
    return false
end

-- Thêm section Story trong tab Play
local StorySection = PlayTab:AddSection("Story")

-- Hàm để thay đổi map
local function changeWorld(worldDisplay)
    local success, err = pcall(function()
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if Event then
            -- Chuyển đổi từ tên hiển thị sang tên thật
            local worldReal = mapNameMapping[worldDisplay] or "OnePiece"
            
            local args = {
                [1] = "Change-World",
                [2] = {
                    ["World"] = worldReal
                }
            }
            
            Event:FireServer(unpack(args))
            print("Đã đổi map: " .. worldDisplay .. " (thực tế: " .. worldReal .. ")")
        else
            warn("Không tìm thấy Event để đổi map")
        end
    end)
    
    if not success then
        warn("Lỗi khi đổi map: " .. tostring(err))
    end
end

-- Hàm để thay đổi chapter
local function changeChapter(map, chapter)
    local success, err = pcall(function()
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if Event then
            local args = {
                [1] = "Change-Chapter",
                [2] = {
                    ["Chapter"] = map .. "_" .. chapter
                }
            }
            
            Event:FireServer(unpack(args))
            print("Đã đổi chapter: " .. map .. "_" .. chapter)
        else
            warn("Không tìm thấy Event để đổi chapter")
        end
    end)
    
    if not success then
        warn("Lỗi khi đổi chapter: " .. tostring(err))
    end
end

-- Hàm để thay đổi difficulty
local function changeDifficulty(difficulty)
    local success, err = pcall(function()
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if Event then
            local args = {
                [1] = "Change-Difficulty",
                [2] = {
                    ["Difficulty"] = difficulty
                }
            }
            
            Event:FireServer(unpack(args))
            print("Đã đổi difficulty: " .. difficulty)
        else
            warn("Không tìm thấy Event để đổi difficulty")
        end
    end)
    
    if not success then
        warn("Lỗi khi đổi difficulty: " .. tostring(err))
    end
end

-- Hàm để toggle Friend Only
local function toggleFriendOnly()
    local success, err = pcall(function()
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if Event then
            local args = {
                [1] = "Change-FriendOnly"
            }
            
            Event:FireServer(unpack(args))
            print("Đã toggle Friend Only")
        else
            warn("Không tìm thấy Event để toggle Friend Only")
        end
    end)
    
    if not success then
        warn("Lỗi khi toggle Friend Only: " .. tostring(err))
    end
end

-- Hàm để tự động tham gia map
local function joinMap()
    -- Kiểm tra xem người chơi đã ở trong map chưa
    if isPlayerInMap() then
        print("Đã phát hiện người chơi đang ở trong map, không thực hiện join map")
        return false
    end
    
    local success, err = pcall(function()
        -- Lấy Event
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if not Event then
            warn("Không tìm thấy Event để join map")
            return
        end
        
        -- 1. Create
        Event:FireServer("Create")
        wait(0.5)
        
        -- 2. Friend Only (nếu được bật)
        if friendOnly then
            Event:FireServer("Change-FriendOnly")
            wait(0.5)
        end
        
        -- 3. Chọn Map và Chapter
        -- 3.1 Đổi Map
        local args1 = {
            [1] = "Change-World",
            [2] = {
                ["World"] = selectedMap
            }
        }
        Event:FireServer(unpack(args1))
        wait(0.5)
        
        -- 3.2 Đổi Chapter
        local args2 = {
            [1] = "Change-Chapter",
            [2] = {
                ["Chapter"] = selectedMap .. "_" .. selectedChapter
            }
        }
        Event:FireServer(unpack(args2))
        wait(0.5)
        
        -- 3.3 Đổi Difficulty
        local args3 = {
            [1] = "Change-Difficulty",
            [2] = {
                ["Difficulty"] = selectedDifficulty
            }
        }
        Event:FireServer(unpack(args3))
        wait(0.5)
        
        -- 4. Submit
        Event:FireServer("Submit")
        wait(1)
        
        -- 5. Start
        Event:FireServer("Start")
        
        print("Đã join map: " .. selectedMap .. "_" .. selectedChapter .. " với độ khó " .. selectedDifficulty)
    end)
    
    if not success then
        warn("Lỗi khi join map: " .. tostring(err))
        return false
    end
    
    return true
end

-- Dropdown để chọn Map
StorySection:AddDropdown("MapDropdown", {
    Title = "Choose Map",
    Values = {"Voocha Village", "Green Planet", "Demon Forest", "Leaf Village", "Z City"},
    Multi = false,
    Default = selectedDisplayMap,
    Callback = function(Value)
        selectedDisplayMap = Value
        selectedMap = mapNameMapping[Value] or "OnePiece"
        ConfigSystem.CurrentConfig.SelectedMap = selectedMap
        ConfigSystem.SaveConfig()
        
        -- Thay đổi map khi người dùng chọn
        changeWorld(Value)
        print("Đã chọn map: " .. Value .. " (thực tế: " .. selectedMap .. ")")
    end
})

-- Dropdown để chọn Chapter
StorySection:AddDropdown("ChapterDropdown", {
    Title = "Choose Chapter",
    Values = {"Chapter1", "Chapter2", "Chapter3", "Chapter4", "Chapter5", "Chapter6", "Chapter7", "Chapter8", "Chapter9", "Chapter10"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SelectedChapter or "Chapter1",
    Callback = function(Value)
        selectedChapter = Value
        ConfigSystem.CurrentConfig.SelectedChapter = Value
        ConfigSystem.SaveConfig()
        
        -- Thay đổi chapter khi người dùng chọn
        changeChapter(selectedMap, Value)
        print("Đã chọn chapter: " .. Value)
    end
})

-- Dropdown để chọn Difficulty
StorySection:AddDropdown("DifficultyDropdown", {
    Title = "Choose Difficulty",
    Values = {"Normal", "Hard", "Nightmare"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SelectedDifficulty or "Normal",
    Callback = function(Value)
        selectedDifficulty = Value
        ConfigSystem.CurrentConfig.SelectedDifficulty = Value
        ConfigSystem.SaveConfig()
        
        -- Thay đổi difficulty khi người dùng chọn
        changeDifficulty(Value)
        print("Đã chọn difficulty: " .. Value)
        
        Fluent:Notify({
            Title = "Difficulty Changed",
            Content = "Đã đổi độ khó thành: " .. Value,
            Duration = 2
        })
    end
})

-- Toggle Friend Only
StorySection:AddToggle("FriendOnlyToggle", {
    Title = "Friend Only",
    Default = ConfigSystem.CurrentConfig.FriendOnly or false,
    Callback = function(Value)
        friendOnly = Value
        ConfigSystem.CurrentConfig.FriendOnly = Value
        ConfigSystem.SaveConfig()
        
        -- Toggle Friend Only khi người dùng thay đổi
        toggleFriendOnly()
        
        if Value then
            Fluent:Notify({
                Title = "Friend Only",
                Content = "Đã bật chế độ Friend Only",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Friend Only",
                Content = "Đã tắt chế độ Friend Only",
                Duration = 2
            })
        end
    end
})

-- Toggle Auto Join Map
StorySection:AddToggle("AutoJoinMapToggle", {
    Title = "Auto Join Map",
    Default = ConfigSystem.CurrentConfig.AutoJoinMap or false,
    Callback = function(Value)
        autoJoinMapEnabled = Value
        ConfigSystem.CurrentConfig.AutoJoinMap = Value
        ConfigSystem.SaveConfig()
        
        if autoJoinMapEnabled then
            -- Kiểm tra ngay lập tức nếu người chơi đang ở trong map
            if isPlayerInMap() then
                Fluent:Notify({
                    Title = "Auto Join Map",
                    Content = "Đang ở trong map, Auto Join Map sẽ hoạt động khi bạn rời khỏi map",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Auto Join Map",
                    Content = "Auto Join Map đã được bật, sẽ bắt đầu sau " .. storyTimeDelay .. " giây",
                    Duration = 3
                })
                
                -- Thực hiện join map sau thời gian delay
                spawn(function()
                    wait(storyTimeDelay)
                    if autoJoinMapEnabled and not isPlayerInMap() then
                        joinMap()
                    end
                end)
            end
            
            -- Tạo vòng lặp Auto Join Map
            spawn(function()
                while autoJoinMapEnabled and wait(10) do -- Thử join map mỗi 10 giây
                    -- Chỉ thực hiện join map nếu người chơi không ở trong map
                    if not isPlayerInMap() then
                        -- Áp dụng time delay
                        print("Đợi " .. storyTimeDelay .. " giây trước khi join map")
                        wait(storyTimeDelay)
                        
                        -- Kiểm tra lại sau khi delay
                        if autoJoinMapEnabled and not isPlayerInMap() then
                            joinMap()
                        end
                    else
                        -- Người chơi đang ở trong map, không cần join
                        print("Đang ở trong map, đợi đến khi người chơi rời khỏi map")
                    end
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Join Map",
                Content = "Auto Join Map đã được tắt",
                Duration = 3
            })
        end
    end
})

-- Nút Join Map (manual)
StorySection:AddButton({
    Title = "Join Map Now",
    Callback = function()
        -- Kiểm tra nếu người chơi đã ở trong map
        if isPlayerInMap() then
            Fluent:Notify({
                Title = "Join Map",
                Content = "Bạn đang ở trong map, không thể join map mới",
                Duration = 2
            })
            return
        end
        
        local success = joinMap()
        
        if success then
            Fluent:Notify({
                Title = "Join Map",
                Content = "Đang tham gia map: " .. selectedDisplayMap .. " - " .. selectedChapter,
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Join Map",
                Content = "Không thể tham gia map. Vui lòng thử lại sau.",
                Duration = 2
            })
        end
    end
})

-- Hiển thị trạng thái trong game
StorySection:AddParagraph({
    Title = "Trạng thái",
    Content = "Nhấn nút bên dưới để cập nhật trạng thái"
})

-- Thêm nút cập nhật trạng thái
StorySection:AddButton({
    Title = "Cập nhật trạng thái",
    Callback = function()
        local statusText = isPlayerInMap() and "Đang ở trong map" or "Đang ở sảnh chờ"
        
        -- Hiển thị thông báo với trạng thái hiện tại
        Fluent:Notify({
            Title = "Trạng thái hiện tại",
            Content = statusText,
            Duration = 3
        })
        
        print("Trạng thái: " .. statusText)
    end
})

-- Thêm section Summon trong tab Shop
local SummonSection = ShopTab:AddSection("Summon")

-- Hàm thực hiện summon
local function performSummon()
    -- An toàn kiểm tra Remote có tồn tại không
    local success, err = pcall(function()
        local Remote = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "Gambling", "UnitsGacha"}, 2)
        
        if Remote then
            local args = {
                [1] = selectedSummonAmount,
                [2] = selectedSummonBanner,
                [3] = {}
            }
            
            Remote:FireServer(unpack(args))
            print("Đã summon: " .. selectedSummonAmount .. " - " .. selectedSummonBanner)
        else
            warn("Không tìm thấy Remote UnitsGacha")
        end
    end)
    
    if not success then
        warn("Lỗi khi summon: " .. tostring(err))
    end
end

-- Dropdown để chọn số lượng summon
SummonSection:AddDropdown("SummonAmountDropdown", {
    Title = "Choose Summon Amount",
    Values = {"x1", "x10"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SummonAmount or "x1",
    Callback = function(Value)
        selectedSummonAmount = Value
        ConfigSystem.CurrentConfig.SummonAmount = Value
        ConfigSystem.SaveConfig()
        print("Đã chọn summon amount: " .. Value)
    end
})

-- Dropdown để chọn banner
SummonSection:AddDropdown("SummonBannerDropdown", {
    Title = "Choose Banner",
    Values = {"Standard", "Rate-Up"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SummonBanner or "Standard",
    Callback = function(Value)
        selectedSummonBanner = Value
        ConfigSystem.CurrentConfig.SummonBanner = Value
        ConfigSystem.SaveConfig()
        print("Đã chọn banner: " .. Value)
    end
})

-- Nút manual summon
SummonSection:AddButton({
    Title = "Summon Once",
    Callback = function()
        performSummon()
        
        Fluent:Notify({
            Title = "Summon",
            Content = "Đã summon: " .. selectedSummonAmount .. " - " .. selectedSummonBanner,
            Duration = 2
        })
    end
})

-- Toggle Auto Summon
SummonSection:AddToggle("AutoSummonToggle", {
    Title = "Auto Summon",
    Default = ConfigSystem.CurrentConfig.AutoSummon or false,
    Callback = function(Value)
        autoSummonEnabled = Value
        ConfigSystem.CurrentConfig.AutoSummon = Value
        ConfigSystem.SaveConfig()
        
        if autoSummonEnabled then
            Fluent:Notify({
                Title = "Auto Summon",
                Content = "Auto Summon đã được bật",
                Duration = 3
            })
            
            -- Tạo vòng lặp Auto Summon
            if autoSummonLoop then
                autoSummonLoop:Disconnect()
                autoSummonLoop = nil
            end
            
            -- Sử dụng spawn thay vì coroutine
            spawn(function()
                while autoSummonEnabled and wait(2) do -- Summon mỗi 2 giây
                    performSummon()
                end
            end)
            
        else
            Fluent:Notify({
                Title = "Auto Summon",
                Content = "Auto Summon đã được tắt",
                Duration = 3
            })
            
            if autoSummonLoop then
                autoSummonLoop:Disconnect()
                autoSummonLoop = nil
            end
        end
    end
})

-- Thêm section Quest trong tab Shop
local QuestSection = ShopTab:AddSection("Quest")

-- Hàm để nhận tất cả nhiệm vụ
local function claimAllQuests()
    local success, err = pcall(function()
        -- Kiểm tra an toàn đường dẫn PlayerData
        local ReplicatedStorage = safeGetService("ReplicatedStorage")
        if not ReplicatedStorage then
            warn("Không tìm thấy ReplicatedStorage")
            return
        end
        
        local PlayerData = safeGetChild(ReplicatedStorage, "Player_Data", 2)
        if not PlayerData then
            warn("Không tìm thấy Player_Data")
            return
        end
        
        local PlayerFolder = safeGetChild(PlayerData, playerName, 2)
        if not PlayerFolder then
            warn("Không tìm thấy dữ liệu người chơi: " .. playerName)
            return
        end
        
        local DailyQuest = safeGetChild(PlayerFolder, "DailyQuest", 2)
        if not DailyQuest then
            warn("Không tìm thấy DailyQuest")
            return
        end
        
        -- Lấy đường dẫn đến QuestEvent
        local QuestEvent = safeGetPath(ReplicatedStorage, {"Remote", "Server", "Gameplay", "QuestEvent"}, 2)
        if not QuestEvent then
            warn("Không tìm thấy QuestEvent")
            return
        end
        
        -- Tìm tất cả nhiệm vụ có thể nhận
        for _, quest in pairs(DailyQuest:GetChildren()) do
            if quest then
                local args = {
                    [1] = "ClaimAll",
                    [2] = quest
                }
                
                QuestEvent:FireServer(unpack(args))
                wait(0.2) -- Chờ một chút giữa các lần claim để tránh lag
            end
        end
    end)
    
    if not success then
        warn("Lỗi khi claim quest: " .. tostring(err))
    end
end

-- Nút Claim All Quest (manual)
QuestSection:AddButton({
    Title = "Claim All Quests",
    Callback = function()
        claimAllQuests()
        
        Fluent:Notify({
            Title = "Quests",
            Content = "Đã claim tất cả nhiệm vụ",
            Duration = 2
        })
    end
})

-- Toggle Auto Claim All Quest
QuestSection:AddToggle("AutoClaimQuestToggle", {
    Title = "Auto Claim All Quests",
    Default = ConfigSystem.CurrentConfig.AutoClaimQuest or false,
    Callback = function(Value)
        autoClaimQuestEnabled = Value
        ConfigSystem.CurrentConfig.AutoClaimQuest = Value
        ConfigSystem.SaveConfig()
        
        if autoClaimQuestEnabled then
            Fluent:Notify({
                Title = "Auto Claim Quests",
                Content = "Auto Claim Quests đã được bật",
                Duration = 3
            })
            
            -- Tạo vòng lặp Auto Claim Quests
            spawn(function()
                while autoClaimQuestEnabled and wait(30) do -- Claim mỗi 30 giây
                    claimAllQuests()
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Claim Quests",
                Content = "Auto Claim Quests đã được tắt",
                Duration = 3
            })
        end
    end
})

-- Thêm section thiết lập trong tab Settings
local SettingsSection = SettingsTab:AddSection("Thiết lập")

-- Dropdown chọn theme
SettingsSection:AddDropdown("ThemeDropdown", {
    Title = "Chọn Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.UITheme or "Dark",
    Callback = function(Value)
        ConfigSystem.CurrentConfig.UITheme = Value
        ConfigSystem.SaveConfig()
        print("Đã chọn theme: " .. Value)
    end
})

-- Auto Save Config
local function AutoSaveConfig()
    spawn(function()
        while wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Thêm event listener để lưu ngay khi thay đổi giá trị
local function setupSaveEvents()
    for _, tab in pairs({InfoTab, PlayTab, ShopTab, SettingsTab}) do
        if tab and tab._components then
            for _, element in pairs(tab._components) do
                if element and element.OnChanged then
                    element.OnChanged:Connect(function()
                        pcall(function()
                            ConfigSystem.SaveConfig()
                        end)
                    end)
                end
            end
        end
    end
end

-- Tích hợp với SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Thay đổi cách lưu cấu hình để sử dụng tên người chơi
InterfaceManager:SetFolder("HTHubAR")
SaveManager:SetFolder("HTHubAR/" .. playerName)

-- Thêm thông tin vào tab Settings
SettingsTab:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

SettingsTab:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- Thực thi tự động lưu cấu hình
AutoSaveConfig()

-- Thiết lập events
setupSaveEvents()

-- Kiểm tra trạng thái người chơi khi script khởi động
if isPlayerInMap() then
    Fluent:Notify({
        Title = "Phát hiện trạng thái",
        Content = "Bạn đang ở trong map, Auto Join sẽ chỉ hoạt động khi bạn rời khỏi map",
        Duration = 3
    })
else
    -- Nếu Auto Join Map được bật, thực hiện join map sau time delay
    if autoJoinMapEnabled then
        Fluent:Notify({
            Title = "Auto Join",
            Content = "Sẽ tham gia Story Map sau " .. storyTimeDelay .. " giây",
            Duration = 3
        })
        
        spawn(function()
            wait(storyTimeDelay) -- Chờ theo time delay đã đặt
            if autoJoinMapEnabled and not isPlayerInMap() then
                joinMap()
            end
        end)
    end
    
    -- Nếu Auto Join Ranger được bật, thực hiện join ranger sau time delay
    if autoJoinRangerEnabled then
        Fluent:Notify({
            Title = "Auto Join",
            Content = "Sẽ tham gia Ranger Stage sau " .. rangerTimeDelay .. " giây",
            Duration = 3
        })
        
        spawn(function()
            wait(rangerTimeDelay) -- Chờ theo time delay đã đặt
            if autoJoinRangerEnabled and not isPlayerInMap() then
                joinRangerStage()
            end
        end)
    end
    
    -- Nếu Auto Boss Event được bật, thực hiện join boss event sau time delay
    if autoBossEventEnabled then
        Fluent:Notify({
            Title = "Auto Join",
            Content = "Sẽ tham gia Boss Event sau " .. bossEventTimeDelay .. " giây",
            Duration = 3
        })
        
        spawn(function()
            wait(bossEventTimeDelay) -- Chờ theo time delay đã đặt
            if autoBossEventEnabled and not isPlayerInMap() then
                joinBossEvent()
            end
        end)
    end
end

-- Thông báo khi script đã tải xong
Fluent:Notify({
    Title = "HT Hub | Anime Rangers X",
    Content = "Script đã tải thành công! Đã tải cấu hình cho " .. playerName,
    Duration = 3
})

print("Anime Rangers X Script has been loaded!")

-- Thêm section Ranger Stage trong tab Play
local RangerSection = PlayTab:AddSection("Ranger Stage")

-- Hàm để thay đổi act
local function changeAct(map, act)
    local success, err = pcall(function()
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if Event then
            local args = {
                [1] = "Change-Chapter",
                [2] = {
                    ["Chapter"] = map .. "_" .. act
                }
            }
            
            Event:FireServer(unpack(args))
            print("Đã đổi act: " .. map .. "_" .. act)
        else
            warn("Không tìm thấy Event để đổi act")
        end
    end)
    
    if not success then
        warn("Lỗi khi đổi act: " .. tostring(err))
    end
end

-- Hàm để toggle Friend Only cho Ranger
local function toggleRangerFriendOnly()
    local success, err = pcall(function()
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if Event then
            local args = {
                [1] = "Change-FriendOnly"
            }
            
            Event:FireServer(unpack(args))
            print("Đã toggle Friend Only cho Ranger")
        else
            warn("Không tìm thấy Event để toggle Friend Only")
        end
    end)
    
    if not success then
        warn("Lỗi khi toggle Friend Only: " .. tostring(err))
    end
end

-- Hàm để tự động tham gia Ranger Stage
local function joinRangerStage()
    -- Kiểm tra xem người chơi đã ở trong map chưa
    if isPlayerInMap() then
        print("Đã phát hiện người chơi đang ở trong map, không thực hiện join Ranger Stage")
        return false
    end
    
    local success, err = pcall(function()
        -- Lấy Event
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if not Event then
            warn("Không tìm thấy Event để join Ranger Stage")
            return
        end
        
        -- 1. Create
        Event:FireServer("Create")
        wait(0.5)
        
        -- 2. Change Mode to Ranger Stage
        local modeArgs = {
            [1] = "Change-Mode",
            [2] = {
                ["Mode"] = "Ranger Stage"
            }
        }
        Event:FireServer(unpack(modeArgs))
        wait(0.5)
        
        -- 3. Friend Only (nếu được bật)
        if rangerFriendOnly then
            Event:FireServer("Change-FriendOnly")
            wait(0.5)
        end
        
        -- 4. Chọn Map và Act
        -- 4.1 Đổi Map
        local args1 = {
            [1] = "Change-World",
            [2] = {
                ["World"] = selectedRangerMap
            }
        }
        Event:FireServer(unpack(args1))
        wait(0.5)
        
        -- 4.2 Đổi Act
        local args2 = {
            [1] = "Change-Chapter",
            [2] = {
                ["Chapter"] = selectedRangerMap .. "_" .. selectedAct
            }
        }
        Event:FireServer(unpack(args2))
        wait(0.5)
        
        -- 5. Submit
        Event:FireServer("Submit")
        wait(1)
        
        -- 6. Start
        Event:FireServer("Start")
        
        print("Đã join Ranger Stage: " .. selectedRangerMap .. "_" .. selectedAct)
    end)
    
    if not success then
        warn("Lỗi khi join Ranger Stage: " .. tostring(err))
        return false
    end
    
    return true
end

-- Time Delay slider cho Story
StorySection:AddSlider("StoryTimeDelaySlider", {
    Title = "Time Delay (giây)",
    Default = storyTimeDelay,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        storyTimeDelay = Value
        ConfigSystem.CurrentConfig.StoryTimeDelay = Value
        ConfigSystem.SaveConfig()
        print("Đã đặt Story Time Delay: " .. Value .. " giây")
    end
})

-- Dropdown để chọn Map cho Ranger
RangerSection:AddDropdown("RangerMapDropdown", {
    Title = "Choose Map",
    Values = {"Voocha Village", "Green Planet", "Demon Forest", "Leaf Village", "Z City"},
    Multi = false,
    Default = selectedRangerDisplayMap,
    Callback = function(Value)
        selectedRangerDisplayMap = Value
        selectedRangerMap = mapNameMapping[Value] or "OnePiece"
        ConfigSystem.CurrentConfig.SelectedRangerMap = selectedRangerMap
        ConfigSystem.SaveConfig()
        
        -- Thay đổi map khi người dùng chọn
        changeWorld(Value)
        print("Đã chọn Ranger map: " .. Value .. " (thực tế: " .. selectedRangerMap .. ")")
    end
})

-- Dropdown để chọn Act
RangerSection:AddDropdown("ActDropdown", {
    Title = "Choose Act",
    Values = {"RangerStage1", "RangerStage2", "RangerStage3"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SelectedAct or "RangerStage1",
    Callback = function(Value)
        selectedAct = Value
        ConfigSystem.CurrentConfig.SelectedAct = Value
        ConfigSystem.SaveConfig()
        
        -- Thay đổi act khi người dùng chọn
        changeAct(selectedRangerMap, Value)
        print("Đã chọn act: " .. Value)
    end
})

-- Toggle Friend Only cho Ranger
RangerSection:AddToggle("RangerFriendOnlyToggle", {
    Title = "Friend Only",
    Default = ConfigSystem.CurrentConfig.RangerFriendOnly or false,
    Callback = function(Value)
        rangerFriendOnly = Value
        ConfigSystem.CurrentConfig.RangerFriendOnly = Value
        ConfigSystem.SaveConfig()
        
        -- Toggle Friend Only khi người dùng thay đổi
        toggleRangerFriendOnly()
        
        if Value then
            Fluent:Notify({
                Title = "Ranger Friend Only",
                Content = "Đã bật chế độ Friend Only cho Ranger Stage",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Ranger Friend Only",
                Content = "Đã tắt chế độ Friend Only cho Ranger Stage",
                Duration = 2
            })
        end
    end
})

-- Time Delay slider cho Ranger
RangerSection:AddSlider("RangerTimeDelaySlider", {
    Title = "Time Delay (giây)",
    Default = rangerTimeDelay,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        rangerTimeDelay = Value
        ConfigSystem.CurrentConfig.RangerTimeDelay = Value
        ConfigSystem.SaveConfig()
        print("Đã đặt Ranger Time Delay: " .. Value .. " giây")
    end
})

-- Toggle Auto Join Ranger Stage
RangerSection:AddToggle("AutoJoinRangerToggle", {
    Title = "Auto Join Ranger Stage",
    Default = ConfigSystem.CurrentConfig.AutoJoinRanger or false,
    Callback = function(Value)
        autoJoinRangerEnabled = Value
        ConfigSystem.CurrentConfig.AutoJoinRanger = Value
        ConfigSystem.SaveConfig()
        
        if autoJoinRangerEnabled then
            -- Kiểm tra ngay lập tức nếu người chơi đang ở trong map
            if isPlayerInMap() then
                Fluent:Notify({
                    Title = "Auto Join Ranger Stage",
                    Content = "Đang ở trong map, Auto Join Ranger sẽ hoạt động khi bạn rời khỏi map",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Auto Join Ranger Stage",
                    Content = "Auto Join Ranger Stage đã được bật, sẽ bắt đầu sau " .. rangerTimeDelay .. " giây",
                    Duration = 3
                })
                
                -- Thực hiện join Ranger Stage sau thời gian delay
                spawn(function()
                    wait(rangerTimeDelay)
                    if autoJoinRangerEnabled and not isPlayerInMap() then
                        joinRangerStage()
                    end
                end)
            end
            
            -- Tạo vòng lặp Auto Join Ranger Stage
            spawn(function()
                while autoJoinRangerEnabled and wait(10) do -- Thử join map mỗi 10 giây
                    -- Chỉ thực hiện join map nếu người chơi không ở trong map
                    if not isPlayerInMap() then
                        -- Áp dụng time delay
                        print("Đợi " .. rangerTimeDelay .. " giây trước khi join Ranger Stage")
                        wait(rangerTimeDelay)
                        
                        -- Kiểm tra lại sau khi delay
                        if autoJoinRangerEnabled and not isPlayerInMap() then
                            joinRangerStage()
                        end
                    else
                        -- Người chơi đang ở trong map, không cần join
                        print("Đang ở trong map, đợi đến khi người chơi rời khỏi map")
                    end
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Join Ranger Stage",
                Content = "Auto Join Ranger Stage đã được tắt",
                Duration = 3
            })
        end
    end
})

-- Nút Join Ranger Stage (manual)
RangerSection:AddButton({
    Title = "Join Ranger Stage Now",
    Callback = function()
        -- Kiểm tra nếu người chơi đã ở trong map
        if isPlayerInMap() then
            Fluent:Notify({
                Title = "Join Ranger Stage",
                Content = "Bạn đang ở trong map, không thể join Ranger Stage mới",
                Duration = 2
            })
            return
        end
        
        local success = joinRangerStage()
        
        if success then
            Fluent:Notify({
                Title = "Join Ranger Stage",
                Content = "Đang tham gia Ranger Stage: " .. selectedRangerDisplayMap .. " - " .. selectedAct,
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Join Ranger Stage",
                Content = "Không thể tham gia Ranger Stage. Vui lòng thử lại sau.",
                Duration = 2
            })
        end
    end
})

-- Thêm section Boss Event trong tab Play
local BossEventSection = PlayTab:AddSection("Boss Event")

-- Hàm để tham gia Boss Event
local function joinBossEvent()
    -- Kiểm tra xem người chơi đã ở trong map chưa
    if isPlayerInMap() then
        print("Đã phát hiện người chơi đang ở trong map, không thực hiện join Boss Event")
        return false
    end
    
    local success, err = pcall(function()
        -- Lấy Event
        local Event = safeGetPath(game:GetService("ReplicatedStorage"), {"Remote", "Server", "PlayRoom", "Event"}, 2)
        
        if not Event then
            warn("Không tìm thấy Event để tham gia Boss Event")
            return
        end
        
        -- Gọi Boss Event
        local args = {
            [1] = "Boss-Event"
        }
        
        Event:FireServer(unpack(args))
        print("Đã gửi yêu cầu tham gia Boss Event")
    end)
    
    if not success then
        warn("Lỗi khi tham gia Boss Event: " .. tostring(err))
        return false
    end
    
    return true
end

-- Time Delay slider cho Boss Event
BossEventSection:AddSlider("BossEventTimeDelaySlider", {
    Title = "Time Delay (giây)",
    Default = bossEventTimeDelay,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        bossEventTimeDelay = Value
        ConfigSystem.CurrentConfig.BossEventTimeDelay = Value
        ConfigSystem.SaveConfig()
        print("Đã đặt Boss Event Time Delay: " .. Value .. " giây")
    end
})

-- Toggle Auto Join Boss Event
BossEventSection:AddToggle("AutoJoinBossEventToggle", {
    Title = "Auto Boss Event",
    Default = ConfigSystem.CurrentConfig.AutoBossEvent or false,
    Callback = function(Value)
        autoBossEventEnabled = Value
        ConfigSystem.CurrentConfig.AutoBossEvent = Value
        ConfigSystem.SaveConfig()
        
        if autoBossEventEnabled then
            -- Kiểm tra ngay lập tức nếu người chơi đang ở trong map
            if isPlayerInMap() then
                Fluent:Notify({
                    Title = "Auto Boss Event",
                    Content = "Đang ở trong map, Auto Boss Event sẽ hoạt động khi bạn rời khỏi map",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Auto Boss Event",
                    Content = "Auto Boss Event đã được bật, sẽ bắt đầu sau " .. bossEventTimeDelay .. " giây",
                    Duration = 3
                })
                
                -- Thực hiện tham gia Boss Event sau thời gian delay
                spawn(function()
                    wait(bossEventTimeDelay)
                    if autoBossEventEnabled and not isPlayerInMap() then
                        joinBossEvent()
                    end
                end)
            end
            
            -- Tạo vòng lặp Auto Join Boss Event
            spawn(function()
                while autoBossEventEnabled and wait(30) do -- Thử join boss event mỗi 30 giây
                    -- Chỉ thực hiện tham gia nếu người chơi không ở trong map
                    if not isPlayerInMap() then
                        -- Áp dụng time delay
                        print("Đợi " .. bossEventTimeDelay .. " giây trước khi tham gia Boss Event")
                        wait(bossEventTimeDelay)
                        
                        -- Kiểm tra lại sau khi delay
                        if autoBossEventEnabled and not isPlayerInMap() then
                            joinBossEvent()
                        end
                    else
                        -- Người chơi đang ở trong map, không cần tham gia
                        print("Đang ở trong map, đợi đến khi người chơi rời khỏi map")
                    end
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Boss Event",
                Content = "Auto Boss Event đã được tắt",
                Duration = 3
            })
        end
    end
})

-- Nút tham gia Boss Event (manual)
BossEventSection:AddButton({
    Title = "Join Boss Event Now",
    Callback = function()
        -- Kiểm tra nếu người chơi đã ở trong map
        if isPlayerInMap() then
            Fluent:Notify({
                Title = "Join Boss Event",
                Content = "Bạn đang ở trong map, không thể tham gia Boss Event mới",
                Duration = 2
            })
            return
        end
        
        local success = joinBossEvent()
        
        if success then
            Fluent:Notify({
                Title = "Boss Event",
                Content = "Đã gửi yêu cầu tham gia Boss Event",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Boss Event",
                Content = "Không thể tham gia Boss Event. Vui lòng thử lại sau.",
                Duration = 2
            })
        end
    end
})

