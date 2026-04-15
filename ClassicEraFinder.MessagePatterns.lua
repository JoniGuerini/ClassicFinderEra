-- Módulo: padrões estáticos usados pela lógica de mensagens.
--
-- Listas puras, sem lógica. Consumidas por ClassicEraFinder.Messages.lua e
-- espelhadas na aba Termos (UITerms) para referência visual.
--
-- Se alterar alguma destas listas, atualize a lógica correspondente em
-- CEF.classifyMessageIntent / CEF.messageLooksLFG / CEF.looksLikeProfessionOrTradeRequest.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.MessagePatterns = CEF.MessagePatterns or {}
local P = CEF.MessagePatterns

-- ============================================================================
-- Primeira palavra depois de "lf " que indica RECRUTAMENTO (quem já tem grupo
-- e procura função/classe/spec). Ex.: "lf resto sham ...", "lf warlocks for mag".
-- ============================================================================
P.RECRUIT_FIRST_WORDS_LIST = {
  -- funções
  "tank", "tanks", "heal", "heals", "healer", "healers", "dps", "rdps", "mdps",
  -- classes e plurais
  "mage", "mages", "lock", "locks", "warlock", "warlocks",
  "priest", "priests", "pala", "paladin", "paladins", "pally", "pallies",
  "druid", "druids", "rogue", "rogues", "hunter", "hunters",
  "sham", "shaman", "shamans", "warrior", "warriors", "warr", "warrs",
  -- specs de healer
  "resto", "restoration", "holy", "disc", "discipline",
  -- specs de caster/ranged dps
  "shadow", "spriest", "boomkin", "moonkin",
  "ele", "elemental",
  -- specs de melee dps
  "fury", "arms", "ret", "retrib", "retribution",
  "feral", "bear", "kitty", "enh", "enhance", "enhancement",
  -- specs de tank
  "prot", "protection",
}

-- Lookup O(1) derivado da lista acima.
P.RECRUIT_FIRST_WORDS = {}
for _, w in ipairs(P.RECRUIT_FIRST_WORDS_LIST) do
  P.RECRUIT_FIRST_WORDS[w] = true
end

-- ============================================================================
-- Palavras que sugerem montagem de grupo / vaga (messageLooksLFG).
-- ============================================================================
P.LFG_PLAIN = {
  "lfg", "lfm", "lf ", "lf1", "lf1m", "lf2", "lf2m", "lf3", "lf3m", "looking for",
  "need ", "need a", "need 1", "need 2",
  "group for", "gtg", "forming", "wtb group", "boost", "carry",
  "procura", "preciso", "precisa", "grupo", "vaga", "tank", "heal", "healer", "dps",
  "warrior", "paladin", "druid", "rogue", "hunter", "mage", "priest", "lock", "shaman",
  "guerreiro", "mago", "sacer", "cacador", "ladino",
}

-- ============================================================================
-- Pedidos óbvios de serviço / craft / portal (reforço para não listar como anúncio
-- de masmorra). Evitar termos genéricos tipo "engineering" — batem em "Gnomeregan" etc.
-- ============================================================================
P.PROFESSION_TRADE_EXCLUDE = {
  "enchanter",
  "enchantor",
  "lf enchant",
  "lfg enchant",
  "lfm enchant",
  "need enchant",
  "need an enchant",
  "want enchant",
  " chest enchant",
  " bracer enchant",
  " boot enchant",
  " cloak enchant",
  " weapon enchant",
  "+4 stats",
  "+3 stats",
  "+8 stats",
  "stats to chest",
  "stats on chest",
  " lockbox",
  "unlock my",
  " disenchant",
  " d/e ",
  "port to ",
  "portal to ",
  "summon to ",
}

-- ============================================================================
-- Listas só para exibir na aba Termos — não são usadas na lógica (padrões reais
-- estão inline nas funções isLfmRecruiting / isLfgSeekingGroup em Messages.lua).
-- Se alterar um lado, atualize o outro.
-- ============================================================================
P.RECRUITING_INTENT_HINTS = {
  "lfm", "lfm ...", "... lfm", "lf1m / lf2m / lf3m", "lf 1m / lf 2m / lf 3m",
  "lf <N> more", "lf one more", "lf two more", "lf three more",
  "looking for more", "looking for <N> more",
  "need <N>", "need a", "need an", "need 1", "need 2", "need 3",
  "need tank", "need heal", "need dps", "need mage", "need lock", "need priest",
  "precisamos", "preciso de", "falta", "falta um",
  "tem grupo + vaga",
  "lf tank / heal / heals / dps",
  "lf mage / lock / priest / pala",
  "lf druid / rogue / hunter",
  "lf sham / warrior / warlock",
  "lf <spec/classe> (ver tabela abaixo)",
}

P.SEEKING_INTENT_HINTS = {
  "lfg", "lfg ...", "... lfg",
  "looking for group",
  "procuro grupo", "procura grupo", "pf grupo",
  "lf ... (sem classe/spec após) → assume procura grupo",
}
