-- Módulo: tema visual (fonte única de cores)
--
-- Organização:
--   - CEF.Theme.Hex.*     → strings "|cffRRGGBB" usadas como prefixo em rich text
--                           (ex.: fsNome:SetText(Theme.Hex.raidName .. name .. "|r"))
--   - CEF.Theme.RGB.*     → {r, g, b} em [0,1] para SetTextColor
--   - CEF.Theme.RGBA.*    → {r, g, b, a} em [0,1] para SetColorTexture
--
-- Qualquer ajuste de cor do addon passa por aqui; evita divergência entre módulos.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Theme = CEF.Theme or {}
local T = CEF.Theme

-- ============================================================================
-- Hex strings (prefixo |cffRRGGBB para rich text do chat/UI)
-- ============================================================================
T.Hex = {
  -- Faixa de níveis (laranja = mín / verde = máx)
  levelMin   = "|cffff9933",
  levelMax   = "|cff33cc33",

  -- Nome da instância por tipo
  dungeonName = "|cff9fd3ff",  -- azul-claro
  raidName    = "|cffffb74d",  -- âmbar

  -- Coluna "Era" na lista principal
  eraClassic = "|cffb8956b",   -- marrom
  eraTbc     = "|cff33cc33",   -- verde

  -- Aba Termos
  termsDungeon     = "|cffffd100",
  termsRaid        = "|cffff8866",
  termsKeywords    = "|cff99cc99",
  termsLfgPattern  = "|cffb8d4e8",
  termsSectionHdr  = "|cffffcc66",
  termsColHeader   = "|cffc8c8c8",

  -- Dropdowns / filtros
  dropdownHeader   = "|cffffcc66",  -- header de seção dentro do dropdown de instância
  dropdownLabel    = "|cffffffff",

  -- Neutro/placeholder
  dim              = "|cff888888",
}

-- ============================================================================
-- RGB (SetTextColor)
-- ============================================================================
T.RGB = {
  navTabActiveText   = { 1, 0.9, 0.42 },
  navTabInactiveText = { 0.62, 0.58, 0.52 },
  dropdownHeaderText = { 1, 0.82, 0.18 },
  dropdownRowText    = { 1, 1, 1 },
  fullscreenBtnText  = { 0.95, 0.82, 0.45 },
  arrowTint          = { 0.95, 0.82, 0.45 },
  actionBtnLabel         = { 1, 0.92, 0.22 },
  actionBtnLabelDisabled = { 0.48, 0.44, 0.32 },
}

-- ============================================================================
-- RGBA (SetColorTexture)
-- ============================================================================
T.RGBA = {
  -- Janela principal
  windowBg     = { 0.02, 0.02, 0.03, 0.97 },
  titleBarBg   = { 0.15, 0.12, 0.08, 1 },
  navBarBg     = { 0.06, 0.055, 0.07, 0.98 },
  filterBarBg  = { 0.07, 0.065, 0.08, 0.97 },
  headerBg     = { 0.2, 0.18, 0.12, 0.95 },

  -- Nav tabs
  navTabActive   = { 0.24, 0.19, 0.12, 1 },
  navTabInactive = { 0.1, 0.09, 0.08, 0.92 },

  -- Search
  searchBg     = { 0.04, 0.04, 0.05, 1 },

  -- Dropdowns
  dropdownBtnBg       = { 0.11, 0.09, 0.07, 1 },
  dropdownMenuBg      = { 0.05, 0.048, 0.06, 0.99 },
  dropdownMenuBorder  = { 0.55, 0.45, 0.18, 0.85 },
  dropdownRowBg       = { 0.13, 0.11, 0.09, 0.96 },
  dropdownRowBgHover  = { 0.26, 0.2, 0.14, 1 },
  dropdownHeaderBg    = { 0.08, 0.07, 0.06, 1 },

  -- Reset button
  resetBtnBg      = { 0.14, 0.1, 0.08, 1 },
  resetBtnBgHover = { 0.22, 0.16, 0.1, 1 },

  -- Scrollbar
  scrollTrack    = { 0.04, 0.035, 0.07, 0.96 },
  scrollThumb    = { 0.52, 0.5, 0.6, 0.88 },
  scrollThumbHi  = { 0.62, 0.58, 0.72, 0.55 },

  -- Terms tab
  termsBanner       = { 0.14, 0.11, 0.08, 0.98 },
  termsTableHeader  = { 0.2, 0.17, 0.13, 0.98 },
  termsZebraA       = { 0.06, 0.055, 0.09, 0.94 },
  termsZebraB       = { 0.085, 0.07, 0.11, 0.9 },

  -- Fullscreen button
  fullscreenBtnBg      = { 0.1, 0.08, 0.06, 0.65 },
  fullscreenBtnBgHover = { 0.16, 0.12, 0.09, 0.85 },

  -- Action buttons (invite/whisper/disabled)
  actionBtnInviteBg   = { 0.52, 0.12, 0.1, 0.96 },
  actionBtnWhisperBg  = { 0.4, 0.16, 0.52, 0.96 },
  actionBtnDisabledBg = { 0.12, 0.12, 0.14, 0.72 },
  actionBtnInviteHi   = { 0.72, 0.26, 0.22, 0.55 },
  actionBtnWhisperHi  = { 0.55, 0.26, 0.68, 0.55 },

  -- Blocker transparente (clique-fora fecha dropdowns)
  blockerTransparent = { 0, 0, 0, 0.001 },
}

-- ============================================================================
-- Helpers
-- ============================================================================

-- Aplica uma tupla RGBA em uma textura.
function T.applyTexture(tex, rgba)
  if tex and rgba then
    tex:SetColorTexture(rgba[1], rgba[2], rgba[3], rgba[4] or 1)
  end
end

-- Aplica uma tupla RGB em um FontString.
function T.applyTextColor(fs, rgb)
  if fs and rgb then
    fs:SetTextColor(rgb[1], rgb[2], rgb[3])
  end
end
