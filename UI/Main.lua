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
  -- Classic + TBC normal/heroic/raids + cabeçalhos; precisa de folga.
  local FILTER_MENU_MAX_ROWS = 130
  local INTENT_FILTER_MENU_MAX_ROWS = 8
  local ROLE_FILTER_MENU_MAX_ROWS = 8
  local FILTER_INSTANCE_DROPDOWN_W = 196
  local FILTER_INTENT_DROPDOWN_W = 212
  local FILTER_ROLE_DROPDOWN_W = 168
  local FILTER_RESET_BTN_W = 88
  local SEARCH_EDIT_W = 220
  local SEARCH_EDIT_H = 26
  local FILTER_SEARCH_INSTANCE_GAP = 10

  local filterMenuRows = {}
  local intentFilterMenuRows = {}
  local roleFilterMenuRows = {}

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

  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
  title:SetText("Classic Era Finder")

  local close = CreateFrame("Button", nil, titleBar)
  close:SetSize(22, 22)
  close:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
  local closeFs = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  closeFs:SetAllPoints()
  closeFs:SetText("×")

  local function closeMainWindow()
    CEF.UIUtils.cefTooltipHide()
    if f.cefApplyNavTab then
      f.cefApplyNavTab("home")
    end
    CEF.UIFilters.hideAllFilterDropdowns(f)
    if f.cefLeaveFullscreenIfNeeded then
      f.cefLeaveFullscreenIfNeeded()
    end
    f:Hide()
    if CEF.UI.uiTicker then
      CEF.UI.uiTicker:Hide()
    end
  end

  close:SetScript("OnClick", closeMainWindow)

  -- ESC: fecha dropdown aberto primeiro; senão fecha a janela (sem abrir o menu do jogo).
  f:SetScript("OnKeyDown", function(self, key)
    if key ~= "ESCAPE" then
      if self.SetPropagateKeyboardInput then
        self:SetPropagateKeyboardInput(true)
      end
      return
    end
    if self.SetPropagateKeyboardInput then
      self:SetPropagateKeyboardInput(false)
    end
    if CEF.UIFilters.anyFilterMenuShown(self) then
      CEF.UIFilters.hideAllFilterDropdowns(self)
      return
    end
    closeMainWindow()
  end)
  f:HookScript("OnShow", function(self)
    self:EnableKeyboard(true)
    if self.SetPropagateKeyboardInput then
      self:SetPropagateKeyboardInput(true)
    end
  end)
  f:HookScript("OnHide", function(self)
    self:EnableKeyboard(false)
  end)

  local NAV_H = 30
  local TAB_BTN_W = 88
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
    if xOff ~= nil then
      b:SetPoint("LEFT", parent, "LEFT", xOff, 0)
    end
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

  local btnHome = makeNavTabButton(navBar, 8, CEF.L.TAB_HOME or "Home")
  local btnLista = makeNavTabButton(navBar, 8 + (TAB_BTN_W + 4) * 1, CEF.L.TAB_LIST)
  local btnLfg = makeNavTabButton(navBar, 8 + (TAB_BTN_W + 4) * 2, CEF.L.TAB_LFG)
  local btnGuilda = makeNavTabButton(navBar, 8 + (TAB_BTN_W + 4) * 3, CEF.L.TAB_GUILD)
  local btnMensagens = makeNavTabButton(navBar, 8 + (TAB_BTN_W + 4) * 4, CEF.L.TAB_MESSAGES)
  local btnGrupo = makeNavTabButton(navBar, 8 + (TAB_BTN_W + 4) * 5, CEF.L.TAB_GROUP)
  local btnTermos = makeNavTabButton(navBar, nil, CEF.L.TAB_TERMS)
  btnTermos:SetPoint("RIGHT", navBar, "RIGHT", -8, 0)
  f.cefNavBar = navBar
  f.cefBtnHome = btnHome
  f.cefBtnLista = btnLista
  f.cefBtnLfg = btnLfg
  f.cefBtnGuilda = btnGuilda
  f.cefBtnMensagens = btnMensagens
  f.cefBtnGrupo = btnGrupo
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
  searchPlaceholder:SetText(CEF.L.SEARCH_PLACEHOLDER_LIST)

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

  -- Forward decls: OnClick dos menus chama estes refresh antes da definição local.
  local refreshFilterMenuList
  local refreshIntentFilterMenuList
  local refreshRoleFilterMenuList

  local dropBtn = CreateFrame("Button", nil, filterBar)
  dropBtn:SetSize(FILTER_INSTANCE_DROPDOWN_W, SEARCH_EDIT_H)
  dropBtn:SetPoint("TOPLEFT", searchBorder, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)

  local dropBg = dropBtn:CreateTexture(nil, "BACKGROUND")
  dropBg:SetAllPoints()
  dropBg:SetColorTexture(0.11, 0.09, 0.07, 1)

  local filterDropSummaryFS = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  filterDropSummaryFS:SetPoint("LEFT", 8, 0)
  filterDropSummaryFS:SetPoint("RIGHT", dropBtn, "RIGHT", -22, 0)
  filterDropSummaryFS:SetJustifyH("LEFT")
  filterDropSummaryFS:SetText(CEF.instanceFilterOptionRichText(st().filterInstanceKeys))

  -- Seta custom (cima/baixo) — sem textura Blizzard.
  CEF.UIFilters.attachDropChevron(dropBtn, 16)
  f.cefDropInstanceBtn = dropBtn

  local filterMenu = CreateFrame("Frame", nil, f)
  filterMenu:SetWidth(FILTER_INSTANCE_DROPDOWN_W)
  filterMenu:SetFrameStrata("TOOLTIP")
  filterMenu:SetFrameLevel(500)
  filterMenu:EnableMouse(true)
  filterMenu:Hide()
  filterMenu:SetPoint("TOPLEFT", dropBtn, "BOTTOMLEFT", 0, -2)

  local mBg = filterMenu:CreateTexture(nil, "BACKGROUND")
  mBg:SetAllPoints()
  mBg:SetColorTexture(0.05, 0.048, 0.06, 0.99)

  local brM, bgM, bbM, baM = 0.55, 0.45, 0.18, 0.85
  local ez = 1
  local mt = filterMenu:CreateTexture(nil, "BORDER")
  mt:SetHeight(ez)
  mt:SetColorTexture(brM, bgM, bbM, baM)
  mt:SetPoint("TOPLEFT", filterMenu, "TOPLEFT", 0, 0)
  mt:SetPoint("TOPRIGHT", filterMenu, "TOPRIGHT", 0, 0)

  local mb = filterMenu:CreateTexture(nil, "BORDER")
  mb:SetHeight(ez)
  mb:SetColorTexture(brM, bgM, bbM, baM)
  mb:SetPoint("BOTTOMLEFT", filterMenu, "BOTTOMLEFT", 0, 0)
  mb:SetPoint("BOTTOMRIGHT", filterMenu, "BOTTOMRIGHT", 0, 0)

  local ml = filterMenu:CreateTexture(nil, "BORDER")
  ml:SetWidth(ez)
  ml:SetColorTexture(brM, bgM, bbM, baM)
  ml:SetPoint("TOPLEFT", filterMenu, "TOPLEFT", 0, 0)
  ml:SetPoint("BOTTOMLEFT", filterMenu, "BOTTOMLEFT", 0, 0)

  local mr = filterMenu:CreateTexture(nil, "BORDER")
  mr:SetWidth(ez)
  mr:SetColorTexture(brM, bgM, bbM, baM)
  mr:SetPoint("TOPRIGHT", filterMenu, "TOPRIGHT", 0, 0)
  mr:SetPoint("BOTTOMRIGHT", filterMenu, "BOTTOMRIGHT", 0, 0)

  local FILTER_MENU_SEARCH_H = 22
  local filterMenuSearchQ = ""
  local mSearchBorder = CreateFrame("Frame", nil, filterMenu)
  mSearchBorder:SetHeight(FILTER_MENU_SEARCH_H)
  mSearchBorder:SetPoint("TOPLEFT", filterMenu, "TOPLEFT", 6, -6)
  mSearchBorder:SetPoint("TOPRIGHT", filterMenu, "TOPRIGHT", -6, -6)
  local mSearchBg = mSearchBorder:CreateTexture(nil, "BACKGROUND")
  mSearchBg:SetAllPoints()
  mSearchBg:SetColorTexture(0.1, 0.09, 0.08, 1)
  local mSearchPh = mSearchBorder:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  mSearchPh:SetPoint("LEFT", mSearchBorder, "LEFT", 6, 0)
  mSearchPh:SetPoint("RIGHT", mSearchBorder, "RIGHT", -6, 0)
  mSearchPh:SetJustifyH("LEFT")
  mSearchPh:SetText(CEF.L.FILTER_INSTANCE_SEARCH or "Search instance…")
  local mSearchEdit = CreateFrame("EditBox", nil, mSearchBorder)
  mSearchEdit:SetFontObject(GameFontHighlightSmall)
  mSearchEdit:SetPoint("TOPLEFT", mSearchBorder, "TOPLEFT", 4, -2)
  mSearchEdit:SetPoint("BOTTOMRIGHT", mSearchBorder, "BOTTOMRIGHT", -4, 2)
  mSearchEdit:SetAutoFocus(false)
  mSearchEdit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  local function updateFilterMenuSearchPh()
    local tx = mSearchEdit:GetText() or ""
    if tx == "" and not mSearchEdit:HasFocus() then
      mSearchPh:Show()
    else
      mSearchPh:Hide()
    end
  end
  mSearchEdit:SetScript("OnEditFocusGained", updateFilterMenuSearchPh)
  mSearchEdit:SetScript("OnEditFocusLost", updateFilterMenuSearchPh)
  f.filterInstanceSearchEdit = mSearchEdit
  f.filterInstanceSearchPlaceholder = mSearchPh

  local mScroll = CreateFrame("ScrollFrame", nil, filterMenu)
  mScroll:SetPoint("TOPLEFT", filterMenu, "TOPLEFT", 4, -(8 + FILTER_MENU_SEARCH_H))
  mScroll:SetPoint("BOTTOMRIGHT", filterMenu, "BOTTOMRIGHT", -4, 4)
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

  for mi = 1, FILTER_MENU_MAX_ROWS do
    local row = CreateFrame("Button", nil, mChild)
    row:SetHeight(FILTER_MENU_ROW_H)
    row.isHeader = false
    local rb = row:CreateTexture(nil, "BACKGROUND")
    rb:SetAllPoints()
    rb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    row.bg = rb
    row:SetScript("OnEnter", function()
      if row.isHeader then
        return
      end
      CEF.UIFilters.applyFilterRowBg(row, true)
    end)
    row:SetScript("OnLeave", function()
      CEF.UIFilters.applyFilterRowBg(row, false)
    end)

    local rlab = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rlab:SetPoint("LEFT", row, "LEFT", CEF.UIFilters.filterCheckLabelLeft(), 0)
    rlab:SetJustifyH("LEFT")
    rlab:SetWidth(FILTER_INSTANCE_DROPDOWN_W - 24)
    row.label = rlab
    CEF.UIFilters.attachFilterRowCheck(row)

    row:SetScript("OnClick", function(self)
      if self.isHeader then
        return
      end
      local myLvl = CEF.FILTER_INSTANCE_MY_LEVEL
      if self.optionKey == false or self.optionKey == nil then
        st().filterInstanceKeys = CEF.filterSetClear()
      elseif self.optionKey == myLvl then
        if CEF.filterSetContains(st().filterInstanceKeys, myLvl) then
          st().filterInstanceKeys = CEF.filterSetClear()
        else
          st().filterInstanceKeys = { [myLvl] = true }
        end
      else
        local cur = CEF.normalizeFilterSet(st().filterInstanceKeys)
        cur[myLvl] = nil
        st().filterInstanceKeys = CEF.filterSetToggle(cur, self.optionKey)
      end
      CEF.UIFilters.updateFilterDropSummary(filterDropSummaryFS, st().filterInstanceKeys)
      refreshFilterMenuList()
      if scrollFrame then
        scrollFrame:SetVerticalScroll(0)
      end
      CEF.UI.refreshUI()
    end)

    filterMenuRows[mi] = row
    row:Hide()
  end

  refreshFilterMenuList = function()
    filterMenu:SetWidth(dropBtn:GetWidth())
    local mw = filterMenu:GetWidth()
    local labelW = math.max(40, mw - CEF.UIFilters.filterCheckLabelLeft() - 8)
    local allOpts = CEF.INSTANCE_FILTER_MENU_OPTS or {}
    local q = filterMenuSearchQ
    local opts = allOpts
    if q ~= "" then
      opts = {}
      local pendingHdr = nil
      local myLvl = CEF.FILTER_INSTANCE_MY_LEVEL
      for _, entry in ipairs(allOpts) do
        if entry.kind == "hdr" then
          pendingHdr = entry
        else
          local keep = false
          if entry.key == false or entry.key == nil or entry.key == myLvl then
            keep = true
          else
            local hay = ""
            if type(entry.key) == "string" then
              if CEF.instanceSearchHay then
                hay = CEF.instanceSearchHay(entry.key)
              else
                hay = strlower(entry.key)
                if CEF.getInstanceDisplayName then
                  hay = hay .. " " .. strlower(tostring(CEF.getInstanceDisplayName(entry.key) or ""))
                end
              end
            end
            keep = hay:find(q, 1, true) ~= nil
          end
          if keep then
            if pendingHdr then
              opts[#opts + 1] = pendingHdr
              pendingHdr = nil
            end
            opts[#opts + 1] = entry
          end
        end
      end
    end
    local selected = st().filterInstanceKeys
    local y = 0
    for i = 1, FILTER_MENU_MAX_ROWS do
      local row = filterMenuRows[i]
      if i <= #opts then
        local entry = opts[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", mChild, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", mChild, "TOPRIGHT", 0, -y)
        row:SetHeight(FILTER_MENU_ROW_H)
        row.label:SetWidth(labelW)
        if entry.kind == "hdr" then
          row.isHeader = true
          row.optionKey = nil
          row:EnableMouse(false)
          row.label:ClearAllPoints()
          row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
          row.label:SetTextColor(1, 0.82, 0.18)
          row.label:SetText((entry.textKey and CEF.L[entry.textKey]) or entry.text or "")
          CEF.UIFilters.setFilterRowChecked(row, false, false)
        else
          row.isHeader = false
          row:EnableMouse(true)
          row.optionKey = entry.key
          row.label:ClearAllPoints()
          row.label:SetPoint("LEFT", row, "LEFT", CEF.UIFilters.filterCheckLabelLeft(), 0)
          row.label:SetTextColor(1, 1, 1)
          row.label:SetText(CEF.instanceFilterOptionRichText(entry.key))
          CEF.UIFilters.setFilterRowChecked(row, CEF.filterSetContains(selected, entry.key), true)
        end
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
    local vis = math.min(11, math.max(1, nOpts))
    filterMenu:SetHeight(8 + FILTER_MENU_SEARCH_H + 4 + vis * FILTER_MENU_ROW_H)
    local maxO = math.max(0, mChild:GetHeight() - mScroll:GetHeight())
    local cur = mScroll:GetVerticalScroll() or 0
    if cur > maxO then
      cur = maxO
    end
    mScroll:SetVerticalScroll(cur)
  end

  mSearchEdit:SetScript("OnTextChanged", function(self)
    local t = self:GetText() or ""
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    filterMenuSearchQ = strlower(t)
    updateFilterMenuSearchPh()
    refreshFilterMenuList()
    mScroll:SetVerticalScroll(0)
  end)
  updateFilterMenuSearchPh()

  dropBtn:SetScript("OnClick", function()
    if filterMenu:IsShown() then
      CEF.UIFilters.hideFilterInstanceMenu(f)
    else
      CEF.UIFilters.hideFilterIntentMenu(f)
      CEF.UIFilters.hideFilterRoleMenu(f)
      filterMenuSearchQ = ""
      mSearchEdit:SetText("")
      updateFilterMenuSearchPh()
      refreshFilterMenuList()
      mScroll:SetVerticalScroll(0)
      filterMenu:Show()
      filterMenu:Raise()
      CEF.UIFilters.syncFilterDropBlocker(f)
    end
  end)

  f.filterInstanceMenu = filterMenu

  local intentDropBtn = CreateFrame("Button", nil, filterBar)
  intentDropBtn:SetSize(FILTER_INTENT_DROPDOWN_W, SEARCH_EDIT_H)
  intentDropBtn:SetPoint("TOPLEFT", dropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)
  local idBg = intentDropBtn:CreateTexture(nil, "BACKGROUND")
  idBg:SetAllPoints()
  idBg:SetColorTexture(0.11, 0.09, 0.07, 1)

  local filterIntentDropSummaryFS = intentDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  filterIntentDropSummaryFS:SetPoint("LEFT", 8, 0)
  filterIntentDropSummaryFS:SetPoint("RIGHT", intentDropBtn, "RIGHT", -22, 0)
  filterIntentDropSummaryFS:SetJustifyH("LEFT")
  filterIntentDropSummaryFS:SetText(CEF.intentFilterOptionRichText(st().filterIntentKeys))

  CEF.UIFilters.attachDropChevron(intentDropBtn, 16)
  f.cefDropIntentBtn = intentDropBtn

  local intentFilterMenu = CreateFrame("Frame", nil, f)
  intentFilterMenu:SetWidth(FILTER_INTENT_DROPDOWN_W)
  intentFilterMenu:SetFrameStrata("TOOLTIP")
  intentFilterMenu:SetFrameLevel(502)
  intentFilterMenu:EnableMouse(true)
  intentFilterMenu:Hide()
  intentFilterMenu:SetPoint("TOPLEFT", intentDropBtn, "BOTTOMLEFT", 0, -2)

  local iBg = intentFilterMenu:CreateTexture(nil, "BACKGROUND")
  iBg:SetAllPoints()
  iBg:SetColorTexture(0.05, 0.048, 0.06, 0.99)

  local brI, bgI, bbI, baI = 0.55, 0.45, 0.18, 0.85
  local ezI = 1
  local itTop = intentFilterMenu:CreateTexture(nil, "BORDER")
  itTop:SetHeight(ezI)
  itTop:SetColorTexture(brI, bgI, bbI, baI)
  itTop:SetPoint("TOPLEFT", intentFilterMenu, "TOPLEFT", 0, 0)
  itTop:SetPoint("TOPRIGHT", intentFilterMenu, "TOPRIGHT", 0, 0)

  local itBot = intentFilterMenu:CreateTexture(nil, "BORDER")
  itBot:SetHeight(ezI)
  itBot:SetColorTexture(brI, bgI, bbI, baI)
  itBot:SetPoint("BOTTOMLEFT", intentFilterMenu, "BOTTOMLEFT", 0, 0)
  itBot:SetPoint("BOTTOMRIGHT", intentFilterMenu, "BOTTOMRIGHT", 0, 0)

  local itL = intentFilterMenu:CreateTexture(nil, "BORDER")
  itL:SetWidth(ezI)
  itL:SetColorTexture(brI, bgI, bbI, baI)
  itL:SetPoint("TOPLEFT", intentFilterMenu, "TOPLEFT", 0, 0)
  itL:SetPoint("BOTTOMLEFT", intentFilterMenu, "BOTTOMLEFT", 0, 0)

  local itR = intentFilterMenu:CreateTexture(nil, "BORDER")
  itR:SetWidth(ezI)
  itR:SetColorTexture(brI, bgI, bbI, baI)
  itR:SetPoint("TOPRIGHT", intentFilterMenu, "TOPRIGHT", 0, 0)
  itR:SetPoint("BOTTOMRIGHT", intentFilterMenu, "BOTTOMRIGHT", 0, 0)

  local intentMScroll = CreateFrame("ScrollFrame", nil, intentFilterMenu)
  intentMScroll:SetPoint("TOPLEFT", intentFilterMenu, "TOPLEFT", 4, -4)
  intentMScroll:SetPoint("BOTTOMRIGHT", intentFilterMenu, "BOTTOMRIGHT", -4, 4)
  intentMScroll:EnableMouse(true)
  local intentMChild = CreateFrame("Frame", nil, intentMScroll)
  intentMScroll:SetScrollChild(intentMChild)
  intentMChild:EnableMouse(true)
  intentMScroll:EnableMouseWheel(true)
  intentMScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, intentMChild:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * FILTER_MENU_ROW_H * 2
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
  end)

  for ii = 1, INTENT_FILTER_MENU_MAX_ROWS do
    local irow = CreateFrame("Button", nil, intentMChild)
    irow:SetHeight(FILTER_MENU_ROW_H)
    irow.isHeader = false

    local irb = irow:CreateTexture(nil, "BACKGROUND")
    irb:SetAllPoints()
    irb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    irow.bg = irb

    irow:SetScript("OnEnter", function()
      CEF.UIFilters.applyFilterRowBg(irow, true)
    end)
    irow:SetScript("OnLeave", function()
      CEF.UIFilters.applyFilterRowBg(irow, false)
    end)

    local irlab = irow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    irlab:SetPoint("LEFT", irow, "LEFT", CEF.UIFilters.filterCheckLabelLeft(), 0)
    irlab:SetJustifyH("LEFT")
    irlab:SetWidth(FILTER_INTENT_DROPDOWN_W - 24)
    irow.label = irlab
    CEF.UIFilters.attachFilterRowCheck(irow)

    irow:SetScript("OnClick", function(self)
      if self.intentKey == false or self.intentKey == nil then
        st().filterIntentKeys = CEF.filterSetClear()
      else
        st().filterIntentKeys = CEF.filterSetToggle(st().filterIntentKeys, self.intentKey)
      end
      CEF.UIFilters.updateIntentFilterDropSummary(filterIntentDropSummaryFS, st().filterIntentKeys)
      refreshIntentFilterMenuList()
      if scrollFrame then
        scrollFrame:SetVerticalScroll(0)
      end
      CEF.UI.refreshUI()
    end)

    intentFilterMenuRows[ii] = irow
    irow:Hide()
  end

  refreshIntentFilterMenuList = function()
    intentFilterMenu:SetWidth(intentDropBtn:GetWidth())
    local imw = intentFilterMenu:GetWidth()
    local ilabelW = math.max(40, imw - CEF.UIFilters.filterCheckLabelLeft() - 8)
    local iopts = CEF.INTENT_FILTER_MENU_OPTS
    local selected = st().filterIntentKeys
    local iy = 0
    for i = 1, INTENT_FILTER_MENU_MAX_ROWS do
      local irow = intentFilterMenuRows[i]
      if i <= #iopts then
        local opt = iopts[i]
        irow:ClearAllPoints()
        irow:SetPoint("TOPLEFT", intentMChild, "TOPLEFT", 0, -iy)
        irow:SetPoint("TOPRIGHT", intentMChild, "TOPRIGHT", 0, -iy)
        irow:SetHeight(FILTER_MENU_ROW_H)
        irow.label:SetWidth(ilabelW)
        irow.intentKey = opt.key
        irow.label:SetTextColor(1, 1, 1)
        irow.label:SetText(opt.label)
        CEF.UIFilters.setFilterRowChecked(irow, CEF.filterSetContains(selected, opt.key), true)
        CEF.UIFilters.applyFilterRowBg(irow, false)
        irow:Show()
        iy = iy + FILTER_MENU_ROW_H
      else
        irow:Hide()
      end
    end
    local nIOpts = #iopts
    intentMChild:SetWidth(math.max(1, imw - 8))
    intentMChild:SetHeight(math.max(FILTER_MENU_ROW_H, nIOpts * FILTER_MENU_ROW_H))
    local ivis = math.min(6, math.max(1, nIOpts))
    intentFilterMenu:SetHeight(8 + ivis * FILTER_MENU_ROW_H)
    local maxO = math.max(0, intentMChild:GetHeight() - intentMScroll:GetHeight())
    local cur = intentMScroll:GetVerticalScroll() or 0
    if cur > maxO then
      cur = maxO
    end
    intentMScroll:SetVerticalScroll(cur)
  end

  intentDropBtn:SetScript("OnClick", function()
    if intentFilterMenu:IsShown() then
      CEF.UIFilters.hideFilterIntentMenu(f)
    else
      CEF.UIFilters.hideFilterInstanceMenu(f)
      CEF.UIFilters.hideFilterRoleMenu(f)
      refreshIntentFilterMenuList()
      intentMScroll:SetVerticalScroll(0)
      intentFilterMenu:Show()
      intentFilterMenu:Raise()
      CEF.UIFilters.syncFilterDropBlocker(f)
    end
  end)

  f.filterIntentMenu = intentFilterMenu

  local roleDropBtn = CreateFrame("Button", nil, filterBar)
  roleDropBtn:SetSize(FILTER_ROLE_DROPDOWN_W, SEARCH_EDIT_H)
  roleDropBtn:SetPoint("TOPLEFT", intentDropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)

  local rdBg = roleDropBtn:CreateTexture(nil, "BACKGROUND")
  rdBg:SetAllPoints()
  rdBg:SetColorTexture(0.11, 0.09, 0.07, 1)

  local filterRoleDropSummaryFS = roleDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  filterRoleDropSummaryFS:SetPoint("LEFT", 8, 0)
  filterRoleDropSummaryFS:SetPoint("RIGHT", roleDropBtn, "RIGHT", -22, 0)
  filterRoleDropSummaryFS:SetJustifyH("LEFT")
  filterRoleDropSummaryFS:SetText(CEF.roleFilterOptionRichText(st().filterRoleKeys))

  CEF.UIFilters.attachDropChevron(roleDropBtn, 16)
  f.cefDropRoleBtn = roleDropBtn

  local roleFilterMenu = CreateFrame("Frame", nil, f)
  roleFilterMenu:SetWidth(FILTER_ROLE_DROPDOWN_W)
  roleFilterMenu:SetFrameStrata("TOOLTIP")
  roleFilterMenu:SetFrameLevel(504)
  roleFilterMenu:EnableMouse(true)
  roleFilterMenu:Hide()
  roleFilterMenu:SetPoint("TOPLEFT", roleDropBtn, "BOTTOMLEFT", 0, -2)

  local rMenuBg = roleFilterMenu:CreateTexture(nil, "BACKGROUND")
  rMenuBg:SetAllPoints()
  rMenuBg:SetColorTexture(0.05, 0.048, 0.06, 0.99)

  local brR, bgR, bbR, baR = 0.55, 0.45, 0.18, 0.85
  local ezR = 1
  local rtTop = roleFilterMenu:CreateTexture(nil, "BORDER")
  rtTop:SetHeight(ezR)
  rtTop:SetColorTexture(brR, bgR, bbR, baR)
  rtTop:SetPoint("TOPLEFT", roleFilterMenu, "TOPLEFT", 0, 0)
  rtTop:SetPoint("TOPRIGHT", roleFilterMenu, "TOPRIGHT", 0, 0)

  local rtBot = roleFilterMenu:CreateTexture(nil, "BORDER")
  rtBot:SetHeight(ezR)
  rtBot:SetColorTexture(brR, bgR, bbR, baR)
  rtBot:SetPoint("BOTTOMLEFT", roleFilterMenu, "BOTTOMLEFT", 0, 0)
  rtBot:SetPoint("BOTTOMRIGHT", roleFilterMenu, "BOTTOMRIGHT", 0, 0)

  local rtL = roleFilterMenu:CreateTexture(nil, "BORDER")
  rtL:SetWidth(ezR)
  rtL:SetColorTexture(brR, bgR, bbR, baR)
  rtL:SetPoint("TOPLEFT", roleFilterMenu, "TOPLEFT", 0, 0)
  rtL:SetPoint("BOTTOMLEFT", roleFilterMenu, "BOTTOMLEFT", 0, 0)

  local rtR = roleFilterMenu:CreateTexture(nil, "BORDER")
  rtR:SetWidth(ezR)
  rtR:SetColorTexture(brR, bgR, bbR, baR)
  rtR:SetPoint("TOPRIGHT", roleFilterMenu, "TOPRIGHT", 0, 0)
  rtR:SetPoint("BOTTOMRIGHT", roleFilterMenu, "BOTTOMRIGHT", 0, 0)

  local roleMScroll = CreateFrame("ScrollFrame", nil, roleFilterMenu)
  roleMScroll:SetPoint("TOPLEFT", roleFilterMenu, "TOPLEFT", 4, -4)
  roleMScroll:SetPoint("BOTTOMRIGHT", roleFilterMenu, "BOTTOMRIGHT", -4, 4)
  roleMScroll:EnableMouse(true)
  local roleMChild = CreateFrame("Frame", nil, roleMScroll)
  roleMScroll:SetScrollChild(roleMChild)
  roleMChild:EnableMouse(true)
  roleMScroll:EnableMouseWheel(true)
  roleMScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, roleMChild:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * FILTER_MENU_ROW_H * 2
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
  end)

  for ri = 1, ROLE_FILTER_MENU_MAX_ROWS do
    local rrow = CreateFrame("Button", nil, roleMChild)
    rrow:SetHeight(FILTER_MENU_ROW_H)
    local rrb = rrow:CreateTexture(nil, "BACKGROUND")
    rrb:SetAllPoints()
    rrb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    rrow.bg = rrb
    rrow:SetScript("OnEnter", function()
      CEF.UIFilters.applyFilterRowBg(rrow, true)
    end)
    rrow:SetScript("OnLeave", function()
      CEF.UIFilters.applyFilterRowBg(rrow, false)
    end)

    local rrlab = rrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rrlab:SetPoint("LEFT", rrow, "LEFT", CEF.UIFilters.filterCheckLabelLeft(), 0)
    rrlab:SetJustifyH("LEFT")
    rrlab:SetWidth(FILTER_ROLE_DROPDOWN_W - 24)
    rrow.label = rrlab
    CEF.UIFilters.attachFilterRowCheck(rrow)

    rrow:SetScript("OnClick", function(self)
      if self.roleKey == false or self.roleKey == nil then
        st().filterRoleKeys = CEF.filterSetClear()
      else
        st().filterRoleKeys = CEF.filterSetToggle(st().filterRoleKeys, self.roleKey)
      end
      CEF.UIFilters.updateRoleFilterDropSummary(filterRoleDropSummaryFS, st().filterRoleKeys)
      refreshRoleFilterMenuList()
      if scrollFrame then
        scrollFrame:SetVerticalScroll(0)
      end
      CEF.UI.refreshUI()
    end)

    roleFilterMenuRows[ri] = rrow
    rrow:Hide()
  end

  refreshRoleFilterMenuList = function()
    roleFilterMenu:SetWidth(roleDropBtn:GetWidth())
    local rmw = roleFilterMenu:GetWidth()
    local rlabelW = math.max(40, rmw - CEF.UIFilters.filterCheckLabelLeft() - 8)
    local ropts = CEF.ROLE_FILTER_MENU_OPTS
    local selected = st().filterRoleKeys
    local ry = 0
    for i = 1, ROLE_FILTER_MENU_MAX_ROWS do
      local rrow = roleFilterMenuRows[i]
      if i <= #ropts then
        local ropt = ropts[i]
        rrow:ClearAllPoints()
        rrow:SetPoint("TOPLEFT", roleMChild, "TOPLEFT", 0, -ry)
        rrow:SetPoint("TOPRIGHT", roleMChild, "TOPRIGHT", 0, -ry)
        rrow:SetHeight(FILTER_MENU_ROW_H)
        rrow.label:SetWidth(rlabelW)
        rrow.roleKey = ropt.key
        rrow.label:SetTextColor(1, 1, 1)
        rrow.label:SetText(ropt.label)
        CEF.UIFilters.setFilterRowChecked(rrow, CEF.filterSetContains(selected, ropt.key), true)
        CEF.UIFilters.applyFilterRowBg(rrow, false)
        rrow:Show()
        ry = ry + FILTER_MENU_ROW_H
      else
        rrow:Hide()
      end
    end
    local nROpts = #ropts
    roleMChild:SetWidth(math.max(1, rmw - 8))
    roleMChild:SetHeight(math.max(FILTER_MENU_ROW_H, nROpts * FILTER_MENU_ROW_H))
    local rvis = math.min(6, math.max(1, nROpts))
    roleFilterMenu:SetHeight(8 + rvis * FILTER_MENU_ROW_H)
    local maxO = math.max(0, roleMChild:GetHeight() - roleMScroll:GetHeight())
    local cur = roleMScroll:GetVerticalScroll() or 0
    if cur > maxO then
      cur = maxO
    end
    roleMScroll:SetVerticalScroll(cur)
  end

  roleDropBtn:SetScript("OnClick", function()
    if roleFilterMenu:IsShown() then
      CEF.UIFilters.hideFilterRoleMenu(f)
    else
      CEF.UIFilters.hideFilterInstanceMenu(f)
      CEF.UIFilters.hideFilterIntentMenu(f)
      refreshRoleFilterMenuList()
      roleMScroll:SetVerticalScroll(0)
      roleFilterMenu:Show()
      roleFilterMenu:Raise()
      CEF.UIFilters.syncFilterDropBlocker(f)
    end
  end)

  f.filterRoleMenu = roleFilterMenu

  local resetFiltersBtn = CreateFrame("Button", nil, filterBar)
  resetFiltersBtn:SetSize(FILTER_RESET_BTN_W, SEARCH_EDIT_H)
  resetFiltersBtn:SetPoint("TOPLEFT", roleDropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)
  local resetBg = resetFiltersBtn:CreateTexture(nil, "BACKGROUND")
  resetBg:SetAllPoints()
  resetBg:SetColorTexture(0.14, 0.1, 0.08, 1)
  local resetFs = resetFiltersBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  resetFs:SetAllPoints()
  resetFs:SetText(CEF.L.RESET)
  resetFiltersBtn:SetScript("OnEnter", function()
    resetBg:SetColorTexture(0.22, 0.16, 0.1, 1)
  end)
  resetFiltersBtn:SetScript("OnLeave", function()
    resetBg:SetColorTexture(0.14, 0.1, 0.08, 1)
  end)
  resetFiltersBtn:SetScript("OnClick", function()
    CEF.UIFilters.hideAllFilterDropdowns(f)
    st().filterInstanceKeys = CEF.filterSetClear()
    st().filterIntentKeys = CEF.filterSetClear()
    st().filterRoleKeys = CEF.filterSetClear()
    st().filterSearchText = ""
    CEF.UIFilters.updateFilterDropSummary(filterDropSummaryFS, st().filterInstanceKeys)
    CEF.UIFilters.updateIntentFilterDropSummary(filterIntentDropSummaryFS, st().filterIntentKeys)
    CEF.UIFilters.updateRoleFilterDropSummary(filterRoleDropSummaryFS, st().filterRoleKeys)
    searchEdit:SetText("")
    searchEdit:ClearFocus()
    updateSearchPlaceholder()
    if scrollFrame then
      scrollFrame:SetVerticalScroll(0)
    end
    CEF.UI.refreshUI()
  end)

  -- Redistribui busca + dropdowns para preencher 100% da barra (como na Guilda).
  local LIST_FILTER_PAD_X = 10
  local function layoutListFilterBarFill()
    local barW = filterBar:GetWidth() or 960
    local gaps = 4 * FILTER_SEARCH_INSTANCE_GAP
    local fixed = FILTER_RESET_BTN_W
    local flexTotal = barW - LIST_FILTER_PAD_X * 2 - gaps - fixed
    if flexTotal < 280 then
      flexTotal = 280
    end
    local wSearch = math.floor(math.max(140, flexTotal * 0.28) + 0.5)
    local wInst = math.floor(math.max(120, flexTotal * 0.26) + 0.5)
    local wIntent = math.floor(math.max(120, flexTotal * 0.26) + 0.5)
    local wRole = math.max(100, flexTotal - wSearch - wInst - wIntent)

    searchBorder:ClearAllPoints()
    searchBorder:SetHeight(SEARCH_EDIT_H)
    searchBorder:SetWidth(wSearch)
    searchBorder:SetPoint("TOPLEFT", filterBar, "TOPLEFT", LIST_FILTER_PAD_X, -7)

    dropBtn:ClearAllPoints()
    dropBtn:SetHeight(SEARCH_EDIT_H)
    dropBtn:SetWidth(wInst)
    dropBtn:SetPoint("TOPLEFT", searchBorder, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)

    intentDropBtn:ClearAllPoints()
    intentDropBtn:SetHeight(SEARCH_EDIT_H)
    intentDropBtn:SetWidth(wIntent)
    intentDropBtn:SetPoint("TOPLEFT", dropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)

    roleDropBtn:ClearAllPoints()
    roleDropBtn:SetHeight(SEARCH_EDIT_H)
    roleDropBtn:SetWidth(wRole)
    roleDropBtn:SetPoint("TOPLEFT", intentDropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)

    resetFiltersBtn:ClearAllPoints()
    resetFiltersBtn:SetSize(FILTER_RESET_BTN_W, SEARCH_EDIT_H)
    resetFiltersBtn:SetPoint("TOPLEFT", roleDropBtn, "TOPRIGHT", FILTER_SEARCH_INSTANCE_GAP, 0)
  end

  filterBar:SetScript("OnSizeChanged", layoutListFilterBarFill)
  layoutListFilterBarFill()
  f.cefLayoutListFilterBar = layoutListFilterBarFill

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

  header.h1:SetText(CEF.L.COL_INSTANCE_LEVELS)
  header.h2:SetText("")
  header.h2:Hide()
  header.h3:SetText(CEF.L.COL_MESSAGE)
  header.h4:SetText(CEF.L.COL_CHARACTER)
  header.h5:SetText(CEF.L.COL_TIME)
  header.h6:SetText(CEF.L.COL_ACTION)

  -- Mesmo recuo à direita para Lista e Termos (conteúdo + faixa da barra).
  local LIST_SCROLLBAR_GAP = 18
  local RIGHT_EDGE_INSET = 2
  local RIGHT_SCROLL_OUTSET = RIGHT_EDGE_INSET + LIST_SCROLLBAR_GAP

  -- Footer com contagem (mesmo padrão do Oficial / Guilda).
  local LIST_FOOTER_H = 22
  local LIST_BOTTOM_PAD = 4
  local listFooter = CreateFrame("Frame", nil, f)
  listFooter:SetHeight(LIST_FOOTER_H)
  listFooter:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, LIST_BOTTOM_PAD)
  listFooter:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, LIST_BOTTOM_PAD)
  listFooter:Hide()
  local listFootBg = listFooter:CreateTexture(nil, "BACKGROUND")
  listFootBg:SetAllPoints()
  listFootBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)
  local listFootFs = listFooter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  listFootFs:SetPoint("LEFT", listFooter, "LEFT", 12, 0)
  listFootFs:SetPoint("RIGHT", listFooter, "RIGHT", -12, 0)
  listFootFs:SetJustifyH("LEFT")
  listFootFs:SetText((CEF.L and CEF.L("LFG_RESULT_COUNT", 0)) or "0")
  f.listFooter = listFooter
  f.listFooterLabel = listFootFs
  CEF.UI.listFooterLabel = listFootFs

  scrollFrame = CreateFrame("ScrollFrame", nil, f)
  scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  -- Âncora no frame principal (não no footer) para o layout não colapsar com Show/Hide.
  scrollFrame:SetPoint(
    "BOTTOMRIGHT",
    f,
    "BOTTOMRIGHT",
    -RIGHT_SCROLL_OUTSET,
    LIST_BOTTOM_PAD + LIST_FOOTER_H + 4
  )
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

  local settingsTopPanel = CreateFrame("Frame", nil, f)
  -- Painel “Sobre…”: mesmo recuo que o resto da janela.
  local TERMS_H_PAD = CC.TABLE_PAD
  -- Cabeçalho fixo de 3 colunas + scroll por baixo: um pouco mais à esquerda que TABLE_PAD
  -- para o texto (ex. GameFontNormalLarge em «Masmorras») alinhar visualmente ao header.
  local TERMS_TABLE_LEFT = math.max(2, CC.TABLE_PAD - 4)
  settingsTopPanel:Hide()
  settingsTopPanel:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  local STP_PAD = CC.TABLE_PAD

  -- Seletor de idioma (automático ou override manual).
  local localeLabel = settingsTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  localeLabel:SetJustifyH("LEFT")
  localeLabel:SetText("|cffffcc66" .. CEF.L.LOCALE_LABEL .. "|r")
  local localeDropBtn = CreateFrame("Button", nil, settingsTopPanel)
  localeDropBtn:SetHeight(SEARCH_EDIT_H)
  localeDropBtn:SetWidth(220)
  local localeDropBg = localeDropBtn:CreateTexture(nil, "BACKGROUND")
  localeDropBg:SetAllPoints()
  localeDropBg:SetColorTexture(0.11, 0.09, 0.07, 1)
  local localeDropFS = localeDropBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  localeDropFS:SetPoint("LEFT", localeDropBtn, "LEFT", 8, 0)
  localeDropFS:SetPoint("RIGHT", localeDropBtn, "RIGHT", -22, 0)
  localeDropFS:SetJustifyH("LEFT")
  localeDropFS:SetText(CEF.Locale.chooserSummaryText())
  CEF.UIFilters.attachDropChevron(localeDropBtn, 16)
  f.cefDropLocaleBtn = localeDropBtn
  f.cefLocaleDropFS = localeDropFS
  f.cefLocaleLabel = localeLabel

  -- Toggle: imprimir novas listagens do Chat no chat do jogo.
  local alertRow = CreateFrame("Button", nil, settingsTopPanel)
  alertRow:SetHeight(22)
  local alertBg = alertRow:CreateTexture(nil, "BACKGROUND")
  alertBg:SetAllPoints()
  alertBg:SetColorTexture(0.11, 0.09, 0.07, 0.95)
  alertRow.bg = alertBg
  if CEF.UIFilters and CEF.UIFilters.attachFilterRowCheck then
    CEF.UIFilters.attachFilterRowCheck(alertRow)
  end
  local alertFs = alertRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  if alertRow.check then
    alertFs:SetPoint("LEFT", alertRow.check, "RIGHT", 8, 0)
  else
    alertFs:SetPoint("LEFT", alertRow, "LEFT", 8, 0)
  end
  alertFs:SetPoint("RIGHT", alertRow, "RIGHT", -8, 0)
  alertFs:SetJustifyH("LEFT")
  alertFs:SetText(CEF.L.SETTINGS_CHAT_LISTING_ALERTS or "Print new Chat listings to the game chat")
  f.cefChatAlertRow = alertRow
  f.cefChatAlertFs = alertFs
  local function syncChatAlertCheck()
    local on = CEF.isChatListingAlertsEnabled and CEF.isChatListingAlertsEnabled()
    if CEF.UIFilters and CEF.UIFilters.setFilterRowChecked then
      CEF.UIFilters.setFilterRowChecked(alertRow, on, true)
    end
  end
  alertRow:SetScript("OnClick", function()
    local on = not (CEF.isChatListingAlertsEnabled and CEF.isChatListingAlertsEnabled())
    if CEF.setChatListingAlertsEnabled then
      CEF.setChatListingAlertsEnabled(on)
    end
    syncChatAlertCheck()
  end)
  alertRow:SetScript("OnEnter", function(self)
    self.bg:SetColorTexture(0.2, 0.16, 0.11, 1)
  end)
  alertRow:SetScript("OnLeave", function(self)
    self.bg:SetColorTexture(0.11, 0.09, 0.07, 0.95)
  end)
  syncChatAlertCheck()
  f.cefSyncChatAlertCheck = syncChatAlertCheck

  local localeMenu = CreateFrame("Frame", nil, f)
  localeMenu:SetWidth(220)
  localeMenu:SetFrameStrata("TOOLTIP")
  localeMenu:SetFrameLevel(530)
  localeMenu:EnableMouse(true)
  localeMenu:Hide()
  localeMenu:SetPoint("TOPLEFT", localeDropBtn, "BOTTOMLEFT", 0, -2)
  do
    local bg = localeMenu:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.048, 0.06, 0.99)
    local br, bgc, bb, ba = 0.55, 0.45, 0.18, 0.85
    local top = localeMenu:CreateTexture(nil, "BORDER")
    top:SetHeight(1)
    top:SetColorTexture(br, bgc, bb, ba)
    top:SetPoint("TOPLEFT", localeMenu, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", localeMenu, "TOPRIGHT", 0, 0)
    local bot = localeMenu:CreateTexture(nil, "BORDER")
    bot:SetHeight(1)
    bot:SetColorTexture(br, bgc, bb, ba)
    bot:SetPoint("BOTTOMLEFT", localeMenu, "BOTTOMLEFT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", localeMenu, "BOTTOMRIGHT", 0, 0)
    local left = localeMenu:CreateTexture(nil, "BORDER")
    left:SetWidth(1)
    left:SetColorTexture(br, bgc, bb, ba)
    left:SetPoint("TOPLEFT", localeMenu, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", localeMenu, "BOTTOMLEFT", 0, 0)
    local right = localeMenu:CreateTexture(nil, "BORDER")
    right:SetWidth(1)
    right:SetColorTexture(br, bgc, bb, ba)
    right:SetPoint("TOPRIGHT", localeMenu, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", localeMenu, "BOTTOMRIGHT", 0, 0)
  end
  f.filterLocaleMenu = localeMenu
  local function syncLocaleMenuWidth()
    local bw = localeDropBtn:GetWidth() or 220
    if bw < 120 then
      bw = 220
    end
    localeMenu:SetWidth(bw)
  end
  local localeMenuRows = {}
  local function rebuildLocaleMenu()
    syncLocaleMenuWidth()
    for _, row in ipairs(localeMenuRows) do
      row:Hide()
    end
    local opts = CEF.Locale.getChooserOptions()
    local y = -4
    for i, opt in ipairs(opts) do
      local row = localeMenuRows[i]
      if not row then
        row = CreateFrame("Button", nil, localeMenu)
        row:SetHeight(22)
        local rb = row:CreateTexture(nil, "BACKGROUND")
        rb:SetAllPoints()
        rb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
        row.bg = rb
        local lab = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lab:SetPoint("LEFT", row, "LEFT", 8, 0)
        lab:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        lab:SetJustifyH("LEFT")
        row.label = lab
        row:SetScript("OnEnter", function(self)
          self.bg:SetColorTexture(0.22, 0.18, 0.12, 1)
        end)
        row:SetScript("OnLeave", function(self)
          self.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
        end)
        row:SetScript("OnClick", function(self)
          CEF.Locale.setOverride(self.optionKey)
          localeMenu:Hide()
          CEF.UIFilters.syncFilterDropBlocker(f)
        end)
        localeMenuRows[i] = row
      end
      row.optionKey = opt.key
      row.label:SetText(opt.label)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", localeMenu, "TOPLEFT", 4, y)
      row:SetPoint("TOPRIGHT", localeMenu, "TOPRIGHT", -4, y)
      row:Show()
      y = y - 22
    end
    localeMenu:SetHeight(8 + #opts * 22)
  end
  localeDropBtn:SetScript("OnClick", function()
    if localeMenu:IsShown() then
      localeMenu:Hide()
      CEF.UIFilters.syncFilterDropBlocker(f)
    else
      CEF.UIFilters.hideAllFilterDropdowns(f)
      rebuildLocaleMenu()
      localeMenu:Show()
      localeMenu:Raise()
      CEF.UIFilters.syncFilterDropBlocker(f)
    end
  end)
  f.cefRebuildLocaleMenu = rebuildLocaleMenu

  local stpAboutTitle = settingsTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local stpAboutBody = settingsTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local stpInstTitle = settingsTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local stpInstBody = settingsTopPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  stpAboutTitle:SetJustifyH("LEFT")
  stpAboutBody:SetJustifyH("LEFT")
  stpAboutBody:SetWordWrap(true)
  stpInstTitle:SetJustifyH("LEFT")
  stpInstBody:SetJustifyH("LEFT")
  stpInstBody:SetWordWrap(true)
  stpAboutTitle:SetText(CEF.L.TERMS_ABOUT_TITLE)
  stpAboutBody:SetText(CEF.L.TERMS_ABOUT_BODY)
  stpInstTitle:SetText(CEF.L.TERMS_INSTANCES_TITLE)
  stpInstBody:SetText(CEF.L.TERMS_INSTANCES_BODY)

  local function layoutSettingsTopPanel()
    local fw = math.max(100, (f:GetWidth() or 960) - 4)
    settingsTopPanel:SetWidth(fw)
    local w = fw - TERMS_H_PAD * 2
    if w < 120 then
      w = math.max(120, fw - TERMS_H_PAD * 2)
    end
    localeLabel:SetWidth(w)
    localeDropBtn:SetWidth(math.min(260, math.max(180, w * 0.45)))
    syncLocaleMenuWidth()
    stpAboutTitle:SetWidth(w)
    stpAboutBody:SetWidth(w)
    stpInstTitle:SetWidth(w)
    stpInstBody:SetWidth(w)
    local y = STP_PAD
    localeLabel:ClearAllPoints()
    localeLabel:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
    y = y + localeLabel:GetStringHeight() + 6
    localeDropBtn:ClearAllPoints()
    localeDropBtn:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
    y = y + SEARCH_EDIT_H + 10
    if alertRow then
      alertRow:ClearAllPoints()
      alertRow:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
      alertRow:SetWidth(math.min(520, math.max(220, w)))
      y = y + 22 + 14
    end
    stpAboutTitle:ClearAllPoints()
    stpAboutTitle:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
    y = y + stpAboutTitle:GetStringHeight() + 8
    stpAboutBody:ClearAllPoints()
    stpAboutBody:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
    y = y + stpAboutBody:GetStringHeight() + 14
    stpInstTitle:ClearAllPoints()
    stpInstTitle:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
    y = y + stpInstTitle:GetStringHeight() + 8
    stpInstBody:ClearAllPoints()
    stpInstBody:SetPoint("TOPLEFT", settingsTopPanel, "TOPLEFT", TERMS_H_PAD, -y)
    y = y + stpInstBody:GetStringHeight() + STP_PAD
    settingsTopPanel:SetHeight(math.max(y, 20))
  end

  settingsTopPanel:SetScript("OnSizeChanged", function()
    layoutSettingsTopPanel()
  end)
  settingsTopPanel:SetScript("OnShow", function()
    settingsTopPanel:SetScript("OnUpdate", function(s)
      s:SetScript("OnUpdate", nil)
      layoutSettingsTopPanel()
    end)
  end)

  local function colWidthsForTerms(rowW)
    local nomeW = math.min(300, math.max(160, math.floor(rowW * 0.30)))
    local levelW = math.max(56, math.floor(rowW * 0.11))
    local keyW = math.max(80, rowW - nomeW - levelW - 20)
    return nomeW, levelW, keyW
  end

  -- Cabeçalho 3 colunas: largura total como o header da Lista (barra até à direita da janela; texto alinhado ao scroll).
  local settingsTermsTableHeader = CreateFrame("Frame", nil, f)
  settingsTermsTableHeader:Hide()
  settingsTermsTableHeader:SetHeight(24)
  local stthTex = settingsTermsTableHeader:CreateTexture(nil, "BACKGROUND")
  stthTex:SetAllPoints()
  stthTex:SetColorTexture(0.2, 0.18, 0.12, 0.95)
  local stth1 = settingsTermsTableHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local stth2 = settingsTermsTableHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local stth3 = settingsTermsTableHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  stth1:SetJustifyH("LEFT")
  stth2:SetJustifyH("LEFT")
  stth3:SetJustifyH("LEFT")
  stth1:SetText(CEF.L.TERMS_COL_INSTANCE_ZONE)
  stth2:SetText(CEF.L.TERMS_COL_LEVELS)
  stth3:SetText(CEF.L.TERMS_COL_KEYWORDS)
  f.settingsTermsTableHeader = settingsTermsTableHeader

  -- Declarado antes do layout do header: a função abaixo usa este scroll (evita global nil).
  local settingsScroll

  -- Larguras das colunas vêm sempre do mesmo cálculo que relayoutSettingsTermsTable (evita cabeçalho vs corpo).
  local function layoutSettingsTermsTableHeader(nomeW, levelW, keyW)
    if not settingsTermsTableHeader:IsShown() then
      return
    end
    local fw = math.max(100, (f:GetWidth() or 960) - 4)
    settingsTermsTableHeader:ClearAllPoints()
    settingsTermsTableHeader:SetPoint("TOPLEFT", settingsTopPanel, "BOTTOMLEFT", 0, -4)
    settingsTermsTableHeader:SetWidth(fw)
    local x = TERMS_TABLE_LEFT
    stth1:ClearAllPoints()
    stth1:SetPoint("LEFT", settingsTermsTableHeader, "LEFT", x, 0)
    stth1:SetWidth(math.max(40, nomeW - 8))
    x = x + nomeW
    stth2:ClearAllPoints()
    stth2:SetPoint("LEFT", settingsTermsTableHeader, "LEFT", x, 0)
    stth2:SetWidth(math.max(36, levelW - 8))
    x = x + levelW
    stth3:ClearAllPoints()
    stth3:SetPoint("LEFT", settingsTermsTableHeader, "LEFT", x, 0)
    stth3:SetWidth(math.max(40, keyW - 10))
  end

  settingsScroll = CreateFrame("ScrollFrame", nil, f)
  settingsScroll:Hide()
  settingsScroll:SetPoint("TOPLEFT", settingsTermsTableHeader, "BOTTOMLEFT", 0, -1)
  settingsScroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, 8)
  settingsScroll:EnableMouse(true)
  local settingsChild = CreateFrame("Frame", nil, settingsScroll)
  settingsScroll:SetScrollChild(settingsChild)
  settingsChild:EnableMouse(true)

  -- Barra de rolagem manual (sem templates da Blizzard): trilho + thumb arrastável.
  local settingsSBar = CreateFrame("Frame", nil, f)
  settingsSBar:SetWidth(12)
  settingsSBar:SetPoint("TOPLEFT", settingsScroll, "TOPRIGHT", 2, 0)
  settingsSBar:SetPoint("BOTTOMLEFT", settingsScroll, "BOTTOMRIGHT", 2, 0)
  settingsSBar:EnableMouse(true)
  settingsSBar:Hide()

  local sbarTrack = settingsSBar:CreateTexture(nil, "BACKGROUND")
  sbarTrack:SetAllPoints()
  sbarTrack:SetColorTexture(0.04, 0.035, 0.07, 0.96)

  local settingsSBarThumb = CreateFrame("Button", nil, settingsSBar)
  settingsSBarThumb:SetWidth(10)
  settingsSBarThumb:SetHeight(32)
  settingsSBarThumb:SetFrameLevel((settingsSBar:GetFrameLevel() or 0) + 3)
  local sbarThumbTex = settingsSBarThumb:CreateTexture(nil, "ARTWORK")
  sbarThumbTex:SetAllPoints()
  sbarThumbTex:SetColorTexture(0.52, 0.5, 0.6, 0.88)
  settingsSBarThumb:SetNormalTexture(sbarThumbTex)
  local sbarThumbHi = settingsSBarThumb:CreateTexture(nil, "HIGHLIGHT")
  sbarThumbHi:SetAllPoints()
  sbarThumbHi:SetColorTexture(0.62, 0.58, 0.72, 0.55)
  settingsSBarThumb:SetHighlightTexture(sbarThumbHi)

  local function syncSettingsScrollbar()
    if not settingsScroll:IsShown() then
      settingsSBar:Hide()
      settingsSBarThumb:Hide()
      return
    end
    local ch = settingsChild:GetHeight() or 0
    local sh = settingsScroll:GetHeight() or 1
    local maxV = math.max(0, ch - sh)
    local cur = settingsScroll:GetVerticalScroll() or 0
    if cur > maxV then
      cur = maxV
      settingsScroll:SetVerticalScroll(cur)
    end
    if maxV > 0.5 then
      settingsSBar:Show()
      local trackH = settingsSBar:GetHeight() or 1
      local thumbH = math.min(trackH, math.max(24, math.floor(trackH * sh / math.max(ch, 1))))
      if thumbH > trackH then
        thumbH = trackH
      end
      settingsSBarThumb:SetHeight(thumbH)
      local range = math.max(1e-6, trackH - thumbH)
      local yFromTop = (maxV > 0) and ((cur / maxV) * range) or 0
      settingsSBarThumb:ClearAllPoints()
      local tx = math.max(0, (settingsSBar:GetWidth() - settingsSBarThumb:GetWidth()) / 2)
      settingsSBarThumb:SetPoint("TOPLEFT", settingsSBar, "TOPLEFT", tx, -yFromTop)
      settingsSBarThumb:Show()
    else
      settingsSBar:Hide()
      settingsSBarThumb:Hide()
    end
  end

  settingsScroll:SetScript("OnVerticalScroll", function()
    syncSettingsScrollbar()
  end)

  settingsSBarThumb:SetScript("OnMouseDown", function(self, button)
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
      local scale = settingsSBar:GetEffectiveScale() or 1
      if scale < 0.01 then
        scale = 1
      end
      local deltaPx = (btn.cefLastCursorY - cy) / scale
      btn.cefLastCursorY = cy
      local ch = settingsChild:GetHeight() or 0
      local sh = settingsScroll:GetHeight() or 1
      local maxS = math.max(0, ch - sh)
      local trackH = settingsSBar:GetHeight() or 1
      local thumbH = btn:GetHeight() or 24
      local range = math.max(1e-6, trackH - thumbH)
      local scrollDelta = (deltaPx / range) * maxS
      local cur = (settingsScroll:GetVerticalScroll() or 0) + scrollDelta
      if cur < 0 then
        cur = 0
      end
      if cur > maxS then
        cur = maxS
      end
      settingsScroll:SetVerticalScroll(cur)
    end)
  end)

  settingsSBarThumb:SetScript("OnMouseUp", function(self)
    self.cefDragging = false
    self:SetScript("OnUpdate", nil)
  end)

  settingsScroll:SetScript("OnShow", function()
    settingsScroll:SetScript("OnUpdate", function(self)
      self:SetScript("OnUpdate", nil)
      if f.cefRelayoutSettingsTerms then
        f.cefRelayoutSettingsTerms()
      else
        syncSettingsScrollbar()
      end
    end)
  end)

  f.cefSyncSettingsScroll = syncSettingsScrollbar

  local settingsTermsLayoutOrder = {}
  local padX_ST = TERMS_TABLE_LEFT
  local zebraA_ST = { 0.06, 0.055, 0.09, 0.94 }
  local zebraB_ST = { 0.085, 0.07, 0.11, 0.9 }
  local COLOR_DG_NAME_ST = "|cffffd100"
  local COLOR_RAID_NAME_ST = "|cffff8866"
  local COLOR_KEYWORDS_ST = "|cff99cc99"
  local COLOR_LFG_PATTERN_ST = "|cffb8d4e8"

  do
    local function pushSectionTitle(txt, localeKey)
      local fs = settingsChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      fs:SetJustifyH("LEFT")
      fs:SetText("|cffffcc66" .. txt .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "sectionTitle", fs = fs, localeKey = localeKey, gold = true }
    end

    local function pushParagraph(txt, localeKey)
      local fs = settingsChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetJustifyH("LEFT")
      fs:SetWordWrap(true)
      fs:SetText(txt)
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "paragraph", fs = fs, localeKey = localeKey }
    end

    local function pushCategoryBanner(txt, localeKey)
      local row = CreateFrame("Frame", nil, settingsChild)
      local bg = row:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.14, 0.11, 0.08, 0.98)
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      fs:SetPoint("LEFT", row, "LEFT", TERMS_TABLE_LEFT, 0)
      fs:SetJustifyH("LEFT")
      fs:SetText("|cffffcc66" .. txt .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "banner", row = row, fs = fs, localeKey = localeKey, gold = true }
    end

    local function pushTableHeader1(lab, localeKey)
      local row = CreateFrame("Frame", nil, settingsChild)
      local bg = row:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.2, 0.17, 0.13, 0.98)
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetPoint("LEFT", row, "LEFT", TERMS_TABLE_LEFT, 0)
      fs:SetJustifyH("LEFT")
      fs:SetText("|cffc8c8c8" .. lab .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "tableHeader1", row = row, fs = fs, localeKey = localeKey, grey = true }
    end

    local function pushInstanceRow(rowData, isRaid, zebraZone)
      local kwStr = table.concat(rowData.needles, ", ")
      local rf = CreateFrame("Frame", nil, settingsChild)
      local rb = rf:CreateTexture(nil, "BACKGROUND")
      rb:SetAllPoints()
      local fsNome = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fsNome:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, -5)
      fsNome:SetJustifyH("LEFT")
      fsNome:SetJustifyV("TOP")
      local nameTag = isRaid and COLOR_RAID_NAME_ST or COLOR_DG_NAME_ST
      fsNome:SetText(nameTag .. CEF.getInstanceDisplayName(rowData.key) .. "|r")
      local fsLvl = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fsLvl:SetJustifyH("LEFT")
      fsLvl:SetJustifyV("TOP")
      fsLvl:SetText(CEF.instanceLevelRangeRichText(rowData.key))
      local keyFs = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      keyFs:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, -5)
      keyFs:SetWordWrap(true)
      keyFs:SetJustifyH("LEFT")
      keyFs:SetJustifyV("TOP")
      keyFs:SetText(COLOR_KEYWORDS_ST .. kwStr .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = {
        kind = "instance",
        rf = rf,
        rb = rb,
        fsNome = fsNome,
        fsLvl = fsLvl,
        keyFs = keyFs,
        zebraZone = zebraZone,
        instanceKey = rowData.key,
        isRaid = isRaid,
      }
    end

    local function pushOneColRow(cellText, useLfgBlue, zebraZone, localeKey)
      local rf = CreateFrame("Frame", nil, settingsChild)
      local rb = rf:CreateTexture(nil, "BACKGROUND")
      rb:SetAllPoints()
      local fs = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetPoint("TOPLEFT", rf, "TOPLEFT", TERMS_TABLE_LEFT, -4)
      fs:SetJustifyH("LEFT")
      fs:SetWordWrap(true)
      fs:SetJustifyV("TOP")
      local col = useLfgBlue and COLOR_LFG_PATTERN_ST or COLOR_KEYWORDS_ST
      fs:SetText(col .. cellText .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = {
        kind = "onecol",
        rf = rf,
        rb = rb,
        fs = fs,
        zebraZone = zebraZone,
        localeKey = localeKey,
        colorPrefix = col,
      }
    end

    local function pushSpacer12()
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "spacer", h = 12 }
    end

    local instCat = CEF.getInstanceDetectionCatalog()
    local grouped = CEF.getInstanceDetectionRowsGroupedSorted()

    if grouped.splitTbc then
      pushCategoryBanner(CEF.L.CATEGORY_CLASSIC_DUNGEONS or CEF.L.CATEGORY_DUNGEONS, "CATEGORY_CLASSIC_DUNGEONS")
      for _, row in ipairs(grouped.classicDungeons or {}) do
        pushInstanceRow(row, false, 1)
      end
      pushCategoryBanner(CEF.L.CATEGORY_CLASSIC_RAIDS or CEF.L.CATEGORY_RAIDS, "CATEGORY_CLASSIC_RAIDS")
      for _, row in ipairs(grouped.classicRaids or {}) do
        pushInstanceRow(row, true, 1)
      end
      pushCategoryBanner(CEF.L.CATEGORY_TBC_DUNGEONS or CEF.L.CATEGORY_DUNGEONS, "CATEGORY_TBC_DUNGEONS")
      for _, row in ipairs(grouped.tbcDungeons or {}) do
        pushInstanceRow(row, false, 1)
      end
      pushCategoryBanner(CEF.L.CATEGORY_TBC_HEROIC_DUNGEONS or "TBC Heroic Dungeons", "CATEGORY_TBC_HEROIC_DUNGEONS")
      for _, row in ipairs(grouped.tbcHeroicDungeons or {}) do
        pushInstanceRow(row, false, 1)
      end
      pushCategoryBanner(CEF.L.CATEGORY_TBC_RAIDS or CEF.L.CATEGORY_RAIDS, "CATEGORY_TBC_RAIDS")
      for _, row in ipairs(grouped.tbcRaids or {}) do
        pushInstanceRow(row, true, 1)
      end
    else
      pushCategoryBanner(CEF.L.CATEGORY_DUNGEONS, "CATEGORY_DUNGEONS")
      for _, row in ipairs(grouped.dungeons) do
        pushInstanceRow(row, false, 1)
      end
      pushCategoryBanner(CEF.L.CATEGORY_RAIDS, "CATEGORY_RAIDS")
      for _, row in ipairs(grouped.raids) do
        pushInstanceRow(row, true, 1)
      end
    end

    pushSpacer12()
    pushSectionTitle(CEF.L.TERMS_SM_GENERIC_TITLE, "TERMS_SM_GENERIC_TITLE")
    pushParagraph(CEF.L.TERMS_SM_GENERIC_BODY, "TERMS_SM_GENERIC_BODY")
    pushTableHeader1(CEF.L.TERMS_COL_PHRASE, "TERMS_COL_PHRASE")
    for _, phrase in ipairs(instCat.scarletGenericUiHints or {}) do
      pushOneColRow(phrase, false, 2, "TERMS_SM_AUTO_HINT")
    end
    for _, phrase in ipairs(instCat.scarletGeneric) do
      pushOneColRow(phrase, false, 2)
    end

    pushSpacer12()
    pushSectionTitle(CEF.L.TERMS_LFG_PATTERNS_TITLE, "TERMS_LFG_PATTERNS_TITLE")
    pushParagraph(CEF.L.TERMS_LFG_PATTERNS_BODY, "TERMS_LFG_PATTERNS_BODY")
    pushTableHeader1(CEF.L.TERMS_COL_PATTERN_TERM, "TERMS_COL_PATTERN_TERM")
    local msgCat = CEF.getMessageDetectionCatalog()
    for _, hint in ipairs(msgCat.lfgHints) do
      pushOneColRow(hint, true, 3)
    end

    pushSpacer12()
    pushSectionTitle(CEF.L.TERMS_EXCLUSIONS_TITLE, "TERMS_EXCLUSIONS_TITLE")
    pushParagraph(CEF.L.TERMS_EXCLUSIONS_BODY, "TERMS_EXCLUSIONS_BODY")
    pushTableHeader1(CEF.L.TERMS_COL_PATTERN_FRAGMENT, "TERMS_COL_PATTERN_FRAGMENT")
    for _, phrase in ipairs(msgCat.professionTradeExclude) do
      pushOneColRow(phrase, false, 4)
    end
  end

  local function relayoutSettingsTermsTable()
    -- Não forçar sw >= 100: isso desincronizava colunas (header usava GetWidth real, corpo usava 100px a mais).
    local sw = settingsScroll:GetWidth()
    if not sw or sw < 60 then
      local fwEst = math.max(100, (f:GetWidth() or 960) - 4)
      sw = math.max(60, fwEst - RIGHT_SCROLL_OUTSET)
    end
    settingsChild:SetWidth(sw)
    local rowInner = math.max(40, sw - 2 * TERMS_TABLE_LEFT)
    local nomeW, levelW, keyW = colWidthsForTerms(rowInner)
    local rowW = rowInner
    local zebraCount = { 0, 0, 0, 0 }
    local y = 2
    layoutSettingsTermsTableHeader(nomeW, levelW, keyW)

    for _, e in ipairs(settingsTermsLayoutOrder) do
      if e.kind == "sectionTitle" then
        e.fs:SetWidth(rowW)
        e.fs:ClearAllPoints()
        e.fs:SetPoint("TOPLEFT", settingsChild, "TOPLEFT", padX_ST, -y)
        y = y + e.fs:GetStringHeight() + 8
      elseif e.kind == "paragraph" then
        e.fs:SetWidth(rowW)
        e.fs:ClearAllPoints()
        e.fs:SetPoint("TOPLEFT", settingsChild, "TOPLEFT", padX_ST, -y)
        y = y + e.fs:GetStringHeight() + 12
      elseif e.kind == "banner" then
        -- Largura total como as linhas de instância; texto em TABLE_PAD = alinhado ao header.
        e.row:SetHeight(28)
        e.row:ClearAllPoints()
        e.row:SetPoint("TOPLEFT", settingsChild, "TOPLEFT", 0, -y)
        e.row:SetPoint("TOPRIGHT", settingsChild, "TOPRIGHT", 0, -y)
        e.fs:ClearAllPoints()
        e.fs:SetPoint("LEFT", e.row, "LEFT", padX_ST, 0)
        e.fs:SetWidth(math.max(40, rowInner - 4))
        y = y + 30
      elseif e.kind == "tableHeader1" then
        e.row:SetHeight(24)
        e.row:ClearAllPoints()
        e.row:SetPoint("TOPLEFT", settingsChild, "TOPLEFT", 0, -y)
        e.row:SetPoint("TOPRIGHT", settingsChild, "TOPRIGHT", 0, -y)
        e.fs:ClearAllPoints()
        e.fs:SetPoint("LEFT", e.row, "LEFT", padX_ST, 0)
        e.fs:SetWidth(math.max(40, rowInner - 2 * padX_ST))
        y = y + 26
      elseif e.kind == "instance" then
        local z = e.zebraZone or 1
        zebraCount[z] = zebraCount[z] + 1
        local zi = zebraCount[z]
        local zcol = (zi % 2 == 1) and zebraA_ST or zebraB_ST
        e.rb:SetColorTexture(zcol[1], zcol[2], zcol[3], zcol[4])
        local px = padX_ST
        e.fsNome:ClearAllPoints()
        e.fsNome:SetPoint("TOPLEFT", e.rf, "TOPLEFT", px, -5)
        e.fsNome:SetWidth(math.max(40, nomeW - 8))
        e.fsLvl:ClearAllPoints()
        e.fsLvl:SetPoint("TOPLEFT", e.rf, "TOPLEFT", px + nomeW, -5)
        e.fsLvl:SetWidth(math.max(36, levelW - 8))
        e.keyFs:ClearAllPoints()
        e.keyFs:SetPoint("TOPLEFT", e.rf, "TOPLEFT", px + nomeW + levelW, -5)
        e.keyFs:SetWidth(math.max(40, rowInner - nomeW - levelW - 4))
        local rowH = math.max(30, e.keyFs:GetStringHeight() + 10)
        e.rf:SetHeight(rowH)
        e.rf:ClearAllPoints()
        e.rf:SetPoint("TOPLEFT", settingsChild, "TOPLEFT", 0, -y)
        e.rf:SetPoint("TOPRIGHT", settingsChild, "TOPRIGHT", 0, -y)
        y = y + rowH + 1
      elseif e.kind == "onecol" then
        local z = e.zebraZone or 2
        zebraCount[z] = zebraCount[z] + 1
        local zi = zebraCount[z]
        local zcol = (zi % 2 == 1) and zebraA_ST or zebraB_ST
        e.rb:SetColorTexture(zcol[1], zcol[2], zcol[3], zcol[4])
        e.fs:SetWidth(math.max(40, rowInner - 2 * padX_ST))
        local rh = math.max(22, e.fs:GetStringHeight() + 8)
        e.rf:SetHeight(rh)
        e.rf:ClearAllPoints()
        e.rf:SetPoint("TOPLEFT", settingsChild, "TOPLEFT", 0, -y)
        e.rf:SetPoint("TOPRIGHT", settingsChild, "TOPRIGHT", 0, -y)
        e.fs:ClearAllPoints()
        e.fs:SetPoint("TOPLEFT", e.rf, "TOPLEFT", padX_ST, -4)
        y = y + rh + 1
      elseif e.kind == "spacer" then
        y = y + (e.h or 12)
      end
    end

    settingsChild:SetHeight(math.max(y + 28, 200))
    syncSettingsScrollbar()
  end

  f.cefRelayoutSettingsTerms = relayoutSettingsTermsTable
  relayoutSettingsTermsTable()

  settingsScroll:SetScript("OnSizeChanged", function()
    relayoutSettingsTermsTable()
  end)

  settingsScroll:EnableMouseWheel(true)
  settingsScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, settingsChild:GetHeight() - self:GetHeight())
    local step = 32
    local v = (self:GetVerticalScroll() or 0) - delta * step
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
  end)

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
  listFooter:SetFrameLevel(240)
  scrollFrame:SetFrameLevel(50)
  settingsTopPanel:SetFrameLevel(55)
  settingsTermsTableHeader:SetFrameLevel(50)
  settingsScroll:SetFrameLevel(50)
  listSBar:SetFrameLevel((scrollFrame:GetFrameLevel() or 0) + 8)
  listSBarThumb:SetFrameLevel((listSBar:GetFrameLevel() or 0) + 3)
  settingsSBar:SetFrameLevel((settingsScroll:GetFrameLevel() or 0) + 8)
  settingsSBarThumb:SetFrameLevel((settingsSBar:GetFrameLevel() or 0) + 3)

  if CEF.GuildUI and CEF.GuildUI.createPanels then
    CEF.GuildUI.createPanels(f, navBar)
  end
  if CEF.ChatUI and CEF.ChatUI.createPanels then
    CEF.ChatUI.createPanels(f, navBar)
  end
  if CEF.LFGUI and CEF.LFGUI.createPanels then
    CEF.LFGUI.createPanels(f, navBar)
  end
  if CEF.GroupUI and CEF.GroupUI.createPanels then
    CEF.GroupUI.createPanels(f, navBar)
  end
  if CEF.HomeUI and CEF.HomeUI.createPanels then
    CEF.HomeUI.createPanels(f, navBar)
  end
  if f.guildFilterBar then
    f.guildFilterBar:SetFrameLevel(240)
  end
  if f.guildHeader then
    f.guildHeader:SetFrameLevel(50)
  end
  if f.guildScrollFrame then
    f.guildScrollFrame:SetFrameLevel(50)
  end
  if f.guildFooter then
    f.guildFooter:SetFrameLevel(240)
  end
  if f.lfgRoot then
    f.lfgRoot:SetFrameLevel(50)
  end
  if f.groupInfoBar then
    f.groupInfoBar:SetFrameLevel(240)
  end
  if f.groupBoard then
    f.groupBoard:SetFrameLevel(50)
  end

  local function syncTableLayout()
    if f.cefLayoutListFilterBar then
      f.cefLayoutListFilterBar()
    end
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
    local prevTab = f.cefNavTab
    f.cefNavTab = which
    local isHome = which == "home"
    local isList = which == "list"
    local isLfg = which == "lfg"
    local isGuild = which == "guild"
    local isMessages = which == "messages"
    local isGroup = which == "group"
    local isSettings = which == "settings"

    -- Saiu de Mensagens sem enviar: remove rascunho vazio e limpa o composer.
    if prevTab == "messages" and which ~= "messages" then
      if CEF.Chat and CEF.Chat.discardEmptyActive then
        CEF.Chat.discardEmptyActive()
      end
      if f.chatEditBox then
        f.chatEditBox:SetText("")
        if f.chatEditBox.ClearFocus then
          f.chatEditBox:ClearFocus()
        end
        if f.chatUpdateCharCount then
          f.chatUpdateCharCount()
        end
      end
    end

    styleNavTab(btnHome, isHome)
    styleNavTab(btnLista, isList)
    styleNavTab(btnLfg, isLfg)
    styleNavTab(btnGuilda, isGuild)
    styleNavTab(btnMensagens, isMessages)
    styleNavTab(btnGrupo, isGroup)
    styleNavTab(btnTermos, isSettings)

    CEF.UIFilters.hideAllFilterDropdowns(f)
    if f.lfgCategoryMenu then
      f.lfgCategoryMenu:Hide()
    end
    if f.lfgActivityMenu then
      f.lfgActivityMenu:Hide()
    end
    if f.lfgCategoryBtn and CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
      CEF.UIFilters.setDropChevronOpen(f.lfgCategoryBtn, false)
    end
    if f.lfgActivityBtn and CEF.UIFilters and CEF.UIFilters.setDropChevronOpen then
      CEF.UIFilters.setDropChevronOpen(f.lfgActivityBtn, false)
    end

    if f.homeRoot then
      f.homeRoot:SetShown(isHome)
    end

    filterBar:SetShown(isList)
    header:SetShown(isList)
    scrollFrame:SetShown(isList)
    if f.listFooter then
      f.listFooter:SetShown(isList)
    end

    if f.lfgRoot then
      f.lfgRoot:SetShown(isLfg)
    end

    if f.guildFilterBar then
      f.guildFilterBar:SetShown(isGuild)
    end
    if f.guildHeader then
      f.guildHeader:SetShown(isGuild)
    end
    if f.guildScrollFrame then
      f.guildScrollFrame:SetShown(isGuild)
    end
    if f.guildFooter then
      f.guildFooter:SetShown(isGuild)
    end

    if f.chatRoot then
      f.chatRoot:SetShown(isMessages)
    end

    if f.groupInfoBar then
      f.groupInfoBar:SetShown(isGroup)
    end
    if f.groupBoard then
      f.groupBoard:SetShown(isGroup)
    end

    settingsTopPanel:SetShown(isSettings)
    settingsTermsTableHeader:SetShown(isSettings)
    settingsScroll:SetShown(isSettings)

    if isHome then
      if CEF.LFG and CEF.LFG.search then
        local n = #(CEF.LFG.getResults and CEF.LFG.getResults() or {})
        if n == 0 then
          CEF.LFG.search()
        end
      end
      if CEF.HomeUI and CEF.HomeUI.refresh then
        CEF.HomeUI.refresh()
      end
    elseif isList then
      syncTableLayout()
      scrollFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        if f.cefSyncListScroll then
          f.cefSyncListScroll()
        end
      end)
    elseif isLfg then
      -- Adia busca/refresh 1 frame: evita congelar o clique da tab no mesmo tick.
      if f.lfgRoot then
        f.lfgRoot:SetScript("OnUpdate", function(self)
          self:SetScript("OnUpdate", nil)
          if not f:IsShown() or f.cefNavTab ~= "lfg" then
            return
          end
          if CEF.LFG and CEF.LFG.search then
            CEF.LFG.search(nil, { force = true })
          end
          if CEF.LFGUI and CEF.LFGUI.refresh then
            CEF.LFGUI.refresh()
          end
        end)
      elseif CEF.LFG and CEF.LFG.search then
        CEF.LFG.search(nil, { force = true })
        if CEF.LFGUI and CEF.LFGUI.refresh then
          CEF.LFGUI.refresh()
        end
      end
    elseif isGuild then
      if CEF.Guild then
        if CEF.Guild.requestRoster then
          CEF.Guild.requestRoster()
        end
        if CEF.Guild.refreshFromApi then
          CEF.Guild.refreshFromApi()
        end
      end
      if f.cefSyncGuildLayout then
        f.cefSyncGuildLayout()
      end
      if f.guildScrollFrame then
        f.guildScrollFrame:SetScript("OnUpdate", function(self)
          self:SetScript("OnUpdate", nil)
          if f.cefSyncGuildScroll then
            f.cefSyncGuildScroll()
          end
        end)
      end
    elseif isMessages then
      if f.cefScheduleChatLayoutSync then
        f.cefScheduleChatLayoutSync()
      elseif CEF.ChatUI and CEF.ChatUI.refresh then
        CEF.ChatUI.refresh()
      end
    elseif isGroup then
      if CEF.Group and CEF.Group.refreshFromApi then
        CEF.Group.refreshFromApi()
      end
      if f.cefScheduleGroupLayoutSync then
        f.cefScheduleGroupLayoutSync()
      elseif f.cefSyncGroupLayout then
        f.cefSyncGroupLayout()
      end
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
    if f.cefSyncListScroll then
      f.cefSyncListScroll()
    end
    if f.cefSyncGuildScroll then
      f.cefSyncGuildScroll()
    end
    if f.cefSyncSettingsScroll then
      f.cefSyncSettingsScroll()
    end
  end

  btnHome:SetScript("OnClick", function()
    applyNavTab("home")
  end)
  btnLista:SetScript("OnClick", function()
    applyNavTab("list")
  end)
  btnLfg:SetScript("OnClick", function()
    applyNavTab("lfg")
  end)
  btnGuilda:SetScript("OnClick", function()
    applyNavTab("guild")
  end)
  btnMensagens:SetScript("OnClick", function()
    applyNavTab("messages")
  end)
  btnGrupo:SetScript("OnClick", function()
    applyNavTab("group")
  end)
  btnTermos:SetScript("OnClick", function()
    applyNavTab("settings")
  end)
  f.cefApplyNavTab = applyNavTab
  applyNavTab("home")

  f.cefIsFullscreen = false
  local fullscreenBtn = CreateFrame("Button", nil, titleBar)
  fullscreenBtn:SetSize(30, 22)
  fullscreenBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
  CEF.UIFilters.attachFullscreenIcon(fullscreenBtn)
  f.cefFullscreenBtn = fullscreenBtn
  local function setFullscreenBtnLook(isFs)
    CEF.UIFilters.setFullscreenIcon(fullscreenBtn, isFs)
  end
  fullscreenBtn:SetScript("OnEnter", function()
    if fullscreenBtn.cefFsIcon and fullscreenBtn.cefFsIcon.tex then
      fullscreenBtn.cefFsIcon.tex:SetVertexColor(1, 0.92, 0.45)
    end
  end)
  fullscreenBtn:SetScript("OnLeave", function()
    if fullscreenBtn.cefFsIcon and fullscreenBtn.cefFsIcon.tex then
      fullscreenBtn.cefFsIcon.tex:SetVertexColor(1.0, 0.82, 0.0)
    end
  end)

  -- Timer anti-AFK no header (só fullscreen): reseta ao mexer o personagem.
  local AFK_IDLE_LIMIT = 5 * 60
  local afkDeadline = 0
  -- Avisos com 2 min e 1 min restantes (timer total = 5 min).
  local afkWarnedAt = { [120] = false, [60] = false }
  local afkWasMoving = false
  local afkTimerFs = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  afkTimerFs:SetPoint("RIGHT", fullscreenBtn, "LEFT", -10, 0)
  afkTimerFs:SetJustifyH("RIGHT")
  afkTimerFs:Hide()
  f.cefAfkTimerFs = afkTimerFs

  local function formatAfkMmSs(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
  end

  local function resetAfkIdleTimer()
    afkDeadline = GetTime() + AFK_IDLE_LIMIT
    afkWarnedAt[120] = false
    afkWarnedAt[60] = false
  end

  local function stopAfkIdleTimer()
    afkDeadline = 0
    afkWasMoving = false
    afkTimerFs:Hide()
  end

  local function paintAfkIdleTimer()
    if not f.cefIsFullscreen or not f:IsShown() or afkDeadline <= 0 then
      afkTimerFs:Hide()
      return
    end
    local left = afkDeadline - GetTime()
    if left < 0 then
      left = 0
    end
    local timeStr = formatAfkMmSs(left)
    local label = (CEF.L and CEF.L("AFK_TIMER_FMT", timeStr)) or ("Move: " .. timeStr)
    if left <= 60 then
      afkTimerFs:SetText("|cffff4444" .. label .. "|r")
    elseif left <= 120 then
      afkTimerFs:SetText("|cffffcc66" .. label .. "|r")
    else
      afkTimerFs:SetText("|cffbbbbbb" .. label .. "|r")
    end
    afkTimerFs:Show()

    for _, threshold in ipairs({ 120, 60 }) do
      if left <= threshold and not afkWarnedAt[threshold] then
        afkWarnedAt[threshold] = true
        local msg = (CEF.L and CEF.L("AFK_TIMER_WARN", timeStr))
          or ("Move your character to avoid disconnect (" .. timeStr .. " left).")
        print("|cffffcc66CEF:|r " .. msg)
      end
    end
  end

  local function playerIsMovingNow()
    if IsPlayerMoving then
      return IsPlayerMoving() and true or false
    end
    return (GetUnitSpeed and GetUnitSpeed("player") or 0) > 0
  end

  local function startAfkIdleTimer()
    resetAfkIdleTimer()
    afkWasMoving = playerIsMovingNow()
    paintAfkIdleTimer()
  end

  f.cefTickAfkIdleTimer = function()
    if not f.cefIsFullscreen or not f:IsShown() then
      return
    end
    local moving = playerIsMovingNow()
    if moving and not afkWasMoving then
      resetAfkIdleTimer()
    end
    afkWasMoving = moving
    paintAfkIdleTimer()
  end

  local afkMoveFrame = CreateFrame("Frame")
  afkMoveFrame:RegisterEvent("PLAYER_STARTED_MOVING")
  afkMoveFrame:SetScript("OnEvent", function()
    if f.cefIsFullscreen and f:IsShown() then
      resetAfkIdleTimer()
      paintAfkIdleTimer()
    end
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
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(0)
    f:SetMovable(false)
    titleBar:SetScript("OnDragStart", nil)
    titleBar:SetScript("OnDragStop", nil)
    f.cefIsFullscreen = true
    setFullscreenBtnLook(true)
    startAfkIdleTimer()
    syncTableLayout()
    if f.cefRelayoutSettingsTerms then
      f.cefRelayoutSettingsTerms()
    end
    if f.cefNavTab == "list" and f.cefSyncListScroll then
      f.cefSyncListScroll()
    elseif f.cefNavTab == "guild" then
      if f.cefScheduleGuildLayoutSync then
        f.cefScheduleGuildLayoutSync()
      elseif f.cefSyncGuildLayout then
        f.cefSyncGuildLayout()
      end
    elseif f.cefNavTab == "messages" then
      if f.cefScheduleChatLayoutSync then
        f.cefScheduleChatLayoutSync()
      elseif CEF.ChatUI and CEF.ChatUI.refresh then
        CEF.ChatUI.refresh()
      end
    elseif f.cefNavTab == "group" then
      if f.cefScheduleGroupLayoutSync then
        f.cefScheduleGroupLayoutSync()
      elseif f.cefSyncGroupLayout then
        f.cefSyncGroupLayout()
      end
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
    stopAfkIdleTimer()
    syncTableLayout()
    if f.cefRelayoutSettingsTerms then
      f.cefRelayoutSettingsTerms()
    end
    if f.cefNavTab == "list" and f.cefSyncListScroll then
      f.cefSyncListScroll()
    elseif f.cefNavTab == "guild" then
      if f.cefScheduleGuildLayoutSync then
        f.cefScheduleGuildLayoutSync()
      elseif f.cefSyncGuildLayout then
        f.cefSyncGuildLayout()
      end
    elseif f.cefNavTab == "messages" then
      if f.cefScheduleChatLayoutSync then
        f.cefScheduleChatLayoutSync()
      elseif CEF.ChatUI and CEF.ChatUI.refresh then
        CEF.ChatUI.refresh()
      end
    elseif f.cefNavTab == "group" then
      if f.cefScheduleGroupLayoutSync then
        f.cefScheduleGroupLayoutSync()
      elseif f.cefSyncGroupLayout then
        f.cefSyncGroupLayout()
      end
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
    layoutSettingsTopPanel()
    syncTableLayout()
    if f.cefNavTab == "guild" then
      if f.cefScheduleGuildLayoutSync then
        f.cefScheduleGuildLayoutSync()
      elseif f.cefSyncGuildLayout then
        f.cefSyncGuildLayout()
      end
    elseif f.cefNavTab == "messages" then
      if f.cefScheduleChatLayoutSync then
        f.cefScheduleChatLayoutSync()
      end
    elseif f.cefNavTab == "group" then
      if f.cefScheduleGroupLayoutSync then
        f.cefScheduleGroupLayoutSync()
      end
    end
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
        if f.cefTickAfkIdleTimer then
          f.cefTickAfkIdleTimer()
        end
        if f.cefNavTab == "home" and CEF.HomeUI and CEF.HomeUI.refresh then
          CEF.HomeUI.refresh()
        end
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
      if f.cefNavTab == "guild" then
        if f.cefScheduleGuildLayoutSync then
          f.cefScheduleGuildLayoutSync()
        elseif f.cefSyncGuildLayout then
          f.cefSyncGuildLayout()
        end
      end
      if f.cefNavTab == "messages" and f.cefScheduleChatLayoutSync then
        f.cefScheduleChatLayoutSync()
      end
      if f.cefNavTab == "group" and f.cefScheduleGroupLayoutSync then
        f.cefScheduleGroupLayoutSync()
      end
      if f.cefRelayoutSettingsTerms and f.cefNavTab == "settings" then
        f.cefRelayoutSettingsTerms()
      end
    end)
  end
  f:HookScript("OnShow", scheduleUiLayoutSync)

  layoutSettingsTopPanel()
  -- Primeira sincronização (alinha cabeçalho e renderiza)
  syncTableLayout()
  scheduleUiLayoutSync()

  local function applyLocaleToFrame()
    if CEF.clearInstanceDisplayNameCache then
      CEF.clearInstanceDisplayNameCache()
    end
    if CEF.clearZoneDisplayNameCache then
      CEF.clearZoneDisplayNameCache()
    end
    if CEF.refreshIntentLocaleLabels then
      CEF.refreshIntentLocaleLabels()
    end
    if CEF.refreshRoleLocaleLabels then
      CEF.refreshRoleLocaleLabels()
    end
    if btnHome and btnHome.fs then
      btnHome.fs:SetText(CEF.L.TAB_HOME)
    end
    if btnLista and btnLista.fs then
      btnLista.fs:SetText(CEF.L.TAB_LIST)
    end
    if btnLfg and btnLfg.fs then
      btnLfg.fs:SetText(CEF.L.TAB_LFG)
    end
    if btnGuilda and btnGuilda.fs then
      btnGuilda.fs:SetText(CEF.L.TAB_GUILD)
    end
    if btnMensagens and btnMensagens.fs then
      btnMensagens.fs:SetText(CEF.L.TAB_MESSAGES)
    end
    if btnGrupo and btnGrupo.fs then
      btnGrupo.fs:SetText(CEF.L.TAB_GROUP)
    end
    if btnTermos and btnTermos.fs then
      btnTermos.fs:SetText(CEF.L.TAB_TERMS)
    end
    if f.cefApplyHomeLocale then
      f.cefApplyHomeLocale()
    end
    if CEF.LFGUI and CEF.LFGUI.refreshLocale then
      CEF.LFGUI.refreshLocale(f)
    end
    searchPlaceholder:SetText(CEF.L.SEARCH_PLACEHOLDER_LIST)
    if f.filterInstanceSearchPlaceholder then
      f.filterInstanceSearchPlaceholder:SetText(CEF.L.FILTER_INSTANCE_SEARCH or "Search instance…")
    end
    resetFs:SetText(CEF.L.RESET)
    header.h1:SetText(CEF.L.COL_INSTANCE_LEVELS)
    header.h3:SetText(CEF.L.COL_MESSAGE)
    header.h4:SetText(CEF.L.COL_CHARACTER)
    header.h5:SetText(CEF.L.COL_TIME)
    header.h6:SetText(CEF.L.COL_ACTION)
    CEF.UIFilters.updateFilterDropSummary(filterDropSummaryFS, st().filterInstanceKeys)
    CEF.UIFilters.updateIntentFilterDropSummary(filterIntentDropSummaryFS, st().filterIntentKeys)
    CEF.UIFilters.updateRoleFilterDropSummary(filterRoleDropSummaryFS, st().filterRoleKeys)
    if localeLabel then
      localeLabel:SetText("|cffffcc66" .. CEF.L.LOCALE_LABEL .. "|r")
    end
    if localeDropFS then
      localeDropFS:SetText(CEF.Locale.chooserSummaryText())
    end
    if f.cefChatAlertFs then
      f.cefChatAlertFs:SetText(CEF.L.SETTINGS_CHAT_LISTING_ALERTS or "Print new Chat listings to the game chat")
    end
    if f.cefSyncChatAlertCheck then
      f.cefSyncChatAlertCheck()
    end
    stpAboutTitle:SetText(CEF.L.TERMS_ABOUT_TITLE)
    stpAboutBody:SetText(CEF.L.TERMS_ABOUT_BODY)
    stpInstTitle:SetText(CEF.L.TERMS_INSTANCES_TITLE)
    stpInstBody:SetText(CEF.L.TERMS_INSTANCES_BODY)
    stth1:SetText(CEF.L.TERMS_COL_INSTANCE_ZONE)
    stth2:SetText(CEF.L.TERMS_COL_LEVELS)
    stth3:SetText(CEF.L.TERMS_COL_KEYWORDS)
    for _, e in ipairs(settingsTermsLayoutOrder) do
      if e.kind == "instance" and e.fsNome and e.instanceKey then
        local nameTag = e.isRaid and COLOR_RAID_NAME_ST or COLOR_DG_NAME_ST
        e.fsNome:SetText(nameTag .. CEF.getInstanceDisplayName(e.instanceKey) .. "|r")
      end
      if e.localeKey and e.fs then
        local t = CEF.L[e.localeKey]
        if e.colorPrefix then
          e.fs:SetText(e.colorPrefix .. t .. "|r")
        elseif e.gold then
          e.fs:SetText("|cffffcc66" .. t .. "|r")
        elseif e.grey then
          if type(t) == "string" and t:find("|c", 1, true) then
            e.fs:SetText(t)
          else
            e.fs:SetText("|cffc8c8c8" .. t .. "|r")
          end
        else
          e.fs:SetText(t)
        end
      end
    end
    layoutSettingsTopPanel()
    if f.cefRelayoutSettingsTerms then
      f.cefRelayoutSettingsTerms()
    end
    if f.cefApplyGuildLocale then
      f.cefApplyGuildLocale()
    end
    if f.cefApplyChatLocale then
      f.cefApplyChatLocale()
    end
    if f.cefApplyGroupLocale then
      f.cefApplyGroupLocale()
    end
    CEF.UI.refreshUI()
    if f.cefRebuildLocaleMenu and f.filterLocaleMenu and f.filterLocaleMenu:IsShown() then
      f.cefRebuildLocaleMenu()
    end
  end
  f.cefApplyLocale = applyLocaleToFrame
  CEF.Locale.onChanged(applyLocaleToFrame)

  return f
end

