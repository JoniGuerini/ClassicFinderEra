-- Módulo: UI da aba Guilda (filter bar, header, scroll virtualizado).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.GuildUI = CEF.GuildUI or {}
local GUI = CEF.GuildUI

local FILTER_MENU_ROW_H = 22
local FILTER_GAP = 10
local SEARCH_W, SEARCH_H = 180, 26
local DROP_CLASS_W = 130
local DROP_RANK_W = 140
local DROP_ONLINE_W = 110
local LVL_BOX_W = 40
local RESET_W = 80
local RIGHT_SCROLL_OUTSET = 20
local MENU_MAX = 24

local function st()
  CEF.state = CEF.state or {}
  return CEF.state
end

local function makeMenuChrome(menu)
  local bg = menu:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.048, 0.06, 0.99)
  local br, bgc, bb, ba = 0.55, 0.45, 0.18, 0.85
  local top = menu:CreateTexture(nil, "BORDER")
  top:SetHeight(1)
  top:SetColorTexture(br, bgc, bb, ba)
  top:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, 0)
  local bot = menu:CreateTexture(nil, "BORDER")
  bot:SetHeight(1)
  bot:SetColorTexture(br, bgc, bb, ba)
  bot:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 0, 0)
  bot:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 0, 0)
  local left = menu:CreateTexture(nil, "BORDER")
  left:SetWidth(1)
  left:SetColorTexture(br, bgc, bb, ba)
  left:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 0)
  left:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 0, 0)
  local right = menu:CreateTexture(nil, "BORDER")
  right:SetWidth(1)
  right:SetColorTexture(br, bgc, bb, ba)
  right:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, 0)
  right:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 0, 0)
end

local CTX_W = 168
local CTX_ROW_H = 22
local CTX_HEADER_H = 22
local CTX_PAD = 4
local CTX_MENU_H = CTX_PAD * 2 + CTX_HEADER_H + 1 + CTX_ROW_H * 2

local function isSelfGuildMember(m)
  if not m then
    return false
  end
  local me = UnitName("player")
  if not me then
    return false
  end
  local name = CEF.stripRealm and CEF.stripRealm(m.name or m.nameShort or "") or (m.nameShort or m.name or "")
  return strlower(name) == strlower(me)
end

function GUI.hideMemberContextMenu()
  local f = CEF.UI and CEF.UI.mainFrame
  if f and f.guildMemberContextMenu then
    f.guildMemberContextMenu:Hide()
  end
  if f and f.cefGuildContextOutsideCloser then
    f.cefGuildContextOutsideCloser:Hide()
  end
  if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
    CEF.UIFilters.syncFilterDropBlocker(f)
  end
end

local function ensureGuildContextOutsideCloser(f)
  if f.cefGuildContextOutsideCloser then
    return f.cefGuildContextOutsideCloser
  end
  -- Filho da janela principal: não compete com strata do fullscreen nem cobre o ecrã inteiro.
  local closer = CreateFrame("Button", nil, f)
  closer:Hide()
  closer:SetAllPoints(f)
  closer:SetFrameLevel(500)
  closer:EnableMouse(true)
  closer:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local tex = closer:CreateTexture(nil, "BACKGROUND")
  tex:SetAllPoints()
  tex:SetColorTexture(0, 0, 0, 0.001)
  closer:SetScript("OnClick", function()
    GUI.hideMemberContextMenu()
  end)
  f.cefGuildContextOutsideCloser = closer
  return closer
end

local function ensureMemberContextMenu(f)
  if f.guildMemberContextMenu then
    return f.guildMemberContextMenu
  end
  local menu = CreateFrame("Frame", nil, f)
  menu:SetSize(CTX_W, CTX_MENU_H)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(560)
  menu:EnableMouse(true)
  menu:Hide()
  makeMenuChrome(menu)
  f.guildMemberContextMenu = menu

  local headerBg = menu:CreateTexture(nil, "BACKGROUND")
  headerBg:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1)
  headerBg:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1)
  headerBg:SetHeight(CTX_HEADER_H)
  headerBg:SetColorTexture(0.12, 0.1, 0.08, 1)

  local headerFs = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  headerFs:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -1)
  headerFs:SetPoint("BOTTOMRIGHT", menu, "TOPRIGHT", -10, -1 - CTX_HEADER_H)
  headerFs:SetJustifyH("LEFT")
  headerFs:SetJustifyV("MIDDLE")
  headerFs:SetText("")
  menu.headerFs = headerFs

  local sep = menu:CreateTexture(nil, "ARTWORK")
  sep:SetHeight(1)
  sep:SetColorTexture(0.55, 0.45, 0.18, 0.7)
  sep:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1 - CTX_HEADER_H)
  sep:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1 - CTX_HEADER_H)

  local function makeCtxRow(label, y)
    local row = CreateFrame("Button", nil, menu)
    row:SetHeight(CTX_ROW_H)
    row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, y)
    row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, y)
    row:RegisterForClicks("LeftButtonUp")
    row:EnableMouse(true)
    local rb = row:CreateTexture(nil, "BACKGROUND")
    rb:SetAllPoints()
    rb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    row.bg = rb
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", row, "LEFT", 8, 0)
    fs:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    row.label = fs
    row:SetScript("OnEnter", function(self)
      if self.cefDisabled then
        return
      end
      self.bg:SetColorTexture(0.22, 0.18, 0.12, 1)
    end)
    row:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    end)
    return row
  end

  local actionsTop = -1 - CTX_HEADER_H - 1 - CTX_PAD
  local inviteRow = makeCtxRow(CEF.L.CTX_INVITE_TO_GROUP, actionsTop)
  local whisperRow = makeCtxRow(CEF.L.WHISPER, actionsTop - CTX_ROW_H)
  menu.inviteRow = inviteRow
  menu.whisperRow = whisperRow
  menu.refreshLocale = function()
    inviteRow.label:SetText(CEF.L.CTX_INVITE_TO_GROUP)
    whisperRow.label:SetText(CEF.L.WHISPER)
  end

  local function setRowEnabled(row, enabled)
    row.cefDisabled = not enabled
    row:EnableMouse(enabled)
    if enabled then
      row:Enable()
      row.label:SetTextColor(1, 0.92, 0.55)
    else
      row:Disable()
      row.label:SetTextColor(0.45, 0.42, 0.38)
    end
    row.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
  end
  menu.setRowEnabled = setRowEnabled

  inviteRow:SetScript("OnClick", function()
    local m = menu.cefMember
    GUI.hideMemberContextMenu()
    if not m or not m.name or isSelfGuildMember(m) then
      return
    end
    InviteUnit(m.name)
  end)

  whisperRow:SetScript("OnClick", function()
    local m = menu.cefMember
    local name = m and m.name
    -- Fecha menu/closer ANTES de mudar de aba (evita overlay a bloquear cliques).
    GUI.hideMemberContextMenu()
    if not name or name == "" or isSelfGuildMember(m) then
      return
    end
    if CEF.UI and CEF.UI.openWhisperInHub then
      CEF.UI.openWhisperInHub(name)
    end
  end)

  return menu
end

function GUI.showMemberContextMenu(member, anchorFrame)
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not member then
    return
  end
  if CEF.UIFilters and CEF.UIFilters.hideAllFilterDropdowns then
    CEF.UIFilters.hideAllFilterDropdowns(f)
  end
  local menu = ensureMemberContextMenu(f)
  menu.cefMember = member
  local namePrefix = CEF.Guild.classColorPrefix(member.classFile)
  local displayName = member.nameShort or member.name or ""
  if menu.headerFs then
    menu.headerFs:SetText(namePrefix .. displayName .. "|r")
  end
  local selfMember = isSelfGuildMember(member)
  local online = member.online and true or false
  menu.setRowEnabled(menu.inviteRow, online and not selfMember)
  menu.setRowEnabled(menu.whisperRow, not selfMember)

  menu:ClearAllPoints()
  local scale = UIParent:GetEffectiveScale() or 1
  if scale < 0.01 then
    scale = 1
  end
  local cx, cy = GetCursorPosition()
  local x, y = cx / scale, cy / scale
  local mw, mh = menu:GetWidth() or CTX_W, menu:GetHeight() or CTX_MENU_H
  local uiW, uiH = UIParent:GetWidth() or 1024, UIParent:GetHeight() or 768
  if x + mw > uiW then
    x = uiW - mw - 4
  end
  if y - mh < 0 then
    y = mh + 4
  end
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)

  local closer = ensureGuildContextOutsideCloser(f)
  closer:SetFrameLevel(500)
  closer:Show()
  menu:SetFrameLevel(560)
  menu:Show()
  if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
    CEF.UIFilters.syncFilterDropBlocker(f)
  end
end

local function bindGuildRowMouse(rf)
  if rf.cefCtxBound then
    return
  end
  rf.cefCtxBound = true
  rf:EnableMouse(true)
  rf:SetScript("OnEnter", function(self)
    if self.bg then
      self.bg:SetColorTexture(0.14, 0.12, 0.1, 0.95)
    end
  end)
  rf:SetScript("OnLeave", function(self)
    if self.bg then
      local even = self.cefEven
      if even then
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.85)
      else
        self.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      end
    end
  end)
  rf:SetScript("OnMouseUp", function(self, button)
    if button ~= "RightButton" then
      return
    end
    if self.cefMember then
      GUI.showMemberContextMenu(self.cefMember, self)
    end
  end)
end

local function makeDropArrow(btn)
  CEF.UIFilters.attachDropChevron(btn, 16)
end

function GUI.refresh()
  if CEF.Guild then
    CEF.Guild.rebuildFilteredView()
  end
  GUI.layoutRows()
  GUI.applyColumnWidths()
  if CEF.UI and CEF.UI.mainFrame and CEF.UI.mainFrame.cefSyncGuildScroll then
    CEF.UI.mainFrame.cefSyncGuildScroll()
  end
  GUI.updateEmptyState()
end

function GUI.updateEmptyState()
  local ui = CEF.UI or {}
  local empty = ui.guildEmptyLabel
  if not empty then
    return
  end
  if not CEF.Guild.isInGuild() then
    empty:SetText(CEF.L.GUILD_EMPTY_NOT_IN_GUILD)
    empty:Show()
  elseif CEF.Guild.isPendingRefresh() and not CEF.Guild.isRosterReady() then
    empty:SetText(CEF.L.GUILD_EMPTY_UPDATING)
    empty:Show()
  else
    local view = CEF.Guild.getFilteredView()
    if #view == 0 then
      if #(CEF.Guild.getMembers() or {}) == 0 then
        empty:SetText(CEF.L.GUILD_EMPTY_NO_MEMBERS)
      else
        empty:SetText(CEF.L.GUILD_EMPTY_NO_MATCH)
      end
      empty:Show()
    else
      empty:Hide()
    end
  end
  GUI.updateFooter()
end

function GUI.updateFooter()
  local ui = CEF.UI or {}
  local fs = ui.guildFooterLabel
  if not fs then
    return
  end
  if not CEF.Guild.isInGuild() then
    fs:SetText("|cff888888" .. CEF.L.GUILD_FOOTER_NO_GUILD .. "|r")
    return
  end
  local c = CEF.Guild.getRosterCounts()
  if c.shown ~= c.total then
    fs:SetText(CEF.L("GUILD_FOOTER_FILTERED", c.online, c.total, c.shown, c.shownOnline))
  else
    fs:SetText(CEF.L("GUILD_FOOTER_COUNTS", c.online, c.total))
  end
end

function GUI.applyColumnWidths()
  local ui = CEF.UI or {}
  local scrollChild = ui.guildScrollChild
  local rowFrames = ui.guildRowFrames
  local header = ui.guildHeader
  local scroll = ui.guildScrollFrame
  local CC = CEF.CONST
  if not scrollChild or not rowFrames then
    return
  end
  local w = scrollChild:GetWidth() or 0
  if scroll and scroll.GetWidth then
    local sw = scroll:GetWidth() or 0
    if sw > w then
      w = sw
    end
  end
  if w < 32 then
    return
  end
  local showOfficer = CEF.Guild.canViewOfficerNote and CEF.Guild.canViewOfficerNote()
  local widths, xs, colCount = CEF.UILayout.guildColumnWidths(w, showOfficer)
  if header then
    CEF.UILayout.layoutGuildHeaderColumns(header, scroll)
  end
  local iconSize = math.min(18, math.max(14, (CC.ROW_HEIGHT or 22) - 4))
  for _, rf in ipairs(rowFrames) do
    if rf and rf.cols then
      for i = 1, 8 do
        local fs = rf.cols[i]
        if fs then
          if i <= colCount then
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", rf, "LEFT", xs[i], 0)
            fs:SetWidth(math.max(24, widths[i] - CC.COL_GAP))
            fs:SetJustifyH("LEFT")
            fs:SetJustifyV("MIDDLE")
            fs:SetHeight(CC.ROW_HEIGHT)
            fs:Show()
          else
            fs:SetText("")
            fs:Hide()
          end
        end
      end
      if rf.classIcon then
        rf.classIcon:ClearAllPoints()
        rf.classIcon:SetSize(iconSize, iconSize)
        rf.classIcon:SetPoint("LEFT", rf, "LEFT", xs[3] + 2, 0)
      end
      if rf.cols[3] then
        rf.cols[3]:SetText("")
      end
    end
  end
end

function GUI.layoutRows()
  local ui = CEF.UI or {}
  local scrollChild = ui.guildScrollChild
  local scrollFrame = ui.guildScrollFrame
  local rowFrames = ui.guildRowFrames
  local CC = CEF.CONST
  if not scrollChild or not scrollFrame or not rowFrames then
    return
  end

  -- Evita limpar as linhas enquanto o ScrollFrame ainda não tem geometria
  -- (ex.: no mesmo frame do toggle fullscreen / ClearAllPoints).
  local viewH = scrollFrame:GetHeight() or 0
  local childW = scrollChild:GetWidth() or 0
  if viewH < 8 or childW < 32 then
    return
  end

  GUI.hideMemberContextMenu()

  CEF.Guild.rebuildFilteredView()
  local filteredView = CEF.Guild.getFilteredView()
  local n = #filteredView
  local rowH = CC.ROW_HEIGHT
  local totalH = math.max(n * rowH, 1)
  scrollChild:SetHeight(totalH)

  local maxScroll = math.max(0, totalH - viewH)
  local vs = scrollFrame:GetVerticalScroll() or 0
  if vs > maxScroll then
    vs = maxScroll
    scrollFrame:SetVerticalScroll(maxScroll)
  elseif vs < 0 then
    vs = 0
    scrollFrame:SetVerticalScroll(0)
  end

  local first = 1
  if n > 0 and rowH > 0 then
    first = math.floor(vs / rowH) + 1
    if first < 1 then
      first = 1
    end
    if first > n then
      first = n
    end
  end
  local visible = math.ceil(viewH / rowH) + 2
  local last = math.min(n, first + visible - 1)
  if last < first then
    last = first
  end
  if n == 0 then
    first, last = 1, 0
  end

  for _, rf in ipairs(rowFrames) do
    rf:Hide()
  end

  local w = childW
  if scrollFrame and scrollFrame.GetWidth then
    local sw = scrollFrame:GetWidth() or 0
    if sw > w then
      w = sw
    end
  end
  local showOfficer = CEF.Guild.canViewOfficerNote and CEF.Guild.canViewOfficerNote()
  local widths, xs, colCount = CEF.UILayout.guildColumnWidths(w, showOfficer)
  local iconSize = math.min(18, math.max(14, rowH - 4))

  for i = first, last do
    local rowIndex = i - first + 1
    if rowIndex > CC.MAX_ROW_FRAMES_POOL then
      break
    end
    local rf = rowFrames[rowIndex]
    if not rf then
      rf = CreateFrame("Frame", nil, scrollChild)
      rf:SetHeight(rowH)
      local bg = rf:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      rf.bg = bg
      rf.cols = {}
      for c = 1, 8 do
        rf.cols[c] = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      end
      rf.classIcon = rf:CreateTexture(nil, "OVERLAY")
      rf.classIcon:SetSize(iconSize, iconSize)
      local sep = rf:CreateTexture(nil, "ARTWORK")
      sep:SetHeight(1)
      sep:SetColorTexture(0, 0, 0, 0.22)
      sep:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 4, 0)
      sep:SetPoint("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -4, 0)
      rf.rowBotSep = sep
      rowFrames[rowIndex] = rf
    elseif not rf.classIcon then
      rf.classIcon = rf:CreateTexture(nil, "OVERLAY")
      rf.classIcon:SetSize(iconSize, iconSize)
    end
    bindGuildRowMouse(rf)

    local m = filteredView[i]
    rf.cefMember = m
    rf.cefEven = (i % 2) == 0
    if rf.bg then
      if rf.cefEven then
        rf.bg:SetColorTexture(0.1, 0.1, 0.12, 0.85)
      else
        rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      end
    end
    rf:ClearAllPoints()
    rf:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * rowH))
    rf:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -((i - 1) * rowH))
    rf:SetHeight(rowH)
    rf:Show()

    for c = 1, 8 do
      local fs = rf.cols[c]
      if c <= colCount then
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", rf, "LEFT", xs[c], 0)
        fs:SetWidth(math.max(24, widths[c] - CC.COL_GAP))
        fs:SetJustifyH("LEFT")
        fs:SetHeight(rowH)
        fs:Show()
      else
        fs:SetText("")
        fs:Hide()
      end
    end

    local namePrefix = CEF.Guild.classColorPrefix(m.classFile)
    rf.cols[1]:SetText(namePrefix .. (m.nameShort or m.name or "") .. "|r")
    rf.cols[2]:SetText(CEF.Guild.levelColorRichText(m.level))
    rf.cols[3]:SetText("")
    rf.classIcon:ClearAllPoints()
    rf.classIcon:SetSize(iconSize, iconSize)
    rf.classIcon:SetPoint("LEFT", rf, "LEFT", xs[3] + 2, 0)
    CEF.Guild.setClassIconTexture(rf.classIcon, m.classFile)
    rf.cols[4]:SetText(m.rank or "")
    rf.cols[5]:SetText((CEF.getZoneDisplayName and CEF.getZoneDisplayName(m.zone)) or (m.zone or ""))
    if m.online then
      rf.cols[6]:SetText("|cff66ff66" .. CEF.L.STATUS_ONLINE .. "|r")
    else
      rf.cols[6]:SetText("|cff888888" .. CEF.L.STATUS_OFFLINE .. "|r")
    end
    rf.cols[7]:SetText(m.note ~= "" and m.note or "—")
    if showOfficer and rf.cols[8] then
      rf.cols[8]:SetText(m.officerNote ~= "" and m.officerNote or "—")
    end
  end
end

local function buildMultiMenu(f, dropBtn, width, getOpts, getSelected, setSelected, summaryFS, summaryFn, menuKey, frameLevel)
  local menu = CreateFrame("Frame", nil, f)
  menu:SetWidth(width)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(frameLevel or 520)
  menu:EnableMouse(true)
  menu:Hide()
  menu:SetPoint("TOPLEFT", dropBtn, "BOTTOMLEFT", 0, -2)
  makeMenuChrome(menu)
  f[menuKey] = menu

  local mScroll = CreateFrame("ScrollFrame", nil, menu)
  mScroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
  mScroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -4, 4)
  mScroll:EnableMouse(true)
  local mChild = CreateFrame("Frame", nil, mScroll)
  mScroll:SetScrollChild(mChild)
  mChild:EnableMouse(true)
  mScroll:EnableMouseWheel(true)
  mScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, mChild:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * FILTER_MENU_ROW_H * 2
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
  end)

  local rows = {}
  for i = 1, MENU_MAX do
    local row = CreateFrame("Button", nil, mChild)
    row:SetHeight(FILTER_MENU_ROW_H)
    local rb = row:CreateTexture(nil, "BACKGROUND")
    rb:SetAllPoints()
    rb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    row.bg = rb
    row:SetScript("OnEnter", function()
      CEF.UIFilters.applyFilterRowBg(row, true)
    end)
    row:SetScript("OnLeave", function()
      CEF.UIFilters.applyFilterRowBg(row, false)
    end)
    local lab = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lab:SetPoint("LEFT", row, "LEFT", CEF.UIFilters.filterCheckLabelLeft(), 0)
    lab:SetJustifyH("LEFT")
    row.label = lab
    CEF.UIFilters.attachFilterRowCheck(row)
    row:SetScript("OnClick", function(self)
      if self.optionKey == false or self.optionKey == nil then
        setSelected(CEF.filterSetClear())
      else
        setSelected(CEF.filterSetToggle(getSelected(), self.optionKey))
      end
      if summaryFS and summaryFn then
        summaryFS:SetText(summaryFn(getSelected()))
      end
      menu._refresh()
      if CEF.UI.guildScrollFrame then
        CEF.UI.guildScrollFrame:SetVerticalScroll(0)
      end
      GUI.refresh()
    end)
    rows[i] = row
    row:Hide()
  end

  menu._refresh = function()
    menu:SetWidth(dropBtn:GetWidth())
    local mw = menu:GetWidth()
    local labelW = math.max(40, mw - CEF.UIFilters.filterCheckLabelLeft() - 8)
    local opts = getOpts()
    local selected = getSelected()
    local y = 0
    for i = 1, MENU_MAX do
      local row = rows[i]
      if i <= #opts then
        local opt = opts[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", mChild, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", mChild, "TOPRIGHT", 0, -y)
        row.label:SetWidth(labelW)
        row.optionKey = opt.key
        row.label:SetTextColor(1, 1, 1)
        row.label:SetText(opt.label)
        CEF.UIFilters.setFilterRowChecked(row, CEF.filterSetContains(selected, opt.key), true)
        CEF.UIFilters.applyFilterRowBg(row, false)
        row:Show()
        y = y + FILTER_MENU_ROW_H
      else
        row:Hide()
      end
    end
    local nOpts = #opts
    mChild:SetWidth(math.max(1, mw - 8))
    mChild:SetHeight(math.max(FILTER_MENU_ROW_H, nOpts * FILTER_MENU_ROW_H))
    local vis = math.min(10, math.max(1, nOpts))
    menu:SetHeight(8 + vis * FILTER_MENU_ROW_H)
  end

  dropBtn:SetScript("OnClick", function()
    if menu:IsShown() then
      menu:Hide()
      CEF.UIFilters.syncFilterDropBlocker(f)
    else
      CEF.UIFilters.hideAllFilterDropdowns(f)
      menu._refresh()
      menu:Show()
      menu:Raise()
      CEF.UIFilters.syncFilterDropBlocker(f)
    end
  end)

  return menu
end

--- Cria painéis da aba Guilda dentro do mainFrame.
-- @param f main frame
-- @param navBar âncora superior
function GUI.createPanels(f, navBar)
  local CC = CEF.CONST
  CEF.UI = CEF.UI or {}
  CEF.UI.guildRowFrames = CEF.UI.guildRowFrames or {}

  local guildFilterBar = CreateFrame("Frame", nil, f)
  guildFilterBar:SetHeight(SEARCH_H + 14)
  guildFilterBar:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  guildFilterBar:SetPoint("TOPRIGHT", navBar, "BOTTOMRIGHT", 0, -4)
  guildFilterBar:EnableMouse(true)
  guildFilterBar:Hide()
  local gfbBg = guildFilterBar:CreateTexture(nil, "BACKGROUND")
  gfbBg:SetAllPoints()
  gfbBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)

  local searchBorder = CreateFrame("Frame", nil, guildFilterBar)
  searchBorder:SetSize(SEARCH_W, SEARCH_H)
  searchBorder:SetPoint("TOPLEFT", guildFilterBar, "TOPLEFT", 10, -7)
  local sbd = searchBorder:CreateTexture(nil, "BACKGROUND")
  sbd:SetAllPoints()
  sbd:SetColorTexture(0.04, 0.04, 0.05, 1)

  local searchPlaceholder = searchBorder:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  searchPlaceholder:SetPoint("LEFT", searchBorder, "LEFT", 6, 0)
  searchPlaceholder:SetPoint("RIGHT", searchBorder, "RIGHT", -6, 0)
  searchPlaceholder:SetJustifyH("LEFT")
  searchPlaceholder:SetText(CEF.L.SEARCH_PLACEHOLDER_GUILD)

  local searchEdit = CreateFrame("EditBox", nil, searchBorder)
  searchEdit:SetFontObject(GameFontHighlightSmall)
  searchEdit:SetPoint("TOPLEFT", searchBorder, "TOPLEFT", 4, -2)
  searchEdit:SetPoint("BOTTOMRIGHT", searchBorder, "BOTTOMRIGHT", -4, 2)
  searchEdit:SetAutoFocus(false)

  local function updateSearchPlaceholder()
    local tx = searchEdit:GetText() or ""
    if tx == "" and not searchEdit:HasFocus() then
      searchPlaceholder:Show()
    else
      searchPlaceholder:Hide()
    end
  end

  searchEdit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    updateSearchPlaceholder()
  end)
  searchEdit:SetScript("OnEditFocusGained", updateSearchPlaceholder)
  searchEdit:SetScript("OnEditFocusLost", updateSearchPlaceholder)
  searchEdit:SetScript("OnTextChanged", function(self)
    local t = self:GetText() or ""
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    st().filterGuildSearchText = strlower(t)
    if CEF.UI.guildScrollFrame then
      CEF.UI.guildScrollFrame:SetVerticalScroll(0)
    end
    GUI.refresh()
    updateSearchPlaceholder()
  end)
  updateSearchPlaceholder()

  local function makeDrop(parent, w, anchor, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, SEARCH_H)
    btn:SetPoint("TOPLEFT", anchor, "TOPRIGHT", FILTER_GAP, 0)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.11, 0.09, 0.07, 1)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", 8, 0)
    fs:SetPoint("RIGHT", btn, "RIGHT", -22, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    makeDropArrow(btn)
    return btn, fs
  end

  local classBtn, classFS = makeDrop(guildFilterBar, DROP_CLASS_W, searchBorder, CEF.Guild.classFilterOptionRichText(st().filterGuildClassKeys))
  local rankBtn, rankFS = makeDrop(guildFilterBar, DROP_RANK_W, classBtn, CEF.Guild.rankFilterOptionRichText(st().filterGuildRankKeys))
  local onlineBtn, onlineFS = makeDrop(guildFilterBar, DROP_ONLINE_W, rankBtn, CEF.Guild.onlineFilterOptionRichText(st().filterGuildOnlineKey))
  f.cefDropGuildClassBtn = classBtn
  f.cefDropGuildRankBtn = rankBtn
  f.cefDropGuildOnlineBtn = onlineBtn

  buildMultiMenu(f, classBtn, DROP_CLASS_W, function()
    local opts = { { key = false, label = CEF.L.FILTER_ALL_CLASSES } }
    for _, o in ipairs(CEF.GUILD_CLASS_FILTER_OPTS) do
      opts[#opts + 1] = o
    end
    return opts
  end, function()
    return st().filterGuildClassKeys
  end, function(v)
    st().filterGuildClassKeys = v
  end, classFS, CEF.Guild.classFilterOptionRichText, "filterGuildClassMenu", 520)

  buildMultiMenu(f, rankBtn, DROP_RANK_W, function()
    return CEF.Guild.getRankFilterOpts()
  end, function()
    return st().filterGuildRankKeys
  end, function(v)
    st().filterGuildRankKeys = v
  end, rankFS, CEF.Guild.rankFilterOptionRichText, "filterGuildRankMenu", 522)

  -- Online: seleção única
  do
    local menu = CreateFrame("Frame", nil, f)
    menu:SetWidth(DROP_ONLINE_W)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(524)
    menu:EnableMouse(true)
    menu:Hide()
    menu:SetPoint("TOPLEFT", onlineBtn, "BOTTOMLEFT", 0, -2)
    makeMenuChrome(menu)
    f.filterGuildOnlineMenu = menu
    local rows = {}
    for i = 1, #CEF.GUILD_ONLINE_FILTER_OPTS do
      local row = CreateFrame("Button", nil, menu)
      row:SetHeight(FILTER_MENU_ROW_H)
      row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4 - (i - 1) * FILTER_MENU_ROW_H)
      row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, -4 - (i - 1) * FILTER_MENU_ROW_H)
      local rb = row:CreateTexture(nil, "BACKGROUND")
      rb:SetAllPoints()
      rb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
      row.bg = rb
      row:SetScript("OnEnter", function()
        CEF.UIFilters.applyFilterRowBg(row, true)
      end)
      row:SetScript("OnLeave", function()
        CEF.UIFilters.applyFilterRowBg(row, false)
      end)
      local lab = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      lab:SetPoint("LEFT", row, "LEFT", CEF.UIFilters.filterCheckLabelLeft(), 0)
      lab:SetJustifyH("LEFT")
      row.label = lab
      CEF.UIFilters.attachFilterRowCheck(row)
      local opt = CEF.GUILD_ONLINE_FILTER_OPTS[i]
      row.optionKey = opt.key
      row.label:SetText(opt.label)
      row:SetScript("OnClick", function(self)
        st().filterGuildOnlineKey = self.optionKey
        onlineFS:SetText(CEF.Guild.onlineFilterOptionRichText(st().filterGuildOnlineKey))
        menu:Hide()
        CEF.UIFilters.syncFilterDropBlocker(f)
        if CEF.UI.guildScrollFrame then
          CEF.UI.guildScrollFrame:SetVerticalScroll(0)
        end
        GUI.refresh()
      end)
      rows[i] = row
    end
    menu:SetHeight(8 + #CEF.GUILD_ONLINE_FILTER_OPTS * FILTER_MENU_ROW_H)
    menu._refresh = function()
      local sel = st().filterGuildOnlineKey
      for i, row in ipairs(rows) do
        local opt = CEF.GUILD_ONLINE_FILTER_OPTS[i]
        if opt and row.label then
          row.label:SetText(opt.label or CEF.L[opt.labelKey] or "")
        end
        local checked = (row.optionKey == false or row.optionKey == nil) and (sel == false or sel == nil)
          or row.optionKey == sel
        CEF.UIFilters.setFilterRowChecked(row, checked, true)
        CEF.UIFilters.applyFilterRowBg(row, false)
      end
    end
    onlineBtn:SetScript("OnClick", function()
      if menu:IsShown() then
        menu:Hide()
        CEF.UIFilters.syncFilterDropBlocker(f)
      else
        CEF.UIFilters.hideAllFilterDropdowns(f)
        menu._refresh()
        menu:Show()
        menu:Raise()
        CEF.UIFilters.syncFilterDropBlocker(f)
      end
    end)
  end

  local function makeLvlBox(anchor, initial)
    local border = CreateFrame("Frame", nil, guildFilterBar)
    border:SetSize(LVL_BOX_W, SEARCH_H)
    border:SetPoint("TOPLEFT", anchor, "TOPRIGHT", FILTER_GAP, 0)
    local bg = border:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.04, 0.05, 1)
    local edit = CreateFrame("EditBox", nil, border)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetAllPoints()
    edit:SetAutoFocus(false)
    edit:SetNumeric(true)
    edit:SetMaxLetters(2)
    edit:SetText(tostring(initial))
    edit:SetJustifyH("CENTER")
    edit:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
    end)
    return border, edit
  end

  local minBorder, minEdit = makeLvlBox(onlineBtn, st().filterGuildLevelMin or 1)
  local maxBorder, maxEdit = makeLvlBox(minBorder, st().filterGuildLevelMax or 60)

  local lvlDash = guildFilterBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lvlDash:SetText("-")
  lvlDash:SetTextColor(1, 0.82, 0.0)
  lvlDash:SetJustifyH("CENTER")
  lvlDash:SetPoint("LEFT", minBorder, "RIGHT", 0, 0)
  lvlDash:SetPoint("RIGHT", maxBorder, "LEFT", 0, 0)

  local function parseLvl(edit, fallback)
    local n = tonumber(edit:GetText())
    if not n then
      return fallback
    end
    if n < 1 then
      n = 1
    end
    if n > 60 then
      n = 60
    end
    return n
  end

  local function applyLevelFilters()
    st().filterGuildLevelMin = parseLvl(minEdit, 1)
    st().filterGuildLevelMax = parseLvl(maxEdit, 60)
    minEdit:SetText(tostring(st().filterGuildLevelMin))
    maxEdit:SetText(tostring(st().filterGuildLevelMax))
    if CEF.UI.guildScrollFrame then
      CEF.UI.guildScrollFrame:SetVerticalScroll(0)
    end
    GUI.refresh()
  end

  minEdit:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    applyLevelFilters()
  end)
  maxEdit:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    applyLevelFilters()
  end)
  minEdit:SetScript("OnEditFocusLost", applyLevelFilters)
  maxEdit:SetScript("OnEditFocusLost", applyLevelFilters)

  local resetBtn = CreateFrame("Button", nil, guildFilterBar)
  resetBtn:SetSize(RESET_W, SEARCH_H)
  resetBtn:SetPoint("TOPLEFT", maxBorder, "TOPRIGHT", FILTER_GAP, 0)
  local resetBg = resetBtn:CreateTexture(nil, "BACKGROUND")
  resetBg:SetAllPoints()
  resetBg:SetColorTexture(0.14, 0.1, 0.08, 1)
  local resetFs = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  resetFs:SetAllPoints()
  resetFs:SetText(CEF.L.RESET)
  resetBtn:SetScript("OnEnter", function()
    resetBg:SetColorTexture(0.22, 0.16, 0.1, 1)
  end)
  resetBtn:SetScript("OnLeave", function()
    resetBg:SetColorTexture(0.14, 0.1, 0.08, 1)
  end)
  resetBtn:SetScript("OnClick", function()
    CEF.UIFilters.hideAllFilterDropdowns(f)
    CEF.Guild.resetFilters()
    searchEdit:SetText("")
    searchEdit:ClearFocus()
    updateSearchPlaceholder()
    classFS:SetText(CEF.Guild.classFilterOptionRichText(st().filterGuildClassKeys))
    rankFS:SetText(CEF.Guild.rankFilterOptionRichText(st().filterGuildRankKeys))
    onlineFS:SetText(CEF.Guild.onlineFilterOptionRichText(st().filterGuildOnlineKey))
    minEdit:SetText("1")
    maxEdit:SetText("60")
    if f.guildHeader and f.guildHeader.updateSortLabels then
      f.guildHeader.updateSortLabels()
    end
    if CEF.UI.guildScrollFrame then
      CEF.UI.guildScrollFrame:SetVerticalScroll(0)
    end
    GUI.refresh()
  end)

  -- Redistribui a largura dos campos para preencher a barra toda (sem buraco à direita).
  local PAD_X = 10
  local function layoutGuildFilterBarFill()
    local barW = guildFilterBar:GetWidth() or 960
    local gaps = 6 * FILTER_GAP
    local fixed = LVL_BOX_W + LVL_BOX_W + RESET_W
    local flexTotal = barW - PAD_X * 2 - gaps - fixed
    if flexTotal < 200 then
      flexTotal = 200
    end
    local wSearch = math.floor(math.max(120, flexTotal * 0.34) + 0.5)
    local wClass = math.floor(math.max(100, flexTotal * 0.22) + 0.5)
    local wRank = math.floor(math.max(100, flexTotal * 0.24) + 0.5)
    local wOnline = math.max(80, flexTotal - wSearch - wClass - wRank)

    searchBorder:ClearAllPoints()
    searchBorder:SetHeight(SEARCH_H)
    searchBorder:SetWidth(wSearch)
    searchBorder:SetPoint("TOPLEFT", guildFilterBar, "TOPLEFT", PAD_X, -7)

    classBtn:ClearAllPoints()
    classBtn:SetHeight(SEARCH_H)
    classBtn:SetWidth(wClass)
    classBtn:SetPoint("TOPLEFT", searchBorder, "TOPRIGHT", FILTER_GAP, 0)

    rankBtn:ClearAllPoints()
    rankBtn:SetHeight(SEARCH_H)
    rankBtn:SetWidth(wRank)
    rankBtn:SetPoint("TOPLEFT", classBtn, "TOPRIGHT", FILTER_GAP, 0)

    onlineBtn:ClearAllPoints()
    onlineBtn:SetHeight(SEARCH_H)
    onlineBtn:SetWidth(wOnline)
    onlineBtn:SetPoint("TOPLEFT", rankBtn, "TOPRIGHT", FILTER_GAP, 0)

    minBorder:ClearAllPoints()
    minBorder:SetSize(LVL_BOX_W, SEARCH_H)
    minBorder:SetPoint("TOPLEFT", onlineBtn, "TOPRIGHT", FILTER_GAP, 0)

    maxBorder:ClearAllPoints()
    maxBorder:SetSize(LVL_BOX_W, SEARCH_H)
    maxBorder:SetPoint("TOPLEFT", minBorder, "TOPRIGHT", FILTER_GAP, 0)

    lvlDash:ClearAllPoints()
    lvlDash:SetPoint("LEFT", minBorder, "RIGHT", 0, 0)
    lvlDash:SetPoint("RIGHT", maxBorder, "LEFT", 0, 0)

    resetBtn:ClearAllPoints()
    resetBtn:SetSize(RESET_W, SEARCH_H)
    resetBtn:SetPoint("TOPLEFT", maxBorder, "TOPRIGHT", FILTER_GAP, 0)
  end

  guildFilterBar:SetScript("OnSizeChanged", layoutGuildFilterBarFill)
  layoutGuildFilterBarFill()
  f.cefLayoutGuildFilterBar = layoutGuildFilterBarFill

  local guildHeader = CreateFrame("Frame", nil, f)
  guildHeader:SetHeight(20)
  guildHeader:SetPoint("TOPLEFT", guildFilterBar, "BOTTOMLEFT", 0, -4)
  guildHeader:SetPoint("TOPRIGHT", guildFilterBar, "BOTTOMRIGHT", 0, -4)
  guildHeader:EnableMouse(true)
  guildHeader:Hide()
  local hTex = guildHeader:CreateTexture(nil, "BACKGROUND")
  hTex:SetAllPoints()
  hTex:SetColorTexture(0.2, 0.18, 0.12, 0.95)
  local labels = {
    CEF.L.COL_NAME,
    CEF.L.COL_LEVEL,
    CEF.L.COL_CLASS,
    CEF.L.COL_RANK,
    CEF.L.COL_ZONE,
    CEF.L.COL_STATUS,
    CEF.L.COL_NOTE,
    CEF.L.COL_OFFICER_NOTE,
  }
  local hdrKeys = {
    "COL_NAME",
    "COL_LEVEL",
    "COL_CLASS",
    "COL_RANK",
    "COL_ZONE",
    "COL_STATUS",
    "COL_NOTE",
    "COL_OFFICER_NOTE",
  }
  local MEDIA = "Interface\\AddOns\\ClassicEraFinder\\Media\\"
  local TEX_CHEVRON_UP = MEDIA .. "chevron-up.tga"
  local TEX_CHEVRON_DOWN = MEDIA .. "chevron-down.tga"
  local SORT_ICON_SIZE = 9
  local function updateGuildHeaderLabels()
    local active = CEF.Guild.getSortColumnIndex and CEF.Guild.getSortColumnIndex() or 0
    local asc = CEF.Guild.getSortAsc and CEF.Guild.getSortAsc()
    for i = 1, 8 do
      local h = guildHeader["h" .. i]
      local icon = guildHeader["sortIcon" .. i]
      if h then
        local base = CEF.L[hdrKeys[i]] or labels[i] or ""
        h:SetFontObject(GameFontNormalSmall)
        h:SetText(base)
        if i == active then
          h:SetTextColor(1, 0.92, 0.45)
          if icon then
            icon:SetTexture(asc and TEX_CHEVRON_UP or TEX_CHEVRON_DOWN)
            icon:SetVertexColor(1, 0.92, 0.45)
            local tw = h:GetStringWidth() or 0
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", h, "LEFT", tw + 3, 0)
            icon:Show()
          end
        else
          h:SetTextColor(1, 0.82, 0.18)
          if icon then
            icon:Hide()
          end
        end
      end
    end
  end
  for i = 1, 8 do
    local btn = CreateFrame("Button", nil, guildHeader)
    btn:SetHeight(20)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp")
    local h = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetPoint("LEFT", btn, "LEFT", 0, 0)
    h:SetPoint("RIGHT", btn, "RIGHT", -(SORT_ICON_SIZE + 4), 0)
    h:SetJustifyH("LEFT")
    h:SetJustifyV("MIDDLE")
    h:SetWordWrap(false)
    h:SetText(labels[i])
    h:SetTextColor(1, 0.82, 0.18)
    -- Sem SetFontString: o Button força fonte sem glifos CJK/cirílicos.
    local sortIcon = btn:CreateTexture(nil, "ARTWORK")
    sortIcon:SetSize(SORT_ICON_SIZE, SORT_ICON_SIZE)
    sortIcon:SetTexture(TEX_CHEVRON_DOWN)
    sortIcon:SetVertexColor(1, 0.92, 0.45)
    sortIcon:Hide()
    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    local ht = btn:GetHighlightTexture()
    if ht then
      ht:SetVertexColor(1, 0.85, 0.35)
      ht:SetAlpha(0.14)
      ht:SetAllPoints()
    end
    btn:SetScript("OnClick", function()
      if CEF.Guild and CEF.Guild.setSortColumn then
        CEF.Guild.setSortColumn(i)
        updateGuildHeaderLabels()
        GUI.refresh()
      end
    end)
    btn:SetScript("OnEnter", function()
      if i ~= (CEF.Guild.getSortColumnIndex and CEF.Guild.getSortColumnIndex()) then
        h:SetTextColor(1, 0.92, 0.55)
      end
    end)
    btn:SetScript("OnLeave", function()
      updateGuildHeaderLabels()
    end)
    guildHeader["btn" .. i] = btn
    guildHeader["h" .. i] = h
    guildHeader["sortIcon" .. i] = sortIcon
  end
  guildHeader.updateSortLabels = updateGuildHeaderLabels
  updateGuildHeaderLabels()

  local guildFooter = CreateFrame("Frame", nil, f)
  guildFooter:SetHeight(22)
  guildFooter:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 6)
  guildFooter:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, 6)
  guildFooter:Hide()
  local footBg = guildFooter:CreateTexture(nil, "BACKGROUND")
  footBg:SetAllPoints()
  footBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)
  local footFs = guildFooter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  footFs:SetPoint("LEFT", guildFooter, "LEFT", 12, 0)
  footFs:SetPoint("RIGHT", guildFooter, "RIGHT", -12, 0)
  footFs:SetJustifyH("LEFT")
  footFs:SetText(CEF.L("GUILD_FOOTER_COUNTS", 0, 0))

  local guildScroll = CreateFrame("ScrollFrame", nil, f)
  guildScroll:SetPoint("TOPLEFT", guildHeader, "BOTTOMLEFT", 0, -4)
  guildScroll:SetPoint("BOTTOMRIGHT", guildFooter, "TOPRIGHT", 0, -4)
  guildScroll:EnableMouse(true)
  guildScroll:Hide()

  local guildChild = CreateFrame("Frame", nil, guildScroll)
  guildChild:SetWidth(guildScroll:GetWidth())
  guildChild:SetHeight(400)
  guildScroll:SetScrollChild(guildChild)

  local emptyLabel = guildScroll:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyLabel:SetPoint("CENTER", guildScroll, "CENTER", 0, 0)
  emptyLabel:SetText("")
  emptyLabel:Hide()

  CEF.UI.guildFilterBar = guildFilterBar
  CEF.UI.guildHeader = guildHeader
  CEF.UI.guildScrollFrame = guildScroll
  CEF.UI.guildScrollChild = guildChild
  CEF.UI.guildEmptyLabel = emptyLabel
  CEF.UI.guildFooter = guildFooter
  CEF.UI.guildFooterLabel = footFs
  f.guildFilterBar = guildFilterBar
  f.guildHeader = guildHeader
  f.guildScrollFrame = guildScroll
  f.guildFooter = guildFooter

  local function onGuildWheel(_, delta)
    local view = CEF.Guild.getFilteredView()
    local n = #view
    local totalH = math.max(1, n * CC.ROW_HEIGHT)
    local viewH = guildScroll:GetHeight() or CC.ROW_HEIGHT
    local maxScroll = math.max(0, totalH - viewH)
    local step = viewH * 0.75
    local vs = guildScroll:GetVerticalScroll()
    if delta > 0 then
      vs = math.max(0, vs - step)
    else
      vs = math.min(maxScroll, vs + step)
    end
    guildScroll:SetVerticalScroll(vs)
    GUI.refresh()
  end
  guildScroll:EnableMouseWheel(true)
  guildScroll:SetScript("OnMouseWheel", onGuildWheel)

  local guildSBar = CreateFrame("Frame", nil, f)
  guildSBar:SetWidth(12)
  guildSBar:SetPoint("TOPLEFT", guildScroll, "TOPRIGHT", 2, 0)
  guildSBar:SetPoint("BOTTOMLEFT", guildScroll, "BOTTOMRIGHT", 2, 0)
  guildSBar:EnableMouse(true)
  guildSBar:SetFrameLevel((guildScroll:GetFrameLevel() or 0) + 8)
  guildSBar:Hide()
  local track = guildSBar:CreateTexture(nil, "BACKGROUND")
  track:SetAllPoints()
  track:SetColorTexture(0.04, 0.035, 0.07, 0.96)
  local thumb = CreateFrame("Button", nil, guildSBar)
  thumb:SetWidth(10)
  thumb:SetHeight(32)
  thumb:SetFrameLevel((guildSBar:GetFrameLevel() or 0) + 3)
  local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
  thumbTex:SetAllPoints()
  thumbTex:SetColorTexture(0.52, 0.5, 0.6, 0.88)
  thumb:SetNormalTexture(thumbTex)
  local thumbHi = thumb:CreateTexture(nil, "HIGHLIGHT")
  thumbHi:SetAllPoints()
  thumbHi:SetColorTexture(0.62, 0.58, 0.72, 0.55)
  thumb:SetHighlightTexture(thumbHi)
  thumb:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

  local function syncGuildScroll()
    if not guildScroll:IsShown() then
      guildSBar:Hide()
      thumb:Hide()
      return
    end
    local ch = guildChild:GetHeight() or 0
    local sh = guildScroll:GetHeight() or 1
    local maxV = math.max(0, ch - sh)
    local cur = guildScroll:GetVerticalScroll() or 0
    if cur > maxV then
      cur = maxV
      guildScroll:SetVerticalScroll(cur)
    end
    if maxV > 0.5 then
      guildSBar:Show()
      local trackH = guildSBar:GetHeight() or 1
      local thumbH = math.min(trackH, math.max(24, math.floor(trackH * sh / math.max(ch, 1))))
      if thumbH > trackH then
        thumbH = trackH
      end
      thumb:SetHeight(thumbH)
      local range = math.max(1e-6, trackH - thumbH)
      local yFromTop = (maxV > 0) and ((cur / maxV) * range) or 0
      thumb:ClearAllPoints()
      local lx = math.max(0, (guildSBar:GetWidth() - thumb:GetWidth()) / 2)
      thumb:SetPoint("TOPLEFT", guildSBar, "TOPLEFT", lx, -yFromTop)
      thumb:Show()
    else
      guildSBar:Hide()
      thumb:Hide()
    end
  end
  f.cefSyncGuildScroll = syncGuildScroll
  guildScroll:SetScript("OnVerticalScroll", syncGuildScroll)
  guildSBar:EnableMouseWheel(true)
  guildSBar:SetScript("OnMouseWheel", onGuildWheel)

  thumb:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then
      return
    end
    self.cefDragging = true
    local _, ny = GetCursorPosition()
    self.cefLastCursorY = ny
    self:SetScript("OnUpdate", function(btn)
      if not btn.cefDragging then
        return
      end
      if not IsMouseButtonDown("LeftButton") then
        btn.cefDragging = false
        btn:SetScript("OnUpdate", nil)
        return
      end
      local _, cy = GetCursorPosition()
      local scale = guildSBar:GetEffectiveScale() or 1
      if scale < 0.01 then
        scale = 1
      end
      local deltaPx = (btn.cefLastCursorY - cy) / scale
      btn.cefLastCursorY = cy
      local ch = guildChild:GetHeight() or 0
      local sh = guildScroll:GetHeight() or 1
      local maxS = math.max(0, ch - sh)
      local trackH = guildSBar:GetHeight() or 1
      local thumbH = btn:GetHeight() or 24
      local range = math.max(1e-6, trackH - thumbH)
      local scrollDelta = (deltaPx / range) * maxS
      local v = (guildScroll:GetVerticalScroll() or 0) + scrollDelta
      if v < 0 then
        v = 0
      end
      if v > maxS then
        v = maxS
      end
      guildScroll:SetVerticalScroll(v)
      GUI.refresh()
    end)
  end)

  thumb:SetScript("OnMouseUp", function(self)
    self.cefDragging = false
    self:SetScript("OnUpdate", nil)
  end)

  guildScroll:SetScript("OnShow", function()
    guildScroll:SetScript("OnUpdate", function(self)
      self:SetScript("OnUpdate", nil)
      syncGuildScroll()
    end)
  end)

  f.cefRefreshGuildUI = function()
    GUI.refresh()
  end

  -- Reagenda o layout no próximo frame (tamanho dos filhos só estabiliza depois do resize).
  local guildLayoutBoot = CreateFrame("Frame", nil, f)
  guildLayoutBoot:Hide()
  local function scheduleGuildLayoutSync()
    guildLayoutBoot:Show()
    guildLayoutBoot:SetScript("OnUpdate", function(s)
      s:SetScript("OnUpdate", nil)
      s:Hide()
      if f.cefNavTab == "guild" and f.cefSyncGuildLayout then
        f.cefSyncGuildLayout()
      end
    end)
  end
  f.cefScheduleGuildLayoutSync = scheduleGuildLayoutSync

  f.cefSyncGuildLayout = function()
    if f.cefLayoutGuildFilterBar then
      f.cefLayoutGuildFilterBar()
    end
    if not guildScroll or not guildChild then
      return
    end
    local sw = guildScroll:GetWidth() or 0
    local sh = guildScroll:GetHeight() or 0
    if sw < 32 or sh < 8 then
      scheduleGuildLayoutSync()
      return
    end
    guildChild:SetWidth(sw)
    -- Rebind evita ScrollFrame Classic “perder” o conteúdo após resize do parent.
    guildScroll:SetScrollChild(guildChild)
    CEF.UILayout.layoutGuildHeaderColumns(guildHeader, guildScroll)
    GUI.refresh()
    if f.cefSyncGuildScroll then
      f.cefSyncGuildScroll()
    end
  end

  guildScroll:SetScript("OnSizeChanged", function()
    if f.cefNavTab == "guild" then
      scheduleGuildLayoutSync()
    end
  end)

  f.cefApplyGuildLocale = function()
    if CEF.Guild and CEF.Guild.refreshLocaleLabels then
      CEF.Guild.refreshLocaleLabels()
    end
    if guildHeader.updateSortLabels then
      guildHeader.updateSortLabels()
    end
    CEF.UILayout.layoutGuildHeaderColumns(guildHeader, guildScroll)
    searchPlaceholder:SetText(CEF.L.SEARCH_PLACEHOLDER_GUILD)
    resetFs:SetText(CEF.L.RESET)
    classFS:SetText(CEF.Guild.classFilterOptionRichText(st().filterGuildClassKeys))
    rankFS:SetText(CEF.Guild.rankFilterOptionRichText(st().filterGuildRankKeys))
    onlineFS:SetText(CEF.Guild.onlineFilterOptionRichText(st().filterGuildOnlineKey))
    if f.guildMemberContextMenu and f.guildMemberContextMenu.refreshLocale then
      f.guildMemberContextMenu.refreshLocale()
    end
    if f.filterGuildOnlineMenu and f.filterGuildOnlineMenu._refresh then
      f.filterGuildOnlineMenu._refresh()
    end
    GUI.refresh()
  end

  return {
    filterBar = guildFilterBar,
    header = guildHeader,
    scroll = guildScroll,
    searchEdit = searchEdit,
    classFS = classFS,
    rankFS = rankFS,
    onlineFS = onlineFS,
  }
end
