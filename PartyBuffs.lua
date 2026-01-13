-- PartyBuffs Addon for WoW 1.12
-- Cycles through party members and casts appropriate buffs based on caster and target class

PartyBuffs = {}
PartyBuffs.currentIndex = 0 -- 0 = player, 1-4 = party members
PartyBuffs.lastCast = 0
PartyBuffs.castDelay = 1.5 -- Global cooldown delay

-- Spell names
local BLESSING_OF_MIGHT = "Blessing of Might"
local ARCANE_INTELLECT = "Arcane Intellect"

-- Class names (English client)
local CLASS_WARRIOR = "Warrior"
local CLASS_PALADIN = "Paladin"
local CLASS_MAGE = "Mage"

-- Create the main frame
local frame = CreateFrame("Frame", "PartyBuffsFrame", UIParent)
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_FAILED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")

-- Function to get the player's class
function PartyBuffs:GetPlayerClass()
    local _, class = UnitClass("player")
    return class
end

-- Function to get a unit's class by unit ID
function PartyBuffs:GetUnitClass(unitId)
    local _, class = UnitClass(unitId)
    return class
end

-- Function to get the unit ID for current index
function PartyBuffs:GetUnitId(index)
    if index == 0 then
        return "player"
    else
        return "party" .. index
    end
end

-- Function to check if unit exists and is in range
function PartyBuffs:IsValidTarget(unitId)
    if not UnitExists(unitId) then
        return false
    end
    if UnitIsDeadOrGhost(unitId) then
        return false
    end
    if not UnitIsConnected(unitId) then
        return false
    end
    return true
end

-- Function to get the number of party members
function PartyBuffs:GetPartyCount()
    return GetNumPartyMembers()
end

-- Function to cast the appropriate buff on the current target
function PartyBuffs:CastBuff()
    local currentTime = GetTime()
    
    -- Check GCD
    if currentTime - self.lastCast < self.castDelay then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00PartyBuffs:|r Please wait for cooldown.")
        return
    end
    
    local partyCount = self:GetPartyCount()
    
    -- If not in a party, just buff self
    if partyCount == 0 then
        self.currentIndex = 0
    end
    
    local unitId = self:GetUnitId(self.currentIndex)
    local playerClass = self:GetPlayerClass()
    
    -- Find next valid target
    local attempts = 0
    local maxAttempts = partyCount + 1 -- +1 for player
    
    while not self:IsValidTarget(unitId) and attempts < maxAttempts do
        self:AdvanceIndex()
        unitId = self:GetUnitId(self.currentIndex)
        attempts = attempts + 1
    end
    
    if not self:IsValidTarget(unitId) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000PartyBuffs:|r No valid targets found.")
        return
    end
    
    local targetClass = self:GetUnitClass(unitId)
    local targetName = UnitName(unitId)
    local spellCast = nil
    
    -- Determine which spell to cast based on caster and target class
    if playerClass == "PALADIN" then
        if targetClass == "WARRIOR" then
            spellCast = BLESSING_OF_MIGHT
        end
        if targetClass == "PALADIN" then
            spellCast = BLESSING_OF_MIGHT
        end
    elseif playerClass == "MAGE" then
        -- Mages cast Arcane Intellect on everyone
        spellCast = ARCANE_INTELLECT
    end
    
    if spellCast then
        -- Target the unit and cast
        TargetUnit(unitId)
        CastSpellByName(spellCast)
        self.lastCast = currentTime
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs:|r Casting " .. spellCast .. " on " .. targetName)
    else
        if playerClass == "PALADIN" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00PartyBuffs:|r " .. targetName .. " is not a Warrior, skipping.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00PartyBuffs:|r Your class cannot buff with this addon.")
        end
    end
    
    -- Advance to next party member
    self:AdvanceIndex()
end

-- Function to advance to the next party member
function PartyBuffs:AdvanceIndex()
    local partyCount = self:GetPartyCount()
    self.currentIndex = self.currentIndex + 1
    
    if self.currentIndex > partyCount then
        self.currentIndex = 0 -- Loop back to player
    end
end

-- Function to reset to first party member
function PartyBuffs:Reset()
    self.currentIndex = 0
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs:|r Reset to player.")
end

-- Function to buff all party members at once (with delay between each)
function PartyBuffs:BuffAll()
    self.currentIndex = 0
    local partyCount = self:GetPartyCount()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs:|r Starting to buff all " .. (partyCount + 1) .. " members. Use /pbuff repeatedly or click the button.")
end

-- Function to show current status
function PartyBuffs:Status()
    local partyCount = self:GetPartyCount()
    local unitId = self:GetUnitId(self.currentIndex)
    local targetName = "None"
    local targetClass = "Unknown"
    
    if self:IsValidTarget(unitId) then
        targetName = UnitName(unitId)
        targetClass = self:GetUnitClass(unitId)
    end
    
    local playerClass = self:GetPlayerClass()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs Status:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  Your class: " .. playerClass)
    DEFAULT_CHAT_FRAME:AddMessage("  Party members: " .. partyCount)
    DEFAULT_CHAT_FRAME:AddMessage("  Current target: " .. targetName .. " (" .. targetClass .. ")")
    DEFAULT_CHAT_FRAME:AddMessage("  Current index: " .. self.currentIndex)
end

-- Event handler
frame:SetScript("OnEvent", function()
    if event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        -- Optionally handle failed casts
    end
end)

-- Create a button for buffing
local button = CreateFrame("Button", "PartyBuffsButton", UIParent, "UIPanelButtonTemplate")
button:SetWidth(100)
button:SetHeight(30)
button:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
button:SetText("Party Buffs")
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        PartyBuffs:CastBuff()
    elseif arg1 == "RightButton" then
        PartyBuffs:Reset()
    end
end)

-- Make button movable
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForDrag("LeftButton")
button:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then
        this:StartMoving()
    end
end)
button:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

-- Tooltip for the button
button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:SetText("Party Buffs")
    GameTooltip:AddLine("Left-click: Buff next party member", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Reset to player", 1, 1, 1)
    GameTooltip:AddLine("Shift+drag: Move button", 1, 1, 1)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Slash commands
SLASH_PARTYBUFFS1 = "/pbuff"
SLASH_PARTYBUFFS2 = "/partybuffs"

SlashCmdList["PARTYBUFFS"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "" or msg == "cast" or msg == "next" then
        PartyBuffs:CastBuff()
    elseif msg == "reset" then
        PartyBuffs:Reset()
    elseif msg == "all" then
        PartyBuffs:BuffAll()
    elseif msg == "status" then
        PartyBuffs:Status()
    elseif msg == "show" then
        PartyBuffsButton:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs:|r Button shown")
    elseif msg == "hide" then
        PartyBuffsButton:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs:|r Button hidden")
    elseif msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /pbuff - Buff next party member")
        DEFAULT_CHAT_FRAME:AddMessage("  /pbuff reset - Reset to player")
        DEFAULT_CHAT_FRAME:AddMessage("  /pbuff all - Start buffing from player")
        DEFAULT_CHAT_FRAME:AddMessage("  /pbuff status - Show current status")
        DEFAULT_CHAT_FRAME:AddMessage("  /pbuff show - Show the button")
        DEFAULT_CHAT_FRAME:AddMessage("  /pbuff hide - Hide the button")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Supported Classes:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Paladin: Casts Blessing of Might on Warriors")
        DEFAULT_CHAT_FRAME:AddMessage("  Mage: Casts Arcane Intellect on everyone")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs:|r Unknown command. Type /pbuff help for options.")
    end
end

-- Initialization message
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PartyBuffs|r loaded! Type /pbuff help for commands.")
