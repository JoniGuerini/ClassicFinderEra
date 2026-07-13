-- Módulo: roster da guilda — cache, filtros e vista filtrada.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Guild = CEF.Guild or {}
local Guild = CEF.Guild

local CLASS_OPTS = {
  { key = "WARRIOR", labelKey = "CLASS_WARRIOR" },
  { key = "PALADIN", labelKey = "CLASS_PALADIN" },
  { key = "HUNTER", labelKey = "CLASS_HUNTER" },
  { key = "ROGUE", labelKey = "CLASS_ROGUE" },
  { key = "PRIEST", labelKey = "CLASS_PRIEST" },
  { key = "SHAMAN", labelKey = "CLASS_SHAMAN" },
  { key = "MAGE", labelKey = "CLASS_MAGE" },
  { key = "WARLOCK", labelKey = "CLASS_WARLOCK" },
  { key = "DRUID", labelKey = "CLASS_DRUID" },
}
CEF.GUILD_CLASS_FILTER_OPTS = CLASS_OPTS

local ONLINE_OPTS = {
  { key = false, labelKey = "FILTER_ALL" },
  { key = "online", labelKey = "STATUS_ONLINE" },
  { key = "offline", labelKey = "STATUS_OFFLINE" },
}
CEF.GUILD_ONLINE_FILTER_OPTS = ONLINE_OPTS

local members = {}
local filteredView = {}
local rankOpts = {}
local rosterReady = false
local pendingRefresh = false

-- Ordenação por coluna (clique no header). Padrão: online primeiro.
local SORT_COLS = {
  "name",
  "level",
  "class",
  "rank",
  "zone",
  "status",
  "note",
  "officerNote",
}
local sortColumn = "status"
local sortAsc = false

local function classLabel(opt)
  return (opt and opt.labelKey and CEF.L[opt.labelKey]) or (opt and opt.label) or "—"
end

local function onlineLabel(opt)
  return (opt and opt.labelKey and CEF.L[opt.labelKey]) or (opt and opt.label) or "—"
end

function Guild.refreshLocaleLabels()
  for _, opt in ipairs(CLASS_OPTS) do
    opt.label = classLabel(opt)
  end
  for _, opt in ipairs(ONLINE_OPTS) do
    opt.label = onlineLabel(opt)
  end
  if rankOpts[1] then
    rankOpts[1].label = CEF.L.FILTER_ALL_RANKS
  end
end

function Guild.canViewOfficerNote()
  if C_GuildInfo and C_GuildInfo.CanViewOfficerNote then
    return C_GuildInfo.CanViewOfficerNote() and true or false
  end
  if CanViewOfficerNote then
    return CanViewOfficerNote() and true or false
  end
  return false
end

local function ensureGuildFilterState()
  CEF.state = CEF.state or {}
  local s = CEF.state
  s.filterGuildSearchText = s.filterGuildSearchText or ""
  s.filterGuildClassKeys = s.filterGuildClassKeys or {}
  s.filterGuildRankKeys = s.filterGuildRankKeys or {}
  s.filterGuildOnlineKey = s.filterGuildOnlineKey
  if s.filterGuildOnlineKey == nil then
    s.filterGuildOnlineKey = false
  end
  if s.filterGuildLevelMin == nil then
    s.filterGuildLevelMin = 1
  end
  if s.filterGuildLevelMax == nil then
    s.filterGuildLevelMax = (CEF.getMaxPlayerLevel and CEF.getMaxPlayerLevel()) or 60
  end
end

function Guild.classFilterOptionRichText(keyOrSet)
  if type(keyOrSet) ~= "table" then
    if keyOrSet == false or keyOrSet == nil then
      return "|cffffffff" .. CEF.L.FILTER_ALL_CLASSES .. "|r"
    end
    for _, opt in ipairs(CLASS_OPTS) do
      if opt.key == keyOrSet then
        return "|cffffffff" .. classLabel(opt) .. "|r"
      end
    end
    return "|cffffffff—|r"
  end
  local keys = CEF.filterSetSortedKeys(keyOrSet)
  if #keys == 0 then
    return "|cffffffff" .. CEF.L.FILTER_ALL_CLASSES .. "|r"
  end
  if #keys == 1 then
    return Guild.classFilterOptionRichText(keys[1])
  end
  return "|cffffffff" .. CEF.L("FILTER_N_CLASSES", #keys) .. "|r"
end

function Guild.rankFilterOptionRichText(keyOrSet)
  if type(keyOrSet) ~= "table" then
    if keyOrSet == false or keyOrSet == nil then
      return "|cffffffff" .. CEF.L.FILTER_ALL_RANKS .. "|r"
    end
    return "|cffffffff" .. tostring(keyOrSet) .. "|r"
  end
  local keys = CEF.filterSetSortedKeys(keyOrSet)
  if #keys == 0 then
    return "|cffffffff" .. CEF.L.FILTER_ALL_RANKS .. "|r"
  end
  if #keys == 1 then
    return "|cffffffff" .. tostring(keys[1]) .. "|r"
  end
  return "|cffffffff" .. CEF.L("FILTER_N_RANKS", #keys) .. "|r"
end

function Guild.onlineFilterOptionRichText(key)
  if key == false or key == nil then
    return "|cffffffff" .. CEF.L.FILTER_ALL .. "|r"
  end
  for _, opt in ipairs(ONLINE_OPTS) do
    if opt.key == key then
      return "|cffffffff" .. onlineLabel(opt) .. "|r"
    end
  end
  return "|cffffffff—|r"
end

function Guild.getRankFilterOpts()
  return rankOpts
end

function Guild.isInGuild()
  return IsInGuild and IsInGuild() or false
end

function Guild.isRosterReady()
  return rosterReady
end

function Guild.isPendingRefresh()
  return pendingRefresh
end

function Guild.requestRoster()
  if not Guild.isInGuild() then
    wipe(members)
    wipe(filteredView)
    wipe(rankOpts)
    rosterReady = true
    pendingRefresh = false
    return false
  end
  pendingRefresh = true
  if GuildRoster then
    GuildRoster()
  end
  return true
end

local function rebuildRankOpts()
  wipe(rankOpts)
  rankOpts[1] = { key = false, label = CEF.L.FILTER_ALL_RANKS }
  local seen = {}
  local names = {}
  for _, m in ipairs(members) do
    local r = m.rank or ""
    if r ~= "" and not seen[r] then
      seen[r] = true
      names[#names + 1] = r
    end
  end
  table.sort(names, function(a, b)
    return strlower(a) < strlower(b)
  end)
  for _, r in ipairs(names) do
    rankOpts[#rankOpts + 1] = { key = r, label = r }
  end
end

function Guild.refreshFromApi()
  wipe(members)
  ensureGuildFilterState()

  if not Guild.isInGuild() then
    wipe(rankOpts)
    rankOpts[1] = { key = false, label = CEF.L.FILTER_ALL_RANKS }
    rosterReady = true
    pendingRefresh = false
    Guild.rebuildFilteredView()
    return
  end

  local n = GetNumGuildMembers and GetNumGuildMembers() or 0
  for i = 1, n do
    local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName =
      GetGuildRosterInfo(i)
    if name and name ~= "" then
      local file = classFileName
      if (not file or file == "") and class and class ~= "" then
        file = strupper((class:gsub("%s+", "")))
      end
      members[#members + 1] = {
        name = name,
        nameShort = CEF.stripRealm and CEF.stripRealm(name) or name,
        rank = rank or "",
        rankIndex = tonumber(rankIndex) or 0,
        level = tonumber(level) or 0,
        class = class or "",
        classFile = file or "",
        zone = zone or "",
        note = note or "",
        officerNote = (Guild.canViewOfficerNote() and (officerNote or "")) or "",
        online = online and true or false,
        status = status,
      }
    end
  end

  table.sort(members, function(a, b)
    if a.online ~= b.online then
      return a.online
    end
    if a.level ~= b.level then
      return a.level > b.level
    end
    return strlower(a.nameShort or "") < strlower(b.nameShort or "")
  end)

  rebuildRankOpts()
  rosterReady = true
  pendingRefresh = false
  Guild.rebuildFilteredView()
end

local function memberSortValue(m, col)
  if col == "name" then
    return strlower(m.nameShort or m.name or "")
  elseif col == "level" then
    return tonumber(m.level) or 0
  elseif col == "class" then
    return strlower(m.classFile or m.class or "")
  elseif col == "rank" then
    return tonumber(m.rankIndex) or 0
  elseif col == "zone" then
    return strlower(m.zone or "")
  elseif col == "status" then
    return m.online and 1 or 0
  elseif col == "note" then
    return strlower(m.note or "")
  elseif col == "officerNote" then
    return strlower(m.officerNote or "")
  end
  return ""
end

local function compareMembers(a, b)
  local col = sortColumn or "status"
  local asc = sortAsc and true or false
  local va, vb = memberSortValue(a, col), memberSortValue(b, col)
  if va ~= vb then
    if asc then
      return va < vb
    end
    return va > vb
  end
  -- Desempate estável: online, nível, nome.
  if col ~= "status" and a.online ~= b.online then
    return a.online
  end
  if col ~= "level" and (a.level or 0) ~= (b.level or 0) then
    return (a.level or 0) > (b.level or 0)
  end
  return strlower(a.nameShort or "") < strlower(b.nameShort or "")
end

function Guild.getSortColumn()
  return sortColumn
end

function Guild.getSortAsc()
  return sortAsc
end

function Guild.getSortColumnIndex()
  for i, key in ipairs(SORT_COLS) do
    if key == sortColumn then
      return i
    end
  end
  return 6
end

-- Clique no header: mesma coluna inverte; outra coluna inicia em ordem “natural”.
function Guild.setSortColumn(colKeyOrIndex)
  local col = colKeyOrIndex
  if type(col) == "number" then
    col = SORT_COLS[col]
  end
  if type(col) ~= "string" then
    return
  end
  local valid = false
  for _, key in ipairs(SORT_COLS) do
    if key == col then
      valid = true
      break
    end
  end
  if not valid then
    return
  end
  if sortColumn == col then
    sortAsc = not sortAsc
  else
    sortColumn = col
    -- Nome/classe/zona/notas: A→Z; nível/status/posto: maior primeiro.
    if col == "name" or col == "class" or col == "zone" or col == "note" or col == "officerNote" then
      sortAsc = true
    else
      sortAsc = false
    end
  end
  Guild.rebuildFilteredView()
end

local function memberMatchesFilters(m, s)
  local q = s.filterGuildSearchText or ""
  if q ~= "" then
    local blob = strlower((m.nameShort or "") .. " " .. (m.name or ""))
    if not blob:find(q, 1, true) then
      return false
    end
  end

  local classSet = CEF.normalizeFilterSet(s.filterGuildClassKeys)
  if next(classSet) then
    local cf = m.classFile or ""
    if cf == "" or not classSet[cf] then
      return false
    end
  end

  local rankSet = CEF.normalizeFilterSet(s.filterGuildRankKeys)
  if next(rankSet) then
    if not rankSet[m.rank or ""] then
      return false
    end
  end

  local onKey = s.filterGuildOnlineKey
  if onKey == "online" and not m.online then
    return false
  end
  if onKey == "offline" and m.online then
    return false
  end

  local minL = tonumber(s.filterGuildLevelMin) or 1
  local maxL = tonumber(s.filterGuildLevelMax) or (CEF.getMaxPlayerLevel and CEF.getMaxPlayerLevel()) or 60
  if minL > maxL then
    minL, maxL = maxL, minL
  end
  local lvl = m.level or 0
  if lvl < minL or lvl > maxL then
    return false
  end

  return true
end

function Guild.rebuildFilteredView()
  ensureGuildFilterState()
  wipe(filteredView)
  local s = CEF.state
  for _, m in ipairs(members) do
    if memberMatchesFilters(m, s) then
      filteredView[#filteredView + 1] = m
    end
  end
  table.sort(filteredView, compareMembers)
end

function Guild.getMembers()
  return members
end

function Guild.getFilteredView()
  return filteredView
end

function Guild.getRosterCounts()
  local total, online = 0, 0
  for _, m in ipairs(members) do
    total = total + 1
    if m.online then
      online = online + 1
    end
  end
  local shown, shownOnline = 0, 0
  for _, m in ipairs(filteredView) do
    shown = shown + 1
    if m.online then
      shownOnline = shownOnline + 1
    end
  end
  return {
    total = total,
    online = online,
    shown = shown,
    shownOnline = shownOnline,
  }
end

function Guild.resetSort()
  sortColumn = "status"
  sortAsc = false
end

function Guild.resetFilters()
  ensureGuildFilterState()
  local s = CEF.state
  s.filterGuildSearchText = ""
  s.filterGuildClassKeys = CEF.filterSetClear()
  s.filterGuildRankKeys = CEF.filterSetClear()
  s.filterGuildOnlineKey = false
  s.filterGuildLevelMin = 1
  s.filterGuildLevelMax = (CEF.getMaxPlayerLevel and CEF.getMaxPlayerLevel()) or 60
  Guild.resetSort()
  Guild.rebuildFilteredView()
end

function Guild.classColorPrefix(classFile)
  local token = classFile
  if token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then
    local c = RAID_CLASS_COLORS[token]
    return ("|cff%02x%02x%02x"):format((c.r or 1) * 255, (c.g or 1) * 255, (c.b or 1) * 255)
  end
  return "|cffffffff"
end

-- Cor do nível relativa ao personagem (mesmo critério de quest/mob do jogo).
function Guild.levelColorRichText(level)
  level = tonumber(level) or 0
  local color
  if GetQuestDifficultyColor then
    color = GetQuestDifficultyColor(level)
  elseif GetDifficultyColor then
    color = GetDifficultyColor(level)
  end
  if type(color) == "table" then
    return ("|cff%02x%02x%02x%d|r"):format(
      (color.r or 1) * 255,
      (color.g or 1) * 255,
      (color.b or 1) * 255,
      level
    )
  end
  return tostring(level)
end

-- Ícone de classe (folha CharacterCreate + CLASS_ICON_TCOORDS do cliente).
function Guild.setClassIconTexture(tex, classFile)
  if not tex then
    return
  end
  local token = classFile and strupper(classFile) or nil
  local coords = (CLASS_ICON_TCOORDS and token) and CLASS_ICON_TCOORDS[token] or nil
  if coords then
    tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    tex:Show()
  else
    tex:Hide()
  end
end

ensureGuildFilterState()
