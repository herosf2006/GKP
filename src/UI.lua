---------------------------------------------------------------------
-- ����UI�� By haimanman
---------------------------------------------------------------------

local _L = {}
setmetatable(_L, {
	__index = function(t, k) return k end,
	__call = function(t, k, ...) return string.format(k, ...) end,
})

local _GUI = {}
---------------------------------------------------------------------
-- ���ص� UI �������
---------------------------------------------------------------------

-------------------------------------
-- Base object class
-------------------------------------
_GUI.Base = class()

-- (userdata) Instance:Raw()		-- ��ȡԭʼ����/�������
function _GUI.Base:Raw()
	if self.type == "Label" then
		return self.txt
	end
	return self.wnd or self.edit or self.self
end

-- (void) Instance:Remove()		-- ɾ�����
function _GUI.Base:Remove()
	if self.fnDestroy then
		local wnd = self.wnd or self.self
		self.fnDestroy(wnd)
	end
	local hP = self.self:GetParent()
	if hP.___uis then
		local szName = self.self:GetName()
		hP.___uis[szName] = nil
	end
	if self.type == "WndFrame" then
		Wnd.CloseWindow(self.self)
	elseif string.sub(self.type, 1, 3) == "Wnd" then
		self.self:Destroy()
	else
		hP:RemoveItem(self.self:GetIndex())
	end
end

-- (string) Instance:Name()					-- ȡ������
-- (self) Instance:Name(szName)			-- ��������Ϊ szName ������������֧�ִ��ӵ���
function _GUI.Base:Name(szName)
	if not szName then
		return self.self:GetName()
	end
	self.self:SetName(szName)
	return self
end

-- (self) Instance:Toggle([boolean bShow])			-- ��ʾ/����
function _GUI.Base:Toggle(bShow)
	if bShow == false or (not bShow and self.self:IsVisible()) then
		self.self:Hide()
	else
		self.self:Show()
		if self.type == "WndFrame" then
			self.self:BringToTop()
		end
	end
	return self.self
end
function _GUI.Base:IsVisible()
	return self.self:IsVisible()
end
-- (number, number) Instance:Pos()					-- ȡ��λ������
-- (self) Instance:Pos(number nX, number nY)	-- ����λ������
function _GUI.Base:Pos(nX, nY)
	if not nX then
		return self.self:GetRelPos()
	end
	self.self:SetRelPos(nX, nY)
	if self.type == "WndFrame" then
		self.self:CorrectPos()
	elseif string.sub(self.type, 1, 3) ~= "Wnd" then
		self.self:GetParent():FormatAllItemPos()
	end
	return self
end

-- (number, number) Instance:Pos_()			-- ȡ�����½ǵ�����
function _GUI.Base:Pos_()
	local nX, nY = self:Pos()
	local nW, nH = self:Size()
	return nX + nW, nY + nH
end

-- (number, number) Instance:CPos_()			-- ȡ�����һ����Ԫ�����½�����
-- �ر�ע�⣺����ͨ�� :Append() ׷�ӵ�Ԫ����Ч���Ա����ڶ�̬��λ
function _GUI.Base:CPos_()
	local hP = self.wnd or self.self
	if not hP.___last and string.sub(hP:GetType(), 1, 3) == "Wnd" then
		hP = hP:Lookup("", "")
	end
	if hP.___last then
		local ui = GUI.Fetch(hP, hP.___last)
		if ui then
			return ui:Pos_()
		end
	end
	return 0, 0
end

-- (class) Instance:Append(string szType, ...)	-- ��� UI �����
-- NOTICE��only for Handle��WndXXX
function _GUI.Base:Append(szType, ...)
	local hP = self.wnd or self.self
	if string.sub(hP:GetType(), 1, 3) == "Wnd" and string.sub(szType, 1, 3) ~= "Wnd" then
		hP.___last = nil
		hP = hP:Lookup("", "")
	end
	return GUI.Append(hP, szType, ...)
end

-- (class) Instance:Fetch(string szName)	-- �������ƻ�ȡ UI �����
function _GUI.Base:Fetch(szName)
	local hP = self.wnd or self.self
	local ui = GUI.Fetch(hP, szName)
	if not ui and self.handle then
		ui = GUI.Fetch(self.handle, szName)
	end
	return ui
end

-- (number, number) Instance:Align()
-- (self) Instance:Align(number nHAlign, number nVAlign)
function _GUI.Base:Align(nHAlign, nVAlign)
	local txt = self.edit or self.txt
	if txt then
		if not nHAlign and not nVAlign then
			return txt:GetHAlign(), txt:GetVAlign()
		else
			if nHAlign then
				txt:SetHAlign(nHAlign)
			end
			if nVAlign then
				txt:SetVAlign(nVAlign)
			end
		end
	end
	return self
end

-- (number) Instance:Font()
-- (self) Instance:Font(number nFont)
function _GUI.Base:Font(nFont)
	local txt = self.edit or self.txt
	if txt then
		if not nFont then
			return txt:GetFontScheme()
		end
		txt:SetFontScheme(nFont)
	end
	return self
end

-- (number, number, number) Instance:Color()
-- (self) Instance:Color(number nRed, number nGreen, number nBlue)
function _GUI.Base:Color(nRed, nGreen, nBlue)
	if self.type == "Shadow" then
		if not nRed then
			return self.self:GetColorRGB()
		end
		self.self:SetColorRGB(nRed, nGreen, nBlue)
	else
		local txt = self.edit or self.txt
		if txt then
			if not nRed then
				return txt:GetFontColor()
			end
			txt:SetFontColor(nRed, nGreen, nBlue)
		end
	end
	return self
end

-- (number) Instance:Alpha()
-- (self) Instance:Alpha(number nAlpha)
function _GUI.Base:Alpha(nAlpha)
	local txt = self.edit or self.txt or self.self
	if txt then
		if not nAlpha then
			return txt:GetAlpha()
		end
		txt:SetAlpha(nAlpha)
	end
	return self
end

-------------------------------------
-- Dialog frame
-------------------------------------
_GUI.Frm = class(_GUI.Base)

-- constructor
function _GUI.Frm:ctor(szName, bEmpty)
	local frm, szIniFile = nil, "interface\\JH\\GKP\\ui\\WndFrame.ini"
	if bEmpty then
		szIniFile = "interface\\JH\\GKP\\ui\\WndFrameEmpty.ini"
	end
	if type(szName) == "string" then
		frm = Station.Lookup("Normal/" .. szName)
		if frm then
			Wnd.CloseWindow(frm)
		end
		frm = Wnd.OpenWindow(szIniFile, szName)
	else
		frm = Wnd.OpenWindow(szIniFile)
	end
	frm:Show()
	if not bEmpty then
		frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frm:Lookup("Btn_Close").OnLButtonClick = function()
			if frm.bClose then
				Wnd.CloseWindow(frm)
			else
				frm:Hide()
			end
		end
		self.wnd = frm:Lookup("Window_Main")
		self.handle = self.wnd:Lookup("", "")
	else
		self.handle = frm:Lookup("", "")
	end
	self.self, self.type = frm, "WndFrame"
end

-- (number, number) Instance:Size()						-- ȡ�ô����͸�
-- (self) Instance:Size(number nW, number nH)	-- ���ô���Ŀ�͸�
-- �ر�ע�⣺������С�߶�Ϊ 200������Զ����ӽ�ȡ  234/380/770 �е�һ��
function _GUI.Frm:Size(nW, nH)
	local frm = self.self
	if not nW then
		return frm:GetSize()
	end
	local hnd = frm:Lookup("", "")
	-- empty frame
	if not self.wnd then
		frm:SetSize(nW, nH)
		hnd:SetSize(nW, nH)
		return self
	end
	-- fix size
	if nW > 400 then
		nW = 770
		hnd:Lookup("Image_CBg1"):SetSize(385, 70)
		hnd:Lookup("Image_CBg2"):SetSize(384, 70)
		hnd:Lookup("Image_CBg1"):SetFrame(2)
		hnd:Lookup("Image_CBg2"):SetFrame(2)
	elseif nW > 250 then
		nW = 380
		hnd:Lookup("Image_CBg1"):SetSize(190, 70)
		hnd:Lookup("Image_CBg2"):SetSize(189, 70)
		hnd:Lookup("Image_CBg1"):SetFrame(1)
		hnd:Lookup("Image_CBg2"):SetFrame(1)
	else
		nW = 234
		hnd:Lookup("Image_CBg1"):SetSize(117, 70)
		hnd:Lookup("Image_CBg2"):SetSize(117, 70)
		hnd:Lookup("Image_CBg1"):SetFrame(0)
		hnd:Lookup("Image_CBg2"):SetFrame(0)
	end
	if nH < 200 then nH = 200 end
	-- set size
	frm:SetSize(nW, nH)
	frm:SetDragArea(0, 0, nW, 70)
	hnd:SetSize(nW, nH)
	hnd:Lookup("Image_CBg3"):SetSize(8, nH - 160)
	hnd:Lookup("Image_CBg4"):SetSize(nW - 16, nH - 160)
	hnd:Lookup("Image_CBg5"):SetSize(8, nH - 160)
	hnd:Lookup("Image_CBg7"):SetSize(nW - 132, 85)
	hnd:Lookup("Text_Title"):SetSize(nW - 90, 30)
	hnd:FormatAllItemPos()
	frm:Lookup("Btn_Close"):SetRelPos(nW - 35, 15)
	self.wnd:SetSize(nW - 90, nH - 90)
	self.wnd:Lookup("", ""):SetSize(nW - 90, nH - 90)
	-- reset position
	local an = GetFrameAnchor(frm)
	frm:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	return self
end

-- (string) Instance:Title()					-- ȡ�ô������
-- (self) Instance:Title(string szTitle)	-- ���ô������
function _GUI.Frm:Title(szTitle)
	local ttl = self.self:Lookup("", "Text_Title")
	if not szTitle then
		return ttl:GetText()
	end
	ttl:SetText(szTitle)
	return self
end

-- (boolean) Instance:Drag()						-- �жϴ����Ƿ������
-- (self) Instance:Drag(boolean bEnable)	-- ���ô����Ƿ������
function _GUI.Frm:Drag(bEnable)
	local frm = self.self
	if bEnable == nil then
		return frm:IsDragable()
	end
	frm:EnableDrag(bEnable == true)
	return self
end

-- (string) Instance:Relation()
-- (self) Instance:Relation(string szName)	-- Normal/Lowest ...
function _GUI.Frm:Relation(szName)
	local frm = self.self
	if not szName then
		return frm:GetParent():GetName()
	end
	frm:ChangeRelation(szName)
	return self
end

-- (userdata) Instance:Lookup(...)
function _GUI.Frm:Lookup(...)
	local wnd = self.wnd or self.self
	return self.wnd:Lookup(...)
end

-------------------------------------
-- Window Component
-------------------------------------
_GUI.Wnd = class(_GUI.Base)

-- constructor
function _GUI.Wnd:ctor(pFrame, szType, szName)
	local wnd = nil
	if not szType and not szName then
		-- convert from raw object
		wnd, szType = pFrame, pFrame:GetType()
	else
		-- append from ini file
		local szFile = "interface\\JH\\GKP\\ui\\" .. szType .. ".ini"
		local frame = Wnd.OpenWindow(szFile, "GUI_Virtual")
		if not frame then
			return GUI.Sysmsg(_L("Unable to open ini file [%s]", szFile))
		end
		wnd = frame:Lookup(szType)
		if not wnd then
			GUI.Sysmsg(_L("Can not find wnd component [%s]", szType))
		else
			wnd:SetName(szName)
			wnd:ChangeRelation(pFrame, true, true)
		end
		Wnd.CloseWindow(frame)
	end
	if wnd then
		self.type = szType
		self.edit = wnd:Lookup("Edit_Default")
		self.handle = wnd:Lookup("", "")
		self.self = wnd
		if self.handle then
			self.txt = self.handle:Lookup("Text_Default")
		end
		if szType == "WndTrackBar" then
			local scroll = wnd:Lookup("Scroll_Track")
			scroll.nMin, scroll.nMax, scroll.szText = 0, scroll:GetStepCount(), self.txt:GetText()
			scroll.nVal = scroll.nMin
			self.txt:SetText(scroll.nVal .. scroll.szText)
			scroll.OnScrollBarPosChanged = function()
				this.nVal = this.nMin + math.ceil((this:GetScrollPos() / this:GetStepCount()) * (this.nMax - this.nMin))
				if this.OnScrollBarPosChanged_ then
					this.OnScrollBarPosChanged_(this.nVal)
				end
				self.txt:SetText(this.nVal .. this.szText)
			end
		end
	end
end

-- (number, number) Instance:Size()
-- (self) Instance:Size(number nW, number nH)
function _GUI.Wnd:Size(nW, nH)
	local wnd = self.self
	if not nW then
		local nW, nH = wnd:GetSize()
		if self.type == "WndRadioBox" or self.type == "WndCheckBox" or self.type == "WndTrackBar" then
			local xW, _ = self.txt:GetTextExtent()
			nW = nW + xW + 5
		end
		return nW, nH
	end
	if self.edit then
		wnd:SetSize(nW + 2, nH)
		self.handle:SetSize(nW + 2, nH)
		self.handle:Lookup("Image_Default"):SetSize(nW + 2, nH)
		self.edit:SetSize(nW, nH)
	else
		wnd:SetSize(nW, nH)
		if self.handle then
			self.handle:SetSize(nW, nH)
			if self.type == "WndButton" or self.type == "WndTabBox" then
				self.txt:SetSize(nW, nH)
			elseif self.type == "WndComboBox" then
				self.handle:Lookup("Image_ComboBoxBg"):SetSize(nW, nH)
				local btn = wnd:Lookup("Btn_ComboBox")
				local hnd = btn:Lookup("", "")
				local bW, bH = btn:GetSize()
				btn:SetRelPos(nW - bW - 5, math.ceil((nH - bH)/2))
				hnd:SetAbsPos(self.handle:GetAbsPos())
				hnd:SetSize(nW, nH)
				self.txt:SetSize(nW - math.ceil(bW/2), nH)
			elseif self.type == "WndCheckBox" then
				local _, xH = self.txt:GetTextExtent()
				self.txt:SetRelPos(nW - 20, math.floor((nH - xH)/2))
				self.handle:FormatAllItemPos()
			elseif self.type == "WndRadioBox" then
				local _, xH = self.txt:GetTextExtent()
				self.txt:SetRelPos(nW + 5, math.floor((nH - xH)/2))
				self.handle:FormatAllItemPos()
			elseif self.type == "WndTrackBar" then
				wnd:Lookup("Scroll_Track"):SetSize(nW, nH - 13)
				wnd:Lookup("Scroll_Track/Btn_Track"):SetSize(math.ceil(nW/5), nH - 13)
				self.handle:Lookup("Image_BG"):SetSize(nW, nH - 15)
				self.handle:Lookup("Text_Default"):SetRelPos(nW + 5, math.ceil((nH - 25)/2))
				self.handle:FormatAllItemPos()
			end
		end
	end
	return self
end

-- (boolean) Instance:Enable()
-- (self) Instance:Enable(boolean bEnable)
function _GUI.Wnd:Enable(bEnable)
	local wnd = self.edit or self.self
	local txt = self.edit or self.txt
	if bEnable == nil then
		if self.type == "WndButton" then
			return wnd:IsEnabled()
		end
		return self.enable ~= false
	end
	if bEnable then
		wnd:Enable(1)
		if txt and self.font then
			txt:SetFontScheme(self.font)
		end
		self.enable = true
	else
		wnd:Enable(0)
		if txt and self.enable ~= false then
			self.font = txt:GetFontScheme()
			txt:SetFontScheme(161)
		end
		self.enable = false
	end
	return self
end

-- (self) Instance:AutoSize([number hPad[, number vPad]])
function _GUI.Wnd:AutoSize(hPad, vPad)
	local wnd = self.self
	if self.type == "WndTabBox" or self.type == "WndButton" then
		local _, nH = wnd:GetSize()
		local nW, _ = self.txt:GetTextExtent()
		local nEx = self.txt:GetTextPosExtent()
		if hPad then
			nW = nW + hPad + hPad
		end
		if vPad then
			nH = nH + vPad + vPad
		end
		self:Size(nW + nEx + 16, nH)
	elseif self.type == "WndComboBox" then
		local bW, _ = wnd:Lookup("Btn_ComboBox"):GetSize()
		local nW, nH = self.txt:GetTextExtent()
		local nEx = self.txt:GetTextPosExtent()
		if hPad then
			nW = nW + hPad + hPad
		end
		if vPad then
			nH = nH + vPad + vPad
		end
		self:Size(nW + bW + 20, nH + 6)
	end
	return self
end

-- (boolean) Instance:Check()
-- (self) Instance:Check(boolean bCheck)
-- NOTICE��only for WndCheckBox
function _GUI.Wnd:Check(bCheck)
	local wnd = self.self
	if wnd:GetType() == "WndCheckBox" then
		if bCheck == nil then
			return wnd:IsCheckBoxChecked()
		end
		wnd:Check(bCheck == true)
	end
	return self
end

-- (string) Instance:Group()
-- (self) Instance:Group(string szGroup)
-- NOTICE��only for WndCheckBox
function _GUI.Wnd:Group(szGroup)
	local wnd = self.self
	if wnd:GetType() == "WndCheckBox" then
		if not szGroup then
			return wnd.group
		end
		wnd.group = szGroup
	end
	return self
end

-- (string) Instance:Url()
-- (self) Instance:Url(string szUrl)
-- NOTICE��only for WndWebPage
function _GUI.Wnd:Url(szUrl)
	local wnd = self.self
	if self.type == "WndWebPage" then
		if not szUrl then
			return wnd:GetLocationURL()
		end
		wnd:Navigate(szUrl)
	end
	return self
end

-- (number, number, number) Instance:Range()
-- (self) Instance:Range(number nMin, number nMax[, number nStep])
-- NOTICE��only for WndTrackBar
function _GUI.Wnd:Range(nMin, nMax, nStep)
	if self.type == "WndTrackBar" then
		local scroll = self.self:Lookup("Scroll_Track")
		if not nMin and not nMax then
			return scroll.nMin, scroll.nMax, scroll:GetStepCount()
		end
		if nMin then scroll.nMin = nMin end
		if nMax then scroll.nMax = nMax end
		if nStep then scroll:SetStepCount(nStep) end
		self:Value(scroll.nVal)
	end
	return self
end

-- (number) Instance:Value()
-- (self) Instance:Value(number nVal)
-- NOTICE��only for WndTrackBar
function _GUI.Wnd:Value(nVal)
	if self.type == "WndTrackBar" then
		local scroll = self.self:Lookup("Scroll_Track")
		if not nVal then
			return scroll.nVal
		end
		scroll.nVal = math.min(math.max(nVal, scroll.nMin), scroll.nMax)
		scroll:SetScrollPos(math.ceil((scroll.nVal - scroll.nMin) / (scroll.nMax - scroll.nMin) * scroll:GetStepCount()))
		self.txt:SetText(scroll.nVal .. scroll.szText)
	end
	return self
end

-- (string) Instance:Text()
-- (self) Instance:Text(string szText[, boolean bDummy])
-- bDummy		-- ��Ϊ true ������������ onChange �¼�
function _GUI.Wnd:Text(szText, bDummy)
	local txt = self.edit or self.txt
	if txt then
		if not szText then
			return txt:GetText()
		end
		if self.type == "WndTrackBar" then
			local scroll = self.self:Lookup("Scroll_Track")
			scroll.szText = szText
			txt:SetText(scroll.nVal .. scroll.szText)
		elseif self.type == "WndEdit" and bDummy then
			local fnChanged = txt.OnEditChanged
			txt.OnEditChanged = nil
			txt:SetText(szText)
			txt.OnEditChanged = fnChanged
		else
			txt:SetText(szText)
		end
		if self.type == "WndTabBox" then
			self:AutoSize()
		end
	end
	return self
end

-- (boolean) Instance:Multi()
-- (self) Instance:Multi(boolean bEnable)
-- NOTICE: only for WndEdit
function _GUI.Wnd:Multi(bEnable)
	local edit = self.edit
	if edit then
		if bEnable == nil then
			return edit:IsMultiLine()
		end
		edit:SetMultiLine(bEnable == true)
	end
	return self
end

-- (number) Instance:Limit()
-- (self) Instance:Limit(number nLimit)
-- NOTICE: only for WndEdit
function _GUI.Wnd:Limit(nLimit)
	local edit = self.edit
	if edit then
		if not nLimit then
			return edit:GetLimit()
		end
		edit:SetLimit(nLimit)
	end
	return self
end

-- (self) Instance:Change()			-- �����༭���޸Ĵ�����
-- (self) Instance:Change(func fnAction)
-- NOTICE��only for WndEdit��WndTrackBar
function _GUI.Wnd:Change(fnAction)
	if self.type == "WndTrackBar" then
		self.self:Lookup("Scroll_Track").OnScrollBarPosChanged_ = fnAction
	elseif self.edit then
		local edit = self.edit
		if not fnAction then
			if edit.OnEditChanged then
				local _this = this
				this = edit
				edit.OnEditChanged()
				this = _this
			end
		else
			edit.OnEditChanged = function()
				if not this.bChanging then
					this.bChanging = true
					fnAction(this:GetText())
					this.bChanging = false
				end
			end
		end
	end
	return self
end

-- (self) Instance:Focus()
-- (self) Instance:Focus(func fnAction)
-- NOTICE��only for WndEdit
function _GUI.Wnd:Focus(SetfnAction,KillfnAction)
	if type(SetfnAction) == "function" then
		local wnd = self.edit
		if SetfnAction then
			wnd.OnSetFocus = SetfnAction
		end
		if KillfnAction then
			wnd.OnKillFocus = KillfnAction
		end
	else
		Station.SetFocusWindow(self.edit)
	end
	return self
end


-- (self) Instance:Menu(table menu)		-- ���������˵�
-- NOTICE��only for WndComboBox
function _GUI.Wnd:Menu(menu)
	if self.type == "WndComboBox" then
		local wnd = self.self
		self:Click(function()
			local _menu = nil
			local nX, nY = wnd:GetAbsPos()
			local nW, nH = wnd:GetSize()
			if type(menu) == "function" then
				_menu = menu()
			else
				_menu = menu
			end
			_menu.nMiniWidth = nW
			_menu.x = nX
			_menu.y = nY + nH
			PopupMenu(_menu)
		end)
	end
	return self
end

-- (self) Instance:Click()
-- (self) Instance:Click(func fnAction)	-- �����������󴥷�ִ�еĺ���
-- fnAction = function([bCheck])			-- ���� WndCheckBox �ᴫ�� bCheck �����Ƿ�ѡ
function _GUI.Wnd:Click(fnAction)
	local wnd = self.self
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	end
	if wnd:GetType() == "WndCheckBox" then
		if not fnAction then
			self:Check(not self:Check())
		else
			wnd.OnCheckBoxCheck = function()
				if wnd.group then
					local uis = this:GetParent().___uis or {}
					for _, ui in pairs(uis) do
						if ui:Group() == this.group and ui:Name() ~= this:GetName() then
							ui:Check(false)
						end
					end
				end
				fnAction(true)
			end
			wnd.OnCheckBoxUncheck = function() fnAction(false) end
		end
	else
		if not fnAction then
			if wnd.OnLButtonClick then
				local _this = this
				this = wnd
				wnd.OnLButtonClick()
				this = _this
			end
		else
			wnd.OnLButtonClick = fnAction
		end
	end
	return self
end

-- (self) Instance:Hover(func fnEnter[, func fnLeave])	-- ����������������
-- fnEnter = function(true)		-- ������ʱ����
-- fnLeave = function(false)		-- ����Ƴ�ʱ���ã���ʡ����ͽ��뺯��һ��
function _GUI.Wnd:Hover(fnEnter, fnLeave)
	local wnd = wnd
	if self.type == "WndComboBox" then
		wnd = wnd:Lookup("Btn_ComboBox")
	end
	if wnd then
		fnLeave = fnLeave or fnEnter
		if fnEnter then
			wnd.OnMouseEnter = function() fnEnter(true) end
		end
		if fnLeave then
			wnd.OnMouseLeave = function() fnLeave(false) end
		end
	end
	return self
end

-------------------------------------
-- Handle Item
-------------------------------------
_GUI.Item = class(_GUI.Base)

-- xml string
_GUI.tItemXML = {
	["Text"] = "<text>w=150 h=30 valign=1 font=162 eventid=257 </text>",
	["Image"] = "<image>w=100 h=100 eventid=257 </image>",
	["Box"] = "<box>w=48 h=48 eventid=525311 </text>",
	["Shadow"] = "<shadow>w=15 h=15 eventid=277 </shadow>",
	["Handle"] = "<handle>w=10 h=10</handle>",
	["Label"] = "<handle>w=150 h=30 eventid=257 <text>name=\"Text_Label\" w=150 h=30 font=162 valign=1 </text></handle>",
}

-- construct
function _GUI.Item:ctor(pHandle, szType, szName)
	local hnd = nil
	if not szType and not szName then
		-- convert from raw object
		hnd, szType = pHandle, pHandle:GetType()
	else
		local szXml = _GUI.tItemXML[szType]
		if szXml then
			-- append from xml
			local nCount = pHandle:GetItemCount()
			pHandle:AppendItemFromString(szXml)
			hnd = pHandle:Lookup(nCount)
			if hnd then hnd:SetName(szName) end
		else
			-- append from ini
			hnd = pHandle:AppendItemFromIni("interface\\JH\\GKP\\ui\\HandleItems.ini","Handle_" .. szType, szName)
		end
		if not hnd then
			return GUI.Sysmsg(_L("Unable to append handle item [%s]", szType))
		end
	end
	if szType == "BoxButton" then
		self.txt = hnd:Lookup("Text_BoxButton")
		self.img = hnd:Lookup("Image_BoxIco")
		hnd.OnItemMouseEnter = function()
			if not this.bSelected then
				this:Lookup("Image_BoxBg"):Hide()
				this:Lookup("Image_BoxBgOver"):Show()
			end
		end
		hnd.OnItemMouseLeave = function()
			if not this.bSelected then
				this:Lookup("Image_BoxBg"):Show()
				this:Lookup("Image_BoxBgOver"):Hide()
			end
		end
	elseif szType == "TxtButton" then
		self.txt = hnd:Lookup("Text_TxtButton")
		self.img = hnd:Lookup("Image_TxtBg")
		hnd.OnItemMouseEnter = function()
			self.img:Show()
		end
		hnd.OnItemMouseLeave = function()
			if not this.bSelected then
				self.img:Hide()
			end
		end
	elseif szType == "Label" then
		self.txt = hnd:Lookup("Text_Label")
	elseif szType == "Text" then
		self.txt = hnd
	elseif szType == "Image" then
		self.img = hnd
	end
	self.self, self.type = hnd, szType
	hnd:SetRelPos(0, 0)
	hnd:GetParent():FormatAllItemPos()
end

-- (number, number) Instance:Size()
-- (self) Instance:Size(number nW, number nH)
function _GUI.Item:Size(nW, nH)
	local hnd = self.self
	if not nW then
		local nW, nH = hnd:GetSize()
		if self.type == "Text" or self.type == "Label" then
			nW, nH = self.txt:GetTextExtent()
		end
		return nW, nH
	end
	hnd:SetSize(nW, nH)
	if self.type == "BoxButton" then
		local nPad = math.ceil(nH * 0.2)
		hnd:Lookup("Image_BoxBg"):SetSize(nW - 12, nH + 8)
		hnd:Lookup("Image_BoxBgOver"):SetSize(nW - 12, nH + 8)
		hnd:Lookup("Image_BoxBgSel"):SetSize(nW - 1, nH + 11)
		self.img:SetSize(nH - nPad, nH - nPad)
		self.img:SetRelPos(10, math.ceil(nPad / 2))
		self.txt:SetSize(nW - nH - nPad, nH)
		self.txt:SetRelPos(nH + 10, 0)
		hnd:FormatAllItemPos()
	elseif self.type == "TxtButton" then
		self.img:SetSize(nW, nH - 5)
		self.txt:SetSize(nW - 10, nH - 5)
	elseif self.type == "Label" then
		self.txt:SetSize(nW, nH)
	end
	return self
end

-- (self) Instance:Zoom(boolean bEnable)	-- �Ƿ����õ����Ŵ�
-- NOTICE��only for BoxButton
function _GUI.Item:Zoom(bEnable)
	local hnd = self.self
	if self.type == "BoxButton" then
		local bg = hnd:Lookup("Image_BoxBg")
		local sel = hnd:Lookup("Image_BoxBgSel")
		if bEnable == true then
			local nW, nH = bg:GetSize()
			sel:SetSize(nW + 11, nH + 3)
			sel:SetRelPos(1, -5)
		else
			sel:SetSize(bg:GetSize())
			sel:SetRelPos(5, -2)
		end
		hnd:FormatAllItemPos()
	end
	return self
end

-- (self) Instance:Select()		-- ����ѡ�е�ǰ��Ŧ��������Ч����
-- NOTICE��only for BoxButton��TxtButton
function _GUI.Item:Select()
	local hnd = self.self
	if self.type == "BoxButton" or self.type == "TxtButton" then
		local hParent, nIndex = hnd:GetParent(), hnd:GetIndex()
		local nCount = hParent:GetItemCount() - 1
		for i = 0, nCount do
			local item = GUI.Fetch(hParent:Lookup(i))
			if item and item.type == self.type then
				if i == nIndex then
					if not item.self.bSelected then
						hnd.bSelected = true
						hnd.nIndex = i
						if self.type == "BoxButton" then
							hnd:Lookup("Image_BoxBg"):Hide()
							hnd:Lookup("Image_BoxBgOver"):Hide()
							hnd:Lookup("Image_BoxBgSel"):Show()
							self.txt:SetFontScheme(65)
							local icon = hnd:Lookup("Image_BoxIco")
							local nW, nH = icon:GetSize()
							local nX, nY = icon:GetRelPos()
							icon:SetSize(nW + 8, nH + 8)
							icon:SetRelPos(nX - 3, nY - 5)
							hnd:FormatAllItemPos()
						else
							self.img:Show()
						end
					end
				elseif item.self.bSelected then
					item.self.bSelected = false
					if item.type == "BoxButton" then
						item.self:SetIndex(item.self.nIndex)
						if hnd.nIndex >= item.self.nIndex then
							hnd.nIndex = hnd.nIndex + 1
						end
						item.self:Lookup("Image_BoxBg"):Show()
						item.self:Lookup("Image_BoxBgOver"):Hide()
						item.self:Lookup("Image_BoxBgSel"):Hide()
						item.txt:SetFontScheme(163)
						local icon = item.self:Lookup("Image_BoxIco")
						local nW, nH = icon:GetSize()
						local nX, nY = icon:GetRelPos()
						icon:SetSize(nW - 8, nH - 8)
						icon:SetRelPos(nX + 3, nY + 5)
						item.self:FormatAllItemPos()
					else
						item.img:Hide()
					end
				end
			end
		end
		if hnd.nIndex then
			hnd:SetIndex(nCount)
		end
	end
	return self
end

-- (string) Instance:Text()
-- (self) Instance:Text(string szText)
function _GUI.Item:Text(szText)
	local txt = self.txt
	if txt then
		if not szText then
			return txt:GetText()
		end
		txt:SetText(szText)
	end
	return self
end

-- (boolean) Instance:Multi()
-- (self) Instance:Multi(boolean bEnable)
-- NOTICE: only for Text��Label
function _GUI.Item:Multi(bEnable)
	local txt = self.txt
	if txt then
		if bEnable == nil then
			return txt:IsMultiLine()
		end
		txt:SetMultiLine(bEnable == true)
	end
	return self
end

-- (self) Instance:File(string szUitexFile, number nFrame)
-- (self) Instance:File(string szTextureFile)
-- (self) Instance:File(number dwIcon)
-- NOTICE��only for Image��BoxButton
function _GUI.Item:File(szFile, nFrame)
	local img = nil
	if self.type == "Image" then
		img = self.self
	elseif self.type == "BoxButton" then
		img = self.img
	end
	if img then
		if type(szFile) == "number" then
			img:FromIconID(szFile)
		elseif not nFrame then
			img:FromTextureFile(szFile)
		else
			img:FromUITex(szFile, nFrame)
		end
	end
	return self
end

-- (self) Instance:Type()
-- (self) Instance:Type(number nType)		-- �޸�ͼƬ���ͻ� BoxButton �ı�������
-- NOTICE��only for Image��BoxButton
function _GUI.Item:Type(nType)
	local hnd = self.self
	if self.type == "Image" then
		if not nType then
			return hnd:GetImageType()
		end
		hnd:SetImageType(nType)
	elseif self.type == "BoxButton" then
		if nType == nil then
			local nFrame = hnd:Lookup("Image_BoxBg"):GetFrame()
			if nFrame == 16 then
				return 2
			elseif nFrame == 18 then
				return 1
			end
			return 0
		elseif nType == 0 then
			hnd:Lookup("Image_BoxBg"):SetFrame(1)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(2)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(3)
		elseif nType == 1 then
			hnd:Lookup("Image_BoxBg"):SetFrame(18)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(19)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(22)
		elseif nType == 2 then
			hnd:Lookup("Image_BoxBg"):SetFrame(16)
			hnd:Lookup("Image_BoxBgOver"):SetFrame(17)
			hnd:Lookup("Image_BoxBgSel"):SetFrame(15)
		end
	end
	return self
end

-- (self) Instance:Icon(number dwIcon)
-- NOTICE��only for Box��Image��BoxButton
function _GUI.Item:Icon(dwIcon)
	if self.type == "BoxButton" or self.type == "Image" then
		self.img:FromIconID(dwIcon)
	elseif self.type == "Box" then
		self.self:SetObjectIcon(dwIcon)
	end
	return self
end

-- (self) Instance:Click()
-- (self) Instance:Click(func fnAction[, boolean bSound[, boolean bSelect]])	-- �Ǽ������������
-- (self) Instance:Click(func fnAction[, table tLinkColor[, tHoverColor]])		-- ͬ�ϣ�ֻ���ı�
function _GUI.Item:Click(fnAction, bSound, bSelect)
	local hnd = self.self
	--hnd:RegisterEvent(0x001)
	if not fnAction then
		if hnd.OnItemLButtonDown then
			local _this = this
			this = hnd
			hnd.OnItemLButtonDown()
			_this = this
		end
	elseif self.type == "BoxButton" or self.type == "TxtButton" then
		hnd.OnItemLButtonDown = function()
			if bSound then PlaySound(SOUND.UI_SOUND, g_sound.Button) end
			if bSelect then self:Select() end
			fnAction()
		end
	else
		hnd.OnItemLButtonDown = fnAction
		-- text link��tLinkColor��tHoverColor
		local txt = self.txt
		if txt then
			local tLinkColor = bSound or { 255, 255, 0 }
			local tHoverColor = bSelect or { 255, 200, 100 }
			txt:SetFontColor(unpack(tLinkColor))
			if tHoverColor then
				self:Hover(function(bIn)
					if bIn then
						txt:SetFontColor(unpack(tHoverColor))
					else
						txt:SetFontColor(unpack(tLinkColor))
					end
				end)
			end
		end
	end
	return self
end

-- (self) Instance:Hover(func fnEnter[, func fnLeave])	-- ����������������
-- fnEnter = function(true)		-- ������ʱ����
-- fnLeave = function(false)		-- ����Ƴ�ʱ���ã���ʡ����ͽ��뺯��һ��
function _GUI.Item:Hover(fnEnter, fnLeave)
	local hnd = self.self
	--hnd:RegisterEvent(0x300)
	fnLeave = fnLeave or fnEnter
	if fnEnter then
		hnd.OnItemMouseEnter = function() fnEnter(true) end
	end
	if fnLeave then
		hnd.OnItemMouseLeave = function() fnLeave(false) end
	end
	return self
end

---------------------------------------------------------------------
-- ������ API��GUI.xxx
---------------------------------------------------------------------
GUI = {}
GUI.Sysmsg = function(szMsg)
	OutputMessage("MSG_SYS", "[GUI] " .. szMsg .. "\n")
end
-- ����Ԫ���������Ե����������ã���Ч���൱�� GUI.Fetch
setmetatable(GUI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

-- ����һ���յĶԻ�������棬������ GUI ��װ����
-- (class) GUI.CreateFrame([string szName, ]table tArg)
-- szName		-- *��ѡ* ���ƣ���ʡ�����Զ������
-- tArg {			-- *��ѡ* ��ʼ�����ò������Զ�������Ӧ�ķ�װ�������������Ծ���ѡ
--		w, h,			-- ��͸ߣ��ɶԳ�������ָ����С��ע���Ȼ��Զ����ͽ�����Ϊ��770/380/234���߶���С 200
--		x, y,			-- λ�����꣬Ĭ������Ļ���м�
--		title			-- �������
--		drag			-- ���ô����Ƿ���϶�
--		close		-- ����رհ�Ŧ���Ƿ������رմ��壨��Ϊ false �������أ�
--		empty		-- �����մ��壬����������ȫ͸����ֻ�ǽ�������
--		fnCreate = function(frame)		-- �򿪴����ĳ�ʼ��������frame Ϊ���ݴ��壬�ڴ���� UI
--		fnDestroy = function(frame)	-- �ر����ٴ���ʱ���ã�frame Ϊ���ݴ��壬���ڴ��������
-- }
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ����
GUI.CreateFrame = function(szName, tArg)
	if type(szName) == "table" then
		szName, tArg = nil, szName
	end
	tArg = tArg or {}
	local ui = _GUI.Frm.new(szName, tArg.empty == true)
	-- apply init setting
	if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
	if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
	if tArg.title then ui:Title(tArg.title) end
	if tArg.drag ~= nil then ui:Drag(tArg.drag) end
	if tArg.close ~= nil then ui.self.bClose = tArg.close end
	if tArg.fnCreate then tArg.fnCreate(ui:Raw()) end
	if tArg.fnDestroy then ui.fnDestroy = tArg.fnDestroy end
	if tArg.parent then ui:Relation(tArg.parent) end
	return ui
end

-- �����մ���
GUI.CreateFrameEmpty = function(szName, szParent)
	return GUI.CreateFrame(szName, { empty  = true, parent = szParent })
end

-- ��ĳһ��������������  INI �����ļ��еĲ��֣������� GUI ��װ����
-- (class) GUI.Append(userdata hParent, string szIniFile, string szTag, string szName)
-- hParent		-- �����������ԭʼ����GUI ������ֱ����  :Append ������
-- szIniFile		-- INI �ļ�·��
-- szTag			-- Ҫ��ӵĶ���Դ�����������ڵĲ��� [XXXX]������ hParent ƥ����� Wnd ���������
-- szName		-- *��ѡ* �������ƣ�����ָ��������ԭ����
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
-- �ر�ע�⣺�������Ҳ֧����Ӵ������
GUI.AppendIni = function(hParent, szFile, szTag, szName)
	local raw = nil
	if hParent:GetType() == "Handle" then
		if not szName then
			szName = "Child_" .. hParent:GetItemCount()
		end
		raw = hParent:AppendItemFromIni(szFile, szTag, szName)
	elseif string.sub(hParent:GetType(), 1, 3) == "Wnd" then
		local frame = Wnd.OpenWindow(szFile, "GUI_Virtual")
		if frame then
			raw = frame:Lookup(szTag)
			if raw and string.sub(raw:GetType(), 1, 3) == "Wnd" then
				raw:ChangeRelation(hParent, true, true)
				if szName then
					raw:SetName(szName)
				end
			else
				raw = nil
			end
			Wnd.CloseWindow(frame)
		end
	end
	if not raw then
		GUI.Sysmsg(_L("Fail to add component [%s@%s]", szTag, szFile))
	else
		return GUI.Fetch(raw)
	end
end

-- ��ĳһ�������������� GUI ��������ط�װ����
-- (class) GUI.Append(userdata hParent, string szType[, string szName], table tArg)
-- hParent		-- �����������ԭʼ����GUI ������ֱ����  :Append ������
-- szType			-- Ҫ��ӵ�������ͣ��磺WndWindow��WndEdit��Handle��Text ������
-- szName		-- *��ѡ* ���ƣ���ʡ�����Զ������
-- tArg {			-- *��ѡ* ��ʼ�����ò������Զ�������Ӧ�ķ�װ�������������Ծ���ѡ�����û�������
--		w, h,			-- ��͸ߣ��ɶԳ�������ָ����С
--		x, y,			-- λ������
--		txt, font, multi, limit, align		-- �ı����ݣ����壬�Ƿ���У��������ƣ����뷽ʽ��0����1���У�2���ң�
--		color, alpha			-- ��ɫ����͸����
--		checked				-- �Ƿ�ѡ��CheckBox ר��
--		enable					-- �Ƿ�����
--		file, icon, type		-- ͼƬ�ļ���ַ��ͼ���ţ�����
--		group					-- ��ѡ���������
-- }
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
-- �ر�ע�⣺Ϊͳһ�ӿڴ˺���Ҳ������ AppendIni �ļ��������� GUI.AppendIni һ��
-- (class) GUI.Append(userdata hParent, string szIniFile, string szTag, string szName)
GUI.Append = function(hParent, szType, szName, tArg)
	-- compatiable with AppendIni
	if StringFindW(szType, ".ini") ~= nil then
		return GUI.AppendIni(hParent, szType, szName, tArg)
	end
	-- reset parameters
	if not tArg and type(szName) == "table" then
		szName, tArg = nil, szName
	end
	if not szName then
		if not hParent.nAutoIndex then
			hParent.nAutoIndex = 1
		end
		szName = szType .. "_" .. hParent.nAutoIndex
		hParent.nAutoIndex = hParent.nAutoIndex + 1
	else
		szName = tostring(szName)
	end
	-- create ui
	local ui = nil
	if string.sub(szType, 1, 3) == "Wnd" then
		if string.sub(hParent:GetType(), 1, 3) ~= "Wnd" then
			return GUI.Sysmsg(_L["The 1st arg for adding component must be a [WndXxx]"])
		end
		ui = _GUI.Wnd.new(hParent, szType, szName)
	else
		if hParent:GetType() ~= "Handle" then
			return GUI.Sysmsg(_L["The 1st arg for adding item must be a [Handle]"])
		end
		ui = _GUI.Item.new(hParent, szType, szName)
	end
	local raw = ui:Raw()
	if raw then
		-- for reverse fetching
		hParent.___uis = hParent.___uis or {}
		for k, v in pairs(hParent.___uis) do
			if not v.self.___id then
				hParent.___uis[k] = nil
			end
		end
		hParent.___uis[szName] = ui
		hParent.___last = szName
		-- apply init setting
		tArg = tArg or {}
		if tArg.w and tArg.h then ui:Size(tArg.w, tArg.h) end
		if tArg.x and tArg.y then ui:Pos(tArg.x, tArg.y) end
		if tArg.font then ui:Font(tArg.font) end
		if tArg.multi ~= nil then ui:Multi(tArg.multi) end
		if tArg.limit then ui:Limit(tArg.limit) end
		if tArg.color then ui:Color(unpack(tArg.color)) end
		if tArg.align ~= nil then ui:Align(tArg.align) end
		if tArg.alpha then ui:Alpha(tArg.alpha) end
		if tArg.txt then ui:Text(tArg.txt) end
		if tArg.checked ~= nil then ui:Check(tArg.checked) end
		-- wnd only
		if tArg.enable ~= nil then ui:Enable(tArg.enable) end
		if tArg.group then ui:Group(tArg.group) end
		if ui.type == "WndComboBox" and (not tArg.w or not tArg.h) then
			ui:Size(185, 25)
		end
		-- item only
		if tArg.file then ui:File(tArg.file, tArg.num) end
		if tArg.icon ~= nil then ui:Icon(tArg.icon) end
		if tArg.type then ui:Type(tArg.type) end
		return ui
	end
end

-- (class) GUI(...)
-- (class) GUI.Fetch(hRaw)						-- �� hRaw ԭʼ����ת��Ϊ GUI ��װ����
-- (class) GUI.Fetch(hParent, szName)	-- �� hParent ����ȡ��Ϊ szName ����Ԫ����ת��Ϊ GUI ����
-- ����ֵ��ͨ�õ�  GUI ���󣬿�ֱ�ӵ��÷�װ������ʧ�ܻ������ nil
GUI.Fetch = function(hParent, szName)
	if type(hParent) == "string" then
		hParent = Station.Lookup(hParent)
	end
	if not szName then
		szName = hParent:GetName()
		hParent = hParent:GetParent()
	end
	-- exists
	if hParent.___uis and hParent.___uis[szName] then
		local ui = hParent.___uis[szName]
		if ui and ui.self.___id then
			return ui
		end
	end
	-- convert
	local hRaw = hParent:Lookup(szName)
	if hRaw then
		local ui
		if string.sub(hRaw:GetType(), 1, 3) == "Wnd" then
			ui = _GUI.Wnd.new(hRaw)
		else
			ui = _GUI.Item.new(hRaw)
		end
		hParent.___uis = hParent.___uis or {}
		hParent.___uis[szName] = ui
		return ui
	end
end