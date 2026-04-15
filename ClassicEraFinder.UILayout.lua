-- Módulo: helpers de layout/altura e colunas para a tabela virtualizada.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UILayout = CEF.UILayout or {}
local UI = CEF.UILayout

local function cfg()
  return CEF.CONST
end

function UI.columnWidths(totalW)
  local CC = cfg()
  local innerTotal = math.max(280 + CC.INSTANCE_LEVELS_TO_MSG_GAP, totalW - 2 * CC.TABLE_PAD)
  local inner = innerTotal - CC.INSTANCE_LEVELS_TO_MSG_GAP
  -- c1 = instância; c2 = Classic/TBC; c3–c6 = mensagem, personagem, tempo, ação.
  local c1 = inner * 0.175
  local c2 = inner * 0.075
  local c3 = inner * 0.285
  local c4 = inner * 0.155
  local c5 = inner * 0.11
  local c6 = inner * 0.20
  local x1 = CC.TABLE_PAD
  local x2 = x1 + c1 + CC.COL_GAP
  local x3 = x2 + c2 + CC.INSTANCE_LEVELS_TO_MSG_GAP
  local x4 = x3 + c3
  local x5 = x4 + c4
  local x6 = x5 + c5
  return c1, c2, c3, c4, c5, c6, x1, x2, x3, x4, x5, x6
end

function UI.entryMessageDisplayLineBudget(e)
  local n = CEF.entryInstancesLineCount(e)
  if n <= 1 then
    return 1
  end
  return math.min(5, n)
end

function UI.entryRowTotalHeight(e)
  local CC = cfg()
  local ni = CEF.entryInstancesLineCount(e)
  local nm = UI.entryMessageDisplayLineBudget(e)

  local instBlock = CC.ROW_HEIGHT
  if ni > 1 then
    -- Como usamos "\n\n" entre instâncias, o texto vira "2*ni - 1" linhas.
    instBlock = (2 * ni - 1) * CC.ROW_INSTANCE_LINE
  end

  local msgBlock = CC.ROW_HEIGHT
  if nm > 1 then
    msgBlock = nm * CC.MSG_CELL_LINE_HEIGHT + (nm - 1) * CC.MSG_CELL_LINE_LEADING
  end

  local edge = 2 * CC.ROW_EDGE_INSET_SINGLE
  if ni > 1 or nm > 1 then
    edge = 2 * CC.ROW_EDGE_INSET_MULTI
  end

  local h = math.max(CC.ROW_HEIGHT, instBlock, msgBlock) + edge
  -- «Era» com Classic+TBC em duas linhas precisa de espaço extra.
  if e then
    local eraTxt = CEF.entryExpansionColumnRichText(e)
    if eraTxt and eraTxt:find("\n", 1, true) then
      h = h + CC.ROW_INSTANCE_LINE
    end
  end
  return h
end

function UI.layoutHeaderColumns(header)
  if not header then
    return
  end
  local CC = cfg()
  local w = header:GetWidth()
  local sf = CEF.UI and CEF.UI.scrollFrame
  if sf and sf.GetWidth then
    local sw = sf:GetWidth()
    if sw and sw > 80 then
      w = sw
    end
  end
  local c1, c2, c3, c4, c5, c6, x1, x2, x3, x4, x5, x6 = UI.columnWidths(w)
  local w1 = math.max(92, c1 - CC.COL_GAP)
  local w2 = math.max(44, c2 - CC.COL_GAP)
  local w3 = math.max(50, c3 - CC.COL_GAP)
  local w4 = math.max(36, c4 - CC.COL_GAP)
  local w5 = math.max(40, c5 - CC.COL_GAP)
  local w6 = math.max(56, c6 - CC.COL_GAP)

  header.h1:ClearAllPoints()
  header.h2:ClearAllPoints()
  header.h3:ClearAllPoints()
  header.h4:ClearAllPoints()
  header.h5:ClearAllPoints()
  header.h6:ClearAllPoints()

  header.h1:SetPoint("LEFT", header, "LEFT", x1, 0)
  header.h1:SetWidth(w1)
  header.h2:SetPoint("LEFT", header, "LEFT", x2, 0)
  header.h2:SetWidth(w2)
  header.h2:Show()
  header.h3:SetPoint("LEFT", header, "LEFT", x3, 0)
  header.h3:SetWidth(w3)
  header.h4:SetPoint("LEFT", header, "LEFT", x4, 0)
  header.h4:SetWidth(w4)
  header.h5:SetPoint("LEFT", header, "LEFT", x5, 0)
  header.h5:SetWidth(w5)
  header.h6:SetPoint("LEFT", header, "LEFT", x6, 0)
  header.h6:SetWidth(w6)
  header.h5:SetJustifyH("LEFT")
  header.h6:SetJustifyH("LEFT")
end
