-- Locale ptBR — sobrescreve chaves em CEF.L quando o cliente for Português.
-- Qualquer chave não traduzida aqui cai no enUS automaticamente.

if GetLocale() ~= "ptBR" then
  return
end

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder
CEF.L = CEF.L or {}
local L = CEF.L

L["addonTitle"] = "Classic Era Finder"
L["searchPlaceholder"] = "Procurar nome ou instância..."
L["resetButton"] = "Redefinir"

L["tabList"] = "Lista"
L["tabTerms"] = "Termos"
L["tabAbout"] = "Sobre"

L["colInstance"] = "Instância / níveis"
L["colEra"] = "Era"
L["colMessage"] = "Mensagem"
L["colCharacter"] = "Personagem"
L["colTime"] = "Tempo"
L["colAction"] = "Ação"

L["eraClassic"] = "Classic"
L["eraTbc"] = "TBC"

L["actionInvite"] = "Convidar"
L["actionWhisper"] = "Sussurrar"

L["allInstances"] = "Todas as instâncias"
L["dungeons"] = "Masmorras"
L["raids"] = "Raides"
L["tbcDungeons"] = "TBC — masmorras"
L["tbcRaids"] = "TBC — raides"

L["allAnnouncements"] = "Todos os anúncios"
L["intentSeekingGroup"] = "Procura grupo"
L["intentRecruiting"] = "Procura membros"

L["anyRole"] = "Qualquer função"
L["roleTank"] = "Tank"
L["roleHeal"] = "Curandeiro"
L["roleDps"] = "DPS"

L["tooltipInstance"] = "Instância:"
L["tooltipCharacter"] = "Personagem:"
L["tooltipChannel"] = "Canal:"

L["termsAboutTitle"] = "Sobre esta página"
L["termsAboutBody"] = "Referência aos padrões que o Classic Era Finder usa no chat. Marcadores de raide aparecem como ícones na lista: {square}, {{circle}}, {rt6}, star, skull, etc. Listas atualizam com novas versões do addon."
L["termsInstancesBody"] = "Match no texto (minúsculas / maiúsculas indiferentes). A linha do chat é normalizada (espaços colapsados; códigos |c…|r e marcadores de textura retirados). A coluna «Palavras-chave» espelha as mesmas entradas do código; além disso o addon trata abreviaturas no fim da frase ou com pontuação (ex.: «… DM» Dire Maul, «… WC» ou «for wc » Wailing Caverns, «STRAT(live)» Stratholme) sem todas aparecerem repetidas na lista. Nesta build também entram masmorras e raides do TBC (secções TBC no filtro e na lista de termos)."
L["termsTableColInstance"] = "Instância / zona"
L["termsTableColLevels"] = "Níveis"
L["termsTableColKeywords"] = "Palavras-chave"
L["termsTableColPattern"] = "Padrão / fragmento"
L["termsTableColPatternOrTerm"] = "Padrão / termo"
L["termsTableColPhrase"] = "Frase / fragmento"
L["termsTableColWord"] = "Palavra (spec / classe / função)"
L["termsScarletBody"] = "Com uma destas frases e sem asa nomeada (GY/Lib/Arm/Cath), assumem-se as 4 alas. Mensagens só com «sm» como palavra (ex.: «LFG SM») contam também."
L["termsLfgBody"] = "Fragmentos que ajudam a tratar a linha como anúncio de grupo (com outras regras). A lista inclui lf1m, lf2m, lf3m e o mesmo texto normalizado usado na deteção de instâncias."
L["termsRecruitIntentBody"] = "Padrões que classificam a linha como RECRUTAMENTO (quem já tem grupo e busca função/classe). Ação da linha vira «Sussurrar»."
L["termsRecruitFirstWordBody"] = "Se a primeira palavra depois de «lf » estiver nesta lista, a linha é tratada como recrutamento. Ex.: «LF Resto Sham/Druid and Warlocks for Gruul» → «resto» está na lista → Sussurrar."
L["termsSeekingIntentBody"] = "Padrões que classificam a linha como jogador procurando GRUPO. Ação da linha vira «Convidar»."
L["termsExcludeBody"] = "Não listar como anúncio de instância."
L["termsInstances"] = "Instâncias reconhecidas"
L["termsBannerDungeons"] = "Masmorras"
L["termsBannerRaids"] = "Raides"
L["termsBannerDungeonsTbc"] = "TBC — masmorras"
L["termsBannerRaidsTbc"] = "TBC — raides"
L["termsScarletTitle"] = "Mosteiro Escarlate — frases genéricas"
L["termsLfgTitle"] = "Padrões LFG (messageLooksLFG)"
L["termsExcludeTitle"] = "Exclusões (profissão / portal / encantamento)"
L["termsRecruitIntentTitle"] = "Intenção: Procura membros (sussurrar)"
L["termsRecruitFirstWordTitle"] = "Recrutamento — primeira palavra após «lf »"
L["termsSeekingIntentTitle"] = "Intenção: Procura grupo (convidar)"

L["minimapTitle"] = "Classic Era Finder"
L["minimapLeftClick"] = "Clique esquerdo: abrir ou fechar"
L["minimapDrag"] = "Arraste com o botão direito: mover no minimapa"
