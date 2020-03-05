local addonName, addonTable = ...

-- addon object created using Ace3
local Accounting = LibStub('AceAddon-3.0'):NewAddon(
	'Multiboxer_Accounting', 'AceEvent-3.0', 'AceTimer-3.0')
addonTable[1] = Accounting
_G[addonName] = Accounting


function Accounting:OnEnable()
	self:InitDatabase() -- deal with SavedVariables	
	self:RegisterEvent('MAIL_SHOW')
	self:RegisterEvent('MAIL_CLOSED')
	self:RegisterEvent('MAIL_INBOX_UPDATE')
end

function Accounting:MAIL_SHOW()
	self.mailOpen = true

	if not self.inboxUpdate then
		self:ScheduleTimer('MAIL_SHOW', 0.3)
		return
	end
	self:StoreMailMoney()
	self.inboxUpdate = false
end

function Accounting:MAIL_CLOSED()
	self.mailOpen = false
end

function Accounting:MAIL_INBOX_UPDATE()
	if not self.inboxUpdate then
		self.inboxUpdate = true
	end
end

function Accounting:GUILDBANKFRAME_OPENED()
	self.charData.money.guild = GetGuildBankMoney()
end

function Accounting:GUILDBANK_UPDATE_MONEY()
	self.charData.money.guild = GetGuildBankMoney()
end

function Accounting:PLAYER_MONEY()
	self.charData.money.inventory = GetMoney()
	print(self.mailOpen)
	if self.mailOpen then
		print('checking')
		self:StoreMailMoney()
	else
		print('not checking')
	end
end

function Accounting:PLAYER_LOGOUT()
	-- remove empty charData
	if not next(self.charData) then
		self.db[self.realmName][self.charName] = nil
	end
	-- remove empty realmData
	if not next(self.db[self.realmName]) then
		self.db[self.realmName] = nil
	end
end

function Accounting:StoreMailMoney()
	print('checking mail money')
	CheckInbox()
	local numMails, _ = GetInboxNumItems()
	local mailMoney = 0

	for i = 1, numMails do
		--local isInvoice = select(5, GetInboxText(i))
		local money = select(5, GetInboxHeaderInfo(i))
		if money > 0 then
			mailMoney = mailMoney + money
		end
	end

	if mailMoney < 0 then mailMoney = nil end
	self.charData.money.mail = mailMoney
	print(mailMoney)
end

function Accounting:InitDatabase()
	-- First time running the addon (usually db = nil)
	if not Multiboxer_AccountingDB or type(Multiboxer_AccountingDB) ~= 'table' then
		Multiboxer_AccountingDB = {}
	end
	self.db = Multiboxer_AccountingDB

	local charName, realmName = UnitName('player'), GetRealmName()
	self.charName = charName
	self.realmName = realmName

	self.db[realmName] = self.db[realmName] or {}
	self.charData = self.db[realmName][charName] or {}
	self.db[realmName][charName] = self.charData 
	
	self:InitMoneyInfo() 
	self:RegisterEvent('PLAYER_LOGOUT')

	-- remove mail info
	--[[
	for realm, realmData in pairs(self.db) do
		for char, charData in pairs(realmData) do
			charData.money.mail = nil
		end
	end
	]]
end

function Accounting:InitMoneyInfo()
	local money = self.charData.money or {}
	self.charData.money = money

	-- store inventory money
	local level = UnitLevel('unit') < 25 -- lower than lvl 25
	--local inventory = GetMoney() > 500000000 -- more than 50k gold
	local inventory = true
	if level and inventory then
		money.inventory = GetMoney()
		self:RegisterEvent('PLAYER_MONEY')
	end

	-- store guild money if guild master
	if IsInGuild() then
		local guildRank = select(3, GetGuildInfo('player'))
		if guildRank == 0 then 
			self:RegisterEvent('GUILDBANKFRAME_OPENED')
			self:RegisterEvent('GUILDBANK_UPDATE_MONEY')
		end
	end
end


