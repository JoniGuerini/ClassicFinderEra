-- Módulo: dados estáticos das instâncias (apenas tabelas, sem lógica).
--
-- Cada linha em INSTANCE_ROWS tem:
--   key        (string, identidade interna — NUNCA traduzida)
--   kind       ("dungeon" ou "raid")
--   expansion  ("classic" ou "tbc")
--   needles    ({ "substr1", "substr2", ... } — match case-insensitive no texto normalizado)
--
-- Qualquer consumidor (detection, filter menu, Termos) deve ler DESTE módulo.
-- Lógica de detecção, formatação e UI vive em ClassicEraFinder.Instances.lua.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.InstanceData = CEF.InstanceData or {}
local D = CEF.InstanceData

-- ============================================================================
-- INSTANCE_ROWS — fonte única de verdade para detecção + filtros.
-- ============================================================================
D.INSTANCE_ROWS = {
  -- Classic — raids
  { key = "Naxxramas",      kind = "raid", expansion = "classic", needles = { "naxxramas", "naxx ", " naxx", "naxx." } },
  { key = "Ahn'Qiraj 40",   kind = "raid", expansion = "classic", needles = { "aq40", "aq 40", "ahn'qiraj", "ahn qiraj", " temple of ahn", "cthun", "ouro", "viscidus", "huhuran", "fankriss" } },
  { key = "Ahn'Qiraj 20",   kind = "raid", expansion = "classic", needles = { "aq20", "aq 20", "ruins of ahn", "ossirian", "moam", "rajaxx" } },
  { key = "Zul'Gurub",      kind = "raid", expansion = "classic", needles = { " zg ", " zg.", "zg run", "zul'gurub", "zul gurub", "hakkar", "jindo" } },
  { key = "Molten Core",    kind = "raid", expansion = "classic", needles = { "molten core", "ragnaros", "geddon", "golemagg", "magmadar", "lucifron", " mc ", " mc,", "full mc", "molten", "m mc", " gdkp mc", "mc gdkp" } },
  { key = "Blackwing Lair", kind = "raid", expansion = "classic", needles = { "blackwing", "bwl ", " bwl", "nefarian", "razorgore", "vael" } },
  { key = "Onyxia",         kind = "raid", expansion = "classic", needles = { "onyxia", " ony ", " ony.", "ony run" } },

  -- Classic — dungeons
  {
    key = "Stratholme", kind = "dungeon", expansion = "classic",
    needles = {
      "stratholme", "strat ", " strat", "strat(", "strat)", "strat,", "strat.",
      "strat-", "strat live", "strat ud", "rivendare", "baron run",
    },
  },
  { key = "Scholomance", kind = "dungeon", expansion = "classic", needles = { "scholomance", "scholo", "gandling", "darkmaster" } },
  {
    key = "Dire Maul", kind = "dungeon", expansion = "classic",
    needles = {
      "dire maul", " dm ", "-> dm", "> dm ", "^dm ", " dm,", " dm.", " dm/", "/dm ",
      "dm north", "dm east", "dm west", "dm tribute", "immol'thar", "alzzin",
    },
  },
  { key = "Lower Blackrock Spire", kind = "dungeon", expansion = "classic", needles = { "lbrs", "lower blackrock", "lower spire", "lower brs", "war master voone", "voone", "wyrmthalak" } },
  { key = "Upper Blackrock Spire", kind = "dungeon", expansion = "classic", needles = { "ubrs", "upper blackrock", "upper spire", "upper brs", "drakkisath", "rend ", "gyth", "jed runewatcher" } },
  { key = "Blackrock Depths", kind = "dungeon", expansion = "classic", needles = { "blackrock depths", "brd ", " brd", "angerforge", "emperor ", "lokhtos", "arena run" } },
  { key = "Sunken Temple", kind = "dungeon", expansion = "classic", needles = { "sunken temple", "atal'hakkar", "atal hakkar", " jammalan", "eranikus" } },
  { key = "Maraudon", kind = "dungeon", expansion = "classic", needles = { "maraudon", " mara ", "mara run", "princess ", "rotgrip", "landslide" } },
  { key = "Zul'Farrak", kind = "dungeon", expansion = "classic", needles = { "zul'farrak", "zul farrak", "zf ", " zf", "sandfury", "chief sandscalp" } },
  { key = "Uldaman", kind = "dungeon", expansion = "classic", needles = { "uldaman", "ulda ", "/ulda", "ulda/", "archaedas", "ironaya" } },
  -- Scarlet Monastery no Classic = 4 instâncias separadas (alas).
  { key = "SM Graveyard", kind = "dungeon", expansion = "classic", needles = { "sm gy", "sm graveyard", "sm grave" } },
  { key = "SM Library",   kind = "dungeon", expansion = "classic", needles = { "sm lib", "sm librar", "sm library" } },
  { key = "SM Armory",    kind = "dungeon", expansion = "classic", needles = { "sm arm", "sm armory", "sm arms" } },
  { key = "SM Cathedral", kind = "dungeon", expansion = "classic", needles = { "sm cath", "sm cathedral" } },
  { key = "Razorfen Downs", kind = "dungeon", expansion = "classic", needles = { "razorfen downs", "rfd/", " rfd/", "/rfd", "rfd ", " rfd", "amnennar" } },
  { key = "Razorfen Kraul", kind = "dungeon", expansion = "classic", needles = { "razorfen kraul", "rfk ", " rfk", "charlga" } },
  { key = "Gnomeregan", kind = "dungeon", expansion = "classic", needles = { "gnomeregan", "gnomer", "thermaplugg", "pummeler" } },
  { key = "The Stockade", kind = "dungeon", expansion = "classic", needles = { "stockade", "stocks", "stocks,", "stocks.", "stocks:", "stocks;", "stocks)", "stocks(", "stocks ", " the stocks" } },
  { key = "Blackfathom Deeps", kind = "dungeon", expansion = "classic", needles = { "blackfathom", "bfd ", " bfd", "akumai" } },
  { key = "Shadowfang Keep", kind = "dungeon", expansion = "classic", needles = { "shadowfang", "sfk ", " sfk", "arugal" } },
  { key = "Deadmines", kind = "dungeon", expansion = "classic", needles = { "deadmines", "dead mines", "van cleef", "defias", "vc ", " vc" } },
  {
    key = "Wailing Caverns", kind = "dungeon", expansion = "classic",
    needles = {
      "wailing caverns", "for wc ", " wc ", " wc,", " wc.", " wc/", "/wc ", "^wc ",
      "wc run", " mutanus", "cobrahn",
    },
  },
  { key = "Ragefire Chasm", kind = "dungeon", expansion = "classic", needles = { "ragefire", "rfc ", " rfc", "bazzalan" } },

  -- TBC — dungeons
  {
    key = "Hellfire Ramparts", kind = "dungeon", expansion = "tbc",
    needles = { "hellfire ramparts", " hellfire ramp", "ramparts", " bastilhas", "bastilhas", "muralha fogo do inferno", "infernal " },
  },
  {
    key = "The Blood Furnace", kind = "dungeon", expansion = "tbc",
    needles = { "blood furnace", "the blood furnace", "fornalha", "fornalha de sangue", " bf ", " bf,", " bf.", "/bf ", "furnace" },
  },
  {
    key = "The Slave Pens", kind = "dungeon", expansion = "tbc",
    needles = { "slave pens", "the slave pens", "slave pen", "catacumbas dos verminagos", " sp ", " sp,", " sp." },
  },
  {
    key = "The Underbog", kind = "dungeon", expansion = "tbc",
    needles = { "underbog", "the underbog", "under bog", " ub ", " ub," },
  },
  {
    key = "The Steamvault", kind = "dungeon", expansion = "tbc",
    needles = { "steamvault", "steam vault", "the steamvault", "câmara dos vapores", "câmara vapor", " sv ", " sv," },
  },
  {
    key = "Mana-Tombs", kind = "dungeon", expansion = "tbc",
    needles = { "mana-tombs", "mana tombs", "the mana tombs", "tumbas de mana", "tombs of mana" },
  },
  {
    key = "Auchenai Crypts", kind = "dungeon", expansion = "tbc",
    needles = { "auchenai crypts", "the auchenai crypts", "auchenai", "criptas auchenai", " crypts " },
  },
  {
    key = "Sethekk Halls", kind = "dungeon", expansion = "tbc",
    needles = { "sethekk halls", "the sethekk halls", "sethekk", "salões sethekk", "saloes sethekk" },
  },
  {
    key = "Shadow Labyrinth", kind = "dungeon", expansion = "tbc",
    needles = { "shadow labyrinth", "the shadow labyrinth", "shadow labs", "shadow lab", "slabs", " labirinto ", "labirinto das sombras" },
  },
  {
    key = "Old Hillsbrad Foothills", kind = "dungeon", expansion = "tbc",
    needles = { "old hillsbrad", "hillsbrad foothills", "durnholde", "escape de durnholde", "ohfb", " ohfb ", "cot hillsbrad", "opening hillsbrad" },
  },
  {
    key = "The Black Morass", kind = "dungeon", expansion = "tbc",
    needles = { "black morass", "the black morass", "dark portal", "opening the dark portal", "morass", "pântano negro", "pantano negro", "cot2", "bm morass" },
  },
  {
    key = "The Mechanar", kind = "dungeon", expansion = "tbc",
    needles = { "mechanar", "the mechanar", "mecanar", " mech ", " mech," },
  },
  {
    key = "The Botanica", kind = "dungeon", expansion = "tbc",
    needles = { "botanica", "the botanica", "botânica", " bota ", " bota," },
  },
  {
    key = "The Arcatraz", kind = "dungeon", expansion = "tbc",
    needles = { "arcatraz", "the arcatraz", " arcatraz ", " arcatraz," },
  },
  {
    key = "Magisters' Terrace", kind = "dungeon", expansion = "tbc",
    needles = { "magisters' terrace", "magisters terrace", "the magisters", "terraço dos magísteres", "terraco dos magisteres", " mgt ", " mgt,", " mgt." },
  },
  {
    key = "The Shattered Halls", kind = "dungeon", expansion = "tbc",
    needles = { "shattered halls", "the shattered halls", "shattered hall", "salões estilhaçados", "saloes estilhacados", " shh ", " shh," },
  },

  -- TBC — raids
  {
    key = "Karazhan", kind = "raid", expansion = "tbc",
    needles = { "karazhan", "kara ", " kara", " kara,", " kara.", "lfg kara" },
  },
  {
    key = "Gruul's Lair", kind = "raid", expansion = "tbc",
    needles = { "gruul's lair", "gruuls lair", "gruul's", "covil de gruul", "gruul ", " gruul" },
  },
  {
    key = "Magtheridon's Lair", kind = "raid", expansion = "tbc",
    needles = { "magtheridon's lair", "magtheridon", "magtheridon's", "covil de magtheridon", " magther" },
  },
  {
    key = "Serpentshrine Cavern", kind = "raid", expansion = "tbc",
    needles = { "serpentshrine", "serpentshrine cavern", "ssc ", " ssc", "caverna serpentarium" },
  },
  {
    key = "Tempest Keep", kind = "raid", expansion = "tbc",
    needles = { "tempest keep", "the eye", "tk eye", "tk ", " tk", "fortaleza da tempestade", " tempestade" },
  },
  {
    key = "Battle for Mount Hyjal", kind = "raid", expansion = "tbc",
    needles = { "mount hyjal", "battle for mount hyjal", "hyjal summit", "monte hyjal", "hyjal ", " hyjal", "mh hyjal" },
  },
  {
    key = "Black Temple", kind = "raid", expansion = "tbc",
    needles = { "black temple", "templo negro", " bt ", " bt,", " bt.", "/bt ", "illidan" },
  },
  {
    key = "Zul'Aman", kind = "raid", expansion = "tbc",
    needles = { "zul'aman", "zul aman", "zulaman", " zul'aman", " za ", " za,", " za." },
  },
  {
    key = "Sunwell Plateau", kind = "raid", expansion = "tbc",
    needles = { "sunwell plateau", "sunwell", "platô do poço", "plato do poco", "swp ", " swp", "kil'jaeden" },
  },
}

-- ============================================================================
-- INSTANCE_LEVEL_RANGE — faixa recomendada (exibição na UI)
-- ============================================================================
D.INSTANCE_LEVEL_RANGE = {
  -- Classic dungeons
  ["Ragefire Chasm"]    = "13-18",
  ["Wailing Caverns"]   = "17-24",
  ["Deadmines"]         = "17-26",
  ["Shadowfang Keep"]   = "22-30",
  ["Blackfathom Deeps"] = "24-32",
  ["The Stockade"]      = "24-32",
  ["Gnomeregan"]        = "29-38",
  ["Razorfen Kraul"]    = "30-40",
  ["SM Graveyard"]      = "34-45",
  ["SM Library"]        = "34-45",
  ["SM Armory"]         = "34-45",
  ["SM Cathedral"]      = "34-45",
  ["Razorfen Downs"]    = "35-45",
  ["Uldaman"]           = "41-51",
  ["Zul'Farrak"]        = "44-54",
  ["Maraudon"]          = "46-55",
  ["Sunken Temple"]     = "50-60",
  ["Blackrock Depths"]  = "52-60",
  ["Dire Maul"]         = "56-60",
  ["Scholomance"]       = "58-60",
  ["Stratholme"]        = "58-60",
  ["Lower Blackrock Spire"] = "55-60",
  ["Upper Blackrock Spire"] = "57-60",

  -- Classic raids
  ["Zul'Gurub"]      = "60",
  ["Molten Core"]    = "60",
  ["Onyxia"]         = "60",
  ["Blackwing Lair"] = "60",
  ["Ahn'Qiraj 20"]   = "60",
  ["Ahn'Qiraj 40"]   = "60",
  ["Naxxramas"]      = "60",

  -- TBC dungeons
  ["Hellfire Ramparts"]       = "59-62",
  ["The Blood Furnace"]       = "61-63",
  ["The Slave Pens"]          = "62-64",
  ["The Underbog"]            = "63-65",
  ["Mana-Tombs"]              = "64-66",
  ["Auchenai Crypts"]         = "65-67",
  ["Sethekk Halls"]           = "67-69",
  ["Old Hillsbrad Foothills"] = "66-68",
  ["The Black Morass"]        = "68-70",
  ["Shadow Labyrinth"]        = "69-70",
  ["The Shattered Halls"]     = "69-70",
  ["The Steamvault"]          = "69-70",
  ["The Mechanar"]            = "69-70",
  ["The Botanica"]            = "69-70",
  ["The Arcatraz"]            = "70",
  ["Magisters' Terrace"]      = "70",

  -- TBC raids
  ["Karazhan"]               = "70",
  ["Gruul's Lair"]            = "70",
  ["Magtheridon's Lair"]      = "70",
  ["Serpentshrine Cavern"]    = "70",
  ["Tempest Keep"]            = "70",
  ["Battle for Mount Hyjal"]  = "70",
  ["Black Temple"]            = "70",
  ["Zul'Aman"]                = "70",
  ["Sunwell Plateau"]         = "70",
}

-- ============================================================================
-- Scarlet Monastery — regras especiais para frase genérica
-- (quando a linha fala «SM» sem nomear ala, trata como full clear das 4 alas)
-- ============================================================================
D.SCARLET_WING_KEYS = { "SM Graveyard", "SM Library", "SM Armory", "SM Cathedral" }

D.SCARLET_GENERIC_NEEDLES = {
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
