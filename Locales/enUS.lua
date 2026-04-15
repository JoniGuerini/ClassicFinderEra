-- Locale base (enUS) — carrega SEMPRE antes dos demais e preenche CEF.L com
-- todas as chaves. Outros locales (ptBR.lua, ...) só sobrescrevem o que querem
-- traduzir; qualquer chave ausente cai automaticamente no texto em inglês.
--
-- IMPORTANTE: a `key` interna das instâncias NÃO é traduzida — ela é identidade
-- usada em INSTANCE_ROWS, filtros, SavedVariables, etc. A tradução acontece só
-- na hora de EXIBIR, via CEF.LocalizeInstance(key) (ver InstanceNames.lua).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.L = CEF.L or {}
local L = CEF.L

-- Janela / cabeçalho
L["addonTitle"] = "Classic Era Finder"
L["searchPlaceholder"] = "Search name or instance..."
L["resetButton"] = "Reset"

-- Abas
L["tabList"] = "List"
L["tabTerms"] = "Terms"
L["tabAbout"] = "About"

-- Colunas da tabela principal
L["colInstance"] = "Instance / levels"
L["colEra"] = "Era"
L["colMessage"] = "Message"
L["colCharacter"] = "Character"
L["colTime"] = "Time"
L["colAction"] = "Action"

-- Coluna "Era" (marca de expansão)
L["eraClassic"] = "Classic"
L["eraTbc"] = "TBC"

-- Ações nas linhas
L["actionInvite"] = "Invite"
L["actionWhisper"] = "Whisper"

-- Dropdown de instância
L["allInstances"] = "All instances"
L["dungeons"] = "Dungeons"
L["raids"] = "Raids"
L["tbcDungeons"] = "TBC — dungeons"
L["tbcRaids"] = "TBC — raids"

-- Dropdown de intenção (procura grupo / procura membros)
L["allAnnouncements"] = "All announcements"
L["intentSeekingGroup"] = "Looking for group"
L["intentRecruiting"] = "Looking for members"

-- Dropdown de função
L["anyRole"] = "Any role"
L["roleTank"] = "Tank"
L["roleHeal"] = "Healer"
L["roleDps"] = "DPS"

-- Tooltip / rótulos auxiliares
L["tooltipInstance"] = "Instance:"
L["tooltipCharacter"] = "Character:"
L["tooltipChannel"] = "Channel:"

-- Aba Termos — títulos de seção
L["termsAboutTitle"] = "About this page"
L["termsAboutBody"] = "Reference for the patterns Classic Era Finder uses on chat. Raid markers show as icons in the list: {square}, {{circle}}, {rt6}, star, skull, etc. Lists update with new versions of the addon."
L["termsInstancesBody"] = "Text matching is case-insensitive. The chat line is normalized (collapsed whitespace; |c...|r color codes and texture markers stripped). The \"Keywords\" column mirrors the same entries from the code; the addon also treats abbreviations at the end of the sentence or with punctuation (e.g. \"... DM\" = Dire Maul, \"... WC\" or \"for wc \" = Wailing Caverns, \"STRAT(live)\" = Stratholme) without having to list every variation. This build also includes TBC dungeons and raids (TBC sections in the filter and in the terms list)."
L["termsTableColInstance"] = "Instance / zone"
L["termsTableColLevels"] = "Levels"
L["termsTableColKeywords"] = "Keywords"
L["termsTableColPattern"] = "Pattern / fragment"
L["termsTableColPatternOrTerm"] = "Pattern / term"
L["termsTableColPhrase"] = "Phrase / fragment"
L["termsTableColWord"] = "Word (spec / class / role)"
L["termsScarletBody"] = "With one of these phrases and no named wing (GY/Lib/Arm/Cath), all 4 wings are assumed. Messages with only \"sm\" as a word (e.g. \"LFG SM\") also count."
L["termsLfgBody"] = "Fragments that help treat the line as a group announcement (combined with other rules). The list includes lf1m, lf2m, lf3m and the same normalized text used in instance detection."
L["termsRecruitIntentBody"] = "Patterns that classify the line as RECRUITMENT (someone who already has a group and is looking for roles/classes). Row action becomes \"Whisper\"."
L["termsRecruitFirstWordBody"] = "If the first word after \"lf \" is in this list, the line is treated as recruitment. Ex.: \"LF Resto Sham/Druid and Warlocks for Gruul\" → \"resto\" is in the list → Whisper."
L["termsSeekingIntentBody"] = "Patterns that classify the line as a player looking for GROUP. Row action becomes \"Invite\"."
L["termsExcludeBody"] = "Do not list as instance announcement."
L["termsInstances"] = "Recognized instances"
L["termsBannerDungeons"] = "Dungeons"
L["termsBannerRaids"] = "Raids"
L["termsBannerDungeonsTbc"] = "TBC — dungeons"
L["termsBannerRaidsTbc"] = "TBC — raids"
L["termsScarletTitle"] = "Scarlet Monastery — generic phrases"
L["termsLfgTitle"] = "LFG patterns (messageLooksLFG)"
L["termsExcludeTitle"] = "Exclusions (craft / portal / enchant)"
L["termsRecruitIntentTitle"] = "Intent: Looking for members (whisper)"
L["termsRecruitFirstWordTitle"] = "Recruiting — first word after \"lf \""
L["termsSeekingIntentTitle"] = "Intent: Looking for group (invite)"

-- Minimapa
L["minimapTitle"] = "Classic Era Finder"
L["minimapLeftClick"] = "Left click: open or close"
L["minimapDrag"] = "Drag with right button: move on minimap"
