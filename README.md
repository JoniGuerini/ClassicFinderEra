# Classic Era Finder

Addon para **World of Warcraft Classic Era** que lê o chat (LFG/LFM), organiza pedidos de grupo numa UI própria e inclui abas de **Guilda** e **Mensagens** (Battle.net + sussurros).

## Funcionalidades

- **Lista** — anúncios de grupo detectados no chat, com filtros por instância, intenção e função
- **Guilda** — roster com filtros, ordenação por cabeçalho e cores de nível relativas ao seu personagem
- **Mensagens** — conversas Battle.net e sussurros no jogo, com histórico local, resposta citada e exclusão confirmada
- **Termos** — referência das palavras-chave / padrões usados na detecção
- **Idiomas** — automático pelo cliente, com overrides `enUS`, `ptBR` e `esES`

## Instalação

1. Copie a pasta `ClassicEraFinder` para:
   ```text
   World of Warcraft\_classic_era_\Interface\AddOns\
   ```
2. Reinicie o cliente ou use `/reload`
3. Abra com `/cef` ou pelo botão no minimapa

## Comandos

| Comando | Descrição |
|---------|-----------|
| `/cef` ou `/classicerafinder` | Abre / fecha a janela principal |
| `/cef listchat` | Lista conversas salvas (diagnóstico) |
| `/cef movechat Origem Destino` | Move o histórico BNet de um amigo para outro |

## Estrutura do projeto

Organização em pastas por domínio (estilo feature-folders):

```text
ClassicEraFinder/
├── ClassicEraFinder.toc      # manifesto do addon
├── ClassicEraFinder.xml      # ordem de carga dos scripts
├── ClassicEraFinder.lua      # bootstrap / eventos
├── Media/                    # ícones (TGA)
├── Core/                     # Constants, DB
├── Locale/                   # i18n
├── Data/                     # instâncias, filtros, entries, nomes
├── Features/
│   ├── Guild/                # lógica + UI da guilda
│   └── Chat/                 # lógica + UI de mensagens
└── UI/                       # Lista, layout, engine, minimapa
```

A ordem de carga fica em `ClassicEraFinder.xml`. Os módulos compartilham o global `ClassicEraFinder` (`CEF`); não há sistema de `require`.

## Requisitos

- Cliente **Classic Era** (`Interface: 11508` no `.toc`)
- SavedVariables: `ClassicEraFinderDB` (histórico de lista e chat)

## Desenvolvimento

1. Edite os `.lua` nas pastas acima
2. No jogo: `/reload` para aplicar
3. Branch de modularização: `refactor/modular-structure`

## Licença / autor

Projeto **ClassicEraFinder** — uso pessoal / comunidade Classic Era.
