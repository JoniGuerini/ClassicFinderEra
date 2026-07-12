-- Módulo: UI da aba Grupo (barra de resumo, header e scroll virtualizado).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.GroupUI = CEF.GroupUI or {}
local GUI = CEF.GroupUI

local INFO_BAR_H = 30
local RIGHT_SCROLL_OUTSET = 20
local COL_COUNT = 7

-- Nome | Nível | Classe | Função | Grupo | Zona | Status (última absorve o resto).
local COL_FRACS = { 0.20, 0.07, 0.08, 0.14, 0.08, 0.24 }

local HDR_KEYS = {
  "COL_NAME",
  "COL_LEVEL",
  "COL_CLASS",
  "COL_ROLE",
  "COL_GROUP",
  "COL_ZONE",
  "COL_STATUS",
}

local function columnWidths(totalW)
  local CC = CEF.CONST
  local inner = math.max(420, totalW - 2 * CC.TABLE_PAD)
  local widths, xs = {}, {}
  local x = CC.TABLE_PAD
  local used = 0
  for i = 1, COL_COUNT - 1 do
    widths[i] = inner * COL_FRACS[i]
    xs[i] = x
    x = x + widths[i]
    used = used + widths[i]
  end
  widths[COL_COUNT] = math.max(40, inner - used)
  xs[COL_COUNT] = x
  return widths, xs
end

local function layoutHeaderColumns(header, scrollFrame)
  if not header then
    return
  end
  local CC = CEF.CONST
  local w = header:GetWidth()
  if scrollFrame and scrollFrame.GetWidth then
    local sw = scrollFrame:GetWidth()
    if sw and sw > 80 then
      w = sw
    end
  end
  local widths, xs = columnWidths(w)
  for i = 1, COL_COUNT do
    local h = header["h" .. i]
    if h then
      h:ClearAllPoints()
      h:SetPoint("LEFT", header, "LEFT", xs[i], 0)
      h:SetWidth(math.max(28, widths[i] - CC.COL_GAP))
      h:SetJustifyH("LEFT")
    end
  end
end

function GUI.refresh()
  GUI.layoutRows()
  if CEF.UI and CEF.UI.mainFrame and CEF.UI.mainFrame.cefSyncGroupScroll then
    CEF.UI.mainFrame.cefSyncGroupScroll()
  end
  GUI.updateEmptyState()
  GUI.updateInfoBar()
end

function GUI.updateInfoBar()
  local ui = CEF.UI or {}
  local fs = ui.groupInfoLabel
  if fs then
    fs:SetText(CEF.Group.summaryRichText())
  end
end

function GUI.updateEmptyState()
  local ui = CEF.UI or {}
  local empty = ui.groupEmptyLabel
  if not empty then
    return
  end
  if not CEF.Group.isInGroup() or #(CEF.Group.getMembers() or {}) == 0 then
    empty:SetText(CEF.L.GROUP_EMPTY_NOT_IN_GROUP)
    empty:Show()
  else
    empty:Hide()
  end
end

function GUI.layoutRows()
  local ui = CEF.UI or {}
  local scrollChild = ui.groupScrollChild
  local scrollFrame = ui.groupScrollFrame
  local rowFrames = ui.groupRowFrames
  local CC = CEF.CONST
  if not scrollChild or not scrollFrame or not rowFrames then
    return
  end

  local viewH = scrollFrame:GetHeight() or 0
  local childW = scrollChild:GetWidth() or 0
  if viewH < 8 or childW < 32 then
    return
  end

  local list = CEF.Group.getDisplayList()
  local n = #list
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
  if n == 0 then
    first, last = 1, 0
  end

  for _, rf in ipairs(rowFrames) do
    rf:Hide()
  end

  local w = childW
  if scrollFrame.GetWidth then
    local sw = scrollFrame:GetWidth() or 0
    if sw > w then
      w = sw
    end
  end
  local widths, xs = columnWidths(w)
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
      for c = 1, COL_COUNT do
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
    end

    local item = list[i]
    rf:ClearAllPoints()
    rf:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * rowH))
    rf:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -((i - 1) * rowH))
    rf:SetHeight(rowH)
    rf:Show()

    for c = 1, COL_COUNT do
      local fs = rf.cols[c]
      fs:ClearAllPoints()
      fs:SetPoint("LEFT", rf, "LEFT", xs[c], 0)
      fs:SetWidth(math.max(24, widths[c] - CC.COL_GAP))
      fs:SetJustifyH("LEFT")
      fs:SetJustifyV("MIDDLE")
      fs:SetHeight(rowH)
      fs:SetText("")
      fs:Show()
    end

    if item.kind == "hdr" then
      -- Cabeçalho de subgrupo (raide): faixa própria, sem colunas.
      rf.bg:SetColorTexture(0.16, 0.13, 0.08, 0.98)
      rf.cols[1]:ClearAllPoints()
      rf.cols[1]:SetPoint("LEFT", rf, "LEFT", xs[1], 0)
      rf.cols[1]:SetWidth(math.max(120, (widths[1] or 120) + (widths[2] or 0)))
      rf.cols[1]:SetText("|cffffcc66" .. CEF.L("GROUP_SUBGROUP_FMT", item.subgroup) .. "|r")
      rf.classIcon:Hide()
    else
      local m = item.member
      if (i % 2) == 0 then
        rf.bg:SetColorTexture(0.1, 0.1, 0.12, 0.85)
      else
        rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      end

      rf.cols[1]:SetText(CEF.Group.nameRichText(m))
      if CEF.Guild and CEF.Guild.levelColorRichText then
        rf.cols[2]:SetText(CEF.Guild.levelColorRichText(m.level))
      else
        rf.cols[2]:SetText(tostring(m.level or ""))
      end
      rf.classIcon:ClearAllPoints()
      rf.classIcon:SetSize(iconSize, iconSize)
      rf.classIcon:SetPoint("LEFT", rf, "LEFT", xs[3] + 2, 0)
      if CEF.Guild and CEF.Guild.setClassIconTexture then
        CEF.Guild.setClassIconTexture(rf.classIcon, m.classFile)
      end
      rf.cols[4]:SetText(CEF.Group.roleRichText(m))
      if CEF.Group.isRaid() then
        rf.cols[5]:SetText(tostring(m.subgroup or 1))
      else
        rf.cols[5]:SetText("|cff888888—|r")
      end
      local zone = m.zone or ""
      if zone ~= "" then
        rf.cols[6]:SetText((CEF.getZoneDisplayName and CEF.getZoneDisplayName(zone)) or zone)
      else
        rf.cols[6]:SetText("|cff888888—|r")
      end
      rf.cols[7]:SetText(CEF.Group.statusRichText(m))
    end
  end
end

function GUI.createPanels(f, navBar)
  local CC = CEF.CONST
  CEF.UI = CEF.UI or {}
  CEF.UI.groupRowFrames = CEF.UI.groupRowFrames or {}

  -- Barra de resumo (tipo · membros · líder).
  local infoBar = CreateFrame("Frame", nil, f)
  infoBar:SetHeight(INFO_BAR_H)
  infoBar:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  infoBar:SetPoint("TOPRIGHT", navBar, "BOTTOMRIGHT", 0, -4)
  infoBar:EnableMouse(true)
  infoBar:Hide()
  local ibBg = infoBar:CreateTexture(nil, "BACKGROUND")
  ibBg:SetAllPoints()
  ibBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)

  local infoLabel = infoBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  infoLabel:SetPoint("LEFT", infoBar, "LEFT", 12, 0)
  infoLabel:SetPoint("RIGHT", infoBar, "RIGHT", -12, 0)
  infoLabel:SetJustifyH("LEFT")
  infoLabel:SetText("")

  -- Header das colunas (estático, sem ordenação).
  local header = CreateFrame("Frame", nil, f)
  header:SetHeight(20)
  header:SetPoint("TOPLEFT", infoBar, "BOTTOMLEFT", 0, -4)
  header:SetPoint("TOPRIGHT", infoBar, "BOTTOMRIGHT", 0, -4)
  header:Hide()
  local hTex = header:CreateTexture(nil, "BACKGROUND")
  hTex:SetAllPoints()
  hTex:SetColorTexture(0.2, 0.18, 0.12, 0.95)
  for i = 1, COL_COUNT do
    local h = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetJustifyH("LEFT")
    h:SetJustifyV("MIDDLE")
    h:SetWordWrap(false)
    h:SetHeight(20)
    h:SetText(CEF.L[HDR_KEYS[i]])
    h:SetTextColor(1, 0.82, 0.18)
    header["h" .. i] = h
  end

  local scroll = CreateFrame("ScrollFrame", nil, f)
  scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, 6)
  scroll:EnableMouse(true)
  scroll:Hide()

  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(scroll:GetWidth())
  child:SetHeight(400)
  scroll:SetScrollChild(child)

  local emptyLabel = scroll:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyLabel:SetPoint("CENTER", scroll, "CENTER", 0, 0)
  emptyLabel:SetText("")
  emptyLabel:Hide()

  CEF.UI.groupInfoBar = infoBar
  CEF.UI.groupInfoLabel = infoLabel
  CEF.UI.groupHeader = header
  CEF.UI.groupScrollFrame = scroll
  CEF.UI.groupScrollChild = child
  CEF.UI.groupEmptyLabel = emptyLabel
  f.groupInfoBar = infoBar
  f.groupHeader = header
  f.groupScrollFrame = scroll

  local function onGroupWheel(_, delta)
    local n = #(CEF.Group.getDisplayList() or {})
    local totalH = math.max(1, n * CC.ROW_HEIGHT)
    local viewH = scroll:GetHeight() or CC.ROW_HEIGHT
    local maxScroll = math.max(0, totalH - viewH)
    local step = viewH * 0.75
    local vs = scroll:GetVerticalScroll()
    if delta > 0 then
      vs = math.max(0, vs - step)
    else
      vs = math.min(maxScroll, vs + step)
    end
    scroll:SetVerticalScroll(vs)
    GUI.refresh()
  end
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", onGroupWheel)

  -- Scrollbar custom, mesmo padrão da aba Guilda.
  local sbar = CreateFrame("Frame", nil, f)
  sbar:SetWidth(12)
  sbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 2, 0)
  sbar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 0)
  sbar:EnableMouse(true)
  sbar:SetFrameLevel((scroll:GetFrameLevel() or 0) + 8)
  sbar:Hide()
  local track = sbar:CreateTexture(nil, "BACKGROUND")
  track:SetAllPoints()
  track:SetColorTexture(0.04, 0.035, 0.07, 0.96)
  local thumb = CreateFrame("Button", nil, sbar)
  thumb:SetWidth(10)
  thumb:SetHeight(32)
  thumb:SetFrameLevel((sbar:GetFrameLevel() or 0) + 3)
  local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
  thumbTex:SetAllPoints()
  thumbTex:SetColorTexture(0.52, 0.5, 0.6, 0.88)
  thumb:SetNormalTexture(thumbTex)
  local thumbHi = thumb:CreateTexture(nil, "HIGHLIGHT")
  thumbHi:SetAllPoints()
  thumbHi:SetColorTexture(0.62, 0.58, 0.72, 0.55)
  thumb:SetHighlightTexture(thumbHi)
  thumb:RegisterForClicks("LeftButtonUp", "LeftButtonDown")

  local function syncGroupScroll()
    if not scroll:IsShown() then
      sbar:Hide()
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
      sbar:Show()
      local trackH = sbar:GetHeight() or 1
      local thumbH = math.min(trackH, math.max(24, math.floor(trackH * sh / math.max(ch, 1))))
      if thumbH > trackH then
        thumbH = trackH
      end
      thumb:SetHeight(thumbH)
      local range = math.max(1e-6, trackH - thumbH)
      local yFromTop = (maxV > 0) and ((cur / maxV) * range) or 0
      thumb:ClearAllPoints()
      local lx = math.max(0, (sbar:GetWidth() - thumb:GetWidth()) / 2)
      thumb:SetPoint("TOPLEFT", sbar, "TOPLEFT", lx, -yFromTop)
      thumb:Show()
    else
      sbar:Hide()
      thumb:Hide()
    end
  end
  f.cefSyncGroupScroll = syncGroupScroll
  scroll:SetScript("OnVerticalScroll", syncGroupScroll)
  sbar:EnableMouseWheel(true)
  sbar:SetScript("OnMouseWheel", onGroupWheel)

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
      local scale = sbar:GetEffectiveScale() or 1
      if scale < 0.01 then
        scale = 1
      end
      local deltaPx = (btn.cefLastCursorY - cy) / scale
      btn.cefLastCursorY = cy
      local ch = child:GetHeight() or 0
      local sh = scroll:GetHeight() or 1
      local maxS = math.max(0, ch - sh)
      local trackH = sbar:GetHeight() or 1
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
      syncGroupScroll()
    end)
  end)

  -- Reagenda o layout no próximo frame (tamanho só estabiliza depois do resize).
  local layoutBoot = CreateFrame("Frame", nil, f)
  layoutBoot:Hide()
  local function scheduleGroupLayoutSync()
    layoutBoot:Show()
    layoutBoot:SetScript("OnUpdate", function(s)
      s:SetScript("OnUpdate", nil)
      s:Hide()
      if f.cefNavTab == "group" and f.cefSyncGroupLayout then
        f.cefSyncGroupLayout()
      end
    end)
  end
  f.cefScheduleGroupLayoutSync = scheduleGroupLayoutSync

  f.cefSyncGroupLayout = function()
    if not scroll or not child then
      return
    end
    local sw = scroll:GetWidth() or 0
    local sh = scroll:GetHeight() or 0
    if sw < 32 or sh < 8 then
      scheduleGroupLayoutSync()
      return
    end
    child:SetWidth(sw)
    -- Rebind evita ScrollFrame Classic "perder" o conteúdo após resize do parent.
    scroll:SetScrollChild(child)
    layoutHeaderColumns(header, scroll)
    GUI.refresh()
    if f.cefSyncGroupScroll then
      f.cefSyncGroupScroll()
    end
  end

  scroll:SetScript("OnSizeChanged", function()
    if f.cefNavTab == "group" then
      scheduleGroupLayoutSync()
    end
  end)

  f.cefApplyGroupLocale = function()
    for i = 1, COL_COUNT do
      local h = header["h" .. i]
      if h then
        h:SetText(CEF.L[HDR_KEYS[i]])
      end
    end
    layoutHeaderColumns(header, scroll)
    GUI.refresh()
  end

  return {
    infoBar = infoBar,
    header = header,
    scroll = scroll,
  }
end
