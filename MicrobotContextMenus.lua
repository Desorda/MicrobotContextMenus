-- MicrobotContextMenus.lua
-- Coded for Vanilla WoW 1.12.1, using LUA version 5.1

--[[ TODO:

[Future Versions?]
- Seperate Server Call for Spells of a certain Companion, a way to notice if a call is handeled.
- Add tooltips to menu commands
- Hold Key for quick Modifiers/prevent Menu closing
- Save and Manage presets for your companions (Melee totems etc) 
- Set distancing/angle with proper display frame (some BWL, overworld)

[RAID MENU?]

--]]
--[[------------------------------------
	Bindings Variable
--------------------------------------]]	
BINDING_HEADER_MCM = "Microbot Context Menus"

--[[------------------------------------
	Helpers
--------------------------------------]]
local function table_contains(tbl, x)
    found = false
    for _, entry in pairs(tbl) do
        if entry == x then 
            found = true 
        end
    end
    return found
end

function table_length(tbl)
	local count = 0
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

function table_index(tbl,x)
	index = 0
    for _, entry in pairs(tbl) do
		index = index+1
        if entry == x then 
            return index 
        end
    end
    return nil
end

local function hasLicence(name, licence)
    licenceFulfilled = false
	local compLicence =  allCompanionInfos[name]["licence"]
	if (compLicence) then 
		if(string.find(licence,"T1D")) then
			if(string.find(compLicence,"T1D") or string.find(compLicence,"T2D") or string.find(compLicence,"T3D") or string.find(compLicence,"T4D") or string.find(compLicence,"T5D")) then
				return true
			end
		end
		if(string.find(licence,"T2D")) then
			if(string.find(compLicence,"T2D") or string.find(compLicence,"T3D") or string.find(compLicence,"T4D") or string.find(compLicence,"T5D")) then
				return true
			end
		end
		if(string.find(licence,"T3D")) then
			if(string.find(compLicence,"T3D") or string.find(compLicence,"T4D") or string.find(compLicence,"T5D")) then
				return true
			end
		end
		if(string.find(licence,"T4D")) then
			if(string.find(compLicence,"T4D") or string.find(compLicence,"T5D")) then
				return true
			end
		end
		if(string.find(licence,"T5D") and string.find(compLicence,"T5D")) then
			return true
		end
		if(string.find(licence,"T1R")) then
			if(string.find(compLicence,"T1R") or string.find(compLicence,"T2R") or string.find(compLicence,"T3R") or string.find(compLicence,"T4R") or string.find(compLicence,"T5R")) then
				return true
			end
		end
		if(string.find(licence,"T2R")) then
			if(string.find(compLicence,"T2R") or string.find(compLicence,"T3R") or string.find(compLicence,"T4R") or string.find(compLicence,"T5R")) then
				return true
			end
		end
		if(string.find(licence,"T3R")) then
			if(string.find(compLicence,"T3R") or string.find(compLicence,"T4R") or string.find(compLicence,"T5R")) then
				return true
			end
		end
		if(string.find(licence,"T4R")) then
			if(string.find(compLicence,"T4R") or string.find(compLicence,"T5R")) then
				return true
			end
		end
		if(string.find(licence,"T5R") and string.find(compLicence,"T5R")) then
			return true
		end
	end
    return licenceFulfilled
end	


local function runGearChangeTimer(target)
	local timerFrame = CreateFrame("Frame")
		local timerDuration = 120 
		local timeElapsed = 0
		timerFrame:SetScript("OnUpdate", function()
			timeElapsed = timeElapsed + arg1			
			if timeElapsed >= timerDuration then
				DEFAULT_CHAT_FRAME:AddMessage("Context Menu: 2 Minutes Gear Change Cooldown for "..target.." has passed")
				timerFrame:SetScript("OnUpdate", nil)
			end
	end)
end

function MCM_Send(msg)
	if GetNumRaidMembers() > 0 then
		SendChatMessage(msg, "RAID")
	elseif GetNumPartyMembers() > 0 then
		SendChatMessage(msg, "PARTY")
	else
		SendChatMessage(msg)
	end
end

function updateData()
	MCM_Send(".z remove list")	 
	ClientRequest("GRINFO:ALL:FULL")
	if string.find(savedSettings["Debug"],"ON") then DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Request to Server made") end
end

--[[------------------------------------
	Get Companion Infos from Server
--------------------------------------]]		
CLIENTTOSERVER = CreateFrame("Frame",nil,UIParent)

-- Create a frame for receiving responses from the server.
SERVERTOCLIENT = CreateFrame("Frame",nil,UIParent) -- create a frame that will listen for events
SERVERTOCLIENT:RegisterEvent("CHAT_MSG_ADDON") -- register what events do you want the frame to listen for - in our case we want to listen to messages from the server

function ClientRequest(arg)
	-- It's necessary to call an OnUpdate function from a frame in order to SendAddonMessages to the server
	CLIENTTOSERVER:SetScript("OnUpdate", function()
		-- Send the message request to the server
		SendAddonMessage("nexus", arg, "BATTLEGROUND")
		
		--DEFAULT_CHAT_FRAME:AddMessage(arg .. " sent")
		-- Clear the OnUpdate script after it finishes because the job's done and we don't want to spam the server
		CLIENTTOSERVER:SetScript("OnUpdate", nil)
		
	end)
end

--[[------------------------------------
	Recieve Companion Infos from Server
--------------------------------------]]

function SERVERTOCLIENT:OnEvent()
	--DEFAULT_CHAT_FRAME:AddMessage("SMSG:" .. arg1 .. " arg2:" .. arg2 .. " CHANNEL:" .. arg3 .. " SENDER:" .. arg4)
	-- DEFAULT_CHAT_FRAME:AddMessage(arg1)
	
	-- We are only interested in capturing messages from the server on the addon channel, which is invisible to the players
	if event ~= "CHAT_MSG_ADDON" then
		return
	end
	
	-- Check if the message starts with [nexus]
	local startPos, endPos = string.find(arg1, "%[nexus%]")
	
	-- If no [nexus] tag is found, or the channel is different than the server one, or the sender is not this player, then do nothing
	if startPos == nil or arg3 ~= "UNKNOWN" or arg4 ~= UnitName("player") then
		return
	end
	-- Extract the part of the instruction after the [nexus] tag
	-- This instruction is the same as the one you've sent in ClientRequest(arg), like for example: GRINFO:ALL:FULL
	-- The server is sending back for which instruction it gives the answer, so you know how to process the answer
	local serverResponse = string.sub(arg1, endPos + 2) -- +2 to skip the space after [nexus]	
	
	if string.find(arg1,"ACINFO:ACTIVE:LIST")  and serverResponse ~= "ACINFO:ACTIVE:LIST" then
		local companionInfo = string.sub(serverResponse, string.find(serverResponse, " ") + 1)
		--DEFAULT_CHAT_FRAME:AddMessage("LIST: "..companionInfo)
		
		-- Lists of companions
		returnedCompanions = {}
		ownCompanionNames = {}
		allCompanionInfos = {}
		compsFollowingYou = {}
		-- Roles
		tankCompanions = {}
		healerCompanions = {}
		mdpsCompanions = {}
		rdpsCompanions = {}
		-- Classes
		druidCompanions = {}
		hunterCompanions = {}
		mageCompanions = {}
		paladinCompanions = {}
		priestCompanions = {}
		rogueCompanions = {}
		shamanCompanions = {}
		warlockCompanions = {}
		warriorCompanions = {}


		-- Split companionInfo by space to extract companion details
		local nameStart = 1
		local nameEnd = string.find(companionInfo, " ", nameStart)

		while nameEnd do
			local nameBlock = string.sub(companionInfo, nameStart, nameEnd - 1)
			table.insert(returnedCompanions, nameBlock)
			nameStart = nameEnd + 1
			nameEnd = string.find(companionInfo, " ", nameStart)
		end

		-- Insert the last block of companion info (if there is no space at the end)
		if nameStart <= string.len(companionInfo) then
			local lastBlock = string.sub(companionInfo, nameStart)
			table.insert(returnedCompanions, lastBlock)
		end	
		
		for _, companion in ipairs(returnedCompanions) do
			--DEFAULT_CHAT_FRAME:AddMessage("Companion Raw Data: " .. companion, 1.0, 1.0, 0.0) -- Output the raw companion data
			local companionData = {}
			local partStart = 1
			local partEnd = string.find(companion, ":")
			while partEnd do
				table.insert(companionData, string.sub(companion, partStart, partEnd - 1))
				partStart = partEnd + 1
				partEnd = string.find(companion, ":", partStart)
			end

			-- Add the last part (owner name) if there is no colon at the end
			if partStart <= string.len(companion) then
				table.insert(companionData, string.sub(companion, partStart))
			end
			
			-- Now we have companionData[1] = name, [2] = Class, [3] = Role, [4] = Kind (l/p), [5] = Level, [6] = Licence, [7] = Race, [8] = Gender, [9] = Durability, 
			-- [10] = Specc, [11] = Owner, [12] = Master, [13] = Follow, [14] = Focus, [15] = CC, [16] = Transferable, [17] = AI Preset
			
			local companionName = companionData[1]
			local companionRace = companionData[7]
			if string.find(companionRace,1) then companionRace = "Human"
			elseif string.find(companionRace,2) then companionRace = "Orc"
			elseif string.find(companionRace,3) then companionRace = "Dwarf"			
			elseif string.find(companionRace,4) then companionRace = "NightElf"			
			elseif string.find(companionRace,5) then companionRace = "Undead"
			elseif string.find(companionRace,6) then companionRace = "Tauren"			
			elseif string.find(companionRace,7) then companionRace = "Gnome" 
			elseif string.find(companionRace,8) then companionRace = "Troll" end	
			local companionClass = companionData[2]
			local companionRole = companionData[3]
			local companionLicence = companionData[6]
			local companionMaster = companionData[12]
			if string.find(companionMaster,"%.") then companionMaster = UnitName("player") end
			
			allCompanionInfos[companionName] = {}
			allCompanionInfos[companionName]["race"] = companionRace
			allCompanionInfos[companionName]["class"] = companionClass	
			allCompanionInfos[companionName]["role"] = companionRole
			allCompanionInfos[companionName]["licence"] = companionLicence
			allCompanionInfos[companionName]["master"] = companionMaster
			allCompanionInfos[companionName]["specc"] = companionData[10]
			allCompanionInfos[companionName]["focusmarks"] =  companionData[14]
			allCompanionInfos[companionName]["ccmarks"] =  companionData[15]
			allCompanionInfos[companionName]["transferable"] =  companionData[16]
			allCompanionInfos[companionName]["following"] = companionData[13]
			
			if(companionMaster and string.find(companionMaster,UnitName("player"))) then
				table.insert(ownCompanionNames, companionName)
			elseif string.find(allCompanionInfos[companionName]["following"],UnitName("player")) then
				table.insert(ownCompanionNames, companionName)
				table.insert(compsFollowingYou, companionName)
			end
			
			-- Store companions based on their role
			if companionRole == "Tank" then
				table.insert(tankCompanions, companionName)
			elseif companionRole == "Healer" then
				table.insert(healerCompanions, companionName)				
			elseif companionRole == "MDPS" then
				table.insert(mdpsCompanions, companionName)
			elseif companionRole == "RDPS" then
				table.insert(rdpsCompanions, companionName)
			end

			-- Store companions based on their role
			if companionClass == "Druid" then
				table.insert(druidCompanions, companionName)
			elseif companionClass == "Hunter" then
				table.insert(hunterCompanions, companionName)
			elseif companionClass == "Mage" then
				table.insert(mageCompanions, companionName)
			elseif companionClass == "Paladin" then
				table.insert(paladinCompanions, companionName)
			elseif companionClass == "Priest" then
				table.insert(priestCompanions, companionName)
			elseif companionClass == "Rogue" then
				table.insert(rogueCompanions, companionName)
			elseif companionClass == "Shaman" then
				table.insert(shamanCompanions, companionName)
			elseif companionClass == "Warlock" then
				table.insert(warlockCompanions, companionName)
			elseif companionClass == "Warrior" then
				table.insert(warriorCompanions, companionName)
			end
			
		end
	end
	if string.find(arg1,"ACINFO:ACTIVE:MORE") then
		local companionInfo = string.sub(serverResponse, string.find(serverResponse, " ") + 1)
		--DEFAULT_CHAT_FRAME:AddMessage("LIST: "..companionInfo)
		
		-- Lists of companions
		moreCompanions = {}

		-- Split companionInfo by space to extract companion details
		local nameStart = 1
		local nameEnd = string.find(companionInfo, " ", nameStart)

		while nameEnd do
			local nameBlock = string.sub(companionInfo, nameStart, nameEnd - 1)
			table.insert(moreCompanions, nameBlock)
			nameStart = nameEnd + 1
			nameEnd = string.find(companionInfo, " ", nameStart)
		end

		-- Insert the last block of companion info (if there is no space at the end)
		if nameStart <= string.len(companionInfo) then
			local lastBlock = string.sub(companionInfo, nameStart)
			table.insert(moreCompanions, lastBlock)
		end	
		
		for _, companion in ipairs(moreCompanions) do
			--DEFAULT_CHAT_FRAME:AddMessage("Companion Raw Data: " .. companion, 1.0, 1.0, 0.0) -- Output the raw companion data
			local companionData = {}
			local partStart = 1
			local partEnd = string.find(companion, ":")
			while partEnd do
				table.insert(companionData, string.sub(companion, partStart, partEnd - 1))
				partStart = partEnd + 1
				partEnd = string.find(companion, ":", partStart)
			end

			-- Add the last part (owner name) if there is no colon at the end
			if partStart <= string.len(companion) then
				table.insert(companionData, string.sub(companion, partStart))
			end
			
			-- Now we have companionData[1] = name, [2] = Class, [3] = Role, [4] = Kind (l/p), [5] = Level, [6] = Licence, [7] = Race, [8] = Gender, [9] = Durability, 
			-- [10] = Specc, [11] = Owner, [12] = Master, [13] = Follow, [14] = Focus, [15] = CC, [16] = Transferable, [17] = AI Preset
			
			local companionName = companionData[1]
			local companionRace = companionData[7]
			if string.find(companionRace,1) then companionRace = "Human"
			elseif string.find(companionRace,2) then companionRace = "Orc"
			elseif string.find(companionRace,3) then companionRace = "Dwarf"			
			elseif string.find(companionRace,4) then companionRace = "NightElf"			
			elseif string.find(companionRace,5) then companionRace = "Undead"
			elseif string.find(companionRace,6) then companionRace = "Tauren"			
			elseif string.find(companionRace,7) then companionRace = "Gnome" 
			elseif string.find(companionRace,8) then companionRace = "Troll" end	
			local companionClass = companionData[2]
			local companionRole = companionData[3]
			local companionLicence = companionData[6]
			local companionMaster = companionData[12]
			if string.find(companionMaster,"%.") then companionMaster = UnitName("player") end
			
			allCompanionInfos[companionName] = {}
			allCompanionInfos[companionName]["race"] = companionRace
			allCompanionInfos[companionName]["class"] = companionClass	
			allCompanionInfos[companionName]["role"] = companionRole
			allCompanionInfos[companionName]["licence"] = companionLicence
			allCompanionInfos[companionName]["master"] = companionMaster
			allCompanionInfos[companionName]["specc"] = companionData[10]
			allCompanionInfos[companionName]["focusmarks"] =  companionData[14]
			allCompanionInfos[companionName]["ccmarks"] =  companionData[15]
			allCompanionInfos[companionName]["transferable"] =  companionData[16]
			allCompanionInfos[companionName]["following"] = companionData[13]
			
			if(companionMaster and string.find(companionMaster,UnitName("player"))) then
				table.insert(ownCompanionNames, companionName)
			elseif string.find(allCompanionInfos[companionName]["following"],UnitName("player")) then
				table.insert(ownCompanionNames, companionName)
				table.insert(compsFollowingYou, companionName)
			end
			
			-- Store companions based on their role
			if companionRole == "Tank" then
				table.insert(tankCompanions, companionName)
			elseif companionRole == "Healer" then
				table.insert(healerCompanions, companionName)				
			elseif companionRole == "MDPS" then
				table.insert(mdpsCompanions, companionName)
			elseif companionRole == "RDPS" then
				table.insert(rdpsCompanions, companionName)
			end

			-- Store companions based on their role
			if companionClass == "Druid" then
				table.insert(druidCompanions, companionName)
			elseif companionClass == "Hunter" then
				table.insert(hunterCompanions, companionName)
			elseif companionClass == "Mage" then
				table.insert(mageCompanions, companionName)
			elseif companionClass == "Paladin" then
				table.insert(paladinCompanions, companionName)
			elseif companionClass == "Priest" then
				table.insert(priestCompanions, companionName)
			elseif companionClass == "Rogue" then
				table.insert(rogueCompanions, companionName)
			elseif companionClass == "Shaman" then
				table.insert(shamanCompanions, companionName)
			elseif companionClass == "Warlock" then
				table.insert(warlockCompanions, companionName)
			elseif companionClass == "Warrior" then
				table.insert(warriorCompanions, companionName)
			end
		end
	end
	if string.find(arg1,"ACINFO:CINFO:") then
		--DEFAULT_CHAT_FRAME:AddMessage("CINFO: "..serverResponse)
	end	
	
	--only do our stuff when the Server sends the a response we can handle so we don't clash with other addons using this Interface
	if string.find(arg1,"GRINFO:ALL:FULL") and serverResponse ~= "GRINFO:ALL:FULL" then
		--End the function prematurely if the server doesn't return any companion information			
		
		local companionInfo = string.sub(serverResponse, string.find(serverResponse, " ") + 1)		
			
		otherCompanions = {}		
		allCompanions = {}

		-- Split companionInfo by space to extract companion details
		local nameStart = 1
		local nameEnd = string.find(companionInfo, " ", nameStart)

		while nameEnd do
			local nameBlock = string.sub(companionInfo, nameStart, nameEnd - 1)
			table.insert(allCompanions, nameBlock)
			nameStart = nameEnd + 1
			nameEnd = string.find(companionInfo, " ", nameStart)
		end

		-- Insert the last block of companion info (if there is no space at the end)
		if nameStart <= string.len(companionInfo) then
			local lastBlock = string.sub(companionInfo, nameStart)
			table.insert(allCompanions, lastBlock)
		end		
				
		-- Now parse the companions into their respective fields: name, race, class, role, and owner
		for _, companion in ipairs(allCompanions) do
			--DEFAULT_CHAT_FRAME:AddMessage("Companion Raw Data: " .. companion, 1.0, 1.0, 0.0) -- Output the raw companion data
			local companionData = {}
			local partStart = 1
			local partEnd = string.find(companion, ":")
			while partEnd do
				table.insert(companionData, string.sub(companion, partStart, partEnd - 1))
				partStart = partEnd + 1
				partEnd = string.find(companion, ":", partStart)
			end

			-- Add the last part (owner name) if there is no colon at the end
			if partStart <= string.len(companion) then
				table.insert(companionData, string.sub(companion, partStart))
			end

			-- Now we have companionData[1] = name, [2] = race, [3] = class, [4] = role, [5] = Licence, [6] = owner
			local companionName = companionData[1]
			local companionOwner = companionData[6]			
			if(companionOwner and not string.find(companionOwner,UnitName("player"))) then
				if not (allCompanionInfos) then allCompanionInfos = {} end
				if not (allCompanionInfos[companionName]) then allCompanionInfos[companionName] = {} end				
				allCompanionInfos[companionName]["race"] = companionData[2]
				allCompanionInfos[companionName]["class"] = companionData[3]				
				allCompanionInfos[companionName]["role"] = companionData[4]
				allCompanionInfos[companionName]["licence"] = companionData[5]				
				table.insert(otherCompanions, companionName)
			end			
			
		end
		
		
	end
	
	--Save UnitIDs for all members in Group/raid
	otherPlayers = {}
	playerUnitIds = {}
	local numMembers = 0
	local getNameFunc
	local getUnitIdFunc
	local playerName = UnitName("player")
	
	if UnitInRaid("player") then
		numMembers = GetNumRaidMembers()
		getNameFunc = function(i) 
			local name = GetRaidRosterInfo(i)
			return name
		end
		getUnitIdFunc = function(j) 
			local unitId = "raid"..j
			return unitId
		end
	elseif GetNumPartyMembers() > 0 then
		numMembers = GetNumPartyMembers()
		getNameFunc = function(i) return UnitName("party"..i) end
		getUnitIdFunc = function(j) return "party"..j end
	else
		--DEFAULT_CHAT_FRAME:AddMessage("Get all players failed: You are not in a party or raid.")
		return
	end
	for i = 1, numMembers do
		local name = getNameFunc(i)	
		if name and name ~= playerName and allCompanionInfos and allCompanionInfos[name] then
			allCompanionInfos[name]["unitID"] = getUnitIdFunc(i)
		elseif otherCompanions and table_contains(otherCompanions,name) then
			-- nothing for now
		elseif name and name ~= playerName then
			playerUnitIds[name] = getUnitIdFunc(i)
			table.insert(otherPlayers,name)
		end
	end
end
	


--[[------------------------------------
		Cache
--------------------------------------]]
local followedComps = {}
local transferredComps = {}

--[[------------------------------------
	Frames/Events
--------------------------------------]]

 -- Attach the OnEvent() function to the frame that will execute when the event is triggered. This needs to be done after you've defined the OnEvent() function.
SERVERTOCLIENT:SetScript("OnEvent", SERVERTOCLIENT.OnEvent)

-- Update Companion Data every time Group/raid changes
local f1 = CreateFrame("Frame")
	f1:RegisterEvent("PARTY_MEMBERS_CHANGED")

	f1:SetScript("OnEvent", function()
		updateData()
end)

-- Update Companion Data every time a companion gets followed or transferred
local f2 = CreateFrame("Frame")

f2:RegisterEvent("CHAT_MSG_MONSTER_WHISPER")

f2:SetScript("OnEvent", function()
	-- case 1: following a single companion
	if string.find(arg1,"will follow") then  
		updateData()
		if not(table_contains(followedComps,arg2)) then
			table.insert(followedComps,arg2) 
		end		
	-- case 2: unfollowing a single companion
	elseif string.find(arg1,"longer follow") then  
		updateData()
		if(table_contains(followedComps,arg2)) then
			table.remove(followedComps,table_index(followedComps,arg2))
		end
	-- case 3: a companion is followed to us
	elseif string.find(arg1,"followed") and string.find(arg1,"me to you") then 
		updateData()
		if(table_contains(followedComps,arg2)) then
			table.remove(followedComps,table_index(followedComps,arg2))
		end
	-- case 4: a companion is unfollowed from us
	elseif string.find(arg1,"unfollowed") then
		updateData()
	-- case 5: untransfering a single companion
	elseif string.find(arg1,"transferred") and string.find(arg1," back to you") and string.find(arg1,"I have") then 
		updateData()
		if(table_contains(transferredComps,arg2)) then
			table.remove(transferredComps,table_index(transferredComps,arg2))
		end
	-- case 6: a companion gets untransferred from you
	elseif string.find(arg1,"transferred") and string.find(arg1,"back to") then 
		updateData()
	-- cast 7: transfering a single companion
	elseif string.find(arg1,"transferred") and string.find(arg1," to ") and string.find(arg1,"I have") then 
		updateData()
		if not(table_contains(transferredComps,arg2)) then
			table.insert(transferredComps,arg2) 
		end
	-- case 8: a companion gets transferred to you
	elseif string.find(arg1,"transferred") and string.find(arg1,"me to you") then 
		updateData()
	-- case 9: unfollowing fails, own bot
	elseif string.find(arg1,"I'm not following anybody") then 
		if(table_contains(followedComps,arg2)) then
			table.remove(followedComps,table_index(followedComps,arg2))
		end
		updateData()
	-- case 10: unfollowing fails, foreign bot (most commonly happens when folling a bot that was followed to us)
	elseif string.find(arg1,"You are not my Master,") and table_contains(followedComps,arg2) then 
		updateData()
		table.remove(followedComps,table_index(followedComps,arg2))		
	-- case 11: a Bots specc is changed
	elseif string.find(arg1,"Spec") then 
		updateData()
	end		
	
end)


-- Update Companion Data every time all companions get followed or transferred
local f3 = CreateFrame("Frame")

f3:RegisterEvent("CHAT_MSG_SYSTEM")

f3:SetScript("OnEvent", function()
	-- case 1: unfollowing all companions
	if string.find(arg1,"to following") then	
		updateData()
		followedComps = {}
	-- case 2: following all companions
	elseif string.find(arg1,"follow") and string.find(arg1,"will") then
		for _, comp in pairs(ownCompanionNames) do
			if not(table_contains(followedComps,comp)) then
				table.insert(followedComps,comp) 
			end	
		end
		updateData()
	-- case 3: untransfering all companions
	elseif string.find(arg1,"transferred") and string.find(arg1," back to you") then
		updateData()
		local sub1 = string.sub(arg1,20,string.find(arg1,"]")-1)
		local name = string.sub(sub1,1,string.find(sub1,"|")-1)
	-- case 4: transfering all companions
	elseif string.find(arg1,"transferred") and string.find(arg1," to ")then
		updateData()
		local sub1 = string.sub(arg1,20,string.find(arg1,"]")-1)
		local name = string.sub(sub1,1,string.find(sub1,"|")-1)
		if not(table_contains(transferredComps,name)) then
			table.insert(transferredComps,name) 
		end
	-- case 5: a Companions Role has been changed
	elseif string.find(arg1,"set") and string.find(arg1," to ")then		
		updateData()
	-- case 5: a Companions Mark has been changed
	elseif string.find(arg1,"Focus Mark") or string.find(arg1,"CC Marks") or string.find(arg1,"Mark assignments") then		
		updateData()
	end
end)


-- Expand Loot Settings
local f4 = CreateFrame("Frame")
f4:RegisterEvent("PLAYER_LOGIN")

f4:SetScript("OnEvent", function()

	updateData()
	
    UnitPopupButtons["LEGENDARY"] = { text = "\124cffFF8000Legendary\124r", dist = 0 }

    -- Ensure the menu exists before modifying it
    if UnitPopupMenus["LOOT_THRESHOLD"] then
        local menu = UnitPopupMenus["LOOT_THRESHOLD"]
        local menuLength = 0

        -- Count the number of items in the menu
        for _ in pairs(menu) do
            menuLength = menuLength + 1
        end

        -- Insert "LEGENDARY" above "Cancel" (second-to-last position)
        table.insert(menu, menuLength, "LEGENDARY")
    end

    -- Override UnitPopup_OnClick to add functionality for the "LEGENDARY" button
    local originalUnitPopup_OnClick = UnitPopup_OnClick

    UnitPopup_OnClick = function()
        if this.value == "LEGENDARY" then
            SetLootThreshold(5)
            CloseMenus()
        else
            -- Call the original function for other buttons
            originalUnitPopup_OnClick()
        end
    end
	
end)


--[[------------------------------------
	Load Settings, Customize Self Menu after Load
--------------------------------------]]
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")

initFrame:SetScript("OnEvent", function()
	--Init Settings
	if not savedSettings then
		savedSettings = {}
	end
	if not savedSettings["broadcastTo"] then
		savedSettings["broadcastTo"] = "NONE"
	end
	if not savedSettings["showConfirmations"] then
		savedSettings["showConfirmations"] = "ON"
	end
	if not savedSettings["Debug"] then
		savedSettings["Debug"] = "OFF"
	end
	if not savedSettings["autoTrade"] then
		savedSettings["autoTrade"] = "ON"
	end
	
	--[[---------------------------------------------------------------------------------
	  PLAYER (SELF) MENU COMMANDS
	----------------------------------------------------------------------------------]]

	UnitPopupButtons["SELF_DEBUG"] = { text = "|cFF9482C9DEBUG|r", dist = 0, nested = 1}
	UnitPopupButtons["SELF_DEBUG_RESPONSE"] = { text = "Print last Server Response", dist = 0}
	UnitPopupButtons["SELF_DEBUG_OWN_COMPS"] = { text = "Print your owned Companions", dist = 0}	
	UnitPopupButtons["SELF_DEBUG_PLAYERS"] = { text = "Print other Players", dist = 0}
	UnitPopupButtons["SELF_DEBUG_DATA_ALL"] = { text = "Print all Companion Info", dist = 0}
	UnitPopupButtons["SELF_DEBUG_SETTINGS"] = { text = "Print Menu Settings", dist = 0}
	UnitPopupButtons["SELF_DEBUG_TANKS"] = { text = "Print Tanks", dist = 0}
	UnitPopupButtons["SELF_DEBUG_HEALER"] = { text = "Print Healers", dist = 0}
	UnitPopupButtons["SELF_DEBUG_RDPS"] = { text = "Print RDPS", dist = 0}
	UnitPopupButtons["SELF_DEBUG_MDPS"] = { text = "Print MDPS", dist = 0}
	UnitPopupButtons["SELF_DEBUG_WARRIOR"] = { text = "Print Warriors", dist = 0}
	UnitPopupButtons["SELF_DEBUG_MAGE"] = { text = "Print Mages", dist = 0}
	UnitPopupButtons["SELF_DEBUG_ROGUE"] = { text = "Print Rogues", dist = 0}
	UnitPopupButtons["SELF_DEBUG_DRUID"] = { text = "Print Druids", dist = 0}
	UnitPopupButtons["SELF_DEBUG_HUNTER"] = { text = "Print Hunters", dist = 0}
	UnitPopupButtons["SELF_DEBUG_SHAMAN"] = { text = "Print Shamans", dist = 0}
	UnitPopupButtons["SELF_DEBUG_PRIEST"] = { text = "Print Priests", dist = 0}
	UnitPopupButtons["SELF_DEBUG_WARLOCK"] = { text = "Print Warlocks", dist = 0}
	UnitPopupButtons["SELF_DEBUG_PALADIN"] = { text = "Print Paladins", dist = 0}
	UnitPopupButtons["SELF_DEBUG_FOLLOWED"] = { text = "Print Companions you followed", dist = 0}	
	UnitPopupButtons["SELF_DEBUG_FOLLOWED_SELF"] = { text = "Print Companions followed onto you", dist = 0}
	UnitPopupButtons["SELF_DEBUG_TRANSFERED"] = { text = "Print Transferred Companions", dist = 0}	
	UnitPopupButtons["SELF_DEBUG_OFF"] = { text = "Turn debug |cffFF0000off|r", dist = 0}

	UnitPopupMenus["SELF_DEBUG"] = {
		"SELF_DEBUG_RESPONSE",
		"SELF_DEBUG_PLAYERS",
		"SELF_DEBUG_SETTINGS",
		"SELF_DEBUG_OWN_COMPS",
		"SELF_DEBUG_TANKS",
		"SELF_DEBUG_HEALER",
		"SELF_DEBUG_RDPS",
		"SELF_DEBUG_MDPS", 
		"SELF_DEBUG_WARRIOR",
		"SELF_DEBUG_MAGE",
		"SELF_DEBUG_ROGUE", 
		"SELF_DEBUG_DRUID", 
		"SELF_DEBUG_HUNTER",
		"SELF_DEBUG_SHAMAN",
		"SELF_DEBUG_PRIEST",
		"SELF_DEBUG_WARLOCK",
		"SELF_DEBUG_PALADIN",	
		"SELF_DEBUG_FOLLOWED",
		"SELF_DEBUG_TRANSFERED",
		"SELF_DEBUG_FOLLOWED_SELF",
		"SELF_DEBUG_OFF"
		}
	if string.find(savedSettings["Debug"],"ON") then table.insert(UnitPopupMenus["SELF"], 1, "SELF_DEBUG") end

	-- Toggle PvP
	UnitPopupButtons["SELF_PVP"] = { text = "Toggle PvP", dist = 0 }
	table.insert(UnitPopupMenus["SELF"], 1, "SELF_PVP")

	-- Whisper all in raid (added or removed below)
	UnitPopupButtons["SELF_SEND_COMMAND_TO_ALL"] = { text = "|cFFFF80FFWhisper to All|r", dist = 0 }
	table.insert(UnitPopupMenus["SELF"], 1, "SELF_SEND_COMMAND_TO_ALL")

	UnitPopupButtons["SELF_RETURN_COMPANIONS"] = { text = "|cffFF0000Return Companions|r", dist = 0, nested = 1 }
	UnitPopupButtons["SELF_RETURN_COMPANIONS_UNFOLLOW"] = { text = "Unfollow All", dist = 0 }
	UnitPopupButtons["SELF_RETURN_COMPANIONS_UNTRANSFER"] = { text = "Untransfer All", dist = 0 }
	UnitPopupButtons["SELF_RETURN_COMPANIONS_REMALL"] = { text = "|cffFF0000Remove All", dist = 0 }

	UnitPopupMenus["SELF_RETURN_COMPANIONS"] = {"SELF_RETURN_COMPANIONS_UNFOLLOW","SELF_RETURN_COMPANIONS_UNTRANSFER","SELF_RETURN_COMPANIONS_REMALL"}
	table.insert(UnitPopupMenus["SELF"], 1, "SELF_RETURN_COMPANIONS")
	
	local tradeString = ""
	if string.find(savedSettings["autoTrade"],"OFF") then tradeString = "|cffFF0000off|r" end
	if string.find(savedSettings["autoTrade"], "ON") then tradeString = "|cff1EFF00on|r" end

	UnitPopupButtons["SELF_MENU_SETTINGS"] = { text = "|cFFFFFFA0Menu Settings|r", dist = 0, nested = 1}
	UnitPopupButtons["SETTINGS_DISP"] = { text = "|cFFFFFFA0Now: Autotrade - |r"..tradeString.."|cFFFFFFA0, Broadcast to - |r"..savedSettings["broadcastTo"], dist = 0 }	
	UnitPopupButtons["SETTINGS_AUTOTRADE_ON"] = { text = "Set Auto Trade Port/Summ: |cff1EFF00on|r", dist = 0 }
	UnitPopupButtons["SETTINGS_AUTOTRADE_OFF"] = { text = "Set Auto Trade Port/Summ: |cffFF0000off|r", dist = 0 }
	UnitPopupButtons["SETTINGS_BROADCAST_NONE"] = { text = "Broadcast to: None", dist = 0 }
	UnitPopupButtons["SETTINGS_BROADCAST_CLASS"] = { text = "Broadcast to: Class", dist = 0 }
	UnitPopupButtons["SETTINGS_BROADCAST_ROLE"] = { text = "Broadcast to: Role", dist = 0 }
	UnitPopupButtons["SETTINGS_BROADCAST_ALL"] = { text = "Broadcast to: All", dist = 0 }
	settingsMenu = {}	
	
	table.insert(settingsMenu,"SETTINGS_DISP")
	if not string.find(savedSettings["autoTrade"],"OFF") then table.insert(settingsMenu,"SETTINGS_AUTOTRADE_OFF") end
	if not string.find(savedSettings["autoTrade"], "ON") then table.insert(settingsMenu,"SETTINGS_AUTOTRADE_ON") end
	if not string.find(savedSettings["broadcastTo"],"NONE") then table.insert(settingsMenu,"SETTINGS_BROADCAST_NONE") end
	if not string.find(savedSettings["broadcastTo"],"CLASS") then table.insert(settingsMenu,"SETTINGS_BROADCAST_CLASS") end
	if not string.find(savedSettings["broadcastTo"],"ROLE") then table.insert(settingsMenu,"SETTINGS_BROADCAST_ROLE") end
	if not string.find(savedSettings["broadcastTo"],"ALL") then table.insert(settingsMenu,"SETTINGS_BROADCAST_ALL") end
	UnitPopupMenus["SELF_MENU_SETTINGS"] = settingsMenu
	table.insert(UnitPopupMenus["SELF"], 1, "SELF_MENU_SETTINGS")

	-- Dungeon Settings (Difficulty, Reset option)
	UnitPopupButtons["SELF_DUNGEON_SETTINGS"] = { text = "|cFFD2B48CDungeon Settings|r", dist = 0, nested = 1 }
	UnitPopupButtons["SELF_DUNGEON_NORMAL"] = { text = "Set Difficulty: |cff1EFF00Normal|r", dist = 0 }
	UnitPopupButtons["SELF_DUNGEON_HEROIC"] = { text = "Set Difficulty: |cFFFFAA00Heroic|r", dist = 0 }	
	UnitPopupButtons["SELF_RESET_INSTANCES"] = { text = "Reset all instances", dist = 0 }
	
	StaticPopupDialogs["SELF_RESET_INSTANCES_CONFIRM"] = {
		text = "Do you really want to reset all of your instances?",
		button1 = TEXT(OKAY),
		button2 = TEXT(CANCEL),
		OnAccept = function()
			RunScript("ResetInstances()")
		end,
		timeout = 0,
		hideOnEscape = 1
	}
	UnitPopupMenus["SELF_DUNGEON_SETTINGS"] = { "SELF_DUNGEON_NORMAL", "SELF_DUNGEON_HEROIC", "SELF_RESET_INSTANCES" }
	table.insert(UnitPopupMenus["SELF"],1,"SELF_DUNGEON_SETTINGS")
	
end)

--[[------------------------------------
    Interface
--------------------------------------]]


function updateSettingsDisplay()
	local tradeString = ""
	if string.find(savedSettings["autoTrade"],"OFF") then tradeString = "|cffFF0000off|r" end
	if string.find(savedSettings["autoTrade"], "ON") then tradeString = "|cff1EFF00on|r" end
	UnitPopupButtons["SETTINGS_DISP"] = { text = "|cFFFFFFA0Now: Autotrade - |r"..tradeString.."|cFFFFFFA0, Broadcast to - |r"..savedSettings["broadcastTo"], dist = 0 }	
	table.remove(settingsMenu,1)
	table.insert(settingsMenu,1,"SETTINGS_DISP")
end

function setBroadcast(mode)
	if (mode == "ALL") then
		if not string.find(savedSettings["broadcastTo"],"ALL") then
			savedSettings["broadcastTo"] = "ALL"
			if not(table_contains(settingsMenu,"SETTINGS_BROADCAST_NONE")) then
				table.insert(settingsMenu,3,"SETTINGS_BROADCAST_NONE")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_ROLE")) then
				table.insert(settingsMenu,4,"SETTINGS_BROADCAST_ROLE")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_CLASS")) then
				table.insert(settingsMenu,5,"SETTINGS_BROADCAST_CLASS")
			end
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_BROADCAST_ALL"))
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Sending to All Companions")
	elseif (mode == "CLASS") then
		if not string.find(savedSettings["broadcastTo"],"CLASS") then
			savedSettings["broadcastTo"] = "CLASS"
			if not(table_contains(settingsMenu,"SETTINGS_BROADCAST_NONE")) then
				table.insert(settingsMenu,3,"SETTINGS_BROADCAST_NONE")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_ALL")) then
				table.insert(settingsMenu,6,"SETTINGS_BROADCAST_ALL")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_ROLE")) then
				table.insert(settingsMenu,4,"SETTINGS_BROADCAST_ROLE")
			end
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_BROADCAST_CLASS"))
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Sending to All Companions of same Class") 
	elseif (mode == "ROLE") then
		if not string.find(savedSettings["broadcastTo"],"ROLE") then
			savedSettings["broadcastTo"] = "ROLE"
			if not(table_contains(settingsMenu,"SETTINGS_BROADCAST_NONE")) then
				table.insert(settingsMenu,3,"SETTINGS_BROADCAST_NONE")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_ALL")) then
				table.insert(settingsMenu,6,"SETTINGS_BROADCAST_ALL")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_CLASS")) then
				table.insert(settingsMenu,4,"SETTINGS_BROADCAST_CLASS")
			end
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_BROADCAST_ROLE"))
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Sending to All Companions of same Role")
	elseif (mode == "NONE") then
		if not string.find(savedSettings["broadcastTo"],"NONE") then
			savedSettings["broadcastTo"] = "NONE"
			if not(table_contains(settingsMenu,"SETTINGS_BROADCAST_CLASS")) then
				table.insert(settingsMenu,4,"SETTINGS_BROADCAST_CLASS")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_ALL")) then
				table.insert(settingsMenu,6,"SETTINGS_BROADCAST_ALL")
			elseif not (table_contains(settingsMenu,"SETTINGS_BROADCAST_ROLE")) then
				table.insert(settingsMenu,3,"SETTINGS_BROADCAST_ROLE")
			end
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_BROADCAST_NONE"))
		end 
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Not sending to other Companions") 	
	end
	updateSettingsDisplay()
end

function toggleBroadcastMode()
	if (savedSettings["broadcastTo"] == "NONE") then
		setBroadcast("CLASS")
	elseif (savedSettings["broadcastTo"] == "CLASS") then
		setBroadcast("ROLE")
	elseif (savedSettings["broadcastTo"] == "ROLE") then
		setBroadcast("ALL")
	elseif (savedSettings["broadcastTo"] == "ALL") then
		setBroadcast("NONE")
	end
end

function setConfirmations(mode)
	if (mode == "ON") then
		if string.find(savedSettings["showConfirmations"],"OFF") then
			savedSettings["showConfirmations"] = "ON"
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_CONFIRMATIONS_ON"))
			table.insert(settingsMenu,3,"SETTINGS_CONFIRMATIONS_OFF")
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Showing Confirmation Popups")
	elseif (mode == "OFF") then
		if string.find(savedSettings["showConfirmations"],"ON") then
			savedSettings["showConfirmations"] = "OFF"
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_CONFIRMATIONS_OFF"))
			table.insert(settingsMenu,3,"SETTINGS_CONFIRMATIONS_ON")
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Not showing Confirmation Popups") 	
	end
end

function toggleConfirmations()
	if string.find(savedSettings["showConfirmations"],"ON") then
		setConfirmations("OFF")
	elseif string.find(savedSettings["showConfirmations"],"OFF") then
		setConfirmations("ON")
	end
end

function setDebug(mode)
	if (mode == "ON") then
		if string.find(savedSettings["Debug"],"OFF") then
			savedSettings["Debug"] = "ON"
			table.insert(UnitPopupMenus["SELF"],6,"SELF_DEBUG")
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Debug on")
	elseif (mode == "OFF") then
		if string.find(savedSettings["Debug"],"ON") then
			savedSettings["Debug"] = "OFF"			
			table.remove(UnitPopupMenus["SELF"],table_index(UnitPopupMenus["SELF"],"SELF_DEBUG"))
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Debug off") 	
	end
end

function setAutoTrade(mode)
	if (mode == "ON") then
		if string.find(savedSettings["autoTrade"],"OFF") then
			savedSettings["autoTrade"] = "ON"
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_AUTOTRADE_ON"))
			table.insert(settingsMenu,2,"SETTINGS_AUTOTRADE_OFF")
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Automatically trading Companions after requesting a Portal/Summon")
	elseif (mode == "OFF") then
		if string.find(savedSettings["autoTrade"],"ON") then
			savedSettings["autoTrade"] = "OFF"
			table.remove(settingsMenu,table_index(settingsMenu,"SETTINGS_AUTOTRADE_OFF"))
			table.insert(settingsMenu,2,"SETTINGS_AUTOTRADE_ON")
		end
		DEFAULT_CHAT_FRAME:AddMessage("Context Menu: Disabled automatically trading Companions after requesting a Portal/Summon") 	
	end
	updateSettingsDisplay()
end

function toggleAutoTrade()
	if string.find(savedSettings["autoTrade"],"ON") then
		setAutoTrade("OFF")
	elseif string.find(savedSettings["autoTrade"],"OFF") then
		setAutoTrade("ON")
	end
end



--[[------------------------------------
    Send Z Commands (Bot Targeted)
--------------------------------------]]
local function SendTargetedBotZCommand(unit, command)
    -- Target the bot whose command we want to send
    TargetUnit(unit)
    -- Use a non-blocking delay mechanism to let the target go through (c_timer does not work, less than a second misses them sometimes)
    local delayTime = 1.0
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
        delayTime = delayTime - arg1
        if delayTime <= 0 then
            MCM_Send(".z " .. command)
            frame:SetScript("OnUpdate", nil)
        end
    end)
end

--[[------------------------------------
    Send Whisper Commands to Bot
--------------------------------------]]
local function SendTargetedBotWhisperCommand(name, command)
    SendChatMessage(command, "WHISPER", nil, name)
end

--[[------------------------------------
    Send Whisper Commands to Entire Party/Raid
--------------------------------------]]
 
local function SendCommandToAll(message)
    local numMembers = 0
    local getNameFunc
    local playerName = UnitName("player")
    
    if UnitInRaid("player") then
        numMembers = GetNumRaidMembers()
        getNameFunc = function(i) 
            local name = GetRaidRosterInfo(i)
            return name
        end
    elseif GetNumPartyMembers() > 0 then
        numMembers = GetNumPartyMembers()
        getNameFunc = function(i) return UnitName("party"..i) end
    else
        DEFAULT_CHAT_FRAME:AddMessage("You are not in a party or raid.")
        return
    end

    for i = 1, numMembers do
        local name = getNameFunc(i)
        if name and name ~= playerName then
            SendChatMessage(message, "WHISPER", GetDefaultLanguage("player"), name)
        end
    end
end

--[[------------------------------------
    Send Whisper Commands to Group of Bots
	Returns: List of Companions that where affected
--------------------------------------]]
local function SendGroupBotWhisperCommand(group, command)
	--DEFAULT_CHAT_FRAME:AddMessage(group.." "..command)
	local targets = {}
	if(group == "All") then
		for _, comp in pairs(ownCompanionNames) do
			SendChatMessage(command, "WHISPER", nil, comp)
			table.insert(targets,comp)
		end
		for _, comp in pairs(followedComps) do
			SendChatMessage(command, "WHISPER", nil, comp)
			table.insert(targets,comp)
		end
	elseif group == "Tank" then
		for _, tank in pairs(tankCompanions) do
			if(table_contains(ownCompanionNames,tank) or table_contains(followedComps,tank)) then
				SendChatMessage(command, "WHISPER", nil, tank)
				table.insert(targets,tank)
			end
		end
	elseif group == "Healer" then
		for _, healer in pairs(healerCompanions) do
			if(table_contains(ownCompanionNames,healer) or table_contains(followedComps,healer)) then
				SendChatMessage(command, "WHISPER", nil, healer)
				table.insert(targets,healer)
			end
		end
	elseif group == "MDPS" then
		for _, mdps in pairs(mdpsCompanions) do
			if(table_contains(ownCompanionNames,mdps) or table_contains(followedComps,mdps)) then
				SendChatMessage(command, "WHISPER", nil, mdps)
				table.insert(targets,mdps)
			end
		end
	elseif group == "RDPS" then
		for _, rdps in pairs(rdpsCompanions) do
			if(table_contains(ownCompanionNames,rdps) or table_contains(followedComps,rdps)) then
				SendChatMessage(command, "WHISPER", nil, rdps)
				table.insert(targets,rdps)
			end
		end
	elseif group == "Druid" then
		for _, druid in pairs(druidCompanions) do
			if(table_contains(ownCompanionNames,druid) or table_contains(followedComps,druid)) then
				SendChatMessage(command, "WHISPER", nil, druid)
				table.insert(targets,druid)
			end
		end
	elseif group == "Hunter" then
		for _, hunter in pairs(hunterCompanions) do			
			if(table_contains(ownCompanionNames,hunter) or table_contains(followedComps,hunter)) then
				SendChatMessage(command, "WHISPER", nil, hunter)
				table.insert(targets,hunter)
			end
		end
	elseif group == "Mage" then
		for _, mage in pairs(mageCompanions) do
			if(table_contains(ownCompanionNames,mage) or table_contains(followedComps,mage)) then
				SendChatMessage(command, "WHISPER", nil, mage)
				table.insert(targets,mage)
			end
		end
	elseif group == "Paladin" then
		for _, paladin in pairs(paladinCompanions) do
			if(table_contains(ownCompanionNames,paladin) or table_contains(followedComps,paladin)) then
				SendChatMessage(command, "WHISPER", nil, paladin)
				table.insert(targets,paladin)
			end
		end
	elseif group == "Priest" then
		for _, priest in pairs(priestCompanions) do
			if(table_contains(ownCompanionNames,priest) or table_contains(followedComps,priest)) then
				SendChatMessage(command, "WHISPER", nil, priest)
				table.insert(targets,priest)
			end
		end
	elseif group == "Rogue" then
		for _, rogue in pairs(rogueCompanions) do
			if(table_contains(ownCompanionNames,rogue) or table_contains(followedComps,rogue)) then
				SendChatMessage(command, "WHISPER", nil, rogue)
				table.insert(targets,rogue)
			end
		end
	elseif group == "Shaman" then
		for _, shaman in pairs(shamanCompanions) do			
			if(table_contains(ownCompanionNames,shaman) or table_contains(followedComps,shaman)) then
				SendChatMessage(command, "WHISPER", nil, shaman)
				table.insert(targets,shaman)
			end
		end	
	elseif group == "Warlock" then
		for _, warlock in pairs(warlockCompanions) do
			if(table_contains(ownCompanionNames,warlock) or table_contains(followedComps,warlock)) then
				SendChatMessage(command, "WHISPER", nil, warlock)
				table.insert(targets,warlock)
			end
		end	
	elseif group == "Warrior" then
		for _, warrior in pairs(warriorCompanions) do
			if(table_contains(ownCompanionNames,warrior) or table_contains(followedComps,warrior)) then
				SendChatMessage(command, "WHISPER", nil, warrior)
				table.insert(targets,warrior)
			end
		end	
	end
	return targets
end

--[[------------------------------------
    Send Whisper Commands to Bots based on Broadcast Settings and valid Modes for the command, returns what was affected by the command for output
--------------------------------------]]
local function BroadcastBotWhisperCommand(validModes, command)
	local result = {}
	if (savedSettings["broadcastTo"] == "ALL" and table_contains(validModes,"ALL")) then 
		result["targets"] = SendGroupBotWhisperCommand("All", command) 
		result["group"] = "all Companions"
	elseif (savedSettings["broadcastTo"] == "ROLE" and table_contains(validModes,"ROLE")) then 
		result["targets"] = SendGroupBotWhisperCommand(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"], command)
		result["group"] = allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"]
	elseif (savedSettings["broadcastTo"] == "CLASS" and table_contains(validModes,"CLASS")) then 
		result["targets"] = SendGroupBotWhisperCommand(MICROBOT_SELECTED_UNIT_CLASS, command)
		result["group"] = MICROBOT_SELECTED_UNIT_CLASS.."s"
	else 
		SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, command)	
		result["targets"] = {MICROBOT_SELECTED_UNIT_NAME}
		result["group"] = MICROBOT_SELECTED_UNIT_NAME		
	end
	return result
end

-- Create a StaticPopupDialog for the text input
StaticPopupDialogs["SEND_COMMAND_TO_ALL"] = {
    text = "Enter a command to whisper to all raid/party members:",
    button1 = "Send",
    button2 = "Cancel",
    OnAccept = function()
        local editBox = getglobal(this:GetParent():GetName().."EditBox")
        local message = editBox:GetText()
        SendCommandToAll(message)
        editBox:SetText("")
    end,
    OnShow = function()
        local editBox = getglobal(this:GetName().."EditBox")
        editBox:SetText("")
        editBox:SetScript("OnEnterPressed", function()
            local message = this:GetText()
            SendCommandToAll(message)
            this:SetText("")
            StaticPopup_Hide("SEND_COMMAND_TO_ALL")
        end)
    end,
    OnHide = function()
        local editBox = getglobal(this:GetName().."EditBox")
        editBox:SetScript("OnEnterPressed", nil)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    hasEditBox = true,
    editBoxWidth = 400,
}


--[[------------------------------------
	UI handling
--------------------------------------]]
function closeSetPercentageFrame()
	drinkRequested = nil	
	eatRequested = nil
	healRequested = nil
	healOocRequested = nil
	offHealRequested = nil
	offDpsRequested = nil
	SetPercentageFrame:Hide();
end

function confirmSetPercentageFrame()
	if (drinkRequested) then
		local value = SetDrinkEatEditBox:GetText()
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set drink "..value)
		drinkRequested = nil
		SetPercentageFrame:Hide();
	elseif (eatRequested) then
		local value = SetDrinkEatEditBox:GetText()
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set eat "..value)
		eatRequested = nil
		SetPercentageFrame:Hide();
	elseif (healRequested) then
		local value = SetDrinkEatEditBox:GetText()
		BroadcastBotWhisperCommand({"ROLE","CLASS"},"set heal "..value)
		healRequested = nil
		SetPercentageFrame:Hide();
	elseif (healOocRequested) then
		local value = SetDrinkEatEditBox:GetText()
		BroadcastBotWhisperCommand({"ROLE","CLASS"},"set healooc "..value)
		healOocRequested = nil
		SetPercentageFrame:Hide();
	elseif (offHealRequested) then
		local value = SetDrinkEatEditBox:GetText()
		BroadcastBotWhisperCommand({"ROLE","CLASS"},"set offheal "..value)
		offHealRequested = nil
		SetPercentageFrame:Hide();
	elseif (offDpsRequested) then
		local value = SetDrinkEatEditBox:GetText()
		BroadcastBotWhisperCommand({"ROLE","CLASS"},"set offdps "..value)
		offDpsRequested = nil
		SetPercentageFrame:Hide();	
	end
end

function closeSetDistanceFrame()
	SetDistanceFrame:Hide();
end

function confirmSetDistanceFrame()
	local value = SetDistanceEditBox:GetText()
	BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation distance "..value)
	SetDistanceFrame:Hide();
end

--[[------------------------------------
    Define Class Colors for Addon
--------------------------------------]]
local CLASS_COLORS = {
    ["WARRIOR"] = "cFFC79C6E",
    ["MAGE"]    = "cFF69CCF0",
    ["ROGUE"]   = "cFFFFF569",
    ["DRUID"]   = "cFFFF7D0A",
    ["HUNTER"]  = "cFFABD473",
    ["SHAMAN"]  = "cFF0070DE",
    ["PRIEST"]  = "cFFFFFFA0",  -- Slightly yellow-tinted
    ["WARLOCK"] = "cFF9482C9",
    ["PALADIN"] = "cFFF58CBA"
}
local function getUnitClassColor(unit)
    local _, class = UnitClass(unit)
    return CLASS_COLORS[string.upper(class)] or "cFFFFFFFF"  -- Default to white if class not found
end

--[[------------------------------------
    Find Raid Group for Unit
--------------------------------------]]
local function GetUnitRaidGroup(unit)
    if UnitInRaid(unit) then
        for i = 1, 40 do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name == UnitName(unit) then
                return subgroup
            end
        end
    end
    return nil
end
	
--[[------------------------------------
    Get Local Group Members and Build Menu Buttons
--------------------------------------]]
local function GetLocalGroupMembers(unit, includePlayer, includeTarget, buttonPrefix)
    local members = {}
    local menuItems = {}
    local playerName = UnitName("player")
    local targetName = UnitName(unit)
    local isInRaid = UnitInRaid("player")
    local unitGroup = GetUnitRaidGroup(unit)

    if includePlayer then
        local playerColorCode = getUnitClassColor("player")
        table.insert(members, {name = playerName, colorCode = playerColorCode, isPlayer = true})
    end
	
	if (otherPlayers) then
		for _, player in ipairs(otherPlayers) do
			table.insert(members, {name = player, colorCode = "cFFFFFFFF", isPlayer = false})
		end
	end

    if isInRaid then
        -- In a raid, add members of the unit's group
        for i = 1, 40 do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name and subgroup == unitGroup and (includeTarget or name ~= targetName) and name ~= playerName and not table_contains(otherPlayers,name) then
                local colorCode = getUnitClassColor("raid"..i)
                table.insert(members, {name = name, colorCode = colorCode, isPlayer = false})
            end
        end
    else
        -- In a party, add all party members
        for i = 1, GetNumPartyMembers() do
            local partyUnit = "party"..i
            local name = GetUnitName(partyUnit)
            if name and (includeTarget or name ~= targetName) and name ~= playerName and not table_contains(otherPlayers,name) then
                local colorCode = getUnitClassColor(partyUnit)
                table.insert(members, {name = name, colorCode = colorCode, isPlayer = false})
            end
        end
    end

    -- Build menu items for each member
    for _, member in ipairs(members) do
        local buttonName = buttonPrefix .. "_" .. member.name
        local displayText = "|" .. member.colorCode .. member.name .. "|r" 
        if member.isPlayer then
            displayText = displayText .. " (Me)"
        end
        UnitPopupButtons[buttonName] = { text = displayText, dist = 0 }
        table.insert(menuItems, buttonName)
    end

    return menuItems
end


--[[---------------------------------------------------------------------------------
  COMPANION MENU COMMANDS
----------------------------------------------------------------------------------]]
-- Hook the UnitPopup_ShowMenu function to establish the variables of which party member is being clicked
local originalUnitPopupShowMenu = UnitPopup_ShowMenu
function UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
    --[[--------------------------
        Initialize Unit Menu
    ----------------------------]]
    -- Check if the unit is valid and in party or raid
    local isValidUnitInPartyOrRaid = false
    isValidUnitInPartyOrRaid = UnitInParty(unit) or UnitInRaid(unit)
		
	-- BOT CONTROL MENU: Clear prior settings
	-- Remove any existing class-specific menus
	local i = table.getn(UnitPopupMenus["PLAYER"])
	while i > 0 do
		local menu = UnitPopupMenus["PLAYER"][i]
		if string.find(menu, "^BOT_") then
			table.remove(UnitPopupMenus["PLAYER"], i)
		end
		i = i - 1
	end	
	
	-- BOT CONTROL MENU: Clear prior settings
	-- Remove any existing class-specific menus
	local i = table.getn(UnitPopupMenus["PARTY"])
	while i > 0 do
		local menu = UnitPopupMenus["PARTY"][i]
		if string.find(menu, "^BOT_") then
			table.remove(UnitPopupMenus["PARTY"], i)
		end
		i = i - 1
	end


    -- If the unit is not in party/raid, fall back to the original menu
    if not isValidUnitInPartyOrRaid then
        return originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)
    end
    -- Store the unit, name, class, faction, and level in global variables
    MICROBOT_SELECTED_UNIT = unit
    MICROBOT_SELECTED_UNIT_NAME = tostring(UnitName(unit))
    MICROBOT_SELECTED_UNIT_CLASS = tostring(UnitClass(unit))
    MICROBOT_SELECTED_UNIT_FACTION = UnitFactionGroup(unit)
    MICROBOT_SELECTED_UNIT_RACE = UnitRace(unit)
    MICROBOT_SELECTED_UNIT_LEVEL = UnitLevel(unit)

    -- Check if the selected unit is the player
    if MICROBOT_SELECTED_UNIT_NAME == UnitName("player") then
        -- If it is, show the self menu instead
        return originalUnitPopupShowMenu(dropdownMenu, "SELF", unit, name, userData)
    end
	
	--Create Markers to indicate if a Menu is affected by current Broadcast settings
	if(savedSettings["broadcastTo"] == "ALL") then
		markerBCAll = " - All"
	else
		markerBCAll = ""
	end
	if(savedSettings["broadcastTo"] == "ROLE") then
		markerBCRole = " - Role"
	else
		markerBCRole = ""
	end
	if(savedSettings["broadcastTo"] == "CLASS") then
		markerBCClass = " - Class"
	else
		markerBCClass = ""
	end
	
 
    -- BOT CONTROL MENU: Declare top level defaults
    UnitPopupButtons["BOT_CONTROL"] = { text = "|cFFFFAA00Companion Settings|r", dist = 0, nested = 1 }
    UnitPopupButtons["BOT_TOGGLE_HELM"] = {text = "Toggle Helm", dist = 0}
    UnitPopupButtons["BOT_TOGGLE_CLOAK"] = { text = "Toggle Cloak", dist = 0 }
    UnitPopupButtons["BOT_TOGGLE_AOE"] = { text = "Toggle AoE", dist = 0 }
    UnitPopupMenus["BOT_CONTROL"] = { "BOT_TOGGLE_AOE","BOT_TOGGLE_HELM", "BOT_TOGGLE_CLOAK"}
	
	
	 -- Target the PARTY dropdown menu by default
	local menuFrame = "PARTY"
	
	
	-- this is needed to get ContextMenus for our target
	if(which == "PLAYER") then 	
		menuFrame = "PLAYER"	
	end
		
    -- Remove any existing custom options from BOT_CONTROL menu
    i = table.getn(UnitPopupMenus["BOT_CONTROL"])
    while i > 0 do
        local option = UnitPopupMenus["BOT_CONTROL"][i]
        if string.find(option, "^BOT_ROLE_") or string.find(option, "^BOT_DENY") then
            table.remove(UnitPopupMenus["BOT_CONTROL"], i)
        end
        i = i - 1
    end
	
	--After Menu is cleared, check if unit is a bot of the player and show default if it is not
	--[[if (UIDROPDOWNMENU_MENU_LEVEL == 1) then -- only do it once per right click
		updateData()
	end	]]
	
	if(allCompanionInfos and table_length(allCompanionInfos) > 0) then 
		if not(table_contains(otherPlayers,MICROBOT_SELECTED_UNIT_NAME)) then --Is this a companion?
			if not(table_contains(ownCompanionNames,MICROBOT_SELECTED_UNIT_NAME)) then -- check if unit is a companion of the player				
				if(table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) then -- check if we have previously followed this bot
					--one you followed, add unfollow option
					UnitPopupButtons["BOT_UNFOLLOW"] = { text = "Unfollow"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
					table.insert(UnitPopupMenus[menuFrame],1,"BOT_UNFOLLOW")
					--return originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)	
				elseif (table_contains(transferredComps,MICROBOT_SELECTED_UNIT_NAME)) then -- check if we have previously followed this bot
					--one you transferred, add untransfer option
					UnitPopupButtons["BOT_UNTRANSFER"] = { text = "Untransfer"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
					table.insert(UnitPopupMenus[menuFrame],1,"BOT_UNTRANSFER")
					return originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)
				else
					-- None of the companions you control, open normal Menu
					return originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)
				end				
			end
		else --Other player, open normal Menu.
			return originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)
		end
	else
		-- no Copanions info but someone to rightclick, must be in a fresh group with another Player			
		return originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)
	end
	
    -- Remove the whisper all command if present
    for i, v in ipairs(UnitPopupMenus["SELF"]) do
        if v == "SELF_SEND_COMMAND_TO_ALL" then
            table.remove(UnitPopupMenus["SELF"], i)
            break
        end
    end

    -- Add the whisper all command after dungeon settings if in party or raid
    if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then
        for i, v in ipairs(UnitPopupMenus["SELF"]) do
            if v == "SELF_DUNGEON_SETTINGS" then
                table.insert(UnitPopupMenus["SELF"], i + 1, "SELF_SEND_COMMAND_TO_ALL")
                break
            end
        end
    end

    --[[--------------------------
        Add Companion Settings
    ----------------------------]]
    -- COMPANION ROLES: Define & insert role button settings into bot control menu
    local roleButtons = {
        ["BOT_ROLE_TANK"] = "|cFFC79C6ETank|r",
        ["BOT_ROLE_HEALER"] = "|cFFF58CBAHealer|r",
        ["BOT_ROLE_DPS"] = "|cFF69CCF0DPS|r",
        ["BOT_ROLE_MDPS"] = "|cFFFFF569Melee DPS|r",
        ["BOT_ROLE_RDPS"] = "|cFFABD473Ranged DPS|r"
    }
    for id, text in pairs(roleButtons) do
        UnitPopupButtons[id] = { text = "|cFFFFAA00Set Role:|r " .. text, dist = 0 }
    end

    -- Add role options to BOT_CONTROL menu based on class and set color of companions menu
    local classSettings = {
        ["Warrior"] = {color = "C79C6E", roles = {"TANK", "MDPS"}},
        ["Paladin"] = {color = "F58CBA", roles = {"TANK", "HEALER", "MDPS"}},
        ["Hunter"] = {color = "ABD473", roles = {}},
        ["Rogue"] = {color = "FFF569", roles = {}},
        ["Priest"] = {color = "FFFFA0", roles = {"HEALER", "RDPS"}},
        ["Shaman"] = {color = "0070DE", roles = {"TANK", "HEALER", "MDPS", "RDPS"}},
        ["Mage"] = {color = "69CCF0", roles = {}},
        ["Warlock"] = {color = "9482C9", roles = {}},
        ["Druid"] = {color = "FF7D0A", roles = {"TANK", "HEALER", "MDPS", "RDPS"}}
    }

    local classInfo = classSettings[MICROBOT_SELECTED_UNIT_CLASS]
    UnitPopupButtons["BOT_CONTROL"].text = "|cFF" .. classInfo.color .. "Companion Settings|r"
    for _, role in ipairs(classInfo.roles) do
		if not(string.find(string.upper(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"]), role)) then
			table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_ROLE_" .. role)
		end
    end
	
	UnitPopupButtons["BOT_DRINK"] = { text = "Set Drink"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }	
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_DRINK")	
	UnitPopupButtons["BOT_EAT"] = { text = "Set Eat"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }	
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_EAT")	
	if(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"] and allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"] == "Healer") then 
		UnitPopupButtons["BOT_HEAL"] = { text = "Set |cFFF58CBAHeal|r"..markerBCRole..markerBCClass, dist = 0 }	
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_HEAL")
		UnitPopupButtons["BOT_HEALOOC"] = { text = "Set |cFFF58CBAHealOOC|r"..markerBCRole..markerBCClass, dist = 0 }	
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_HEALOOC")
	end
	-- Sets a Health Treshold under which to start offhealing
	UnitPopupButtons["BOT_OFFHEAL"] = { text = "Set |cFFF58CBAOffheal|r"..markerBCRole..markerBCClass, dist = 0 }	
	-- Set a Mana Treshold when to stop casting DPS Spells
	UnitPopupButtons["BOT_OFFDPS"] = { text = "Set |cFF69CCF0Offdps|r"..markerBCRole..markerBCClass, dist = 0 }
		
	if (MICROBOT_SELECTED_UNIT_CLASS == "Priest" and allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"] and string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"],"RDPS")) then
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFHEAL")
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFDPS")
	elseif (MICROBOT_SELECTED_UNIT_CLASS == "Paladin" and allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"] and string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"],"MDPS")) then
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFHEAL")
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFDPS")
	elseif (MICROBOT_SELECTED_UNIT_CLASS == "Druid" and allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"] and string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"],"RDPS")) then
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFHEAL")
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFDPS")
	elseif (MICROBOT_SELECTED_UNIT_CLASS == "Shaman" and allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"] and string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"],"DPS")) then
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFHEAL")
		table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_OFFDPS") 
	end
	
	UnitPopupButtons["BOT_LIMITER_ON"] = { text = "Threat Limiter |cff1EFF00on|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }	
	UnitPopupButtons["BOT_LIMITER_OFF"] = { text = "Threat Limiter |cffFF0000off|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_LIMITER_ON")
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_LIMITER_OFF")	
	
	-- Add to List of assigned Tanks
	UnitPopupButtons["BOT_ASSIGN_TANK"] = { text = "|cff1EFF00Assign|r as |cFFC79C6ETank|r"..markerBCRole, dist = 0 }
	UnitPopupButtons["BOT_UNASSIGN_TANK"] = { text = "|cffFF0000Unassign|r as |cFFC79C6ETank|r"..markerBCRole, dist = 0 }		
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_ASSIGN_TANK")
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_UNASSIGN_TANK")
	
    -- Deny danger spells (added after roles by class for those that have them)
    UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny Danger Spells", dist = 0 }
	
	UnitPopupButtons["BOT_RESET"] = { text = "Reset Companion"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }	
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_RESET")
	
	-- Add Debug controls 
    UnitPopupButtons["BOT_DEBUG_ON"] = { text = "Debug |cff1EFF00on|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }	
	UnitPopupButtons["BOT_DEBUG_OFF"] = { text = "Debug |cffFF0000off|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_DEBUG_ON")
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_DEBUG_OFF")	
	
	UnitPopupButtons["BOT_LIST_SPELLS"] = { text = "List Spells", dist = 0 }	
	UnitPopupButtons["BOT_LIST_GEAR"] = { text = "List Gear", dist = 0 }
	UnitPopupButtons["BOT_LIST_TALENTS"] = { text = "List Talents", dist = 0 }
	UnitPopupButtons["BOT_LIST_STATUS"] = { text = "List Status", dist = 0 }	
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_LIST_SPELLS")
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_LIST_GEAR")
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_LIST_TALENTS")
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_LIST_STATUS")
	
	
	-- Clear Deny list
	UnitPopupButtons["BOT_DENY_CLEAR"] = { text = "Clear |cffFF0000deny|r List"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
	table.insert(UnitPopupMenus["BOT_CONTROL"],"BOT_DENY_CLEAR")
	
    -- Insert BOT_CONTROL into the PARTY menu
    table.insert(UnitPopupMenus[menuFrame], 1, "BOT_CONTROL")
	
	
	--Preparing Revival Options, will be added in the Classes that can revive. 
	UnitPopupButtons["BOT_SOULSTONE_DENY"] = { text = "|cffFF0000Deny|r Soulstone use"..markerBCRole..markerBCClass, dist = 0 }	
	UnitPopupButtons["BOT_SOULSTONE_ALLOW"] = { text = "|cff1EFF00Allow|r Soulstone use"..markerBCRole..markerBCClass, dist = 0 }
	UnitPopupButtons["BOT_DISPEL_DI"] = { text = "Dispel Divine Intervention"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }	

    -- Conditionally edit the tables for each class
    local dynamicMenus = {}
    --[[--------------------------
        Mage
    ----------------------------]]
    if MICROBOT_SELECTED_UNIT_CLASS == "Mage" then
        -- MAGE: Group portals
        UnitPopupButtons["BOT_OPEN_PORTAL"] = { text = "|cFF69CCF0Open Portal|r", dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PORTAL_STORMWIND"] = { text = "Stormwind", dist = 0 }
        UnitPopupButtons["BOT_PORTAL_IRONFORGE"] = { text = "Ironforge", dist = 0 }
        UnitPopupButtons["BOT_PORTAL_DARNASSUS"] = { text = "Darnassus", dist = 0 }
        UnitPopupButtons["BOT_PORTAL_ORGRIMMAR"] = { text = "Orgrimmar", dist = 0 }
        UnitPopupButtons["BOT_PORTAL_UNDERCITY"] = { text = "Undercity", dist = 0 }
        UnitPopupButtons["BOT_PORTAL_THUNDER_BLUFF"] = { text = "Thunder Bluff", dist = 0 }
        local portals = {}
        if MICROBOT_SELECTED_UNIT_LEVEL >= 40 then
            if MICROBOT_SELECTED_UNIT_RACE == "Human" or MICROBOT_SELECTED_UNIT_RACE == "Dwarf" or MICROBOT_SELECTED_UNIT_RACE == "Gnome" or MICROBOT_SELECTED_UNIT_RACE == "NightElf" then
                table.insert(portals, "BOT_PORTAL_STORMWIND")
                table.insert(portals, "BOT_PORTAL_IRONFORGE")
                if MICROBOT_SELECTED_UNIT_LEVEL >= 50 then
                    table.insert(portals, "BOT_PORTAL_DARNASSUS")
                end
            elseif MICROBOT_SELECTED_UNIT_RACE == "Orc" or MICROBOT_SELECTED_UNIT_RACE == "Troll" or MICROBOT_SELECTED_UNIT_RACE == "Tauren" or MICROBOT_SELECTED_UNIT_RACE == "Undead" then
                table.insert(portals, "BOT_PORTAL_ORGRIMMAR")
                table.insert(portals, "BOT_PORTAL_UNDERCITY")
                if MICROBOT_SELECTED_UNIT_LEVEL >= 50 then
                    table.insert(portals, "BOT_PORTAL_THUNDER_BLUFF")
                end
            end
            if table.getn(portals) > 0 then
                UnitPopupMenus["BOT_OPEN_PORTAL"] = portals
                table.insert(dynamicMenus, "BOT_OPEN_PORTAL")
            end
        end

        -- MAGE: Amplify Magic options
        UnitPopupButtons["BOT_MAGE_AMPLIFY_MAGIC"] = { text = "|cFF69CCF0Set Amplify Magic|r", dist = 0, nested = 1 }
        UnitPopupButtons["BOT_MAGE_AMPLIFY_USE"] = { text = "Use Amplify Magic", dist = 0 }
        UnitPopupButtons["BOT_MAGE_DAMPEN_USE"] = { text = "Use Dampen Magic", dist = 0 }
        UnitPopupButtons["BOT_MAGE_AMPLIFY_NEITHER"] = { text = "None", dist = 0 }
        if MICROBOT_SELECTED_UNIT_LEVEL >= 12 then -- Dampen Magic is learned at level 12
            local amplifyMagicOptions = {"BOT_MAGE_DAMPEN_USE","BOT_MAGE_AMPLIFY_NEITHER"}
            if MICROBOT_SELECTED_UNIT_LEVEL >= 18 then -- Amplify Magic is learned at level 18
                table.insert(amplifyMagicOptions, 1, "BOT_MAGE_AMPLIFY_USE")
            end
            UnitPopupMenus["BOT_MAGE_AMPLIFY_MAGIC"] = amplifyMagicOptions
            table.insert(dynamicMenus, "BOT_MAGE_AMPLIFY_MAGIC")
        end
		-- MAGE: Specc options
        UnitPopupButtons["BOT_MAGE_SPEC"] = { text = "|cFF69CCF0Set Spec|r"..markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_MAGE_SPEC_ARCANE"] = { text = "|cFFf069ccArcane|r", dist = 0 }
        UnitPopupButtons["BOT_MAGE_SPEC_FIRE"] = { text = "|cFFFF4500Fire|r", dist = 0 }
        UnitPopupButtons["BOT_MAGE_SPEC_FROST"] = { text = "|cFF34EBD2Frost|r", dist = 0 }
		local mageSpecs = {}
		if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["specc"],"1")) then
			table.insert(mageSpecs,"BOT_MAGE_SPEC_FROST")
		end
		if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["specc"],"2")) then
			table.insert(mageSpecs,"BOT_MAGE_SPEC_FIRE")
		end
		if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["specc"],"3")) then
			table.insert(mageSpecs,"BOT_MAGE_SPEC_ARCANE")
		end
		UnitPopupMenus["BOT_MAGE_SPEC"] = mageSpecs
		table.insert(dynamicMenus, "BOT_MAGE_SPEC")
        -- Deny Danger Spells
        if MICROBOT_SELECTED_UNIT_LEVEL >= 20 or savedSettings["broadcastTo"] == "ALL" then -- Blink is learned at level 20, always show if you are broadcasting to all
            UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny |cFF69CCF0Danger Spells|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
            table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_DENY_DANGER_SPELLS")
        end

    --[[--------------------------
        Hunter
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Hunter" then
        -- HUNTER: Choose pet type
        UnitPopupButtons["BOT_HUNTER_PET"] = { text = "|cFFABD473Choose Beast|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_HUNTER_PET_BAT"] = { text = "|cFFFF7D0ABat|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_BEAR"] = { text = "|cFF0070DEBear|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_BOAR"] = { text = "|cFF0070DEBoar|r |cFFFFFFFF(Charge)|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_BIRD"] = { text = "|cFFFFF569Carrion Bird|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_CAT"] = { text = "|cFFFF7D0ACat|r |cFFFFFFFF(Prowl)|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_CRAB"] = { text = "|cFF0070DECrab|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_CROC"] = { text = "|cFF0070DECrocolisk|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_GORILLA"] = { text = "|cFF0070DEGorilla|r |cFFFFFFFF(Thunderstomp)|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_HYENA"] = { text = "|cFFFFF569Hyena|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_OWL"] = { text = "|cFFFF7D0AOwl|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_RAPTOR"] = { text = "|cFFFF7D0ARaptor|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_SCORPID"] = { text = "|cFF0070DEScorpid|r |cFFFFFFFF(Scorpid Poison)|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_SPIDER"] = { text = "|cFFFF7D0ASpider|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_STRIDER"] = { text = "|cFF0070DETallstrider|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_TURTLE"] = { text = "|cFF0070DETurtle|r |cFFFFFFFF(Shell Shield)|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_SERPENT"] = { text = "|cFFFF7D0AWind Serpent|r |cFFFFFFFF(Lightning Breath)|r", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_PET_WOLF"] = { text = "|cFFFFF569Wolf|r |cFFFFFFFF(Furious Howl)|r", dist = 0 }
        UnitPopupMenus["BOT_HUNTER_PET"] = {
            "BOT_HUNTER_PET_BAT",
            "BOT_HUNTER_PET_BEAR",
            "BOT_HUNTER_PET_BOAR",
            "BOT_HUNTER_PET_BIRD",
            "BOT_HUNTER_PET_CAT",
            "BOT_HUNTER_PET_CRAB",
            "BOT_HUNTER_PET_CROC",
            "BOT_HUNTER_PET_GORILLA",
            "BOT_HUNTER_PET_HYENA",
            "BOT_HUNTER_PET_OWL",
            "BOT_HUNTER_PET_RAPTOR",
            "BOT_HUNTER_PET_SCORPID", 
            "BOT_HUNTER_PET_SPIDER",
            "BOT_HUNTER_PET_STRIDER",
            "BOT_HUNTER_PET_TURTLE",
            "BOT_HUNTER_PET_SERPENT",
            "BOT_HUNTER_PET_WOLF"
        }
        if MICROBOT_SELECTED_UNIT_LEVEL >= 10 then -- Hunters get pets at level 10
            UnitPopupButtons["BOT_PET_TOGGLE"] = { text = "|cFFABD473Pet Control|r".. markerBCClass, dist = 0, nested = 1 }
            UnitPopupButtons["BOT_PET_ON"] = { text = "|cff1EFF00Summon Pet|r", dist = 0 }
            UnitPopupButtons["BOT_PET_OFF"] = { text = "|cffFF0000Dismiss Pet|r", dist = 0 }			
            UnitPopupButtons["BOT_PET_GROWL_OFF"] = { text = "|cffFF0000Deny|r Growl", dist = 0 }
			UnitPopupButtons["BOT_PET_GROWL_ON"] = { text = "|cff1EFF00Allow|r Growl", dist = 0 }
            UnitPopupMenus["BOT_PET_TOGGLE"] = { "BOT_PET_ON", "BOT_PET_OFF","BOT_PET_GROWL_OFF","BOT_PET_GROWL_ON"}
            table.insert(dynamicMenus, "BOT_PET_TOGGLE")
            table.insert(dynamicMenus, "BOT_HUNTER_PET")
        end

        -- HUNTER: Choose aspect
        UnitPopupButtons["BOT_HUNTER_ASPECT_DEFAULT"] = { text = "AI Default (Clear Setting)", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_ASPECT_HAWK"] = { text = "Aspect of the Hawk", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_ASPECT_CHEETAH"] = { text = "Aspect of the Cheetah", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_ASPECT_PACK"] = { text = "Aspect of the Pack", dist = 0 }
        UnitPopupButtons["BOT_HUNTER_ASPECT_WILD"] = { text = "Aspect of the Wild", dist = 0 }
        local aspects = {
            -- Monkey omitted intentionally (cannot be set)
            {level = 10,  id = "BOT_HUNTER_ASPECT_HAWK"},
            {level = 20, id = "BOT_HUNTER_ASPECT_CHEETAH"},
            -- Beast omitted intentionally (cannot be set)
            {level = 40, id = "BOT_HUNTER_ASPECT_PACK"},
            {level = 46, id = "BOT_HUNTER_ASPECT_WILD"}
        }
        local aspectItems = {}
        for i = 1, table.getn(aspects) do
            if MICROBOT_SELECTED_UNIT_LEVEL >= aspects[i].level then
                table.insert(aspectItems, aspects[i].id)
            end
        end
        if table.getn(aspectItems) > 0 then
            table.insert(aspectItems, 1, "BOT_HUNTER_ASPECT_DEFAULT")
            UnitPopupMenus["BOT_HUNTER_ASPECT"] = aspectItems
            UnitPopupButtons["BOT_HUNTER_ASPECT"] = { text = "|cFFABD473Set Aspect|r" .. markerBCClass, dist = 0, nested = 1 }
            table.insert(dynamicMenus, "BOT_HUNTER_ASPECT")
        end
    -- HUNTER: Deny dangerous spells
    if MICROBOT_SELECTED_UNIT_LEVEL >= 8 or savedSettings["broadcastTo"] == "ALL" then -- Scare Beast is learned at level 8, always show if you are broadcasting to all
        UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny |cFFABD473Danger Spells|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
        table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_DENY_DANGER_SPELLS")
    end

    --[[--------------------------
        Warlock
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Warlock" then
        -- WARLOCK: Summon player ritual
        UnitPopupButtons["BOT_WARLOCK_SUMMON_PLAYER_RITUAL"] = { text = "|cFF9482C9Summon Player|r", dist = 0 }
        if MICROBOT_SELECTED_UNIT_LEVEL >= 20 then
            table.insert(dynamicMenus, "BOT_WARLOCK_SUMMON_PLAYER_RITUAL")
        end
        -- WARLOCK: Choose pet type
        UnitPopupButtons["BOT_WARLOCK_PET"] = { text = "|cFF9482C9Choose Demon|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_WARLOCK_PET_IMP"] = { text = "Imp", dist = 0 }
        UnitPopupButtons["BOT_WARLOCK_PET_VOIDWALKER"] = { text = "Voidwalker", dist = 0 }
        UnitPopupButtons["BOT_WARLOCK_PET_SUCCUBUS"] = { text = "Succubus", dist = 0 }
        UnitPopupButtons["BOT_WARLOCK_PET_FELHUNTER"] = { text = "Felhunter", dist = 0 }
        UnitPopupButtons["BOT_PET_TOGGLE"] = { text = "|cFF9482C9Pet Control|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PET_ON"] = { text = "|cff1EFF00Summon Pet|r" , dist = 0 }
        UnitPopupButtons["BOT_PET_OFF"] = { text = "|cffFF0000Dismiss Pet|r", dist = 0 }
        UnitPopupMenus["BOT_PET_TOGGLE"] = { "BOT_PET_ON", "BOT_PET_OFF" }
        UnitPopupMenus["BOT_WARLOCK_PET"] = { "BOT_WARLOCK_PET_IMP" }
        if MICROBOT_SELECTED_UNIT_LEVEL >= 10 then
            table.insert(UnitPopupMenus["BOT_WARLOCK_PET"], "BOT_WARLOCK_PET_VOIDWALKER")
        end
        if MICROBOT_SELECTED_UNIT_LEVEL >= 20 then
            table.insert(UnitPopupMenus["BOT_WARLOCK_PET"], "BOT_WARLOCK_PET_SUCCUBUS")
        end
        if MICROBOT_SELECTED_UNIT_LEVEL >= 30 then
            table.insert(UnitPopupMenus["BOT_WARLOCK_PET"], "BOT_WARLOCK_PET_FELHUNTER")
        end
        if MICROBOT_SELECTED_UNIT_LEVEL >= 8 or savedSettings["broadcastTo"] == "ALL" then -- Fear is learned at level 8, always show if you are broadcasting to all
            UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny |cFF9482C9Danger Spells|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
            table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_DENY_DANGER_SPELLS")
        end
        table.insert(dynamicMenus, "BOT_PET_TOGGLE")
        table.insert(dynamicMenus, "BOT_WARLOCK_PET")
        
        -- WARLOCK: Set Soulstone on
        if MICROBOT_SELECTED_UNIT_LEVEL >= 18 then -- Soulstone is learned at level 18
            UnitPopupButtons["BOT_WARLOCK_SOULSTONE"] = { text = "|cFF9482C9Set Soulstone On|r"..markerBCClass, dist = 0, nested = 1 }
			local soulstoneTargets = GetLocalGroupMembers(MICROBOT_SELECTED_UNIT, true, true, "BOT_WARLOCK_SOULSTONE")
			UnitPopupButtons["BOT_WARLOCK_SOULSTONE_TARGET"] = { text = "Target", dist = 0 }
			table.insert(soulstoneTargets,"BOT_WARLOCK_SOULSTONE_TARGET")
			UnitPopupMenus["BOT_WARLOCK_SOULSTONE"] = soulstoneTargets
            table.insert(dynamicMenus, "BOT_WARLOCK_SOULSTONE")
        end

    --[[--------------------------
        Paladin
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Paladin" then
        -- PALADIN: Choose blessing
        UnitPopupButtons["BOT_PALADIN_BLESSING_1"] = { text = "|cFFF58CBASet first Blessing|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_1_DEFAULT"] = { text = "AI Default (Clear Settings)", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_1_MIGHT"] = { text = "Blessing of Might", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_1_WISDOM"] = { text = "Blessing of Wisdom", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_1_KINGS"] = { text = "Blessing of Kings", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_1_LIGHT"] = { text = "Blessing of Light", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_1_SALVATION"] = { text = "Blessing of Salvation", dist = 0 }
        local blessings = {
            {level = 4,  id = "BOT_PALADIN_BLESSING_1_MIGHT"},
            {level = 14, id = "BOT_PALADIN_BLESSING_1_WISDOM"},
            {level = 26, id = "BOT_PALADIN_BLESSING_1_SALVATION"},
            {level = 40, id = "BOT_PALADIN_BLESSING_1_LIGHT"},
            {level = 60, id = "BOT_PALADIN_BLESSING_1_KINGS"}
        }
        local blessingItems = {}
        for _, blessing in ipairs(blessings) do
            if MICROBOT_SELECTED_UNIT_LEVEL >= blessing.level then
                table.insert(blessingItems, blessing.id)
            end
        end
        if table.getn(blessingItems) > 0 then
            table.insert(blessingItems, 1, "BOT_PALADIN_BLESSING_1_DEFAULT")
            UnitPopupMenus["BOT_PALADIN_BLESSING_1"] = blessingItems
            table.insert(dynamicMenus, "BOT_PALADIN_BLESSING_1")
        end
		
		-- PALADIN: Choose second blessing
		UnitPopupButtons["BOT_PALADIN_BLESSING_2"] = { text = "|cFFF58CBASet second Blessing|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_2_DEFAULT"] = { text = "AI Default (Clear Settings)", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_2_MIGHT"] = { text = "Blessing of Might", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_2_WISDOM"] = { text = "Blessing of Wisdom", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_2_KINGS"] = { text = "Blessing of Kings", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_2_LIGHT"] = { text = "Blessing of Light", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_BLESSING_2_SALVATION"] = { text = "Blessing of Salvation", dist = 0 }
        local blessings = {
            {level = 4,  id = "BOT_PALADIN_BLESSING_2_MIGHT"},
            {level = 14, id = "BOT_PALADIN_BLESSING_2_WISDOM"},
            {level = 26, id = "BOT_PALADIN_BLESSING_2_SALVATION"},
            {level = 40, id = "BOT_PALADIN_BLESSING_2_LIGHT"},
            {level = 60, id = "BOT_PALADIN_BLESSING_2_KINGS"}
        }
        local blessingItems = {}
        for _, blessing in ipairs(blessings) do
            if MICROBOT_SELECTED_UNIT_LEVEL >= blessing.level then
                table.insert(blessingItems, blessing.id)
            end
        end
        if table.getn(blessingItems) > 0 then
            table.insert(blessingItems, 1, "BOT_PALADIN_BLESSING_2_DEFAULT")
            UnitPopupMenus["BOT_PALADIN_BLESSING_2"] = blessingItems
            table.insert(dynamicMenus, "BOT_PALADIN_BLESSING_2")
        end
        
        -- PALADIN: Choose auras
        UnitPopupButtons["BOT_PALADIN_AURAS"] = { text = "|cFFF58CBASet Aura|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PALADIN_AURAS_DEFAULT"] = { text = "AI Default (Clear Setting)", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_DEVOTION"] = { text = "Devotion Aura", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_RETRIBUTION"] = { text = "Retribution Aura", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_CONCENTRATION"] = { text = "Concentration Aura", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_SANCTITY"] = { text = "Sanctity Aura", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_SHADOW_RESISTANCE"] = { text = "Shadow Resistance Aura", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_FROST_RESISTANCE"] = { text = "Frost Resistance Aura", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_AURA_FIRE_RESISTANCE"] = { text = "Fire Resistance Aura", dist = 0 }
        local auras = {
            {level = 1,  id = "BOT_PALADIN_AURA_DEVOTION"},
            {level = 16, id = "BOT_PALADIN_AURA_RETRIBUTION"},
            {level = 22, id = "BOT_PALADIN_AURA_CONCENTRATION"},
            {level = 28, id = "BOT_PALADIN_AURA_SHADOW_RESISTANCE"},
            {level = 30, id = "BOT_PALADIN_AURA_SANCTITY"},
            {level = 32, id = "BOT_PALADIN_AURA_FROST_RESISTANCE"},
            {level = 36, id = "BOT_PALADIN_AURA_FIRE_RESISTANCE"}
        }
        local auraItems = {}
        for _, aura in ipairs(auras) do
            if MICROBOT_SELECTED_UNIT_LEVEL >= aura.level then
                table.insert(auraItems, aura.id)
            end
        end
        if table.getn(auraItems) > 0 then
            table.insert(auraItems, 1, "BOT_PALADIN_AURAS_DEFAULT")
            UnitPopupMenus["BOT_PALADIN_AURAS"] = auraItems
            table.insert(dynamicMenus, "BOT_PALADIN_AURAS")
        end
		if MICROBOT_SELECTED_UNIT_LEVEL >= 24 or savedSettings["broadcastTo"] == "ALL" then -- Turn Undead is learned at level 24, always show if you are broadcasting to all
            UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny |cFF9482C9Danger Spells|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
            table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_DENY_DANGER_SPELLS")
        end
		-- PALADIN: Specc options
        UnitPopupButtons["BOT_PALADIN_SPEC"] = { text = "|cFFF58CBASet Spec|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PALADIN_SPEC_MIGHT"] = { text = "|cFFC79C6EMight|r", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_SPEC_MAGIC"] = { text = "|cFF69CCF0Magic|r", dist = 0 }
		local palaSpecs = {}
		if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["specc"],"1")) then
			table.insert(palaSpecs,"BOT_PALADIN_SPEC_MIGHT")
		end
		if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["specc"],"2")) then
			table.insert(palaSpecs,"BOT_PALADIN_SPEC_MAGIC")
		end
		UnitPopupMenus["BOT_PALADIN_SPEC"] = palaSpecs
		table.insert(dynamicMenus, "BOT_PALADIN_SPEC")
		-- PALADIN: Specc Weapon options
        UnitPopupButtons["BOT_PALADIN_WEAPON"] = { text = "|cFFF58CBASet Weapon|r", dist = 0, nested = 1 }
        UnitPopupButtons["BOT_PALADIN_WEAPON_NIGHTFALL"] = { text = "Nightfall", dist = 0 }
        UnitPopupButtons["BOT_PALADIN_WEAPON_NORMAL"] = { text = "Normal", dist = 0 }
		UnitPopupMenus["BOT_PALADIN_WEAPON"] = {"BOT_PALADIN_WEAPON_NIGHTFALL","BOT_PALADIN_WEAPON_NORMAL"}
		--Only add this for Tank or MDPS comps
		if(table_contains(mdpsCompanions,MICROBOT_SELECTED_UNIT_NAME) or table_contains(tankCompanions,MICROBOT_SELECTED_UNIT_NAME)) then
			if (hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T1R")) then
				table.insert(dynamicMenus, "BOT_PALADIN_WEAPON")
			end
		end
		UnitPopupButtons["BOT_REVIVAL"] = { text = "|cFFF58CBARevival|r", dist = 0, nested = 1 }
		UnitPopupMenus["BOT_REVIVAL"] = {"BOT_SOULSTONE_ALLOW","BOT_SOULSTONE_DENY","BOT_DISPEL_DI"}
		table.insert(dynamicMenus, "BOT_REVIVAL")
		
    --[[--------------------------
        Shaman
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Shaman" then
        -- SHAMAN: Choose air totem
        UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM"] = { text = "|cFF0070DESet|r |cFFb8bcffAir|r |cFF0070DETotem|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM_GRACE"] = { text = "Grace of Air", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM_NATURE"] = { text = "Nature Resistance", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM_WINDFURY"] = { text = "Windfury", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM_GROUNDING"] = { text = "Grounding", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM_TRANQUIL"] = { text = "Tranquil Air", dist = 0 }
		UnitPopupButtons["BOT_SHAMAN_AIR_TOTEM_NATURE_CAST"] = { text = "|cFF0070DEcast|r Nature Resistance", dist = 0 }

        -- SHAMAN: Choose earth totem
        UnitPopupButtons["BOT_SHAMAN_EARTH_TOTEM"] = { text = "|cFF0070DESet|r |cFF4dd943Earth|r |cFF0070DETotem|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_SHAMAN_EARTH_TOTEM_STONESKIN"] = { text = "Stoneskin", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_EARTH_TOTEM_EARTHBIND"] = { text = "Earthbind", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_EARTH_TOTEM_STRENGTH"] = { text = "Strength of Earth", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_EARTH_TOTEM_TREMOR"] = { text = "Tremor", dist = 0 }

        -- SHAMAN: Choose fire totem
        UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM"] = { text = "|cFF0070DESet|r |cFFFF4500Fire|r |cFF0070DETotem|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM_SEARING"] = { text = "Searing", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM_FIRE_NOVA"] = { text = "Fire Nova", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM_FROST_RESISTANCE"] = { text = "Frost Resistance", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM_MAGMA"] = { text = "Magma", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM_FLAMETONGUE"] = { text = "Flametongue", dist = 0 }
		UnitPopupButtons["BOT_SHAMAN_FIRE_TOTEM_FROST_RESISTANCE_CAST"] = { text = "|cFF0070DEcast|r Frost Resistance", dist = 0 }

        -- SHAMAN: Choose water totem
        UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM"] = { text = "|cFF0070DESet|r |cFF34EBD2Water|r |cFF0070DETotem|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_HEALING"] = { text = "Healing Stream", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_MANA_SPRING"] = { text = "Mana Spring", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_FIRE_RESISTANCE"] = { text = "Fire Resistance", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_DISEASE_CLEANSING"] = { text = "Disease Cleansing", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_POISON_CLEANSING"] = { text = "Poison Cleansing", dist = 0 }
		UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_FIRE_RESISTANCE_CAST"] = { text = "|cFF0070DEcast|r Fire Resistance", dist = 0 }
		UnitPopupButtons["BOT_SHAMAN_WATER_TOTEM_POISON_CLEANSING_CAST"] = { text = "|cFF0070DEcast|r Poison Cleansing", dist = 0 }

        -- SHAMAN: Clear set totems or toggle off
        UnitPopupButtons["BOT_SHAMAN_CLEAR_TOTEMS"] = { text = "|cFF0070DEClear Totem Settings|r" .. markerBCClass, dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_TOGGLE_TOTEMS"] = { text = "|cFF0070DEToggle Totems|r", dist = 0 }
         
        -- SHAMAN: Totems
        local totems = {
            earth = {
                {level = 4,  id = "BOT_SHAMAN_EARTH_TOTEM_STONESKIN"},
                {level = 6,  id = "BOT_SHAMAN_EARTH_TOTEM_EARTHBIND"},
                {level = 10, id = "BOT_SHAMAN_EARTH_TOTEM_STRENGTH"},
                {level = 18, id = "BOT_SHAMAN_EARTH_TOTEM_TREMOR"}
            },
            fire = {
                {level = 10, id = "BOT_SHAMAN_FIRE_TOTEM_SEARING"},
                {level = 12, id = "BOT_SHAMAN_FIRE_TOTEM_FIRE_NOVA"},
                {level = 24, id = "BOT_SHAMAN_FIRE_TOTEM_FROST_RESISTANCE"},
                {level = 26, id = "BOT_SHAMAN_FIRE_TOTEM_MAGMA"},
                {level = 28, id = "BOT_SHAMAN_FIRE_TOTEM_FLAMETONGUE"},
				{level = 24, id = "BOT_SHAMAN_FIRE_TOTEM_FROST_RESISTANCE_CAST"}
            },
            water = {
                {level = 20, id = "BOT_SHAMAN_WATER_TOTEM_HEALING"},
                {level = 22, id = "BOT_SHAMAN_WATER_TOTEM_POISON_CLEANSING"},
                {level = 26, id = "BOT_SHAMAN_WATER_TOTEM_MANA_SPRING"},
                {level = 28, id = "BOT_SHAMAN_WATER_TOTEM_FIRE_RESISTANCE"},
                {level = 38, id = "BOT_SHAMAN_WATER_TOTEM_DISEASE_CLEANSING"},
				{level = 28, id = "BOT_SHAMAN_WATER_TOTEM_FIRE_RESISTANCE_CAST"},
				{level = 38, id = "BOT_SHAMAN_WATER_TOTEM_POISON_CLEANSING_CAST"},
            },
            air = {
                {level = 30, id = "BOT_SHAMAN_AIR_TOTEM_NATURE"},
                {level = 30, id = "BOT_SHAMAN_AIR_TOTEM_GROUNDING"},
                {level = 32, id = "BOT_SHAMAN_AIR_TOTEM_WINDFURY"},
                {level = 42, id = "BOT_SHAMAN_AIR_TOTEM_GRACE"},
                {level = 50, id = "BOT_SHAMAN_AIR_TOTEM_TRANQUIL"},
				{level = 30, id = "BOT_SHAMAN_AIR_TOTEM_NATURE_CAST"}
            }
        }
        if MICROBOT_SELECTED_UNIT_LEVEL >= 10 then -- First totem is available at level 10
            table.insert(dynamicMenus, "BOT_SHAMAN_TOGGLE_TOTEMS")
        end
        local elementOrder = {"earth", "fire", "water", "air"}
        for _, element in ipairs(elementOrder) do
            local menuItems = {}
            for _, totem in ipairs(totems[element]) do
                if MICROBOT_SELECTED_UNIT_LEVEL >= totem.level then
                    table.insert(menuItems, totem.id)
                end
            end
            if table.getn(menuItems) > 0 then
                UnitPopupMenus["BOT_SHAMAN_"..string.upper(element).."_TOTEM"] = menuItems
                table.insert(dynamicMenus, "BOT_SHAMAN_"..string.upper(element).."_TOTEM")
            end
        end
        if MICROBOT_SELECTED_UNIT_LEVEL >= 10 then -- First totem is available at level 10
            table.insert(dynamicMenus, "BOT_SHAMAN_CLEAR_TOTEMS")
        end
		
		-- SHAMAN: Choose weapon
        UnitPopupButtons["BOT_SHAMAN_WEAPON"] = { text = "|cFF0070DESet Weapon|r", dist = 0, nested = 1}		
        UnitPopupButtons["BOT_SHAMAN_WEAPON_DEFAULT"] = { text = "AI Default (Clear Setting)", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_WEAPON_ROCKBITER"] = { text = "|cFF4dd943Rockbiter|r", dist = 0 }		
        UnitPopupButtons["BOT_SHAMAN_WEAPON_FLAMETOUNGUE"] = { text = "|cFFFF4500Flametongue|r", dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_WEAPON_FROSTBRAND"] = { text = "|cFF34EBD2Frostbrand|r", dist = 0 }	
		UnitPopupButtons["BOT_SHAMAN_WEAPON_WINDFURY"] = { text = "|cFFb8bcffWindfury|r", dist = 0 }			
        UnitPopupButtons["BOT_SHAMAN_WEAPON_NONE"] = { text = "None", dist = 0 }
		local shamWeapons = {
            {level = 1,  id = "BOT_SHAMAN_WEAPON_ROCKBITER"},
            {level = 10, id = "BOT_SHAMAN_WEAPON_FLAMETOUNGUE"},
            {level = 20, id = "BOT_SHAMAN_WEAPON_FROSTBRAND"},
			{level = 30, id = "BOT_SHAMAN_WEAPON_WINDFURY"},
        }
		local weaponItems = {}
        for _, weapon in ipairs(shamWeapons) do
            if MICROBOT_SELECTED_UNIT_LEVEL >= weapon.level then
                table.insert(weaponItems, weapon.id)
            end
        end
        if table.getn(weaponItems) > 0 then
            table.insert(weaponItems, 1, "BOT_SHAMAN_WEAPON_DEFAULT")
			table.insert(weaponItems, "BOT_SHAMAN_WEAPON_NONE")
            UnitPopupMenus["BOT_SHAMAN_WEAPON"] = weaponItems
			--only add this for mpds shamans
			if(table_contains(mdpsCompanions,MICROBOT_SELECTED_UNIT_NAME)) then
				table.insert(dynamicMenus, "BOT_SHAMAN_WEAPON")
			end
        end
		

        -- SHAMAN: Reincarnation
        UnitPopupButtons["BOT_SHAMAN_REINCARNATION"] = { text = "|cFF0070DEReincarnation|r", dist = 0, nested = 1 }
        UnitPopupButtons["BOT_SHAMAN_REINCARNATION_ALLOW"] = { text = "|cff1EFF00Allow Self-Resurrection|r" .. markerBCClass, dist = 0 }
        UnitPopupButtons["BOT_SHAMAN_REINCARNATION_DENY"] = { text = "|cffFF0000Deny Self-Resurrection|r" .. markerBCClass, dist = 0 }
		UnitPopupButtons["BOT_REVIVAL"] = { text = "|cFF0070DERevival|r", dist = 0, nested = 1 }
		UnitPopupMenus["BOT_REVIVAL"] = {"BOT_SOULSTONE_ALLOW","BOT_SOULSTONE_DENY","BOT_DISPEL_DI"}		
        if MICROBOT_SELECTED_UNIT_LEVEL >= 30 then -- Reincarnation is learned at level 30
            table.insert(UnitPopupMenus["BOT_REVIVAL"], "BOT_SHAMAN_REINCARNATION_ALLOW")
			table.insert(UnitPopupMenus["BOT_REVIVAL"], "BOT_SHAMAN_REINCARNATION_DENY")
        end
		table.insert(dynamicMenus, "BOT_REVIVAL")
    --[[--------------------------
        Priest
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Priest" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 14 or savedSettings["broadcastTo"] == "ALL" then 
            UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny |cFFFFFFA0Danger Spells|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
            table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_DENY_DANGER_SPELLS")
        end
        
        -- PRIEST: Fear Ward (Dwarf only)
        if MICROBOT_SELECTED_UNIT_LEVEL >= 20 and UnitRace(MICROBOT_SELECTED_UNIT) == "Dwarf" then
            UnitPopupButtons["BOT_PRIEST_FEAR_WARD"] = { text = "|cFFFFFFA0Set Fear Ward On|r" .. markerBCClass, dist = 0, nested = 1 }
            local fearWardTargets = GetLocalGroupMembers(MICROBOT_SELECTED_UNIT, true, true, "BOT_PRIEST_FEAR_WARD")
			UnitPopupButtons["BOT_PRIEST_FEAR_WARD_TARGET"] = { text = "Target", dist = 0 }
            table.insert(fearWardTargets, "BOT_PRIEST_FEAR_WARD_TARGET")
			UnitPopupMenus["BOT_PRIEST_FEAR_WARD"] = fearWardTargets
			table.insert(dynamicMenus, "BOT_PRIEST_FEAR_WARD")
        end
		
		 -- PRIEST: Power Infusion (Lites only)
        if  string.find(MICROBOT_SELECTED_UNIT_NAME,"-lite") then
			UnitPopupButtons["BOT_PRIEST_POWER_INFUSION"] = { text = "|cFFFFFFA0Set Power Infusion On|r", dist = 0, nested = 1 }
			local powerInfusionTargets = GetLocalGroupMembers(MICROBOT_SELECTED_UNIT, true, true, "BOT_PRIEST_POWER_INFUSION")
			UnitPopupButtons["BOT_PRIEST_POWER_INFUSION_TARGET"] = { text = "Target", dist = 0 }
			table.insert(powerInfusionTargets, "BOT_PRIEST_POWER_INFUSION_TARGET")
			UnitPopupMenus["BOT_PRIEST_POWER_INFUSION"] = powerInfusionTargets
			table.insert(dynamicMenus, "BOT_PRIEST_POWER_INFUSION")			
        end
		UnitPopupButtons["BOT_REVIVAL"] = { text = "|cFFFFFFA0Revival|r", dist = 0, nested = 1 }
		UnitPopupMenus["BOT_REVIVAL"] = {"BOT_SOULSTONE_ALLOW","BOT_SOULSTONE_DENY","BOT_DISPEL_DI"}
		table.insert(dynamicMenus, "BOT_REVIVAL")
    --[[--------------------------
        Warrior
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Warrior" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 22 or savedSettings["broadcastTo"] == "ALL" then -- Intimidating Shout is learned at level 22, always show if you are broadcasting to all
            UnitPopupButtons["BOT_DENY_DANGER_SPELLS"] = { text = "Deny |cFFC79C6EDanger Spells|r"..markerBCAll..markerBCRole..markerBCClass, dist = 0 }
            table.insert(UnitPopupMenus["BOT_CONTROL"], "BOT_DENY_DANGER_SPELLS")
        end
    --[[--------------------------
        Rogue
    ----------------------------]]
    elseif MICROBOT_SELECTED_UNIT_CLASS == "Rogue" then -- Stealth at level 1
        -- ROGUE: Stealth control on or off
        UnitPopupButtons["BOT_ROGUE_STEALTH"] = { text = "|cFFFFF569Stealth Control|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_ROGUE_STEALTH_ON"] = { text = "|cff1EFF00Allow Stealth|r", dist = 0 }
        UnitPopupButtons["BOT_ROGUE_STEALTH_OFF"] = { text = "|cffFF0000Prevent Stealth|r", dist = 0 }
        UnitPopupMenus["BOT_ROGUE_STEALTH"] = { "BOT_ROGUE_STEALTH_ON", "BOT_ROGUE_STEALTH_OFF" }
        table.insert(dynamicMenus, "BOT_ROGUE_STEALTH")
    --[[--------------------------
        Druid
    ----------------------------]]


    elseif MICROBOT_SELECTED_UNIT_CLASS == "Druid" then
        -- DRUID: Stealth control on or off
        UnitPopupButtons["BOT_DRUID_STEALTH"] = { text = "|cFFFF7D0AStealth Control|r" .. markerBCClass, dist = 0, nested = 1 }
        UnitPopupButtons["BOT_DRUID_STEALTH_ON"] = { text = "|cff1EFF00Allow Stealth|r", dist = 0 }
        UnitPopupButtons["BOT_DRUID_STEALTH_OFF"] = { text = "|cffFF0000Prevent Stealth|r", dist = 0 }
        if MICROBOT_SELECTED_UNIT_LEVEL >= 20 then -- Stealth is learned at level 20 (cat form)
            UnitPopupMenus["BOT_DRUID_STEALTH"] = { "BOT_DRUID_STEALTH_ON", "BOT_DRUID_STEALTH_OFF" }
            table.insert(dynamicMenus, "BOT_DRUID_STEALTH")
        end

        -- DRUID: Rebirth control
        --UnitPopupButtons["BOT_DRUID_REBIRTH"] = { text = "|cFFFF7D0ARebirth|r", dist = 0, nested = 1 }
        UnitPopupButtons["BOT_DRUID_REBIRTH_ALLOW"] = { text = "|cff1EFF00Allow Combat Resurrect|r" .. markerBCClass, dist = 0 }
        UnitPopupButtons["BOT_DRUID_REBIRTH_DENY"] = { text = "|cffFF0000Deny Combat Resurrect|r" .. markerBCClass, dist = 0 }
		UnitPopupButtons["BOT_DRUID_REBIRTH_CAST"] = { text = "|cFFFF7D0ACast Combat Resurrect|r", dist = 0 }
		UnitPopupButtons["BOT_REVIVAL"] = { text = "|cFFFF7D0ARevival|r", dist = 0, nested = 1 }
		UnitPopupMenus["BOT_REVIVAL"] = {"BOT_SOULSTONE_ALLOW","BOT_SOULSTONE_DENY","BOT_DISPEL_DI"}		
        if MICROBOT_SELECTED_UNIT_LEVEL >= 20 then -- Rebirth is learned at level 20
 			table.insert(UnitPopupMenus["BOT_REVIVAL"], "BOT_DRUID_REBIRTH_ALLOW")
			table.insert(UnitPopupMenus["BOT_REVIVAL"], "BOT_DRUID_REBIRTH_DENY")
		   table.insert(UnitPopupMenus["BOT_REVIVAL"], "BOT_DRUID_REBIRTH_CAST")
        end
		table.insert(dynamicMenus, "BOT_REVIVAL")
    end
	
	--[[--------------------------
        Add Set Gear Buttons
    ----------------------------]]
    
    UnitPopupButtons["BOT_SET_GEAR"] = { text = "Set Gear", dist = 0, nested = 1 }
    UnitPopupButtons["BOT_SET_GEAR_NORMAL"] = { text = "Normal"..markerBCRole..markerBCClass, dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_FIRE"] = { text = "|cFFFF4500Fire|r"..markerBCRole..markerBCClass, dist = 0 }
	UnitPopupButtons["BOT_SET_GEAR_CLOAK"] = { text = "|cffDC143COny Cloak|r"..markerBCRole..markerBCClass, dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_SHADOW"] = { text = "|cFF9482C9Shadow|r"..markerBCRole..markerBCClass, dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_NATURE"] = { text = "|cFF4dd943Nature|r"..markerBCRole..markerBCClass, dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_FROST"] = { text = "|cFF34EBD2Frost|r"..markerBCRole..markerBCClass, dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_VISCIDUS"] = { text = "Viscidus"..markerBCRole..markerBCClass, dist = 0 }
	UnitPopupButtons["BOT_SET_GEAR_ALL_NORMAL"] = { text = "All Normal", dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_ALL_FIRE"] = { text = "All |cFFFF4500Fire", dist = 0 }
	UnitPopupButtons["BOT_SET_GEAR_ALL_CLOAK"] = { text = "All |cffDC143COny Cloak|r", dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_ALL_SHADOW"] = { text = "All |cFF9482C9Shadow|r", dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_ALL_NATURE"] = { text = "All |cFF4dd943Nature|r", dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_ALL_FROST"] = { text = "All |cFF34EBD2Frost|r", dist = 0 }
    UnitPopupButtons["BOT_SET_GEAR_ALL_VISCIDUS"] = { text = "All Viscidus", dist = 0 }
	
	
	local _, fireRes, _, _ = UnitResistance("player", 2)
	local _, shadowRes, _, _ = UnitResistance("player", 5)	
	local _, natureRes, _, _ = UnitResistance("player", 3)
	local _, frostRes, _, _ = UnitResistance("player", 4)
	
	UnitPopupButtons["BOT_SET_GEAR_INFO_FIRE"] = { text = "|cFFFF4500Fire Res:|r |cffFF0000"..fireRes.."/255|r", dist = 0 }
	UnitPopupButtons["BOT_SET_GEAR_INFO_CLOAK"] = { text = "|cffDC143COny Cloak:|r |cffFF0000 Not equiped|r", dist = 0 }	
	UnitPopupButtons["BOT_SET_GEAR_INFO_SHADOW"] = { text = "|cFF9482C9Shadow Res:|r |cffFF0000"..shadowRes.."/255|r", dist = 0 }
	UnitPopupButtons["BOT_SET_GEAR_INFO_NATURE"] = { text = "|cFF4dd943Nature Res:|r |cffFF0000"..natureRes.."/255|r", dist = 0 }	
	UnitPopupButtons["BOT_SET_GEAR_INFO_VISCIDUS"] = { text = "Viscidus: |cffFF0000"..natureRes.."/255|r (nature)", dist = 0 }
	UnitPopupButtons["BOT_SET_GEAR_INFO_FROST"] = { text = "|cFF34EBD2Frost Res:|r |cffFF0000"..frostRes.."/255|r", dist = 0 }	
	
	local resistOptions = {}
	table.insert(resistOptions, "BOT_SET_GEAR_NORMAL")
	table.insert(resistOptions, "BOT_SET_GEAR_ALL_NORMAL")	
	if hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T1R") then
		if(fireRes >= 255) then
			table.insert(resistOptions, "BOT_SET_GEAR_FIRE")
			table.insert(resistOptions, "BOT_SET_GEAR_ALL_FIRE")
		else
			table.insert(resistOptions, "BOT_SET_GEAR_INFO_FIRE")
		end
	end	
	if hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T2R") then
		if(shadowRes >= 255) then
			table.insert(resistOptions, "BOT_SET_GEAR_SHADOW")
			table.insert(resistOptions, "BOT_SET_GEAR_ALL_SHADOW")
		else
			table.insert(resistOptions, "BOT_SET_GEAR_INFO_SHADOW")
		end
	end
	if hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T3R") then
		if(natureRes >= 255) then
			table.insert(resistOptions, "BOT_SET_GEAR_NATURE")
			table.insert(resistOptions, "BOT_SET_GEAR_ALL_NATURE")
		else
			table.insert(resistOptions, "BOT_SET_GEAR_INFO_NATURE")
		end
	end
	if hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T4R") then
		if(frostRes >= 255) then
			table.insert(resistOptions, "BOT_SET_GEAR_FROST")
			table.insert(resistOptions, "BOT_SET_GEAR_ALL_FROST")
		else
			table.insert(resistOptions, "BOT_SET_GEAR_INFO_FROST")
		end
	end
	if hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T3R") then
		if(natureRes >= 255) then
			table.insert(resistOptions, "BOT_SET_GEAR_VISCIDUS")
			table.insert(resistOptions, "BOT_SET_GEAR_ALL_VISCIDUS")
		else
			table.insert(resistOptions, "BOT_SET_GEAR_INFO_VISCIDUS")
		end
	end
	if hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T1R") or hasLicence(MICROBOT_SELECTED_UNIT_NAME,"T1D") then
		itemLink = GetInventoryItemLink("player", GetInventorySlotInfo("BackSlot"))
		local found, _, itemString
		if itemLink then
			found, _, itemString = string.find(itemLink, "|H(.+)|h")
		end
		if(itemLink and itemString and string.find(itemString,"Onyxia Scale Cloak")) then
			table.insert(resistOptions, "BOT_SET_GEAR_CLOAK")
			table.insert(resistOptions, "BOT_SET_GEAR_ALL_CLOAK")
		else 
			table.insert(resistOptions, "BOT_SET_GEAR_INFO_CLOAK")
		end
	end
	UnitPopupMenus["BOT_SET_GEAR"] = resistOptions
	if MICROBOT_SELECTED_UNIT_LEVEL >= 50 then -- Don't show at all for lowbie Bots, T1r quest is level 50+
		table.insert(dynamicMenus, "BOT_SET_GEAR")
	end
	
	--[[--------------------------
        Add Set Formation Buttons
    ----------------------------]]
	UnitPopupButtons["BOT_FORMATION"] = { text = "Set Formation"..markerBCAll..markerBCRole..markerBCClass, dist = 0, nested = 1 }
	UnitPopupButtons["BOT_FORMATION_DEFAULT"] = { text = "Return to default", dist = 0 }	
	UnitPopupButtons["BOT_FORMATION_DISTANCE"] = { text = "Set Distance", dist = 0 }
	UnitPopupButtons["BOT_FORMATION_ANGLE_FRONT"] = { text = "Angle: Front", dist = 0 }	
	UnitPopupButtons["BOT_FORMATION_ANGLE_LEFT"] = { text = "Angle: Left", dist = 0 }		
	UnitPopupButtons["BOT_FORMATION_ANGLE_RIGHT"] = { text = "Angle: Right", dist = 0 }		
	UnitPopupButtons["BOT_FORMATION_ANGLE_BACK"] = { text = "Angle: Back", dist = 0 }	
	UnitPopupButtons["BOT_FORMATION_ANGLE_UPPERLEFT"] = { text = "Angle: Front-Left", dist = 0 }	
	UnitPopupButtons["BOT_FORMATION_ANGLE_UPPERRIGHT"] = { text = "Angle: Front-Right", dist = 0 }		
	UnitPopupButtons["BOT_FORMATION_ANGLE_BOTTOMLEFT"] = { text = "Angle: Back-Left", dist = 0 }		
	UnitPopupButtons["BOT_FORMATION_ANGLE_BOTTOMRIGHT"] = { text = "Angle: Back-Right", dist = 0 }
	
  UnitPopupMenus["BOT_FORMATION"] = {
		"BOT_FORMATION_DEFAULT",
		"BOT_FORMATION_DISTANCE",
		"BOT_FORMATION_ANGLE_FRONT",
		"BOT_FORMATION_ANGLE_LEFT",
		"BOT_FORMATION_ANGLE_RIGHT",		
		"BOT_FORMATION_ANGLE_BACK",
		"BOT_FORMATION_ANGLE_UPPERLEFT",
		"BOT_FORMATION_ANGLE_UPPERRIGHT",
		"BOT_FORMATION_ANGLE_BOTTOMLEFT",
		"BOT_FORMATION_ANGLE_BOTTOMRIGHT"
	}
		
	 table.insert(dynamicMenus, "BOT_FORMATION")	

	
    --[[--------------------------
        Add CC and Focus Buttons
    ----------------------------]]
    -- Assign CC mark buttons
    UnitPopupButtons["BOT_ASSIGN_CC_MARK"] = { text = "Set |cff00ffffCC|r Mark", dist = 0, nested = 1 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_STAR"] = { text = "|cffFFD100Star|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_CIRCLE"] = { text = "|cffFF7F00Circle|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_DIAMOND"] = { text = "|cffFF00FFDiamond|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_TRIANGLE"] = { text = "|cff1EFF00Triangle|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_MOON"] = { text = "|cff6699CCMoon|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_SQUARE"] = { text = "|cff00ffffSquare|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_CROSS"] = { text = "|cffFF0000Cross|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_SKULL"] = { text = "|cFFFFFFA0Skull|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_CC_MARK_CLEAR"] = { text = "Clear CC (Defaults to |cff6699CCMoon|r)"..markerBCRole..markerBCClass..markerBCAll, dist = 0 }
	
	local validCCMarks = {}
	table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_CLEAR")
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"1")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_STAR")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"2")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_CIRCLE")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"3")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_DIAMOND")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"4")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_TRIANGLE")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"5")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_MOON")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"6")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_SQUARE")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"7")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_CROSS")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["ccmarks"],"8")) then
		table.insert(validCCMarks,"BOT_ASSIGN_CC_MARK_SKULL")
	end
    UnitPopupMenus["BOT_ASSIGN_CC_MARK"] = validCCMarks

    -- Assign focus mark buttons
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK"] = { text = "Set |cffFF0000Focus|r Mark", dist = 0, nested = 1 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_STAR"] = { text = "|cffFFD100Star|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_CIRCLE"] = { text = "|cffFF7F00Circle|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_DIAMOND"] = { text = "|cffFF00FFDiamond|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_TRIANGLE"] = { text = "|cff1EFF00Triangle|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_MOON"] = { text = "|cff6699CCMoon|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_SQUARE"] = { text = "|cff00ffffSquare|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_CROSS"] = { text = "|cffFF0000Cross|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_SKULL"] = { text = "|cFFFFFFA0Skull|r", dist = 0 }
    UnitPopupButtons["BOT_ASSIGN_FOCUS_MARK_CLEAR"] = { text = "Clear Focus (Defaults to |cFFFFFFA0Skull|r)"..markerBCRole..markerBCClass..markerBCAll, dist = 0 }

    local validFocusMarks = {}
	table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_CLEAR")
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"1")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_STAR")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"2")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_CIRCLE")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"3")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_DIAMOND")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"4")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_TRIANGLE")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"5")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_MOON")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"6")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_SQUARE")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"7")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_CROSS")
	end
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and not string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["focusmarks"],"8")) then
		table.insert(validFocusMarks,"BOT_ASSIGN_FOCUS_MARK_SKULL")
	end
    UnitPopupMenus["BOT_ASSIGN_FOCUS_MARK"] = validFocusMarks
	
    -- Add cc and focus mark assignment to the dynamic menus in the last position
    table.insert(dynamicMenus, "BOT_ASSIGN_CC_MARK")
    table.insert(dynamicMenus, "BOT_ASSIGN_FOCUS_MARK")

    --[[--------------------------
    Add Follow On Buttons
	   
	Old Logic:	
	UnitPopupButtons["BOT_FOLLOW_ON"] = { text = "Set |cFFFFFFA0Follow|r On", dist = 0, nested = 1 }
    UnitPopupMenus["BOT_FOLLOW_ON"] = GetLocalGroupMembers(MICROBOT_SELECTED_UNIT, true, false, "BOT_FOLLOW_ON")
	
	table.insert(dynamicMenus, "BOT_FOLLOW_ON")
	
    ----------------------------]]
    
	UnitPopupButtons["BOT_FOLLOW_ON"] = { text = "Set |cFFFFFFA0Follow|r On"..markerBCAll..markerBCRole..markerBCClass, dist = 0, nested = 1 }  
	local followOptions = {}
	UnitPopupButtons["BOT_FOLLOW_ON_PLAYER"] = { text = "Clear follow", dist = 0 }
    table.insert(followOptions, "BOT_FOLLOW_ON_PLAYER")
	for _, player in ipairs(otherPlayers) do
		local playerButton = "BOT_FOLLOW_ON_"..player
		UnitPopupButtons[playerButton] = { text = player, dist = 0 }
        table.insert(followOptions, playerButton)
    end
	if(tankCompanions and table_length(tankCompanions) > 0) then
		UnitPopupButtons["BOT_FOLLOW_ON_TANK"] = { text = "|cFFC79C6ETank", dist = 0 }
		table.insert(followOptions, "BOT_FOLLOW_ON_TANK")
	end
	if(healerCompanions and table_length(healerCompanions) > 0) then
		UnitPopupButtons["BOT_FOLLOW_ON_HEALER"] = { text = "|cFF4dd943Heal", dist = 0 }
		table.insert(followOptions, "BOT_FOLLOW_ON_HEALER")
	end
	if(mdpsCompanions and table_length(mdpsCompanions) > 0) then
		UnitPopupButtons["BOT_FOLLOW_ON_MDPS"] = { text = "|cFFFFF569MDPS", dist = 0 }
		table.insert(followOptions, "BOT_FOLLOW_ON_MDPS")
	end
	if(rdpsCompanions and table_length(rdpsCompanions) > 0) then
		UnitPopupButtons["BOT_FOLLOW_ON_RDPS"] = { text = "|cFF69CCF0RDPS", dist = 0 }
		table.insert(followOptions, "BOT_FOLLOW_ON_RDPS")
	end											
	UnitPopupButtons["BOT_FOLLOW_ON_TARGET"] = { text = "Target", dist = 0 }
	table.insert(followOptions, "BOT_FOLLOW_ON_TARGET")
	UnitPopupMenus["BOT_FOLLOW_ON"] = followOptions
	
	UnitPopupButtons["BOT_FOLLOW_RETURN"] = { text = "Return |cFFFFFFA0Follow|r"..markerBCAll, dist = 0 }
	
	if (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["following"] and string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["following"],UnitName("player"))) then
		table.insert(dynamicMenus, "BOT_FOLLOW_RETURN")
	else
		table.insert(dynamicMenus, "BOT_FOLLOW_ON")
	end
	
	 --[[--------------------------
    Add Transfer On Buttons	
    ----------------------------]]
	UnitPopupButtons["BOT_TRANSFER_ON"] = { text = "Set |cFFFFAA00Transfer|r On"..markerBCAll..markerBCRole..markerBCClass, dist = 0, nested = 1 }  
	local transferOptions = {}
	UnitPopupButtons["BOT_TRANSFER_ON_PLAYER"] = { text = "Clear Transfer", dist = 0 }
    table.insert(transferOptions, "BOT_TRANSFER_ON_PLAYER")
	for _, player in ipairs(otherPlayers) do
		local playerButton = "BOT_TRANSFER_ON_"..player
		UnitPopupButtons[playerButton] = { text = player, dist = 0 }
        table.insert(transferOptions, playerButton)
    end
	UnitPopupButtons["BOT_TRANSFER_ON_TARGET"] = { text = "Target", dist = 0 }
    table.insert(transferOptions, "BOT_TRANSFER_ON_TARGET")
	UnitPopupMenus["BOT_TRANSFER_ON"] = transferOptions
	
	-- Only show for bots that can still be transfered (or followed Companions because we do not have that information for them)
	if (followedComps and table_contains(followedComps,MICROBOT_SELECTED_UNIT_NAME)) or (allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME] and string.find(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["transferable"],"0")) then
		table.insert(dynamicMenus, "BOT_TRANSFER_ON")
	end
	
	--[[--------------------------
    Add Uninvite Button if we are not Party Leader
    ----------------------------]]
	if not(UnitIsPartyLeader("player")) then 
		UnitPopupButtons["BOT_UNINVITE"] = { text = "Uninvite", dist = 0 }
		table.insert(dynamicMenus, "BOT_UNINVITE")
	end
	
    --[[--------------------------
        Finish and Clean Up
    ----------------------------]]
    -- Insert dynamic menus at the top of the party menu, under BOT_CONTROL
    for i = table.getn(dynamicMenus), 1, -1 do
        table.insert(UnitPopupMenus[menuFrame], 2, dynamicMenus[i])
    end

    -- Call the original function
    originalUnitPopupShowMenu(dropdownMenu, which, unit, name, userData)
end

--[[------------------------------------
    Handle Custom Menu Clicks
--------------------------------------]]
local originalUnitPopupOnClick = UnitPopup_OnClick
function UnitPopup_OnClick()
	local button = this.value;
    
    --[[------------------------------------
    Player (self commands)
    --------------------------------------]]
    if button == "SELF_RESET_INSTANCES" then		
			RunScript("ResetInstances()")
    elseif button == "SELF_DUNGEON_NORMAL" then
        MCM_Send(".settings difficulty normal")
    elseif button == "SELF_DUNGEON_HEROIC" then
        MCM_Send(".settings difficulty heroic")
	elseif button == "SETTINGS_CONFIRMATIONS_ON" then
        setConfirmations("ON")
	elseif button == "SETTINGS_CONFIRMATIONS_OFF" then
		setConfirmations("OFF")
	elseif button == "SETTINGS_BROADCAST_ALL" then		
		setBroadcast("ALL")
	elseif button == "SETTINGS_BROADCAST_ROLE" then
        setBroadcast("ROLE")
	elseif button == "SETTINGS_BROADCAST_CLASS" then
        setBroadcast("CLASS")
	elseif button == "SETTINGS_BROADCAST_NONE" then
        setBroadcast("NONE")
	elseif button == "SETTINGS_AUTOTRADE_ON" then	 
		setAutoTrade("ON")
	elseif button == "SETTINGS_AUTOTRADE_OFF" then	 
		setAutoTrade("OFF")
	elseif button == "SELF_RETURN_COMPANIONS_UNFOLLOW" then
        MCM_Send(".z unfollow")	
	elseif button == "SELF_RETURN_COMPANIONS_UNTRANSFER" then
        MCM_Send(".z untransfer")
	elseif button == "SELF_PVP" then
        TogglePVP()	
	elseif button == "SELF_DEBUG_RESPONSE" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Companion Info recieved from Server")
		for _, comp in ipairs(allCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_PLAYERS" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Player Info Saved")
		for _, player in ipairs(otherPlayers) do
			DEFAULT_CHAT_FRAME:AddMessage(player)
		end	
	elseif button == "SELF_DEBUG_OWN_COMPS" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Own Companion Info Saved")
		for _, comp in ipairs(ownCompanionNames) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end		
	elseif button == "SELF_DEBUG_SETTINGS" then
		-- removed confirmation Setting, redundant with autotrade
		--DEFAULT_CHAT_FRAME:AddMessage("DEBUG: show Confirmations: "..savedSettings["showConfirmations"])
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Broadcast To: "..savedSettings["broadcastTo"])
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: AutoTrade: "..savedSettings["autoTrade"])
	
	elseif button == "SELF_DEBUG_TANKS" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Tanks Saved:")
		for _, comp in ipairs(tankCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_HEALER" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Healers Saved:")
		for _, comp in ipairs(healerCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_RDPS" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: RDPS Saved:")
		for _, comp in ipairs(rdpsCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_MDPS" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: MDPS Saved:")
		for _, comp in ipairs(mdpsCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_WARRIOR" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Warriors Saved:")
		for _, comp in ipairs(warriorCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_MAGE" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Mages Saved:")
		for _, comp in ipairs(mageCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_ROGUE" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Rogues Saved:")
		for _, comp in ipairs(rogueCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_DRUID" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Druids Saved:")
		for _, comp in ipairs(druidCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_HUNTER" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Hunters Saved:")
		for _, comp in ipairs(hunterCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_SHAMAN" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Shamans Saved:")
		for _, comp in ipairs(shamanCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_PRIEST" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Priests Saved:")
		for _, comp in ipairs(priestCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_WARLOCK" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Warlocks Saved:")
		for _, comp in ipairs(warlockCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_PALADIN" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Paladins Saved:")
		for _, comp in ipairs(paladinCompanions) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end
	elseif button == "SELF_DEBUG_FOLLOWED" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Companions you followed:")
		for _, comp in ipairs(followedComps) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end		
	elseif button == "SELF_DEBUG_FOLLOWED_SELF" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Companions followed to you:")
		for _, comp in ipairs(compsFollowingYou) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end	
	elseif button == "SELF_DEBUG_TRANSFERED" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Companions transferred:")
		for _, comp in ipairs(transferredComps) do
			DEFAULT_CHAT_FRAME:AddMessage(comp)
		end			
	elseif button == "SELF_DEBUG_OFF" then
		DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Turning Debug off, you will only be able to turn it on again with /mcm debug on")
		setDebug("OFF")	
	elseif button == "SELF_RETURN_COMPANIONS_REMALL" then
		StaticPopupDialogs["REMALL_CONFIRM"] = {
			text = "Are you sure you want to remove all your Companions?",
			button1 = OKAY,
			button2 = CANCEL,
			OnAccept = function()
				MCM_Send(".z remove all")
			end,
			timeout = 0,
			hideOnEscape = 1,
		}
		StaticPopup_Show("REMALL_CONFIRM")
        
	
    --[[------------------------------------
    Companion Control
    --------------------------------------]]
    elseif button == "BOT_TOGGLE_HELM" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "toggle helm")
    elseif button == "BOT_TOGGLE_CLOAK" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "toggle cloak")
    elseif button == "BOT_TOGGLE_AOE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "toggle aoe")
    elseif button == "BOT_ROLE_TANK" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "set tank")
    elseif button == "BOT_ROLE_HEALER" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "set healer")		
    elseif button == "BOT_ROLE_DPS" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "set dps")
    elseif button == "BOT_ROLE_MDPS" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "set mdps")		
    elseif button == "BOT_ROLE_RDPS" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "set rdps")						
	elseif button == "BOT_RESET" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"reset")
	elseif button == "BOT_DRINK" then
		drinkRequested = "y"
		SetPercentageFrame:Show()
	elseif button == "BOT_EAT" then
		eatRequested = "y"
		SetPercentageFrame:Show()
	elseif button == "BOT_HEAL" then
		healRequested = "y"
		SetPercentageFrame:Show()
	elseif button == "BOT_HEALOOC" then
		healOocRequested = "y"
		SetPercentageFrame:Show()
	elseif button == "BOT_OFFHEAL" then
		offHealRequested = "y"
		SetPercentageFrame:Show()
	elseif button == "BOT_OFFDPS" then
		offDpsRequested = "y"
		SetPercentageFrame:Show()
	elseif button == "BOT_LIMITER_ON" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set limiter on")
	elseif button == "BOT_LIMITER_OFF" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set limiter off")
	elseif button == "BOT_ASSIGN_TANK" then
		BroadcastBotWhisperCommand({"ROLE"},"set tank")	
	elseif button == "BOT_UNASSIGN_TANK" then		
		BroadcastBotWhisperCommand({"ROLE"},"set tank off")	
	elseif button == "BOT_DEBUG_ON" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set debug on")
	elseif button == "BOT_DEBUG_OFF" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set debug off")		
	elseif button == "BOT_LIST_SPELLS" then
		BroadcastBotWhisperCommand({"NONE"},"list Spells")
	elseif button == "BOT_LIST_GEAR" then
		BroadcastBotWhisperCommand({"NONE"},"list Gear")
	elseif button == "BOT_LIST_TALENTS" then
		BroadcastBotWhisperCommand({"NONE"},"list talents")
	elseif button == "BOT_LIST_STATUS" then
		BroadcastBotWhisperCommand({"NONE"},"list Status")
	elseif button == "BOT_DENY_CLEAR" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"deny remove all")	
	elseif button == "BOT_DENY_CLEAR" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"deny remove all")	
    elseif button == "BOT_SOULSTONE_DENY" then
		BroadcastBotWhisperCommand({"ROLE","CLASS"},"deny add soulstone")	
	elseif button == "BOT_SOULSTONE_ALLOW" then
		BroadcastBotWhisperCommand({"ROLE","CLASS"},"deny remove soulstone")
	elseif button == "BOT_DISPEL_DI" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"dispel aura Divine Intervention")
	elseif button == "BOT_FOLLOW_ON_PLAYER" then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then
			MCM_Send(".z unfollow")
		else
			BroadcastBotWhisperCommand({"ROLE","CLASS"},"set follow off")					
		end	
	elseif button == "BOT_FOLLOW_ON_TANK" then
		local tankname
		for _, comp in ipairs(tankCompanions) do tankname=comp end
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set follow on " .. tankname)			
	elseif button == "BOT_FOLLOW_ON_HEALER" then
		local healername
		for _, comp in ipairs(healerCompanions) do healername=comp end
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set follow on " .. healername)		
	elseif button == "BOT_FOLLOW_ON_RDPS" then
		local rdpsname		
		for _, comp in ipairs(rdpsCompanions) do rdpsname=comp end
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set follow on " .. rdpsname)		
	elseif button == "BOT_FOLLOW_ON_MDPS" then
		local mdpsname
		for _, comp in ipairs(mdpsCompanions) do mdpsname=comp end
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set follow on " .. mdpsname)				
	elseif button == "BOT_FOLLOW_ON_TARGET" then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then
			MCM_Send(".z follow")
		else
			BroadcastBotWhisperCommand({"ROLE","CLASS"},"set follow on " .. UnitName("target"))			
		end
	elseif string.find(button, "^BOT_FOLLOW_ON_") then
        local _, _, playerName = string.find(button, "_([^_]+)$")
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set follow on " .. playerName)		
	elseif string.find(button, "BOT_UNFOLLOW") then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then
			MCM_Send(".z unfollow")
		else
			BroadcastBotWhisperCommand({"ROLE","CLASS"},"set follow off")					
		end	
	elseif string.find(button, "BOT_FOLLOW_RETURN") then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then
			for _, comp in ipairs(compsFollowingYou) do
				SendTargetedBotWhisperCommand(comp,"set follow off")
			end
		else
			SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME,"set follow off")				
		end					
	elseif string.find(button, "BOT_UNTRANSFER") then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then
			MCM_Send(".z untransfer")
		else
			BroadcastBotWhisperCommand({"ROLE","CLASS"},"set transfer off")					
		end				
	elseif button == "BOT_TRANSFER_ON_PLAYER" then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then
			MCM_Send(".z untransfer")
		else
			BroadcastBotWhisperCommand({"ROLE","CLASS"},"set transfer off")					
		end					
	elseif button == "BOT_TRANSFER_ON_TARGET" then
		if(string.find(savedSettings["broadcastTo"],"ALL")) then			
			MCM_Send(".z transfer")
		else
			BroadcastBotWhisperCommand({"ROLE","CLASS"},"set transfer on " .. UnitName("target"))
		end		
	elseif string.find(button, "^BOT_TRANSFER_ON_") then
		-- This requires you to target a player
		local _, _, playerName = string.find(button, "_([^_]+)$")
		TargetUnit(playerUnitIds[playerName])
		-- Use a non-blocking delay mechanism to let the target go through (c_timer does not work, less than a second misses them sometimes)
		local delayTime = 1.0
		local frame = CreateFrame("Frame")
		frame:SetScript("OnUpdate", function()
			delayTime = delayTime - arg1
			if delayTime <= 0 then
				BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set transfer on " .. playerName)				
				frame:SetScript("OnUpdate", nil)
				
			end
		end)
	--[[------------------------------------
    Uninvite Companion
    --------------------------------------]]
	elseif button == "BOT_UNINVITE" then		
        MCM_Send(".z remove " .. MICROBOT_SELECTED_UNIT_NAME)
	--[[------------------------------------
    Bot Gear Controls
    --------------------------------------]]
    elseif button == "BOT_SET_GEAR_NORMAL" then
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear normal")
		runGearChangeTimer(target["group"])
    elseif button == "BOT_SET_GEAR_FIRE" then
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear fire")
		runGearChangeTimer(target["group"])
	elseif button == "BOT_SET_GEAR_SHADOW" then
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear shadow")
		runGearChangeTimer(target["group"])
    elseif button == "BOT_SET_GEAR_NATURE" then
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear nature")
		runGearChangeTimer(target["group"])
    elseif button == "BOT_SET_GEAR_FROST" then
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear frost")
		runGearChangeTimer(target["group"])
	elseif button == "BOT_SET_GEAR_VISCIDUS" then
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear viscidus")	
		runGearChangeTimer(target["group"])
	elseif button == "BOT_SET_GEAR_CLOAK" then 
		local target = BroadcastBotWhisperCommand({"ROLE","CLASS"},"set gear cloak")	
		runGearChangeTimer(target["group"])
    elseif button == "BOT_SET_GEAR_ALL_NORMAL" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all normal")
		runGearChangeTimer("all Companions")
    elseif button == "BOT_SET_GEAR_ALL_FIRE" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all fire")
		runGearChangeTimer("all Companions")
	elseif button == "BOT_SET_GEAR_ALL_SHADOW" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all shadow")
		runGearChangeTimer("all Companions")
    elseif button == "BOT_SET_GEAR_ALL_NATURE" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all nature")
		runGearChangeTimer("all Companions")
    elseif button == "BOT_SET_GEAR_ALL_FROST" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all frost")
		runGearChangeTimer("all Companions")
	elseif button == "BOT_SET_GEAR_ALL_VISCIDUS" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all viscidus")		
		runGearChangeTimer("all Companions")
	elseif button == "BOT_SET_GEAR_ALL_CLOAK" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set gear all cloak")		
		runGearChangeTimer("all Companions")
	
	elseif button == "BOT_SET_GEAR_INFO_CLOAK" then
		itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo("Eternal Magic Dust") 
		DEFAULT_CHAT_FRAME:AddMessage(itemName)
		local found, _, itemString = string.find(itemLink, "|H(.+)|h")
		DEFAULT_CHAT_FRAME:AddMessage(itemString)
	
	--[[------------------------------------
    Bot Formation Controls
    --------------------------------------]]	
	elseif button == "BOT_FORMATION_DEFAULT" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation default")
	elseif button == "BOT_FORMATION_DISTANCE" then
		SetDistanceFrame:Show()				
	elseif button == "BOT_FORMATION_ANGLE_FRONT" then
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle front")
	elseif button == "BOT_FORMATION_ANGLE_LEFT" then		
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle left")
	elseif button == "BOT_FORMATION_ANGLE_RIGHT" then				
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle right")
	elseif button == "BOT_FORMATION_ANGLE_BACK" then		
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle back")
	elseif button == "BOT_FORMATION_ANGLE_UPPERLEFT" then		
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle upperleft")
	elseif button == "BOT_FORMATION_ANGLE_UPPERRIGHT" then		
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle upperright")
	elseif button == "BOT_FORMATION_ANGLE_BOTTOMLEFT" then		
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle bottomleft")
	elseif button == "BOT_FORMATION_ANGLE_BOTTOMRIGHT" then		
		BroadcastBotWhisperCommand({"ALL","ROLE","CLASS"},"set formation angle bottomright")
		
    --[[------------------------------------
    CC and Focus Mark Controls
    --------------------------------------]]
    elseif button == "BOT_ASSIGN_CC_MARK_STAR" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark star")
    elseif button == "BOT_ASSIGN_CC_MARK_CIRCLE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark circle")
    elseif button == "BOT_ASSIGN_CC_MARK_DIAMOND" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark diamond")
    elseif button == "BOT_ASSIGN_CC_MARK_TRIANGLE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark triangle")
    elseif button == "BOT_ASSIGN_CC_MARK_SQUARE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark square")
    elseif button == "BOT_ASSIGN_CC_MARK_CROSS" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark cross")
    elseif button == "BOT_ASSIGN_CC_MARK_CLEAR" then
        if string.find(savedSettings["broadcastTo"],"CLASS") then
			MCM_Send(".z clear ccmark "..string.lower(MICROBOT_SELECTED_UNIT_CLASS))
		elseif string.find(savedSettings["broadcastTo"],"ROLE") then
			MCM_Send(".z clear ccmark "..string.lower(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"]))
		elseif string.find(savedSettings["broadcastTo"],"ALL") then
			ClearTarget()
			MCM_Send(".z clear ccmark")
		elseif string.find(savedSettings["broadcastTo"],"NONE") then
			SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "clear ccmark")
		end
    elseif button == "BOT_ASSIGN_CC_MARK_MOON" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark moon")
    elseif button == "BOT_ASSIGN_CC_MARK_SKULL" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "ccmark skull")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_STAR" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark star")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_CIRCLE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark circle")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_DIAMOND" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark diamond")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_TRIANGLE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark triangle")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_SQUARE" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark square")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_CROSS" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark cross")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_CLEAR" then
		 if string.find(savedSettings["broadcastTo"],"CLASS") then
			MCM_Send(".z clear focusmark "..string.lower(MICROBOT_SELECTED_UNIT_CLASS))
		elseif string.find(savedSettings["broadcastTo"],"ROLE") then
			MCM_Send(".z clear focusmark "..string.lower(allCompanionInfos[MICROBOT_SELECTED_UNIT_NAME]["role"]))
		elseif string.find(savedSettings["broadcastTo"],"ALL") then
			ClearTarget()
			MCM_Send(".z clear focusmark")
		elseif string.find(savedSettings["broadcastTo"],"NONE") then
			SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "clear focusmark")
		end
    elseif button == "BOT_ASSIGN_FOCUS_MARK_MOON" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark moon")
    elseif button == "BOT_ASSIGN_FOCUS_MARK_SKULL" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "focusmark skull")
    --[[------------------------------------
    Mage portals
    --------------------------------------]]
    elseif string.find(button, "^BOT_PORTAL_") then
        local _, _, city = string.find(button, "^BOT_PORTAL_(.+)$")
        if city then
            local portalCity = string.gsub(city, "_", " ")
            portalCity = string.gsub(portalCity, "(%a)([%w_']*)", function(first, rest)
                return string.upper(first)..string.lower(rest)
            end)
			SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "cast Portal: " .. portalCity)
			if string.find(savedSettings["autoTrade"],"ON") then	
				InitiateTrade(MICROBOT_SELECTED_UNIT)
				MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, 100000)
				 -- Use a non-blocking delay mechanism to let the target go through (c_timer does not work, less than a second misses them sometimes)
				local delayTime = 3.0
				local frame = CreateFrame("Frame")
				frame:SetScript("OnUpdate", function()
					delayTime = delayTime - arg1
					if delayTime <= 0 then
						if( MoneyInputFrame_GetCopper(TradePlayerInputMoneyFrame) == 100000) then
							AcceptTrade()
						end
						frame:SetScript("OnUpdate", nil)
					end
				end)
			end
        end
    --[[------------------------------------
    Mage Amplify Magic options
    --------------------------------------]]
    elseif button == "BOT_MAGE_AMPLIFY_USE" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set magic amplify")
    elseif button == "BOT_MAGE_DAMPEN_USE" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set magic dampen")
    elseif button == "BOT_MAGE_AMPLIFY_NEITHER" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set magic none")
		
	 --[[------------------------------------
    Mage Spec options
    --------------------------------------]]
    elseif button == "BOT_MAGE_SPEC_ARCANE" then
		BroadcastBotWhisperCommand({"CLASS"},"set spec arcane")
    elseif button == "BOT_MAGE_SPEC_FIRE" then
		BroadcastBotWhisperCommand({"CLASS"},"set spec fire")
    elseif button == "BOT_MAGE_SPEC_FROST" then
		BroadcastBotWhisperCommand({"CLASS"},"set spec frost")	
    --[[------------------------------------
    Warlock summon player ritual
    --------------------------------------]]
    elseif button == "BOT_WARLOCK_SUMMON_PLAYER_RITUAL" then
        local targetName = UnitName("target")
        local warlockName = MICROBOT_SELECTED_UNIT_NAME
        if not UnitInParty("target") and not UnitInRaid("target") then
            StaticPopupDialogs["SUMMON_INVALID_TARGET"] = {
                text = "You don't have a valid player targeted for Ritual of Summoning. Please target a player in your party or raid group.",
                button1 = OKAY,
                timeout = 0,
                hideOnEscape = 1,
            }
            StaticPopup_Show("SUMMON_INVALID_TARGET")
        else
			SendTargetedBotWhisperCommand(warlockName, "cast Ritual of Summoning")
			InitiateTrade(MICROBOT_SELECTED_UNIT)
			MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, 100000)
			 -- Use a non-blocking delay mechanism to let the target go through (c_timer does not work, less than a second misses them sometimes)
			local delayTime = 3.0
			local frame = CreateFrame("Frame")
			frame:SetScript("OnUpdate", function()
				delayTime = delayTime - arg1
				if delayTime <= 0 then
					if( MoneyInputFrame_GetCopper(TradePlayerInputMoneyFrame) == 100000) then
						AcceptTrade()
					end
					frame:SetScript("OnUpdate", nil)
				end
			end)
        end
    --[[------------------------------------
    Warlock soulstone
    --------------------------------------]]
	elseif string.find(button, "BOT_WARLOCK_SOULSTONE_TARGET") then
		BroadcastBotWhisperCommand({"CLASS"},"set soulstone on " .. UnitName("target"))		
    elseif string.find(button, "^BOT_WARLOCK_SOULSTONE_") then
        local _, _, playerName = string.find(button, "_([^_]+)$")
		BroadcastBotWhisperCommand({"CLASS"},"set soulstone on " .. playerName)	
    --[[------------------------------------
    Pet toggle
    --------------------------------------]]
    elseif button == "BOT_PET_ON" then
		BroadcastBotWhisperCommand({"CLASS"},"set pet on")      
    elseif button == "BOT_PET_OFF" then
		BroadcastBotWhisperCommand({"CLASS"},"set pet off")
	elseif button == "BOT_PET_GROWL_OFF" then
		BroadcastBotWhisperCommand({"CLASS"},"deny add growl")
	elseif button == "BOT_PET_GROWL_ON" then
		BroadcastBotWhisperCommand({"CLASS"},"deny remove growl")	
	
    --[[------------------------------------
    Hunter pets
    --------------------------------------]]
    elseif button == "BOT_HUNTER_PET_BAT" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet bat")
    elseif button == "BOT_HUNTER_PET_BEAR" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet bear")
    elseif button == "BOT_HUNTER_PET_BIRD" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet bird")
    elseif button == "BOT_HUNTER_PET_BOAR" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet boar")
    elseif button == "BOT_HUNTER_PET_CAT" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet cat")
    elseif button == "BOT_HUNTER_PET_CRAB" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet crab")
    elseif button == "BOT_HUNTER_PET_CROC" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet croc")
    elseif button == "BOT_HUNTER_PET_GORILLA" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet gorilla")
    elseif button == "BOT_HUNTER_PET_HYENA" then 
        BroadcastBotWhisperCommand({"CLASS"},"set pet hyena")
    elseif button == "BOT_HUNTER_PET_OWL" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet owl")
    elseif button == "BOT_HUNTER_PET_RAPTOR" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet raptor")
    elseif button == "BOT_HUNTER_PET_SCORPID" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet scorpid")
    elseif button == "BOT_HUNTER_PET_SERPENT" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet serpent")
    elseif button == "BOT_HUNTER_PET_SPIDER" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet spider")
    elseif button == "BOT_HUNTER_PET_STRIDER" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet strider")
    elseif button == "BOT_HUNTER_PET_TURTLE" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet turtle")
    elseif button == "BOT_HUNTER_PET_WOLF" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet wolf")
    --[[------------------------------------
    Hunter aspects
    --------------------------------------]]
    elseif button == "BOT_HUNTER_ASPECT_DEFAULT" then
        BroadcastBotWhisperCommand({"CLASS"},"set aspect cancel")
    elseif button == "BOT_HUNTER_ASPECT_HAWK" then
        BroadcastBotWhisperCommand({"CLASS"},"set aspect Aspect of the Hawk")
    elseif button == "BOT_HUNTER_ASPECT_CHEETAH" then
        BroadcastBotWhisperCommand({"CLASS"},"set aspect Aspect of the Cheetah")
    elseif button == "BOT_HUNTER_ASPECT_PACK" then
        BroadcastBotWhisperCommand({"CLASS"},"set aspect Aspect of the Pack")
    elseif button == "BOT_HUNTER_ASPECT_WILD" then
        BroadcastBotWhisperCommand({"CLASS"},"set aspect Aspect of the Wild")
    --[[------------------------------------
    Warlock pets
    --------------------------------------]]
    elseif button == "BOT_WARLOCK_PET_IMP" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet imp")
    elseif button == "BOT_WARLOCK_PET_VOIDWALKER" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet voidwalker")
    elseif button == "BOT_WARLOCK_PET_SUCCUBUS" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet succubus")
    elseif button == "BOT_WARLOCK_PET_FELHUNTER" then
        BroadcastBotWhisperCommand({"CLASS"},"set pet felhunter")
    --[[------------------------------------
    Paladin blessings
    --------------------------------------]]
    elseif button == "BOT_PALADIN_BLESSING_1_DEFAULT" then
        BroadcastBotWhisperCommand({"CLASS"},"set blessing cancel")
    elseif button == "BOT_PALADIN_BLESSING_1_MIGHT" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 52 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Greater Blessing of Might")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Blessing of Might")
        end
    elseif button == "BOT_PALADIN_BLESSING_1_WISDOM" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 54 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Greater Blessing of Wisdom")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Blessing of Wisdom")
        end
    elseif button == "BOT_PALADIN_BLESSING_1_KINGS" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 60 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Greater Blessing of Kings")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Blessing of Kings")
        end
    elseif button == "BOT_PALADIN_BLESSING_1_LIGHT" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 60 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Greater Blessing of Light")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Blessing of Light")
        end
    elseif button == "BOT_PALADIN_BLESSING_1_SALVATION" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 60 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Greater Blessing of Salvation")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing Blessing of Salvation")
        end
	 elseif button == "BOT_PALADIN_BLESSING_2_DEFAULT" then
        BroadcastBotWhisperCommand({"CLASS"},"set blessing cancel")
    elseif button == "BOT_PALADIN_BLESSING_MIGHT" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 52 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Greater Blessing of Might")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Blessing of Might")
        end
    elseif button == "BOT_PALADIN_BLESSING_2_WISDOM" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 54 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Greater Blessing of Wisdom")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Blessing of Wisdom")
        end
    elseif button == "BOT_PALADIN_BLESSING_2_KINGS" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 60 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Greater Blessing of Kings")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Blessing of Kings")
        end
    elseif button == "BOT_PALADIN_BLESSING_2_LIGHT" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 60 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Greater Blessing of Light")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Blessing of Light")
        end
    elseif button == "BOT_PALADIN_BLESSING_2_SALVATION" then
        if MICROBOT_SELECTED_UNIT_LEVEL >= 60 then
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Greater Blessing of Salvation")
        else
            BroadcastBotWhisperCommand({"CLASS"},"set blessing second Blessing of Salvation")
        end
    --[[------------------------------------
    Paladin auras
    --------------------------------------]]
    elseif button == "BOT_PALADIN_AURAS_DEFAULT" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura cancel")
    elseif button == "BOT_PALADIN_AURA_DEVOTION" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Devotion Aura")
    elseif button == "BOT_PALADIN_AURA_RETRIBUTION" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Retribution Aura")
    elseif button == "BOT_PALADIN_AURA_SANCTITY" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Sanctity Aura")
    elseif button == "BOT_PALADIN_AURA_CONCENTRATION" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Concentration Aura")
    elseif button == "BOT_PALADIN_AURA_SHADOW_RESISTANCE" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Shadow Resistance Aura")
    elseif button == "BOT_PALADIN_AURA_FROST_RESISTANCE" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Frost Resistance Aura")
    elseif button == "BOT_PALADIN_AURA_FIRE_RESISTANCE" then
        BroadcastBotWhisperCommand({"CLASS"},"set aura Fire Resistance Aura")
	--[[------------------------------------
    Paladin Specs
    --------------------------------------]]
    elseif button == "BOT_PALADIN_SPEC_MAGIC" then
        BroadcastBotWhisperCommand({"CLASS"},"set spec magic")
    elseif button == "BOT_PALADIN_SPEC_MIGHT" then
        BroadcastBotWhisperCommand({"CLASS"},"set spec might")		
	--[[------------------------------------
    Paladin Weapons
    --------------------------------------]]
    elseif button == "BOT_PALADIN_WEAPON_NIGHTFALL" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon nightfall")
		runGearChangeTimer(MICROBOT_SELECTED_UNIT_NAME)
    elseif button == "BOT_PALADIN_WEAPON_NORMAL" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon normal")
		runGearChangeTimer(MICROBOT_SELECTED_UNIT_NAME)
    --[[------------------------------------
    Shaman air totems
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_AIR_TOTEM_GRACE" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Grace of Air Totem")
    elseif button == "BOT_SHAMAN_AIR_TOTEM_NATURE" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Nature Resistance Totem")
    elseif button == "BOT_SHAMAN_AIR_TOTEM_WINDFURY" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Windfury Totem")
    elseif button == "BOT_SHAMAN_AIR_TOTEM_GROUNDING" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Grounding Totem")
    elseif button == "BOT_SHAMAN_AIR_TOTEM_TRANQUIL" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Tranquil Air Totem")
	elseif button == "BOT_SHAMAN_AIR_TOTEM_NATURE_CAST" then
        BroadcastBotWhisperCommand({"CLASS"},"cast Nature Resistance Totem")
    --[[------------------------------------
    Shaman earth totems
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_EARTH_TOTEM_STONESKIN" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Stoneskin Totem")
    elseif button == "BOT_SHAMAN_EARTH_TOTEM_EARTHBIND" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Earthbind Totem")
    elseif button == "BOT_SHAMAN_EARTH_TOTEM_STRENGTH" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Strength of Earth Totem")
    elseif button == "BOT_SHAMAN_EARTH_TOTEM_TREMOR" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Tremor Totem")
    --[[------------------------------------
    Shaman fire totems
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_FIRE_TOTEM_SEARING" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Searing Totem")
    elseif button == "BOT_SHAMAN_FIRE_TOTEM_FIRE_NOVA" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Fire Nova Totem")
    elseif button == "BOT_SHAMAN_FIRE_TOTEM_FROST_RESISTANCE" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Frost Resistance Totem")
    elseif button == "BOT_SHAMAN_FIRE_TOTEM_MAGMA" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Magma Totem")
    elseif button == "BOT_SHAMAN_FIRE_TOTEM_FLAMETONGUE" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Flametongue Totem")
	elseif button == "BOT_SHAMAN_FIRE_TOTEM_FROST_RESISTANCE_CAST" then
        BroadcastBotWhisperCommand({"CLASS"},"cast Frost Resistance Totem")
    --[[------------------------------------
    Shaman water totems
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_WATER_TOTEM_HEALING" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Healing Stream Totem")
    elseif button == "BOT_SHAMAN_WATER_TOTEM_MANA_SPRING" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Mana Spring Totem")
    elseif button == "BOT_SHAMAN_WATER_TOTEM_FIRE_RESISTANCE" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Fire Resistance Totem")
    elseif button == "BOT_SHAMAN_WATER_TOTEM_DISEASE_CLEANSING" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Disease Cleansing Totem")
    elseif button == "BOT_SHAMAN_WATER_TOTEM_POISON_CLEANSING" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem Poison Cleansing Totem")
	elseif button == "BOT_SHAMAN_WATER_TOTEM_FIRE_RESISTANCE_CAST" then
        BroadcastBotWhisperCommand({"CLASS"},"cast Fire Resistance Totem")
	 elseif button == "BOT_SHAMAN_WATER_TOTEM_POISON_CLEANSING_CAST" then
        BroadcastBotWhisperCommand({"CLASS"},"cast Poison Cleansing Totem")
    --[[------------------------------------
    Shaman Clear & Toggle totems
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_CLEAR_TOTEMS" then
        BroadcastBotWhisperCommand({"CLASS"},"set totem cancel")
    elseif button == "BOT_SHAMAN_TOGGLE_TOTEMS" then
        SendTargetedBotZCommand(MICROBOT_SELECTED_UNIT, "toggle totems")
	 --[[------------------------------------
    Shaman weapons
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_WEAPON_DEFAULT" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon auto")
    elseif button == "BOT_SHAMAN_WEAPON_ROCKBITER" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon rockbiter")
	elseif button == "BOT_SHAMAN_WEAPON_FLAMETOUNGUE" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon flametongue")
	elseif button == "BOT_SHAMAN_WEAPON_FROSTBRAND" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon frostbrand")
	elseif button == "BOT_SHAMAN_WEAPON_WINDFURY" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon windfury")
    elseif button == "BOT_SHAMAN_WEAPON_NONE" then
        SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, "set weapon none")
    --[[------------------------------------
    Shaman Reincarnation
    --------------------------------------]]
    elseif button == "BOT_SHAMAN_REINCARNATION_ALLOW" then
        BroadcastBotWhisperCommand({"CLASS"},"deny remove reincarnation")
    elseif button == "BOT_SHAMAN_REINCARNATION_DENY" then
        BroadcastBotWhisperCommand({"CLASS"},"deny add reincarnation")
    --[[------------------------------------
    Druid Rebirth
    --------------------------------------]]
    elseif button == "BOT_DRUID_REBIRTH_ALLOW" then
        BroadcastBotWhisperCommand({"CLASS"},"deny remove rebirth")
    elseif button == "BOT_DRUID_REBIRTH_DENY" then
        BroadcastBotWhisperCommand({"CLASS"},"deny add rebirth")
	--[[------------------------------------
    Druid Rebirth cast
    --------------------------------------]]
    elseif button == "BOT_DRUID_REBIRTH_CAST" then
        local targetName = UnitName("target")
        local druidName = MICROBOT_SELECTED_UNIT_NAME
        if not UnitInParty("target") and not UnitInRaid("target") then
            StaticPopupDialogs["REBIRTH_INVALID_TARGET"] = {
                text = "You don't have a valid player targeted for Rebirth. Please target a player in your party or raid group.",
                button1 = OKAY,
                timeout = 0,
                hideOnEscape = 1,
            }
            StaticPopup_Show("REBIRTH_INVALID_TARGET")
        else
            SendTargetedBotWhisperCommand(druidName, "cast Rebirth")
        end
	
    --[[------------------------------------
    Deny danger spells
    --------------------------------------]]
    elseif button == "BOT_DENY_DANGER_SPELLS" then
		local function getDangerSpellsforComp(name)
			local whisperMsg = ""
			local compUnitID = allCompanionInfos[name]["unitID"]
			if tostring(UnitClass(compUnitID)) == "Mage" then
				whisperMsg = "deny add blink"           
			elseif tostring(UnitClass(compUnitID)) == "Priest" then
				whisperMsg = "deny add psychic scream"
				if UnitLevel(compUnitID) >= 20 then
					whisperMsg =  whisperMsg .. ",holy nova"
				end				
			elseif tostring(UnitClass(compUnitID)) == "Warlock" then
				whisperMsg = "deny add fear"
				if UnitLevel(compUnitID) >= 40 then
					whisperMsg =  whisperMsg .. ",howl of terror"
				end
				if UnitLevel(compUnitID) >= 42 then					
					whisperMsg =  whisperMsg .. ",death coil"
				end
			elseif tostring(UnitClass(compUnitID)) == "Paladin" then
				whisperMsg = "deny add turn undead"
			elseif tostring(UnitClass(compUnitID)) == "Warrior" then
				whisperMsg = "deny add intimidating shout"
			elseif tostring(UnitClass(compUnitID)) == "Hunter" then
				whisperMsg = "deny add scare beast"
			end
			return whisperMsg
		end
		if(savedSettings["broadcastTo"] == "ALL") then
			for _, comp in pairs(mageCompanions) do
				SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
			end
			for _, comp in pairs(priestCompanions) do
				SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
			end
			for _, comp in pairs(warlockCompanions) do
				SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
			end
			for _, comp in pairs(paladinCompanions) do
				SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
			end
			for _, comp in pairs(warriorCompanions) do
				SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
			end
			for _, comp in pairs(hunterCompanions) do
				SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
			end
		elseif(savedSettings["broadcastTo"] == "CLASS") then
			if(MICROBOT_SELECTED_UNIT_CLASS == "Mage") then
				for _, comp in pairs(mageCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
			if(MICROBOT_SELECTED_UNIT_CLASS == "Priest") then
				for _, comp in pairs(priestCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
			if(MICROBOT_SELECTED_UNIT_CLASS == "Warlock") then
				for _, comp in pairs(warlockCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
			if(MICROBOT_SELECTED_UNIT_CLASS == "Paladin") then
				for _, comp in pairs(paladinCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
			if(MICROBOT_SELECTED_UNIT_CLASS == "Warrior") then
				for _, comp in pairs(warriorCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
			if(MICROBOT_SELECTED_UNIT_CLASS == "Hunter") then
				for _, comp in pairs(hunterCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
		elseif(savedSettings["broadcastTo"] == "ROLE") then
			if(table_contains(rdpsCompanions,MICROBOT_SELECTED_UNIT_NAME)) then
				for _, comp in pairs(rdpsCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			elseif (table_contains(mdpsCompanions,MICROBOT_SELECTED_UNIT_NAME)) then
				for _, comp in pairs(mdpsCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			elseif (table_contains(tankCompanions,MICROBOT_SELECTED_UNIT_NAME)) then
				for _, comp in pairs(tankCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			elseif (table_contains(healerCompanions,MICROBOT_SELECTED_UNIT_NAME)) then
				for _, comp in pairs(healerCompanions) do
					SendTargetedBotWhisperCommand(comp, getDangerSpellsforComp(comp))
				end
			end
		else 
			SendTargetedBotWhisperCommand(MICROBOT_SELECTED_UNIT_NAME, getDangerSpellsforComp(MICROBOT_SELECTED_UNIT_NAME))
		end
        
    --[[------------------------------------
    Rogue stealth control
    --------------------------------------]]
    elseif button == "BOT_ROGUE_STEALTH_ON" then
        BroadcastBotWhisperCommand({"CLASS"},"deny remove stealth")
    elseif button == "BOT_ROGUE_STEALTH_OFF" then
        BroadcastBotWhisperCommand({"CLASS"},"deny add stealth")
    --[[------------------------------------
    Druid stealth control
    --------------------------------------]]
    elseif button == "BOT_DRUID_STEALTH_ON" then
        BroadcastBotWhisperCommand({"CLASS"},"deny remove prowl")
    elseif button == "BOT_DRUID_STEALTH_OFF" then
        BroadcastBotWhisperCommand({"CLASS"},"deny add prowl")
    --[[------------------------------------
    Priest Fear Ward
    --------------------------------------]]
	elseif button == "BOT_PRIEST_FEAR_WARD_TARGET" then
		BroadcastBotWhisperCommand({"CLASS"},"set fearward on %t")
    elseif string.find(button, "^BOT_PRIEST_FEAR_WARD_") then
        local _, _, playerName = string.find(button, "_([^_]+)$")
        BroadcastBotWhisperCommand({"CLASS"},"set fearward on " .. playerName)
		
	--[[------------------------------------
    Priest Power Infusion
    --------------------------------------]]
	elseif button == "BOT_PRIEST_POWER_INFUSION_TARGET" then
		BroadcastBotWhisperCommand({"CLASS"},"set powerinfusion on %t")
    elseif string.find(button, "^BOT_PRIEST_POWER_INFUSION_") then
        local _, _, playerName = string.find(button, "_([^_]+)$")
        BroadcastBotWhisperCommand({"CLASS"},"sset powerinfusion on " .. playerName)
    --[[------------------------------------
    Default Behavior
    --------------------------------------]]
    else
        originalUnitPopupOnClick()
    end
    -- Close the dropdown menus
    CloseDropDownMenus()
end

 --[[------------------------------------
	Slash Commands
--------------------------------------]]
SLASH_MICROBOTCONTEXTMENUS1 = "/mcm"

SlashCmdList["MICROBOTCONTEXTMENUS"] = function(msg)
	
	if msg == "broadcast none" or msg == "bc none" then
		setBroadcast("NONE")
	elseif msg == "broadcast all" or msg == "bc all" then
		setBroadcast("ALL") 
	elseif msg == "broadcast role" or msg == "bc role" then
		setBroadcast("ROLE")	
	elseif msg == "broadcast class" or msg == "bc class" then
		setBroadcast("CLASS")
	elseif msg == "toggle broadcast" or msg == "tbc" then
		toggleBroadcastMode()
	elseif msg == "autotrade on" or msg == "at on" then
		setAutoTrade("ON")
	elseif msg == "autotrade off" or msg == "at off" then
		setAutoTrade("OFF")
	elseif msg == "toggle autotrade" or msg == "tat" then
		toggleAutoTrade()
	elseif msg == "debug on" then
		setDebug("ON")
	elseif msg == "debug off" then
		setDebug("OFF")
	else
		DEFAULT_CHAT_FRAME:AddMessage("ContexMenu accepted commands:") 
		DEFAULT_CHAT_FRAME:AddMessage("/mcm broadcast none / bc none | broadcast all / bc all | broadcast class / bc class | broadcast role / bc role | toggle broadcast / tbc")
		DEFAULT_CHAT_FRAME:AddMessage("/mcm autotrade on / at on  | autotrade off / at off | toggle autotrade / tat")
		DEFAULT_CHAT_FRAME:AddMessage("/mcm debug on | debug off")
	end
	
end