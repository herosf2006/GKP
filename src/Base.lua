---------------------------------------------------------------------->
-- 脚本名称:    E:\JX3_EXP\bin\zhcn_exp\interface\JH\GKP\src\Base.lua
-- 更新时间:    2014/10/20 14:07:11
-- 更新用户:    Webster
-- 脚本说明:    GKP金团记录 开源支持学习
----------------------------------------------------------------------<
GKP = {
	Config = {
		bDebug = false, -- /script ... 
		bOn = true, -- 是分配者就开启
		bOn2 = false, -- 不是分配者关闭
		bMoneyTalk = false, -- 金钱变动喊话
		bAlertMessage = true, -- 进入副本提醒清空数据
		bCheckScore = true, -- 查看装备分
		bMoneySystem = false, -- 记录系统金钱变动
		bDeathWarn = false, -- 重伤提示
		bAutoSetMoney = false, --自动设置发布时的金钱
		bAutoBX = true, -- 自动设置碧玺碎片的价格
		bDisplayEmptyRecords = true, -- show 0 record
		bAutoSync = true, -- 自动接收分配者的同步信息
	}
}

---------------------------------------------------------------------->
-- 本地函数与变量
----------------------------------------------------------------------<
local _GKP = {
	szVersion = "v0.9.7",
	szPath = "interface/JH/@DATA/",
	szIniFile = "interface/JH/GKP/ui/GKP.ini",
	aDoodadCache = {}, -- 拾取列表cache
	aDistributeList = {}, -- 当前拾取列表
	tLootListMoney = {}, -- 发布的金钱cache
	tDistribute = {}, -- 待记账列表
	tDistributeRecords = {},
	tDungeonList = {},
	tViewInvite = {},
	tDelayCall = {},
	DeathWarn = {},
	aPartyMember = {
		{szName = "test user 1", dwForceID = 1, dwForce = 1, bOnlineFlag = true, dwID = 0},
		{szName = "test user 2", dwForceID = 2, dwForce = 2, bOnlineFlag = true, dwID = 1},
		{szName = "test user 3", dwForceID = 5, dwForce = 5, bOnlineFlag = true, dwID = 2},
		{szName = "test user 4", dwForceID = 7, dwForce = 7, bOnlineFlag = true, dwID = 3},
		{szName = "test user 5", dwForceID = 9, dwForce = 9, bOnlineFlag = true, dwID = 4},
		{szName = "test user 6", dwForceID = 0, dwForce = 0, bOnlineFlag = true, dwID = 5},
		{szName = "test user 7", dwForceID = 6, dwForce = 6, bOnlineFlag = true, dwID = 6},
		{szName = "test user 8", dwForceID = 11, dwForce = 11, bOnlineFlag = true, dwID = 8},
		{szName = "test user 9", dwForceID = 6, dwForce = 6, bOnlineFlag = true, dwID = 9},
		{szName = "test user 10 ban", dwForceID = 5, dwForce = 5, bOnlineFlag = false, dwID = 10},
	},
	tQualityImage = {nil,13,12,14,11}, -- Frame
	tForceCol = {
		[0] = {255, 255, 255},
		[3] = {255, 111, 83},
		[2] = {196, 152, 255},
		[4] = {89, 224, 232},
		[5] = {255, 129, 176},
		[1] = {255, 178, 95},
		[8] = {214, 249, 93},
		[6] = {55, 147, 255},
		[7] = {121, 183, 54},
		[10] = {240, 70, 96},
		[9] = {205,133,63},
	},
	tSyncQueue = {},
	bSync = {},
	GKP_Record = {},
	GKP_Account = {},
	Config = {
		Subsidies = {
			{"宝箱","",true},
			{"碧玺碎片","",true},
			{"老板包团","",true},
			{"宴席补贴",-1000,true},
			{"犯错罚款","",true},
			{"其他","",true},
		},
		Scheme = {
			{100,true},
			{1000,true},
			{2000,true},
			{3000,true},
			{4000,true},
			{5000,true},
			{6000,true},
			{7000,true},
			{8000,true},
			{9000,true},
			{10000,true},
			{20000,true},
			{50000,true},
			{100000,true},
		},
		Special = {
			["浮屠陨铁"] = true,
			["乌金陨铁"] = true,
			["天外陨铁"] = true,
			["蜀玉裂石"] = true,
			["碧玺碎片"] = true,
		},
	}
}
_GKP.Config = LoadLUAData(_GKP.szPath.. "/config/gkp.cfg") or _GKP.Config
---------------------------------------------------------------------->
-- 职业着色
----------------------------------------------------------------------<
setmetatable(_GKP.tForceCol,{ __call = function(me,dwForce)
	if me[dwForce] then
		return me[dwForce]
	else
		return {255,255,255}
	end
end})
---------------------------------------------------------------------->
-- 数据处理
----------------------------------------------------------------------<
setmetatable(GKP,{ __call = function(me,key,value,sort)
	if _GKP[key] then
		if value and type(value) == "table" then
			table.insert(_GKP[key],value)
			pcall(_GKP.GKP_Save)
		elseif value and type(value) == "string" then
			if sort == "asc" or sort == "desc" then
				table.sort(_GKP[key],function(a,b)
					if a[value] and b[value] then
						if a[value] == b[value] then
							if sort == "asc" then
								return a.nTime < b.nTime
							else
								return a.nTime > b.nTime
							end
						else
							if sort == "asc" then
								return a[value] < b[value]
							else
								return a[value] > b[value]
							end
						end
					else
						return false
					end
				end)
			elseif value == "del" then
				if _GKP[key][sort] then
					_GKP[key][sort].bDelete = not _GKP[key][sort].bDelete
					pcall(_GKP.GKP_Save)
					return _GKP[key][sort]
				end
			end
			return _GKP[key]
		elseif value and type(value) == "number" then
			if _GKP[key][value] then
				_GKP[key][value] = sort
				pcall(_GKP.GKP_Save)
				return _GKP[key][value]
			end
		else
			return _GKP[key]
		end
	end
end})

---------------------------------------------------------------------->
-- get segment name
----------------------------------------------------------------------<
if not Table_GetSegmentName then
function Table_GetSegmentName(dwBookID, dwSegmentID)
	local szSegmentName = ""
	local tBookSegment = g_tTable.BookSegment:Search(dwBookID, dwSegmentID)
	if tBookSegment then
		szSegmentName = tBookSegment.szSegmentName
	end
	return szSegmentName
end
end
---------------------------------------------------------------------->
-- get item name by item
----------------------------------------------------------------------<
if not GetItemNameByItem then
function GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	else
		return Table_GetItemName(item.nUiId)
	end
end
end
---------------------------------------------------------------------->
-- 本地函数
----------------------------------------------------------------------<
_GKP.SaveConfig = function()
	SaveLUAData(_GKP.szPath .. "/config/gkp.cfg",_GKP.Config)
	GKP.Debug("Save Config ...")
end

_GKP.GKP_Save = function()
	local me = GetClientPlayer()
	local szPath = _GKP.szPath .. me.szName .. "/" .. FormatTime("%Y-%m-%d",GetCurrentTime()) .. ".gkp"	
	SaveLUAData(szPath,{ GKP_Record = GKP("GKP_Record") , GKP_Account = GKP("GKP_Account") })
	GKP.Debug("Save Data ...")
end
_GKP.GKP_LoadData = function(szFile)
	local me = GetClientPlayer()
	local szPath = _GKP.szPath .. szFile .. ".gkp"
	local t = LoadLUAData(szPath)
	if t then
		_GKP.GKP_Record = t.GKP_Record or {}
		_GKP.GKP_Account = t.GKP_Account or {}
	end
	pcall(_GKP.Draw_GKP_Record)
	pcall(_GKP.Draw_GKP_Account)
	GKP.Debug("Load Data / " .. szPath)
end
_GKP.OpenPanel = function(bDisableSound)
	local frame = Station.Lookup("Normal/GKP") or Wnd.OpenWindow(_GKP.szIniFile, "GKP")
	frame:Show()
	frame:BringToTop()
	pcall(_GKP.Draw_GKP_Buff)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end
-- close
_GKP.ClosePanel = function(bRealClose)
	if _GKP.frame then
		if not bRealClose then
			_GKP.frame:Hide()
		else
			Wnd.CloseWindow(_GKP.frame)
			_GKP.frame = nil
		end
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end
-- toggle
_GKP.TogglePanel = function()
	if _GKP.frame and _GKP.frame:IsVisible() then
		_GKP.ClosePanel()
	else
		_GKP.OpenPanel()
	end
end
-- initlization
_GKP.Init = function()
	if not _GKP.bInit then
		Wnd.OpenWindow("interface/JH/GKP/ui/GKP_Loot.ini","GKP_Loot"):Hide()
		Wnd.OpenWindow("interface/JH/GKP/ui/GKP_Record.ini","GKP_Record"):Hide()
		Wnd.OpenWindow("interface/JH/GKP/ui/GKP.ini","GKP"):Hide()
		local me = GetClientPlayer()
		_GKP.nNowMoney = me.GetMoney().nGold
		_GKP.bInit = true
		GKP.DelayCall(50,function() -- Init延后 避免和进入副本冲突
			_GKP.GKP_LoadData(me.szName .. "/" .. FormatTime("%Y-%m-%d",GetCurrentTime()))
		end)
	end
end
RegisterEvent("LOADING_END",_GKP.Init) -- LOADING_END 主要是为了获取名字 所以压到最后加载

---------------------------------------------------------------------->
-- 常用函数
----------------------------------------------------------------------<
GKP.Random = function() -- 生成一个随机字符串 这还能重复我吃翔
	local a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,_+ [];*-/"
	local t = {}
	for i = 1, 64 do
		local n = math.random(1,string.len(a))
		table.insert(t,string.sub(a,n,n))
	end
	return table.concat(t,"")
end

GKP.RegisterCustomData = function(szVarPath)
	if _G and type(_G[szVarPath]) == "table" then
		for k, _ in pairs(_G[szVarPath]) do
			RegisterCustomData(szVarPath .. "." .. k)
		end
	else
		RegisterCustomData(szVarPath)
	end
end

GKP.RegisterCustomData("GKP.Config")

GKP.Sysmsg = function(szMsg)
	OutputMessage("MSG_SYS","[GKP] " .. szMsg .."\n")
end

GKP.Alert = function(szMsg, fnAction, szSure)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 2.5, szMessage = "[GKP] " .. szMsg, szName = "GKP",
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		},
	}
	MessageBox(tMsg,true)
end

GKP.Confirm = function(szMsg, fnAction, fnCancel, szSure, szCancel)
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 2.5, szMessage = "[GKP] " .. szMsg, szName = "GKP_Confirm" .. GetTime(),
		{
			szOption = szSure or g_tStrings.STR_HOTKEY_SURE,
			fnAction = fnAction,
		}, {
			szOption = szCancel or g_tStrings.STR_HOTKEY_CANCEL,
			fnAction = fnCancel,
		},
	}
	MessageBox(tMsg)
end

GKP.Debug = function(szMsg)
	if GKP.Config.bDebug then
		OutputMessage("MSG_SYS","[GKP_DEBUG] " .. szMsg .."\n")
	end
end

GKP.BgTalk = function(...)
	local tSay = { { type = "text", text = "BG_CHANNEL_MSG" } }
	local tArg = { ... }
	for _, v in ipairs(tArg) do
		if v == nil then
			break
		end
		table.insert(tSay, { type = "text", text = tostring(v) })
	end
	GetClientPlayer().Talk(PLAYER_TALK_CHANNEL.RAID,"",tSay)
end

GKP.AscIIEncode = function(szText)
	return szText:gsub('(.)',function(s) return string.format("%02x",s:byte()) end)
end

GKP.AscIIDecode = function(szText)
	return szText:gsub('([0-9a-f][0-9a-f])',function(s) return string.char(tonumber(s,16)) end)
end
GKP.DelayCall = function(nDelay, fnAction)
	local nTime = nDelay + GetTime()
	table.insert(_GKP.tDelayCall, { nTime = nTime, fnAction = fnAction })
end
GKP.Talk = function(tSay,szName)
	local me = GetClientPlayer()
	local nChannel,name,say = PLAYER_TALK_CHANNEL.RAID,"",tSay
	if szName then
		nChannel,name = PLAYER_TALK_CHANNEL.WHISPER,szName
	end
	if type(tSay) == "string" then
		say = {{type = "text" ,text = tSay}}
	end
	me.Talk(nChannel,name,say)
end

GKP.Split = function(szFull, szSep)
	local nOff, tResult = 1, {}
	while true do
		local nEnd = StringFindW(szFull, szSep, nOff)
		if not nEnd then
			table.insert(tResult, string.sub(szFull, nOff, string.len(szFull)))
			break
		else
			table.insert(tResult, string.sub(szFull, nOff, nEnd - 1))
			nOff = nEnd + string.len(szSep)
		end
	end
	return tResult
end

GKP.GetTimeString = function(nTime,year)
	if year then
		return FormatTime("%H:%M:%S",nTime)
	else
		return FormatTime("%Y-%m-%d %H:%M:%S",nTime)
	end
end

GKP.GetForceCol = function(dwForce)
	return unpack(_GKP.tForceCol(dwForce))
end

GKP.GetMoneyCol = function(Money)
	local Money = tonumber(Money)
	if Money then
		if Money < 0 then
			return 0,128,255
		elseif Money < 10000 then
			return 255,255,255
		elseif Money < 100000 then
			return 255,255,0
		elseif Money < 1000000 then
			return 255,128,0
		else
			return 255,0,0
		end
	else
		return 255,255,255
	end
end
---------------------------------------------------------------------->
-- 判断分配者
----------------------------------------------------------------------<
GKP.IsDistributer = function()
	local me = GetClientPlayer()
	local team = GetClientTeam()	
	local dwDistributerID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) 
	if dwDistributerID == me.dwID then
		return true
	end
	return false
end
---------------------------------------------------------------------->
-- 判断是否在副本地图
----------------------------------------------------------------------<
GKP.IsInDungeon = function()
	if IsEmpty(_GKP.tDungeonList) then
		_GKP.tDungeonList = {}
		for k,v in ipairs(GetMapList()) do
			local a = g_tTable.DungeonInfo:Search(v)
			if a and a.dwClassID == 3 then
				_GKP.tDungeonList[a.dwMapID] = true
			end 
		end
	end
	local me = GetClientPlayer()
	return _GKP.tDungeonList[me.GetMapID()] or false
end

---------------------------------------------------------------------->
-- 格式化item链接
----------------------------------------------------------------------<
GKP.GetFormatLink = function(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		return { type = "book",tabtype = item.dwTabType, index = item.dwIndex, bookinfo = item.nBookID, version = item.nVersion,text = "" }
	else 
		return { type = "iteminfo",version = item.nVersion,tabtype = item.dwTabType,index = item.dwIndex,text = "" }
	end
end
---------------------------------------------------------------------->
-- 获取团队成员 menu
----------------------------------------------------------------------<
GKP.GetTeamList = function()
	local TeamMemberList = GetClientTeam().GetTeamMemberList()
	local tTeam,menu = {},{}
	if GKP.Config.bDebug then 
		tTeam = _GKP.aPartyMember 
	else
		for _,v in ipairs(TeamMemberList) do
			local player = GetClientTeam().GetMemberInfo(v)
			table.insert(tTeam,{ szName = player.szName ,dwForce = player.dwForceID})
		end
	end
	table.sort(tTeam,function(a,b) return a.dwForce < b.dwForce end)
	for _,v in ipairs(tTeam) do
		local szIcon,nFrame = GetForceImage(v.dwForce)
		table.insert(menu,{
			szOption = v.szName,
			szLayer = "ICON_RIGHT",
			szIcon = szIcon,
			nFrame = nFrame ,
			rgb = {GKP.GetForceCol(v.dwForce)},
			fnAction = function()
				local list = GUI(Station.Lookup("Normal1/GKP_Record/TeamList"))
				local teamlist = list:Text(v.szName):Color(GKP.GetForceCol(v.dwForce)).self
				teamlist.dwForceID = v.dwForce
			end
		})
	end
	return menu
end


---------------------------------------------------------------------->
-- 窗体创建时会被调用
----------------------------------------------------------------------<
function GKP.OnFrameCreate()
	_GKP.frame = this
	_GKP.GKP_Record_Container = this:Lookup("PageSet_Menu/Page_GKP_Record/WndScroll_GKP_Record/WndContainer_Record_List")
	_GKP.GKP_Account_Container = this:Lookup("PageSet_Menu/Page_GKP_Account/WndScroll_GKP_Account/WndContainer_Account_List")
	_GKP.GKP_Buff_Container = this:Lookup("PageSet_Menu/Page_GKP_Buff/WndScroll_GKP_Buff/WndContainer_Buff_List")
	
	this.OnFrameKeyDown = function()
		if GetKeyName(Station.GetMessageKey()) == "Esc" then
			_GKP.ClosePanel()
			return 1
		end
	end
	local fx, fy = Station.GetClientSize()
	local w,h = this:GetSize()
	local ui = GUI(this)
	local PageSet = ui:Fetch("PageSet_Menu")
	local record = GUI(Station.Lookup("Normal1/GKP_Record"))
	
	ui:Pos((fx-w)/2,(fy-h)/2):Append("WndComboBox",{x = 805,y = 52,txt = "设置"}):Menu(_GKP.GetSettingMenu)
	ui:Fetch("Btn_Close"):Click(_GKP.ClosePanel)
	PageSet:Append("WndButton2",{x = 50,y = 610,txt = "手动添加"}):Click(function()
		if record:IsVisible() then
			return GKP.Alert("当前物品还没有记录。")
		end
		pcall(_GKP.Record)
	end)
	PageSet:Append("WndButton2",{x = 850,y = 610,txt = "结算工资"}):Click(_GKP.GKP_Calculation)
	PageSet:Append("WndButton2",{x = 745,y = 610,txt = "消费情况"}):Click(_GKP.GKP_SpendingList)
	PageSet:Append("WndButton2",{x = 640,y = 610,txt = "欠债发布"}):Click(_GKP.GKP_OweList)
	PageSet:Append("WndButton2",{x = 535,y = 610,txt = "清空记录"}):Click(_GKP.GKP_Clear)
	PageSet:Append("WndButton2",{x = 430,y = 610,txt = "加载记录"}):Click(_GKP.GKP_Recovery)
	PageSet:Append("WndButton2",{x = 325,y = 610,txt = "手动同步"}):Click(_GKP.GKP_Sync)
	if IsFileExist("interface/ZFix/GKP") then -- 和谐自用
		PageSet:Append("WndButton2",{x = 220,y = 610,txt = "发钱"}):Click(_GKP.GKP_Bidding)
	end
	
	
	local w,h = record:Size()
	record:Pos((fx-w)/2,(fy-h)/2)
	
	record:Fetch("Btn_Close"):Click(function()
		if this.userdata then
			record:Fetch("Money"):Text(0)
			return record:Fetch("btn_ok"):Click()
		end
		record:Toggle(false)
		FireEvent("GKP_DEL_DISTRIBUTE_ITEM")
	end)
	
	record:Append("WndButton2",{x = 145,y = 300,txt = "确定"}):Name("btn_ok")
	record:Append("WndComboBox",{x = 135,y = 53,txt = "选择成员"}):Name("TeamList"):Menu(GKP.GetTeamList)
	record:Append("WndEdit",{x = 135,y = 155,w = 185,h = 25}):Name("Source")
	
	
	local fnAction_Name = function()
		local me = this
		local txt = me:GetText()
		if txt ~= "" then
			if IsPopupMenuOpened() then 
				Wnd.CloseWindow("PopupMenuPanel")
				me.txt = nil
			end
			return 
		end
		if IsPopupMenuOpened() then
			return
		end
		local menu = {}
		for k,v in ipairs(_GKP.Config.Subsidies) do
			if v[3] then
				table.insert(menu,{
					szOption = v[1],
					fnAction = function()
						me:SetText(v[1])
						record:Fetch("Money"):Text(v[2]):Focus()
					end
				})
			end
		end
		local nX, nY = this:GetAbsPos()
		local nW, nH = this:GetSize()
		menu.nMiniWidth = nW
		menu.x = nX
		menu.y = nY + nH
		menu.bShowKillFocus = true
		menu.bDisableSound = true		
		PopupMenu(menu)
		Station.SetFocusWindow(me)
	end
	record:Append("WndEdit",{x = 135,y = 125,w = 185,h = 25}):Name("Name"):Focus(fnAction_Name,function()
		GKP.DelayCall(20,function()
			if not Station.GetFocusWindow() then return end
			local szFocusWindow = Station.GetFocusWindow():GetName()
			if szFocusWindow ~= "Edit_Default" and szFocusWindow ~= "PopupMenuPanel" then
				Wnd.CloseWindow("PopupMenuPanel")
			end
		end)
	end):Change(fnAction_Name)
	
	local fnAction =  function()
		local me = this
		local txt = me:GetText()
		if IsPopupMenuOpened() and me.txt and me.txt == txt then
			return
		end
		if tonumber(me:GetText()) then
			me.txt = me:GetText()
			me:SetFontColor(GKP.GetMoneyCol(me:GetText()))
			if tonumber(me:GetText()) >= 1000 or tonumber(me:GetText()) <= -1000 or tonumber(me:GetText()) == 0 then
				if IsPopupMenuOpened() then
					Wnd.CloseWindow("PopupMenuPanel")
				end
				return
			end
			local menu = {}
			for k,v in ipairs({2,3,4}) do
				local nMoney = string.format("%0.".. v .."f", me:GetText()):gsub("%.","")
				table.insert(menu,{
					szOption = nMoney,
					rgb = {GKP.GetMoneyCol(nMoney)},
					fnAction = function()
						me:SetText(nMoney)
					end
				})
			end
			local nX, nY = me:GetAbsPos()
			local nW, nH = me:GetSize()
			menu.nMiniWidth = nW
			menu.x = nX
			menu.y = nY + nH
			menu.bShowKillFocus = true
			menu.bDisableSound = true
			PopupMenu(menu)
			Station.SetFocusWindow(me)
		elseif txt == "" then
			me.txt = nil
			if IsPopupMenuOpened() then 
				Wnd.CloseWindow("PopupMenuPanel")
			end
		else
			if me.txt then
				me:SetText(me.txt)
			else
				me:SetText(0)
			end
		end
	end
	record:Append("WndEdit",{x = 135,y = 185,w = 185,h = 25}):Name("Money"):Focus(fnAction,function()
		GKP.DelayCall(20,function()
			if not Station.GetFocusWindow() then return end
			local szFocusWindow = Station.GetFocusWindow():GetName()
			if szFocusWindow ~= "Edit_Default" and szFocusWindow ~= "PopupMenuPanel" then
				Wnd.CloseWindow("PopupMenuPanel")
			end
		end)
	end):Change(fnAction)
	-- 排序
	local page = this:Lookup("PageSet_Menu/Page_GKP_Record")
	for k ,v in ipairs({false,"szPlayer","szName","nMoney","szNpcName","nTime"}) do
		if v then
			local txt = page:Lookup("","Text_Record_Break"..k)
			txt:RegisterEvent(786)
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or "asc"
				pcall(_GKP.Draw_GKP_Record,v,sort)
				if sort == "asc" then
					txt.sort = "desc"
				else
					txt.sort = "asc"
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255,128,0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255,255,255)
			end
		end
	end
	
	-- 排序2
	local page = this:Lookup("PageSet_Menu/Page_GKP_Account")
	for k ,v in ipairs({false,"szPlayer","nGold","szPlayer","dwMapID","nTime"}) do
		if v then
			local txt = page:Lookup("","Text_Account_Break"..k)
			txt:RegisterEvent(786)
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or "asc"
				pcall(_GKP.Draw_GKP_Account,v,sort)
				if sort == "asc" then
					txt.sort = "desc"
				else
					txt.sort = "asc"
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255,128,0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255,255,255)
			end
		end
	end
	-- 排序3
	local page = this:Lookup("PageSet_Menu/Page_GKP_Buff")
	for k ,v in ipairs({false,"dwForceID","nScore1","nScore2","nEquipScore","bFightState"}) do
		if v then
			local txt = page:Lookup("","Text_Buff_Break"..k)
			txt:RegisterEvent(786)
			txt.OnItemLButtonClick = function()
				local sort = txt.sort or "asc"
				pcall(_GKP.Draw_GKP_Buff,v,sort)
				if sort == "asc" then
					txt.sort = "desc"
				else
					txt.sort = "asc"
				end
			end
			txt.OnItemMouseEnter = function()
				this:SetFontColor(255,128,0)
			end
			txt.OnItemMouseLeave = function()
				this:SetFontColor(255,255,255)
			end
		end
	end
	
	local loot = Station.Lookup("Normal/GKP_Loot")
	loot.OnFrameKeyDown = function()
		if GetKeyName(Station.GetMessageKey()) == "Esc" then
			this:Hide()
			return 1
		end
	end
	loot:Lookup("Btn_Close").OnLButtonClick = function() loot:Hide() end
	local fx, fy = Station.GetClientSize()
	local w,h = loot:GetSize()
	loot:SetAbsPos((fx-w)/2,(fy-h)/2)
end
---------------------------------------------------------------------->
-- 呼吸函数
----------------------------------------------------------------------<
function GKP.OnFrameBreathe()
	-- run delay calls
	local nTime = GetTime()
	for k = #_GKP.tDelayCall, 1, -1 do
		local v = _GKP.tDelayCall[k]
		if v.nTime <= nTime then
			local res, err = pcall(v.fnAction)
			if not res then
				GKP.Debug("DelayCall#" .. k .." ERROR: " .. err)
			end
			table.remove(_GKP.tDelayCall, k)
		end
	end
end
---------------------------------------------------------------------->
-- 获取设置菜单
----------------------------------------------------------------------<
_GKP.GetSettingMenu = function()
	local menu = {}
	table.insert(menu,{ szOption = "GKP " .. _GKP.szVersion,bDisable = true})
	table.insert(menu,{ bDevide = true })
	table.insert(menu,{ szOption = "偏好设置",bDisable = true})
	table.insert(menu,{ szOption = "显示记录为0金的条目", bCheck = true , bChecked = GKP.Config.bDisplayEmptyRecords,fnAction = function()
		GKP.Config.bDisplayEmptyRecords = not GKP.Config.bDisplayEmptyRecords
		pcall(_GKP.Draw_GKP_Record)
	end })	
	table.insert(menu,{ szOption = "自动填充右键发布时的金钱", bCheck = true , bChecked = GKP.Config.bAutoSetMoney,fnAction = function()
		GKP.Config.bAutoSetMoney = not GKP.Config.bAutoSetMoney
	end })
	table.insert(menu,{ szOption = "自动填充碧玺碎片数量为价格", bCheck = true , bChecked = GKP.Config.bAutoBX,fnAction = function()
		GKP.Config.bAutoBX = not GKP.Config.bAutoBX
	end })
	table.insert(menu,{ szOption = "进入副本提醒清空数据", bCheck = true, bChecked = GKP.Config.bAlertMessage,fnAction = function()
		GKP.Config.bAlertMessage = not GKP.Config.bAlertMessage
	end })
	table.insert(menu,{ szOption = "自动接收分配者发出的记录同步", bCheck = true, bChecked = GKP.Config.bAutoSync,fnAction = function()
		GKP.Config.bAutoSync = not GKP.Config.bAutoSync
	end })
	table.insert(menu,{ szOption = "弹出记录选项",
		{ szOption = "是分配者弹出记录", bCheck = true, bChecked = GKP.Config.bOn,fnAction = function()
			GKP.Config.bOn = not GKP.Config.bOn
		end},
		{ szOption = "不是分配者也弹出记录", bCheck = true, bChecked = GKP.Config.bOn2,fnAction = function()
			GKP.Config.bOn2 = not GKP.Config.bOn2
		end }
	})
	table.insert(menu,{ bDevide = true })
	table.insert(menu,{ szOption = "金钱记录",bDisable = true})
	table.insert(menu,{ szOption = "记录系统金钱变动", bCheck = true , bChecked = GKP.Config.bMoneySystem,fnAction = function()
		GKP.Config.bMoneySystem = not GKP.Config.bMoneySystem
	end })
	table.insert(menu,{ szOption = "开启金钱变动喊话", bCheck = true , bChecked = GKP.Config.bMoneyTalk,fnAction = function()
		GKP.Config.bMoneyTalk = not GKP.Config.bMoneyTalk
	end })
	table.insert(menu,{ bDevide = true})
	table.insert(menu,{ szOption = "团队概况",bDisable = true})
	table.insert(menu,{ szOption = "团队概况显示装备分", bCheck = true, bChecked = GKP.Config.bCheckScore,fnAction = function()
		GKP.Config.bCheckScore = not GKP.Config.bCheckScore
	end })
	table.insert(menu,{ szOption = "实时播报重伤提示", bCheck = true, bChecked = GKP.Config.bDeathWarn,fnAction = function()
		GKP.Config.bDeathWarn = not GKP.Config.bDeathWarn
	end })
	table.insert(menu,{ bDevide = true })
	table.insert(menu,{ szOption = "预设方案修改", bDisable = true})
	table.insert(menu,_GKP.GetSubsidiesMenu())
	table.insert(menu,_GKP.GetSchemeMenu())
	table.insert(menu,{ bDevide = true})
	table.insert(menu,{ szOption = "开发调试/测试人员", bCheck = true, bChecked = GKP.Config.bDebug,fnAction = function()
		GKP.Confirm("警告：开启调试模式将会使插件无视权限规定，越权显示不可执行的操作，但这些并不能真正的被服务器接受，非开发者请不要勾选，避免造成误解，请勿在开团时尝试，可能造成记录混乱等问题。",function()
			GKP.Config.bDebug = not GKP.Config.bDebug
		end)
	end })
	if GKP.Config.bDebug then
		table.insert(menu,{ szOption = "物品表",fnAction = function()
			Output(_GKP.GKP_Record)
		end })
		table.insert(menu,{ szOption = "金钱表",fnAction = function()
			Output(_GKP.GKP_Account)
		end })
		table.insert(menu,{ szOption = "配置表",fnAction = function()
			Output(_GKP.Config)
		end })
		table.insert(menu,{ szOption = "记忆表",fnAction = function()
			Output(_GKP.tDistributeRecords)
		end })
		table.insert(menu,{ szOption = "待记账表",fnAction = function()
			Output(_GKP.tDistribute)
		end })
		table.insert(menu,{ szOption = "发布时金钱表",fnAction = function()
			Output(_GKP.tLootListMoney)
		end })
		table.insert(menu,{ szOption = "当前拾取表",fnAction = function()
			Output(_GKP.aDistributeList)
		end })
		table.insert(menu,{ szOption = "副本表",fnAction = function()
			Output(_GKP.tDungeonList)
		end })
		table.insert(menu,{ szOption = "待查看装备表",fnAction = function()
			Output(_GKP.tViewInvite)
		end })
	end
	
	return menu
end
---------------------------------------------------------------------->
-- 获取补贴方案菜单
----------------------------------------------------------------------<
_GKP.GetSubsidiesMenu = function()
	local menu = { szOption = "编辑补贴方案" , rgb = {255,0,0} }
	table.insert(menu,{
		szOption = "添加新方案",
		rgb = {255,255,0},
		fnAction = function()
			GetUserInput("新方案 格式：方案名,金钱",function(txt)
				local t = GKP.Split(txt,",")
				table.insert(_GKP.Config.Subsidies,{t[1],tonumber(t[2]) or "",true})
				pcall(_GKP.SaveConfig)
			end)
		end
	})
	table.insert(menu,{bDevide = true})
	for k,v in ipairs(_GKP.Config.Subsidies) do
		table.insert(menu,{
			szOption = v[1],
			bCheck = true,
			bChecked = v[3],
			fnAction = function()
				v[3] = not v[3]
				pcall(_GKP.SaveConfig)
			end,
		})
	end
	return menu
end
---------------------------------------------------------------------->
-- 获取拍卖方案菜单
----------------------------------------------------------------------<
_GKP.GetSchemeMenu = function()
	local menu = { szOption = "编辑拍卖方案" , rgb = {255,0,0} }
	table.insert(menu,{
		szOption = "编辑所有方案",
		rgb = {255,255,0},
		fnAction = function()
			GetUserInput("新方案 格式：金钱,金钱,金钱,...",function(txt)
				local t = GKP.Split(txt,",")
				_GKP.Config.Scheme = {}
				for k,v in ipairs(t) do
					table.insert(_GKP.Config.Scheme,{tonumber(v) or 0,true})
				end
				pcall(_GKP.SaveConfig)
			end)
		end
	})
	table.insert(menu,{bDevide = true})
	for k,v in ipairs(_GKP.Config.Scheme) do
		table.insert(menu,{
			szOption = v[1],
			bCheck = true,
			bChecked = v[2],
			fnAction = function()
				v[2] = not v[2]
				pcall(_GKP.SaveConfig)
			end,
		})
	end
	
	return menu
end
---------------------------------------------------------------------->
-- 获取玩家身上Buff列表
----------------------------------------------------------------------<
_GKP.GetBuffList = function(obj)
	local aBuffTable = {}
	local nCount = obj.GetBuffCount()
	for i=1,nCount,1 do
		local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
		if dwID then
			table.insert(aBuffTable,{dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame, nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid})
		end
	end
	return aBuffTable
end
---------------------------------------------------------------------->
-- 绘制团队概况
----------------------------------------------------------------------<
_GKP.Draw_GKP_Buff = function(key,sort)
	GKP.DelayCall(3000,function() -- 无所谓了 关闭窗口 kill
		if _GKP.frame:IsVisible() then
			local res , err = pcall(_GKP.Draw_GKP_Buff)
			if err then
				GKP.Debug(err)
			end
		end
	end)
	local key = key or _GKP.GKP_Buff_Container.key or "nEquipScore"
	local sort = sort or _GKP.GKP_Buff_Container.sort or "desc"
	_GKP.GKP_Buff_Container.key = key
	_GKP.GKP_Buff_Container.sort = sort
	_GKP.GKP_Buff_Container:Clear()
	local me = GetClientPlayer()
	if not me.IsInParty() then
		return
	end
	local team = GetClientTeam()
	local TeamMemberList = team.GetTeamMemberList()
	local tType = { [24] = true ,[17] = true,[18] = true,[19] = true,[20] = true }
	local tType2 = { [362] = true, [673] = true,[112] = true ,[382] = true , [3219] = true , [2837] = true }
	local tNameEx = {
		["隐居"] = 3694590,
		["樱墨"] = 1301156,
	}
	local tab = {}
	for k,v in ipairs(TeamMemberList) do
		local player = GetPlayer(v)
		local tPlayer = team.GetMemberInfo(v)
		local t = {
			dwID = v,
			Box1 = {},
			Box2 = {},
			szName = tPlayer.szName,
			dwForceID = tPlayer.dwForceID,
			dwMountKungfuID = tPlayer.dwMountKungfuID,
			nScore1 = 0,
			nScore2 = 0,
			nEquipScore = 0,
			bFightState = 2,
		}
		if player then
			for _, tBuff in ipairs(_GKP.GetBuffList(player)) do
				local nType = GetBuffInfo(tBuff.dwID,tBuff.nLevel,{}).nDetachType or 0
				if tType[nType] then
					table.insert(t.Box1,tBuff)
					t.nScore1 = t.nScore1 + 1
				end
				if tType2[tBuff.dwID] then
					table.insert(t.Box2,tBuff)
					t.nScore2 = t.nScore2 + 1
				end
			end
			local nEquipScore = player.GetTotalEquipScore()
			if GKP.Config.bCheckScore then
				if nEquipScore == 0 then
					_GKP.tViewInvite[v] = true
					local PlayerView = Station.Lookup("Normal/PlayerView")
					if not PlayerView or not PlayerView:IsVisible() then
						ViewInviteToPlayer(v)
					end
				end
			end
			t.nEquipScore = nEquipScore
			if player.bFightState then
				t.bFightState = 1
			else
				t.bFightState = 0
			end
		end
		table.insert(tab,t)
	end

	table.sort(tab,function(a,b)
		if a[key] and b[key] then
			if sort == "asc" then
				return a[key] < b[key]
			else
				return a[key] > b[key]
			end
		else
			return false
		end
	end)
	
	for k,v in ipairs(tab) do
		local wnd = _GKP.GKP_Buff_Container:AppendContentFromIni("interface/JH/GKP/ui/GKP_Buff_Item.ini","WndWindow",k)
		local item = wnd:Lookup("","")
		if k % 2 == 0 then
			item:Lookup("Image_Line"):Hide()
		end
		local player = GetPlayer(v.dwID)
		item:Lookup("Text_No"):SetText(k)
		-- item:Lookup("Image_NameIcon"):FromUITex(GetForceImage(v.dwForceID))
		item:Lookup("Image_NameIcon"):FromIconID(Table_GetSkillIconID(v.dwMountKungfuID))
		item:Lookup("Text_Name"):SetText(v.szName)
		item:Lookup("Text_Name"):SetFontColor(GKP.GetForceCol(v.dwForceID))
		local ex,r,g,b = "不在范围内",255,255,255
		if tNameEx[v.szName] and tNameEx[v.szName] == v.dwID then
			player = nil
			ex,r,g,b = "Access denied",255,128,0
		end
		if player then
			for kk, vv in pairs(v.Box1) do
				wnd:Lookup("","Handle_Box1"):AppendItemFromString("<box>w=28 h=28 name=\"".. vv.nIndex  .."\"</box>")
				local box = wnd:Lookup("","Handle_Box1"):Lookup(tostring(vv.nIndex))
				wnd:Lookup("","Handle_Box1"):FormatAllItemPos()
				box:SetObject(UI_OBJECT_ITEM)
				box:SetObjectIcon(Table_GetBuffIconID(vv.dwID,vv.nLevel))
				box:RegisterEvent(786)
				local nTime = (vv.nEndFrame - GetLogicFrameCount()) / 16
				if nTime < 480 then
					box:SetAlpha(80)
				end
				box.OnItemMouseLeave = function()
					this:SetObjectMouseOver(false)
					HideTip()
				end
				box.OnItemMouseEnter = function()
					this:SetObjectMouseOver(true)
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputBuffTip(player,vv.dwID,vv.nLevel,0,true,nTime,{x,y,w,h})
				end
			end
			
			-- wnd:Lookup("","Handle_Box1"):SetRelPos(200+ (150 - #v.Box1 * 28) / 2 ,0)

			for kk, vv in pairs(v.Box2) do
				wnd:Lookup("","Handle_Box2"):AppendItemFromString("<box>w=28 h=28 name=\"".. vv.nIndex  .."\"</box>")
				local box = wnd:Lookup("","Handle_Box2"):Lookup(tostring(vv.nIndex))
				wnd:Lookup("","Handle_Box2"):FormatAllItemPos()
				box:SetObject(UI_OBJECT_ITEM)
				box:SetObjectIcon(Table_GetBuffIconID(vv.dwID,vv.nLevel))
				box:RegisterEvent(786)
				local nTime = (vv.nEndFrame - GetLogicFrameCount()) / 16
				if nTime < 480 then
					box:SetAlpha(80)
				end
				box.OnItemMouseLeave = function()
					this:SetObjectMouseOver(false)
					HideTip()
				end
				box.OnItemMouseEnter = function()
					this:SetObjectMouseOver(true)
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputBuffTip(player,vv.dwID,vv.nLevel,0,true,nTime,{x,y,w,h})
				end
			end

			-- wnd:Lookup("","Handle_Box2"):SetRelPos(350 + (150 - #v.Box2 * 28) / 2 ,0)
			-- wnd:Lookup("",""):FormatAllItemPos()
			if v.bFightState == 1 then
				item:Lookup("Text_Fight"):SetText("战斗中")
				item:Lookup("Text_Fight"):SetFontColor(255,0,0)
			else
				item:Lookup("Text_Fight"):SetText("不在战斗中")
				item:Lookup("Text_Fight"):SetFontColor(0,255,0)
			end
			if GKP.Config.bCheckScore then
				item:Lookup("Text_Score"):SetText(v.nEquipScore)
			else
				item:Lookup("Text_Score"):SetText("未开启")
			end			
		else
			for kk,vv in ipairs({"Text_Box1","Text_Box2","Text_Score","Text_Fight"}) do
				item:Lookup(vv):SetText(ex)
				item:Lookup(vv):SetFontColor(r,g,b)
			end
		end
		item:Lookup("Text_Time"):SetText(GKP.GetTimeString(GetCurrentTime()))
		item:Lookup("Text_Name"):RegisterEvent(786)
		item:Lookup("Text_Name").OnItemLButtonClick = function()
			if IsCtrlKeyDown() then
				local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
				edit:InsertObj("[" .. v.szName .. "]",{ type = "name" , name = v.szName , text = v.szName})
				Station.SetFocusWindow(edit)
				return
			end
			SetTarget(TARGET.PLAYER,v.dwID)
			ViewInviteToPlayer(v.dwID)
		end
		
		item:Lookup("Text_Name").OnItemMouseEnter = function()
			local szIcon,nFrame = GetForceImage(v.dwForceID)
			local r,g,b = GKP.GetForceCol(v.dwForceID)
			local szXml = GetFormatImage(szIcon,nFrame,20,20) .. GetFormatText("  " .. v.szName .. "：\n",136,r,g,b)
			szXml = szXml .. GetFormatText("---------- 重伤记录如下 ----------\n\n",136,255,255,255)
			if not _GKP.DeathWarn.tDeath[v.dwID] or #_GKP.DeathWarn.tDeath[v.dwID] == 0 then
				szXml = szXml ..GetFormatText("没有任何记录\n",136,255,255,0)
			else
				for i = #_GKP.DeathWarn.tDeath[v.dwID] , 1 , -1 do
					local a = _GKP.DeathWarn.tDeath[v.dwID][i]
					szXml = szXml ..GetFormatText(GKP.GetTimeString(a.time,true) .. " ",136,255,255,0)
					szXml = szXml ..GetFormatText(a.szCaster,136,255,128,0)
					szXml = szXml ..GetFormatText(" 的 ",136,255,255,0)
					szXml = szXml ..GetFormatText(a.szSkillName,136,255,128,0)
					szXml = szXml ..GetFormatText(" 造成了 ",136,255,255,0)
					szXml = szXml ..GetFormatText(a.szValue .. "\n",136,255,128,0)
				end
			end
			local x, y = item:Lookup("Text_No"):GetAbsPos()
			local w, h = item:Lookup("Text_No"):GetSize()
			OutputTip(szXml,600,{x,y,w,h})
		end
		
		item:Lookup("Text_Name").OnItemMouseLeave = function()
			HideTip()
		end
	end
	_GKP.GKP_Buff_Container:FormatAllContentPos()	
end

---------------------------------------------------------------------->
-- 查看装备回调事件
----------------------------------------------------------------------<
RegisterEvent("PEEK_OTHER_PLAYER", function()
	if arg0 ~= 1 then return end
	if _GKP.tViewInvite[arg1] then
		_GKP.tViewInvite[arg1] = nil
		for k,v in pairs(_GKP.tViewInvite) do
			return ViewInviteToPlayer(k)
		end
		GKP.DelayCall(200,function()
			Station.Lookup("Normal/PlayerView"):Hide()
		end)
	end
end)
---------------------------------------------------------------------->
-- 绘制物品记录
----------------------------------------------------------------------<
_GKP.Draw_GKP_Record = function(key,sort)
	local key = key or _GKP.GKP_Record_Container.key or "nTime"
	local sort = sort or _GKP.GKP_Record_Container.sort or "desc"
	local tab = GKP("GKP_Record",key,sort)
	_GKP.GKP_Record_Container.key = key
	_GKP.GKP_Record_Container.sort = sort
	_GKP.GKP_Record_Container:Clear()
	local a,b = _GKP.GetRecordSum()
	local c = 0
	for k,v in ipairs(tab) do
		if GKP.Config.bDisplayEmptyRecords or v.nMoney ~= 0 then
			local wnd = _GKP.GKP_Record_Container:AppendContentFromIni("interface/JH/GKP/ui/GKP_Record_Item.ini","WndWindow",i)
			local item = wnd:Lookup("","")
			if k % 2 == 0 then
				item:Lookup("Image_Line"):Hide()
			end
			if v.bDelete then
				wnd:SetAlpha(80)
			end
			item:RegisterEvent(32)
			item.OnItemRButtonClick = function()
				_GKP.Record(v,k)
			end
			item:Lookup("Text_No"):SetText(k)
			item:Lookup("Image_NameIcon"):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup("Text_Name"):SetText(v.szPlayer)
			item:Lookup("Text_Name"):SetFontColor(GKP.GetForceCol(v.dwForceID))
			local szName = v.szName or Table_GetItemName(v.nUiId)
			item:Lookup("Text_ItemName"):SetText(szName)
			if v.nQuality then
				item:Lookup("Text_ItemName"):SetFontColor(GetItemFontColorByQuality(v.nQuality))
			else
				item:Lookup("Text_ItemName"):SetFontColor(255,255,0)
			end
			item:Lookup("Text_Money"):SetText(v.nMoney)
			item:Lookup("Text_Money"):SetFontColor(GKP.GetMoneyCol(v.nMoney))
			
			item:Lookup("Text_Source"):SetText(v.szNpcName)
			if v.bSync then
				item:Lookup("Text_Source"):SetFontColor(0,255,0)
			end
			item:Lookup("Text_Time"):SetText(GKP.GetTimeString(v.nTime))
			if v.bEdit then
				item:Lookup("Text_Time"):SetFontColor(255,255,0)
			end
			local box = item:Lookup("Box_Item")
			box:SetObject(UI_OBJECT_ITEM_INFO, v.nVersion, v.dwTabType, v.dwIndex)
			box:SetObjectIcon(Table_GetItemIconID(v.nUiId))
			
			if v.nStackNum then
				box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
				box:SetOverTextFontScheme(0,15)
				box:SetOverText(0, v.nStackNum .. " ")
			end
			if v.dwTabType == 0 and v.dwIndex == 0 then box:SetObjectIcon(95) end
			item:Lookup("Text_ItemName"):RegisterEvent(786)
			box:RegisterEvent(786)
			local OnItemMouseEnter = function()
				box:SetObjectMouseOver(true)
				local x, y = box:GetAbsPos()
				local w, h = box:GetSize()
				if v.nBookID then
					local dwBookID, dwSubID = GlobelRecipeID2BookID(v.nBookID)
					OutputBookTipByID(dwBookID, dwSubID,{x, y, w, h})
				else
					local _,dwTabType,dwIndex = box:GetObjectData()
					if dwTabType == 0 and dwIndex == 0 then return end
					OutputItemTip(UI_OBJECT_ITEM_INFO,GLOBAL.CURRENT_ITEM_VERSION,dwTabType,dwIndex,{x, y, w, h})
				end
			end
			
			item:Lookup("Text_ItemName").OnItemMouseEnter = OnItemMouseEnter
			box.OnItemMouseEnter = OnItemMouseEnter
			
			local OnItemMouseLeave = function()
				box:SetObjectMouseOver(false)
				HideTip()
			end
			
			item:Lookup("Text_ItemName").OnItemMouseLeave = OnItemMouseLeave
			box.OnItemMouseLeave = OnItemMouseLeave
			local OnItemLButtonClick = function()
				if IsCtrlKeyDown() then
					if v.dwTabType == 0 and v.dwIndex == 0 then return end
					local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
					edit:InsertObj("[" ..szName.. "]",GKP.GetFormatLink(v))
					Station.SetFocusWindow(edit)
					return
				end
			end
			item:Lookup("Text_ItemName").OnItemLButtonClick = OnItemLButtonClick
			box.OnItemLButtonClick = OnItemLButtonClick
			
			wnd:Lookup("WndButton_Delete").OnLButtonClick = function()
				local tab = GKP("GKP_Record","del",k)
				if GKP.IsDistributer() then
					GKP.BgTalk("del",GKP.AscIIEncode(GKP.JsonEncode(tab)))
				end
				pcall(_GKP.Draw_GKP_Record)
			end
			
			wnd:Lookup("WndButton_Edit").OnLButtonClick = function()
				_GKP.Record(v,k)
			end
			
			-- tip
			item:Lookup("Text_Name"):RegisterEvent(786)
			item:Lookup("Text_Name").OnItemLButtonClick = function()
				if IsCtrlKeyDown() then
					local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
					edit:InsertObj("[" .. v.szPlayer .. "]",{ type = "name" , name = v.szPlayer , text = v.szPlayer})
					Station.SetFocusWindow(edit)
					return
				end
			end
			
			item:Lookup("Text_Name").OnItemMouseEnter = function()
				local szIcon,nFrame = GetForceImage(v.dwForceID)
				local r,g,b = GKP.GetForceCol(v.dwForceID)
				local szXml = GetFormatImage(szIcon,nFrame,20,20) .. GetFormatText("  " .. v.szPlayer .. "：\n",136,r,g,b)
				szXml = szXml .. GetFormatText("---------- 统计信息如下 ----------\n\n",136,255,255,255)
				local nNum,nNum1,nNum2 = 0,0,0
				for kk,vv in ipairs(GKP("GKP_Record")) do
					if vv.szPlayer == v.szPlayer and not vv.bDelete then
						if  vv.nMoney > 0 then
							nNum = nNum + vv.nMoney
						else
							nNum1 = nNum1 + vv.nMoney
						end
					end
				end
				local r,g,b = GKP.GetMoneyCol(nNum)
				szXml = szXml .. GetFormatText("总计消费：",136,255,128,0) .. GetFormatText(nNum .."金。\n",136,r,g,b)
				local r,g,b = GKP.GetMoneyCol(nNum1)
				szXml = szXml .. GetFormatText("总计补贴：",136,255,128,0) .. GetFormatText(nNum1 .."金。\n",136,r,g,b)
				
				for kk,vv in ipairs(GKP("GKP_Account")) do
					if vv.szPlayer == v.szPlayer and not vv.bDelete and vv.nGold > 0 then
						nNum2 = nNum2 + vv.nGold
					end
				end
				local r,g,b = GKP.GetMoneyCol(nNum2)
				szXml = szXml .. GetFormatText("总计付款：",136,255,128,0) .. GetFormatText(nNum2 .."金。\n",136,r,g,b)
				local nNum3 = nNum+nNum1-nNum2
				if nNum3 < 0 then
					nNum3 = 0
				end
				local r,g,b = GKP.GetMoneyCol(nNum3)			
				szXml = szXml .. GetFormatText("欠债金额：",136,255,128,0) .. GetFormatText(nNum3 .."金。\n",136,r,g,b)
				
				local x, y = item:Lookup("Text_No"):GetAbsPos()
				local w, h = item:Lookup("Text_No"):GetSize()
				OutputTip(szXml,400,{x,y,w,h})
			end
			
			item:Lookup("Text_Name").OnItemMouseLeave = function()
				HideTip()
			end
			
			if v.bDelete then
				c = c + 1
			end
		end
	end
	_GKP.GKP_Record_Container:FormatAllContentPos()
	local txt = Station.Lookup("Normal/GKP/PageSet_Menu/Page_GKP_Record"):Lookup("","Text_GKP_RecordSettlement")
	txt:SetText(string.format("统计：实际工资 ＝ %d金（拍卖所得：%d金 ＋ 额外补贴：%d金）%d条记录被删除",a+b,a,b,c))
	txt:SetFontColor(255,255,0)
end
---------------------------------------------------------------------->
-- 和谐
----------------------------------------------------------------------<
_GKP.GKP_Bidding = function()
	local team = GetClientTeam()
	if not GKP.IsDistributer() then
		return GKP.Alert("你不是分配者。")
	end	
	local nGold = _GKP.GetRecordSum(true)
	if nGold <= 0 then
		return GKP.Alert("拍卖金额<=0。")
	end
	team.SetTeamLootMode(PARTY_LOOT_MODE.BIDDING)
	local GoldTeam = Wnd.OpenWindow("GoldTeam")
	local LeaderAddMoney = Wnd.OpenWindow("LeaderAddMoney")
	local fx, fy = Station.GetClientSize()
	local w,h = GoldTeam:GetSize()
	local w2,h2 = LeaderAddMoney:GetSize()
	GoldTeam:Hide()
	GoldTeam:SetAbsPos((fx-w)/2,(fy-h)/2)
	LeaderAddMoney:SetAbsPos((fx-w2)/2,(fy-h2)/2)
	LeaderAddMoney:Lookup("Edit_Price"):SetText(nGold)
	LeaderAddMoney:Lookup("Edit_Reason"):SetText("Auto Append Money")
	LeaderAddMoney:Lookup("Btn_Ok").OnLButtonUp = function()
		GoldTeam:Show()
		Station.SetActiveFrame("GoldTeam")
		GoldTeam:Lookup("PageSet_Total"):ActivePage(1)
	end	
end
---------------------------------------------------------------------->
-- 同步数据
----------------------------------------------------------------------<
_GKP.GKP_Sync = function()
	local me = GetClientPlayer()
	if not me.IsInParty() then return GKP.Alert("你不在队伍中。") end
	local TeamMemberList = GetClientTeam().GetTeamMemberList()
	local tTeam,menu = {},{}
	for _,v in ipairs(TeamMemberList) do
		local player = GetClientTeam().GetMemberInfo(v)
		table.insert(tTeam,{ szName = player.szName ,dwForce = player.dwForceID ,bIsOnLine = player.bIsOnLine})
	end
	table.sort(tTeam,function(a,b) return a.dwForce < b.dwForce end)
	table.insert(menu,{szOption = "请选择向谁获取记录",	bDisable = true	})
	table.insert(menu,{bDevide = true})
	for _,v in ipairs(tTeam) do
		local szIcon,nFrame = GetForceImage(v.dwForce)
		table.insert(menu,{
			szOption = v.szName,
			szLayer = "ICON_RIGHT",
			bDisable = not v.bIsOnLine,
			szIcon = szIcon,
			nFrame = nFrame ,
			rgb = {GKP.GetForceCol(v.dwForce)},
			fnAction = function()
				GKP.Confirm("是否将当前的记录替换为同步对象的记录？\n请注意，这将失去你当前记录的信息。\n",function()
					GKP.Alert("正在请求同步信息.... \n如果长时间没有反应可能是对方没有使用GKP插件或未响应。")
					GKP.BgTalk("GKP_Sync",v.szName) -- 请求同步信息
				end)
			end
		})
	end
	PopupMenu(menu)
end
_GKP.OnMsg = function()
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if team then
		local t = me.GetTalkData()
		if t[2].text == "GKP_Sync" and t[3].text == me.szName then
			local tab = {
				GKP_Record = GKP("GKP_Record"),
				GKP_Account = GKP("GKP_Account"),
			}
			local str = GKP.AscIIEncode(GKP.JsonEncode(tab))
			local nMax = 150
			local nTotle = math.ceil(#str / nMax)
			GKP.BgTalk("GKP_Sync_Start",arg3)
			for i = 1 , nTotle do
				GKP.BgTalk("GKP_Sync_Content",arg3,string.sub(str ,(i-1) * nMax + 1 , i * nMax))
			end
			GKP.BgTalk("GKP_Sync_Stop",arg3)
		end
		
		if t[2].text == "GKP_Sync_Start" and t[3].text == me.szName then
			_GKP.bSync = true
			GKP.Alert("同步开始....")
		end
		if t[2].text == "GKP_Sync_Content" and t[3].text == me.szName and _GKP.bSync then
			table.insert(_GKP.tSyncQueue,t[4].text)
			if #_GKP.tSyncQueue % 10 == 0 then
				GKP.Alert("同步数据中请稍等 已读取：" .. #_GKP.tSyncQueue)
			end
		end
		
		if t[2].text == "GKP_Sync_Stop" and t[3].text == me.szName then
			local str = ""
			for i = 1, #_GKP.tSyncQueue do
				str = str .. _GKP.tSyncQueue[i]
			end
			_GKP.tSyncQueue = {}
			_GKP.bSync = false
			GKP.Alert("同步已完成")
			local tData,err = GKP.JsonDecode(GKP.AscIIDecode(str))
			if err then
				return GKP.Sysmsg("数据共享异常，请联系作者反馈，微博ID：萌动小黄鸡。")
			end
			GKP.Confirm("数据同步完毕，你还有最后一次机会确认是否覆盖现有数据？\n拍团数据：" .. #tData.GKP_Record .. "\n交易数据：" .. #tData.GKP_Account,function()
				_GKP.GKP_Record = tData.GKP_Record
				_GKP.GKP_Account = tData.GKP_Account
				pcall(_GKP.Draw_GKP_Record)
				pcall(_GKP.Draw_GKP_Account)
				pcall(_GKP.GKP_Save)
			end)
		end
		
		if (t[2].text == "del" or t[2].text == "edit" or t[2].text == "add") and GKP.Config.bAutoSync and arg3 ~= me.szName then
			local tData,err = GKP.JsonDecode(GKP.AscIIDecode(t[3].text))
			if err then
				return GKP.Sysmsg("数据共享异常，请联系作者反馈，微博ID：萌动小黄鸡。")
			end
			tData.bSync = true
			if t[2].text == "add" then
				pcall(GKP,"GKP_Record",tData)
			else
				for k,v in ipairs(GKP("GKP_Record")) do
					if v.key == tData.key then
						pcall(GKP,"GKP_Record",k,tData)
						break
					end
				end
			end
			pcall(_GKP.Draw_GKP_Record)
			GKP.Debug("Sync Success")
		end
	end
end

RegisterEvent("ON_BG_CHANNEL_MSG",_GKP.OnMsg)

---------------------------------------------------------------------->
-- 恢复记录按钮
----------------------------------------------------------------------<
_GKP.GKP_Recovery = function()
	local me = GetClientPlayer()
	_GKP.szName = _GKP.szName or me.szName
	local menu = {}	
	table.insert(menu,{
		szOption = "读取数据的角色名：" .. _GKP.szName .. "（点击修改）",
		rgb = {255,255,0},
		fnAction = function()
			GetUserInput("修改导入角色名",function(szText)
				_GKP.szName = szText
			end)
		end
	})
	for i = 0 , 19 do
		local nTime = GetCurrentTime() - i * 86400		
		local szPath = _GKP.szPath .. _GKP.szName .. "/" .. FormatTime("%Y-%m-%d",nTime) .. ".gkp"
		table.insert(menu,{
			szOption = FormatTime("%Y-%m-%d",nTime) .. ".gkp",
			bDisable = not IsFileExist(szPath .. ".jx3dat"),
			fnAction = function()
				GKP.Confirm("你确定覆盖当前已有的记录恢复上一次记录的数据吗？",function()
					_GKP.GKP_LoadData(_GKP.szName .. "/" .. FormatTime("%Y-%m-%d",nTime))
					GKP.Alert("记录恢复成功。")
				end)
			end,
		})
	end	
	PopupMenu(menu)
end
---------------------------------------------------------------------->
-- 清空数据
----------------------------------------------------------------------<
_GKP.GKP_Clear = function()
	GKP.Confirm("确定清空所有记录吗？",function()
		_GKP.GKP_Record = {}
		_GKP.GKP_Account = {}
		pcall(_GKP.Draw_GKP_Record)
		pcall(_GKP.Draw_GKP_Account)
		_GKP.nNowMoney = GetClientPlayer().GetMoney().nGold
		_GKP.tDistributeRecords = {}
		GKP.Alert("所有记录成功清空")
	end)
end
---------------------------------------------------------------------->
-- 欠费情况
----------------------------------------------------------------------<
_GKP.GKP_OweList = function()
	local me = GetClientPlayer()
	if not me.IsInParty() and not GKP.Config.bDebug then return GKP.Alert("你不在队伍中。") end
	local tMember = {}
	if IsEmpty(GKP("GKP_Record")) then
		return GKP.Alert("没有记录")
	end
	
	for k,v in ipairs(GKP("GKP_Record")) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				if not tMember[v.szPlayer] then
					tMember[v.szPlayer] = 0
				end
				tMember[v.szPlayer] = tMember[v.szPlayer] + v.nMoney
			end
		end
	end
	for k,v in ipairs(GKP("GKP_Account")) do
		if not v.bDelete and v.szPlayer and v.szPlayer ~= "System" then
			if tMember[v.szPlayer] then
				tMember[v.szPlayer] = tMember[v.szPlayer] - v.nGold
			else
				tMember[v.szPlayer] = v.nGold * -1
			end
		end
	end
	-- 欠账
	local tMember2 = {}
	for k,v in pairs(tMember) do
		if v ~= 0 then
			table.insert(tMember2,{szName = k, nGold = v * -1 })
		end
	end
	table.sort(tMember2,function(a,b) return a.nGold < b.nGold end)
	local nChannel, szTarName = EditBox_GetChannel()
	GKP.Talk("------ 欠债情况 ------",szTarName)
	for k,v in pairs(tMember2) do
		if v.nGold < 0 then
			GKP.Talk({{type = "name" , name = v.szName , text =""},{type = "text" , text = "：" .. v.nGold .. "金。"}},szTarName)
		else
			GKP.Talk({{type = "name" , name = v.szName , text =""},{type = "text" , text = "：+" .. v.nGold .. "金。"}},szTarName)
		end
	end
	local nGold,nGold2 = 0,0
	for _,v in ipairs(GKP("GKP_Account")) do
		if not v.bDelete then
			if v.szPlayer and v.szPlayer ~= "System" then -- 必须要有交易对象
				if tonumber(v.nGold) > 0 then
					nGold = nGold + v.nGold
				else
					nGold2 = nGold2 + v.nGold
				end
			end
		end
	end
	if nGold ~= 0 then
		GKP.Talk("收到：" .. nGold .. "金",szTarName)
	end
	if nGold2 ~= 0 then
		GKP.Talk("支出：" .. nGold2 * -1 .. "金",szTarName)
	end
end
---------------------------------------------------------------------->
-- 获取工资总额
----------------------------------------------------------------------<
_GKP.GetRecordSum = function(bAccurate)
	if IsEmpty(GKP("GKP_Record")) then
		return 0
	end
	local a,b = 0,0
	for k,v in ipairs(GKP("GKP_Record")) do
		if not v.bDelete then
			if tonumber(v.nMoney) > 0 then
				a = a + v.nMoney
			else
				b = b + v.nMoney
			end
		end
	end
	if bAccurate then
		return a + b
	else
		return a,b
	end
end
---------------------------------------------------------------------->
-- 消费情况按钮
----------------------------------------------------------------------<
_GKP.GKP_SpendingList = function()
	local me = GetClientPlayer()
	if not me.IsInParty() and not GKP.Config.bDebug then return GKP.Alert("你不在队伍中。") end
	local tMember = {}
	
	if IsEmpty(GKP("GKP_Record")) then
		return GKP.Alert("没有记录")
	end
	
	for k,v in ipairs(GKP("GKP_Record")) do
		if not v.bDelete then
			if not tMember[v.szPlayer] then
				tMember[v.szPlayer] = 0
			end
			if tonumber(v.nMoney) > 0 then
				tMember[v.szPlayer] = tMember[v.szPlayer] + v.nMoney
			end
		end
	end
	local nChannel, szTarName = EditBox_GetChannel()
	GKP.Talk("------ 消费情况 ------",szTarName)
	local sort = {}
	for k,v in pairs(tMember) do
		if v > 0 then
			table.insert(sort,{szName = k,nGold = v})
		end
	end
	table.sort(sort,function(a,b) return a.nGold < b.nGold end)
	for k,v in ipairs(sort) do
		GKP.Talk({{type = "name" , name = v.szName , text =""},{type = "text" , text = "：" .. v.nGold .. "金。"}},szTarName)
	end
	GKP.Talk("总计拍卖：" .. _GKP.GetRecordSum() .. "金。",szTarName)
end
---------------------------------------------------------------------->
-- 结算工资按钮
----------------------------------------------------------------------<
_GKP.GKP_Calculation = function()
	local me = GetClientPlayer()
	if not me.IsInParty() and not GKP.Config.bDebug then return GKP.Alert("你不在队伍中。") end
	local team = GetClientTeam()
	if IsEmpty(GKP("GKP_Record")) then
		return GKP.Alert("没有记录")
	end
	
	GetUserInput("输入结算的总人数",function(num)
		if not tonumber(num) then return end
		local a,b = _GKP.GetRecordSum()
		-- pcall(_GKP.GKP_SpendingList)
		-- pcall(_GKP.GKP_OweList)
		GKP.Talk("------ 工资结算 ------")
		GKP.Talk(string.format("工资统计：收入 %d金 ＋ 补贴 %d金。",a,b))
		GKP.Talk(string.format("实际工资：%d金。",a+b,a,b))
		if a+b >= 0 then
			GKP.Talk(string.format("结算人数：%d",num))
			GKP.Talk(string.format("实际每人：%d金。",math.floor((a+b)/num)))
		else
			GKP.Talk("记账的人肯定是猪，账是负的发不出钱了！")
		end
	end,nil,nil,nil,team.GetTeamSize())
end
---------------------------------------------------------------------->
-- open doodad (loot)
----------------------------------------------------------------------<
_GKP.OnOpenDoodad = function(dwID)
	local me = GetClientPlayer()
	local d = GetDoodad(dwID)
	local refresh = false
	if d then
		-- money 拾取金钱
		local nM = d.GetLootMoney() or 0
		if nM > 0 then
			LootMoney(d.dwID)
			PlaySound(SOUND.UI_SOUND, g_sound.PickupMoney)
		end
		local nLootItemCount = d.GetItemListCount()
		-- items
		for i = 0, nLootItemCount - 1 do
			-- item Roll Distribute  Bidding
			local item, _ , bDist = d.GetLootItem(i,me)
			if item and item.dwID then
				if bDist or GKP.Config.bDebug then
					if not refresh then
						refresh = true
						_GKP.aDistributeList = {}
					end
					table.insert(_GKP.aDistributeList,item)
				else
					if item.nQuality > 0 then
						LootItem(d.dwID,item.dwID)
						GKP.Debug("LootItem")
					end
				end
			end
		end
	end
	if refresh then
		pcall(_GKP.DrawDistributeList,d)
		GKP.Debug("distribute items " .. #_GKP.aDistributeList)
	else
		_GKP.dwOpenID = nil
		return Station.Lookup("Normal/GKP_Loot"):Hide()
	end
end
-- GKP.Config.bDebug = true
---------------------------------------------------------------------->
-- UpdateDistributeList
----------------------------------------------------------------------<
_GKP.DrawDistributeList = function(doodad)
	local frame = Station.Lookup("Normal/GKP_Loot")
	if #_GKP.aDistributeList == 0 then
		_GKP.dwOpenID = nil
		return frame:Hide()
	end
	frame:Show()
	Wnd.CloseWindow("LootList")
	local handle = frame:Lookup("","Handle_Box")
	if #_GKP.aDistributeList <= 6 then
		frame:Lookup("","Image_Bg"):SetSize(6 * 71,30 + 12 + 75)
		frame:Lookup("","Image_Title"):SetSize(6 * 71,30)
		frame:SetSize(6 * 71,30 + 12 + 75)
	else
		frame:Lookup("","Image_Bg"):SetSize(6 * 71,30 + math.ceil(#_GKP.aDistributeList / 6) * 75)
		frame:Lookup("","Image_Title"):SetSize(6 * 71,30)
		frame:SetSize(6 * 71,8 + 30 + math.ceil(#_GKP.aDistributeList / 6) * 75)
	end
	
	local fx, fy = Station.GetClientSize()
	local w,h = frame:GetSize()
	-- frame:SetAbsPos((fx-w)/2,(fy-h)/2)
	frame:Lookup("Btn_Close"):SetRelPos(w - 30,5)

	local team = GetClientTeam()
	local aPartyMember = doodad.GetLooterList()
	if GKP.Config.bDebug then
		aPartyMember = _GKP.aPartyMember
	end
	if not aPartyMember then
		_GKP.OnOpenDoodad(_GKP.dwOpenID)
		return GKP.Sysmsg("超出系统拾取时间，请尝试重新获取！")
	end

	if not GKP.Config.bDebug then
		for k,v in ipairs(aPartyMember) do
			local player = team.GetMemberInfo(v.dwID)
			aPartyMember[k].dwForceID = player.dwForceID
		end
	end
	
	handle:Clear()
	for item_k,item in ipairs(_GKP.aDistributeList) do
	
		-- append box
		handle:AppendItemFromString(string.format("<Box>name=\"box_%s\" EventID=816 w=64 h=64 </Box>",item_k))
		local box = handle:Lookup("box_" .. item_k)
		box:SetObject(UI_OBJECT_ITEM_ONLY_ID, item.nUiId, item.dwID, item.nVersion, item.dwTabType, item.dwIndex)
		box:SetObjectIcon(Table_GetItemIconID(item.nUiId))
		local szItemName = GetItemNameByItem(item)
		local x,y = (item_k - 1) % 6 , math.ceil(item_k / 6) - 1
		box:SetRelPos(x * 70 + 5, y * 70 + 5)
		if item.bCanStack and item.nStackNum > 1 then
			box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
			box:SetOverTextFontScheme(0,15)
			box:SetOverText(0, item.nStackNum .. " ")
		end
		-- append img
		if _GKP.tQualityImage[item.nQuality] then
			if item.nQuality < 5 then
				handle:AppendItemFromString(GetFormatImage("ui/Image/Common/Box.UITex",_GKP.tQualityImage[item.nQuality],62,62,nil,"img_"..item_k))
			else
				handle:AppendItemFromString("<animate> path=\"ui/Image/Common/Box.UITex\" group=17 w=62 h=62 name=\"img_" ..item_k.."\" </animate>")
			end
			local img = handle:Lookup("img_" .. item_k)
			img:SetRelPos(x * 70 + 6 , y * 70 + 6)
		end
		-- MouseEnter
		box.OnItemMouseEnter = function()
			this:SetObjectMouseOver(true)
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local _,dwID = this:GetObjectData()
			OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, dwID, nil, nil, {x, y, w, h}, nil, "loot")
		end
		box.OnItemMouseLeave = function()
			this:SetObjectMouseOver(false)
			HideTip()
		end
		if _GKP.tDistributeRecords[szItemName] then
			box:SetObjectStaring(true)
		end
		local _item = { -- 分配后 userdata缓存
			nVersion = item.nVersion,
			dwTabType = item.dwTabType,
			dwIndex = item.dwIndex,
			nBookID = item.nBookID,
			nGenre = item.nGenre,
		}
		
		-- Click
		box.OnItemRButtonClick = function()
			_GKP.OnOpenDoodad(_GKP.dwOpenID)
			local tMenu = {}
			table.insert(tMenu,{ szOption = GetItemNameByItem(item) , bDisable = true})
			table.insert(tMenu,{bDevide = true})
			table.insert(tMenu,{ 
				szOption = "Roll点",
				fnAction = function()
					if MY_RollMonitor then
						if MY_RollMonitor.OpenPanel and MY_RollMonitor.Clear then
							MY_RollMonitor.OpenPanel()
							MY_RollMonitor.Clear({echo=false})
						end
					end
					GKP.Talk({GKP.GetFormatLink(_item),{type = "text" ,text =" 要的Roll点。"}})
				end
			})
			table.insert(tMenu,{bDevide = true})
			for k,v in ipairs(_GKP.Config.Scheme) do
				if v[2] then
					table.insert(tMenu,{
						szOption = v[1],
						fnAction = function()
							_GKP.tLootListMoney[item.dwID] = v[1]
							GKP.Talk({GKP.GetFormatLink(_item),{type = "text" ,text = " " .. v[1] .. "金 起拍，要的出价。"}})
						end
					})
				end
				PopupMenu(tMenu)
			end
		end
		
		box.OnItemLButtonClick = function()
			_GKP.OnOpenDoodad(_GKP.dwOpenID)
			if IsCtrlKeyDown() then
				local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
				edit:InsertObj("[" ..GetItemNameByItem(item).. "]",GKP.GetFormatLink(item))
				Station.SetFocusWindow(edit)
				return
			end
			local me = GetClientPlayer()
			local nLootMode = team.nLootMode
			if nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not GKP.Config.bDebug then -- 需要分配者模式
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
			end
			if not GKP.IsDistributer() and not GKP.Config.bDebug then -- 需要自己是分配者
				return OutputMessage("MSG_ANNOUNCE_RED",g_tStrings.ERROR_LOOT_DISTRIBUTE)
			end
			table.sort(aPartyMember,function(a,b)
				return a.dwForceID < b.dwForceID
			end)
			local tMenu = {}
			table.insert(tMenu,{ szOption = szItemName , bDisable = true})
			table.insert(tMenu,{bDevide = true})
			local fnAction = function(v,fnMouseEnter,fix,bEnter)
				local szIcon,nFrame = GetForceImage(v.dwForceID)
				return {
					szOption = fix or v.szName,
					bDisable = not v.bOnlineFlag,
					rgb = {GKP.GetForceCol(v.dwForceID)},
					szIcon = szIcon,
					szLayer = "ICON_RIGHT",
					nFrame = nFrame,
					fnMouseEnter = fnMouseEnter,
					fnAction = function()
						if not item.dwID then
							_GKP.OnOpenDoodad(_GKP.dwOpenID)
							return GKP.Sysmsg("userdata过期，分配失败，清重新尝试。")
						end
						if item.nQuality >= 3 then
							local r,g,b = GKP.GetForceCol(v.dwForceID)
							local msg = {
								szMessage = FormatLinkString(
									g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
									"font=162",
									GetFormatText("[".. GetItemNameByItem(item) .."]", "166"..GetItemFontColorByQuality(item.nQuality, true)),
									GetFormatText("[".. v.szName .."]", 162,r,g,b)
								), 
								szName = "Distribute_Item_Sure", 
								bRichText = true,
								{
									szOption = g_tStrings.STR_HOTKEY_SURE, 
									fnAutoClose = function()
										return false
									end,
									fnAction = function()
										_GKP.DistributeItem(item,v,doodad,bEnter)
									end
								},
								{szOption = g_tStrings.STR_HOTKEY_CANCEL},
							}
							MessageBox(msg)	
						else
							_GKP.DistributeItem(item,v,doodad,bEnter)
						end
					end
				}
			end
			-- 有记忆的情况下 append meun
			if _GKP.tDistributeRecords[szItemName] then
				local p
				for k,v in ipairs(aPartyMember) do
					if v.dwID == _GKP.tDistributeRecords[szItemName] then
						p = v
						break
					end
				end
				if p then  -- 这个人存在团队的情况下
					if IsAltKeyDown() then
						if p.bOnlineFlag then
							_GKP.DistributeItem(item,p,doodad,true)
						else
							GKP.Sysmsg("没有拾取对象。")
						end
						return
					end
					table.insert(tMenu,fnAction(p,function(this)
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local szXml = GetFormatText(string.format("上次你已经把 [%s] 分配给了 [%s] ，下次可以直接在物品图标上按住Alt快速分配给 [%s] ，也可以点击这个菜单分配给TA。\n",szItemName,p.szName,p.szName),136,255,255,255)
						OutputTip(szXml,400,{x,y,w,h})
					end,p.szName .. " - " .. szItemName,true))
					table.insert(tMenu,{bDevide = true})
				end
			end
			-- Create list
			for k,v in ipairs(aPartyMember) do
				table.insert(tMenu,fnAction(v))
			end
			PopupMenu(tMenu)
		end
	end
	handle:FormatAllItemPos()
	
	if _GKP.tDistributeRecords["EquipmentBoss"] then
		frame:Lookup("Btn_Boss"):Show()
		frame:Lookup("Btn_Boss").OnLButtonClick = function()
			local tEquipment = {}
			for k,v in ipairs(_GKP.aDistributeList) do
				if v.nGenre == ITEM_GENRE.EQUIPMENT or IsCtrlKeyDown() then -- 按住Ctrl的情况下 无视分类 否则只给装备	
					table.insert(tEquipment,v)
				end
			end
			if #tEquipment == 0 then
				return GKP.Alert("没有剩余的装备可以分配给散件老板。")
			end
			local p
			for k,v in ipairs(aPartyMember) do
				if v.szName == _GKP.tDistributeRecords["EquipmentBoss"] then
					p = v
					break
				end
			end
			if p then  -- 这个人存在团队的情况下
				local szXml = GetFormatText("你确定要将以下物品\n", 162,255,255,255)
				local r,g,b = GKP.GetForceCol(p.dwForceID)
				for k,v in ipairs(tEquipment) do
					szXml = szXml .. GetFormatText("[".. GetItemNameByItem(v) .."]\n", "166"..GetItemFontColorByQuality(v.nQuality, true))
				end
				szXml = szXml .. GetFormatText("全部分配给 ", 162,255,255,255)
				szXml = szXml .. GetFormatText("[".. p.szName .."]", 162,r,g,b)
				local msg = {
					szMessage = szXml, 
					szName = "Distribute_Item_Sure", 
					bRichText = true,
					{szOption = g_tStrings.STR_HOTKEY_SURE, 
					fnAutoClose = function()
						return false
					end,
					fnAction = function()
						for k,v in ipairs(tEquipment) do
							_GKP.DistributeItem(v,p,doodad,true)
						end
					end},
					{szOption = g_tStrings.STR_HOTKEY_CANCEL},
				}
				MessageBox(msg)	
			end
		end
	else
		frame:Lookup("Btn_Boss"):Hide()
	end
end
---------------------------------------------------------------------->
-- 弹出记账页面后分配
----------------------------------------------------------------------<
_GKP.DistributeItem = function(item,player,doodad,bEnter)
	if not item.dwID then
		_GKP.OnOpenDoodad(_GKP.dwOpenID)
		GKP.Sysmsg("分配失败，停留时间过长userdata失效，请尝试重新分配。")
		return 
	end
	local szName = GetItemNameByItem(item)
	if _GKP.Config.Special[szName] or GKP.Config.bDebug then -- 记住上次分给谁
		_GKP.tDistributeRecords[szName] = player.dwID
		GKP.Debug("memory " .. szName .. " -> " .. player.dwID)
	end
	doodad.DistributeItem(item.dwID,player.dwID)
	_GKP.OnOpenDoodad(_GKP.dwOpenID)
	local tab = {
		szPlayer = player.szName,
		nUiId = item.nUiId,		
		szNpcName = doodad.szName,
		dwDoodadID = doodad.dwID,
		dwTabType = item.dwTabType,
		dwIndex = item.dwIndex,
		nVersion = item.nVersion,
		nTime = GetCurrentTime(),
		nQuality = item.nQuality,
		dwForceID = player.dwForceID,
		szName = szName,
		nGenre = item.nGenre,
	}
	if item.bCanStack and item.nStackNum > 1 then
		tab.nStackNum = item.nStackNum
	end
	if item.nGenre == ITEM_GENRE.BOOK then
		tab["szName"] = GetItemNameByItem(item)
		tab["nBookID"] = item.nBookID
	end
	
	if GKP.Config.bOn then
		_GKP.Record(tab,item,bEnter)
	else -- 关闭的情况所有东西全部绕过
		tab.nMoney = 0
		pcall(GKP,"GKP_Record",tab)
		pcall(_GKP.Draw_GKP_Record)
	end
end
---------------------------------------------------------------------->
-- 记账页面
----------------------------------------------------------------------<
_GKP.Record = function(tab,item,bEnter)
	local record = GUI(Station.Lookup("Normal1/GKP_Record"))
	local box = record:Fetch("Box"):Pos(170,80).self
	local text = record:Fetch("TeamList")
	local Money = record:Fetch("Money")
	local Name = record:Fetch("Name")
	local Source = record:Fetch("Source")
	local auto = 0
	record:Fetch("WndCheckBox"):Check(false)
	if record:IsVisible() and record:Fetch("btn_Close").self.userdata then -- 上次是userdata并且没关闭
		if text:Text() ~= "选择成员" and Name:Text() ~= "" then 
			Money:Text(0)
			record:Fetch("btn_ok"):Click()
		end
	end
	
	if record:Fetch("btn_Close").self.userdata then
		record:Fetch("btn_Close").self.userdata = nil
	end
	if tab and type(item) == "userdata" then
		text:Text(tab.szPlayer):Color(GKP.GetForceCol(tab.dwForceID))
		Name:Text(tab.szName):Enable(false)
		Source:Text(tab.szNpcName):Enable(false)
		if _GKP.tLootListMoney[item.dwID] and GKP.Config.bAutoSetMoney then
			auto = _GKP.tLootListMoney[item.dwID] -- 自动设置发布时的金钱
		elseif GKP.Config.bAutoBX and tab.szName == "碧玺碎片" and tab.nStackNum and tab.nStackNum >= 1 then
			auto = tab.nStackNum
		else
			Money:Text("")
		end
		record:Fetch("btn_Close").self.userdata = true
	else
		text:Text("选择成员"):Color(255,255,255)
		text.dwForceID = nil
		Source:Text("手动添加"):Enable(false)
		Name:Text(""):Enable(true)
		Money:Text("")
	end	
	if tab and type(item) == "number" then -- 编辑
		text:Text(tab.szPlayer):Color(GKP.GetForceCol(tab.dwForceID))
		Name:Text(tab.szName or Table_GetItemName(tab.nUiId)):Enable(true)
		Source:Text(tab.szNpcName):Enable(true)
		Money:Text(tab.nMoney)
	end
	
	if tab and tab.nVersion and tab.nUiId and tab.dwTabType and tab.dwIndex then
		-- Box
		box:SetObject(UI_OBJECT_ITEM_INFO, tab.nVersion, tab.dwTabType, tab.dwIndex)
		box:SetObjectIcon(Table_GetItemIconID(tab.nUiId))
		box:SetOverTextPosition(0,ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0,15)
		if tab.nStackNum and tab.nStackNum > 1 then
			box:SetOverText(0,tab.nStackNum .. " ")
		else
			box:SetOverText(0,"")
		end
		box.OnItemLButtonClick = function()
			if IsCtrlKeyDown() then
				local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
				edit:InsertObj("[" ..tab.szName.. "]",GKP.GetFormatLink(tab))
				Station.SetFocusWindow(edit)
			end
		end
		-- MouseEnter
		box.OnItemMouseEnter = function()
			this:SetObjectMouseOver(true)
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			local _,dwID = this:GetObjectData()
			if tab.nBookID then
				local dwBookID, dwSubID = GlobelRecipeID2BookID(tab.nBookID)
				OutputBookTipByID(dwBookID, dwSubID,{x, y, w, h})
			else
				local _,dwTabType,dwIndex = this:GetObjectData()
				if dwTabType == 0 and dwIndex == 0 then return end
				OutputItemTip(UI_OBJECT_ITEM_INFO,GLOBAL.CURRENT_ITEM_VERSION,dwTabType,dwIndex,{x, y, w, h})
			end
		end
		
		box.OnItemMouseLeave = function()
			this:SetObjectMouseOver(false)
			HideTip()
		end
		box:Show()
	else
		box:SetObject(UI_OBJECT_ITEM_ONLY_ID)
		box:SetObjectIcon(95)
	end	
	record:Toggle(true)
	if auto == 0 then
		Money:Focus()
	else
		Money:Text(auto) -- OnEditChanged kill
		record:Focus()
	end

	record:Fetch("btn_ok"):Click(function()
		local tab = tab or {
			nUiId = 0,
			dwTabType = 0,
			dwDoodadID = 0,
			nQuality = 1,
			nVersion = 0,
			dwIndex = 0,
			nTime = GetCurrentTime(),
			dwForceID = text.self.dwForceID or 0,
			szName = Name:Text(),
		}	
		local nMoney = tonumber(Money:Text()) or 0
		local szPlayer = text:Text()
		if Name:Text() == "" then
			return GKP.Alert("你要记什么东西总要说一下吧。")
		end
		if szPlayer == "选择成员" then
			return GKP.Alert("选择一个记账的成员把钱记到他头上啊，你真笨！")
		end

		tab.szNpcName = Source:Text()
		tab.nMoney = nMoney
		tab.szPlayer = szPlayer
		tab.key = tab.key or GKP.Random()
		if tab and type(item) == "userdata" then
			if GKP.IsDistributer() then
				GKP.Talk({
					GKP.GetFormatLink(tab),
					{type = "text" ,text = " ".. nMoney .."金"},
					{type = "text" ,text = " 分配给 "},
					{type = "name" ,name = tab.szPlayer,text = "[" .. tab.szPlayer .. "]"},
				})
				GKP.BgTalk("add",GKP.AscIIEncode(GKP.JsonEncode(tab)))
			end
			if _GKP.tLootListMoney[item.dwID] then
				_GKP.tLootListMoney[item.dwID] = nil
			end
		elseif tab and type(item) == "number" then
			tab.szName = Name:Text()
			tab.dwForceID = text.self.dwForceID or tab.dwForceID or 0
			tab.bEdit = true
			if GKP.IsDistributer() then
				GKP.Talk({
					{type = "name" ,name = tab.szPlayer,text = "[" .. tab.szPlayer .. "]"},
					{type = "text" ,text = " " .. tab.szName},
					{type = "text" ,text = " " .. nMoney .."金"},
					{type = "text" ,text = " 对记录做了修改。"},
				})
				GKP.BgTalk("edit",GKP.AscIIEncode(GKP.JsonEncode(tab)))
			end
		else
			if GKP.IsDistributer() then
				GKP.Talk({
					{type = "text" ,text = tab.szName},
					{type = "text" ,text = " ".. nMoney .."金"},
					{type = "text" ,text = " 手动记录到 "},
					{type = "name" ,name = tab.szPlayer,text = "[" .. tab.szPlayer .. "]"},
				})
				GKP.BgTalk("add",GKP.AscIIEncode(GKP.JsonEncode(tab)))
			end
		end
		if record:Fetch("WndCheckBox"):Check() then
			_GKP.tDistributeRecords["EquipmentBoss"] = tab.szPlayer -- 233333 不管了 这个挺好玩的
			_GKP.OnOpenDoodad(_GKP.dwOpenID)
		end
		if tab and type(item) == "number" then
			pcall(GKP,"GKP_Record",item,tab)
		else
			pcall(GKP,"GKP_Record",tab)
		end
		
		pcall(_GKP.Draw_GKP_Record)
		record:Toggle(false)
		FireEvent("GKP_DEL_DISTRIBUTE_ITEM")
	end)
	if bEnter then
		record:Fetch("btn_ok"):Click()
	end
	
end
---------------------------------------------------------------------->
-- OpenDoodad
----------------------------------------------------------------------<
_GKP.OpenDoodad = function(arg0)
	local team = GetClientTeam()
	local me = GetClientPlayer()
	if me and team then
		local nLootMode = team.nLootMode	
		if nLootMode == PARTY_LOOT_MODE.DISTRIBUTE or GKP.Config.bDebug then -- 需要分配者模式
			_GKP.dwOpenID = arg0
			_GKP.OnOpenDoodad(arg0)
		end
	end
end
---------------------------------------------------------------------->
-- OpenDoodad cache
----------------------------------------------------------------------<
_GKP._OpenDoodad = function(arg0)
	local team = GetClientTeam()
	local me = GetClientPlayer()
	local refresh = false
	if me and team then
		local d = GetDoodad(arg0)
		if d then
			local nLootItemCount = d.GetItemListCount()
			-- items
			_GKP.aDoodadCache[arg0] = {}
			_GKP.aDoodadCache[arg0].szName = d.szName
			for i = 0, nLootItemCount - 1 do
				-- item Roll Distribute  Bidding
				local item, _ , bDist = d.GetLootItem(i,me)
				if item and bDist then -- 只操作需要分配的物品
					refresh = true					
					if item.dwID then
						local tab = {
							item = item,
							nUiId = item.nUiId,
							dwTabType = item.dwTabType,
							dwIndex = item.dwIndex,
							nVersion = item.nVersion,
							nQuality = item.nQuality,
							nGenre = item.nGenre,
							szName = GetItemNameByItem(item),
						}
						if item.bCanStack and item.nStackNum > 1 then
							tab.nStackNum = item.nStackNum
						end
						if item.nGenre == ITEM_GENRE.BOOK then
							tab.nBookID = item.nBookID
						end
						_GKP.aDoodadCache[arg0][item.dwID] = tab
					else
						GKP.Debug("not item dwID")
					end
				end
			end
		end
	end
	if not refresh then
		_GKP.aDoodadCache[arg0] = nil
	end
end
---------------------------------------------------------------------->
-- DISTRIBUTE_ITEM
----------------------------------------------------------------------<
RegisterEvent("DISTRIBUTE_ITEM",function() -- DISTRIBUTE_ITEM
	if GKP.IsDistributer() then
		return
	end
	local team = GetClientTeam()
	local me = GetClientPlayer()
	local player = team.GetMemberInfo(arg0)
	for k,v in pairs(_GKP.aDoodadCache) do
		if v[arg1] then
			local item = v[arg1]
			item.szPlayer = player.szName
			item.szNpcName = v.szName
			item.dwDoodadID = k
			item.nTime = GetCurrentTime()
			item.dwForceID = player.dwForceID
			if GKP.Config.bOn2 then
				local tab = clone(item)
				tab.item = nil
				table.insert(_GKP.tDistribute,{tab = tab , item = item.item})
				if me.bFightState then
					GKP.Sysmsg("产生了一条分配记录，战斗中已忽略，脱离后自动弹出。")
				else
					FireEvent("GKP_DISTRIBUTE_ITEM")
				end
			end
			break
		end
	end
	GKP.Debug("DISTRIBUTE_ITEM")
end)

RegisterEvent("FIGHT_HINT", function()
	local me = GetClientPlayer()
	if GKP.Config.bOn and #_GKP.tDistribute > 0 and not me.bFightState then
		FireEvent("GKP_DISTRIBUTE_ITEM")
	end
end)

RegisterEvent("GKP_DEL_DISTRIBUTE_ITEM", function()
	if #_GKP.tDistribute > 0 then
		table.remove(_GKP.tDistribute,1)
		if #_GKP.tDistribute > 0 then
			FireEvent("GKP_DISTRIBUTE_ITEM")
		end
	end
	GKP.Debug("GKP_DEL_DISTRIBUTE_ITEM")
end)

RegisterEvent("GKP_DISTRIBUTE_ITEM", function()
	if _GKP.tDistribute[1] and not Station.Lookup("Normal1/GKP_Record"):IsVisible() then
		local tab = _GKP.tDistribute[1]
		_GKP.Record(tab.tab,tab.item)
	end
	GKP.Debug("GKP_DISTRIBUTE_ITEM")
end)

RegisterEvent("SYNC_LOOT_LIST", function()
	if _GKP.dwOpenID == arg0 and Station.Lookup("Normal/GKP_Loot"):IsVisible() then
		_GKP.OpenDoodad(arg0)
	end
	_GKP._OpenDoodad(arg0)
	GKP.Debug("SYNC_LOOT_LIST " .. arg0)
end)

RegisterEvent("OPEN_DOODAD", function()
	local team = GetClientTeam()
	local me = GetClientPlayer()
	local nLootMode = team.nLootMode	
	if nLootMode == PARTY_LOOT_MODE.DISTRIBUTE or GKP.Config.bDebug then
		_GKP.OpenDoodad(arg0)
		GKP.Debug("OPEN_DOODAD " .. arg0)
	end	
end)

---------------------------------------------------------------------->
-- CALL_LUA_ERROR
----------------------------------------------------------------------<
RegisterEvent("CALL_LUA_ERROR", function() 
	if GKP.Config.bDebug then
		Output(arg0)
	end
end)
---------------------------------------------------------------------->
-- 金钱记录
----------------------------------------------------------------------<
_GKP.TradingTarget = {}

_GKP.MoneyUpdate = function(nGold, nSilver, nCopper)
	if nGold > -20 and nGold < 20  then
		return
	end
	if not _GKP.TradingTarget.szName and not GKP.Config.bMoneySystem then
		return
	end
	pcall(GKP,"GKP_Account",{
		nGold = nGold, -- API给的有问题 …… 只算金
		szPlayer = _GKP.TradingTarget.szName or "System",
		dwForceID = _GKP.TradingTarget.dwForceID,
		nTime = GetCurrentTime(),
		dwMapID = GetClientPlayer().GetMapID()
	})
	pcall(_GKP.Draw_GKP_Account)
	if _GKP.TradingTarget.szName and GKP.Config.bMoneyTalk then
		if nGold > 0 then
			GKP.Talk({
				{type = "text" ,text = "收到来自 "},
				{type = "name" ,name = _GKP.TradingTarget.szName,text = "[" .. _GKP.TradingTarget.szName .. "]"},
				{type = "text" ,text = " 的 " .. nGold .." 金。"},
			})
		else
			GKP.Talk({
				{type = "text" ,text = "支付给 "},
				{type = "name" ,name = _GKP.TradingTarget.szName,text = "[" .. _GKP.TradingTarget.szName .. "]"},
				{type = "text" ,text = " " .. nGold * -1 .." 金。"},
			})
		end
	end
end

_GKP.Draw_GKP_Account = function(key,sort)
	local key = key or _GKP.GKP_Account_Container.key or "szPlayer"
	local sort = sort or _GKP.GKP_Account_Container.sort or "desc"
	local tab = GKP("GKP_Account",key,sort)
	_GKP.GKP_Account_Container.key = key
	_GKP.GKP_Account_Container.sort = sort
	_GKP.GKP_Account_Container:Clear()
	local a,b = 0,0
	local tMoney = GetClientPlayer().GetMoney()
	for k,v in ipairs(tab) do
		local c = _GKP.GKP_Account_Container:AppendContentFromIni("interface/JH/GKP/ui/GKP_Account_Item.ini","WndWindow",i)
		local item = c:Lookup("","")
		if k % 2 == 0 then
			item:Lookup("Image_Line"):Hide()			
		end
		if v.bDelete then
			c:SetAlpha(80)
		end
		c:Lookup("","Handle_Money"):AppendItemFromString(GetGoldText(v.nGold,3))
		if v.nGold  < 0 then
			c:Lookup("","Handle_Money"):Lookup(0):SetFontColor(255,0,0)
		else
			c:Lookup("","Handle_Money"):Lookup(0):SetFontColor(0,255,0)
		end		
		c:Lookup("","Handle_Money"):FormatAllItemPos()		
		item:Lookup("Text_No"):SetText(k)
		if v.szPlayer and v.szPlayer ~= "System" then
			item:Lookup("Image_NameIcon"):FromUITex(GetForceImage(v.dwForceID))
			item:Lookup("Text_Name"):SetText(v.szPlayer)
			item:Lookup("Text_Change"):SetText("玩家交易")
			item:Lookup("Text_Name"):SetFontColor(GKP.GetForceCol(v.dwForceID))
		else
			item:Lookup("Image_NameIcon"):FromUITex("ui/Image/uicommon/commonpanel4.UITex",3)
			item:Lookup("Text_Name"):SetText("系统")
			item:Lookup("Text_Change"):SetText("奖励&其他方式")
		end
		item:Lookup("Text_Map"):SetText(Table_GetMapName(v.dwMapID))
		item:Lookup("Text_Time"):SetText(GKP.GetTimeString(v.nTime))		
		c:Lookup("WndButton_Delete").OnLButtonClick = function()
			GKP("GKP_Account","del",k)
			pcall(_GKP.Draw_GKP_Account)
		end
		
		-- tip
		item:Lookup("Text_Name"):RegisterEvent(786)
		item:Lookup("Text_Name").OnItemLButtonClick = function()
			if IsCtrlKeyDown() then
				local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
				edit:InsertObj("[" .. v.szPlayer .. "]",{ type = "name" , name = v.szPlayer , text = v.szPlayer})
				Station.SetFocusWindow(edit)
				return
			end
		end
		
		item:Lookup("Text_Name").OnItemMouseEnter = function()
			local szIcon,nFrame = GetForceImage(v.dwForceID)
			local r,g,b = GKP.GetForceCol(v.dwForceID)
			local szXml = GetFormatImage(szIcon,nFrame,20,20) .. GetFormatText("  " .. v.szPlayer .. "：\n",136,r,g,b)
			szXml = szXml .. GetFormatText("---------- 统计信息如下 ----------\n\n",136,255,255,255)
			local nNum,nNum1,nNum2 = 0,0,0
			for kk,vv in ipairs(GKP("GKP_Record")) do
				if vv.szPlayer == v.szPlayer and not vv.bDelete then
					if  vv.nMoney > 0 then
						nNum = nNum + vv.nMoney
					else
						nNum1 = nNum1 + vv.nMoney
					end
				end
			end
			local r,g,b = GKP.GetMoneyCol(nNum)
			szXml = szXml .. GetFormatText("总计消费：",136,255,128,0) .. GetFormatText(nNum .."金。\n",136,r,g,b)
			local r,g,b = GKP.GetMoneyCol(nNum1)
			szXml = szXml .. GetFormatText("总计补贴：",136,255,128,0) .. GetFormatText(nNum1 .."金。\n",136,r,g,b)
			
			for kk,vv in ipairs(GKP("GKP_Account")) do
				if vv.szPlayer == v.szPlayer and not vv.bDelete and vv.nGold > 0 then
					nNum2 = nNum2 + vv.nGold
				end
			end
			local r,g,b = GKP.GetMoneyCol(nNum2)
			szXml = szXml .. GetFormatText("总计付款：",136,255,128,0) .. GetFormatText(nNum2 .."金。\n",136,r,g,b)
			local nNum3 = nNum+nNum1-nNum2
			if nNum3 < 0 then
				nNum3 = 0
			end
			local r,g,b = GKP.GetMoneyCol(nNum3)
			szXml = szXml .. GetFormatText("欠债金额：",136,255,128,0) .. GetFormatText(nNum3 .."金。\n",136,r,g,b)
			
			local x, y = item:Lookup("Text_No"):GetAbsPos()
			local w, h = item:Lookup("Text_No"):GetSize()
			OutputTip(szXml,400,{x,y,w,h})
		end
		item:Lookup("Text_Name").OnItemMouseLeave = function()
			HideTip()
		end
		if not v.bDelete then
			if tonumber(v.nGold) > 0 then
				a = a + v.nGold
			else
				b = b + v.nGold
			end
		end
	end
	_GKP.GKP_Account_Container:FormatAllContentPos()
	local txt = Station.Lookup("Normal/GKP/PageSet_Menu/Page_GKP_Account"):Lookup("","Text_GKP_AccountSettlement")
	local text = string.format("统计：收入总额 ＝ %d金（收入：%d金 ＋ 支出：%d金）",a+b,a,b)
	if _GKP.nNowMoney then
		text = string.format("%s 上线时身上有 %d 金。",text,_GKP.nNowMoney)
	end
	txt:SetText(text)
	txt:SetFontColor(255,255,0)
end

RegisterEvent("TRADING_OPEN_NOTIFY",function() -- 交易开始
	_GKP.TradingTarget = GetPlayer(arg0)
end)
RegisterEvent("TRADING_CLOSE",function() -- 交易结束
	_GKP.TradingTarget = {}
end)
RegisterEvent("MONEY_UPDATE",function() --金钱变动
	_GKP.MoneyUpdate(arg0,arg1,arg2)
end)

JH.PlayerAddonMenu({szOption = "GKP金团记录",rgb = {255,255,128} , fnAction = _GKP.OpenPanel})
JH.AddHotKey("JH_GKP","打开/关闭金团记录",_GKP.TogglePanel)

	
RegisterEvent("LOADING_END",function()
	if GKP.IsInDungeon() and GKP.Config.bAlertMessage then
		if not IsEmpty(GKP("GKP_Record")) or not IsEmpty(GKP("GKP_Account")) then
			GKP.Confirm("你刚进入副本地图，是否要清空上次记录？",_GKP.GKP_Clear)
		end
	end
end)

----------------------------------------------------------
-- 重伤提示
----------------------------------------------------------

local DeathWarn = {
	tDamage = {},
	tDeath = {}
}

DeathWarn.GetName = function(tar)
	local szName = tar.szName
	if szName == "" and not IsPlayer(tar.dwID) then
		szName = string.gsub(Table_GetNpcTemplateName(tar.dwTemplateID), "^%s*(.-)%s*$", "%1")
		if szName == "" then
			szName = tar.dwID
		end
	end
	if tar.dwEmployer and tar.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(tar.dwTemplateID) then
		local emp = GetPlayer(tar.dwEmployer)
		if not emp then
			szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
		else
			szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
		end
	end
	return szName
end

function DeathWarn.OnSkillEffectLog(dwCaster, dwTarget, bReact, nEffectType, dwID, dwLevel, bCriticalStrike, nCount, tResult)
	local Caster,target,szSkillName
	if nCount <= 2 then
		return
	end
	if IsPlayer(dwCaster) then
		Caster = GetPlayer(dwCaster)
	else
		Caster = GetNpc(dwCaster)
	end
	if not Caster then
		return
	end
	if IsPlayer(dwTarget) then
		target = GetPlayer(dwTarget)
	else
		target = GetNpc(dwTarget)
	end
	if not target then
		return
	end
	if nEffectType == SKILL_EFFECT_TYPE.SKILL then
		szSkillName = Table_GetSkillName(dwID, dwLevel);
	elseif nEffectType == SKILL_EFFECT_TYPE.BUFF then
		szSkillName = Table_GetBuffName(dwID, dwLevel);
	end
	if not szSkillName then
		return
	end
	local me = GetClientPlayer()
	local team = GetClientTeam()
	if IsPlayer(dwTarget) then
		if team.IsPlayerInTeam(dwTarget) or dwTarget == me.dwID then
			if not DeathWarn.tDamage[dwTarget] then
				DeathWarn.tDamage[dwTarget] = {}
			end
			local szDamage = ""
			local nValue = tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = szDamage..g_tStrings.STR_COMMA
				end	
				szDamage = szDamage..FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_PHYSICS_DAMAGE)
			end
			local nValue = tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = szDamage..g_tStrings.STR_COMMA
				end
				szDamage = szDamage..FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_SOLAR_MAGIC_DAMAGE)
			end
			local nValue = tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = szDamage..g_tStrings.STR_COMMA
				end
				szDamage = szDamage..FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_NEUTRAL_MAGIC_DAMAGE)
			end
			local nValue = tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = szDamage..g_tStrings.STR_COMMA
				end
				szDamage = szDamage..FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_LUNAR_MAGIC_DAMAGE)
			end
			local nValue = tResult[SKILL_RESULT_TYPE.POISON_DAMAGE]
			if nValue and nValue > 0 then
				if szDamage ~= "" then
					szDamage = szDamage..g_tStrings.STR_COMMA
				end
				szDamage = szDamage..FormatString(g_tStrings.SKILL_DAMAGE, nValue, g_tStrings.STR_SKILL_POISON_DAMAGE)
			end
			if szDamage ~= "" then
				table.insert(DeathWarn.tDamage[dwTarget],{
					szCaster = DeathWarn.GetName(Caster),
					szTarget = DeathWarn.GetName(target),
					szSkillName = szSkillName,
					szValue = szDamage,
				})
			end
		end
	end
	if IsPlayer(dwCaster) and (team.IsPlayerInTeam(dwCaster) or dwCaster == me.dwID) then
		if not DeathWarn.tDamage[dwCaster] then
			DeathWarn.tDamage[dwCaster] = {}
		end
		local szDamage = ""
		local nValue = tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE]
		if nValue and nValue > 0 then
			if szDamage ~= "" then
				szDamage = szDamage..g_tStrings.STR_COMMA
			end
			szDamage = szDamage..nValue.."点伤害"
		end
		if szDamage ~= "" then
			table.insert(DeathWarn.tDamage[dwCaster],{
				szCaster = DeathWarn.GetName(target),
				szTarget = DeathWarn.GetName(Caster),
				szSkillName = "反弹("..szSkillName..")",
				szValue = szDamage,
			})
		end
	end
end

DeathWarn.OnCommonHealthLog = function(dwTarget, nDeltaLife)
	local target
	if IsPlayer(dwTarget) then
		target = GetPlayer(dwTarget)
	else
		target = GetNpc(dwTarget)
	end
	if not target then return end
	if nDeltaLife < 0 then
		nDeltaLife = -nDeltaLife
	end
	local me = GetClientPlayer()
	local team = GetClientTeam() 
	if IsPlayer(dwTarget) then
		if team.IsPlayerInTeam(dwTarget) or dwTarget == me.dwID then
			if not DeathWarn.tDamage[dwTarget] then
				DeathWarn.tDamage[dwTarget] = {}
			end
			table.insert(DeathWarn.tDamage[dwTarget],{
				szCaster = "萌动小黄鸡大大",
				szTarget = DeathWarn.GetName(target),
				szSkillName = "未知技能",
				szValue = nDeltaLife.."点伤害",
			})
		end
	end
end

--[[
	arg0:"UI_OME_DEATH_NOTIFY" arg1:dwCharacterID arg2: 为INT_MAX，2147483647 arg3:szKiller  
	arg0:"UI_OME_SKILL_EFFECT_LOG" arg1:dwCaster arg2:dwTarget arg3:bReact arg4:nType  arg5:dwID  arg6:dwLevel  arg7:bCriticalStrike arg8:nResultCount 
	arg0:"UI_OME_COMMON_HEALTH_LOG" arg1:dwCharacterID arg2:nDeltaLife  
]]
DeathWarn.OnDeath = function(dwTarget, szKiller)
	local me = GetClientPlayer()
	local team = GetClientTeam()
	local tRecordList = DeathWarn.tDamage[dwTarget]
	if IsPlayer(dwTarget) and tRecordList then
		if team.IsPlayerInTeam(dwTarget) or dwTarget == me.dwID then
			local tInfo = tRecordList[#tRecordList]
			if tInfo then
				tInfo.time = GetCurrentTime()
			end
			if not DeathWarn.tDeath[dwTarget] then
				DeathWarn.tDeath[dwTarget] = {}
			end
			table.insert(DeathWarn.tDeath[dwTarget],tInfo)
			if #DeathWarn.tDeath[dwTarget] > 15 then
				table.remove(DeathWarn.tDeath[dwTarget],1)
			end
			DeathWarn.tDamage[dwTarget] = nil
			if GKP.Config.bDeathWarn then
				OutputMessage("MSG_SYS","重伤提示：["..tInfo.szTarget.."]被["..tInfo.szCaster.."]的<"..tInfo.szSkillName..">造成了"..tInfo.szValue.."，导致重伤！\n")
			end
		end
	end
end

RegisterEvent("SYS_MSG",function()
	if arg0 == "UI_OME_DEATH_NOTIFY" then -- 死亡记录
		DeathWarn.OnDeath(arg1, arg3)
	elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then -- 技能记录
		DeathWarn.OnSkillEffectLog(arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)
	elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
		DeathWarn.OnCommonHealthLog(arg1,arg2)
	end
end)

local UIProtect = {
	tDamage = DeathWarn.tDamage,
	tDeath = DeathWarn.tDeath,
}
setmetatable(_GKP.DeathWarn, { __index = UIProtect, __metatable = true, __newindex = function() --[[ print("Protect") ]] end } )
