-- Módulo: construção da aba “Termos” (painel Sobre + tabela 3 colunas com
-- masmorras/raides/padrões reconhecidos). Antes vivia inline em UI.lua
-- (~540 linhas). Extraído para reduzir o tamanho de createMainUI.
--
-- Uso:
--
--   local terms = CEF.UITerms.build(mainFrame, navBar, {
--     rightScrollOutset = RIGHT_SCROLL_OUTSET,
--   })
--   terms.settingsTopPanel, terms.settingsTermsTableHeader, terms.settingsScroll,
--   terms.settingsSBar, terms.settingsSBarThumb       -- regions
--   terms.relayout()                                   -- força relayout
--   terms.syncScrollbar()                              -- recalcula thumb

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UITerms = CEF.UITerms or {}
local UT = CEF.UITerms

function UT.build(f, navBar, params)
  params = params or {}
  local RIGHT_SCROLL_OUTSET = params.rightScrollOutset or 18
  local CC = CEF.CONST or {}
  local L = CEF.L or {}

  local settingsTopPanel = CreateFrame("Frame", nil, f)
  local TERMS_H_PAD = CC.TABLE_PAD or 10
  local TERMS_TABLE_LEFT = math.max(2, (CC.TABLE_PAD or 10) - 4)
  settingsTopPanel:Hide()
  settingsTopPanel:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  local STP_PAD = CC.TABLE_PAD or 10
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
  stpAboutTitle:SetText("|cffffcc66" .. (L["termsAboutTitle"] or "About this page") .. "|r")
  stpAboutBody:SetText(L["termsAboutBody"] or "Reference for the patterns used on chat.")
  stpInstTitle:SetText("|cffffcc66" .. (L["termsInstances"] or "Recognized instances") .. "|r")
  stpInstBody:SetText(L["termsInstancesBody"] or "Text matching is case-insensitive.")

  local function layoutSettingsTopPanel()
    local fw = math.max(100, (f:GetWidth() or 960) - 4)
    settingsTopPanel:SetWidth(fw)
    local w = fw - TERMS_H_PAD * 2
    if w < 120 then
      w = math.max(120, fw - TERMS_H_PAD * 2)
    end
    stpAboutTitle:SetWidth(w)
    stpAboutBody:SetWidth(w)
    stpInstTitle:SetWidth(w)
    stpInstBody:SetWidth(w)
    local y = STP_PAD
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
  stth1:SetText("|cffc8c8c8" .. (L["termsTableColInstance"] or "Instance / zone") .. "|r")
  stth2:SetText("|cffc8c8c8" .. (L["termsTableColLevels"] or "Levels") .. "|r")
  stth3:SetText("|cffc8c8c8" .. (L["termsTableColKeywords"] or "Keywords") .. "|r")
  f.settingsTermsTableHeader = settingsTermsTableHeader

  local settingsScroll

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
    local function pushSectionTitle(txt)
      local fs = settingsChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      fs:SetJustifyH("LEFT")
      fs:SetText("|cffffcc66" .. txt .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "sectionTitle", fs = fs }
    end

    local function pushParagraph(txt)
      local fs = settingsChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetJustifyH("LEFT")
      fs:SetWordWrap(true)
      fs:SetText(txt)
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "paragraph", fs = fs }
    end

    local function pushCategoryBanner(txt)
      local row = CreateFrame("Frame", nil, settingsChild)
      local bg = row:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.14, 0.11, 0.08, 0.98)
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      fs:SetPoint("LEFT", row, "LEFT", TERMS_TABLE_LEFT, 0)
      fs:SetJustifyH("LEFT")
      fs:SetText("|cffffcc66" .. txt .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "banner", row = row, fs = fs }
    end

    local function pushTableHeader1(lab)
      local row = CreateFrame("Frame", nil, settingsChild)
      local bg = row:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.2, 0.17, 0.13, 0.98)
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetPoint("LEFT", row, "LEFT", TERMS_TABLE_LEFT, 0)
      fs:SetJustifyH("LEFT")
      fs:SetText("|cffc8c8c8" .. lab .. "|r")
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "tableHeader1", row = row, fs = fs }
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
      local displayName = CEF.LocalizeInstance and CEF.LocalizeInstance(rowData.key) or rowData.key
      fsNome:SetText(nameTag .. displayName .. "|r")
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
      }
    end

    local function pushOneColRow(cellText, useLfgBlue, zebraZone)
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
      }
    end

    local function pushSpacer12()
      settingsTermsLayoutOrder[#settingsTermsLayoutOrder + 1] = { kind = "spacer", h = 12 }
    end

    local instCat = CEF.getInstanceDetectionCatalog()
    local grouped = CEF.getInstanceDetectionRowsGroupedSorted()

    local Lt = CEF.L or {}
    pushCategoryBanner(Lt["termsBannerDungeons"] or "Dungeons")
    for _, row in ipairs(grouped.dungeonsClassic or {}) do
      pushInstanceRow(row, false, 1)
    end
    if grouped.dungeonsTbc and #grouped.dungeonsTbc > 0 then
      pushCategoryBanner(Lt["termsBannerDungeonsTbc"] or "TBC — dungeons")
      for _, row in ipairs(grouped.dungeonsTbc) do
        pushInstanceRow(row, false, 1)
      end
    end
    pushCategoryBanner(Lt["termsBannerRaids"] or "Raids")
    for _, row in ipairs(grouped.raidsClassic or {}) do
      pushInstanceRow(row, true, 1)
    end
    if grouped.raidsTbc and #grouped.raidsTbc > 0 then
      pushCategoryBanner(Lt["termsBannerRaidsTbc"] or "TBC — raids")
      for _, row in ipairs(grouped.raidsTbc) do
        pushInstanceRow(row, true, 1)
      end
    end

    pushSpacer12()
    pushSectionTitle(Lt["termsScarletTitle"] or "Scarlet Monastery — generic phrases")
    pushParagraph(Lt["termsScarletBody"] or "Generic phrases assume all 4 wings.")
    pushTableHeader1(Lt["termsTableColPhrase"] or "Phrase / fragment")
    for _, phrase in ipairs(instCat.scarletGenericUiHints or {}) do
      pushOneColRow(phrase, false, 2)
    end
    for _, phrase in ipairs(instCat.scarletGeneric or {}) do
      pushOneColRow(phrase, false, 2)
    end

    pushSpacer12()
    pushSectionTitle(Lt["termsLfgTitle"] or "LFG patterns (messageLooksLFG)")
    pushParagraph(Lt["termsLfgBody"] or "Fragments that help treat the line as a group announcement.")
    pushTableHeader1(Lt["termsTableColPatternOrTerm"] or "Pattern / term")
    local msgCat = CEF.getMessageDetectionCatalog()
    for _, hint in ipairs(msgCat.lfgHints) do
      pushOneColRow(hint, true, 3)
    end

    pushSpacer12()
    pushSectionTitle(Lt["termsRecruitIntentTitle"] or "Intent: Looking for members (whisper)")
    pushParagraph(Lt["termsRecruitIntentBody"] or "Patterns that classify the line as recruitment. Row action becomes Whisper.")
    pushTableHeader1(Lt["termsTableColPattern"] or "Pattern / fragment")
    for _, phrase in ipairs(msgCat.recruitingIntentHints or {}) do
      pushOneColRow(phrase, false, 5)
    end

    pushSpacer12()
    pushSectionTitle(Lt["termsRecruitFirstWordTitle"] or "Recruiting — first word after \"lf \"")
    pushParagraph(Lt["termsRecruitFirstWordBody"] or "If the first word after \"lf \" is in this list, the line is treated as recruitment.")
    pushTableHeader1(Lt["termsTableColWord"] or "Word (spec / class / role)")
    for _, word in ipairs(msgCat.recruitFirstWords or {}) do
      pushOneColRow(word, true, 6)
    end

    pushSpacer12()
    pushSectionTitle(Lt["termsSeekingIntentTitle"] or "Intent: Looking for group (invite)")
    pushParagraph(Lt["termsSeekingIntentBody"] or "Patterns that classify the line as a player looking for group. Row action becomes Invite.")
    pushTableHeader1(Lt["termsTableColPattern"] or "Pattern / fragment")
    for _, phrase in ipairs(msgCat.seekingIntentHints or {}) do
      pushOneColRow(phrase, false, 7)
    end

    pushSpacer12()
    pushSectionTitle(Lt["termsExcludeTitle"] or "Exclusions (craft / portal / enchant)")
    pushParagraph(Lt["termsExcludeBody"] or "Do not list as instance announcement.")
    pushTableHeader1(Lt["termsTableColPattern"] or "Pattern / fragment")
    for _, phrase in ipairs(msgCat.professionTradeExclude) do
      pushOneColRow(phrase, false, 4)
    end
  end

  local function relayoutSettingsTermsTable()
    local sw = settingsScroll:GetWidth()
    if not sw or sw < 60 then
      local fwEst = math.max(100, (f:GetWidth() or 960) - 4)
      sw = math.max(60, fwEst - RIGHT_SCROLL_OUTSET)
    end
    settingsChild:SetWidth(sw)
    local rowInner = math.max(40, sw - 2 * TERMS_TABLE_LEFT)
    local nomeW, levelW, keyW = colWidthsForTerms(rowInner)
    local rowW = rowInner
    local zebraCount = { 0, 0, 0, 0, 0, 0, 0 }
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

  return {
    settingsTopPanel         = settingsTopPanel,
    settingsTermsTableHeader = settingsTermsTableHeader,
    settingsScroll           = settingsScroll,
    settingsChild            = settingsChild,
    settingsSBar             = settingsSBar,
    settingsSBarThumb        = settingsSBarThumb,
    relayout                 = relayoutSettingsTermsTable,
    syncScrollbar            = syncSettingsScrollbar,
    layoutTopPanel           = layoutSettingsTopPanel,
  }
end
