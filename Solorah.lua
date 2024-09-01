-- Initialize the global logging table if it doesn't exist
if not SolorahLogs then
    SolorahLogs = {}
end

-- Get the current realm name and construct a unique saved variable name for the realm
local realm = GetRealmName()
local savedVariableName = "SolorahAuctionDatabase_" .. realm

-- Log levels
local LOG_LEVELS = {INFO = 1, DEBUG = 2, ERROR = 3}

-- Function to log messages with different severity levels
local function Log(message, level)
    level = level or LOG_LEVELS.INFO
    local levelName = "INFO"
    if level == LOG_LEVELS.DEBUG then
        levelName = "DEBUG"
    elseif level == LOG_LEVELS.ERROR then
        levelName = "ERROR"
    end

    -- Construct the log entry
    local logEntry = date("%Y-%m-%d %H:%M:%S") .. " [" .. levelName .. "] " .. message
    table.insert(SolorahLogs, logEntry)

    -- Output the log to the default chat frame
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99SolorahAuctionHelper:|r " .. logEntry)
end

-- Function to save logs to the SolorahLogs saved variable
local function SaveSolorahLogs()
    SolorahLogs = SolorahLogs
end

-- Function to load logs from the SolorahLogs saved variable
local function LoadSolorahLogs()
    if SolorahLogs then
        Log("Solorah logs loaded.", LOG_LEVELS.DEBUG)
    else
        Log("No existing Solorah logs found.", LOG_LEVELS.INFO)
    end
end

-- Function to save the auction database to the global variable using the constructed name
local function SaveAuctionDatabase()
    _G[savedVariableName] = SolorahAuctionDatabase
    Log("Auction database saved for realm: " .. realm)
    SaveSolorahLogs() -- Save logs as well
end

-- Function to load the auction database from the global variable, if it exists
local function LoadAuctionDatabase()
    if _G[savedVariableName] then
        SolorahAuctionDatabase = _G[savedVariableName]
        Log("Auction database loaded for realm: " .. realm)
    else
        Log("No existing auction database found for realm: " .. realm, LOG_LEVELS.INFO)
    end
end

if not SolorahAuctionDatabase then
    SolorahAuctionDatabase = {}
    LoadAuctionDatabase()
end

-- Function to handle the ADDON_LOADED event, loading the auction database when the addon is loaded
local function OnAddonLoaded()
    Log("Addon loaded.", LOG_LEVELS.INFO)
    LoadSolorahLogs()
end

-- Function to handle the PLAYER_LOGOUT event, saving the auction database when the player logs out
local function OnAddonUnloaded()
    Log("Player logging out, saving auction database.", LOG_LEVELS.INFO)
    SaveAuctionDatabase()
end

-- Create a frame to listen for events and register the necessary events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")  -- Listen for the addon loaded event
frame:RegisterEvent("PLAYER_LOGOUT") -- Listen for the player logout event

-- Set up the event handling function to respond to the registered events
frame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == "Solorah" then
        OnAddonLoaded()  -- Load the auction database when the addon is loaded
    elseif event == "PLAYER_LOGOUT" then
        OnAddonUnloaded() -- Save the auction database when the player logs out
    end
end)

-- Function to create the main UI frame for the addon
local function CreateMainFrame()
    Log("Creating main UI frame.", LOG_LEVELS.DEBUG)
    
    -- Create the main frame with a basic template and configure its properties
    local mainFrame = CreateFrame("Frame", "SolorahMainFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(300, 350) -- Set the size of the frame
    mainFrame:SetPoint("CENTER") -- Position the frame in the center of the screen
    mainFrame:SetMovable(true) -- Allow the frame to be moved
    mainFrame:EnableMouse(true) -- Enable mouse interactions
    mainFrame:RegisterForDrag("LeftButton") -- Allow dragging with the left mouse button
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving) -- Start moving the frame on drag start
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing) -- Stop moving on drag stop
    mainFrame:SetScript("OnHide", mainFrame.StopMovingOrSizing) -- Ensure the frame stops moving if hidden
    mainFrame.TitleBg:SetHeight(30) -- Set the height of the title background

    -- Create the title text and set its properties
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
    mainFrame.title:SetText("Solorah Auction Helper") -- Set the title text

    -- Create a scroll frame to display the auction database statistics
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 10)

    -- Create a child frame for the scroll frame content
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())
    scrollFrame:SetScrollChild(scrollChild)

    -- Create a font string for the auction database statistics
    local statsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -5)
    statsText:SetWidth(scrollChild:GetWidth() - 10)
    statsText:SetJustifyH("LEFT")
    -- Function to update the auction database statistics
    local function UpdateAuctionStats()
        local stats = "Auction Database Statistics:\n"
        stats = stats .. "Total Items: " .. (SolorahAuctionDatabase.TotalItems or 0) .. "\n"
        stats = stats .. "Total Buyout Gold: " .. (SolorahAuctionDatabase.TotalBuyoutGold or 0) .. "\n"
        stats = stats .. "Total Bid Gold: " .. (SolorahAuctionDatabase.TotalBidGold or 0) .. "\n"
        stats = stats .. "Total Items Last Scan: " .. (SolorahAuctionDatabase.TotalItemsLastScan or 0) .. "\n"
        stats = stats .. "Total Buyout Gold Last Scan: " .. (SolorahAuctionDatabase.TotalBuyoutGoldLastScan or 0) .. "\n"
        stats = stats .. "Total Bid Gold Last Scan: " .. (SolorahAuctionDatabase.TotalBidGoldLastScan or 0) .. "\n"

        statsText:SetText(stats)
        mainFrame.scrollFrame:SetVerticalScroll(0) -- Reset the scroll position to the top
    end

    -- Update the auction database statistics every 5 seconds
    local updateTimer = C_Timer.NewTicker(5, UpdateAuctionStats)

    -- Add the scroll frame to the main frame
    mainFrame.scrollFrame = scrollFrame
    -- Set the frame's strata and ensure it is on top of other frames
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetToplevel(true)

    -- Create and configure the "Save" button
    local saveButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 25) -- Set the size of the button
    saveButton:SetPoint("LEFT") -- Position the button to the left
    saveButton:SetText("Save") -- Set the button text
    saveButton:SetScript("OnClick", function()
        SaveAuctionDatabase() -- Set the button's click handler to save the auction database
        Log("Save button clicked.", LOG_LEVELS.INFO)
    end)

    mainFrame.saveButton = saveButton -- Save the reference to the save button

    -- Create and configure the "Scan" button
    local scanButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    scanButton:SetSize(80, 25) -- Set the size of the button
    scanButton:SetPoint("CENTER") -- Position the button in the center
    scanButton:SetText("Scan") -- Set the button text

    -- Set up the scan button's click handler to update auction database statistics
    scanButton:SetScript("OnClick", function()
        Log("Scan button clicked, initializing scan process.", LOG_LEVELS.INFO)

        local TotalItemsLastScan = 0 -- Initialize the total items for the last scan
        local TotalBuyoutGoldLastScan = 0 -- Initialize the total buyout gold for the last scan
        local TotalBidGoldLastScan = 0 -- Initialize the total bid gold for the last scan

        -- Define what happens when the scan button is clicked
        scanButton:SetScript("OnClick", function()
            -- Update the auction database with the results of the last scan
            SolorahAuctionDatabase.TotalItemsLastScan = (SolorahAuctionDatabase.TotalItemsLastScan or 0) + math.max(TotalItemsLastScan, 1)
            SolorahAuctionDatabase.TotalBuyoutGoldLastScan = (SolorahAuctionDatabase.TotalBuyoutGoldLastScan or 0) + math.max(TotalBuyoutGoldLastScan, 1)
            SolorahAuctionDatabase.TotalBidGoldLastScan = (SolorahAuctionDatabase.TotalBidGoldLastScan or 0) + math.max(TotalBidGoldLastScan, 1)
            SolorahAuctionDatabase.TotalItems = SolorahAuctionDatabase.TotalItems and (SolorahAuctionDatabase.TotalItems + TotalItemsLastScan) or TotalItemsLastScan
            SolorahAuctionDatabase.TotalBuyoutGold = SolorahAuctionDatabase.TotalBuyoutGold and (SolorahAuctionDatabase.TotalBuyoutGold + TotalBuyoutGoldLastScan) or TotalBuyoutGoldLastScan
            SolorahAuctionDatabase.TotalBidGold = SolorahAuctionDatabase.TotalBidGold and (SolorahAuctionDatabase.TotalBidGold + TotalBidGoldLastScan) or TotalBidGoldLastScan

            Log("Auction database updated after scan.", LOG_LEVELS.DEBUG)
            SaveSolorahLogs() -- Save logs after updating
        end)
    end)

    mainFrame.scanButton = scanButton -- Save the reference to the scan button

    return mainFrame -- Return the main frame after creation
end

-- Create the main frame by calling the CreateMainFrame function
local mainFrame = CreateMainFrame()

-- Create a new frame to handle the AUCTION_HOUSE_SHOW event
local frame = CreateFrame("Frame")

-- Function to handle showing the auction house frame
local function OnAuctionHouseShow()
    Log("Auction house opened.", LOG_LEVELS.INFO)
    if not mainFrame:IsShown() then -- If the main frame is not already shown
        mainFrame:Show() -- Show the main frame
        Log("Main frame shown.", LOG_LEVELS.DEBUG)
    end
end

-- Register the AUCTION_HOUSE_SHOW event and set the event handler
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:SetScript("OnEvent", OnAuctionHouseShow)

-- Define a slash command to reload the UI
SLASH_CRU1 = "/cru"
SlashCmdList["CRU"] = function()
    Log("Reload UI command issued.", LOG_LEVELS.INFO)
    ConsoleExec("reloadui")
end

-- Add the main frame to the list of special UI frames that can be closed with the Escape key
table.insert(UISpecialFrames, "SolorahMainFrame")
