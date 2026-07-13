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
  -- Stratholme: 2 entradas separadas (viva = portão principal; morta-viva = entrada de serviço).
  -- Menção genérica («strat») sem lado → expande para as 2 em detectInstances.
  { key = "Strat Live", needles = { "strat live", "live strat", "live side", "main gate", "strat(live", "strat (live" } },
  { key = "Strat UD", needles = { "strat ud", "ud strat", "strat undead", "undead strat", "ud side", "baron run", "baron side", "rivendare", "service entrance" } },
  { key = "Scholomance", needles = { "scholomance", "scholo", "gandling", "darkmaster" } },
  -- Dire Maul: 3 alas separadas. Menção genérica («dm») sem ala → expande para as 3.
  { key = "DM East", needles = { "dm east", "dm: east", "dm:e", "dm e ", "dme ", " dme", "east dm", "alzzin", "pusillin" } },
  { key = "DM West", needles = { "dm west", "dm: west", "dm:w", "dm w ", "dmw ", " dmw", "west dm", "immol'thar", "immolthar", "tendris" } },
  { key = "DM North", needles = { "dm north", "dm: north", "dm:n", "dm n ", "dmn ", " dmn", "north dm", "dm tribute", "tribute run", "king gordok" } },
  -- Blackrock Spire: inferior (5-man) e superior (10-man) separados.
  -- Menção genérica («blackrock spire»/«brs») sem lado → expande para as 2.
  { key = "LBRS", needles = { "lbrs", "lower spire", "lower blackrock", "lower brs", "wyrmthalak", "voone", "halycon" } },
  { key = "UBRS", needles = { "ubrs", "upper spire", "upper blackrock", "upper brs", "drakkisath", "rend ", "gyth", "jed run" } },
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

-- ===== Season of Discovery =====
-- Conteúdo exclusivo SoD: só entra na deteção/filtros/termos em realm SoD
-- (Era e Hardcore não veem estas entradas).
-- Nota: "karazhan" aqui é Crypts (SoD). No TBC a raid Karazhan vive em TBC_INSTANCE_ROWS.
local SOD_INSTANCE_ROWS = {
  { key = "Demon Fall Canyon", needles = { "demon fall", "demonfall", "dfc ", " dfc" } },
  { key = "Karazhan Crypts", needles = { "karazhan", "kara crypt", "karazhan crypt", "crypts" } },
  { key = "Scarlet Enclave", needles = { "scarlet enclave", "enclave", "tse ", " tse" } },
}

-- Em SoD estas masmorras clássicas viram raids.
local SOD_RAIDS = {
  ["Blackfathom Deeps"] = true,
  ["Gnomeregan"] = true,
  ["Sunken Temple"] = true,
  ["Scarlet Enclave"] = true,
}

-- Ranges recomendados diferentes em SoD (raids de leveling continuam rodando no 60).
local SOD_LEVEL_RANGE = {
  ["Blackfathom Deeps"] = "25-60",
  ["Gnomeregan"] = "40-60",
  ["Sunken Temple"] = "50-60",
}

-- ===== Burning Crusade / TBC Anniversary =====
-- Outland (+ Magisters / Sunwell): só no cliente TBC (vanilla 60 permanece na base).
-- Needles no mesmo estilo Classic: abreviações EN do chat (não nomes i18n —
-- esses vão em InstanceNames para a UI). Masmorras: Normal + "… Heroic".
local TBC_DUNGEON_ROWS = {
  -- Hellfire Citadel
  {
    key = "Hellfire Ramparts",
    needles = { "hellfire ramparts", "ramparts", "ramps ", " ramps", "rampart" },
  },
  {
    key = "Blood Furnace",
    needles = { "blood furnace", " bf ", "/bf", "bf/", "bf,", "bf.", "bf:" },
  },
  {
    key = "Shattered Halls",
    needles = { "shattered halls", "shattered hall", "shalls", " shh ", "shh " },
  },
  -- Coilfang Reservoir
  {
    key = "Slave Pens",
    needles = { "slave pens", "slave pen", " pens " },
  },
  {
    key = "Underbog",
    needles = { "underbog" },
  },
  {
    key = "Steamvault",
    needles = { "steamvault", "steam vault" },
  },
  -- Auchindoun
  {
    key = "Mana-Tombs",
    needles = { "mana-tombs", "mana tombs", "manatombs" },
  },
  {
    key = "Auchenai Crypts",
    needles = { "auchenai", "auchenai crypt" },
  },
  {
    key = "Sethekk Halls",
    needles = { "sethekk", "seth halls" },
  },
  {
    key = "Shadow Labyrinth",
    needles = { "shadow labyrinth", "shadow lab", "slab ", " slab" },
  },
  -- Caverns of Time
  {
    key = "Old Hillsbrad",
    needles = { "old hillsbrad", "hillsbrad", "ohb ", " ohb", "durnholde", "thrall run" },
  },
  {
    key = "Black Morass",
    needles = { "black morass", "morass", "opening of the dark portal" },
  },
  -- Isle of Quel'Danas
  {
    key = "Magisters' Terrace",
    needles = { "magisters", "magister", "mgt ", " mgt" },
  },
  -- Tempest Keep satellites (dungeons; o raid "Tempest Keep" / The Eye fica em TBC_RAID_ROWS)
  {
    key = "Mechanar",
    needles = { "mechanar", "mech ", " mech" },
  },
  {
    key = "Botanica",
    needles = { "botanica" },
  },
  {
    key = "Arcatraz",
    needles = { "arcatraz", "arca " },
  },
}

local TBC_RAID_ROWS = {
  {
    key = "Karazhan",
    needles = { "karazhan", "kara ", " kara", "kara,", "kara.", "kara/", "/kara" },
  },
  { key = "Gruul's Lair", needles = { "gruul", "gruul's", "grull" } },
  {
    key = "Magtheridon",
    needles = { "magtheridon", "magth", "maggy" },
  },
  {
    key = "SSC",
    needles = { "serpentshrine", "ssc ", " ssc", "vashj" },
  },
  {
    key = "Tempest Keep",
    needles = { "tempest keep", "the eye", "tk ", " tk,", " tk.", "kael'thas", "kaelthas" },
  },
  { key = "Hyjal", needles = { "hyjal", "mount hyjal", "archimonde" } },
  {
    key = "Black Temple",
    needles = { "black temple", "bt ", " bt,", " bt.", "illidan" },
  },
  { key = "Zul'Aman", needles = { "zul'aman", "zul aman", "za ", " za,", " za." } },
  {
    key = "Sunwell Plateau",
    needles = { "sunwell", "swp ", " swp", "kil'jaeden", "kiljaeden" },
  },
}

-- Abreviações EN comuns de heroica no chat (além de "hc"/"heroic" + needle base).
local TBC_HEROIC_EXTRA_NEEDLES = {
  ["Hellfire Ramparts"] = { "hc ramps", "h ramps", "hramps", "hc ramparts", "h ramparts" },
  ["Blood Furnace"] = { "hbf", "hc bf", "h bf", "hcbf", "hc furnace" },
  ["Shattered Halls"] = { "hsh", "hc sh", "h sh", "hc shalls", "h shalls", "hc shattered", "h shattered" },
  ["Slave Pens"] = { "hsp", "hc sp", "h sp", "hc pens", "h pens", "hc slave", "h slave" },
  ["Underbog"] = { "hub", "hc ub", "h ub", "hc underbog", "h underbog" },
  ["Steamvault"] = { "hsv", "hc sv", "h sv", "hc steam", "h steam" },
  ["Mana-Tombs"] = { "hmt", "hc mt", "h mt", "hc mana", "h mana", "hc tombs", "h tombs" },
  ["Auchenai Crypts"] = { "hac", "hc ac", "h ac", "hc auchenai", "h auchenai", "hc crypts" },
  ["Sethekk Halls"] = { "hc sethekk", "h sethekk", "hc seth", "h seth" },
  ["Shadow Labyrinth"] = { "hsl", "hc slab", "h slab", "hc shadow lab", "h shadow lab" },
  ["Old Hillsbrad"] = { "hohb", "hc ohb", "h ohb", "hc hillsbrad", "h hillsbrad", "hc durnholde" },
  ["Black Morass"] = { "hbm", "hc bm", "h bm", "hc morass", "h morass", "hc black morass" },
  ["Magisters' Terrace"] = { "hmgt", "hc mgt", "h mgt", "hc magisters", "h magisters", "hc terrace", "h terrace" },
  ["Mechanar"] = { "hc mech", "h mech", "hc mechanar", "h mechanar" },
  ["Botanica"] = { "hc bot", "h bot", "hc botanica", "h botanica" },
  ["Arcatraz"] = { "hc arc", "h arc", "hc arcatraz", "h arcatraz", "hc arca", "h arca" },
}

-- Só EN, como o restante do catálogo Classic (Termos / detecção).
local HEROIC_CHAT_TOKENS = {
  "hc",
  "heroic",
}

local function buildTbcHeroicNeedles(baseNeedles, extra)
  local out, seen = {}, {}
  local function add(s)
    if type(s) ~= "string" or s == "" or seen[s] then
      return
    end
    seen[s] = true
    out[#out + 1] = s
  end
  for _, n in ipairs(baseNeedles or {}) do
    local t = tostring(n):match("^%s*(.-)%s*$") or ""
    -- Evita combinar abreviações muito curtas ("bf") com todos os tokens.
    if #t >= 4 then
      for _, h in ipairs(HEROIC_CHAT_TOKENS) do
        add(h .. " " .. t)
        add(t .. " " .. h)
      end
    end
  end
  for _, e in ipairs(extra or {}) do
    add(e)
  end
  return out
end

local TBC_HEROIC_ROWS = {}
local TBC_HEROIC_KEYS = {}
local TBC_HEROIC_BASE = {} -- heroicKey → normalKey

for _, row in ipairs(TBC_DUNGEON_ROWS) do
  local hKey = row.key .. " Heroic"
  TBC_HEROIC_KEYS[hKey] = true
  TBC_HEROIC_BASE[hKey] = row.key
  TBC_HEROIC_ROWS[#TBC_HEROIC_ROWS + 1] = {
    key = hKey,
    needles = buildTbcHeroicNeedles(row.needles, TBC_HEROIC_EXTRA_NEEDLES[row.key]),
  }
end

-- Lista unificada usada no merge de flavor (normal → heroica → raids).
local TBC_INSTANCE_ROWS = {}
for _, row in ipairs(TBC_DUNGEON_ROWS) do
  TBC_INSTANCE_ROWS[#TBC_INSTANCE_ROWS + 1] = row
end
for _, row in ipairs(TBC_HEROIC_ROWS) do
  TBC_INSTANCE_ROWS[#TBC_INSTANCE_ROWS + 1] = row
end
for _, row in ipairs(TBC_RAID_ROWS) do
  TBC_INSTANCE_ROWS[#TBC_INSTANCE_ROWS + 1] = row
end

local TBC_RAIDS = {
  ["Karazhan"] = true,
  ["Gruul's Lair"] = true,
  ["Magtheridon"] = true,
  ["SSC"] = true,
  ["Tempest Keep"] = true,
  ["Hyjal"] = true,
  ["Black Temple"] = true,
  ["Zul'Aman"] = true,
  ["Sunwell Plateau"] = true,
}

local TBC_INSTANCE_KEYS = {}
for _, row in ipairs(TBC_INSTANCE_ROWS) do
  TBC_INSTANCE_KEYS[row.key] = true
end

--- true se a chave pertence ao pack Outland / TBC Anniversary.
function CEF.instanceKeyIsTbc(instanceKey)
  return instanceKey ~= nil and TBC_INSTANCE_KEYS[instanceKey] == true
end

--- true se é masmorra heroica TBC (chave "… Heroic").
function CEF.instanceKeyIsTbcHeroic(instanceKey)
  return instanceKey ~= nil and TBC_HEROIC_KEYS[instanceKey] == true
end

--- Chave normal correspondente a uma heroica (ou nil).
function CEF.tbcHeroicBaseKey(instanceKey)
  return instanceKey and TBC_HEROIC_BASE[instanceKey] or nil
end

--- Chave heroica correspondente a uma masmorra TBC normal (ou nil).
function CEF.tbcHeroicKeyFor(normalKey)
  if not normalKey then
    return nil
  end
  local h = normalKey .. " Heroic"
  if TBC_HEROIC_KEYS[h] then
    return h
  end
  return nil
end

local sodActiveCache = nil
local tbcActiveCache = nil
local INSTANCE_ROWS_MERGED = nil
local INSTANCE_ROWS_MERGED_FLAVOR = nil

--- Cap de nível do cliente (60 Era / 70 TBC).
function CEF.getMaxPlayerLevel()
  if GetMaxPlayerLevel then
    local n = tonumber(GetMaxPlayerLevel())
    if n and n > 0 then
      return n
    end
  end
  if CEF.isTbcActive and CEF.isTbcActive() then
    return 70
  end
  return 60
end

--- true no cliente Burning Crusade Classic / TBC Anniversary.
function CEF.isTbcActive()
  if tbcActiveCache ~= nil then
    return tbcActiveCache
  end
  if WOW_PROJECT_ID and WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    tbcActiveCache = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
    return tbcActiveCache
  end
  if GetBuildInfo then
    local v = tostring(GetBuildInfo() or "")
    local major = v:match("^(%d+)")
    if major == "2" then
      tbcActiveCache = true
      return true
    end
    if major ~= nil then
      tbcActiveCache = false
      return false
    end
  end
  return false
end

--- true em realm Season of Discovery (C_Seasons pode não estar pronto no load;
--- só cacheia quando a API responde).
function CEF.isSoDActive()
  if sodActiveCache ~= nil then
    return sodActiveCache
  end
  if not (C_Seasons and C_Seasons.GetActiveSeason) then
    return false
  end
  local season = C_Seasons.GetActiveSeason()
  if season == nil then
    return false
  end
  local sodId = (Enum and Enum.SeasonID and Enum.SeasonID.SeasonOfDiscovery) or 2
  sodActiveCache = (season == sodId)
  return sodActiveCache
end

--- Invalida caches de flavor (chamar no PLAYER_LOGIN).
function CEF.invalidateFlavorCaches()
  sodActiveCache = nil
  tbcActiveCache = nil
  INSTANCE_ROWS_MERGED = nil
  INSTANCE_ROWS_MERGED_FLAVOR = nil
  if CEF.invalidateInstanceNameLookup then
    CEF.invalidateInstanceNameLookup()
  end
end

local function flavorKey()
  local parts = { "v" }
  if CEF.isSoDActive() then
    parts[#parts + 1] = "sod"
  end
  if CEF.isTbcActive() then
    parts[#parts + 1] = "tbc"
  end
  return table.concat(parts, ":")
end

local function activeInstanceRows()
  local fk = flavorKey()
  if INSTANCE_ROWS_MERGED and INSTANCE_ROWS_MERGED_FLAVOR == fk then
    return INSTANCE_ROWS_MERGED
  end
  local rows = {}
  for i, row in ipairs(INSTANCE_ROWS) do
    rows[i] = row
  end
  if CEF.isSoDActive() then
    for _, row in ipairs(SOD_INSTANCE_ROWS) do
      rows[#rows + 1] = row
    end
  end
  if CEF.isTbcActive() then
    for _, row in ipairs(TBC_INSTANCE_ROWS) do
      rows[#rows + 1] = row
    end
  end
  INSTANCE_ROWS_MERGED = rows
  INSTANCE_ROWS_MERGED_FLAVOR = fk
  return rows
end

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

local function keyIsRaid(instanceKey)
  if INSTANCE_RAIDS[instanceKey] then
    return true
  end
  if CEF.isSoDActive() and SOD_RAIDS[instanceKey] then
    return true
  end
  if CEF.isTbcActive() and TBC_RAIDS[instanceKey] then
    return true
  end
  return false
end

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
  ["DM East"] = "55-60",
  ["DM West"] = "57-60",
  ["DM North"] = "57-60",
  ["Scholomance"] = "58-60",
  ["Strat Live"] = "58-60",
  ["Strat UD"] = "58-60",
  ["LBRS"] = "55-60",
  ["UBRS"] = "58-60",
  -- Legado (entradas antigas no histórico salvo ainda usam as chaves genéricas).
  ["Dire Maul"] = "56-60",
  ["Stratholme"] = "58-60",
  ["Blackrock Spire"] = "55-60",
  ["Zul'Gurub"] = "60",
  ["Molten Core"] = "60",
  ["Onyxia"] = "60",
  ["Blackwing Lair"] = "60",
  ["Ahn'Qiraj 20"] = "60",
  ["Ahn'Qiraj 40"] = "60",
  ["Naxxramas"] = "60",
  -- Chaves exclusivas SoD (só aparecem com CEF.isSoDActive()).
  ["Demon Fall Canyon"] = "55-60",
  ["Karazhan Crypts"] = "60",
  ["Scarlet Enclave"] = "60",
  -- TBC / Outland (só com CEF.isTbcActive()).
  ["Hellfire Ramparts"] = "58-62",
  ["Blood Furnace"] = "59-63",
  ["Slave Pens"] = "60-64",
  ["Underbog"] = "61-65",
  ["Mana-Tombs"] = "62-66",
  ["Auchenai Crypts"] = "63-67",
  ["Old Hillsbrad"] = "64-68",
  ["Sethekk Halls"] = "65-69",
  ["Shadow Labyrinth"] = "67-70",
  ["Steamvault"] = "67-70",
  ["Shattered Halls"] = "67-70",
  ["Black Morass"] = "68-70",
  ["Magisters' Terrace"] = "68-70",
  ["Mechanar"] = "69-70",
  ["Botanica"] = "70",
  ["Arcatraz"] = "70",
  ["Hellfire Ramparts Heroic"] = "70",
  ["Blood Furnace Heroic"] = "70",
  ["Shattered Halls Heroic"] = "70",
  ["Slave Pens Heroic"] = "70",
  ["Underbog Heroic"] = "70",
  ["Steamvault Heroic"] = "70",
  ["Mana-Tombs Heroic"] = "70",
  ["Auchenai Crypts Heroic"] = "70",
  ["Sethekk Halls Heroic"] = "70",
  ["Shadow Labyrinth Heroic"] = "70",
  ["Old Hillsbrad Heroic"] = "70",
  ["Black Morass Heroic"] = "70",
  ["Magisters' Terrace Heroic"] = "70",
  ["Mechanar Heroic"] = "70",
  ["Botanica Heroic"] = "70",
  ["Arcatraz Heroic"] = "70",
  ["Karazhan"] = "70",
  ["Gruul's Lair"] = "70",
  ["Magtheridon"] = "70",
  ["SSC"] = "70",
  ["Tempest Keep"] = "70",
  ["Hyjal"] = "70",
  ["Black Temple"] = "70",
  ["Zul'Aman"] = "70",
  ["Sunwell Plateau"] = "70",
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
  -- Alas/lados: sem areaId (AreaTable só tem o nome genérico); LFG dá o nome exato.
  ["LBRS"] = { lfgId = 32, lfgPrefer = true },
  ["UBRS"] = { areaId = 1583 },
  ["DM East"] = { lfgId = 34, lfgPrefer = true },
  ["DM West"] = { lfgId = 36, lfgPrefer = true },
  ["DM North"] = { lfgId = 38, lfgPrefer = true },
  ["Scholomance"] = { areaId = 2057, lfgId = 2 },
  ["Strat Live"] = { lfgId = 40, lfgPrefer = true },
  ["Strat UD"] = { lfgId = 274, lfgPrefer = true },
  ["Zul'Gurub"] = { areaId = 1977, lfgId = 42 },
  ["Molten Core"] = { areaId = 2717, lfgId = 48 },
  ["Onyxia"] = { areaId = 2159, lfgId = 46 },
  ["Blackwing Lair"] = { areaId = 2677, lfgId = 50 },
  ["Ahn'Qiraj 20"] = { areaId = 3429, lfgId = 160, lfgPrefer = true },
  ["Ahn'Qiraj 40"] = { areaId = 3428, lfgId = 161, lfgPrefer = true },
  ["Naxxramas"] = { areaId = 3456, lfgId = 159 },
  -- SoD (AreaTable 1.15.x)
  ["Demon Fall Canyon"] = { areaId = 15475 },
  ["Karazhan Crypts"] = { areaId = 16074 },
  ["Scarlet Enclave"] = { areaId = 16236 },
  -- TBC / Outland (AreaTable 2.5.x)
  ["Hellfire Ramparts"] = { areaId = 3562 },
  ["Blood Furnace"] = { areaId = 3713 },
  ["Shattered Halls"] = { areaId = 3714 },
  ["Slave Pens"] = { areaId = 3717 },
  ["Underbog"] = { areaId = 3716 },
  ["Steamvault"] = { areaId = 3715 },
  ["Mana-Tombs"] = { areaId = 3792 },
  ["Auchenai Crypts"] = { areaId = 3790 },
  ["Sethekk Halls"] = { areaId = 3791 },
  ["Shadow Labyrinth"] = { areaId = 3789 },
  ["Old Hillsbrad"] = { areaId = 2367 },
  ["Black Morass"] = { areaId = 2366 },
  ["Magisters' Terrace"] = { areaId = 4131 },
  ["Mechanar"] = { areaId = 3849 },
  ["Botanica"] = { areaId = 3847 },
  ["Arcatraz"] = { areaId = 3848 },
  ["Hellfire Ramparts Heroic"] = { areaId = 3562 },
  ["Blood Furnace Heroic"] = { areaId = 3713 },
  ["Shattered Halls Heroic"] = { areaId = 3714 },
  ["Slave Pens Heroic"] = { areaId = 3717 },
  ["Underbog Heroic"] = { areaId = 3716 },
  ["Steamvault Heroic"] = { areaId = 3715 },
  ["Mana-Tombs Heroic"] = { areaId = 3792 },
  ["Auchenai Crypts Heroic"] = { areaId = 3790 },
  ["Sethekk Halls Heroic"] = { areaId = 3791 },
  ["Shadow Labyrinth Heroic"] = { areaId = 3789 },
  ["Old Hillsbrad Heroic"] = { areaId = 2367 },
  ["Black Morass Heroic"] = { areaId = 2366 },
  ["Magisters' Terrace Heroic"] = { areaId = 4131 },
  ["Mechanar Heroic"] = { areaId = 3849 },
  ["Botanica Heroic"] = { areaId = 3847 },
  ["Arcatraz Heroic"] = { areaId = 3848 },
  ["Karazhan"] = { areaId = 2562 },
  ["Gruul's Lair"] = { areaId = 3618 },
  ["Magtheridon"] = { areaId = 3836 },
  ["SSC"] = { areaId = 3607 },
  ["Tempest Keep"] = { areaId = 3845 },
  ["Hyjal"] = { areaId = 3606 },
  ["Black Temple"] = { areaId = 3959 },
  ["Zul'Aman"] = { areaId = 3805 },
  ["Sunwell Plateau"] = { areaId = 4075 },
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

  -- Fallback: AreaTable localizada (ZoneNames) — cobre chaves sem pack próprio (ex.: SoD).
  if not name then
    local meta = INSTANCE_BLIZZARD_IDS[instanceKey]
    if meta and meta.areaId and type(CEF.AREA_DISPLAY_NAMES) == "table" then
      local areaPack = CEF.AREA_DISPLAY_NAMES[localeCode] or CEF.AREA_DISPLAY_NAMES.enUS
      local n = areaPack and areaPack[meta.areaId]
      if type(n) == "string" and n ~= "" then
        name = n
      end
    end
  end

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
  if CEF.invalidateInstanceNameLookup then
    CEF.invalidateInstanceNameLookup()
  end
end

-- Lookup O(1) nome → key: só locale ativo do addon + locale do cliente + enUS.
-- (Não indexa os 11 packs — desnecessário e mais lento.)
local instanceNameLookup = nil
local instanceNameLookupLocale = nil
local instanceNameResolveMemo = {}

function CEF.invalidateInstanceNameLookup()
  instanceNameLookup = nil
  instanceNameLookupLocale = nil
  wipe(instanceNameResolveMemo)
end

local function activeLocaleForLookup()
  if CEF.Locale and CEF.Locale.getActiveCode then
    local code = CEF.Locale.getActiveCode()
    if type(code) == "string" and code ~= "" then
      return code
    end
  end
  return (GetLocale and GetLocale()) or "enUS"
end

local function addPackToLookup(lookup, pack)
  if type(pack) ~= "table" then
    return
  end
  for key, localized in pairs(pack) do
    lookup[strlower(tostring(key))] = key
    if type(localized) == "string" and localized ~= "" then
      lookup[strlower(localized)] = key
    end
  end
end

local function ensureInstanceNameLookup()
  local active = activeLocaleForLookup()
  local client = (GetLocale and GetLocale()) or active
  local stamp = active .. "\0" .. client
  if instanceNameLookup and instanceNameLookupLocale == stamp then
    return instanceNameLookup
  end

  local lookup = {}
  for key in pairs(INSTANCE_LEVEL_RANGE) do
    lookup[strlower(tostring(key))] = key
  end
  for _, row in ipairs(activeInstanceRows()) do
    if row.key then
      lookup[strlower(row.key)] = row.key
    end
  end

  local packs = CEF.INSTANCE_DISPLAY_NAMES
  if type(packs) == "table" then
    -- Sempre enUS (chaves/aliases EN + nomes Blizzard em inglês).
    addPackToLookup(lookup, packs.enUS)
    -- Locale do addon (UI / Termos).
    if active ~= "enUS" then
      addPackToLookup(lookup, packs[active])
    end
    -- Locale do cliente (nomes vindos de C_LFGList / GetLFGDungeonInfo).
    if client ~= "enUS" and client ~= active then
      addPackToLookup(lookup, packs[client])
    end
  end

  instanceNameLookup = lookup
  instanceNameLookupLocale = stamp
  wipe(instanceNameResolveMemo)
  return lookup
end

local function looksHeroicActivityName(lower)
  return lower:find("heroic", 1, true)
    or lower:find("(h)", 1, true)
    or lower:find("heroico", 1, true)
    or lower:find("heroica", 1, true)
    or lower:find("héroïque", 1, true)
    or lower:find("heroisch", 1, true)
    or lower:find("eroica", 1, true)
    or lower:find("героик", 1, true)
    or lower:find("영웅", 1, true)
    or lower:find("英雄", 1, true)
end

local function stripHeroicMarkers(lower)
  return (lower
    :gsub("%(%s*heroic%s*%)", " ")
    :gsub("%(%s*heroico%s*%)", " ")
    :gsub("%(%s*heroica%s*%)", " ")
    :gsub("%(%s*héroïque%s*%)", " ")
    :gsub("%(%s*heroisch%s*%)", " ")
    :gsub("%(%s*eroica%s*%)", " ")
    :gsub("%(%s*h%s*%)", " ")
    :gsub("heroic[:%s%-]*", " ")
    :gsub("heroico", " ")
    :gsub("heroica", " ")
    :gsub("héroïque", " ")
    :gsub("heroisch", " ")
    :gsub("eroica", " ")
    :gsub("%s+", " ")
    :match("^%s*(.-)%s*$")) or lower
end

--- Resolve chave EN a partir do nome Blizzard/UI (rápido + memoizado).
function CEF.resolveInstanceKeyFromName(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  local lower = strlower(name)
  local memo = instanceNameResolveMemo[lower]
  if memo ~= nil then
    if memo == false then
      return nil
    end
    return memo
  end

  local lookup = ensureInstanceNameLookup()
  local key = lookup[lower]
  if key then
    instanceNameResolveMemo[lower] = key
    return key
  end

  local heroic = looksHeroicActivityName(lower)
  if heroic then
    local stripped = stripHeroicMarkers(lower)
    if stripped and stripped ~= "" and stripped ~= lower then
      local base = lookup[stripped]
      if base then
        local hKey = CEF.tbcHeroicKeyFor and CEF.tbcHeroicKeyFor(base)
        key = hKey or base
        instanceNameResolveMemo[lower] = key
        return key
      end
      -- Prefixo Blizzard "Bastilha da Tormenta - Arcatraz (Heroico)" → tenta só o sufixo.
      local tail = stripped:match("[-–:]%s*(.+)$")
      if tail and #tail >= 4 then
        base = lookup[tail]
        if not base then
          for cand, mapped in pairs(lookup) do
            if #cand >= 4 and (tail:find(cand, 1, true) or cand:find(tail, 1, true)) then
              if not CEF.instanceKeyIsRaid or not CEF.instanceKeyIsRaid(mapped) then
                base = mapped
                break
              end
            end
          end
        end
        if base then
          local hKey = CEF.tbcHeroicKeyFor and CEF.tbcHeroicKeyFor(base)
          key = hKey or base
          instanceNameResolveMemo[lower] = key
          return key
        end
      end
    end
  end

  -- Parcial limitado (maior substring), só se exacto falhar.
  local bestKey, bestLen = nil, 0
  local nameLen = #lower
  local minLen = math.max(8, math.floor(nameLen * 0.7))
  for cand, mapped in pairs(lookup) do
    local cl = #cand
    if cl >= minLen and cl > bestLen and lower:find(cand, 1, true) then
      bestKey = mapped
      bestLen = cl
    end
  end
  if bestKey and heroic and CEF.tbcHeroicKeyFor then
    bestKey = CEF.tbcHeroicKeyFor(bestKey) or bestKey
  end
  instanceNameResolveMemo[lower] = bestKey or false
  return bestKey
end

-- Chave especial do filtro: só instâncias cujo range recomendado inclui o nível do jogador.
CEF.FILTER_INSTANCE_MY_LEVEL = "__cef_my_level__"

local function instanceLevelRangeBounds(instanceKey)
  local plain
  if CEF.isSoDActive() then
    plain = SOD_LEVEL_RANGE[instanceKey]
  end
  plain = plain or INSTANCE_LEVEL_RANGE[instanceKey]
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
  for _, row in ipairs(activeInstanceRows()) do
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
-- Reconstruído no PLAYER_LOGIN: em SoD entram as instâncias exclusivas;
-- no TBC, Classic e Outland ficam em secções separadas (masmorras + raids).
CEF.INSTANCE_FILTER_MENU_OPTS = {}

local function sortInstanceKeysByLevel(list)
  table.sort(list, function(a, b)
    local ka, kb = instanceMinLevelForSort(a), instanceMinLevelForSort(b)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a) < strlower(b)
  end)
end

local function appendFilterSection(opts, textKey, keys)
  if not keys or #keys == 0 then
    return
  end
  opts[#opts + 1] = { kind = "hdr", textKey = textKey }
  for _, k in ipairs(keys) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end
end

function CEF.rebuildInstanceFilterMenuOpts()
  local classicD, classicR, tbcD, tbcH, tbcR = {}, {}, {}, {}, {}
  local seen = {}
  local splitTbc = CEF.isTbcActive()
  for _, row in ipairs(activeInstanceRows()) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      local isTbc = splitTbc and TBC_INSTANCE_KEYS[k]
      local isRaid = keyIsRaid(k)
      if isTbc then
        if isRaid then
          tbcR[#tbcR + 1] = k
        elseif TBC_HEROIC_KEYS[k] then
          tbcH[#tbcH + 1] = k
        else
          tbcD[#tbcD + 1] = k
        end
      else
        if isRaid then
          classicR[#classicR + 1] = k
        else
          classicD[#classicD + 1] = k
        end
      end
    end
  end

  sortInstanceKeysByLevel(classicD)
  sortInstanceKeysByLevel(classicR)
  sortInstanceKeysByLevel(tbcD)
  sortInstanceKeysByLevel(tbcH)
  sortInstanceKeysByLevel(tbcR)

  local opts = CEF.INSTANCE_FILTER_MENU_OPTS
  wipe(opts)
  opts[#opts + 1] = { kind = "opt", key = false }
  opts[#opts + 1] = { kind = "opt", key = CEF.FILTER_INSTANCE_MY_LEVEL }
  if splitTbc then
    appendFilterSection(opts, "CATEGORY_CLASSIC_DUNGEONS", classicD)
    appendFilterSection(opts, "CATEGORY_CLASSIC_RAIDS", classicR)
    appendFilterSection(opts, "CATEGORY_TBC_DUNGEONS", tbcD)
    appendFilterSection(opts, "CATEGORY_TBC_HEROIC_DUNGEONS", tbcH)
    appendFilterSection(opts, "CATEGORY_TBC_RAIDS", tbcR)
  else
    appendFilterSection(opts, "CATEGORY_DUNGEONS", classicD)
    appendFilterSection(opts, "CATEGORY_RAIDS", classicR)
  end
end

CEF.rebuildInstanceFilterMenuOpts()

-- Laranja = nível mínimo do range, verde = nível máximo (|c … |r como no chat).
local COLOR_LVL_ORANGE_MIN = "|cffff9933"
local COLOR_LVL_GREEN_MAX = "|cff33cc33"

-- Nome da instância: masmorra (azul-claro), heroica TBC (violeta), raid (âmbar).
local COLOR_INSTANCE_DUNGEON_NAME = "|cff9fd3ff"
local COLOR_INSTANCE_HEROIC_NAME = "|cffe59cff"
local COLOR_INSTANCE_RAID_NAME = "|cffffb74d"

local function instanceNameRichOpenTag(instanceKey)
  if instanceKey and keyIsRaid(instanceKey) then
    return COLOR_INSTANCE_RAID_NAME
  end
  if instanceKey and TBC_HEROIC_KEYS[instanceKey] then
    return COLOR_INSTANCE_HEROIC_NAME
  end
  return COLOR_INSTANCE_DUNGEON_NAME
end

function CEF.instanceKeyIsRaid(instanceKey)
  return instanceKey ~= nil and instanceKey ~= false and keyIsRaid(instanceKey)
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
  local plain
  if CEF.isSoDActive() then
    plain = SOD_LEVEL_RANGE[instanceKey]
  end
  plain = plain or INSTANCE_LEVEL_RANGE[instanceKey]
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

--- Nome + níveis no estilo da coluna Chat (azul/âmbar + laranja/verde).
--- instanceKey opcional: se existir, usa o range recomendado da tabela do addon.
function CEF.activityNameLevelsRichText(displayName, minV, maxV, instanceKey)
  displayName = tostring(displayName or "")
  if displayName == "" then
    return "—"
  end
  local namePart = instanceNameRichOpenTag(instanceKey) .. displayName .. "|r"
  local levels
  if instanceKey then
    levels = recommendedLevelRichText(instanceKey)
  end
  if (not levels or levels == "—") and minV then
    levels = CEF.formatLevelBoundsRichText(minV, maxV)
  end
  if levels and levels ~= "—" then
    return namePart .. "  " .. levels
  end
  return namePart
end

--- Resolve min/max recomendados a partir do nome localizado da atividade LFG.
function CEF.levelBoundsForDisplayName(activityName)
  if type(activityName) ~= "string" or activityName == "" then
    return nil, nil
  end
  local key = CEF.resolveInstanceKeyFromName and CEF.resolveInstanceKeyFromName(activityName)
  if not key then
    return nil, nil
  end
  return instanceLevelRangeBounds(key)
end

-- Linhas de deteção agrupadas (mesma ordem que o menu de filtro).
function CEF.getInstanceDetectionRowsGroupedSorted()
  local classicD, classicR, tbcD, tbcH, tbcR = {}, {}, {}, {}, {}
  local seen = {}
  local splitTbc = CEF.isTbcActive()
  for _, row in ipairs(activeInstanceRows()) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      local isTbc = splitTbc and TBC_INSTANCE_KEYS[k]
      local isRaid = keyIsRaid(k)
      if isTbc then
        if isRaid then
          tbcR[#tbcR + 1] = row
        elseif TBC_HEROIC_KEYS[k] then
          tbcH[#tbcH + 1] = row
        else
          tbcD[#tbcD + 1] = row
        end
      else
        if isRaid then
          classicR[#classicR + 1] = row
        else
          classicD[#classicD + 1] = row
        end
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
  table.sort(classicD, sortFn)
  table.sort(classicR, sortFn)
  table.sort(tbcD, sortFn)
  table.sort(tbcH, sortFn)
  table.sort(tbcR, sortFn)
  return {
    splitTbc = splitTbc,
    dungeons = classicD,
    raids = classicR,
    classicDungeons = classicD,
    classicRaids = classicR,
    tbcDungeons = tbcD,
    tbcHeroicDungeons = tbcH,
    tbcRaids = tbcR,
  }
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

-- Masmorras com alas/lados: menção genérica (sem ala) → expande para todas as alas,
-- igual à regra do Monastério Escarlate. Ex.: «LF2M strat» → Strat Live + Strat UD.
local GENERIC_WING_GROUPS = {
  {
    keys = { "Strat Live", "Strat UD" },
    needles = { "stratholme", "strat ", " strat", "strat(", "strat)", "strat,", "strat.", "strat-" },
  },
  {
    keys = { "DM East", "DM West", "DM North" },
    needles = { "dire maul", " dm ", "-> dm", "> dm ", "^dm ", " dm,", " dm.", " dm/", "/dm " },
    useIsolatedDm = true,
  },
  {
    keys = { "LBRS", "UBRS" },
    needles = { "blackrock spire", " brs", "brs " },
  },
}

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
  for _, row in ipairs(activeInstanceRows()) do
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

  -- Alas: menção genérica sem ala específica → todas as alas na posição do match.
  for _, grp in ipairs(GENERIC_WING_GROUPS) do
    local hasWing = false
    for _, k in ipairs(grp.keys) do
      if hits[k] then
        hasWing = true
        break
      end
    end
    if not hasWing then
      local bestPos
      for _, n in ipairs(grp.needles) do
        local pos = lower:find(n, 1, true)
        if pos and (not bestPos or pos < bestPos) then
          bestPos = pos
        end
      end
      if not bestPos and grp.useIsolatedDm then
        bestPos = direMaulIsolatedDmPos(lower)
      end
      if bestPos then
        for _, k in ipairs(grp.keys) do
          hits[k] = bestPos
        end
      end
    end
  end

  if not hits["Wailing Caverns"] then
    local pWc = wailingCavernsIsolatedWcPos(lower)
    if pWc then
      hits["Wailing Caverns"] = pWc
    end
  end

  -- Heroica TBC ganha da Normal: "hc ramps" não deve listar também Ramparts normal.
  for hKey, baseKey in pairs(TBC_HEROIC_BASE) do
    if hits[hKey] and hits[baseKey] then
      hits[baseKey] = nil
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
    local fallback = e.instance or ""
    return strlower(fallback)
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = strlower(k)
    local display = CEF.getInstanceDisplayName and CEF.getInstanceDisplayName(k)
    if type(display) == "string" and display ~= "" and display ~= k then
      parts[#parts + 1] = strlower(display)
    end
  end
  return table.concat(parts, " ")
end

--- Texto pesquisável de uma instância (chave EN + nome no locale do addon).
function CEF.instanceSearchHay(instanceKey)
  if type(instanceKey) ~= "string" or instanceKey == "" then
    return ""
  end
  local parts = { strlower(instanceKey) }
  local display = CEF.getInstanceDisplayName and CEF.getInstanceDisplayName(instanceKey)
  if type(display) == "string" and display ~= "" then
    -- Remove códigos de cor caso o nome venha “rico”.
    display = display:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    parts[#parts + 1] = strlower(display)
  end
  return table.concat(parts, " ")
end

-- Leitura para a UI “Termos” (somente referência; listas são as mesmas usadas na deteção).
function CEF.getInstanceDetectionCatalog()
  return {
    rows = activeInstanceRows(),
    scarletGeneric = SCARLET_GENERIC_NEEDLES,
    scarletGenericUiHints = {
      CEF.L.TERMS_SM_AUTO_HINT,
    },
  }
end

