-- Módulo: UI da aba Home — instâncias com barras empilhadas por função.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.HomeUI = CEF.HomeUI or {}
local GUI = CEF.HomeUI

local PAD = 12
local CARD_GAP = 10
local ROW_H = 24
local BAR_H = 10
local MAX_ROWS = 10

-- Cores no estilo clássico: Tank / Healer / DPS
local ROLE_COLORS = {
  tank = { 0.20, 0.50, 0.95 },
  heal = { 0.20, 0.78, 0.35 },
  dps = { 0.90, 0.38, 0.22 },
}
local FALLBACK_COLOR = { 0.85, 0.65, 0.18 }

local homeTip

local function L(key, fallback)
  if CEF.L and CEF.L[key] then
    return CEF.L[key]
  end
  return fallback or key
end

local function roleLabel(rk)
  if rk == "tank" then
    return L("FILTER_ROLE_TANK", "Tank")
  end
  if rk == "heal" then
    return L("FILTER_ROLE_HEAL", "Healer")
  end
  if rk == "dps" then
    return L("FILTER_ROLE_DPS", "DPS")
  end
  return rk
end

local function placeTipAtCursor(tip)
  local scale = UIParent:GetEffectiveScale()
  local x, y = GetCursorPosition()
  x, y = x / scale, y / scale
  local tipW = tip:GetWidth() or 180
  local tipH = tip:GetHeight() or 80
  local uiW = UIParent:GetWidth() or 1920
  local uiH = UIParent:GetHeight() or 1080
  local ox, oy = 14, 14
  local left = x + ox
  local bottom = y + oy
  if left + tipW > uiW - 4 then
    left = x - tipW - ox
  end
  if bottom + tipH > uiH - 4 then
    bottom = y - tipH - oy
  end
  if left < 4 then
    left = 4
  end
  if bottom < 4 then
    bottom = 4
  end
  tip:ClearAllPoints()
  tip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
end

local function ensureHomeTip()
  if homeTip then
    return homeTip
  end

  local tip = CreateFrame("Frame", nil, UIParent)
  tip:SetFrameStrata("TOOLTIP")
  tip:SetFrameLevel(200)
  tip:SetClampedToScreen(true)
  tip:SetWidth(200)
  tip:Hide()
  tip:EnableMouse(false)

  local bg = tip:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", tip, "TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", tip, "BOTTOMRIGHT", -1, 1)
  bg:SetColorTexture(0.04, 0.035, 0.04, 0.97)

  local br, bgc, bb, ba = 0.55, 0.45, 0.18, 0.9
  local edges = {
    { h = 1, p1 = "TOPLEFT", p2 = "TOPRIGHT" },
    { h = 1, p1 = "BOTTOMLEFT", p2 = "BOTTOMRIGHT" },
    { w = 1, p1 = "TOPLEFT", p2 = "BOTTOMLEFT" },
    { w = 1, p1 = "TOPRIGHT", p2 = "BOTTOMRIGHT" },
  }
  for _, e in ipairs(edges) do
    local t = tip:CreateTexture(nil, "BORDER")
    t:SetColorTexture(br, bgc, bb, ba)
    if e.h then
      t:SetHeight(e.h)
    else
      t:SetWidth(e.w)
    end
    t:SetPoint(e.p1, tip, e.p1, 0, 0)
    t:SetPoint(e.p2, tip, e.p2, 0, 0)
  end

  local pad = 10
  tip.titleFs = tip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tip.titleFs:SetPoint("TOPLEFT", tip, "TOPLEFT", pad, -pad)
  tip.titleFs:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -pad, -pad)
  tip.titleFs:SetJustifyH("LEFT")
  tip.titleFs:SetTextColor(1, 0.9, 0.3)

  tip.activityFs = tip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  tip.activityFs:SetPoint("TOPLEFT", tip.titleFs, "BOTTOMLEFT", 0, -6)
  tip.activityFs:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -pad, 0)
  tip.activityFs:SetJustifyH("LEFT")
  tip.activityFs:SetTextColor(0.9, 0.9, 0.9)

  tip.roleRows = {}
  local prev = tip.activityFs
  for i, rk in ipairs({ "tank", "heal", "dps" }) do
    local row = CreateFrame("Frame", nil, tip)
    row:SetHeight(14)
    row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, i == 1 and -8 or -3)
    row:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -pad, 0)

    local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameFs:SetPoint("LEFT", row, "LEFT", 0, 0)
    nameFs:SetJustifyH("LEFT")
    local c = ROLE_COLORS[rk]
    nameFs:SetTextColor(c[1], c[2], c[3])
    row.nameFs = nameFs

    local valFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valFs:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    valFs:SetJustifyH("RIGHT")
    valFs:SetTextColor(1, 1, 1)
    row.valFs = valFs

    row.roleKey = rk
    tip.roleRows[i] = row
    prev = row
  end

  tip.noRolesFs = tip:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  tip.noRolesFs:SetPoint("TOPLEFT", tip.activityFs, "BOTTOMLEFT", 0, -8)
  tip.noRolesFs:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -pad, 0)
  tip.noRolesFs:SetJustifyH("LEFT")
  tip.noRolesFs:SetWordWrap(true)
  tip.noRolesFs:Hide()

  tip.pad = pad
  tip:SetScript("OnUpdate", function(self)
    if self:IsShown() then
      placeTipAtCursor(self)
    end
  end)

  homeTip = tip
  return tip
end

local function hideHomeTip()
  if homeTip then
    homeTip:Hide()
  end
end

--- Mesmo estilo da coluna Chat / Oficial: nome colorido + range de nível.
local function instanceRowRichText(it)
  local label = (it and (it.label or it.key)) or ""
  if label == "" then
    return "—"
  end
  if CEF.activityNameLevelsRichText then
    return CEF.activityNameLevelsRichText(label, nil, nil, it and it.instanceKey)
  end
  return label
end

local function showHomeTip(data)
  if not data then
    hideHomeTip()
    return
  end
  local tip = ensureHomeTip()
  local pad = tip.pad

  tip.titleFs:SetText(instanceRowRichText(data))
  tip.titleFs:SetTextColor(1, 1, 1)
  tip.activityFs:SetText(string.format("%s: %d", L("HOME_TIP_ACTIVITY", "Activity"), data.total or 0))

  local tank = data.tank or 0
  local heal = data.heal or 0
  local dps = data.dps or 0
  local roleSum = tank + heal + dps

  if roleSum > 0 then
    tip.noRolesFs:Hide()
    local counts = { tank = tank, heal = heal, dps = dps }
    for _, row in ipairs(tip.roleRows) do
      local n = counts[row.roleKey] or 0
      local pct = math.floor((n / roleSum) * 100 + 0.5)
      row.nameFs:SetText(roleLabel(row.roleKey))
      row.valFs:SetText(string.format("%d (%d%%)", n, pct))
      row:Show()
    end
    local h = pad + tip.titleFs:GetStringHeight() + 6 + tip.activityFs:GetStringHeight() + 8
    h = h + (#tip.roleRows * 14) + ((#tip.roleRows - 1) * 3) + pad
    tip:SetHeight(math.ceil(h))
  else
    for _, row in ipairs(tip.roleRows) do
      row:Hide()
    end
    tip.noRolesFs:SetText(L("HOME_TIP_NO_ROLES", "No role data for this instance yet."))
    tip.noRolesFs:Show()
    local h = pad + tip.titleFs:GetStringHeight() + 6 + tip.activityFs:GetStringHeight() + 8
    h = h + tip.noRolesFs:GetStringHeight() + pad
    tip:SetHeight(math.ceil(h))
  end

  local titleW = tip.titleFs:GetStringWidth() or 0
  local actW = tip.activityFs:GetStringWidth() or 0
  local maxW = math.max(titleW, actW, 140)
  if roleSum > 0 then
    for _, row in ipairs(tip.roleRows) do
      local nw = (row.nameFs:GetStringWidth() or 0) + (row.valFs:GetStringWidth() or 0) + 24
      if nw > maxW then
        maxW = nw
      end
    end
  else
    local nw = tip.noRolesFs:GetStringWidth() or 0
    if nw > maxW then
      maxW = nw
    end
  end
  tip:SetWidth(math.ceil(maxW + pad * 2))

  placeTipAtCursor(tip)
  tip:Show()
end

local function makeLegend(parent, anchor)
  local legend = CreateFrame("Frame", nil, parent)
  legend:SetHeight(16)
  legend:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
  legend:SetPoint("RIGHT", parent, "RIGHT", -10, 0)

  local x = 0
  legend.parts = {}
  for _, rk in ipairs({ "tank", "heal", "dps" }) do
    local swatch = legend:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(10, 10)
    swatch:SetPoint("LEFT", legend, "LEFT", x, 0)
    local c = ROLE_COLORS[rk]
    swatch:SetColorTexture(c[1], c[2], c[3], 1)

    local fs = legend:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("LEFT", swatch, "RIGHT", 4, 0)
    fs:SetTextColor(0.85, 0.82, 0.75)
    fs:SetText(roleLabel(rk))

    legend.parts[rk] = { swatch = swatch, fs = fs }
    x = x + 10 + 4 + 72
  end

  legend.RefreshLabels = function()
    for _, rk in ipairs({ "tank", "heal", "dps" }) do
      local part = legend.parts[rk]
      if part and part.fs then
        part.fs:SetText(roleLabel(rk))
      end
    end
  end

  return legend
end

local function makeCard(parent, title)
  local card = CreateFrame("Frame", nil, parent)
  local bg = card:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.09, 0.08, 0.07, 0.96)
  local edge = card:CreateTexture(nil, "BORDER")
  edge:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
  edge:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
  edge:SetHeight(1)
  edge:SetColorTexture(0.35, 0.28, 0.14, 0.9)

  local titleFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
  titleFs:SetTextColor(1, 0.82, 0.35)
  titleFs:SetText(title or "")
  card.titleFs = titleFs

  local subFs = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  subFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -2)
  subFs:SetPoint("RIGHT", card, "RIGHT", -10, 0)
  subFs:SetJustifyH("LEFT")
  subFs:SetText("")
  card.subFs = subFs

  card.legend = makeLegend(card, subFs)

  local emptyFs = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  emptyFs:SetPoint("TOPLEFT", card.legend, "BOTTOMLEFT", 0, -16)
  emptyFs:SetPoint("RIGHT", card, "RIGHT", -10, 0)
  emptyFs:SetJustifyH("LEFT")
  emptyFs:Hide()
  card.emptyFs = emptyFs

  card.rows = {}
  for i = 1, MAX_ROWS do
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT", card, "LEFT", 10, 0)
    row:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    if i == 1 then
      row:SetPoint("TOP", card.legend, "BOTTOM", 0, -10)
    else
      row:SetPoint("TOP", card.rows[i - 1], "BOTTOM", 0, -4)
    end

    local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameFs:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", -36, 0)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    row.nameFs = nameFs

    local countFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countFs:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    countFs:SetJustifyH("RIGHT")
    countFs:SetTextColor(0.85, 0.78, 0.55)
    row.countFs = countFs

    local track = row:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 1)
    track:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
    track:SetHeight(BAR_H)
    track:SetColorTexture(0.15, 0.13, 0.11, 1)
    row.track = track

    row.fills = {}
    local prev
    for _, rk in ipairs({ "tank", "heal", "dps" }) do
      local fill = row:CreateTexture(nil, "ARTWORK")
      fill:SetHeight(BAR_H)
      fill:SetWidth(1)
      local c = ROLE_COLORS[rk]
      fill:SetColorTexture(c[1], c[2], c[3], 0.95)
      if prev then
        fill:SetPoint("LEFT", prev, "RIGHT", 0, 0)
      else
        fill:SetPoint("LEFT", track, "LEFT", 0, 0)
      end
      fill:Hide()
      row.fills[rk] = fill
      prev = fill
    end

    local fallback = row:CreateTexture(nil, "ARTWORK")
    fallback:SetPoint("LEFT", track, "LEFT", 0, 0)
    fallback:SetHeight(BAR_H)
    fallback:SetWidth(1)
    fallback:SetColorTexture(FALLBACK_COLOR[1], FALLBACK_COLOR[2], FALLBACK_COLOR[3], 0.95)
    fallback:Hide()
    row.fallbackFill = fallback

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
      showHomeTip(self.tipData)
    end)
    row:SetScript("OnLeave", function()
      hideHomeTip()
    end)

    row:Hide()
    card.rows[i] = row
  end

  return card
end

local function paintStackedRows(card, items, emptyText)
  local maxTotal = 1
  for _, it in ipairs(items or {}) do
    if (it.total or 0) > maxTotal then
      maxTotal = it.total
    end
  end

  local has = items and #items > 0
  if card.emptyFs then
    if has then
      card.emptyFs:Hide()
    else
      card.emptyFs:SetText(emptyText or "")
      card.emptyFs:Show()
    end
  end

  for i = 1, MAX_ROWS do
    local row = card.rows[i]
    local it = items and items[i]
    if it then
      -- Cores vêm do rich text (|c…|r); não sobrescrever com branco sólido.
      row.nameFs:SetText(instanceRowRichText(it))
      row.nameFs:SetTextColor(1, 1, 1)
      row.countFs:SetText(tostring(it.total or 0))
      row.tipData = it

      local w = row.track:GetWidth() or 100
      if w < 8 then
        w = 100
      end
      local barW = math.max(2, w * ((it.total or 0) / maxTotal))
      local tank = it.tank or 0
      local heal = it.heal or 0
      local dps = it.dps or 0
      local roleSum = tank + heal + dps

      if roleSum > 0 then
        row.fallbackFill:Hide()
        local order = {
          { key = "tank", n = tank },
          { key = "heal", n = heal },
          { key = "dps", n = dps },
        }
        local prev
        local used = 0
        for idx, seg in ipairs(order) do
          local fill = row.fills[seg.key]
          local segW
          if idx == #order then
            segW = math.max(0, barW - used)
          else
            segW = math.floor(barW * (seg.n / roleSum) + 0.5)
            if seg.n > 0 and segW < 2 then
              segW = 2
            end
            if seg.n == 0 then
              segW = 0
            end
            used = used + segW
          end
          if segW > 0 then
            fill:ClearAllPoints()
            fill:SetHeight(BAR_H)
            fill:SetWidth(segW)
            if prev then
              fill:SetPoint("LEFT", prev, "RIGHT", 0, 0)
            else
              fill:SetPoint("LEFT", row.track, "LEFT", 0, 0)
            end
            fill:Show()
            prev = fill
          else
            fill:Hide()
          end
        end
      else
        for _, rk in ipairs({ "tank", "heal", "dps" }) do
          row.fills[rk]:Hide()
        end
        row.fallbackFill:ClearAllPoints()
        row.fallbackFill:SetPoint("LEFT", row.track, "LEFT", 0, 0)
        row.fallbackFill:SetWidth(barW)
        row.fallbackFill:Show()
      end

      row:Show()
    else
      row.tipData = nil
      row:Hide()
    end
  end
end

function GUI.refresh()
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not f.homeRoot then
    return
  end
  if not CEF.Home or not CEF.Home.buildSnapshot then
    return
  end
  local snap = CEF.Home.buildSnapshot()

  if f.homeSummaryFs then
    local seeking = (snap.intent and snap.intent.invite) or 0
    local recruiting = (snap.intent and snap.intent.whisper) or 0
    f.homeSummaryFs:SetText(CEF.L and CEF.L(
      "HOME_SUMMARY_FMT",
      snap.chatCount or 0,
      snap.lfgCount or 0,
      seeking,
      recruiting
    ) or string.format(
      "Chat %d · Premade %d · Looking for group %d · Recruiting %d",
      snap.chatCount or 0,
      snap.lfgCount or 0,
      seeking,
      recruiting
    ))
  end

  if f.homeDungeonCard then
    paintStackedRows(f.homeDungeonCard, snap.dungeons, L("HOME_EMPTY_DUNGEONS", "No dungeon activity yet."))
  end
  if f.homeRaidCard then
    paintStackedRows(f.homeRaidCard, snap.raids, L("HOME_EMPTY_RAIDS", "No raid activity yet."))
  end

  local sub = L("HOME_INSTANCES_SUB", "Bar length = activity · colors = role mix")
  for _, card in ipairs({ f.homeDungeonCard, f.homeRaidCard }) do
    if card then
      if card.subFs then
        card.subFs:SetText(sub)
      end
      if card.legend and card.legend.RefreshLabels then
        card.legend.RefreshLabels()
      end
    end
  end
end

local function layoutHome(f)
  local root = f.homeRoot
  if not root then
    return
  end
  local w = root:GetWidth() or 900
  local h = root:GetHeight() or 480
  if w < 100 or h < 100 then
    return
  end

  local summaryH = 36
  if f.homeSummaryBar then
    f.homeSummaryBar:ClearAllPoints()
    f.homeSummaryBar:SetPoint("TOPLEFT", root, "TOPLEFT", PAD, -PAD)
    f.homeSummaryBar:SetPoint("TOPRIGHT", root, "TOPRIGHT", -PAD, -PAD)
    f.homeSummaryBar:SetHeight(summaryH)
  end

  local top = PAD + summaryH + CARD_GAP
  local cardH = math.max(180, h - top - PAD)
  local innerW = w - 2 * PAD
  local colW = math.floor((innerW - CARD_GAP) / 2)

  if f.homeDungeonCard then
    f.homeDungeonCard:ClearAllPoints()
    f.homeDungeonCard:SetSize(colW, cardH)
    f.homeDungeonCard:SetPoint("TOPLEFT", root, "TOPLEFT", PAD, -top)
  end
  if f.homeRaidCard then
    f.homeRaidCard:ClearAllPoints()
    f.homeRaidCard:SetSize(colW, cardH)
    f.homeRaidCard:SetPoint("TOPLEFT", root, "TOPLEFT", PAD + colW + CARD_GAP, -top)
  end
end

function GUI.createPanels(f, navBar)
  local root = CreateFrame("Frame", nil, f)
  root:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  root:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 4)
  root:Hide()
  f.homeRoot = root

  local bg = root:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.045, 0.05, 0.92)

  local summaryBar = CreateFrame("Frame", nil, root)
  summaryBar:SetHeight(36)
  local sbg = summaryBar:CreateTexture(nil, "BACKGROUND")
  sbg:SetAllPoints()
  sbg:SetColorTexture(0.1, 0.09, 0.08, 0.95)
  f.homeSummaryBar = summaryBar

  local summaryFs = summaryBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summaryFs:SetPoint("LEFT", summaryBar, "LEFT", 12, 0)
  summaryFs:SetPoint("RIGHT", summaryBar, "RIGHT", -12, 0)
  summaryFs:SetJustifyH("LEFT")
  f.homeSummaryFs = summaryFs

  local refreshBtn = CreateFrame("Button", nil, summaryBar)
  refreshBtn:SetSize(88, 22)
  refreshBtn:SetPoint("RIGHT", summaryBar, "RIGHT", -8, 0)
  local rbg = refreshBtn:CreateTexture(nil, "BACKGROUND")
  rbg:SetAllPoints()
  rbg:SetColorTexture(0.18, 0.15, 0.1, 1)
  local rfs = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  rfs:SetAllPoints()
  rfs:SetText(L("LFG_REFRESH", "Refresh"))
  refreshBtn.fs = rfs
  refreshBtn:SetScript("OnClick", function()
    if CEF.LFG and CEF.LFG.isAvailable and CEF.LFG.isAvailable() and CEF.LFG.search then
      CEF.LFG.search(nil, { force = true })
    end
    GUI.refresh()
  end)
  f.homeRefreshBtn = refreshBtn

  summaryFs:ClearAllPoints()
  summaryFs:SetPoint("LEFT", summaryBar, "LEFT", 12, 0)
  summaryFs:SetPoint("RIGHT", refreshBtn, "LEFT", -8, 0)

  f.homeDungeonCard = makeCard(root, L("HOME_DUNGEONS_TITLE", "Top dungeons"))
  f.homeRaidCard = makeCard(root, L("HOME_RAIDS_TITLE", "Top raids"))
  f.homeInstCard = f.homeDungeonCard -- compat
  f.homeRoleCard = nil

  root:SetScript("OnSizeChanged", function()
    layoutHome(f)
    GUI.refresh()
  end)
  root:SetScript("OnShow", function()
    layoutHome(f)
    GUI.refresh()
  end)
  root:SetScript("OnHide", function()
    hideHomeTip()
  end)

  f.cefApplyHomeLocale = function()
    if f.homeDungeonCard and f.homeDungeonCard.titleFs then
      f.homeDungeonCard.titleFs:SetText(L("HOME_DUNGEONS_TITLE", "Top dungeons"))
    end
    if f.homeRaidCard and f.homeRaidCard.titleFs then
      f.homeRaidCard.titleFs:SetText(L("HOME_RAIDS_TITLE", "Top raids"))
    end
    if f.homeRefreshBtn and f.homeRefreshBtn.fs then
      f.homeRefreshBtn.fs:SetText(L("LFG_REFRESH", "Refresh"))
    end
    GUI.refresh()
  end

  layoutHome(f)

  if CEF.LFG and CEF.LFG.onChanged then
    CEF.LFG.onChanged(function()
      local mf = CEF.UI and CEF.UI.mainFrame
      if mf and mf:IsShown() and mf.cefNavTab == "home" then
        GUI.refresh()
      end
    end)
  end
end
