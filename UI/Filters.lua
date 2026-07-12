-- Módulo: helpers de UI para filtros (esconder dropdowns e atualizar resumos)

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UIFilters = CEF.UIFilters or {}
local UI = CEF.UIFilters

local function anyFilterMenuShown(mainFrame)
  if not mainFrame then
    return false
  end
  local a = mainFrame.filterInstanceMenu and mainFrame.filterInstanceMenu:IsShown()
  local b = mainFrame.filterIntentMenu and mainFrame.filterIntentMenu:IsShown()
  local c = mainFrame.filterRoleMenu and mainFrame.filterRoleMenu:IsShown()
  local d = mainFrame.filterGuildClassMenu and mainFrame.filterGuildClassMenu:IsShown()
  local e = mainFrame.filterGuildRankMenu and mainFrame.filterGuildRankMenu:IsShown()
  local g = mainFrame.filterGuildOnlineMenu and mainFrame.filterGuildOnlineMenu:IsShown()
  local h = mainFrame.guildMemberContextMenu and mainFrame.guildMemberContextMenu:IsShown()
  local i = mainFrame.filterLocaleMenu and mainFrame.filterLocaleMenu:IsShown()
  local j = mainFrame.groupMemberContextMenu and mainFrame.groupMemberContextMenu:IsShown()
  return a or b or c or d or e or g or h or i or j
end

function UI.anyFilterMenuShown(mainFrame)
  return anyFilterMenuShown(mainFrame)
end

function UI.syncFilterDropBlocker(mainFrame)
  local blocker = mainFrame and mainFrame.cefFilterDropBlocker
  if not blocker then
    UI.syncDropChevrons(mainFrame)
    return
  end
  if anyFilterMenuShown(mainFrame) then
    blocker:Show()
  else
    blocker:Hide()
  end
  UI.syncDropChevrons(mainFrame)
end

function UI.hideFilterInstanceMenu(mainFrame)
  if mainFrame and mainFrame.filterInstanceMenu then
    mainFrame.filterInstanceMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.hideFilterIntentMenu(mainFrame)
  if mainFrame and mainFrame.filterIntentMenu then
    mainFrame.filterIntentMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.hideFilterRoleMenu(mainFrame)
  if mainFrame and mainFrame.filterRoleMenu then
    mainFrame.filterRoleMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.hideAllFilterDropdowns(mainFrame)
  if mainFrame and mainFrame.filterInstanceMenu then
    mainFrame.filterInstanceMenu:Hide()
  end
  if mainFrame and mainFrame.filterIntentMenu then
    mainFrame.filterIntentMenu:Hide()
  end
  if mainFrame and mainFrame.filterRoleMenu then
    mainFrame.filterRoleMenu:Hide()
  end
  if mainFrame and mainFrame.filterGuildClassMenu then
    mainFrame.filterGuildClassMenu:Hide()
  end
  if mainFrame and mainFrame.filterGuildRankMenu then
    mainFrame.filterGuildRankMenu:Hide()
  end
  if mainFrame and mainFrame.filterGuildOnlineMenu then
    mainFrame.filterGuildOnlineMenu:Hide()
  end
  if mainFrame and mainFrame.guildMemberContextMenu then
    mainFrame.guildMemberContextMenu:Hide()
  end
  if mainFrame and mainFrame.cefGuildContextOutsideCloser then
    mainFrame.cefGuildContextOutsideCloser:Hide()
  end
  if mainFrame and mainFrame.groupMemberContextMenu then
    mainFrame.groupMemberContextMenu:Hide()
  end
  if mainFrame and mainFrame.cefGroupContextOutsideCloser then
    mainFrame.cefGroupContextOutsideCloser:Hide()
  end
  if mainFrame and mainFrame.filterLocaleMenu then
    mainFrame.filterLocaleMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.updateFilterDropSummary(filterDropSummaryFS, filterInstanceKeys)
  if filterDropSummaryFS then
    filterDropSummaryFS:SetText(CEF.instanceFilterOptionRichText(filterInstanceKeys))
  end
end

function UI.updateIntentFilterDropSummary(filterIntentDropSummaryFS, filterIntentKeys)
  if filterIntentDropSummaryFS then
    filterIntentDropSummaryFS:SetText(CEF.intentFilterOptionRichText(filterIntentKeys))
  end
end

function UI.updateRoleFilterDropSummary(filterRoleDropSummaryFS, filterRoleKeys)
  if filterRoleDropSummaryFS then
    filterRoleDropSummaryFS:SetText(CEF.roleFilterOptionRichText(filterRoleKeys))
  end
end

-- Checkbox próprio (sem texturas Interface\\ da Blizzard): caixa + marca desenhadas com ColorTexture.
local CHECK_SIZE = 12
local CHECK_PAD_L = 6
local CHECK_GAP = 6
local BR, BG, BB, BA = 0.55, 0.45, 0.18, 0.95

function UI.filterCheckLabelLeft()
  return CHECK_PAD_L + CHECK_SIZE + CHECK_GAP
end

function UI.attachFilterRowCheck(row)
  if not row or row.check then
    return row and row.check
  end
  local box = CreateFrame("Frame", nil, row)
  box:SetSize(CHECK_SIZE, CHECK_SIZE)
  box:SetPoint("LEFT", row, "LEFT", CHECK_PAD_L, 0)
  box:EnableMouse(false)

  local fill = box:CreateTexture(nil, "BACKGROUND")
  fill:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
  fill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
  fill:SetColorTexture(0.04, 0.035, 0.03, 1)
  box.fill = fill

  local function edge(w, h, point, relPoint, x, y)
    local t = box:CreateTexture(nil, "BORDER")
    t:SetSize(w, h)
    t:SetColorTexture(BR, BG, BB, BA)
    t:SetPoint(point, box, relPoint, x, y)
    return t
  end
  edge(CHECK_SIZE, 1, "TOPLEFT", "TOPLEFT", 0, 0)
  edge(CHECK_SIZE, 1, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0)
  edge(1, CHECK_SIZE, "TOPLEFT", "TOPLEFT", 0, 0)
  edge(1, CHECK_SIZE, "TOPRIGHT", "TOPRIGHT", 0, 0)

  -- Marca: bloco âmbar interno (sem glyph/Unicode nem textura Blizzard).
  local mark = box:CreateTexture(nil, "ARTWORK")
  mark:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
  mark:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
  mark:SetColorTexture(0.95, 0.82, 0.35, 1)
  mark:Hide()
  box.mark = mark

  row.check = box
  return box
end

function UI.setFilterRowChecked(row, checked, showCheck)
  if not row then
    return
  end
  UI.attachFilterRowCheck(row)
  row.isSelected = checked and true or false
  if showCheck == false then
    row.check:Hide()
    return
  end
  row.check:Show()
  if row.isSelected then
    row.check.mark:Show()
  else
    row.check.mark:Hide()
  end
end

local ROW_BG_NORMAL = { 0.13, 0.11, 0.09, 0.96 }
local ROW_BG_SELECTED = { 0.2, 0.26, 0.14, 1 }
local ROW_BG_HOVER = { 0.26, 0.2, 0.14, 1 }
local ROW_BG_HEADER = { 0.08, 0.07, 0.06, 1 }

function UI.filterRowBgColor(row, hovering)
  if row.isHeader then
    return ROW_BG_HEADER
  end
  if hovering then
    return ROW_BG_HOVER
  end
  if row.isSelected then
    return ROW_BG_SELECTED
  end
  return ROW_BG_NORMAL
end

function UI.applyFilterRowBg(row, hovering)
  if not row or not row.bg then
    return
  end
  local c = UI.filterRowBgColor(row, hovering)
  row.bg:SetColorTexture(c[1], c[2], c[3], c[4])
end

local MEDIA = "Interface\\AddOns\\ClassicEraFinder\\Media\\"
-- Classic Era: use TGA (PNG is unreliable / often ignored).
-- Ícones devem ser brancos + alpha; a cor vem de SetVertexColor.
local TEX_CHEVRON_DOWN = MEDIA .. "chevron-down.tga"
local TEX_CHEVRON_UP = MEDIA .. "chevron-up.tga"
local TEX_FS_EXPAND = MEDIA .. "maximize.tga"
local TEX_FS_COMPRESS = MEDIA .. "minimize.tga"
-- Mesmo amarelo dos headers (GameFontNormal / NORMAL_FONT_COLOR).
local ICON_R, ICON_G, ICON_B = 1.0, 0.82, 0.0

local function tintIcon(tex)
  if tex then
    tex:SetVertexColor(ICON_R, ICON_G, ICON_B)
  end
end

-- Seta do addon: aberta = cima, fechada = baixo.
function UI.attachDropChevron(btn, size)
  if not btn then
    return nil
  end
  if btn.cefChevron then
    return btn.cefChevron
  end
  size = size or 16
  local holder = CreateFrame("Frame", nil, btn)
  holder:SetSize(size, size)
  holder:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
  holder:EnableMouse(false)
  local tex = holder:CreateTexture(nil, "ARTWORK")
  tex:SetAllPoints()
  tex:SetTexture(TEX_CHEVRON_DOWN)
  tintIcon(tex)
  holder.tex = tex

  function holder:SetOpen(open)
    self.tex:SetTexture(open and TEX_CHEVRON_UP or TEX_CHEVRON_DOWN)
    tintIcon(self.tex)
  end

  holder:SetOpen(false)
  btn.cefChevron = holder
  return holder
end

function UI.setDropChevronOpen(btn, open)
  if btn and btn.cefChevron and btn.cefChevron.SetOpen then
    btn.cefChevron:SetOpen(open and true or false)
  end
end

-- Atualiza setas dos selects Lista + Guilda conforme menus abertos.
function UI.syncDropChevrons(mainFrame)
  if not mainFrame then
    return
  end
  local function openOf(menu)
    return menu and menu:IsShown()
  end
  UI.setDropChevronOpen(mainFrame.cefDropInstanceBtn, openOf(mainFrame.filterInstanceMenu))
  UI.setDropChevronOpen(mainFrame.cefDropIntentBtn, openOf(mainFrame.filterIntentMenu))
  UI.setDropChevronOpen(mainFrame.cefDropRoleBtn, openOf(mainFrame.filterRoleMenu))
  UI.setDropChevronOpen(mainFrame.cefDropGuildClassBtn, openOf(mainFrame.filterGuildClassMenu))
  UI.setDropChevronOpen(mainFrame.cefDropGuildRankBtn, openOf(mainFrame.filterGuildRankMenu))
  UI.setDropChevronOpen(mainFrame.cefDropGuildOnlineBtn, openOf(mainFrame.filterGuildOnlineMenu))
  UI.setDropChevronOpen(mainFrame.cefDropLocaleBtn, openOf(mainFrame.filterLocaleMenu))
end

-- Ícone tela cheia / restaurar.
function UI.attachFullscreenIcon(btn)
  if not btn then
    return nil
  end
  if btn.cefFsIcon then
    return btn.cefFsIcon
  end
  local holder = CreateFrame("Frame", nil, btn)
  holder:SetSize(14, 14)
  holder:SetPoint("CENTER", btn, "CENTER", 0, 0)
  holder:EnableMouse(false)
  local tex = holder:CreateTexture(nil, "ARTWORK")
  tex:SetAllPoints()
  tex:SetTexture(TEX_FS_EXPAND)
  tintIcon(tex)
  holder.tex = tex

  function holder:SetFullscreen(isFs)
    self.tex:SetTexture(isFs and TEX_FS_COMPRESS or TEX_FS_EXPAND)
    tintIcon(self.tex)
  end

  holder:SetFullscreen(false)
  btn.cefFsIcon = holder
  return holder
end

function UI.setFullscreenIcon(btn, isFs)
  if btn and btn.cefFsIcon and btn.cefFsIcon.SetFullscreen then
    btn.cefFsIcon:SetFullscreen(isFs and true or false)
  end
end

