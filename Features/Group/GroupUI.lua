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
    local text = CEF.Group.summaryRichText()
    if CEF.Group.canEditRaid and CEF.Group.canEditRaid() then
      text = text .. "  |cffaaaaaa·|r  |cff888888" .. CEF.L.GROUP_EDIT_HINT .. "|r"
    end
    fs:SetText(text)
  end
end

-- ===== Feedback de ações (erros de permissão/combate/grupo cheio) =====

local function notifyActionError(errKey, ...)
  if not errKey then
    return
  end
  local msg = CEF.L(errKey, ...)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66CEF:|r " .. msg)
  end
end

-- ===== Cores base das linhas (usadas por hover/drag para restaurar) =====

local function applyRowBaseBg(rf)
  if not rf or not rf.bg then
    return
  end
  if rf.cefKind == "hdr" then
    rf.bg:SetColorTexture(0.16, 0.13, 0.08, 0.98)
  elseif rf.cefEven then
    rf.bg:SetColorTexture(0.1, 0.1, 0.12, 0.85)
  else
    rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
  end
end

-- ===== Menu de contexto (sussurrar, liderança, assistente, remover) =====

local CTX_W = 190
local CTX_ROW_H = 22
local CTX_HEADER_H = 22
local CTX_PAD = 4

local function makeMenuChrome(menu)
  local bg = menu:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.048, 0.06, 0.99)
  local br, bgc, bb, ba = 0.55, 0.45, 0.18, 0.85
  local function edge(isH, point1, point2)
    local t = menu:CreateTexture(nil, "BORDER")
    if isH then
      t:SetHeight(1)
    else
      t:SetWidth(1)
    end
    t:SetColorTexture(br, bgc, bb, ba)
    t:SetPoint(point1, menu, point1, 0, 0)
    t:SetPoint(point2, menu, point2, 0, 0)
  end
  edge(true, "TOPLEFT", "TOPRIGHT")
  edge(true, "BOTTOMLEFT", "BOTTOMRIGHT")
  edge(false, "TOPLEFT", "BOTTOMLEFT")
  edge(false, "TOPRIGHT", "BOTTOMRIGHT")
end

function GUI.hideMemberContextMenu()
  local f = CEF.UI and CEF.UI.mainFrame
  if f and f.groupMemberContextMenu then
    f.groupMemberContextMenu:Hide()
  end
  if f and f.cefGroupContextOutsideCloser then
    f.cefGroupContextOutsideCloser:Hide()
  end
  if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
    CEF.UIFilters.syncFilterDropBlocker(f)
  end
end

local function ensureGroupContextOutsideCloser(f)
  if f.cefGroupContextOutsideCloser then
    return f.cefGroupContextOutsideCloser
  end
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
  f.cefGroupContextOutsideCloser = closer
  return closer
end

local function ensureGroupContextMenu(f)
  if f.groupMemberContextMenu then
    return f.groupMemberContextMenu
  end
  local menu = CreateFrame("Frame", nil, f)
  menu:SetSize(CTX_W, 100)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(560)
  menu:EnableMouse(true)
  menu:Hide()
  makeMenuChrome(menu)
  f.groupMemberContextMenu = menu

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

  local function makeCtxRow()
    local row = CreateFrame("Button", nil, menu)
    row:SetHeight(CTX_ROW_H)
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
    fs:SetTextColor(1, 0.92, 0.55)
    row.label = fs
    row:SetScript("OnEnter", function(self)
      self.bg:SetColorTexture(0.22, 0.18, 0.12, 1)
    end)
    row:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    end)
    row:Hide()
    return row
  end

  menu.whisperRow = makeCtxRow()
  menu.leaderRow = makeCtxRow()
  menu.assistRow = makeCtxRow()
  menu.kickRow = makeCtxRow()

  local function runAction(fn)
    local m = menu.cefMember
    GUI.hideMemberContextMenu()
    if not m then
      return
    end
    local ok, errKey = fn(m)
    if not ok and errKey then
      notifyActionError(errKey)
    end
  end

  menu.whisperRow:SetScript("OnClick", function()
    local m = menu.cefMember
    GUI.hideMemberContextMenu()
    if not m or not m.name or m.name == "" or m.isSelf then
      return
    end
    if CEF.UI and CEF.UI.openWhisperInHub then
      CEF.UI.openWhisperInHub(m.nameShort or m.name)
    end
  end)
  menu.leaderRow:SetScript("OnClick", function()
    runAction(CEF.Group.promoteToLeader)
  end)
  menu.assistRow:SetScript("OnClick", function()
    local m = menu.cefMember
    if m and m.isAssist then
      runAction(CEF.Group.demoteFromAssistant)
    else
      runAction(CEF.Group.promoteToAssistant)
    end
  end)
  menu.kickRow:SetScript("OnClick", function()
    runAction(CEF.Group.removeFromGroup)
  end)

  return menu
end

function GUI.showMemberContextMenu(member)
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not member then
    return
  end
  if CEF.UIFilters and CEF.UIFilters.hideAllFilterDropdowns then
    CEF.UIFilters.hideAllFilterDropdowns(f)
  end
  local menu = ensureGroupContextMenu(f)
  menu.cefMember = member

  local colorTag = "|cffffffff"
  if CEF.Guild and CEF.Guild.classColorPrefix then
    colorTag = CEF.Guild.classColorPrefix(member.classFile)
  end
  menu.headerFs:SetText(colorTag .. (member.nameShort or member.name or "") .. "|r")

  local isLeader = CEF.Group.playerIsLeader()
  local isAssist = CEF.Group.playerIsAssist()
  local inRaid = CEF.Group.isRaid()

  menu.whisperRow.label:SetText(CEF.L.WHISPER)
  menu.leaderRow.label:SetText(CEF.L.GROUP_CTX_PROMOTE_LEADER)
  menu.assistRow.label:SetText(member.isAssist and CEF.L.GROUP_CTX_DEMOTE_ASSIST or CEF.L.GROUP_CTX_PROMOTE_ASSIST)
  menu.kickRow.label:SetText(CEF.L.GROUP_CTX_KICK)

  -- Só mostra o que o jogador realmente pode fazer com este alvo.
  local rows = {}
  if not member.isSelf then
    rows[#rows + 1] = menu.whisperRow
  end
  if isLeader and not member.isSelf then
    rows[#rows + 1] = menu.leaderRow
  end
  if isLeader and inRaid and not member.isSelf and not member.isLeader then
    rows[#rows + 1] = menu.assistRow
  end
  if (isLeader or isAssist) and not member.isSelf and not member.isLeader then
    rows[#rows + 1] = menu.kickRow
  end
  if #rows == 0 then
    return
  end

  menu.whisperRow:Hide()
  menu.leaderRow:Hide()
  menu.assistRow:Hide()
  menu.kickRow:Hide()
  local y = -1 - CTX_HEADER_H - 1 - CTX_PAD
  for _, row in ipairs(rows) do
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, y)
    row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, y)
    row.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    row:Show()
    y = y - CTX_ROW_H
  end
  local menuH = CTX_PAD * 2 + CTX_HEADER_H + 1 + CTX_ROW_H * #rows
  menu:SetSize(CTX_W, menuH)

  menu:ClearAllPoints()
  local scale = UIParent:GetEffectiveScale() or 1
  if scale < 0.01 then
    scale = 1
  end
  local cx, cy = GetCursorPosition()
  local x, yy = cx / scale, cy / scale
  local uiW = UIParent:GetWidth() or 1024
  if x + CTX_W > uiW then
    x = uiW - CTX_W - 4
  end
  if yy - menuH < 0 then
    yy = menuH + 4
  end
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, yy)

  local closer = ensureGroupContextOutsideCloser(f)
  closer:SetFrameLevel(500)
  closer:Show()
  menu:SetFrameLevel(560)
  menu:Show()
  if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
    CEF.UIFilters.syncFilterDropBlocker(f)
  end
end

-- ===== Drag & drop de membros entre subgrupos (só raid, líder/assistente) =====

local drag = {
  pending = false, -- botão pressionado, aguardando ultrapassar o limiar
  active = false, -- ghost visível, a arrastar de facto
  memberName = nil,
  startX = 0,
  startY = 0,
  hoverRf = nil,
}

local DRAG_THRESHOLD = 6
local EDGE_BAND = 26
local EDGE_STEP = 7

local function cursorUiXY()
  local scale = UIParent:GetEffectiveScale() or 1
  if scale < 0.01 then
    scale = 1
  end
  local cx, cy = GetCursorPosition()
  return cx / scale, cy / scale
end

local function findMemberByName(name)
  if not name then
    return nil
  end
  for _, m in ipairs(CEF.Group.getMembers() or {}) do
    if m.name == name then
      return m
    end
  end
  return nil
end

local function ensureDragGhost()
  local ui = CEF.UI or {}
  if ui.groupDragGhost then
    return ui.groupDragGhost
  end
  local ghost = CreateFrame("Frame", nil, UIParent)
  ghost:SetSize(180, 24)
  ghost:SetFrameStrata("TOOLTIP")
  ghost:SetFrameLevel(600)
  ghost:EnableMouse(false)
  ghost:Hide()
  makeMenuChrome(ghost)
  local fs = ghost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", ghost, "LEFT", 8, 0)
  fs:SetPoint("RIGHT", ghost, "RIGHT", -8, 0)
  fs:SetJustifyH("LEFT")
  ghost.label = fs
  CEF.UI.groupDragGhost = ghost
  return ghost
end

local function clearDragHover()
  if drag.hoverRf then
    applyRowBaseBg(drag.hoverRf)
    drag.hoverRf = nil
  end
end

-- Linha visível sob o cursor (alvo do drop).
local function rowUnderCursor()
  local ui = CEF.UI or {}
  -- Fora da viewport o clipping esconde a linha, mas ela ainda responde ao rato.
  if not (ui.groupScrollFrame and ui.groupScrollFrame:IsMouseOver()) then
    return nil
  end
  local rowFrames = ui.groupRowFrames or {}
  for _, rf in ipairs(rowFrames) do
    if rf:IsShown() and rf:IsMouseOver() then
      return rf
    end
  end
  return nil
end

-- Semântica do drop (igual à janela de raide da Blizzard):
-- alvo com vaga → move; alvo cheio em cima de um membro → troca os dois.
local function performDrop(targetRf)
  local src = findMemberByName(drag.memberName)
  if not src or not targetRf then
    return
  end
  local targetSubgroup, targetMember
  if targetRf.cefKind == "hdr" then
    targetSubgroup = targetRf.cefSubgroup
  elseif targetRf.cefKind == "member" and targetRf.cefMember then
    targetMember = targetRf.cefMember
    targetSubgroup = targetMember.subgroup
  end
  if not targetSubgroup or targetSubgroup == src.subgroup then
    return
  end
  if CEF.Group.subgroupCount(targetSubgroup) < 5 then
    local ok, errKey = CEF.Group.moveToSubgroup(src, targetSubgroup)
    if not ok and errKey then
      notifyActionError(errKey, targetSubgroup)
    end
  elseif targetMember then
    local ok, errKey = CEF.Group.swapMembers(src, targetMember)
    if not ok and errKey then
      notifyActionError(errKey)
    end
  else
    notifyActionError("GROUP_ERR_FULL", targetSubgroup)
  end
end

local function stopDrag(doDrop)
  local ui = CEF.UI or {}
  local targetRf = doDrop and drag.active and rowUnderCursor() or nil
  clearDragHover()
  if ui.groupDragGhost then
    ui.groupDragGhost:Hide()
  end
  if ui.groupDragDriver then
    ui.groupDragDriver:SetScript("OnUpdate", nil)
    ui.groupDragDriver:Hide()
  end
  local wasActive = drag.active
  drag.pending = false
  drag.active = false
  if wasActive and targetRf then
    performDrop(targetRf)
  end
  drag.memberName = nil
end

-- Auto-scroll quando o cursor encosta nas bordas da lista durante o drag.
local function dragAutoScroll()
  local ui = CEF.UI or {}
  local scroll = ui.groupScrollFrame
  local child = ui.groupScrollChild
  if not scroll or not child or not scroll:IsShown() then
    return
  end
  local _, cy = cursorUiXY()
  local top = scroll:GetTop()
  local bottom = scroll:GetBottom()
  if not top or not bottom then
    return
  end
  local vs = scroll:GetVerticalScroll() or 0
  local maxS = math.max(0, (child:GetHeight() or 0) - (scroll:GetHeight() or 1))
  local newVs = vs
  if cy > top - EDGE_BAND and cy < top + EDGE_BAND then
    newVs = math.max(0, vs - EDGE_STEP)
  elseif cy < bottom + EDGE_BAND and cy > bottom - EDGE_BAND then
    newVs = math.min(maxS, vs + EDGE_STEP)
  end
  if newVs ~= vs then
    scroll:SetVerticalScroll(newVs)
    GUI.layoutRows()
    -- O re-layout troca o conteúdo das linhas; força recalcular o realce.
    drag.hoverRf = nil
    local f = CEF.UI.mainFrame
    if f and f.cefSyncGroupScroll then
      f.cefSyncGroupScroll()
    end
  end
end

local function dragOnUpdate()
  if not IsMouseButtonDown("LeftButton") then
    stopDrag(true)
    return
  end
  local x, y = cursorUiXY()
  if drag.pending and not drag.active then
    local dx = x - drag.startX
    local dy = y - drag.startY
    if (dx * dx + dy * dy) < (DRAG_THRESHOLD * DRAG_THRESHOLD) then
      return
    end
    drag.active = true
    local ghost = ensureDragGhost()
    local m = findMemberByName(drag.memberName)
    ghost.label:SetText(m and CEF.Group.nameRichText(m) or drag.memberName or "")
    ghost:Show()
  end
  if not drag.active then
    return
  end
  local ghost = ensureDragGhost()
  ghost:ClearAllPoints()
  ghost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 14, y - 10)
  dragAutoScroll()
  -- Realce da linha alvo sob o cursor.
  local rf = rowUnderCursor()
  if rf ~= drag.hoverRf then
    clearDragHover()
    if rf then
      local src = findMemberByName(drag.memberName)
      local sameRow = rf.cefKind == "member" and rf.cefMember and src and rf.cefMember.name == src.name
      if not sameRow then
        drag.hoverRf = rf
      end
    end
  end
  -- Reaplica a cada frame: um refresh do roster no meio do arrasto reseta o fundo.
  if drag.hoverRf then
    drag.hoverRf.bg:SetColorTexture(0.3, 0.24, 0.1, 1)
  end
end

local function startDragTracking(member)
  local ui = CEF.UI or {}
  if not ui.groupDragDriver then
    local driver = CreateFrame("Frame", nil, UIParent)
    driver:Hide()
    CEF.UI.groupDragDriver = driver
  end
  drag.pending = true
  drag.active = false
  drag.memberName = member.name
  drag.startX, drag.startY = cursorUiXY()
  drag.hoverRf = nil
  local driver = CEF.UI.groupDragDriver
  driver:Show()
  driver:SetScript("OnUpdate", dragOnUpdate)
end

-- ===== Rato nas linhas: hover, clique direito (menu) e arrasto (esquerdo) =====

local function bindGroupRowMouse(rf)
  if rf.cefMouseBound then
    return
  end
  rf.cefMouseBound = true
  rf:EnableMouse(true)
  rf:SetScript("OnEnter", function(self)
    if drag.active or self.cefKind ~= "member" then
      return
    end
    if self.bg then
      self.bg:SetColorTexture(0.14, 0.12, 0.1, 0.95)
    end
  end)
  rf:SetScript("OnLeave", function(self)
    if drag.active then
      return
    end
    applyRowBaseBg(self)
  end)
  rf:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" or self.cefKind ~= "member" or not self.cefMember then
      return
    end
    if not (CEF.Group.canEditRaid and CEF.Group.canEditRaid()) then
      return
    end
    startDragTracking(self.cefMember)
  end)
  rf:SetScript("OnMouseUp", function(self, button)
    if button ~= "RightButton" then
      return
    end
    if drag.pending or drag.active then
      stopDrag(false)
      return
    end
    if self.cefKind == "member" and self.cefMember then
      GUI.showMemberContextMenu(self.cefMember)
    end
  end)
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
      bindGroupRowMouse(rf)
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
      rf.cefKind = "hdr"
      rf.cefSubgroup = item.subgroup
      rf.cefMember = nil
      rf.cefEven = false
      applyRowBaseBg(rf)
      rf.cols[1]:ClearAllPoints()
      rf.cols[1]:SetPoint("LEFT", rf, "LEFT", xs[1], 0)
      rf.cols[1]:SetWidth(math.max(120, (widths[1] or 120) + (widths[2] or 0)))
      rf.cols[1]:SetText("|cffffcc66" .. CEF.L("GROUP_SUBGROUP_FMT", item.subgroup) .. "|r")
      rf.classIcon:Hide()
    else
      local m = item.member
      rf.cefKind = "member"
      rf.cefSubgroup = m.subgroup
      rf.cefMember = m
      rf.cefEven = ((i % 2) == 0)
      applyRowBaseBg(rf)

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
