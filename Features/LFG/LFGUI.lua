-- Módulo: UI da aba LFG oficial — tabela (como Lista) + busca/filtro.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.LFGUI = CEF.LFGUI or {}
local GUI = CEF.LFGUI

local ROW_H = 36
local ROW_LINE = 14
local ROW_EDGE = 4
local POOL = 28
local ROLE_ICON = 15
local ROLE_GAP = 1
local TABLE_PAD = 10
local COL_GAP = 8
local SEARCH_H = 26
local SEARCH_W = 160
local CAT_W = 130
local ACT_W = 170
local RESET_W = 88
local REFRESH_W = 90
local FILTER_GAP = 10
local FILTER_PAD_X = 10

local function columnWidths(totalW)
  local inner = math.max(420, (totalW or 600) - 2 * TABLE_PAD)
  -- Atividade | Líder | Tempo | Funções | Ação
  local c1 = inner * 0.30
  local c2 = inner * 0.22
  local c3 = inner * 0.12
  local c4 = inner * 0.22
  local c5 = inner * 0.14
  local x1 = TABLE_PAD
  local x2 = x1 + c1
  local x3 = x2 + c2
  local x4 = x3 + c3
  local x5 = x4 + c4
  return c1, c2, c3, c4, c5, x1, x2, x3, x4, x5
end

local function layoutHeader(header, scroll)
  if not header then
    return
  end
  local w = header:GetWidth() or 600
  if scroll and scroll.GetWidth then
    local sw = scroll:GetWidth()
    if sw and sw > 80 then
      w = sw
    end
  end
  local c1, c2, c3, c4, c5, x1, x2, x3, x4, x5 = columnWidths(w)
  local cols = {
    { header.h1, x1, math.max(80, c1 - COL_GAP) },
    { header.h2, x2, math.max(60, c2 - COL_GAP) },
    { header.h3, x3, math.max(40, c3 - COL_GAP) },
    { header.h4, x4, math.max(70, c4 - COL_GAP) },
    { header.h5, x5, math.max(56, c5 - COL_GAP) },
  }
  for _, it in ipairs(cols) do
    local fs, x, ww = it[1], it[2], it[3]
    if fs then
      fs:ClearAllPoints()
      fs:SetPoint("LEFT", header, "LEFT", x, 0)
      fs:SetWidth(ww)
      fs:SetJustifyH("LEFT")
    end
  end
end

local function ensureRoleIcons(rf, n)
  rf.roleIcons = rf.roleIcons or {}
  while #rf.roleIcons < n do
    local icon = rf:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROLE_ICON, ROLE_ICON)
    rf.roleIcons[#rf.roleIcons + 1] = icon
  end
  for i = n + 1, #rf.roleIcons do
    rf.roleIcons[i]:Hide()
  end
  return rf.roleIcons
end

local function hideRoleCountWidgets(rf)
  local widgets = rf.roleCountWidgets
  if not widgets then
    return
  end
  for _, wgt in ipairs(widgets) do
    if wgt.fs then
      wgt.fs:Hide()
    end
    if wgt.icon then
      wgt.icon:Hide()
    end
  end
end

local function ensureRoleCountWidgets(rf)
  if rf.roleCountWidgets then
    return rf.roleCountWidgets
  end
  local order = (CEF.LFG and CEF.LFG.getRoleOrder and CEF.LFG.getRoleOrder()) or { "TANK", "HEALER", "DAMAGER" }
  local widgets = {}
  for _, role in ipairs(order) do
    local fs = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    local icon = rf:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ROLE_ICON, ROLE_ICON)
    widgets[#widgets + 1] = { role = role, fs = fs, icon = icon }
  end
  rf.roleCountWidgets = widgets
  return widgets
end

local function paintRoleSlots(rf, slots, x, w)
  hideRoleCountWidgets(rf)
  slots = slots or {}
  local icons = ensureRoleIcons(rf, #slots)
  local startX = x
  for i, slot in ipairs(slots) do
    local icon = icons[i]
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", rf, "LEFT", startX + (i - 1) * (ROLE_ICON + ROLE_GAP), 0)
    if icon.SetAtlas then
      icon:SetAtlas(slot.atlas, false)
    end
    icon:SetDesaturated(not slot.filled)
    icon:SetAlpha(slot.filled and 1 or 0.4)
    icon:Show()
  end
end

--- Estilo RoleCount da Blizzard: "1 [tank] 0 [heal] 4 [dps]".
local function paintRoleCounts(rf, counts, x, w)
  ensureRoleIcons(rf, 0)
  counts = counts or {}
  local widgets = ensureRoleCountWidgets(rf)
  local cursor = x
  local gapAfter = 8
  for _, wgt in ipairs(widgets) do
    local n = tonumber(counts[wgt.role]) or 0
    wgt.fs:ClearAllPoints()
    wgt.fs:SetPoint("LEFT", rf, "LEFT", cursor, 0)
    wgt.fs:SetText(tostring(n))
    wgt.fs:SetTextColor(1, 1, 1)
    wgt.fs:Show()
    local tw = wgt.fs:GetStringWidth() or 8
    cursor = cursor + tw + 2

    wgt.icon:ClearAllPoints()
    wgt.icon:SetPoint("LEFT", rf, "LEFT", cursor, 0)
    local atlas = CEF.LFG and CEF.LFG.getRoleAtlas and CEF.LFG.getRoleAtlas(wgt.role)
    if atlas and wgt.icon.SetAtlas then
      wgt.icon:SetAtlas(atlas, false)
    end
    wgt.icon:SetDesaturated(false)
    wgt.icon:SetAlpha(0.85)
    wgt.icon:Show()
    cursor = cursor + ROLE_ICON + gapAfter
  end
end

local function paintRoles(rf, row, x, w)
  local display = row.roleDisplay
  if display and display.mode == "count" then
    paintRoleCounts(rf, display.counts or row.counts, x, w)
  else
    paintRoleSlots(rf, row.roleSlots or (display and display.slots), x, w)
  end
end

local function activityLineCount(row)
  local n = tonumber(row and row.activityLineCount) or 0
  if n < 1 then
    n = 1
  end
  return math.min(5, n)
end

-- Altura estilo Chat: "\n\n" entre instâncias → (2*n - 1) linhas visuais.
local function rowHeightFor(row)
  local n = activityLineCount(row)
  if n <= 1 then
    return ROW_H
  end
  return math.max(ROW_H, (2 * n - 1) * ROW_LINE + ROW_EDGE)
end

local function statusText()
  if not (CEF.LFG and CEF.LFG.isAvailable and CEF.LFG.isAvailable()) then
    return CEF.L.LFG_UNAVAILABLE
  end
  if CEF.LFG.isSearching and CEF.LFG.isSearching() then
    return CEF.L.LFG_SEARCHING
  end
  if CEF.LFG.didSearchFail and CEF.LFG.didSearchFail() then
    return CEF.L.LFG_SEARCH_FAILED
  end
  local all = CEF.LFG.getResults and CEF.LFG.getResults() or {}
  local filtered = CEF.LFG.getFilteredResults and CEF.LFG.getFilteredResults() or all
  if #filtered ~= #all then
    return CEF.L("LFG_RESULT_COUNT_FILTERED", #filtered, #all)
  end
  return CEF.L("LFG_RESULT_COUNT", #filtered)
end

function GUI.refresh()
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not f.lfgRoot or not f.lfgRoot:IsShown() then
    return
  end
  local listScroll = f.lfgScroll
  local listChild = f.lfgChild
  local rows = f.lfgRows
  local emptyFs = f.lfgEmpty
  local statusFs = f.lfgFooterLabel
  local header = f.lfgHeader
  if not listScroll or not listChild or not rows then
    return
  end

  layoutHeader(header, listScroll)
  if statusFs then
    statusFs:SetText(statusText())
  end

  local results = (CEF.LFG and CEF.LFG.getFilteredResults and CEF.LFG.getFilteredResults())
    or (CEF.LFG and CEF.LFG.getResults and CEF.LFG.getResults())
    or {}

  if emptyFs then
    if #results == 0 then
      emptyFs:Show()
      emptyFs:SetText(statusText())
    else
      emptyFs:Hide()
    end
  end

  local childW = listScroll:GetWidth() or 600
  listChild:SetWidth(childW)

  local rowHeights, rowStarts = {}, {}
  local totalH = 0
  for idx = 1, #results do
    local h = rowHeightFor(results[idx])
    rowHeights[idx] = h
    rowStarts[idx] = totalH
    totalH = totalH + h
  end
  listChild:SetHeight(math.max(1, totalH))

  local viewH = listScroll:GetHeight() or 1
  local vs = listScroll:GetVerticalScroll() or 0
  local maxScroll = math.max(0, totalH - viewH)
  if vs > maxScroll then
    vs = maxScroll
    listScroll:SetVerticalScroll(vs)
  end

  local first = 1
  for idx = 1, #results do
    if (rowStarts[idx] + rowHeights[idx]) > vs then
      first = idx
      break
    end
  end
  local last = first
  local bottom = vs + viewH
  for idx = first, #results do
    last = idx
    if rowStarts[idx] > bottom then
      break
    end
  end
  last = math.min(#results, last + 1)

  for _, rf in ipairs(rows) do
    rf:Hide()
  end

  local c1, c2, c3, c4, c5, x1, x2, x3, x4, x5 = columnWidths(childW)
  local w1 = math.max(80, c1 - COL_GAP)
  local w2 = math.max(60, c2 - COL_GAP)
  local w3 = math.max(40, c3 - COL_GAP)
  local w5 = math.max(56, c5 - COL_GAP)

  for i = first, last do
    local rowIndex = i - first + 1
    if rowIndex > POOL then
      break
    end
    local rf = rows[rowIndex]
    if not rf then
      rf = CreateFrame("Frame", nil, listChild)
      rf:SetHeight(ROW_H)
      local bg = rf:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      rf.bg = bg
      rf.colAct = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colAct:SetJustifyH("LEFT")
      rf.colAct:SetJustifyV("TOP")
      -- Word wrap ligado: sem ele o FontString ignora os "\n" e mostra tudo numa linha.
      rf.colAct:SetWordWrap(true)
      rf.colAct:SetNonSpaceWrap(false)
      if rf.colAct.SetMaxLines then
        -- 5 instâncias × "\n\n" entre elas = até 9 linhas visuais.
        rf.colAct:SetMaxLines(9)
      end
      rf.colLeader = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colLeader:SetJustifyH("LEFT")
      rf.colLeader:SetJustifyV("MIDDLE")
      rf.colLeader:SetWordWrap(false)
      rf.colTime = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colTime:SetJustifyH("LEFT")
      rf.colTime:SetJustifyV("MIDDLE")
      rf.colMembers = rf:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      rf.colMembers:SetJustifyH("LEFT")
      local actionBtn = CreateFrame("Button", nil, rf)
      actionBtn:SetSize(70, 22)
      local abg = actionBtn:CreateTexture(nil, "BACKGROUND")
      abg:SetAllPoints()
      abg:SetColorTexture(0.35, 0.18, 0.45, 0.95)
      actionBtn.bg = abg
      local afs = actionBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      afs:SetAllPoints()
      afs:SetText(CEF.L.WHISPER)
      actionBtn.fs = afs
      actionBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.45, 0.25, 0.55, 1)
      end)
      actionBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.35, 0.18, 0.45, 0.95)
      end)
      rf.actionBtn = actionBtn
      local sep = rf:CreateTexture(nil, "ARTWORK")
      sep:SetHeight(1)
      sep:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 8, 0)
      sep:SetPoint("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -8, 0)
      sep:SetColorTexture(0.25, 0.22, 0.18, 0.35)
      rows[rowIndex] = rf
    end

    local row = results[i]
    local rh = rowHeights[i] or ROW_H
    rf:SetWidth(childW)
    rf:SetHeight(rh)
    rf:ClearAllPoints()
    rf:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -(rowStarts[i] or 0))
    if (i % 2 == 0) then
      rf.bg:SetColorTexture(0.1, 0.1, 0.12, 0.85)
    else
      rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
    end

    rf.colAct:ClearAllPoints()
    rf.colAct:SetPoint("TOPLEFT", rf, "TOPLEFT", x1, -2)
    rf.colAct:SetWidth(w1)
    rf.colAct:SetHeight(math.max(ROW_LINE, rh - 4))
    rf.colAct:SetJustifyV("TOP")
    rf.colAct:SetText(row.activityRichText or row.activityName or "—")
    -- Cores vêm do rich text (|c…|r); evita sobrescrever com branco.
    rf.colAct:SetTextColor(1, 1, 1)

    rf.colLeader:ClearAllPoints()
    rf.colLeader:SetPoint("LEFT", rf, "LEFT", x2, 6)
    rf.colLeader:SetWidth(w2)
    rf.colLeader:SetText(row.leaderName or "?")
    local classFile = row.leaderClass
    local colored = false
    if classFile and RAID_CLASS_COLORS then
      local c = RAID_CLASS_COLORS[classFile] or RAID_CLASS_COLORS[string.upper(classFile)]
      if c then
        rf.colLeader:SetTextColor(c.r or 1, c.g or 1, c.b or 1)
        colored = true
      end
    end
    if not colored then
      rf.colLeader:SetTextColor(1, 0.9, 0.55)
    end

    rf.colMembers:ClearAllPoints()
    rf.colMembers:SetPoint("LEFT", rf, "LEFT", x2, -8)
    rf.colMembers:SetWidth(w2)
    rf.colMembers:SetText(CEF.L("LFG_MEMBERS", row.numMembers or 0))

    rf.colTime:ClearAllPoints()
    rf.colTime:SetPoint("LEFT", rf, "LEFT", x3, 0)
    rf.colTime:SetWidth(w3)
    rf.colTime:SetText(row.ageText or "")
    rf.colTime:SetTextColor(0.75, 0.72, 0.65)

    paintRoles(rf, row, x4, c4)

    rf.actionBtn:ClearAllPoints()
    rf.actionBtn:SetPoint("LEFT", rf, "LEFT", x5, 0)
    rf.actionBtn:SetWidth(math.min(w5, 78))
    if rf.actionBtn.fs then
      rf.actionBtn.fs:SetText(CEF.L.WHISPER)
    end
    rf.actionBtn:SetScript("OnClick", function()
      local name = row.leaderName
      if name and name ~= "" and CEF.UI and CEF.UI.openWhisperInHub then
        CEF.UI.openWhisperInHub(name)
      end
    end)
    rf:Show()
  end

  if f.cefSyncLfgScroll then
    f.cefSyncLfgScroll()
  end
end

function GUI.createPanels(f, navBar)
  if f.lfgRoot then
    return f.lfgRoot
  end

  local RIGHT_SCROLL_OUTSET = 0
  local root = CreateFrame("Frame", nil, f)
  root:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  root:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, 6)
  root:Hide()
  f.lfgRoot = root

  -- Filter bar (mesmo espírito da Lista).
  local bar = CreateFrame("Frame", nil, root)
  bar:SetHeight(SEARCH_H + 14)
  bar:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
  bar:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
  bar:EnableMouse(true)
  local barBg = bar:CreateTexture(nil, "BACKGROUND")
  barBg:SetAllPoints()
  barBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)
  f.lfgFilterBar = bar

  local searchBorder = CreateFrame("Frame", nil, bar)
  searchBorder:SetSize(SEARCH_W, SEARCH_H)
  searchBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", 10, -7)
  local sbd = searchBorder:CreateTexture(nil, "BACKGROUND")
  sbd:SetAllPoints()
  sbd:SetColorTexture(0.04, 0.04, 0.05, 1)

  local searchPh = searchBorder:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  searchPh:SetPoint("LEFT", searchBorder, "LEFT", 6, 0)
  searchPh:SetPoint("RIGHT", searchBorder, "RIGHT", -6, 0)
  searchPh:SetJustifyH("LEFT")
  searchPh:SetText(CEF.L.LFG_SEARCH_PLACEHOLDER)

  local searchEdit = CreateFrame("EditBox", nil, searchBorder)
  searchEdit:SetFontObject(GameFontHighlightSmall)
  searchEdit:SetPoint("TOPLEFT", searchBorder, "TOPLEFT", 4, -2)
  searchEdit:SetPoint("BOTTOMRIGHT", searchBorder, "BOTTOMRIGHT", -4, 2)
  searchEdit:SetAutoFocus(false)
  f.lfgSearchEdit = searchEdit
  f.lfgSearchPlaceholder = searchPh

  local function updateSearchPh()
    local tx = searchEdit:GetText() or ""
    if tx == "" and not searchEdit:HasFocus() then
      searchPh:Show()
    else
      searchPh:Hide()
    end
  end

  searchEdit:SetScript("OnTextChanged", function(self)
    updateSearchPh()
    if CEF.LFG and CEF.LFG.setSearchText then
      CEF.LFG.setSearchText(self:GetText() or "")
    end
    GUI.refresh()
  end)
  searchEdit:SetScript("OnEditFocusGained", updateSearchPh)
  searchEdit:SetScript("OnEditFocusLost", updateSearchPh)
  searchEdit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  searchEdit:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  local catBtn = CreateFrame("Button", nil, bar)
  catBtn:SetSize(CAT_W, SEARCH_H)
  catBtn:SetPoint("TOPLEFT", searchBorder, "TOPRIGHT", 8, 0)
  local catBg = catBtn:CreateTexture(nil, "BACKGROUND")
  catBg:SetAllPoints()
  catBg:SetColorTexture(0.12, 0.11, 0.1, 1)
  local catFs = catBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  catFs:SetPoint("LEFT", catBtn, "LEFT", 8, 0)
  catFs:SetPoint("RIGHT", catBtn, "RIGHT", -22, 0)
  catFs:SetJustifyH("LEFT")
  catFs:SetWordWrap(false)
  catFs:SetText(CEF.L.LFG_CATEGORY)
  if CEF.UIFilters and CEF.UIFilters.attachDropChevron then
    CEF.UIFilters.attachDropChevron(catBtn, 14)
  end
  f.lfgCategoryBtn = catBtn
  f.lfgCategoryFs = catFs

  local catMenu = CreateFrame("Frame", nil, f)
  catMenu:SetFrameStrata("DIALOG")
  catMenu:SetFrameLevel(600)
  catMenu:SetWidth(CAT_W)
  catMenu:Hide()
  local catMenuBg = catMenu:CreateTexture(nil, "BACKGROUND")
  catMenuBg:SetAllPoints()
  catMenuBg:SetColorTexture(0.08, 0.07, 0.07, 0.98)
  f.lfgCategoryMenu = catMenu
  f.lfgCategoryMenuRows = {}

  local function hideCatMenu()
    catMenu:Hide()
    if CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
      CEF.UIFilters.setDropChevronOpen(catBtn, false)
    end
  end

  local actBtn = CreateFrame("Button", nil, bar)
  actBtn:SetSize(ACT_W, SEARCH_H)
  actBtn:SetPoint("TOPLEFT", catBtn, "TOPRIGHT", 8, 0)
  local actBg = actBtn:CreateTexture(nil, "BACKGROUND")
  actBg:SetAllPoints()
  actBg:SetColorTexture(0.12, 0.11, 0.1, 1)
  local actFs = actBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  actFs:SetPoint("LEFT", actBtn, "LEFT", 8, 0)
  actFs:SetPoint("RIGHT", actBtn, "RIGHT", -22, 0)
  actFs:SetJustifyH("LEFT")
  actFs:SetWordWrap(false)
  actFs:SetText(CEF.L.LFG_ALL_ACTIVITIES)
  if CEF.UIFilters and CEF.UIFilters.attachDropChevron then
    CEF.UIFilters.attachDropChevron(actBtn, 14)
  end
  f.lfgActivityBtn = actBtn
  f.lfgActivityFs = actFs

  local actMenu = CreateFrame("Frame", nil, f)
  actMenu:SetFrameStrata("DIALOG")
  actMenu:SetFrameLevel(610)
  actMenu:SetWidth(ACT_W + 40)
  actMenu:Hide()
  local actMenuBg = actMenu:CreateTexture(nil, "BACKGROUND")
  actMenuBg:SetAllPoints()
  actMenuBg:SetColorTexture(0.08, 0.07, 0.07, 0.98)
  f.lfgActivityMenu = actMenu

  local ACT_MENU_SEARCH_H = 22
  local actMenuSearchQ = ""
  local actSearchBorder = CreateFrame("Frame", nil, actMenu)
  actSearchBorder:SetHeight(ACT_MENU_SEARCH_H)
  actSearchBorder:SetPoint("TOPLEFT", actMenu, "TOPLEFT", 6, -6)
  actSearchBorder:SetPoint("TOPRIGHT", actMenu, "TOPRIGHT", -6, -6)
  local actSearchBg = actSearchBorder:CreateTexture(nil, "BACKGROUND")
  actSearchBg:SetAllPoints()
  actSearchBg:SetColorTexture(0.1, 0.09, 0.08, 1)
  local actSearchPh = actSearchBorder:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  actSearchPh:SetPoint("LEFT", actSearchBorder, "LEFT", 6, 0)
  actSearchPh:SetPoint("RIGHT", actSearchBorder, "RIGHT", -6, 0)
  actSearchPh:SetJustifyH("LEFT")
  actSearchPh:SetText(CEF.L.FILTER_INSTANCE_SEARCH or "Search instance…")
  local actSearchEdit = CreateFrame("EditBox", nil, actSearchBorder)
  actSearchEdit:SetFontObject(GameFontHighlightSmall)
  actSearchEdit:SetPoint("TOPLEFT", actSearchBorder, "TOPLEFT", 4, -2)
  actSearchEdit:SetPoint("BOTTOMRIGHT", actSearchBorder, "BOTTOMRIGHT", -4, 2)
  actSearchEdit:SetAutoFocus(false)
  actSearchEdit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  local function updateActSearchPh()
    local tx = actSearchEdit:GetText() or ""
    if tx == "" and not actSearchEdit:HasFocus() then
      actSearchPh:Show()
    else
      actSearchPh:Hide()
    end
  end
  actSearchEdit:SetScript("OnEditFocusGained", updateActSearchPh)
  actSearchEdit:SetScript("OnEditFocusLost", updateActSearchPh)
  f.lfgActivitySearchEdit = actSearchEdit
  f.lfgActivitySearchPlaceholder = actSearchPh

  local actScroll = CreateFrame("ScrollFrame", nil, actMenu)
  actScroll:SetPoint("TOPLEFT", actMenu, "TOPLEFT", 4, -(8 + ACT_MENU_SEARCH_H))
  actScroll:SetPoint("BOTTOMRIGHT", actMenu, "BOTTOMRIGHT", -4, 4)
  actScroll:EnableMouseWheel(true)
  local actChild = CreateFrame("Frame", nil, actScroll)
  actChild:SetWidth(ACT_W)
  actChild:SetHeight(100)
  actScroll:SetScrollChild(actChild)
  actScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, actChild:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * 66
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
  end)
  f.lfgActivityMenuRows = {}

  local function hideActMenu()
    actMenu:Hide()
    if CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
      CEF.UIFilters.setDropChevronOpen(actBtn, false)
    end
  end

  local function hideAllLfgMenus()
    hideCatMenu()
    hideActMenu()
  end

  local function refreshActivityLabel()
    if CEF.LFG and CEF.LFG.activityFilterSummary then
      actFs:SetText(CEF.LFG.activityFilterSummary())
    else
      actFs:SetText(CEF.L.LFG_ALL_ACTIVITIES)
    end
  end
  f.lfgRefreshActivityLabel = refreshActivityLabel

  local function refreshCategoryLabel()
    local id = CEF.LFG.getSelectedCategoryId and CEF.LFG.getSelectedCategoryId()
    local label = CEF.L.LFG_CATEGORY
    if id and CEF.LFG.getCategories then
      for _, c in ipairs(CEF.LFG.getCategories()) do
        if c.id == id then
          label = c.name
          break
        end
      end
    end
    catFs:SetText(label)
    refreshActivityLabel()
  end
  f.lfgRefreshCategoryLabel = refreshCategoryLabel

  local function ensureActRow(i)
    local rows = f.lfgActivityMenuRows
    local row = rows[i]
    if row then
      return row
    end
    row = CreateFrame("Button", nil, actChild)
    row:SetHeight(22)
    local rbg = row:CreateTexture(nil, "BACKGROUND")
    rbg:SetAllPoints()
    row.bg = rbg
    if CEF.UIFilters and CEF.UIFilters.attachFilterRowCheck then
      CEF.UIFilters.attachFilterRowCheck(row)
    end
    local rfs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    if row.check then
      rfs:SetPoint("LEFT", row.check, "RIGHT", 6, 0)
    else
      rfs:SetPoint("LEFT", row, "LEFT", 8, 0)
    end
    rfs:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    rfs:SetJustifyH("LEFT")
    rfs:SetWordWrap(false)
    row.fs = rfs
    rows[i] = row
    return row
  end

  local function openActMenu()
    hideCatMenu()
    local allActivities = (CEF.LFG and CEF.LFG.getActivities and CEF.LFG.getActivities()) or {}
    local q = actMenuSearchQ
    local activities = allActivities
    if q ~= "" then
      activities = {}
      for _, act in ipairs(allActivities) do
        local hay = tostring(act.label or act.name or "")
        hay = hay:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        hay = strlower(hay)
        if act.instanceKey then
          if CEF.instanceSearchHay then
            hay = hay .. " " .. CEF.instanceSearchHay(act.instanceKey)
          else
            hay = hay .. " " .. strlower(tostring(act.instanceKey))
            if CEF.getInstanceDisplayName then
              hay = hay .. " " .. strlower(tostring(CEF.getInstanceDisplayName(act.instanceKey) or ""))
            end
          end
        end
        if hay:find(q, 1, true) then
          activities[#activities + 1] = act
        end
      end
    end
    local rows = f.lfgActivityMenuRows
    for _, r in ipairs(rows) do
      r:Hide()
    end

    -- Linha 1: Todas as atividades
    local allRow = ensureActRow(1)
    allRow:ClearAllPoints()
    allRow:SetPoint("TOPLEFT", actChild, "TOPLEFT", 0, 0)
    allRow:SetPoint("TOPRIGHT", actChild, "TOPRIGHT", 0, 0)
    allRow.fs:SetText(CEF.L.LFG_ALL_ACTIVITIES)
    local myLevelOn = CEF.LFG.isMyLevelFilter and CEF.LFG.isMyLevelFilter()
    local allSelected = not (CEF.LFG.hasActivityFilter and CEF.LFG.hasActivityFilter())
    if CEF.UIFilters and CEF.UIFilters.setFilterRowChecked then
      CEF.UIFilters.setFilterRowChecked(allRow, allSelected, true)
      CEF.UIFilters.applyFilterRowBg(allRow, false)
    else
      allRow.bg:SetColorTexture(allSelected and 0.2 or 0.12, allSelected and 0.26 or 0.11, allSelected and 0.14 or 0.1, 1)
    end
    allRow:SetScript("OnClick", function()
      if CEF.LFG.clearActivitySelection then
        CEF.LFG.clearActivitySelection()
      end
      refreshActivityLabel()
      hideActMenu()
      -- Filtro só no cliente; evita Search a cada clique (lento / pode travar).
      GUI.refresh()
    end)
    allRow:Show()

    -- Linha 2: Instâncias para o meu personagem (range recomendado)
    local myRow = ensureActRow(2)
    myRow:ClearAllPoints()
    myRow:SetPoint("TOPLEFT", actChild, "TOPLEFT", 0, -22)
    myRow:SetPoint("TOPRIGHT", actChild, "TOPRIGHT", 0, -22)
    myRow.fs:SetText(CEF.L.FILTER_MY_LEVEL_INSTANCES or "Instances for my character")
    if CEF.UIFilters and CEF.UIFilters.setFilterRowChecked then
      CEF.UIFilters.setFilterRowChecked(myRow, myLevelOn, true)
      CEF.UIFilters.applyFilterRowBg(myRow, false)
    else
      myRow.bg:SetColorTexture(myLevelOn and 0.2 or 0.12, myLevelOn and 0.26 or 0.11, myLevelOn and 0.14 or 0.1, 1)
    end
    myRow:SetScript("OnClick", function()
      if CEF.LFG.toggleMyLevelFilter then
        CEF.LFG.toggleMyLevelFilter()
      end
      refreshActivityLabel()
      openActMenu()
      if CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
        CEF.UIFilters.setDropChevronOpen(actBtn, true)
      end
      GUI.refresh()
    end)
    myRow:Show()

    local splitTbc = CEF.isTbcActive and CEF.isTbcActive()
    local catId = CEF.LFG.getSelectedCategoryId and CEF.LFG.getSelectedCategoryId()
    local catLocaleKey = nil
    if CEF.LFG and CEF.LFG.getCategoryLocaleKey then
      catLocaleKey = CEF.LFG.getCategoryLocaleKey(catId)
    end
    local isRaidCat = catLocaleKey == "CATEGORY_RAIDS"
    local isDungeonCat = catLocaleKey == "CATEGORY_DUNGEONS"
    local canSplit = splitTbc and (isRaidCat or isDungeonCat or catLocaleKey == nil)

    local h = 44
    local rowIndex = 2
    local lastBucket = nil
    local sawClassic, sawTbc, sawHeroic = false, false, false
    for _, act in ipairs(activities) do
      if act.isTbcHeroic then
        sawHeroic = true
      elseif act.isTbc then
        sawTbc = true
      else
        sawClassic = true
      end
    end
    canSplit = canSplit and ((sawClassic and (sawTbc or sawHeroic)) or (sawTbc and sawHeroic))

    local function headerForBucket(bucket)
      if isRaidCat then
        if bucket == "tbc" or bucket == "tbcHeroic" then
          return "CATEGORY_TBC_RAIDS"
        end
        return "CATEGORY_CLASSIC_RAIDS"
      end
      if bucket == "tbcHeroic" then
        return "CATEGORY_TBC_HEROIC_DUNGEONS"
      end
      if bucket == "tbc" then
        return "CATEGORY_TBC_DUNGEONS"
      end
      return "CATEGORY_CLASSIC_DUNGEONS"
    end

    local function actBucket(act)
      if act.isTbcHeroic then
        return "tbcHeroic"
      end
      if act.isTbc then
        return "tbc"
      end
      return "classic"
    end

    local function pushHeader(textKey)
      rowIndex = rowIndex + 1
      local row = ensureActRow(rowIndex)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", actChild, "TOPLEFT", 0, -h)
      row:SetPoint("TOPRIGHT", actChild, "TOPRIGHT", 0, -h)
      row.fs:SetText((textKey and CEF.L[textKey]) or textKey or "")
      row.fs:SetTextColor(1, 0.82, 0.18)
      row:EnableMouse(false)
      if CEF.UIFilters and CEF.UIFilters.setFilterRowChecked then
        CEF.UIFilters.setFilterRowChecked(row, false, false)
        CEF.UIFilters.applyFilterRowBg(row, false)
      else
        row.bg:SetColorTexture(0.1, 0.09, 0.08, 1)
      end
      row:SetScript("OnClick", nil)
      row:Show()
      h = h + 22
    end

    for _, act in ipairs(activities) do
      local bucket = actBucket(act)
      if canSplit and bucket ~= lastBucket then
        pushHeader(headerForBucket(bucket))
        lastBucket = bucket
      end
      rowIndex = rowIndex + 1
      local row = ensureActRow(rowIndex)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", actChild, "TOPLEFT", 0, -h)
      row:SetPoint("TOPRIGHT", actChild, "TOPRIGHT", 0, -h)
      row.fs:SetText(act.label or act.name)
      row.fs:SetTextColor(1, 1, 1)
      row:EnableMouse(true)
      local checked = CEF.LFG.isActivitySelected and CEF.LFG.isActivitySelected(act.id)
      if CEF.UIFilters and CEF.UIFilters.setFilterRowChecked then
        CEF.UIFilters.setFilterRowChecked(row, checked, true)
        CEF.UIFilters.applyFilterRowBg(row, false)
      else
        row.bg:SetColorTexture(0.12, 0.11, 0.1, 0.9)
      end
      row:SetScript("OnClick", function()
        if CEF.LFG.toggleActivity then
          CEF.LFG.toggleActivity(act.id)
        end
        refreshActivityLabel()
        openActMenu()
        if CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
          CEF.UIFilters.setDropChevronOpen(actBtn, true)
        end
        GUI.refresh()
      end)
      row:Show()
      h = h + 22
    end

    local rowsAll = f.lfgActivityMenuRows
    for i = rowIndex + 1, #rowsAll do
      rowsAll[i]:Hide()
    end

    actChild:SetHeight(math.max(22, h))
    actChild:SetWidth(math.max(ACT_W, (actBtn:GetWidth() or ACT_W) + 20))
    local menuH = math.min(300, h + 8 + ACT_MENU_SEARCH_H + 4)
    actMenu:SetHeight(menuH)
    actMenu:SetWidth(math.max(ACT_W + 8, (actBtn:GetWidth() or ACT_W) + 28))
    actMenu:ClearAllPoints()
    actMenu:SetPoint("TOPLEFT", actBtn, "BOTTOMLEFT", 0, -2)
    actScroll:SetVerticalScroll(0)
    actMenu:Show()
  end

  actSearchEdit:SetScript("OnTextChanged", function(self)
    local t = self:GetText() or ""
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    actMenuSearchQ = string.lower(t)
    updateActSearchPh()
    if actMenu:IsShown() then
      openActMenu()
    end
  end)
  updateActSearchPh()

  local function openCatMenu()
    hideActMenu()
    local cats = (CEF.LFG and CEF.LFG.getCategories and CEF.LFG.getCategories()) or {}
    local rows = f.lfgCategoryMenuRows
    for _, r in ipairs(rows) do
      r:Hide()
    end
    local h = 4
    local selected = CEF.LFG.getSelectedCategoryId and CEF.LFG.getSelectedCategoryId()
    for i, c in ipairs(cats) do
      local row = rows[i]
      if not row then
        row = CreateFrame("Button", nil, catMenu)
        row:SetHeight(22)
        local rbg = row:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints()
        row.bg = rbg
        local rfs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rfs:SetPoint("LEFT", row, "LEFT", 8, 0)
        rfs:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        rfs:SetJustifyH("LEFT")
        row.fs = rfs
        rows[i] = row
      end
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", catMenu, "TOPLEFT", 4, -h)
      row:SetPoint("TOPRIGHT", catMenu, "TOPRIGHT", -4, -h)
      row.fs:SetText(c.name)
      if c.id == selected then
        row.bg:SetColorTexture(0.24, 0.19, 0.12, 1)
        row.fs:SetTextColor(1, 0.9, 0.45)
      else
        row.bg:SetColorTexture(0.12, 0.11, 0.1, 0.9)
        row.fs:SetTextColor(1, 1, 1)
      end
      row:SetScript("OnClick", function()
        CEF.LFG.setSelectedCategoryId(c.id)
        refreshCategoryLabel()
        hideAllLfgMenus()
        if CEF.LFG.search then
          CEF.LFG.search(c.id)
        end
        GUI.refresh()
      end)
      row:Show()
      h = h + 22
    end
    catMenu:SetHeight(math.max(28, h + 4))
    catMenu:SetWidth(math.max(CAT_W, catBtn:GetWidth() or CAT_W))
    catMenu:ClearAllPoints()
    catMenu:SetPoint("TOPLEFT", catBtn, "BOTTOMLEFT", 0, -2)
    catMenu:Show()
  end

  catBtn:SetScript("OnClick", function()
    if catMenu:IsShown() then
      hideCatMenu()
    else
      openCatMenu()
      if CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
        CEF.UIFilters.setDropChevronOpen(catBtn, true)
      end
    end
  end)

  actBtn:SetScript("OnClick", function()
    if actMenu:IsShown() then
      hideActMenu()
    else
      actMenuSearchQ = ""
      actSearchEdit:SetText("")
      updateActSearchPh()
      openActMenu()
      if CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
        CEF.UIFilters.setDropChevronOpen(actBtn, true)
      end
    end
  end)

  local refreshBtn = CreateFrame("Button", nil, bar)
  refreshBtn:SetSize(REFRESH_W, SEARCH_H)
  refreshBtn:SetPoint("TOPLEFT", actBtn, "TOPRIGHT", FILTER_GAP, 0)
  local rbg = refreshBtn:CreateTexture(nil, "BACKGROUND")
  rbg:SetAllPoints()
  rbg:SetColorTexture(0.35, 0.28, 0.12, 0.95)
  local rfs = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  rfs:SetAllPoints()
  rfs:SetText(CEF.L.LFG_REFRESH)
  rfs:SetTextColor(1, 0.9, 0.45)
  refreshBtn.fs = rfs
  refreshBtn:SetScript("OnClick", function()
    hideAllLfgMenus()
    if CEF.LFG and CEF.LFG.search then
      CEF.LFG.search(nil, { force = true })
    end
    GUI.refresh()
  end)
  f.lfgRefreshBtn = refreshBtn

  local resetBtn = CreateFrame("Button", nil, bar)
  resetBtn:SetSize(RESET_W, SEARCH_H)
  resetBtn:SetPoint("TOPLEFT", refreshBtn, "TOPRIGHT", FILTER_GAP, 0)
  local zbg = resetBtn:CreateTexture(nil, "BACKGROUND")
  zbg:SetAllPoints()
  zbg:SetColorTexture(0.18, 0.15, 0.1, 0.95)
  local zfs = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  zfs:SetAllPoints()
  zfs:SetText(CEF.L.RESET)
  zfs:SetTextColor(1, 0.82, 0.18)
  resetBtn.fs = zfs
  resetBtn:SetScript("OnClick", function()
    hideAllLfgMenus()
    searchEdit:SetText("")
    if CEF.LFG and CEF.LFG.setSearchText then
      CEF.LFG.setSearchText("")
    end
    if CEF.LFG and CEF.LFG.clearActivitySelection then
      CEF.LFG.clearActivitySelection()
    end
    updateSearchPh()
    refreshActivityLabel()
    if CEF.LFG and CEF.LFG.search then
      CEF.LFG.search(nil, { force = true })
    end
    GUI.refresh()
  end)
  f.lfgResetBtn = resetBtn

  -- Redistribui busca + dropdowns para preencher 100% da barra (como Lista/Guilda).
  local function layoutLfgFilterBarFill()
    local barW = bar:GetWidth() or 960
    local gaps = 4 * FILTER_GAP
    local fixed = REFRESH_W + RESET_W
    local flexTotal = barW - FILTER_PAD_X * 2 - gaps - fixed
    if flexTotal < 280 then
      flexTotal = 280
    end
    local wSearch = math.floor(math.max(140, flexTotal * 0.34) + 0.5)
    local wCat = math.floor(math.max(110, flexTotal * 0.28) + 0.5)
    local wAct = math.max(120, flexTotal - wSearch - wCat)

    searchBorder:ClearAllPoints()
    searchBorder:SetHeight(SEARCH_H)
    searchBorder:SetWidth(wSearch)
    searchBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", FILTER_PAD_X, -7)

    catBtn:ClearAllPoints()
    catBtn:SetHeight(SEARCH_H)
    catBtn:SetWidth(wCat)
    catBtn:SetPoint("TOPLEFT", searchBorder, "TOPRIGHT", FILTER_GAP, 0)

    actBtn:ClearAllPoints()
    actBtn:SetHeight(SEARCH_H)
    actBtn:SetWidth(wAct)
    actBtn:SetPoint("TOPLEFT", catBtn, "TOPRIGHT", FILTER_GAP, 0)

    refreshBtn:ClearAllPoints()
    refreshBtn:SetSize(REFRESH_W, SEARCH_H)
    refreshBtn:SetPoint("TOPLEFT", actBtn, "TOPRIGHT", FILTER_GAP, 0)

    resetBtn:ClearAllPoints()
    resetBtn:SetSize(RESET_W, SEARCH_H)
    resetBtn:SetPoint("TOPLEFT", refreshBtn, "TOPRIGHT", FILTER_GAP, 0)
  end

  bar:SetScript("OnSizeChanged", layoutLfgFilterBarFill)
  layoutLfgFilterBarFill()
  f.cefLayoutLfgFilterBar = layoutLfgFilterBarFill

  -- Header da tabela: largura total (como Chat); scroll/footer reservam a barra.
  local SCROLL_BAR_GAP = 14
  local header = CreateFrame("Frame", nil, root)
  header:SetHeight(20)
  header:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
  header:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
  local hTex = header:CreateTexture(nil, "BACKGROUND")
  hTex:SetAllPoints()
  hTex:SetColorTexture(0.2, 0.18, 0.12, 0.95)
  header.h1 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h2 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h3 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h4 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h5 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  for _, h in ipairs({ header.h1, header.h2, header.h3, header.h4, header.h5 }) do
    h:SetTextColor(1, 0.82, 0.18)
  end
  header.h1:SetText(CEF.L.LFG_COL_ACTIVITY)
  header.h2:SetText(CEF.L.LFG_COL_LEADER)
  header.h3:SetText(CEF.L.COL_TIME)
  header.h4:SetText(CEF.L.LFG_COL_ROLES)
  header.h5:SetText(CEF.L.COL_ACTION)
  f.lfgHeader = header
  f.lfgHeaderActivity = header.h1
  f.lfgHeaderLeader = header.h2
  f.lfgHeaderTime = header.h3
  f.lfgHeaderRoles = header.h4
  f.lfgHeaderAction = header.h5

  -- Footer com contagem (como Guilda).
  local footer = CreateFrame("Frame", nil, root)
  footer:SetHeight(22)
  footer:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
  footer:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -SCROLL_BAR_GAP, 0)
  local footBg = footer:CreateTexture(nil, "BACKGROUND")
  footBg:SetAllPoints()
  footBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)
  local footFs = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  footFs:SetPoint("LEFT", footer, "LEFT", 12, 0)
  footFs:SetPoint("RIGHT", footer, "RIGHT", -12, 0)
  footFs:SetJustifyH("LEFT")
  footFs:SetText(CEF.L("LFG_RESULT_COUNT", 0))
  f.lfgFooter = footer
  f.lfgFooterLabel = footFs
  f.lfgStatus = footFs

  local scroll = CreateFrame("ScrollFrame", nil, root)
  scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, -4)
  scroll:EnableMouseWheel(true)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(400)
  child:SetHeight(100)
  scroll:SetScrollChild(child)

  local function onLfgWheel(_, delta)
    local maxO = math.max(0, child:GetHeight() - scroll:GetHeight())
    local v = scroll:GetVerticalScroll() - delta * ROW_H * 3
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    scroll:SetVerticalScroll(v)
    GUI.refresh()
  end
  scroll:SetScript("OnMouseWheel", onLfgWheel)
  scroll:SetScript("OnSizeChanged", function(self)
    child:SetWidth(self:GetWidth() or 400)
    layoutHeader(header, self)
    GUI.refresh()
  end)
  f.lfgScroll = scroll
  f.lfgChild = child
  f.lfgRows = {}

  -- Barra de rolagem visual (trilho + thumb), como Chat/Guilda.
  local sBar = CreateFrame("Frame", nil, root)
  sBar:SetWidth(12)
  sBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 2, 0)
  sBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 0)
  sBar:EnableMouse(true)
  sBar:SetFrameLevel((scroll:GetFrameLevel() or 0) + 8)
  sBar:Hide()
  local track = sBar:CreateTexture(nil, "BACKGROUND")
  track:SetAllPoints()
  track:SetColorTexture(0.04, 0.035, 0.07, 0.96)
  local thumb = CreateFrame("Button", nil, sBar)
  thumb:SetWidth(10)
  thumb:SetHeight(32)
  thumb:SetFrameLevel((sBar:GetFrameLevel() or 0) + 3)
  local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
  thumbTex:SetAllPoints()
  thumbTex:SetColorTexture(0.52, 0.5, 0.6, 0.88)
  thumb:SetNormalTexture(thumbTex)
  local thumbHi = thumb:CreateTexture(nil, "HIGHLIGHT")
  thumbHi:SetAllPoints()
  thumbHi:SetColorTexture(0.62, 0.58, 0.72, 0.55)
  thumb:SetHighlightTexture(thumbHi)
  thumb:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
  f.lfgScrollBar = sBar
  f.lfgScrollThumb = thumb

  local function syncLfgScroll()
    if not scroll:IsShown() or not root:IsShown() then
      sBar:Hide()
      thumb:Hide()
      return
    end
    local ch = child:GetHeight() or 0
    local sh = scroll:GetHeight() or 1
    local maxV = math.max(0, ch - sh)
    local cur = scroll:GetVerticalScroll() or 0
    if cur > maxV then
      cur = maxV
      scroll:SetVerticalScroll(cur)
    end
    if maxV > 0.5 then
      sBar:Show()
      local trackH = sBar:GetHeight() or 1
      local thumbH = math.min(trackH, math.max(24, math.floor(trackH * sh / math.max(ch, 1))))
      if thumbH > trackH then
        thumbH = trackH
      end
      thumb:SetHeight(thumbH)
      local range = math.max(1e-6, trackH - thumbH)
      local yFromTop = (maxV > 0) and ((cur / maxV) * range) or 0
      thumb:ClearAllPoints()
      local lx = math.max(0, (sBar:GetWidth() - thumb:GetWidth()) / 2)
      thumb:SetPoint("TOPLEFT", sBar, "TOPLEFT", lx, -yFromTop)
      thumb:Show()
    else
      sBar:Hide()
      thumb:Hide()
    end
  end
  f.cefSyncLfgScroll = syncLfgScroll
  scroll:SetScript("OnVerticalScroll", syncLfgScroll)
  sBar:EnableMouseWheel(true)
  sBar:SetScript("OnMouseWheel", onLfgWheel)

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
      local scale = sBar:GetEffectiveScale() or 1
      if scale < 0.01 then
        scale = 1
      end
      local deltaPx = (btn.cefLastCursorY - cy) / scale
      btn.cefLastCursorY = cy
      local ch = child:GetHeight() or 0
      local sh = scroll:GetHeight() or 1
      local maxS = math.max(0, ch - sh)
      local trackH = sBar:GetHeight() or 1
      local thumbH = btn:GetHeight() or 24
      local range = math.max(1e-6, trackH - thumbH)
      local scrollDelta = (deltaPx / range) * maxS
      local v = (scroll:GetVerticalScroll() or 0) + scrollDelta
      if v < 0 then
        v = 0
      end
      if v > maxS then
        v = maxS
      end
      scroll:SetVerticalScroll(v)
      GUI.refresh()
    end)
  end)
  thumb:SetScript("OnMouseUp", function(self)
    self.cefDragging = false
    self:SetScript("OnUpdate", nil)
  end)
  scroll:SetScript("OnShow", function()
    scroll:SetScript("OnUpdate", function(self)
      self:SetScript("OnUpdate", nil)
      syncLfgScroll()
    end)
  end)

  local emptyFs = scroll:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyFs:SetPoint("CENTER", scroll, "CENTER", 0, 0)
  emptyFs:SetWidth(420)
  emptyFs:SetJustifyH("CENTER")
  emptyFs:SetText(CEF.L.LFG_NO_RESULTS)
  f.lfgEmpty = emptyFs

  if CEF.LFG and CEF.LFG.onChanged then
    CEF.LFG.onChanged(function()
      if root:IsShown() then
        GUI.refresh()
      end
    end)
  end

  refreshCategoryLabel()
  layoutHeader(header, scroll)
  updateSearchPh()
  return root
end

function GUI.refreshLocale(f)
  f = f or (CEF.UI and CEF.UI.mainFrame)
  if not f or not f.lfgRoot then
    return
  end
  if f.lfgSearchPlaceholder then
    f.lfgSearchPlaceholder:SetText(CEF.L.LFG_SEARCH_PLACEHOLDER)
  end
  if f.lfgActivitySearchPlaceholder then
    f.lfgActivitySearchPlaceholder:SetText(CEF.L.FILTER_INSTANCE_SEARCH or "Search instance…")
  end
  if f.lfgRefreshBtn and f.lfgRefreshBtn.fs then
    f.lfgRefreshBtn.fs:SetText(CEF.L.LFG_REFRESH)
  end
  if f.lfgResetBtn and f.lfgResetBtn.fs then
    f.lfgResetBtn.fs:SetText(CEF.L.RESET)
  end
  if f.lfgHeaderActivity then
    f.lfgHeaderActivity:SetText(CEF.L.LFG_COL_ACTIVITY)
  end
  if f.lfgHeaderLeader then
    f.lfgHeaderLeader:SetText(CEF.L.LFG_COL_LEADER)
  end
  if f.lfgHeaderTime then
    f.lfgHeaderTime:SetText(CEF.L.COL_TIME)
  end
  if f.lfgHeaderRoles then
    f.lfgHeaderRoles:SetText(CEF.L.LFG_COL_ROLES)
  end
  if f.lfgHeaderAction then
    f.lfgHeaderAction:SetText(CEF.L.COL_ACTION)
  end
  if f.lfgRefreshCategoryLabel then
    f.lfgRefreshCategoryLabel()
  end
  if f.lfgRefreshActivityLabel then
    f.lfgRefreshActivityLabel()
  end
  GUI.refresh()
end
