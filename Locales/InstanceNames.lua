-- Nome localizado das instâncias (display-only).
--
-- A `key` de cada instância (ex.: "Molten Core") continua sendo a identidade
-- interna usada para matching, filtros, SavedVariables e cores de raid.
-- Este arquivo só mapeia a `key` → nome exibido em cada idioma.
--
-- Como adicionar/editar:
--   - Preencha a tabela do idioma com ["<key>"] = "<nome traduzido>".
--   - A `key` tem que bater exatamente com a usada em INSTANCE_ROWS
--     (ClassicEraFinder.Instances.lua).
--   - Entradas ausentes caem no fallback: mostra a própria key (inglês).
--
-- Para adicionar um novo idioma (ex.: esES), crie uma sub-tabela
-- LOCALIZED_INSTANCE_NAMES.esES = { ... } com o mesmo formato.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

local LOCALIZED_INSTANCE_NAMES = {

  -- ==========================================================================
  -- English (enUS) — nomes oficiais da Blizzard.
  -- ==========================================================================
  enUS = {
    -- Classic — raids
    ["Naxxramas"]      = "Naxxramas",
    ["Ahn'Qiraj 40"]   = "Temple of Ahn'Qiraj",
    ["Ahn'Qiraj 20"]   = "Ruins of Ahn'Qiraj",
    ["Zul'Gurub"]      = "Zul'Gurub",
    ["Molten Core"]    = "Molten Core",
    ["Blackwing Lair"] = "Blackwing Lair",
    ["Onyxia"]         = "Onyxia's Lair",

    -- Classic — dungeons
    ["Stratholme"]        = "Stratholme",
    ["Scholomance"]       = "Scholomance",
    ["Dire Maul"]         = "Dire Maul",
    ["Lower Blackrock Spire"] = "Lower Blackrock Spire",
    ["Upper Blackrock Spire"] = "Upper Blackrock Spire",
    ["Blackrock Depths"]  = "Blackrock Depths",
    ["Sunken Temple"]     = "Temple of Atal'Hakkar",
    ["Maraudon"]          = "Maraudon",
    ["Zul'Farrak"]        = "Zul'Farrak",
    ["Uldaman"]           = "Uldaman",
    ["SM Graveyard"]      = "Scarlet Monastery: Graveyard",
    ["SM Library"]        = "Scarlet Monastery: Library",
    ["SM Armory"]         = "Scarlet Monastery: Armory",
    ["SM Cathedral"]      = "Scarlet Monastery: Cathedral",
    ["Razorfen Downs"]    = "Razorfen Downs",
    ["Razorfen Kraul"]    = "Razorfen Kraul",
    ["Gnomeregan"]        = "Gnomeregan",
    ["The Stockade"]      = "The Stockade",
    ["Blackfathom Deeps"] = "Blackfathom Deeps",
    ["Shadowfang Keep"]   = "Shadowfang Keep",
    ["Deadmines"]         = "The Deadmines",
    ["Wailing Caverns"]   = "Wailing Caverns",
    ["Ragefire Chasm"]    = "Ragefire Chasm",

    -- TBC — dungeons
    ["Hellfire Ramparts"]       = "Hellfire Ramparts",
    ["The Blood Furnace"]       = "The Blood Furnace",
    ["The Slave Pens"]          = "The Slave Pens",
    ["The Underbog"]            = "The Underbog",
    ["The Steamvault"]          = "The Steamvault",
    ["Mana-Tombs"]              = "Mana-Tombs",
    ["Auchenai Crypts"]         = "Auchenai Crypts",
    ["Sethekk Halls"]           = "Sethekk Halls",
    ["Shadow Labyrinth"]        = "Shadow Labyrinth",
    ["Old Hillsbrad Foothills"] = "Old Hillsbrad Foothills",
    ["The Black Morass"]        = "The Black Morass",
    ["The Mechanar"]            = "The Mechanar",
    ["The Botanica"]            = "The Botanica",
    ["The Arcatraz"]            = "The Arcatraz",
    ["Magisters' Terrace"]      = "Magisters' Terrace",
    ["The Shattered Halls"]     = "The Shattered Halls",

    -- TBC — raids
    ["Karazhan"]               = "Karazhan",
    ["Gruul's Lair"]           = "Gruul's Lair",
    ["Magtheridon's Lair"]     = "Magtheridon's Lair",
    ["Serpentshrine Cavern"]   = "Serpentshrine Cavern",
    ["Tempest Keep"]           = "Tempest Keep: The Eye",
    ["Battle for Mount Hyjal"] = "Battle for Mount Hyjal",
    ["Black Temple"]           = "Black Temple",
    ["Zul'Aman"]               = "Zul'Aman",
    ["Sunwell Plateau"]        = "Sunwell Plateau",
  },

  -- ==========================================================================
  -- Português (ptBR) — nomes oficiais da Blizzard.
  -- ==========================================================================
  ptBR = {
    -- Classic — raids
    ["Naxxramas"]      = "Naxxramas",
    ["Ahn'Qiraj 40"]   = "Templo de Ahn'Qiraj",
    ["Ahn'Qiraj 20"]   = "Ruínas de Ahn'Qiraj",
    ["Zul'Gurub"]      = "Zul'Gurub",
    ["Molten Core"]    = "Núcleo Derretido",
    ["Blackwing Lair"] = "Covil Asa Negra",
    ["Onyxia"]         = "Covil da Onyxia",

    -- Classic — masmorras
    ["Stratholme"]        = "Stratholme",
    ["Scholomance"]       = "Scolomântia",
    ["Dire Maul"]         = "Gládio Cruel",
    ["Lower Blackrock Spire"] = "Pico da Rocha Negra (Inferior)",
    ["Upper Blackrock Spire"] = "Pico da Rocha Negra (Superior)",
    ["Blackrock Depths"]  = "Abismo Rocha Negra",
    ["Sunken Temple"]     = "Templo Submerso",
    ["Maraudon"]          = "Maraudon",
    ["Zul'Farrak"]        = "Zul'Farrak",
    ["Uldaman"]           = "Uldaman",
    ["SM Graveyard"]      = "Monastério Escarlate — Cemitério",
    ["SM Library"]        = "Monastério Escarlate — Biblioteca",
    ["SM Armory"]         = "Monastério Escarlate — Arsenal",
    ["SM Cathedral"]      = "Monastério Escarlate — Catedral",
    ["Razorfen Downs"]    = "Urzal dos Mortos",
    ["Razorfen Kraul"]    = "Urzal dos Tuscos",
    ["Gnomeregan"]        = "Gnomeregan",
    ["The Stockade"]      = "O Cárcere",
    ["Blackfathom Deeps"] = "Profundezas Negras",
    ["Shadowfang Keep"]   = "Bastilha da Presa Negra",
    ["Deadmines"]         = "Minas Mortas",
    ["Wailing Caverns"]   = "Caverna Ululante",
    ["Ragefire Chasm"]    = "Cavernas Ígneas",

    -- TBC — masmorras
    ["Hellfire Ramparts"]       = "Muralha Fogo do Inferno",
    ["The Blood Furnace"]       = "Fornalha de Sangue",
    ["The Slave Pens"]          = "Pátio dos Escravos",
    ["The Underbog"]            = "Brejo Oculto",
    ["The Steamvault"]          = "Câmara dos Vapores",
    ["Mana-Tombs"]              = "Tumbas de Mana",
    ["Auchenai Crypts"]         = "Catacumbas Auchenai",
    ["Sethekk Halls"]           = "Salões dos Sethekk",
    ["Shadow Labyrinth"]        = "Labirinto Soturno",
    ["Old Hillsbrad Foothills"] = "A Fuga do Forte do Desterro",
    ["The Black Morass"]        = "Lamaçal Negro",
    ["The Mechanar"]            = "Mecanar",
    ["The Botanica"]            = "Jardim Botânico",
    ["The Arcatraz"]            = "Arcatraz",
    ["Magisters' Terrace"]      = "Terraço dos Magísteres",
    ["The Shattered Halls"]     = "Salões Despedaçados",

    -- TBC — raids
    ["Karazhan"]               = "Karazhan",
    ["Gruul's Lair"]           = "Covil de Gruul",
    ["Magtheridon's Lair"]     = "Covil de Magtheridon",
    ["Serpentshrine Cavern"]   = "Caverna do Serpentário",
    ["Tempest Keep"]           = "Bastilha da Tormenta: O Olho",
    ["Battle for Mount Hyjal"] = "A Batalha pelo Monte Hyjal",
    ["Black Temple"]           = "Templo Negro",
    ["Zul'Aman"]               = "Zul'Aman",
    ["Sunwell Plateau"]        = "Platô da Nascente do Sol",
  },
}

-- Resolve o nome exibido para a `key` no idioma atual do cliente.
-- Fallback: a própria key (já é o nome em inglês).
local currentLocaleNames = LOCALIZED_INSTANCE_NAMES[GetLocale()]

function CEF.LocalizeInstance(key)
  if not key or key == "" or key == "—" or key == false then
    return key
  end
  if currentLocaleNames and currentLocaleNames[key] then
    return currentLocaleNames[key]
  end
  return key
end
