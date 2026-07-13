-- Módulo: motor de layout/virtualização da tabela
-- Exposto em ClassicEraFinder.UIEngine.*

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UIEngine = CEF.UIEngine or {}
local UIE = CEF.UIEngine

local function getUI()
  CEF.UI = CEF.UI or {}
  return CEF.UI
end

function UIE.layoutRows()
  local ui = getUI()
  local scrollChild = ui.scrollChild
  local scrollFrame = ui.scrollFrame
  local rowFrames = ui.rowFrames
  local CC = CEF.CONST
  if not scrollChild or not scrollFrame or not rowFrames then
    return
  end

  -- Lista filtrada sempre a partir de CEF.state (evita dessincronia com a UI).
  CEF.Entries.rebuildFilteredView()
  local filteredView = CEF.Entries.getFilteredView()
  local n = #filteredView
  local allEntries = CEF.Entries.getAll and CEF.Entries.getAll()
  local allN = (type(allEntries) == "table" and #allEntries) or n
  local footFs = ui.listFooterLabel
  if footFs and CEF.L then
    if n ~= allN then
      footFs:SetText(CEF.L("LFG_RESULT_COUNT_FILTERED", n, allN))
    else
      footFs:SetText(CEF.L("LFG_RESULT_COUNT", n))
    end
  end
  if n < 0 then
    return
  end

  local rowHeights, rowStarts = {}, {}
  local cum = 0
  rowStarts[1] = 0
  for idx = 1, n do
    local h = CEF.UILayout.entryRowTotalHeight(filteredView[idx]) or CC.ROW_HEIGHT
    if h < CC.ROW_HEIGHT then
      h = CC.ROW_HEIGHT
    end
    rowHeights[idx] = h
    cum = cum + h
    rowStarts[idx + 1] = cum
  end

  local totalH = math.max(cum, 1)
  scrollChild:SetHeight(totalH)

  local viewH = scrollFrame:GetHeight() or CC.ROW_HEIGHT
  local maxScroll = math.max(0, totalH - viewH)
  local vs = scrollFrame:GetVerticalScroll() or 0
  if vs > maxScroll then
    vs = maxScroll
    scrollFrame:SetVerticalScroll(maxScroll)
  elseif vs < 0 then
    vs = 0
    scrollFrame:SetVerticalScroll(0)
  end

  local scrollY = vs
  local bottomWithBuffer = scrollY + viewH + (viewH * 0.25)

  local first, last = 1, 0
  if n > 0 then
    local low, high = 1, n
    while low < high do
      local mid = math.floor((low + high) / 2)
      if rowStarts[mid + 1] <= scrollY then
        low = mid + 1
      else
        high = mid
      end
    end
    first = low
    last = first
    while last <= n and rowStarts[last] < bottomWithBuffer do
      last = last + 1
    end
    last = last - 1
  end

  for _, rf in ipairs(rowFrames) do
    rf:Hide()
  end

  for i = first, last do
    local rowIndex = i - first + 1
    if rowIndex > CC.MAX_ROW_FRAMES_POOL then
      break
    end
    local rf = rowFrames[rowIndex]
    if not rf then
      rf = CreateFrame("Frame", nil, scrollChild)
      rf:SetClipsChildren(true)
      rf:SetHeight((rowHeights[i] or CC.ROW_HEIGHT))

      local bg = rf:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      rf.bg = bg

      rf.colInst = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colLvl = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colMsg = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colName = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      rf.colTime = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

      rf.actionBtn = CreateFrame("Button", nil, rf)
      rf.actionBtn:SetHeight(CC.ACTION_BTN_HEIGHT)
      local abg = rf.actionBtn:CreateTexture(nil, "BACKGROUND")
      abg:SetAllPoints()
      abg:SetColorTexture(CC.ACTION_BTN_INVITE_BG_R, CC.ACTION_BTN_INVITE_BG_G, CC.ACTION_BTN_INVITE_BG_B, CC.ACTION_BTN_BG_A)
      rf.actionBtn.bgTex = abg
      local ahi = rf.actionBtn:CreateTexture(nil, "HIGHLIGHT")
      ahi:SetAllPoints()
      ahi:SetColorTexture(CC.ACTION_BTN_HI_INVITE_R, CC.ACTION_BTN_HI_INVITE_G, CC.ACTION_BTN_HI_INVITE_B, CC.ACTION_BTN_HI_A)
      rf.actionBtn.hiTex = ahi
      rf.actionBtn:SetHighlightTexture(ahi)

      local afs = rf.actionBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      afs:SetPoint("LEFT", 2, 0)
      afs:SetPoint("RIGHT", -2, 0)
      afs:SetJustifyH("CENTER")
      rf.actionBtn.actionLabel = afs

      rf.actionBtn:RegisterForClicks("LeftButtonUp")
      rf.actionBtn:SetScript("OnClick", function(self)
        local ent = self.cefEntry
        if not ent or not ent.sender or CEF.UIUtils.entryIsSelf(ent) then
          return
        end
        local name = ent.sender
        if self.cefIntent == "invite" then
          InviteUnit(name)
        else
          if CEF.UI and CEF.UI.openWhisperInHub then
            CEF.UI.openWhisperInHub(name)
          end
        end
      end)

      rf.colInst:SetJustifyH("LEFT")
      rf.colLvl:SetJustifyH("LEFT")
      rf.colInst:SetJustifyV("TOP")
      rf.colLvl:SetJustifyV("TOP")
      rf.colMsg:SetJustifyH("LEFT")
      rf.colMsg:SetJustifyV("TOP")
      rf.colMsg:SetWordWrap(false)
      if rf.colMsg.SetMaxLines then
        rf.colMsg:SetMaxLines(1)
      end
      rf.colName:SetJustifyH("LEFT")
      rf.colName:SetJustifyV("TOP")
      rf.colTime:SetJustifyH("LEFT")
      rf.colTime:SetJustifyV("TOP")

      rf.rowBotSep = rf:CreateTexture(nil, "ARTWORK")
      rf.rowBotSep:SetHeight(1)
      rf.rowBotSep:SetColorTexture(0, 0, 0, 0.22)
      rf.rowBotSep:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 4, 0)
      rf.rowBotSep:SetPoint("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -4, 0)

      rf.msgHit = CreateFrame("Frame", nil, rf)
      rf.msgHit:EnableMouse(true)
      rf.msgHit:SetFrameLevel((rf:GetFrameLevel() or 0) + 10)
      rf.msgHit:SetScript("OnEnter", function(self)
        local ent = self.cefEntry
        if not ent or not ent.text then
          return
        end
        CEF.UIUtils.cefTooltipShow(self, ent)
      end)
      rf.msgHit:SetScript("OnLeave", CEF.UIUtils.cefTooltipHide)

      rowFrames[rowIndex] = rf
    else
      rf:SetClipsChildren(true)
      if rf and not rf.colLvl then
        rf.colLvl = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rf.colLvl:SetJustifyH("LEFT")
        rf.colLvl:SetJustifyV("TOP")
      end
    end

    local e = filteredView[i]
    rf:SetHeight((rowHeights[i] or CC.ROW_HEIGHT))
    rf:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -rowStarts[i])
    rf:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -rowStarts[i])
    rf:Show()

    if rf.actionBtn then
      local sw = scrollChild and scrollChild:GetWidth() or 960
      local c1, c2, c3, c4, c5, c6, x1, x2, x3, x4, x5, x6 = CEF.UILayout.columnWidths(sw)
      local w6 = math.max(56, c6 - CC.COL_GAP)
      rf.actionBtn:ClearAllPoints()
      rf.actionBtn:SetHeight(CC.ACTION_BTN_HEIGHT)
      rf.actionBtn:SetPoint("LEFT", rf, "LEFT", x6 + 2, 0)
      rf.actionBtn:SetWidth(math.max(52, w6 - 4))
    end

    if (i % 2) == 0 then
      rf.bg:SetColorTexture(0.12, 0.12, 0.14, 0.9)
    else
      rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
    end

    rf.colInst:SetText(CEF.entryInstancesComboRichText(e))
    if rf.colLvl then
      rf.colLvl:SetText("")
      rf.colLvl:Hide()
    end

    local msgLines = CEF.UILayout.entryMessageDisplayLineBudget(e)
    local sw = (scrollChild and scrollChild:GetWidth()) or 800
    local c3 = select(3, CEF.UILayout.columnWidths(sw))
    rf.colMsg:SetWidth(math.max(50, c3 - CC.COL_GAP))
    if msgLines > 1 then
      rf.colMsg:SetWordWrap(true)
      if rf.colMsg.SetMaxLines then
        rf.colMsg:SetMaxLines(msgLines)
      end
    else
      rf.colMsg:SetWordWrap(false)
      if rf.colMsg.SetMaxLines then
        rf.colMsg:SetMaxLines(1)
      end
    end

    local disp = select(1, CEF.UIUtils.formatMessageCell(e.text or "", msgLines))
    rf.colMsg:SetText(disp)
    if rf.msgHit then
      rf.msgHit.cefEntry = e
    end
    if rf.rowBotSep then
      rf.rowBotSep:Show()
    end

    local r, g, b = CEF.UIUtils.classColorRGB(e.guid)
    rf.colName:SetText(CEF.stripRealm(e.sender))
    rf.colName:SetTextColor(r, g, b)
    rf.colTime:SetText(CEF.UIUtils.formatRelativeAge(e.time))

    local intent = CEF.classifyMessageIntent(e.text)
    if rf.actionBtn then
      rf.actionBtn.cefEntry = e
      rf.actionBtn.cefIntent = intent
      if rf.actionBtn.actionLabel then
        if intent == "invite" then
          rf.actionBtn.actionLabel:SetText(CEF.L.INVITE)
        else
          rf.actionBtn.actionLabel:SetText(CEF.L.WHISPER)
        end
      end

      if CEF.UIUtils.entryIsSelf(e) then
        rf.actionBtn:Disable()
        if rf.actionBtn.bgTex then
          rf.actionBtn.bgTex:SetColorTexture(
            CC.ACTION_BTN_DISABLED_BG_R,
            CC.ACTION_BTN_DISABLED_BG_G,
            CC.ACTION_BTN_DISABLED_BG_B,
            CC.ACTION_BTN_DISABLED_BG_A
          )
        end
        if rf.actionBtn.actionLabel then
          rf.actionBtn.actionLabel:SetTextColor(CC.ACTION_BTN_LABEL_DISABLED_R, CC.ACTION_BTN_LABEL_DISABLED_G, CC.ACTION_BTN_LABEL_DISABLED_B)
        end
      else
        rf.actionBtn:Enable()
        if rf.actionBtn.bgTex then
          if intent == "invite" then
            rf.actionBtn.bgTex:SetColorTexture(CC.ACTION_BTN_INVITE_BG_R, CC.ACTION_BTN_INVITE_BG_G, CC.ACTION_BTN_INVITE_BG_B, CC.ACTION_BTN_BG_A)
          else
            rf.actionBtn.bgTex:SetColorTexture(CC.ACTION_BTN_WHISPER_BG_R, CC.ACTION_BTN_WHISPER_BG_G, CC.ACTION_BTN_WHISPER_BG_B, CC.ACTION_BTN_BG_A)
          end
        end
        if rf.actionBtn.hiTex then
          if intent == "invite" then
            rf.actionBtn.hiTex:SetColorTexture(CC.ACTION_BTN_HI_INVITE_R, CC.ACTION_BTN_HI_INVITE_G, CC.ACTION_BTN_HI_INVITE_B, CC.ACTION_BTN_HI_A)
          else
            rf.actionBtn.hiTex:SetColorTexture(CC.ACTION_BTN_HI_WHISPER_R, CC.ACTION_BTN_HI_WHISPER_G, CC.ACTION_BTN_HI_WHISPER_B, CC.ACTION_BTN_HI_A)
          end
        end
        if rf.actionBtn.actionLabel then
          rf.actionBtn.actionLabel:SetTextColor(CC.ACTION_BTN_LABEL_R, CC.ACTION_BTN_LABEL_G, CC.ACTION_BTN_LABEL_B)
        end
      end

      rf.actionBtn:Show()
    end
  end
end

function UIE.applyColumnWidths()
  local ui = getUI()
  local scrollChild = ui.scrollChild
  local rowFrames = ui.rowFrames
  local CC = CEF.CONST
  if not scrollChild or not rowFrames then
    return
  end

  local w = scrollChild:GetWidth()
  local c1, c2, c3, c4, c5, c6, x1, x2, x3, x4, x5, x6 = CEF.UILayout.columnWidths(w)

  local w1 = math.max(100, c1 - CC.COL_GAP)
  local w3 = math.max(50, c3 - CC.COL_GAP)
  local w4 = math.max(36, c4 - CC.COL_GAP)
  local w5 = math.max(40, c5 - CC.COL_GAP)
  local w6 = math.max(56, c6 - CC.COL_GAP)

  for _, rf in ipairs(rowFrames) do
    if rf and rf.colInst then
      rf.colInst:ClearAllPoints()
      if rf.colLvl then
        rf.colLvl:ClearAllPoints()
        rf.colLvl:SetText("")
        rf.colLvl:Hide()
      end
      rf.colMsg:ClearAllPoints()
      rf.colName:ClearAllPoints()
      rf.colTime:ClearAllPoints()

      local rh = rf:GetHeight() or CC.ROW_HEIGHT
      rf.colInst:SetJustifyV("MIDDLE")
      rf.colInst:SetHeight(rh)
      rf.colMsg:SetJustifyV("MIDDLE")
      rf.colMsg:SetHeight(rh)
      rf.colName:SetJustifyV("MIDDLE")
      rf.colName:SetHeight(rh)
      rf.colTime:SetJustifyV("MIDDLE")
      rf.colTime:SetHeight(rh)

      rf.colInst:SetPoint("TOPLEFT", rf, "TOPLEFT", x1, 0)
      rf.colInst:SetWidth(w1)
      rf.colMsg:SetWidth(w3)
      rf.colMsg:SetPoint("TOPLEFT", rf, "TOPLEFT", x3, 0)
      rf.colName:SetWidth(w4)
      rf.colName:SetPoint("TOPLEFT", rf, "TOPLEFT", x4, 0)
      rf.colTime:SetWidth(w5)
      rf.colTime:SetPoint("TOPLEFT", rf, "TOPLEFT", x5, 0)

      if rf.actionBtn then
        rf.actionBtn:ClearAllPoints()
        rf.actionBtn:SetHeight(CC.ACTION_BTN_HEIGHT)
        rf.actionBtn:SetPoint("LEFT", rf, "LEFT", x6 + 2, 0)
        rf.actionBtn:SetWidth(math.max(52, w6 - 4))
      end

      if rf.msgHit then
        rf.msgHit:ClearAllPoints()
        rf.msgHit:SetPoint("TOPLEFT", rf.colMsg, "TOPLEFT", -3, 0)
        rf.msgHit:SetPoint("BOTTOMRIGHT", rf.colMsg, "BOTTOMRIGHT", 3, 0)
      end

      if not rf.rowBotSep then
        rf.rowBotSep = rf:CreateTexture(nil, "ARTWORK")
        rf.rowBotSep:SetHeight(1)
        rf.rowBotSep:SetColorTexture(0, 0, 0, 0.22)
        rf.rowBotSep:SetPoint("BOTTOMLEFT", rf, "BOTTOMLEFT", 4, 0)
        rf.rowBotSep:SetPoint("BOTTOMRIGHT", rf, "BOTTOMRIGHT", -4, 0)
      end
    end
  end
end

function UIE.refreshRelativeTimesOnly()
  local ui = getUI()
  local scrollChild = ui.scrollChild
  local scrollFrame = ui.scrollFrame
  local rowFrames = ui.rowFrames
  local CC = CEF.CONST
  if not scrollChild or not scrollFrame or not rowFrames then
    return
  end

  CEF.Entries.rebuildFilteredView()
  local filteredView = CEF.Entries.getFilteredView()
  local n = #filteredView
  if n <= 0 then
    return
  end

  local rowHeights, rowStarts = {}, {}
  local cum = 0
  rowStarts[1] = 0
  for idx = 1, n do
    local h = CEF.UILayout.entryRowTotalHeight(filteredView[idx]) or CC.ROW_HEIGHT
    if h < CC.ROW_HEIGHT then
      h = CC.ROW_HEIGHT
    end
    rowHeights[idx] = h
    cum = cum + h
    rowStarts[idx + 1] = cum
  end

  local totalH = math.max(cum, 1)
  local viewH = scrollFrame:GetHeight() or CC.ROW_HEIGHT
  local maxScroll = math.max(0, totalH - viewH)
  local vs = scrollFrame:GetVerticalScroll() or 0
  if vs > maxScroll then
    vs = maxScroll
  elseif vs < 0 then
    vs = 0
  end

  local scrollY = vs
  local bottomWithBuffer = scrollY + viewH + (viewH * 0.25)

  local first, last = 1, 0
  if n > 0 then
    local low, high = 1, n
    while low < high do
      local mid = math.floor((low + high) / 2)
      if rowStarts[mid + 1] <= scrollY then
        low = mid + 1
      else
        high = mid
      end
    end
    first = low
    last = first
    while last <= n and rowStarts[last] < bottomWithBuffer do
      last = last + 1
    end
    last = last - 1
  end

  local lastShown = math.min(n, last, first + CC.MAX_ROW_FRAMES_POOL - 1)
  local sw = scrollChild and scrollChild:GetWidth() or 960
  local c1, c2, c3, c4, c5, c6, x1, x2, x3, x4, x5, x6 = CEF.UILayout.columnWidths(sw)
  local w6 = math.max(56, c6 - CC.COL_GAP)

  for i = first, lastShown do
    local rowIndex = i - first + 1
    local rf = rowFrames[rowIndex]
    local e = filteredView[i]

    if rf and rf.colTime and e then
      rf.colTime:SetText(CEF.UIUtils.formatRelativeAge(e.time))
    end
    if rf and rf.actionBtn then
      rf.actionBtn:ClearAllPoints()
      rf.actionBtn:SetHeight(CC.ACTION_BTN_HEIGHT)
      rf.actionBtn:SetPoint("LEFT", rf, "LEFT", x6 + 2, 0)
      rf.actionBtn:SetWidth(math.max(52, w6 - 4))
    end
  end
end

