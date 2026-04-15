-- Módulo: criação da UI principal (header, busca, dropdowns e scroll)
-- Exposto em ClassicEraFinder.UI.createMainUI

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UI = CEF.UI or {}

function CEF.UI.createMainUI()
  if CEF.UI.mainFrame then
    return CEF.UI.mainFrame
  end

  local CC = CEF.CONST
  local function st()
    CEF.state = CEF.state or {}
    return CEF.state
  end

  -- Dimensões do painel de filtros/dropdowns (mantidas iguais ao código anterior)
  local FILTER_MENU_ROW_H = 22
  local FILTER_MENU_MAX_ROWS = 72
  local INTENT_FILTER_MENU_MAX_ROWS = 8
  local ROLE_FILTER_MENU_MAX_ROWS = 8
  local FILTER_INSTANCE_DROPDOWN_W = 196
  local FILTER_INTENT_DROPDOWN_W = 212
  local FILTER_ROLE_DROPDOWN_W = 168
  local FILTER_RESET_BTN_W = 88
  local SEARCH_EDIT_W = 220
  local SEARCH_EDIT_H = 26
  local FILTER_SEARCH_INSTANCE_GAP = 10

  local scrollFrame
  local scrollChild

  local f = CreateFrame("Frame", "ClassicEraFinderMain", UIParent)
  f:SetSize(960, 562)
  f:SetPoint("CENTER")
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:Hide()

  local border = f:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(0.02, 0.02, 0.03, 0.97)

  local titleBar = CreateFrame("Frame", nil, f)
  titleBar:SetHeight(28)
  titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
  titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
  titleBar:EnableMouse(true)
  titleBar:RegisterForDrag("LeftButton")
  titleBar:SetScript("OnDragStart", function()
    f:StartMoving()
  end)
  titleBar:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
  end)
  local tbTex = titleBar:CreateTexture(nil, "BACKGROUND")
  tbTex:SetAllPoints()
  tbTex:SetColorTexture(0.15, 0.12, 0.08, 1)

  local L = CEF.L or {}
  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
  title:SetText(L["addonTitle"] or "Classic Era Finder")

  local close = CreateFrame("Button", nil, titleBar)
  close:SetSize(22, 22)
  close:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
  local closeFs = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  closeFs:SetAllPoints()
  closeFs:SetText("×")
  close:SetScript("OnClick", function()
    CEF.UIUtils.cefTooltipHide()
    if f.cefApplyNavTab then
      f.cefApplyNavTab("list")
    end
    CEF.UIFilters.hideAllFilterDropdowns(f)
    if f.cefLeaveFullscreenIfNeeded then
      f.cefLeaveFullscreenIfNeeded()
    end
    f:Hide()
    if CEF.UI.uiTicker then
      CEF.UI.uiTicker:Hide()
    end
  end)

  local NAV_H = 30
  local TAB_BTN_W = 132
  local TAB_BTN_H = 24

  local navBar = CreateFrame("Frame", nil, f)
  navBar:SetHeight(NAV_H)
  navBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -4)
  navBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -4)
  local navBg = navBar:CreateTexture(nil, "BACKGROUND")
  navBg:SetAllPoints()
  navBg:SetColorTexture(0.06, 0.055, 0.07, 0.98)

  local function makeNavTabButton(parent, xOff, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(TAB_BTN_W, TAB_BTN_H)
    b:SetPoint("LEFT", parent, "LEFT", xOff, 0)
    local tbg = b:CreateTexture(nil, "BACKGROUND")
    tbg:SetAllPoints()
    tbg:SetColorTexture(0.12, 0.1, 0.08, 0.95)
    b.bgTex = tbg
    local tfs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tfs:SetAllPoints()
    tfs:SetText(label)
    b.fs = tfs
    return b
  end

  local btnLista = makeNavTabButton(navBar, 10, L["tabList"] or "List")
  local btnTermos = makeNavTabButton(navBar, 10 + TAB_BTN_W + 6, L["tabTerms"] or "Terms")
  f.cefNavBar = navBar
  f.cefBtnLista = btnLista
  f.cefBtnTermos = btnTermos

  local filterBar = CreateFrame("Frame", nil, f)
  filterBar:SetHeight(SEARCH_EDIT_H + 14)
  filterBar:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  filterBar:SetPoint("TOPRIGHT", navBar, "BOTTOMRIGHT", 0, -4)
  filterBar:EnableMouse(true)
  local fbBg = filterBar:CreateTexture(nil, "BACKGROUND")
  fbBg:SetAllPoints()
  fbBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)

  local searchBorder = CreateFrame("Frame", nil, filterBar)
  searchBorder:SetSize(SEARCH_EDIT_W, SEARCH_EDIT_H)
  searchBorder:SetPoint("TOPLEFT", filterBar, "TOPLEFT", 10, -7)
  searchBorder:EnableMouse(true)
  local sbd = searchBorder:CreateTexture(nil, "BACKGROUND")
  sbd:SetAllPoints()
  sbd:SetColorTexture(0.04, 0.04, 0.05, 1)

  local searchPlaceholder = searchBorder:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  searchPlaceholder:SetPoint("LEFT", searchBorder, "LEFT", 6, 0)
  searchPlaceholder:SetPoint("RIGHT", searchBorder, "RIGHT", -6, 0)
  searchPlaceholder:SetJustifyH("LEFT")
  searchPlaceholder:SetText(L["searchPlaceholder"] or "Search name or instance...")

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
  searchEdit:SetScript("OnEditFocusGained", function()
    updateSearchPlaceholder()
  end)
  searchEdit:SetScript("OnEditFocusLost", function()
    updateSearchPlaceholder()
  end)
  searchEdit:SetScript("OnTextChanged", function(self)
    local t = self:GetText() or ""
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    st().filterSearchText = strlower(t)
    if scrollFrame then
      scrollFrame:SetVerticalScroll(0)
    end
    CEF.UI.refreshUI()
    updateSearchPlaceholder()
  end)
  updateSearchPlaceholder()

  -- ============================================================================
  -- Dropdowns (instância / intenção / função) — construídos via fábrica genérica
  -- em CEF.UIDropdown. Antes, cada um tinha ~170 linhas de botão + menu + scroll
  -- + pool de rows duplicadas.
  -- ============================================================================
  local instDD = CEF.UIDropdown.build({
    parent          = f,
    anchorParent    = filterBar,
    anchorTo        = searchBorder,
    anchorPoint     = "TOPRIGHT",
    anchorOffset    = FILTER_SEARCH_INSTANCE_GAP,
    width           = FILTER_INSTANCE_DROPDOWN_W,
    height          = SEARCH_EDIT_H,
    rowHeight       = FILTER_MENU_ROW_H,
    frameLevel      = 500,
    maxRowPool      = FILTER_MENU_MAX_ROWS,
    maxVisibleRows  = 11,
    supportsHeaders = true,
    getOptions      = function() return CEF.INSTANCE_FILTER_MENU_OPTS end,
    renderRow       = function(opt) return CEF.instanceFilterOptionRichText(opt.key) end,
    renderSummary   = function() return CEF.instanceFilterOptionRichText(st().filterInstanceKey) end,
    onOpen          = function()
      CEF.UIFilters.hideFilterIntentMenu(f)
      CEF.UIFilters.hideFilterRoleMenu(f)
    end,
    onSelect        = function(opt, ctx)
      st().filterInstanceKey = opt.key
      ctx.updateSummary()
      CEF.UIFilters.hideAllFilterDropdowns(f)
      if scrollFrame then scrollFrame:SetVerticalScroll(0) end
      CEF.UI.refreshUI()
    end,
  })
  local dropBtn = instDD.button
  local filterDropSummaryFS = instDD.summaryFS
  f.filterInstanceMenu = instDD.menu

  local intentDD = CEF.UIDropdown.build({
    parent          = f,
    anchorParent    = filterBar,
    anchorTo        = dropBtn,
    anchorPoint     = "TOPRIGHT",
    anchorOffset    = FILTER_SEARCH_INSTANCE_GAP,
    width           = FILTER_INTENT_DROPDOWN_W,
    height          = SEARCH_EDIT_H,
    rowHeight       = FILTER_MENU_ROW_H,
    frameLevel      = 502,
    maxRowPool      = INTENT_FILTER_MENU_MAX_ROWS,
    maxVisibleRows  = 6,
    supportsHeaders = false,
    getOptions      = function() return CEF.INTENT_FILTER_MENU_OPTS end,
    renderRow       = function(opt) return opt.label end,
    renderSummary   = function() return CEF.intentFilterOptionRichText(st().filterIntentKey) end,
    onOpen          = function()
      CEF.UIFilters.hideFilterInstanceMenu(f)
      CEF.UIFilters.hideFilterRoleMenu(f)
    end,
    onSelect        = function(opt, ctx)
      st().filterIntentKey = opt.key
      ctx.updateSummary()
      CEF.UIFilters.hideFilterIntentMenu(f)
      if scrollFrame then scrollFrame:SetVerticalScroll(0) end
      CEF.UI.refreshUI()
    end,
  })
  local intentDropBtn = intentDD.button
  local filterIntentDropSummaryFS = intentDD.summaryFS
  f.filterIntentMenu = intentDD.menu

  local roleDD = CEF.UIDropdown.build({
    parent          = f,
    anchorParent    = filterBar,
    anchorTo        = intentDropBtn,
    anchorPoint     = "TOPRIGHT",
    anchorOffset    = FILTER_SEARCH_INSTANCE_GAP,
    width           = FILTER_ROLE_DROPDOWN_W,
    height          = SEARCH_EDIT_H,
    rowHeight       = FILTER_MENU_ROW_H,
    frameLevel      = 504,
    maxRowPool      = ROLE_FILTER_MENU_MAX_ROWS,
    maxVisibleRows  = 6,
    supportsHeaders = false,
    getOptions      = function() return CEF.ROLE_FILTER_MENU_OPTS end,
    renderRow       = function(opt) return opt.label end,
    renderSummary   = function() return CEF.roleFilterOptionRichText(st().filterRoleKey) end,
    onOpen          = function()
      CEF.UIFilters.hideFilterInstanceMenu(f)
      CEF.UIFilters.hideFilterIntentMenu(f)
    end,
    onSelect        = function(opt, ctx)
      st().filterRoleKey = opt.key
      ctx.updateSummary()
      CEF.UIFilters.hideFilterRoleMenu(f)
      if scrollFrame then scrollFrame:SetVerticalScroll(0) end
      CEF.UI.refreshUI()
    end,
  })
  local roleDropBtn = roleDD.button
  local filterRoleDropSummaryFS = roleDD.summaryFS
  f.filterRoleMenu = roleDD.menu


  local resetFiltersBtn = CreateFrame("Button", nil, filterBar)
  resetFiltersBtn:SetSize(FILTER_RESET_BTN_W, SEARCH_EDIT_H)
  resetFiltersBtn:SetPoint("TOPLEFT", roleDropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)
  local resetBg = resetFiltersBtn:CreateTexture(nil, "BACKGROUND")
  resetBg:SetAllPoints()
  resetBg:SetColorTexture(0.14, 0.1, 0.08, 1)
  local resetFs = resetFiltersBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  resetFs:SetAllPoints()
  resetFs:SetText(L["resetButton"] or "Reset")
  resetFiltersBtn:SetScript("OnEnter", function()
    resetBg:SetColorTexture(0.22, 0.16, 0.1, 1)
  end)
  resetFiltersBtn:SetScript("OnLeave", function()
    resetBg:SetColorTexture(0.14, 0.1, 0.08, 1)
  end)
  resetFiltersBtn:SetScript("OnClick", function()
    CEF.UIFilters.hideAllFilterDropdowns(f)
    st().filterInstanceKey = false
    st().filterIntentKey = false
    st().filterRoleKey = false
    st().filterSearchText = ""
    CEF.UIFilters.updateFilterDropSummary(filterDropSummaryFS, false)
    CEF.UIFilters.updateIntentFilterDropSummary(filterIntentDropSummaryFS, false)
    CEF.UIFilters.updateRoleFilterDropSummary(filterRoleDropSummaryFS, false)
    searchEdit:SetText("")
    searchEdit:ClearFocus()
    updateSearchPlaceholder()
    if scrollFrame then
      scrollFrame:SetVerticalScroll(0)
    end
    CEF.UI.refreshUI()
  end)

  local header = CreateFrame("Frame", nil, f)
  header:SetHeight(20)
  header:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 0, -4)
  header:SetPoint("TOPRIGHT", filterBar, "BOTTOMRIGHT", 0, -4)
  header:EnableMouse(true)

  local hTex = header:CreateTexture(nil, "BACKGROUND")
  hTex:SetAllPoints()
  hTex:SetColorTexture(0.2, 0.18, 0.12, 0.95)

  header.h1 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h2 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h3 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h4 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h5 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.h6 = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

  header.h1:SetJustifyH("LEFT")
  header.h2:SetJustifyH("LEFT")
  header.h3:SetJustifyH("LEFT")
  header.h4:SetJustifyH("LEFT")
  header.h5:SetJustifyH("LEFT")
  header.h6:SetJustifyH("LEFT")

  header.h1:SetText(L["colInstance"] or "Instance / levels")
  header.h2:SetText(L["colEra"] or "Era")
  header.h3:SetText(L["colMessage"] or "Message")
  header.h4:SetText(L["colCharacter"] or "Character")
  header.h5:SetText(L["colTime"] or "Time")
  header.h6:SetText(L["colAction"] or "Action")

  -- Mesmo recuo à direita para Lista e Termos (conteúdo + faixa da barra).
  local LIST_SCROLLBAR_GAP = 18
  local RIGHT_EDGE_INSET = 2
  local RIGHT_SCROLL_OUTSET = RIGHT_EDGE_INSET + LIST_SCROLLBAR_GAP
  scrollFrame = CreateFrame("ScrollFrame", nil, f)
  scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, 8)
  scrollFrame:EnableMouse(true)
  CEF.UI.scrollFrame = scrollFrame

  scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(scrollFrame:GetWidth())
  scrollChild:SetHeight(400)
  scrollChild:EnableMouse(true)
  scrollFrame:SetScrollChild(scrollChild)
  CEF.UI.scrollChild = scrollChild

  local function onListScrollMouseWheel(_, delta)
    CEF.Entries.rebuildFilteredView()
    local filteredView = CEF.Entries.getFilteredView()
    local n = #filteredView
    local totalH = 1
    for i = 1, n do
      totalH = totalH + CEF.UILayout.entryRowTotalHeight(filteredView[i]) or CC.ROW_HEIGHT
    end

    local viewH = scrollFrame:GetHeight() or CC.ROW_HEIGHT
    local maxScroll = math.max(0, totalH - viewH)
    local step = viewH * 0.75
    local vs = scrollFrame:GetVerticalScroll()
    if delta > 0 then
      vs = math.max(0, vs - step)
    else
      vs = math.min(maxScroll, vs + step)
    end
    scrollFrame:SetVerticalScroll(vs)
    CEF.UI.refreshUI()
  end

  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", onListScrollMouseWheel)

  -- Barra vertical da lista: canal à direita (não sobrepõe as linhas da tabela).
  local listSBar = CreateFrame("Frame", nil, f)
  listSBar:SetWidth(12)
  listSBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, 0)
  listSBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 0)
  listSBar:EnableMouse(true)
  listSBar:SetFrameLevel((scrollFrame:GetFrameLevel() or 0) + 8)
  listSBar:Hide()

  local listTrack = listSBar:CreateTexture(nil, "BACKGROUND")
  listTrack:SetAllPoints()
  listTrack:SetColorTexture(0.04, 0.035, 0.07, 0.96)

  local listSBarThumb = CreateFrame("Button", nil, listSBar)
  listSBarThumb:SetWidth(10)
  listSBarThumb:SetHeight(32)
  listSBarThumb:SetFrameLevel((listSBar:GetFrameLevel() or 0) + 3)
  local listThumbTex = listSBarThumb:CreateTexture(nil, "ARTWORK")
  listThumbTex:SetAllPoints()
  listThumbTex:SetColorTexture(0.52, 0.5, 0.6, 0.88)
  listSBarThumb:SetNormalTexture(listThumbTex)
  local listThumbHi = listSBarThumb:CreateTexture(nil, "HIGHLIGHT")
  listThumbHi:SetAllPoints()
  listThumbHi:SetColorTexture(0.62, 0.58, 0.72, 0.55)
  listSBarThumb:SetHighlightTexture(listThumbHi)

  listSBar:EnableMouseWheel(true)
  listSBar:SetScript("OnMouseWheel", onListScrollMouseWheel)

  local function syncListScrollbar()
    if not scrollFrame:IsShown() then
      listSBar:Hide()
      listSBarThumb:Hide()
      return
    end
    local ch = scrollChild:GetHeight() or 0
    local sh = scrollFrame:GetHeight() or 1
    local maxV = math.max(0, ch - sh)
    local cur = scrollFrame:GetVerticalScroll() or 0
    if cur > maxV then
      cur = maxV
      scrollFrame:SetVerticalScroll(cur)
    end
    if maxV > 0.5 then
      listSBar:Show()
      local trackH = listSBar:GetHeight() or 1
      local thumbH = math.min(trackH, math.max(24, math.floor(trackH * sh / math.max(ch, 1))))
      if thumbH > trackH then
        thumbH = trackH
      end
      listSBarThumb:SetHeight(thumbH)
      local range = math.max(1e-6, trackH - thumbH)
      local yFromTop = (maxV > 0) and ((cur / maxV) * range) or 0
      listSBarThumb:ClearAllPoints()
      local lx = math.max(0, (listSBar:GetWidth() - listSBarThumb:GetWidth()) / 2)
      listSBarThumb:SetPoint("TOPLEFT", listSBar, "TOPLEFT", lx, -yFromTop)
      listSBarThumb:Show()
    else
      listSBar:Hide()
      listSBarThumb:Hide()
    end
  end

  scrollFrame:SetScript("OnVerticalScroll", function()
    syncListScrollbar()
  end)

  listSBarThumb:SetScript("OnMouseDown", function(self, button)
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
      local scale = listSBar:GetEffectiveScale() or 1
      if scale < 0.01 then
        scale = 1
      end
      local deltaPx = (btn.cefLastCursorY - cy) / scale
      btn.cefLastCursorY = cy
      local ch = scrollChild:GetHeight() or 0
      local sh = scrollFrame:GetHeight() or 1
      local maxS = math.max(0, ch - sh)
      local trackH = listSBar:GetHeight() or 1
      local thumbH = btn:GetHeight() or 24
      local range = math.max(1e-6, trackH - thumbH)
      local scrollDelta = (deltaPx / range) * maxS
      local v = (scrollFrame:GetVerticalScroll() or 0) + scrollDelta
      if v < 0 then
        v = 0
      end
      if v > maxS then
        v = maxS
      end
      scrollFrame:SetVerticalScroll(v)
      CEF.UI.refreshUI()
    end)
  end)

  listSBarThumb:SetScript("OnMouseUp", function(self)
    self.cefDragging = false
    self:SetScript("OnUpdate", nil)
  end)

  scrollFrame:SetScript("OnShow", function()
    scrollFrame:SetScript("OnUpdate", function(self)
      self:SetScript("OnUpdate", nil)
      syncListScrollbar()
    end)
  end)

  f.cefSyncListScroll = syncListScrollbar

  f.header = header

  -- ============================================================================
  -- Aba “Termos”: construída pela fábrica em CEF.UITerms. Retorna as regiões
  -- usadas abaixo (frame levels, tab switching) e as funções de relayout/sync.
  -- Antes: ~540 linhas inline aqui em createMainUI.
  -- ============================================================================
  local terms = CEF.UITerms.build(f, navBar, {
    rightScrollOutset = RIGHT_SCROLL_OUTSET,
  })
  local settingsTopPanel         = terms.settingsTopPanel
  local settingsTermsTableHeader = terms.settingsTermsTableHeader
  local settingsScroll           = terms.settingsScroll
  local settingsSBar             = terms.settingsSBar
  local settingsSBarThumb        = terms.settingsSBarThumb

  -- Clique na área da janela fora dos dropdowns fecha os menus (menus em TOOLTIP ficam por cima do painel).
  local dropBlocker = CreateFrame("Button", nil, f)
  dropBlocker:Hide()
  dropBlocker:SetAllPoints(f)
  dropBlocker:SetFrameStrata("MEDIUM")
  dropBlocker:SetFrameLevel(130)
  local dbTex = dropBlocker:CreateTexture(nil, "BACKGROUND")
  dbTex:SetAllPoints()
  dbTex:SetColorTexture(0, 0, 0, 0.001)
  dropBlocker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  dropBlocker:EnableMouse(true)
  dropBlocker:SetScript("OnClick", function()
    CEF.UIFilters.hideAllFilterDropdowns(f)
  end)
  f.cefFilterDropBlocker = dropBlocker

  titleBar:SetFrameLevel(240)
  navBar:SetFrameLevel(240)
  filterBar:SetFrameLevel(240)
  header:SetFrameLevel(50)
  scrollFrame:SetFrameLevel(50)
  settingsTopPanel:SetFrameLevel(55)
  settingsTermsTableHeader:SetFrameLevel(50)
  settingsScroll:SetFrameLevel(50)
  listSBar:SetFrameLevel((scrollFrame:GetFrameLevel() or 0) + 8)
  listSBarThumb:SetFrameLevel((listSBar:GetFrameLevel() or 0) + 3)
  settingsSBar:SetFrameLevel((settingsScroll:GetFrameLevel() or 0) + 8)
  settingsSBarThumb:SetFrameLevel((settingsSBar:GetFrameLevel() or 0) + 3)

  local function syncTableLayout()
    if scrollFrame and scrollChild then
      scrollChild:SetWidth(scrollFrame:GetWidth())
    end
    CEF.UILayout.layoutHeaderColumns(header)
    CEF.UI.refreshUI()
    if f.cefNavTab == "list" and f.cefSyncListScroll then
      f.cefSyncListScroll()
    end
  end

  local function styleNavTab(btn, active)
    if active then
      btn.bgTex:SetColorTexture(0.24, 0.19, 0.12, 1)
      btn.fs:SetTextColor(1, 0.9, 0.42)
    else
      btn.bgTex:SetColorTexture(0.1, 0.09, 0.08, 0.92)
      btn.fs:SetTextColor(0.62, 0.58, 0.52)
    end
  end

  local function applyNavTab(which)
    f.cefNavTab = which
    local isList = which == "list"
    styleNavTab(btnLista, isList)
    styleNavTab(btnTermos, not isList)
    if isList then
      filterBar:Show()
      header:Show()
      scrollFrame:Show()
      settingsTopPanel:Hide()
      settingsTermsTableHeader:Hide()
      settingsScroll:Hide()
    else
      CEF.UIFilters.hideAllFilterDropdowns(f)
      filterBar:Hide()
      header:Hide()
      scrollFrame:Hide()
      settingsTopPanel:Show()
      settingsTermsTableHeader:Show()
      settingsScroll:Show()
    end
    if isList then
      syncTableLayout()
      scrollFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        if f.cefSyncListScroll then
          f.cefSyncListScroll()
        end
      end)
    else
      settingsScroll:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        if f.cefRelayoutSettingsTerms then
          f.cefRelayoutSettingsTerms()
        elseif f.cefSyncSettingsScroll then
          f.cefSyncSettingsScroll()
        end
      end)
    end
    -- Esconde a barra da aba inativa (evita sobreposição Lista/Termos).
    if f.cefSyncListScroll then
      f.cefSyncListScroll()
    end
    if f.cefSyncSettingsScroll then
      f.cefSyncSettingsScroll()
    end
  end

  btnLista:SetScript("OnClick", function()
    applyNavTab("list")
  end)
  btnTermos:SetScript("OnClick", function()
    applyNavTab("settings")
  end)
  f.cefApplyNavTab = applyNavTab
  applyNavTab("list")

  f.cefIsFullscreen = false
  local fullscreenBtn = CreateFrame("Button", nil, titleBar)
  fullscreenBtn:SetSize(30, 22)
  fullscreenBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
  local fullBg = fullscreenBtn:CreateTexture(nil, "BACKGROUND")
  fullBg:SetAllPoints()
  fullBg:SetColorTexture(0.1, 0.08, 0.06, 0.65)
  local fullFs = fullscreenBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fullFs:SetAllPoints()
  fullFs:SetTextColor(0.95, 0.82, 0.45)
  fullFs:SetText("FS")
  local function setFullscreenBtnLook(isFs)
    fullFs:SetText(isFs and "JL" or "FS")
  end
  fullscreenBtn:SetScript("OnEnter", function()
    fullBg:SetColorTexture(0.16, 0.12, 0.09, 0.85)
  end)
  fullscreenBtn:SetScript("OnLeave", function()
    fullBg:SetColorTexture(0.1, 0.08, 0.06, 0.65)
  end)

  local function saveWindowedGeometry()
    local pts = {}
    local n = f.GetNumPoints and f:GetNumPoints() or 0
    if n > 0 then
      for i = 1, n do
        pts[#pts + 1] = { f:GetPoint(i) }
      end
    else
      local p1, r, rp, x, y = f:GetPoint(1)
      if p1 then
        pts[1] = { p1, r, rp, x, y }
      end
    end
    f.cefRestoreGeom = {
      w = f:GetWidth(),
      h = f:GetHeight(),
      points = pts,
    }
  end

  local function enterFullscreenMode()
    saveWindowedGeometry()
    f:ClearAllPoints()
    f:SetAllPoints(UIParent)
    f:SetFrameStrata("HIGH")
    f:SetMovable(false)
    titleBar:SetScript("OnDragStart", nil)
    titleBar:SetScript("OnDragStop", nil)
    f.cefIsFullscreen = true
    setFullscreenBtnLook(true)
    syncTableLayout()
    if f.cefRelayoutSettingsTerms then
      f.cefRelayoutSettingsTerms()
    end
    if f.cefNavTab == "list" and f.cefSyncListScroll then
      f.cefSyncListScroll()
    end
  end

  local function leaveFullscreenMode()
    f:ClearAllPoints()
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    titleBar:SetScript("OnDragStart", function()
      f:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
      f:StopMovingOrSizing()
    end)
    local g = f.cefRestoreGeom
    if g and g.points and #g.points > 0 then
      for i = 1, #g.points do
        local pt = g.points[i]
        f:SetPoint(unpack(pt))
      end
      f:SetWidth(g.w)
      f:SetHeight(g.h)
    else
      f:SetSize(960, 562)
      f:SetPoint("CENTER")
    end
    f.cefIsFullscreen = false
    setFullscreenBtnLook(false)
    syncTableLayout()
    if f.cefRelayoutSettingsTerms then
      f.cefRelayoutSettingsTerms()
    end
    if f.cefNavTab == "list" and f.cefSyncListScroll then
      f.cefSyncListScroll()
    end
  end

  f.cefLeaveFullscreenIfNeeded = function()
    if f.cefIsFullscreen then
      leaveFullscreenMode()
    end
  end

  fullscreenBtn:SetScript("OnClick", function()
    if f.cefIsFullscreen then
      leaveFullscreenMode()
    else
      enterFullscreenMode()
    end
  end)

  f:SetScript("OnSizeChanged", function()
    terms.layoutTopPanel()
    syncTableLayout()
    if f.cefRelayoutSettingsTerms then
      f.cefRelayoutSettingsTerms()
    end
  end)

  CEF.UI.uiTicker = CreateFrame("Frame", nil, f)
  CEF.UI.uiTicker:Hide()
  local acc = 0
  CEF.UI.uiTicker:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc >= 1 then
      acc = 0
      if f:IsShown() then
        CEF.UI.refreshRelativeTimesOnly()
      end
    end
  end)

  CEF.UI.mainFrame = f

  local cefUiBoot = CreateFrame("Frame", nil, UIParent)
  cefUiBoot:SetSize(1, 1)
  cefUiBoot:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
  cefUiBoot:Hide()
  local function scheduleUiLayoutSync()
    cefUiBoot:Show()
    cefUiBoot:SetScript("OnUpdate", function(s)
      s:SetScript("OnUpdate", nil)
      s:Hide()
      if f.cefSyncListScroll and f.cefNavTab == "list" then
        f.cefSyncListScroll()
      end
      if f.cefRelayoutSettingsTerms and f.cefNavTab == "settings" then
        f.cefRelayoutSettingsTerms()
      end
    end)
  end
  f:HookScript("OnShow", scheduleUiLayoutSync)

  terms.layoutTopPanel()
  -- Primeira sincronização (alinha cabeçalho e renderiza)
  syncTableLayout()
  scheduleUiLayoutSync()
  return f
end

