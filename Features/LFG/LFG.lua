-- Módulo: LFG oficial Blizzard (C_LFGList) — busca e leitura de listagens.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.LFG = CEF.LFG or {}
local LFG = CEF.LFG

local listeners = {}
local results = {}
local searching = false
local searchFailed = false
local selectedCategoryId = nil
local selectedActivityIds = {} -- set { [activityId]=true }; vazio = todas
local filterMyLevel = false -- só atividades no range recomendado do jogador
local lastSearchAt = 0
local pendingSearchCategory = nil
local searchWatch

-- Se o evento da Blizzard não chegar, não fica preso em "A procurar…".
local SEARCH_TIMEOUT = 8


local EXPECTED_5MAN = {
  TANK = 1,
  HEALER = 1,
  DAMAGER = 3,
}

local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }

local ROLE_ATLAS = {
  TANK = "groupfinder-icon-role-large-tank",
  HEALER = "groupfinder-icon-role-large-heal",
  DAMAGER = "groupfinder-icon-role-large-dps",
  EMPTY = "groupfinder-icon-emptyslot",
}

local function notify()
  for i = 1, #listeners do
    local ok, err = pcall(listeners[i])
    if not ok and DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666CEF LFG:|r " .. tostring(err))
    end
  end
end

function LFG.onChanged(fn)
  if type(fn) == "function" then
    listeners[#listeners + 1] = fn
  end
end

function LFG.isAvailable()
  return C_LFGList ~= nil
    and type(C_LFGList.Search) == "function"
    and type(C_LFGList.GetFilteredSearchResults) == "function"
end

function LFG.getRoleAtlas(role)
  return ROLE_ATLAS[role] or ROLE_ATLAS.EMPTY
end

function LFG.getRoleOrder()
  return ROLE_ORDER
end

function LFG.getExpectedSlots()
  return EXPECTED_5MAN.TANK, EXPECTED_5MAN.HEALER, EXPECTED_5MAN.DAMAGER
end

local searchText = ""

-- IDs estáveis do Group Finder (Classic / retail-compat).
local CATEGORY_ID_LOCALE_KEY = {
  [1] = "LFG_CAT_QUESTS",
  [2] = "CATEGORY_DUNGEONS",
  [3] = "CATEGORY_RAIDS",
  [4] = "LFG_CAT_ARENAS",
  [6] = "LFG_CAT_CUSTOM",
  [7] = "LFG_CAT_SKIRMISHES",
  [8] = "LFG_CAT_BATTLEGROUNDS",
  [9] = "LFG_CAT_RATED_BGS",
}

-- Fallback por nome (quando o ID não mapeia): client ou EN → chave de locale.
local CATEGORY_NAME_LOCALE_KEY = {
  ["dungeons"] = "CATEGORY_DUNGEONS",
  ["masmorras"] = "CATEGORY_DUNGEONS",
  ["mazmorras"] = "CATEGORY_DUNGEONS",
  ["calabozos"] = "CATEGORY_DUNGEONS",
  ["donjons"] = "CATEGORY_DUNGEONS",
  ["spedizioni"] = "CATEGORY_DUNGEONS",
  ["подземелья"] = "CATEGORY_DUNGEONS",
  ["던전"] = "CATEGORY_DUNGEONS",
  ["地下城"] = "CATEGORY_DUNGEONS",
  ["地城"] = "CATEGORY_DUNGEONS",
  ["raids"] = "CATEGORY_RAIDS",
  ["raides"] = "CATEGORY_RAIDS",
  ["bandas"] = "CATEGORY_RAIDS",
  ["incursioni"] = "CATEGORY_RAIDS",
  ["рейды"] = "CATEGORY_RAIDS",
  ["공격대"] = "CATEGORY_RAIDS",
  ["团队副本"] = "CATEGORY_RAIDS",
  ["團隊副本"] = "CATEGORY_RAIDS",
  ["quests"] = "LFG_CAT_QUESTS",
  ["questing"] = "LFG_CAT_QUESTS",
  ["quests & zones"] = "LFG_CAT_QUESTS",
  ["questing & zones"] = "LFG_CAT_QUESTS",
  ["missões"] = "LFG_CAT_QUESTS",
  ["missões e áreas"] = "LFG_CAT_QUESTS",
  ["misiones"] = "LFG_CAT_QUESTS",
  ["misiones y zonas"] = "LFG_CAT_QUESTS",
  ["custom"] = "LFG_CAT_CUSTOM",
  ["personalizado"] = "LFG_CAT_CUSTOM",
  ["personnalisé"] = "LFG_CAT_CUSTOM",
  ["своё"] = "LFG_CAT_CUSTOM",
  ["自定义"] = "LFG_CAT_CUSTOM",
  ["自訂"] = "LFG_CAT_CUSTOM",
  ["battlegrounds"] = "LFG_CAT_BATTLEGROUNDS",
  ["campos de batalha"] = "LFG_CAT_BATTLEGROUNDS",
  ["campos de batalla"] = "LFG_CAT_BATTLEGROUNDS",
  ["поля боя"] = "LFG_CAT_BATTLEGROUNDS",
  ["战场"] = "LFG_CAT_BATTLEGROUNDS",
  ["戰場"] = "LFG_CAT_BATTLEGROUNDS",
}

local function resolveCategoryLocaleKeyFromName(blizzName)
  if type(blizzName) ~= "string" or blizzName == "" then
    return nil
  end
  local lower = string.lower(blizzName)
  local exact = CATEGORY_NAME_LOCALE_KEY[lower]
  if exact then
    return exact
  end
  -- Heurística: nomes compostos do cliente (ex. "Missões e Áreas", "Raides").
  if lower:find("raid", 1, true) or lower:find("banda", 1, true) or lower:find("рейд", 1, true) then
    return "CATEGORY_RAIDS"
  end
  if lower:find("dungeon", 1, true)
    or lower:find("masmorr", 1, true)
    or lower:find("mazmorr", 1, true)
    or lower:find("calaboz", 1, true)
    or lower:find("donjon", 1, true)
    or lower:find("подзем", 1, true)
    or lower:find("地下城", 1, true)
    or lower:find("地城", 1, true)
  then
    return "CATEGORY_DUNGEONS"
  end
  if lower:find("quest", 1, true)
    or lower:find("missão", 1, true)
    or lower:find("missoes", 1, true)
    or lower:find("missões", 1, true)
    or lower:find("mision", 1, true)
    or lower:find("área", 1, true)
    or lower:find("areas", 1, true)
    or lower:find("zone", 1, true)
  then
    return "LFG_CAT_QUESTS"
  end
  if lower:find("custom", 1, true) or lower:find("personaliz", 1, true) or lower:find("сво", 1, true) then
    return "LFG_CAT_CUSTOM"
  end
  if lower:find("battle", 1, true) or lower:find("batalha", 1, true) or lower:find("batalla", 1, true) or lower:find("поля боя", 1, true) then
    return "LFG_CAT_BATTLEGROUNDS"
  end
  return nil
end

local function localeString(key)
  if not key then
    return nil
  end
  local v = CEF.L and CEF.L[key]
  if type(v) == "string" and v ~= "" and v ~= key then
    return v
  end
  return nil
end

local function blizzardCategoryName(categoryID)
  if C_LFGList.GetLfgCategoryInfo then
    local info = C_LFGList.GetLfgCategoryInfo(categoryID)
    if type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
      return info.name
    end
  end
  if C_LFGList.GetCategoryInfo then
    local a = C_LFGList.GetCategoryInfo(categoryID)
    if type(a) == "table" and type(a.name) == "string" and a.name ~= "" then
      return a.name
    end
    if type(a) == "string" and a ~= "" then
      return a
    end
    local name = select(1, C_LFGList.GetCategoryInfo(categoryID))
    if type(name) == "string" and name ~= "" then
      return name
    end
  end
  return nil
end

local function categoryName(categoryID)
  categoryID = tonumber(categoryID)
  local blizz = blizzardCategoryName(categoryID)
  -- Preferir match por nome do cliente: IDs Classic Era ≠ retail.
  local key = resolveCategoryLocaleKeyFromName(blizz) or (categoryID and CATEGORY_ID_LOCALE_KEY[categoryID])
  local localized = localeString(key)
  if localized then
    return localized
  end
  if blizz then
    return blizz
  end
  return CEF.L("LFG_CATEGORY_N", categoryID or 0)
end

function LFG.getCategoryLocaleKey(categoryID)
  categoryID = tonumber(categoryID)
  local blizz = blizzardCategoryName(categoryID)
  return resolveCategoryLocaleKeyFromName(blizz) or (categoryID and CATEGORY_ID_LOCALE_KEY[categoryID]) or nil
end

-- Nomes LFG oficiais Blizzard (vários locales) → chave EN do pack de instâncias.
local ACTIVITY_NAME_ALIASES = {
  ["templo submerso"] = "Sunken Temple",
  ["sunken temple"] = "Sunken Temple",
  ["the temple of atal'hakkar"] = "Sunken Temple",
  ["temple of atal'hakkar"] = "Sunken Temple",
  ["templo de atal'hakkar"] = "Sunken Temple",
  ["el templo de atal'hakkar"] = "Sunken Temple",
  -- Alas/lados diferenciados: cada entrada Blizzard → chave própria (LBRS≠UBRS etc.).
  ["upper blackrock spire"] = "UBRS",
  ["lower blackrock spire"] = "LBRS",
  ["pico da rocha negra superior"] = "UBRS",
  ["pico da rocha negra inferior"] = "LBRS",
  ["cumbre de roca negra superior"] = "UBRS",
  ["cumbre de roca negra inferior"] = "LBRS",
  ["dire maul (east)"] = "DM East",
  ["dire maul (north)"] = "DM North",
  ["dire maul (west)"] = "DM West",
  ["dire maul - east"] = "DM East",
  ["dire maul - north"] = "DM North",
  ["dire maul - west"] = "DM West",
  ["gládio cruel (leste)"] = "DM East",
  ["gládio cruel (norte)"] = "DM North",
  ["gládio cruel (oeste)"] = "DM West",
  ["stratholme - main gate"] = "Strat Live",
  ["stratholme - service entrance"] = "Strat UD",
  ["stratholme (portão principal)"] = "Strat Live",
  ["stratholme (entrada de serviço)"] = "Strat UD",
  ["stratholme (main gate)"] = "Strat Live",
  ["stratholme (service entrance)"] = "Strat UD",
  -- Variantes hífen/parênteses de outros idiomas (o pack cobre a forma principal).
  ["gládio cruel - leste"] = "DM East",
  ["gládio cruel - norte"] = "DM North",
  ["gládio cruel - oeste"] = "DM West",
  ["stratholme - portão principal"] = "Strat Live",
  ["stratholme - entrada de serviço"] = "Strat UD",
  ["la masacre (este)"] = "DM East",
  ["la masacre (norte)"] = "DM North",
  ["la masacre (oeste)"] = "DM West",
  ["la masacre - este"] = "DM East",
  ["la masacre - norte"] = "DM North",
  ["la masacre - oeste"] = "DM West",
  ["stratholme (puerta principal)"] = "Strat Live",
  ["stratholme (entrada de servicio)"] = "Strat UD",
  ["hache-tripes (est)"] = "DM East",
  ["hache-tripes (nord)"] = "DM North",
  ["hache-tripes (ouest)"] = "DM West",
  ["hache-tripes - est"] = "DM East",
  ["hache-tripes - nord"] = "DM North",
  ["hache-tripes - ouest"] = "DM West",
  ["pic rochenoire inférieur"] = "LBRS",
  ["pic rochenoire supérieur"] = "UBRS",
  ["stratholme (porte principale)"] = "Strat Live",
  ["stratholme (entrée de service)"] = "Strat UD",
  ["düsterbruch (ost)"] = "DM East",
  ["düsterbruch (nord)"] = "DM North",
  ["düsterbruch (west)"] = "DM West",
  ["düsterbruch - ost"] = "DM East",
  ["düsterbruch - nord"] = "DM North",
  ["düsterbruch - west"] = "DM West",
  ["untere schwarzfelsspitze"] = "LBRS",
  ["obere schwarzfelsspitze"] = "UBRS",
  ["stratholme (haupttor)"] = "Strat Live",
  ["stratholme (diensteingang)"] = "Strat UD",
  ["scarlet monastery - graveyard"] = "SM Graveyard",
  ["scarlet monastery - library"] = "SM Library",
  ["scarlet monastery - armory"] = "SM Armory",
  ["scarlet monastery - cathedral"] = "SM Cathedral",
  ["monastério escarlate - cemitério"] = "SM Graveyard",
  ["monastério escarlate - biblioteca"] = "SM Library",
  ["monastério escarlate - armaria"] = "SM Armory",
  ["monastério escarlate - catedral"] = "SM Cathedral",
  ["cemitério escarlate"] = "SM Graveyard",
  ["biblioteca escarlate"] = "SM Library",
  ["armaria escarlate"] = "SM Armory",
  ["catedral escarlate"] = "SM Cathedral",
  -- TBC / Outland (variantes comuns do Premade / locales).
  ["hellfire ramparts"] = "Hellfire Ramparts",
  ["the blood furnace"] = "Blood Furnace",
  ["blood furnace"] = "Blood Furnace",
  ["the shattered halls"] = "Shattered Halls",
  ["shattered halls"] = "Shattered Halls",
  ["the slave pens"] = "Slave Pens",
  ["slave pens"] = "Slave Pens",
  ["the underbog"] = "Underbog",
  ["the steamvault"] = "Steamvault",
  ["steamvault"] = "Steamvault",
  ["mana-tombs"] = "Mana-Tombs",
  ["mana tombs"] = "Mana-Tombs",
  ["auchenai crypts"] = "Auchenai Crypts",
  ["sethekk halls"] = "Sethekk Halls",
  ["shadow labyrinth"] = "Shadow Labyrinth",
  ["old hillsbrad foothills"] = "Old Hillsbrad",
  ["old hillsbrad"] = "Old Hillsbrad",
  ["the black morass"] = "Black Morass",
  ["black morass"] = "Black Morass",
  ["magisters' terrace"] = "Magisters' Terrace",
  ["magister's terrace"] = "Magisters' Terrace",
  ["the mechanar"] = "Mechanar",
  ["mechanar"] = "Mechanar",
  ["the botanica"] = "Botanica",
  ["botanica"] = "Botanica",
  ["the arcatraz"] = "Arcatraz",
  ["arcatraz"] = "Arcatraz",
  ["tempest keep - the mechanar"] = "Mechanar",
  ["tempest keep - the botanica"] = "Botanica",
  ["tempest keep - the arcatraz"] = "Arcatraz",
  ["bastilha da tormenta - mecanar"] = "Mechanar",
  ["bastilha da tormenta - jardim botânico"] = "Botanica",
  ["bastilha da tormenta - jardim botanico"] = "Botanica",
  ["bastilha da tormenta - arcatraz"] = "Arcatraz",
  ["gruul's lair"] = "Gruul's Lair",
  ["magtheridon's lair"] = "Magtheridon",
  ["magtheridon"] = "Magtheridon",
  ["serpentshrine cavern"] = "SSC",
  ["tempest keep"] = "Tempest Keep",
  ["the eye"] = "Tempest Keep",
  ["the battle for mount hyjal"] = "Hyjal",
  ["battle for mount hyjal"] = "Hyjal",
  ["hyjal summit"] = "Hyjal",
  ["black temple"] = "Black Temple",
  ["zul'aman"] = "Zul'Aman",
  ["sunwell plateau"] = "Sunwell Plateau",
  ["muralha fogo do inferno"] = "Hellfire Ramparts",
  ["fornalha de sangue"] = "Blood Furnace",
  ["salões despedaçados"] = "Shattered Halls",
  ["pátio dos escravos"] = "Slave Pens",
  ["brejo oculto"] = "Underbog",
  ["câmara dos vapores"] = "Steamvault",
  ["tumbas de mana"] = "Mana-Tombs",
  ["catacumbas auchenai"] = "Auchenai Crypts",
  ["salões dos sethekk"] = "Sethekk Halls",
  ["labirinto soturno"] = "Shadow Labyrinth",
  ["terraço dos magísteres"] = "Magisters' Terrace",
  ["covil de gruul"] = "Gruul's Lair",
  ["covil de magtheridon"] = "Magtheridon",
  ["caverna do serpentário"] = "SSC",
  ["bastilha da tempestade"] = "Tempest Keep",
  ["templo negro"] = "Black Temple",
  ["platô da nascente do sol"] = "Sunwell Plateau",
  -- TBC Heroic
  ["hellfire ramparts (heroic)"] = "Hellfire Ramparts Heroic",
  ["heroic hellfire ramparts"] = "Hellfire Ramparts Heroic",
  ["the blood furnace (heroic)"] = "Blood Furnace Heroic",
  ["heroic blood furnace"] = "Blood Furnace Heroic",
  ["the shattered halls (heroic)"] = "Shattered Halls Heroic",
  ["heroic shattered halls"] = "Shattered Halls Heroic",
  ["the slave pens (heroic)"] = "Slave Pens Heroic",
  ["heroic slave pens"] = "Slave Pens Heroic",
  ["the underbog (heroic)"] = "Underbog Heroic",
  ["heroic underbog"] = "Underbog Heroic",
  ["the steamvault (heroic)"] = "Steamvault Heroic",
  ["heroic steamvault"] = "Steamvault Heroic",
  ["mana-tombs (heroic)"] = "Mana-Tombs Heroic",
  ["heroic mana-tombs"] = "Mana-Tombs Heroic",
  ["auchenai crypts (heroic)"] = "Auchenai Crypts Heroic",
  ["sethekk halls (heroic)"] = "Sethekk Halls Heroic",
  ["shadow labyrinth (heroic)"] = "Shadow Labyrinth Heroic",
  ["old hillsbrad foothills (heroic)"] = "Old Hillsbrad Heroic",
  ["the black morass (heroic)"] = "Black Morass Heroic",
  ["magisters' terrace (heroic)"] = "Magisters' Terrace Heroic",
  ["heroic magisters' terrace"] = "Magisters' Terrace Heroic",
  ["the mechanar (heroic)"] = "Mechanar Heroic",
  ["heroic mechanar"] = "Mechanar Heroic",
  ["the botanica (heroic)"] = "Botanica Heroic",
  ["heroic botanica"] = "Botanica Heroic",
  ["the arcatraz (heroic)"] = "Arcatraz Heroic",
  ["heroic arcatraz"] = "Arcatraz Heroic",
  ["bastilha da tormenta - arcatraz (heroico)"] = "Arcatraz Heroic",
  ["bastilha da tormenta - mecanar (heroico)"] = "Mechanar Heroic",
  ["bastilha da tormenta - jardim botânico (heroico)"] = "Botanica Heroic",
  ["bastilha da tormenta - jardim botanico (heroico)"] = "Botanica Heroic",
}

--- Resolve chave EN da instância a partir do nome Blizzard (qualquer idioma do pack).
local function resolveInstanceKeyFromActivityName(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  local lower = string.lower(name)
  local alias = ACTIVITY_NAME_ALIASES[lower]
  if alias then
    return alias
  end
  -- Alias parcial só para needles longos (alas SM/DM etc.).
  for needle, key in pairs(ACTIVITY_NAME_ALIASES) do
    if #needle >= 12 and lower:find(needle, 1, true) then
      return key
    end
  end
  if CEF.resolveInstanceKeyFromName then
    return CEF.resolveInstanceKeyFromName(name)
  end
  return nil
end

local function activityRawName(activityID, info)
  if type(info) ~= "table" then
    if C_LFGList.GetActivityInfoTable then
      info = C_LFGList.GetActivityInfoTable(activityID)
    end
  end
  if type(info) == "table" then
    local name = info.fullName or info.shortName or info.name
    if type(name) == "string" and name ~= "" then
      return name
    end
  end
  if C_LFGList.GetActivityFullName then
    local name = C_LFGList.GetActivityFullName(activityID)
    if type(name) == "string" and name ~= "" then
      return name
    end
  end
  return tostring(activityID)
end

local function activityDisplayName(activityID, info)
  local raw = activityRawName(activityID, info)
  local key = resolveInstanceKeyFromActivityName(raw)
  if key and CEF.getInstanceDisplayName then
    return CEF.getInstanceDisplayName(key)
  end
  return raw
end

function LFG.setSearchText(q)
  searchText = string.lower(tostring(q or ""))
end

function LFG.getSearchText()
  return searchText
end

local function resultFitsPlayerLevel(row)
  local lvl = UnitLevel and UnitLevel("player")
  if not lvl then
    return false
  end
  local minV = row and row.minLevel
  local maxV = row and row.maxLevel
  if minV then
    maxV = maxV or minV
    return lvl >= minV and lvl <= maxV
  end
  local function fitsName(name)
    if type(name) ~= "string" or name == "" or not CEF.levelBoundsForDisplayName then
      return false
    end
    local a, b = CEF.levelBoundsForDisplayName(name)
    if not a then
      return false
    end
    b = b or a
    return lvl >= a and lvl <= b
  end
  if fitsName(row and row.activityName) then
    return true
  end
  local ids = row and row.activityIDs
  if type(ids) == "table" then
    for _, aid in ipairs(ids) do
      if fitsName(activityDisplayName(aid)) then
        return true
      end
    end
  end
  return false
end

local function resultMatchesActivityFilter(row)
  if not LFG.hasActivityFilter() then
    return true
  end
  if filterMyLevel then
    return resultFitsPlayerLevel(row)
  end
  local ids = row and row.activityIDs
  if type(ids) ~= "table" then
    return false
  end
  for _, aid in ipairs(ids) do
    aid = tonumber(aid)
    if aid and selectedActivityIds[aid] then
      return true
    end
  end
  -- Fallback: alguns clientes devolvem só o nome.
  local name = string.lower(tostring(row.activityName or ""))
  if name ~= "" then
    for sid in pairs(selectedActivityIds) do
      local selectedName = string.lower(activityDisplayName(sid) or "")
      if selectedName ~= "" and (name == selectedName or name:find(selectedName, 1, true) or selectedName:find(name, 1, true)) then
        return true
      end
    end
  end
  return false
end

function LFG.getFilteredResults()
  local q = searchText
  local needActivity = LFG.hasActivityFilter()
  local needText = q and q ~= ""
  if not needActivity and not needText then
    return results
  end
  local out = {}
  for _, row in ipairs(results) do
    if resultMatchesActivityFilter(row) then
      if not needText then
        out[#out + 1] = row
      else
        local parts = {
          tostring(row.leaderName or ""),
          tostring(row.activityName or ""),
          tostring(row.comment or ""),
        }
        -- Nomes no locale do addon (e chave EN) por atividade resolvida.
        local entries = row.instanceEntries
        if type(entries) == "table" then
          for _, ie in ipairs(entries) do
            if ie.key and CEF.instanceSearchHay then
              parts[#parts + 1] = CEF.instanceSearchHay(ie.key)
            elseif ie.key and CEF.getInstanceDisplayName then
              parts[#parts + 1] = tostring(CEF.getInstanceDisplayName(ie.key) or "")
              parts[#parts + 1] = tostring(ie.key)
            end
            if ie.name then
              parts[#parts + 1] = tostring(ie.name)
            end
          end
        end
        local hay = string.lower(table.concat(parts, " "))
        hay = hay:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if hay:find(q, 1, true) then
          out[#out + 1] = row
        end
      end
    end
  end
  return out
end

function LFG.getSelectedCategoryId()
  if selectedCategoryId then
    return selectedCategoryId
  end
  local cats = LFG.getCategories()
  for _, c in ipairs(cats) do
    if c.id == 2 then
      selectedCategoryId = c.id
      return selectedCategoryId
    end
  end
  if #cats > 0 then
    selectedCategoryId = cats[1].id
  end
  return selectedCategoryId
end

function LFG.setSelectedCategoryId(id)
  local newId = tonumber(id)
  if newId and newId ~= selectedCategoryId then
    selectedCategoryId = newId
    wipe(selectedActivityIds)
    filterMyLevel = false
  elseif newId then
    selectedCategoryId = newId
  end
end

local function activityInfoTable(activityID)
  if C_LFGList.GetActivityInfoTable then
    local info = C_LFGList.GetActivityInfoTable(activityID)
    if type(info) == "table" then
      return info
    end
  end
  return nil
end

local function activityLevelBounds(info, name)
  if type(info) == "table" then
    local minSug = tonumber(info.minLevelSuggestion) or 0
    local maxSug = tonumber(info.maxLevelSuggestion) or 0
    if minSug > 0 and maxSug > 0 then
      return minSug, maxSug
    end
    if minSug > 0 then
      return minSug, maxSug > 0 and maxSug or nil
    end
    if maxSug > 0 then
      return maxSug, maxSug
    end
  end
  if CEF.levelBoundsForDisplayName and name then
    local minV, maxV = CEF.levelBoundsForDisplayName(name)
    if minV then
      return minV, maxV
    end
    -- Nome localizado do addon: resolve chave EN e tenta de novo.
    local key = resolveInstanceKeyFromActivityName(name)
    if key and CEF.getInstanceDisplayName then
      minV, maxV = CEF.levelBoundsForDisplayName(CEF.getInstanceDisplayName(key))
      if minV then
        return minV, maxV
      end
    end
  end
  if type(info) == "table" then
    local minL = tonumber(info.minLevel) or 0
    if minL > 0 then
      return minL, nil
    end
  end
  return nil, nil
end

local function activityLabel(activityID, info)
  info = info or activityInfoTable(activityID)
  local name = activityDisplayName(activityID, info)
  local minV, maxV = activityLevelBounds(info, name)
  if CEF.formatLevelBoundsRichText then
    local range = CEF.formatLevelBoundsRichText(minV, maxV)
    if range then
      return name .. "  " .. range
    end
  elseif minV then
    if maxV and maxV ~= minV then
      return name .. "  (" .. minV .. "-" .. maxV .. ")"
    end
    return name .. "  (" .. minV .. ")"
  end
  return name
end

function LFG.getCategories()
  local out = {}
  if not LFG.isAvailable() or not C_LFGList.GetAvailableCategories then
    return out
  end
  local cats = C_LFGList.GetAvailableCategories() or {}
  for _, id in ipairs(cats) do
    local keep = true
    if LFGUtil_GetFilteredActivities then
      local activities = LFGUtil_GetFilteredActivities(id)
      keep = type(activities) == "table" and #activities > 0
    end
    if keep then
      out[#out + 1] = { id = id, name = categoryName(id) }
    end
  end
  table.sort(out, function(a, b)
    return (a.name or "") < (b.name or "")
  end)
  return out
end

function LFG.getActivities(categoryId)
  local out = {}
  categoryId = tonumber(categoryId) or LFG.getSelectedCategoryId()
  if not categoryId or not LFG.isAvailable() then
    return out
  end
  local ids = nil
  if LFGUtil_GetFilteredActivities then
    ids = LFGUtil_GetFilteredActivities(categoryId)
  end
  if type(ids) ~= "table" or #ids == 0 then
    if C_LFGList.GetAvailableActivities then
      ids = C_LFGList.GetAvailableActivities(categoryId)
    end
  end
  if type(ids) ~= "table" then
    return out
  end
  for _, aid in ipairs(ids) do
    local info = activityInfoTable(aid)
    local raw = activityRawName(aid, info)
    local instKey = resolveInstanceKeyFromActivityName(raw)
    local name = (instKey and CEF.getInstanceDisplayName and CEF.getInstanceDisplayName(instKey)) or raw
    local minV, maxV = activityLevelBounds(info, name)
    if (not minV) and instKey and CEF.levelBoundsForDisplayName then
      minV, maxV = CEF.levelBoundsForDisplayName(name)
    end
    local isTbc = false
    local isTbcHeroic = false
    if CEF.isTbcActive and CEF.isTbcActive() then
      if instKey and CEF.instanceKeyIsTbcHeroic and CEF.instanceKeyIsTbcHeroic(instKey) then
        isTbc = true
        isTbcHeroic = true
      elseif instKey and CEF.instanceKeyIsTbc and CEF.instanceKeyIsTbc(instKey) then
        isTbc = true
      elseif not instKey and minV and minV >= 58 then
        isTbc = true
      end
    end
    out[#out + 1] = {
      id = aid,
      name = name,
      label = activityLabel(aid, info),
      minLevel = minV or 999,
      maxLevel = maxV or minV or 999,
      orderIndex = (type(info) == "table" and tonumber(info.orderIndex)) or 0,
      instanceKey = instKey,
      isTbc = isTbc,
      isTbcHeroic = isTbcHeroic,
    }
  end
  table.sort(out, function(a, b)
    local function bucket(x)
      if x.isTbcHeroic then
        return 2
      end
      if x.isTbc then
        return 1
      end
      return 0
    end
    local aB, bB = bucket(a), bucket(b)
    if aB ~= bB then
      return aB < bB
    end
    if a.minLevel ~= b.minLevel then
      return a.minLevel < b.minLevel
    end
    if a.maxLevel ~= b.maxLevel then
      return a.maxLevel < b.maxLevel
    end
    if a.orderIndex ~= b.orderIndex then
      return a.orderIndex < b.orderIndex
    end
    return (a.name or "") < (b.name or "")
  end)
  return out
end

function LFG.getSelectedActivityIds()
  local list = {}
  for id in pairs(selectedActivityIds) do
    list[#list + 1] = id
  end
  table.sort(list)
  return list
end

function LFG.isActivitySelected(activityId)
  activityId = tonumber(activityId)
  if not activityId or filterMyLevel then
    return false
  end
  -- Vazio = todas (nenhuma restrição marcada).
  local n = 0
  for _ in pairs(selectedActivityIds) do
    n = n + 1
    break
  end
  if n == 0 then
    return false
  end
  return selectedActivityIds[activityId] and true or false
end

function LFG.hasActivityFilter()
  if filterMyLevel then
    return true
  end
  for _ in pairs(selectedActivityIds) do
    return true
  end
  return false
end

function LFG.isMyLevelFilter()
  return filterMyLevel and true or false
end

function LFG.setMyLevelFilter(on)
  filterMyLevel = on and true or false
  if filterMyLevel then
    wipe(selectedActivityIds)
  end
end

function LFG.toggleMyLevelFilter()
  if filterMyLevel then
    filterMyLevel = false
  else
    filterMyLevel = true
    wipe(selectedActivityIds)
  end
  return filterMyLevel
end

function LFG.clearActivitySelection()
  wipe(selectedActivityIds)
  filterMyLevel = false
end

function LFG.toggleActivity(activityId)
  activityId = tonumber(activityId)
  if not activityId then
    return
  end
  filterMyLevel = false
  if selectedActivityIds[activityId] then
    selectedActivityIds[activityId] = nil
  else
    selectedActivityIds[activityId] = true
  end
end

function LFG.activityFilterSummary()
  if filterMyLevel then
    return CEF.L.FILTER_MY_LEVEL_INSTANCES or "Instances for my character"
  end
  local selected = LFG.getSelectedActivityIds()
  if #selected == 0 then
    return CEF.L.LFG_ALL_ACTIVITIES
  end
  if #selected == 1 then
    return activityLabel(selected[1])
  end
  return CEF.L("LFG_N_ACTIVITIES", #selected)
end

local function stopSearchWatch()
  if searchWatch then
    searchWatch:Hide()
  end
end

local function finishSearchFromWatchdog()
  if not searching then
    stopSearchWatch()
    return
  end
  searching = false
  searchFailed = false
  stopSearchWatch()
  -- Mostra o que existir no cliente mesmo sem o evento.
  LFG.refreshResults()
  local pending = pendingSearchCategory
  pendingSearchCategory = nil
  if pending then
    LFG.search(pending, { force = true })
  end
end

local function ensureSearchWatch()
  if searchWatch then
    return searchWatch
  end
  searchWatch = CreateFrame("Frame")
  searchWatch:Hide()
  searchWatch:SetScript("OnUpdate", function(self)
    if not searching then
      self:Hide()
      return
    end
    local now = (GetTime and GetTime()) or 0
    if (now - lastSearchAt) >= SEARCH_TIMEOUT then
      finishSearchFromWatchdog()
    end
  end)
  return searchWatch
end

local function beginSearchWatch()
  ensureSearchWatch():Show()
end

local function activityNameFromIds(activityIDs)
  if type(activityIDs) ~= "table" or #activityIDs == 0 then
    return ""
  end
  local names, seen = {}, {}
  for _, aid in ipairs(activityIDs) do
    local name = activityDisplayName(aid)
    if name and name ~= "" then
      local dk = string.lower(name)
      if not seen[dk] then
        seen[dk] = true
        names[#names + 1] = name
        if #names >= 5 then
          break
        end
      end
    end
  end
  if #names == 0 then
    return ""
  end
  return table.concat(names, ", ")
end

-- Nome + níveis coloridos; deduplica IDs da Blizzard que apontam à mesma DG.
-- Retorna richText, lineCount (instâncias distintas, máx. 5).
local function activityRichTextFromIds(activityIDs)
  if type(activityIDs) ~= "table" or #activityIDs == 0 then
    return "—", 1
  end
  local parts, seen = {}, {}
  for _, aid in ipairs(activityIDs) do
    local info = activityInfoTable(aid)
    local raw = activityRawName(aid, info)
    local key = resolveInstanceKeyFromActivityName(raw)
    local name = activityDisplayName(aid, info)
    if name and name ~= "" then
      local dk = key or string.lower(name)
      if not seen[dk] then
        seen[dk] = true
        local minV, maxV = activityLevelBounds(info, name)
        if (not minV) and key and CEF.levelBoundsForDisplayName then
          minV, maxV = CEF.levelBoundsForDisplayName(name)
        end
        if CEF.activityNameLevelsRichText then
          parts[#parts + 1] = CEF.activityNameLevelsRichText(name, minV, maxV, key)
        else
          parts[#parts + 1] = name
        end
        if #parts >= 5 then
          break
        end
      end
    end
  end
  if #parts == 0 then
    return "—", 1
  end
  if #parts == 1 then
    return parts[1], 1
  end
  -- Uma instância por linha (como a coluna Instância/níveis do Chat).
  return table.concat(parts, "\n\n"), #parts
end

local function memberCounts(resultID)
  local counts = { TANK = 0, HEALER = 0, DAMAGER = 0, NOROLE = 0 }
  if not C_LFGList.GetSearchResultMemberCounts then
    return counts
  end
  local raw = C_LFGList.GetSearchResultMemberCounts(resultID)
  if type(raw) ~= "table" then
    return counts
  end
  counts.TANK = tonumber(raw.TANK) or 0
  counts.HEALER = tonumber(raw.HEALER) or 0
  counts.DAMAGER = tonumber(raw.DAMAGER) or 0
  counts.NOROLE = tonumber(raw.NOROLE) or 0
  return counts
end

--- Lista de ícones (1 tank / 1 heal / 3 dps), estilo RoleEnumerate da Blizzard.
function LFG.buildRoleSlots(counts)
  counts = counts or {}
  local slots = {}
  for _, role in ipairs(ROLE_ORDER) do
    local filled = tonumber(counts[role]) or 0
    local expected = EXPECTED_5MAN[role] or 0
    for i = 1, expected do
      if i <= filled then
        slots[#slots + 1] = { atlas = ROLE_ATLAS[role], filled = true, role = role }
      else
        slots[#slots + 1] = { atlas = ROLE_ATLAS.EMPTY, filled = false, role = role }
      end
    end
  end
  return slots
end

local function activityDisplayMeta(activityIDs)
  local maxPlayers = 5
  local displayType = nil
  if type(activityIDs) ~= "table" then
    return displayType, maxPlayers
  end
  for _, aid in ipairs(activityIDs) do
    local info = C_LFGList.GetActivityInfoTable and C_LFGList.GetActivityInfoTable(aid)
    if type(info) == "table" then
      local mp = tonumber(info.maxNumPlayers) or 0
      if mp > maxPlayers then
        maxPlayers = mp
      end
      if displayType == nil and info.displayType ~= nil then
        displayType = info.displayType
      end
    end
  end
  return displayType, maxPlayers
end

local function enumRoleCount()
  if Enum and Enum.LFGListDisplayType and Enum.LFGListDisplayType.RoleCount ~= nil then
    return Enum.LFGListDisplayType.RoleCount
  end
  return 0 -- RoleCount na documentação Blizzard
end

--- RoleCount (números) para 10-man/raids; RoleEnumerate (slots) para 5-man.
function LFG.shouldUseRoleCount(displayType, maxPlayers, counts)
  counts = counts or {}
  if displayType ~= nil and displayType == enumRoleCount() then
    return true
  end
  maxPlayers = tonumber(maxPlayers) or 5
  if maxPlayers > 5 then
    return true
  end
  local tank = tonumber(counts.TANK) or 0
  local heal = tonumber(counts.HEALER) or 0
  local dps = tonumber(counts.DAMAGER) or 0
  if (tank + heal + dps) > 5 then
    return true
  end
  if tank > EXPECTED_5MAN.TANK or heal > EXPECTED_5MAN.HEALER or dps > EXPECTED_5MAN.DAMAGER then
    return true
  end
  return false
end

function LFG.buildRoleDisplay(counts, activityIDs)
  local displayType, maxPlayers = activityDisplayMeta(activityIDs)
  local useCount = LFG.shouldUseRoleCount(displayType, maxPlayers, counts)
  return {
    mode = useCount and "count" or "enumerate",
    counts = counts or { TANK = 0, HEALER = 0, DAMAGER = 0 },
    slots = useCount and nil or LFG.buildRoleSlots(counts),
    maxNumPlayers = maxPlayers,
    displayType = displayType,
  }
end

local function formatAge(age)
  age = tonumber(age) or 0
  if age < 60 then
    return CEF.L("LFG_AGE_SECONDS", math.floor(age))
  end
  if age < 3600 then
    return CEF.L("LFG_AGE_MINUTES", math.floor(age / 60))
  end
  return CEF.L("LFG_AGE_HOURS", math.floor(age / 3600))
end

local function leaderClassFile(resultID)
  if C_LFGList.GetSearchResultLeaderInfo then
    local leader = C_LFGList.GetSearchResultLeaderInfo(resultID)
    if type(leader) == "table" and type(leader.classFilename) == "string" and leader.classFilename ~= "" then
      return leader.classFilename
    end
  end
  if C_LFGList.GetSearchResultPlayerInfo then
    local member = C_LFGList.GetSearchResultPlayerInfo(resultID, 1)
    if type(member) == "table" and type(member.classFilename) == "string" and member.classFilename ~= "" then
      return member.classFilename
    end
  end
  if C_LFGList.GetSearchResultMemberInfo then
    local classFile = select(2, C_LFGList.GetSearchResultMemberInfo(resultID, 1))
    if type(classFile) == "string" and classFile ~= "" then
      return classFile
    end
    if type(classFile) == "table" and type(classFile.classFilename) == "string" then
      return classFile.classFilename
    end
  end
  return nil
end

local function normalizeResult(resultID)
  if not C_LFGList.GetSearchResultInfo then
    return nil
  end
  local info = C_LFGList.GetSearchResultInfo(resultID)
  if type(info) ~= "table" or info.isDelisted then
    return nil
  end
  local activityIDs = info.activityIDs
  if type(activityIDs) ~= "table" and info.activityID then
    activityIDs = { info.activityID }
  end
  activityIDs = activityIDs or {}
  local activityName = activityNameFromIds(activityIDs)
  local activityRichText, activityLineCount = activityRichTextFromIds(activityIDs)
  local instanceEntries = {}
  local seenInst = {}
  for _, aid in ipairs(activityIDs) do
    local aInfo = activityInfoTable(aid)
    local raw = activityRawName(aid, aInfo)
    local key = resolveInstanceKeyFromActivityName(raw)
    local name = activityDisplayName(aid, aInfo)
    if name and name ~= "" then
      local dk = key or string.lower(name)
      if not seenInst[dk] then
        seenInst[dk] = true
        local minV, maxV = activityLevelBounds(aInfo, name)
        if (not minV) and key and CEF.levelBoundsForDisplayName then
          minV, maxV = CEF.levelBoundsForDisplayName(
            (CEF.getInstanceDisplayName and CEF.getInstanceDisplayName(key)) or name
          )
        end
        instanceEntries[#instanceEntries + 1] = {
          key = key,
          name = name,
          minLevel = minV,
          maxLevel = maxV or minV,
          maxNumPlayers = (type(aInfo) == "table" and tonumber(aInfo.maxNumPlayers)) or nil,
        }
        if #instanceEntries >= 5 then
          break
        end
      end
    end
  end
  local minLevel, maxLevel = nil, nil
  for _, aid in ipairs(activityIDs) do
    local aInfo = activityInfoTable(aid)
    local aName = activityDisplayName(aid, aInfo)
    local minV, maxV = activityLevelBounds(aInfo, aName)
    if minV then
      maxV = maxV or minV
      if not minLevel or minV < minLevel then
        minLevel = minV
      end
      if not maxLevel or maxV > maxLevel then
        maxLevel = maxV
      end
    end
  end
  if not minLevel and activityName ~= "" then
    minLevel, maxLevel = activityLevelBounds(nil, activityName)
    if minLevel then
      maxLevel = maxLevel or minLevel
    end
  end
  local counts = memberCounts(resultID)
  local roleDisplay = LFG.buildRoleDisplay(counts, activityIDs)
  return {
    id = resultID,
    leaderName = info.leaderName or info.name or "?",
    leaderClass = leaderClassFile(resultID),
    comment = info.comment or "",
    numMembers = tonumber(info.numMembers) or 0,
    age = tonumber(info.age) or 0,
    ageText = formatAge(info.age),
    activityName = activityName,
    activityRichText = activityRichText,
    activityLineCount = activityLineCount or 1,
    activityIDs = activityIDs,
    instanceEntries = instanceEntries,
    minLevel = minLevel,
    maxLevel = maxLevel,
    counts = counts,
    roleDisplay = roleDisplay,
    roleSlots = roleDisplay.slots,
    isSolo = (tonumber(info.numMembers) or 0) <= 1,
    hasSelf = info.hasSelf and true or false,
  }
end

function LFG.isSearching()
  return searching
end

function LFG.didSearchFail()
  return searchFailed
end

function LFG.getResults()
  return results
end

local lastResultRefreshAt = 0
local RESULT_REFRESH_THROTTLE = 0.35
local MAX_RESULTS_NORMALIZE = 200

function LFG.refreshResults()
  wipe(results)
  if not LFG.isAvailable() then
    notify()
    return results
  end
  local total, ids = C_LFGList.GetFilteredSearchResults()
  if type(ids) ~= "table" then
    total, ids = C_LFGList.GetSearchResults()
  end
  ids = ids or {}
  local n = #ids
  if n > MAX_RESULTS_NORMALIZE then
    n = MAX_RESULTS_NORMALIZE
  end
  for i = 1, n do
    local row = normalizeResult(ids[i])
    if row then
      results[#results + 1] = row
    end
  end
  -- Mais recentes primeiro (menor idade).
  table.sort(results, function(a, b)
    local ageA = tonumber(a.age) or 0
    local ageB = tonumber(b.age) or 0
    if ageA ~= ageB then
      return ageA < ageB
    end
    return tostring(a.leaderName or "") < tostring(b.leaderName or "")
  end)
  lastResultRefreshAt = (GetTime and GetTime()) or 0
  notify()
  return results
end

function LFG.search(categoryId, opts)
  if not LFG.isAvailable() then
    return false, "unavailable"
  end
  opts = type(opts) == "table" and opts or {}
  categoryId = tonumber(categoryId) or LFG.getSelectedCategoryId()
  if not categoryId or categoryId <= 0 then
    return false, "no_category"
  end

  local now = (GetTime and GetTime()) or 0
  if searching then
    local elapsed = now - (lastSearchAt or 0)
    if not opts.force and elapsed < SEARCH_TIMEOUT then
      -- Guarda o pedido mais recente; evita perder filtros enquanto a busca corre.
      pendingSearchCategory = categoryId
      return false, "busy"
    end
    -- Busca antiga presa ou force: liberta o cadeado.
    searching = false
    stopSearchWatch()
  end

  pendingSearchCategory = nil
  selectedCategoryId = categoryId
  searching = true
  searchFailed = false
  lastSearchAt = now
  beginSearchWatch()
  notify()

  local filter, preferredFilters = 0, 0
  -- Busca só por categoria (rápido). Filtro de atividades fica no cliente.
  local ok = pcall(function()
    C_LFGList.Search(categoryId, filter, preferredFilters)
  end)
  if not ok then
    ok = pcall(function()
      C_LFGList.Search(categoryId, filter)
    end)
  end
  if not ok then
    searching = false
    searchFailed = true
    stopSearchWatch()
    notify()
    return false, "search_error"
  end
  return true
end

function LFG.handleEvent(event, ...)
  if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
    searching = false
    searchFailed = false
    stopSearchWatch()
    LFG.refreshResults()
    local pending = pendingSearchCategory
    pendingSearchCategory = nil
    if pending then
      LFG.search(pending, { force = true })
    end
  elseif event == "LFG_LIST_SEARCH_FAILED" then
    searching = false
    searchFailed = true
    stopSearchWatch()
    wipe(results)
    notify()
    local pending = pendingSearchCategory
    pendingSearchCategory = nil
    if pending then
      LFG.search(pending, { force = true })
    end
  elseif event == "LFG_LIST_SEARCH_RESULT_UPDATED" then
    -- Atualização pontual: throttle — o cliente dispara isto em rajada.
    if not searching then
      local now = (GetTime and GetTime()) or 0
      if (now - lastResultRefreshAt) >= RESULT_REFRESH_THROTTLE then
        LFG.refreshResults()
      end
    end
  elseif event == "LFG_LIST_AVAILABILITY_UPDATE" then
    if not selectedCategoryId then
      LFG.getSelectedCategoryId()
    end
    notify()
  end
end
