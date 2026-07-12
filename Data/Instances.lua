-- Módulo: lógica de instâncias e formatação da coluna "Instância / níveis"
-- Mantém exatamente a mesma lógica do arquivo único, mas exposta em ClassicEraFinder.*

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

-- Instâncias: várias substrings por linha (busca case-insensitive, texto puro).
local INSTANCE_ROWS = {
  { key = "Naxxramas", needles = { "naxxramas", "naxx ", " naxx", "naxx." } },
  { key = "Ahn'Qiraj 40", needles = { "aq40", "aq 40", "ahn'qiraj", "ahn qiraj", " temple of ahn", "cthun", "ouro", "viscidus", "huhuran", "fankriss" } },
  { key = "Ahn'Qiraj 20", needles = { "aq20", "aq 20", "ruins of ahn", "ossirian", "moam", "rajaxx" } },
  { key = "Zul'Gurub", needles = { " zg ", " zg.", "zg run", "zul'gurub", "zul gurub", "hakkar", "jindo" } },
  { key = "Molten Core", needles = { "molten core", "ragnaros", "geddon", "golemagg", "magmadar", "lucifron", " mc ", " mc,", "full mc", "molten", "m mc", " gdkp mc", "mc gdkp" } },
  { key = "Blackwing Lair", needles = { "blackwing", "bwl ", " bwl", "nefarian", "razorgore", "vael" } },
  { key = "Onyxia", needles = { "onyxia", " ony ", " ony.", "ony run" } },
  {
    key = "Stratholme",
    needles = {
      "stratholme",
      "strat ",
      " strat",
      "strat(",
      "strat)",
      "strat,",
      "strat.",
      "strat-",
      "strat live",
      "strat ud",
      "rivendare",
      "baron run",
    },
  },
  { key = "Scholomance", needles = { "scholomance", "scholo", "gandling", "darkmaster" } },
  {
    key = "Dire Maul",
    needles = {
      "dire maul",
      " dm ",
      "-> dm",
      "> dm ",
      "^dm ",
      " dm,",
      " dm.",
      " dm/",
      "/dm ",
      "dm north",
      "dm east",
      "dm west",
      "dm tribute",
      "immol'thar",
      "alzzin",
    },
  },
  { key = "Blackrock Spire", needles = { "ubrs", "lbrs", "blackrock spire", "lower spire", "upper spire", "drakkisath", "rend " } },
  { key = "Blackrock Depths", needles = { "blackrock depths", "brd ", " brd", "angerforge", "emperor ", "lokhtos", "arena run" } },
  { key = "Sunken Temple", needles = { "sunken temple", "atal'hakkar", "atal hakkar", " jammalan", "eranikus" } },
  { key = "Maraudon", needles = { "maraudon", " mara ", "mara run", "princess ", "rotgrip", "landslide" } },
  { key = "Zul'Farrak", needles = { "zul'farrak", "zul farrak", "zf ", " zf", "sandfury", "chief sandscalp" } },
  { key = "Uldaman", needles = { "uldaman", "ulda ", "/ulda", "ulda/", "archaedas", "ironaya" } },
  -- Scarlet Monastery no Classic = 4 instâncias separadas (alas).
  { key = "SM Graveyard", needles = { "sm gy", "sm graveyard", "sm grave" } },
  { key = "SM Library", needles = { "sm lib", "sm librar", "sm library" } },
  { key = "SM Armory", needles = { "sm arm", "sm armory", "sm arms" } },
  { key = "SM Cathedral", needles = { "sm cath", "sm cathedral" } },
  { key = "Razorfen Downs", needles = { "razorfen downs", "rfd/", " rfd/", "/rfd", "rfd ", " rfd", "amnennar" } },
  { key = "Razorfen Kraul", needles = { "razorfen kraul", "rfk ", " rfk", "charlga" } },
  { key = "Gnomeregan", needles = { "gnomeregan", "gnomer", "thermaplugg", "pummeler" } },
  { key = "The Stockade", needles = { "stockade", "stocks", "stocks,", "stocks.", "stocks:", "stocks;", "stocks)", "stocks(", "stocks ", " the stocks" } },
  { key = "Blackfathom Deeps", needles = { "blackfathom", "bfd ", " bfd", "akumai" } },
  { key = "Shadowfang Keep", needles = { "shadowfang", "sfk ", " sfk", "arugal" } },
  { key = "Deadmines", needles = { "deadmines", "dead mines", "van cleef", "defias", "vc ", " vc" } },
  {
    key = "Wailing Caverns",
    needles = {
      "wailing caverns",
      "for wc ",
      " wc ",
      " wc,",
      " wc.",
      " wc/",
      "/wc ",
      "^wc ",
      "wc run",
      " mutanus",
      "cobrahn",
    },
  },
  { key = "Ragefire Chasm", needles = { "ragefire", "rfc ", " rfc", "bazzalan" } },
}

-- Raids (Classic Era); o restante em INSTANCE_ROWS conta como masmorra no filtro.
local INSTANCE_RAIDS = {
  ["Naxxramas"] = true,
  ["Ahn'Qiraj 40"] = true,
  ["Ahn'Qiraj 20"] = true,
  ["Zul'Gurub"] = true,
  ["Molten Core"] = true,
  ["Blackwing Lair"] = true,
  ["Onyxia"] = true,
}

-- Faixa de níveis recomendada (Classic Era / vanilla); só para referência na UI.
local INSTANCE_LEVEL_RANGE = {
  ["Ragefire Chasm"] = "13-18",
  ["Wailing Caverns"] = "17-24",
  ["Deadmines"] = "17-26",
  ["Shadowfang Keep"] = "22-30",
  ["Blackfathom Deeps"] = "24-32",
  ["The Stockade"] = "24-32",
  ["Gnomeregan"] = "29-38",
  ["Razorfen Kraul"] = "30-40",
  ["SM Graveyard"] = "34-45",
  ["SM Library"] = "34-45",
  ["SM Armory"] = "34-45",
  ["SM Cathedral"] = "34-45",
  ["Razorfen Downs"] = "35-45",
  ["Uldaman"] = "41-51",
  ["Zul'Farrak"] = "44-54",
  ["Maraudon"] = "46-55",
  ["Sunken Temple"] = "50-60",
  ["Blackrock Depths"] = "52-60",
  ["Dire Maul"] = "56-60",
  ["Scholomance"] = "58-60",
  ["Stratholme"] = "58-60",
  ["Blackrock Spire"] = "55-60",
  ["Zul'Gurub"] = "60",
  ["Molten Core"] = "60",
  ["Onyxia"] = "60",
  ["Blackwing Lair"] = "60",
  ["Ahn'Qiraj 20"] = "60",
  ["Ahn'Qiraj 40"] = "60",
  ["Naxxramas"] = "60",
}

-- Nomes oficiais Blizzard (AreaTable / LFG), nunca tradução manual.
-- areaId → C_Map.GetAreaInfo; lfgId → GetLFGDungeonInfo (melhor para alas SM).
-- Preferência: lfgPrefer=true usa LFG primeiro (asas / nomes distintos AQ).
local INSTANCE_BLIZZARD_IDS = {
  ["Ragefire Chasm"] = { areaId = 2437, lfgId = 4 },
  ["Wailing Caverns"] = { areaId = 718, lfgId = 1 },
  ["Deadmines"] = { areaId = 1581, lfgId = 6 },
  ["Shadowfang Keep"] = { areaId = 209, lfgId = 8 },
  ["Blackfathom Deeps"] = { areaId = 719, lfgId = 10 },
  ["The Stockade"] = { areaId = 717, lfgId = 12 },
  ["Gnomeregan"] = { areaId = 721, lfgId = 14 },
  ["Razorfen Kraul"] = { areaId = 491, lfgId = 16 },
  ["SM Graveyard"] = { areaId = 796, lfgId = 18, lfgPrefer = true },
  ["SM Library"] = { areaId = 796, lfgId = 165, lfgPrefer = true },
  ["SM Armory"] = { areaId = 796, lfgId = 163, lfgPrefer = true },
  ["SM Cathedral"] = { areaId = 796, lfgId = 164, lfgPrefer = true },
  ["Razorfen Downs"] = { areaId = 722, lfgId = 20 },
  ["Uldaman"] = { areaId = 1337, lfgId = 22 },
  ["Zul'Farrak"] = { areaId = 1176, lfgId = 24 },
  ["Maraudon"] = { areaId = 2100, lfgId = 26 },
  ["Sunken Temple"] = { areaId = 1477, lfgId = 28 },
  ["Blackrock Depths"] = { areaId = 1584, lfgId = 30 },
  ["Blackrock Spire"] = { areaId = 1583, lfgId = 32 },
  ["Dire Maul"] = { areaId = 2557, lfgId = 34 },
  ["Scholomance"] = { areaId = 2057, lfgId = 2 },
  ["Stratholme"] = { areaId = 2017, lfgId = 40 },
  ["Zul'Gurub"] = { areaId = 1977, lfgId = 42 },
  ["Molten Core"] = { areaId = 2717, lfgId = 48 },
  ["Onyxia"] = { areaId = 2159, lfgId = 46 },
  ["Blackwing Lair"] = { areaId = 2677, lfgId = 50 },
  ["Ahn'Qiraj 20"] = { areaId = 3429, lfgId = 160, lfgPrefer = true },
  ["Ahn'Qiraj 40"] = { areaId = 3428, lfgId = 161, lfgPrefer = true },
  ["Naxxramas"] = { areaId = 3456, lfgId = 159 },
}

local displayNameCache = {}

local function blizzardNameFromLfg(lfgId)
  if not lfgId or not GetLFGDungeonInfo then
    return nil
  end
  local name = GetLFGDungeonInfo(lfgId)
  if type(name) == "string" and name ~= "" then
    return name
  end
  return nil
end

local function blizzardNameFromArea(areaId)
  if not areaId or not C_Map or not C_Map.GetAreaInfo then
    return nil
  end
  local name = C_Map.GetAreaInfo(areaId)
  if type(name) == "string" and name ~= "" then
    return name
  end
  return nil
end

local function activeLocaleCode()
  if CEF.Locale and CEF.Locale.getActiveCode then
    return CEF.Locale.getActiveCode()
  end
  return (GetLocale and GetLocale()) or "enUS"
end

local function nameFromPack(instanceKey, localeCode)
  local packs = CEF.INSTANCE_DISPLAY_NAMES
  if type(packs) ~= "table" then
    return nil
  end
  local pack = packs[localeCode] or packs.enUS
  if not pack then
    return nil
  end
  local n = pack[instanceKey]
  if type(n) == "string" and n ~= "" then
    return n
  end
  return nil
end

--- Nome da instância no idioma ativo do addon (tabelas oficiais Blizzard).
--- Se o pack não tiver a chave, tenta API do cliente; senão a chave EN.
function CEF.getInstanceDisplayName(instanceKey)
  if not instanceKey or instanceKey == "" or instanceKey == "—" then
    return instanceKey or "—"
  end
  local localeCode = activeLocaleCode()
  local cacheKey = localeCode .. "\0" .. instanceKey
  local cached = displayNameCache[cacheKey]
  if cached then
    return cached
  end

  local name = nameFromPack(instanceKey, localeCode)

  -- Fallback: APIs do cliente (só batem se o idioma do jogo = pack).
  if not name then
    local meta = INSTANCE_BLIZZARD_IDS[instanceKey]
    if meta then
      if meta.lfgPrefer then
        name = blizzardNameFromLfg(meta.lfgId) or blizzardNameFromArea(meta.areaId)
      else
        name = blizzardNameFromArea(meta.areaId) or blizzardNameFromLfg(meta.lfgId)
      end
    end
  end

  if not name or name == "" then
    name = instanceKey
  end
  displayNameCache[cacheKey] = name
  return name
end

function CEF.clearInstanceDisplayNameCache()
  wipe(displayNameCache)
end

-- Chave especial do filtro: só instâncias cujo range recomendado inclui o nível do jogador.
CEF.FILTER_INSTANCE_MY_LEVEL = "__cef_my_level__"

local function instanceLevelRangeBounds(instanceKey)
  local plain = INSTANCE_LEVEL_RANGE[instanceKey]
  if not plain then
    return nil, nil
  end
  local minV, maxV = plain:match("^(%d+)%-(%d+)$")
  if minV and maxV then
    return tonumber(minV), tonumber(maxV)
  end
  local solo = plain:match("^(%d+)$")
  if solo then
    local n = tonumber(solo)
    return n, n
  end
  return nil, nil
end

function CEF.instanceFitsPlayerLevel(instanceKey, playerLevel)
  local lvl = playerLevel or UnitLevel("player")
  if not lvl or not instanceKey then
    return false
  end
  local minV, maxV = instanceLevelRangeBounds(instanceKey)
  if not minV or not maxV then
    return false
  end
  -- Dentro do range: exclui dungeon “alta demais” (lvl < min) e “baixa demais” (lvl > max).
  return lvl >= minV and lvl <= maxV
end

function CEF.countInstancesForPlayerLevel(playerLevel)
  local lvl = playerLevel or UnitLevel("player")
  local n = 0
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      if CEF.instanceFitsPlayerLevel(k, lvl) then
        n = n + 1
      end
    end
  end
  return n
end

local function instanceMinLevelForSort(instanceKey)
  local minV = instanceLevelRangeBounds(instanceKey)
  return minV or 999
end

-- Entradas do menu do filtro: opção (key false = todas) ou cabeçalho de secção.
CEF.INSTANCE_FILTER_MENU_OPTS = {}
do
  local dungeons, raids = {}, {}
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      if INSTANCE_RAIDS[k] then
        raids[#raids + 1] = k
      else
        dungeons[#dungeons + 1] = k
      end
    end
  end

  table.sort(dungeons, function(a, b)
    local ka, kb = instanceMinLevelForSort(a), instanceMinLevelForSort(b)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a) < strlower(b)
  end)

  table.sort(raids, function(a, b)
    local ka, kb = instanceMinLevelForSort(a), instanceMinLevelForSort(b)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a) < strlower(b)
  end)

  local opts = {}
  opts[#opts + 1] = { kind = "opt", key = false }
  opts[#opts + 1] = { kind = "opt", key = CEF.FILTER_INSTANCE_MY_LEVEL }
  opts[#opts + 1] = { kind = "hdr", textKey = "CATEGORY_DUNGEONS" }
  for _, k in ipairs(dungeons) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end
  opts[#opts + 1] = { kind = "hdr", textKey = "CATEGORY_RAIDS" }
  for _, k in ipairs(raids) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end

  CEF.INSTANCE_FILTER_MENU_OPTS = opts
end

-- Laranja = nível mínimo do range, verde = nível máximo (|c … |r como no chat).
local COLOR_LVL_ORANGE_MIN = "|cffff9933"
local COLOR_LVL_GREEN_MAX = "|cff33cc33"

-- Nome da instância: masmorra (azul-claro) vs raid (âmbar), alinhado a INSTANCE_RAIDS.
local COLOR_INSTANCE_DUNGEON_NAME = "|cff9fd3ff"
local COLOR_INSTANCE_RAID_NAME = "|cffffb74d"

local function instanceNameRichOpenTag(instanceKey)
  if instanceKey and INSTANCE_RAIDS[instanceKey] then
    return COLOR_INSTANCE_RAID_NAME
  end
  return COLOR_INSTANCE_DUNGEON_NAME
end

function CEF.instanceKeyIsRaid(instanceKey)
  return instanceKey ~= nil and instanceKey ~= false and INSTANCE_RAIDS[instanceKey] == true
end

local function formatLevelRangeColored(plain)
  if not plain or plain == "—" then
    return "—"
  end
  local minV, maxV = plain:match("^(%d+)%-(%d+)$")
  if minV and maxV then
    return COLOR_LVL_ORANGE_MIN .. minV .. "|r-" .. COLOR_LVL_GREEN_MAX .. maxV .. "|r"
  end
  local solo = plain:match("^(%d+)$")
  if solo then
    return COLOR_LVL_ORANGE_MIN .. solo .. "|r-" .. COLOR_LVL_GREEN_MAX .. solo .. "|r"
  end
  return plain
end

local function recommendedLevelRichText(instanceKey)
  if not instanceKey or instanceKey == "—" then
    return "—"
  end
  local plain = INSTANCE_LEVEL_RANGE[instanceKey]
  if not plain then
    return "—"
  end
  return formatLevelRangeColored(plain)
end

function CEF.instanceLevelRangeRichText(instanceKey)
  return recommendedLevelRichText(instanceKey)
end

--- Texto colorido "min-max" (laranja/verde) a partir de bounds numéricos.
function CEF.formatLevelBoundsRichText(minV, maxV)
  minV = tonumber(minV)
  maxV = tonumber(maxV)
  if not minV or minV <= 0 then
    return nil
  end
  if not maxV or maxV <= 0 then
    return formatLevelRangeColored(tostring(minV))
  end
  if maxV == minV then
    return formatLevelRangeColored(tostring(minV))
  end
  return formatLevelRangeColored(minV .. "-" .. maxV)
end

--- Resolve min/max recomendados a partir do nome localizado da atividade LFG.
function CEF.levelBoundsForDisplayName(activityName)
  if type(activityName) ~= "string" or activityName == "" then
    return nil, nil
  end
  local exactKey, partialKey = nil, nil
  for key in pairs(INSTANCE_LEVEL_RANGE) do
    local dn = CEF.getInstanceDisplayName(key)
    if type(dn) == "string" and dn ~= "" then
      if dn == activityName then
        exactKey = key
        break
      end
      if not partialKey and (activityName:find(dn, 1, true) or dn:find(activityName, 1, true)) then
        partialKey = key
      end
    end
  end
  local key = exactKey or partialKey
  if not key then
    return nil, nil
  end
  return instanceLevelRangeBounds(key)
end

-- Linhas de deteção agrupadas (mesma ordem que o menu de filtro).
function CEF.getInstanceDetectionRowsGroupedSorted()
  local d, r = {}, {}
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      if INSTANCE_RAIDS[k] then
        r[#r + 1] = row
      else
        d[#d + 1] = row
      end
    end
  end
  local function sortFn(a, b)
    local ka, kb = instanceMinLevelForSort(a.key), instanceMinLevelForSort(b.key)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a.key) < strlower(b.key)
  end
  table.sort(d, sortFn)
  table.sort(r, sortFn)
  return { dungeons = d, raids = r }
end

function CEF.instanceFilterOptionRichText(instKeyOrSet)
  -- Menu: chave única (false = “todas”; string = uma instância / modo especial).
  if type(instKeyOrSet) ~= "table" then
    if instKeyOrSet == false or instKeyOrSet == nil then
      return "|cffffffff" .. CEF.L.FILTER_ALL_INSTANCES .. "|r"
    end
    if instKeyOrSet == CEF.FILTER_INSTANCE_MY_LEVEL then
      local n = CEF.countInstancesForPlayerLevel()
      return ("|cffffffff%s|r  |cffcccccc(%d)|r"):format(CEF.L.FILTER_MY_LEVEL_INSTANCES, n)
    end
    return instanceNameRichOpenTag(instKeyOrSet) .. CEF.getInstanceDisplayName(instKeyOrSet) .. "|r  " .. recommendedLevelRichText(instKeyOrSet)
  end
  -- Resumo do botão: set multi-seleção.
  local keys = CEF.filterSetSortedKeys(instKeyOrSet)
  if #keys == 0 then
    return "|cffffffff" .. CEF.L.FILTER_ALL_INSTANCES .. "|r"
  end
  if #keys == 1 then
    local k = keys[1]
    if k == CEF.FILTER_INSTANCE_MY_LEVEL then
      return CEF.instanceFilterOptionRichText(k)
    end
    return instanceNameRichOpenTag(k) .. CEF.getInstanceDisplayName(k) .. "|r  " .. recommendedLevelRichText(k)
  end
  return "|cffffffff" .. CEF.L("FILTER_N_INSTANCES", #keys) .. "|r"
end

-- Scarlet Monastery: 4 alas. Mensagem genérica (sem gy/lib/arm/cath) → assume full clear nas 4.
local SCARLET_WING_KEYS = { "SM Graveyard", "SM Library", "SM Armory", "SM Cathedral" }

local SCARLET_GENERIC_NEEDLES = {
  "full sm",
  "full-sm",
  "clear sm",
  "all sm",
  "sm full",
  "run sm",
  "sm run",
  "full clear sm",
  "full monastery",
  "clear monastery",
  " scarlet monastery",
  "scarlet monastery",
  "/sm",
  " sm/",
}

local function listContainsAnyKey(list, keys)
  for _, k in ipairs(list) do
    for _, w in ipairs(keys) do
      if k == w then
        return true
      end
    end
  end
  return false
end

-- «sm» como palavra (ex.: «lfg sm», «dps sm») sem apanhar «small», «asm», etc.
local function scarletSmAsIsolatedWord(lower)
  local pos = 1
  while true do
    local a, b = lower:find("sm", pos, true)
    if not a then
      break
    end
    local beforeLetter = (a > 1) and lower:sub(a - 1, a - 1):match("%a")
    local afterCh = lower:sub(b + 1, b + 1)
    local afterLetter = afterCh ~= "" and afterCh:match("%a")
    if not beforeLetter and not afterLetter then
      return true
    end
    pos = b + 1
  end
  return false
end

local function scarletGenericInText(lower)
  for _, n in ipairs(SCARLET_GENERIC_NEEDLES) do
    if lower:find(n, 1, true) then
      return true
    end
  end
  if scarletSmAsIsolatedWord(lower) then
    return true
  end
  return false
end

-- «DM» sozinho no fim (ex.: «LF3M DPS DM», «… HEALER DM») — sem espaço depois do m.
local function direMaulIsolatedDmPos(lower)
  local t = lower:match("^%s*(.-)%s*$") or lower
  local a = t:find("[%s%p]dm$")
  if a then
    return a
  end
  if #t >= 3 and t:sub(-2) == "dm" then
    local prev = t:sub(-3, -3)
    if prev:match("[%s%p]") then
      return #t - 3
    end
  end
  if t == "dm" or t:find("^dm[%s%p]", 1) then
    return 1
  end
  return nil
end

-- «WC» como Wailing Caverns no fim (ex.: «LF1M DPS WC») ou só «wc» + separador.
local function wailingCavernsIsolatedWcPos(lower)
  local t = lower:match("^%s*(.-)%s*$") or lower
  local a = t:find("[%s%p]wc$")
  if a then
    return a
  end
  if #t >= 3 and t:sub(-2) == "wc" then
    local prev = t:sub(-3, -3)
    if prev:match("[%s%p]") then
      return #t - 3
    end
  end
  if t == "wc" or t:find("^wc[%s%p]", 1) then
    return 1
  end
  return nil
end

-- Todas as instâncias reconhecidas na mensagem; ordem = primeira ocorrência no texto.
function CEF.detectInstances(text)
  if not text or text == "" then
    return {}
  end
  -- Igual a messageLooksLFG: minúsculas + espaços colapsados (evita falhar em «for  wc» no chat).
  local lower = CEF.normalizeMessage(text)
  if lower == "" then
    return {}
  end
  local hits = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local bestPos
    for _, n in ipairs(row.needles) do
      local pos = lower:find(n, 1, true)
      if pos and (not bestPos or pos < bestPos) then
        bestPos = pos
      end
    end
    if bestPos then
      hits[row.key] = bestPos
    end
  end

  if not hits["Dire Maul"] then
    local pDm = direMaulIsolatedDmPos(lower)
    if pDm then
      hits["Dire Maul"] = pDm
    end
  end

  if not hits["Wailing Caverns"] then
    local pWc = wailingCavernsIsolatedWcPos(lower)
    if pWc then
      hits["Wailing Caverns"] = pWc
    end
  end

  local tmp = {}
  for k, pos in pairs(hits) do
    tmp[#tmp + 1] = { key = k, pos = pos }
  end
  table.sort(tmp, function(a, b)
    if a.pos ~= b.pos then
      return a.pos < b.pos
    end
    return strlower(a.key) < strlower(b.key)
  end)

  local out = {}
  for _, item in ipairs(tmp) do
    out[#out + 1] = item.key
  end

  if scarletGenericInText(lower) and not listContainsAnyKey(out, SCARLET_WING_KEYS) then
    for _, w in ipairs(SCARLET_WING_KEYS) do
      out[#out + 1] = w
    end
  end

  return out
end

function CEF.detectInstance(text)
  local list = CEF.detectInstances(text)
  return list[1] or "—"
end

local function entryInstancesList(e)
  if not e then
    return {}
  end
  if type(e.instances) == "table" and #e.instances > 0 then
    return e.instances
  end
  if e.instance and e.instance ~= "" and e.instance ~= "—" then
    return { e.instance }
  end
  return {}
end

function CEF.entryHasInstance(e, key)
  if not key or key == false then
    return true
  end
  for _, k in ipairs(entryInstancesList(e)) do
    if k == key then
      return true
    end
  end
  return false
end

function CEF.entryMatchesPlayerLevelInstances(e, playerLevel)
  for _, k in ipairs(entryInstancesList(e)) do
    if CEF.instanceFitsPlayerLevel(k, playerLevel) then
      return true
    end
  end
  return false
end

-- Coluna: nome + intervalo de níveis na mesma linha por instância.
function CEF.entryInstancesComboRichText(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return "—"
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = instanceNameRichOpenTag(k) .. CEF.getInstanceDisplayName(k) .. "|r  " .. recommendedLevelRichText(k)
  end
  -- Quebra extra (linha em branco) para separar visualmente instâncias.
  return table.concat(parts, "\n\n")
end

-- Tooltip inline (uma linha) para não “quebrar” após o prefixo “Instância:”
function CEF.entryInstancesComboRichTextInline(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return "—"
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = instanceNameRichOpenTag(k) .. CEF.getInstanceDisplayName(k) .. "|r  " .. recommendedLevelRichText(k)
  end
  return table.concat(parts, ", ")
end

function CEF.entryInstancesLineCount(e)
  local list = entryInstancesList(e)
  local c = #list
  if c < 1 then
    return 1
  end
  return c
end

function CEF.entryInstancesSearchBlob(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return strlower(e.instance or "")
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = strlower(k)
  end
  return table.concat(parts, " ")
end

-- Leitura para a UI “Termos” (somente referência; listas são as mesmas usadas na deteção).
function CEF.getInstanceDetectionCatalog()
  return {
    rows = INSTANCE_ROWS,
    scarletGeneric = SCARLET_GENERIC_NEEDLES,
    scarletGenericUiHints = {
      CEF.L.TERMS_SM_AUTO_HINT,
    },
  }
end

