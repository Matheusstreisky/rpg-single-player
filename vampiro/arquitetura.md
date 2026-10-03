# Arquitetura da Mesa de RPG — Vampiro: A Máscara (Single-Player)

## Visão Geral

Mesa de RPG single-player ambientada em Vampiro: A Máscara, gerenciada pelo Kiro como narrador. O sistema mantém contexto e memória entre sessões através de arquivos markdown estruturados, com gravação em lote via agentes de memória ao fim de cada sessão.

---

## Estrutura de Pastas

```
rpg/
├── arquitetura.md              # Este arquivo — decisões de design do sistema
├── config.md                   # Regras, tom, mecânicas, house rules
├── primeiros-passos.md         # Guia para criação de nova campanha
│
├── agentes/                    # Definições e prompts dos agentes de automação
│   ├── rpg-acontecimentos.md   # Agente: atualiza o log de fatos objetivos
│   ├── rpg-memorias.md         # Agente: atualiza memórias individuais dos personagens
│   └── rpg-estado.md           # Agente: atualiza o estado presente de cada personagem
│
├── ferramentas/                # Utilitários opcionais da mesa
│   ├── rolar.ps1               # Rolador de pool de d10 (V5) — opcional
│   ├── fim-de-sessao.ps1       # Lê e combina os 3 agentes ao fim de sessão
│   └── README.md               # Uso das ferramentas
│
├── .kiro/hooks/
│   └── rpg-fim-de-sessao.json  # Hook UserPromptSubmit que dispara a gravação em lote
│
├── mundo/
│   ├── mundo.md                # Lore geral, cidades, facções, NPCs menores
│   └── acontecimentos.md       # Log cronológico e objetivo de eventos (com índice)
│
├── personagens/
│   └── [nome]/
│       ├── ficha.md            # Atributos, disciplinas, background
│       ├── estado.md           # Estado presente: humor, vínculos, objetivos imediatos
│       └── memorias.md         # Experiências acumuladas — append-only
│
└── npcs/
    └── [nome]/
        ├── ficha.md            # Perfil, motivações, segredos, agenda atual
        ├── estado.md           # Estado presente do NPC
        └── memorias.md         # Histórico de interações — append-only
```

NPCs seguem um modelo progressivo de complexidade — veja a seção **Ciclo de Vida de NPCs** para detalhes.

---

## Ciclo de Vida de NPCs

NPCs não nascem com estrutura completa — eles a conquistam conforme ganham importância narrativa. Isso mantém o projeto organizado e evita criar pastas para personagens que aparecem uma vez.

### Estágio 1 — Figurante (só em `mundo.md`)

NPCs sem relevância ainda. Descrição inline, sem pasta própria.

```markdown
### Donnie Riccio
Dono do bar Midnight Fuel em Texas City. Humano, não sabe da existência de vampiros.
Contato útil para informações de rua.
```

### Estágio 2 — NPC Relevante (pasta própria em `/npcs/`)

Quando um NPC começa a ter interações repetidas, segredos próprios ou objetivos que afetam a narrativa, o narrador (ou o agente `rpg-estado`) cria a pasta com estrutura completa:

```
npcs/[nome]/
├── ficha.md      # Perfil, motivações, segredos, agenda_atual
├── estado.md     # Estado presente
└── memorias.md   # Histórico de interações — append-only
```

**Gatilhos para promoção de Estágio 1 → 2:**
- O NPC apareceu em 2 ou mais sessões
- O NPC tem um segredo que pode afetar a trama
- O jogador demonstrou interesse investigativo naquele NPC
- O NPC tem agenda própria que age independentemente do jogador

**A promoção é feita pelo narrador**, que move a descrição de `mundo.md` para uma pasta própria e expande o perfil. O agente `rpg-estado` pode sugerir a promoção no campo "Notas do Narrador" do `estado.md`.

### Agenda de NPCs

A agenda é um campo simples na `ficha.md` do NPC, atualizado pelo agente apenas quando muda. Não precisa ser complexo — uma ou duas linhas do que aquele NPC está tentando fazer agora.

```markdown
## Agenda Atual
**Atualizada em:** Sessão XX — Turno XX
- [Objetivo principal do NPC neste momento]
- [Como a última interação com o jogador afetou seus planos — se aplicável]
```

---

## Composição do Grupo

O jogador pode configurar em `config.md` como deseja que os companheiros do grupo sejam introduzidos na campanha.

### Modo Manual

Todos os personagens do grupo são criados pelo jogador antes de começar. Cada um recebe pasta em `/personagens/` com ficha, estado e memórias completos.

```markdown
## Composição do Grupo
- **Modo:** manual
- **Personagens:** xunda, [nome2], [nome3]
```

### Modo Automático (orgânico)

O narrador introduz personagens potenciais naturalmente no decorrer da história — como aliados, figuras recorrentes ou simplesmente pessoas que cruzam o caminho do protagonista. Quando o relacionamento atingir um ponto natural de virada, o narrador pergunta **in-game**, de forma narrativa, se o personagem deseja convidar aquela pessoa.

```markdown
## Composição do Grupo
- **Modo:** automático
- **Personagens iniciais:** xunda
```

**Como funciona na prática:**

1. O narrador introduz o NPC como parte da história, sem sinalizar que é um "companheiro em potencial"
2. O relacionamento se desenvolve organicamente ao longo de sessões
3. Quando houver um momento natural (crise compartilhada, revelação mútua, pedido de ajuda), o narrador oferece a escolha in-game:
   - *"[NPC] para na porta e vira para você. 'Não consigo fazer isso sozinho. E acho que você também não.' — O que você faz?"*
4. Se o jogador aceitar, o NPC é promovido para `/personagens/` com ficha completa gerada pelo narrador, baseada nas interações anteriores
5. Se o jogador recusar, o NPC continua como NPC em `/npcs/` — sem consequência artificial

**Regras do modo automático:**
- O narrador nunca força ou pressiona a entrada de um companheiro
- A pergunta deve surgir de um momento narrativo real, não de um menu
- O jogador pode configurar o número máximo de companheiros em `config.md`
- NPCs rejeitados como companheiros continuam existindo na história normalmente

```markdown
## Composição do Grupo
- **Modo:** automático
- **Personagens iniciais:** xunda
- **Máximo de companheiros:** 2
- **Notas:** Prefiro companheiros que tenham motivações próprias, não apenas seguidores
```

---

## Princípios de Memória

### Imutabilidade

Arquivos de memória (`memorias.md`) são **append-only** — nenhuma entrada existente pode ser alterada ou removida. Apenas novos blocos são adicionados ao final.

Isso garante:
- Integridade histórica da narrativa
- Rastreabilidade de decisões e mudanças de perspectiva
- Fidelidade ao passado mesmo quando personagens evoluem

Os agentes de memória usam **apenas `fs_append`** nesses arquivos, nunca `str_replace` ou `fs_write`.

### Perspectiva Individual

Um mesmo evento é registrado de formas diferentes em cada arquivo:

| Arquivo | O que registra |
|---|---|
| `acontecimentos.md` | O fato objetivo e neutro |
| `memorias.md` do personagem A | O que ele vivenciou, sentiu e concluiu |
| `memorias.md` do personagem B | O que *ele* vivenciou — pode divergir de A |

Informações que um personagem não tinha acesso **não aparecem em sua memória**, mesmo que o leitor (você) saiba. Isso preserva segredos, mentiras e percepções divergentes entre personagens.

### Separação: Passado × Presente

| Arquivo | Natureza | Quem escreve |
|---|---|---|
| `memorias.md` | Passado imutável — o que aconteceu | `rpg-memorias` via `fs_append` |
| `estado.md` | Presente mutável — como está agora | `rpg-estado` via `fs_write` |
| `ficha.md` | Estrutura mecânica — atributos e poderes | `rpg-estado` via `str_replace` (campos específicos) |

---

## Formato dos Arquivos

### `acontecimentos.md`

O arquivo mantém um **índice no topo**, atualizado automaticamente pelo agente, seguido das entradas cronológicas.

```markdown
# Acontecimentos

## Índice
- [Sessão 01 — Turno 01](#sessão-01--turno-01) — Descrição resumida do evento
- [Sessão 01 — Turno 03 ⚠️](#sessão-01--turno-03-️) — Evento marcante: [título]
- [Sessão 02 — Turno 01](#sessão-02--turno-01) — Descrição resumida

---

## Sessão 01 — Turno 01
**Data ficcional:** [data]
**Local:** [onde]
**Envolvidos:** [personagens]

Descrição objetiva e neutra do que ocorreu.
```

### `memorias.md`

O arquivo também mantém um **índice no topo**, com links para os turnos registrados e destaque para eventos marcantes.

```markdown
# Memórias de [Nome]

## Índice
- [Sessão 01 — Turno 01](#sessão-01--turno-01)
- [Sessão 01 — Turno 03 ⚠️](#sessão-01--turno-03-️) — EVENTO MARCANTE: [título]

---

## Sessão 01 — Turno 01
- Bullet point com o que aconteceu do ponto de vista do personagem.
- Decisão tomada, impressão formada, informação obtida.
```

### Entrada de Evento Marcante ⚠️

Usado para momentos de virada — primeira morte, traição, uso de disciplina poderosa, decisões irreversíveis.

```markdown
## Sessão XX — Turno XX ⚠️ EVENTO MARCANTE: [título curto]

**Local:** [onde aconteceu]
**Presentes:** [quem estava lá]

[Descrição narrativa do momento em prosa curta]

> *"Fala exata do personagem que impactou."*
> — [Quem disse]

[Como o personagem reagiu internamente e externamente]

**Impacto emocional registrado:**
- [Personagem A]: [o que sentiu]
- [Personagem B]: [o que sentiu]
```

**Critérios para evento marcante:**
- Primeira vez que o personagem enfrenta algo significativo
- Decisões irreversíveis (matar, trair, violar uma Tradição)
- Falas de personagens importantes que alteram percepção
- Momentos de virada emocional ou moral
- Uso de disciplinas poderosas contra o personagem

### `estado.md`

Arquivo sobrescrito a cada turno. Reflete o estado *atual* do personagem — não o histórico.

```markdown
# Estado Atual de [Nome]
**Atualizado em:** Sessão XX — Turno XX

## Condição Física
- Níveis de saúde: [X/7]
- Sangue (Vitae): [X/pool máximo]

## Condição Emocional
- Humor predominante: [descrição]
- Tensões ativas: [o que está pesando]

## Humanidade
- Nível atual: [X/10]
- Última mudança: [motivo, se houver]

## Vínculos Ativos
- [Nome do NPC/personagem]: [natureza do vínculo — aliado, suspeito, ameaça, etc.]

## Objetivos Imediatos
- [O que o personagem está tentando fazer agora]

## Notas do Narrador
- [Informações que o narrador deve lembrar sobre esse personagem para a próxima cena]
```

### `ficha.md` — Campo de Controle

O topo da ficha inclui um campo de controle de atualização:

```markdown
# Ficha de [Nome]
**Última atualização mecânica:** Sessão XX
**⚠️ ATENÇÃO:** Esta ficha não é atualizada desde a Sessão XX. Han passado Y sessões. Deseja revisar antes de continuar?
```

O campo `⚠️ ATENÇÃO` é inserido pelo agente `rpg-estado` quando detecta que a ficha não foi atualizada há mais de 5 sessões. Ele é removido quando a ficha é revisada.

### `ficha.md` de NPC — Agenda

A ficha de NPCs narrativamente relevantes inclui um campo `agenda_atual`, atualizado pelo agente quando a agenda muda:

```markdown
## Agenda Atual
**Atualizada em:** Sessão XX — Turno XX

- [O que esse NPC está tentando fazer agora]
- [Como a última interação com o jogador afetou seus planos]
```

---

## Mentiras e Omissões

| Perspectiva | O que registra |
|---|---|
| Quem mentiu | *"Disse X para [fulano], mas a verdade é Y"* |
| Quem ouviu a mentira | Apenas *"[fulano] disse X"* — sem saber que é falso |

---

## Carregamento de Contexto por Sessão

No início de cada sessão, os arquivos relevantes são fornecidos via `#File` no chat.

| Situação | Arquivos recomendados |
|---|---|
| Início de sessão | `config.md` + `acontecimentos.md` + fichas + estados dos presentes |
| Cena de combate | `config.md` + fichas + estados dos combatentes |
| Cena de roleplay emocional | Fichas + estados + memórias dos envolvidos |
| Exploração de novo local | `mundo.md` + `acontecimentos.md` |
| Investigação de NPC | `npcs/[nome]/ficha.md` + `npcs/[nome]/memorias.md` |

---

## Agentes de Memória

Três agentes com responsabilidades separadas e bem definidas. Cada um tem seu arquivo de design em `/agentes/`.

### `rpg-acontecimentos`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, via script `ferramentas/fim-de-sessao.ps1`
- **Arquivos que toca:** `mundo/acontecimentos.md`
- **Operação permitida:** `fs_append` apenas
- **Responsabilidade:** Registrar em lote todos os turnos da sessão não registrados; manter o índice atualizado

### `rpg-memorias`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, coordenado pelo mesmo script (2º na sequência)
- **Arquivos que toca:** `memorias.md` de cada personagem/NPC presente nas cenas
- **Operação permitida:** `fs_append` apenas
- **Responsabilidade:** Registrar em lote a perspectiva individual de cada personagem por turno; detectar eventos marcantes; registrar mentiras e omissões corretamente

### `rpg-estado`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, coordenado pelo mesmo script (3º na sequência)
- **Arquivos que toca:** `estado.md` de cada personagem/NPC; campos específicos de `ficha.md`
- **Operações permitidas:** `fs_write` em `estado.md`; `str_replace` em campos específicos de `ficha.md`
- **Responsabilidade:** Atualizar estado presente ao fim da sessão (saúde, Vitae, Humanidade, humor, vínculos); verificar desatualização da ficha (> 5 sessões); atualizar agenda de NPCs

### Fluxo de Fim de Sessão

```
Jogador digita "fim de sessão" (ou variação)
        ↓
Hook UserPromptSubmit dispara
        ↓
ferramentas/fim-de-sessao.ps1 roda
    → lê agentes/rpg-acontecimentos.md
    → lê agentes/rpg-memorias.md
    → lê agentes/rpg-estado.md
    → combina e injeta instruções no contexto do Kiro
        ↓
[1] rpg-acontecimentos (em lote — todos os turnos não registrados)
    → fs_append em acontecimentos.md (fatos neutros + índice)
        ↓
[2] rpg-memorias (em lote — todos os turnos não registrados)
    → para cada personagem, para cada turno:
        → avalia perspectiva individual
        → fs_append em memorias.md
        → aplica formato ⚠️ se critério atendido
        → atualiza índice de memorias.md
        ↓
[3] rpg-estado (estado ao fim do último turno)
    → fs_write em estado.md de cada personagem
    → atualiza saúde, Vitae, Humanidade, humor, vínculos
    → str_replace em agenda de NPCs se mudou
    → verifica ficha: se > 5 sessões sem update, insere alerta
        ↓
Sessão encerrada — todos os arquivos atualizados
```

---

## Tecnologia

| Componente | Descrição |
|---|---|
| **Plataforma** | Kiro IDE |
| **Narrador** | Kiro (Claude) em sessão Vibe |
| **Automação** | Hook do Kiro (`UserPromptSubmit` — fim de sessão) + script PowerShell |
| **Agentes** | 3 agentes customizados em `/agentes/` |
| **Ferramentas** | Rolador de dados opcional (`ferramentas/rolar.ps1`) — ver seção "Ferramentas da Mesa" |
| **Formato** | Markdown puro para todos os arquivos |
| **Persistência** | Garantida pelos arquivos — Kiro não tem memória nativa entre sessões |

---

## Ferramentas da Mesa

A pasta `ferramentas/` reúne utilitários **opcionais** que apoiam a mesa sem alterar a narrativa nem os arquivos de memória.

### `rolar.ps1` — Rolador de dados (V5)

Script PowerShell que rola um pool de d10 e conta sucessos pelas regras da 5ª edição (ver `config.md`): 6+ é sucesso, pares de 10 somam +2 (mesclagem crítica), e os Dados de Fome sinalizam Falha de Bestialidade (1) e Êxtase (10). Aceita uma dificuldade opcional e indica se o teste passou.

- **Opcional por design:** o projeto funciona 100% sem ele. O jogador pode sempre rolar seus próprios dados (físicos ou de qualquer app) e informar o resultado ao Narrador. O rolador é uma conveniência — útil para rolagens ocultas do Narrador ou por preferência pessoal. A escolha de usar ou não é sempre do jogador.
- **Execução portátil (Windows):** rode sempre com bypass por chamada, que vale só para aquela execução e não altera nenhuma configuração da máquina:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pool 5 -Nome "Destreza + Atletismo"
  ```
  O Narrador **nunca** altera a execution policy da máquina do jogador. Em macOS/Linux, rodar `.ps1` exige PowerShell Core (`pwsh`); sem ele, basta informar as rolagens manualmente.
- **Não escreve em arquivo nenhum** — apenas imprime o resultado no terminal. Está fora do fluxo dos agentes de memória.
- **Uso detalhado:** `ferramentas/README.md`. Regras de conduta do Narrador quanto às rolagens: seção "Como as rolagens acontecem" em `config.md`.
