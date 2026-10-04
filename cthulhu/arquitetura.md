# Arquitetura da Mesa de RPG — Call of Cthulhu 7ª Edição (Single-Player)

## Visão Geral

Mesa de RPG single-player ambientada em Call of Cthulhu 7ª Edição, gerenciada pelo Kiro como Guardião. O sistema mantém contexto e memória entre sessões através de arquivos markdown estruturados, com atualização automática via agentes de memória ao fim de cada turno.

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
│   ├── rpg-estado.md           # Agente: atualiza o estado presente de cada personagem
│   └── rpg-arquivista.md       # Agente: arquiva sessões antigas quando os arquivos crescem demais
│
├── ferramentas/                # Utilitários opcionais da mesa
│   ├── rolar.ps1               # Rolador de dados d100 (CoC 7e) — opcional
│   └── README.md               # Uso do rolador
│
├── mundo/
│   ├── mundo.md                # Lore geral, localidade, facções, NPCs menores
│   ├── acontecimentos.md       # Log ATIVO de eventos (índice das sessões ativas + entradas recentes)
│   └── acontecimentos/         # Partes arquivadas (criadas pelo rpg-arquivista)
│       ├── indice.md           # Índice-mestre das sessões arquivadas
│       └── acontecimentos-parte-NN.md  # Sessões antigas — imutáveis
│
├── personagens/
│   └── [nome]/
│       ├── ficha.md            # Características, perícias, feitiços, background
│       ├── estado.md           # Estado presente: sanidade, vínculos, objetivos imediatos
│       ├── memorias.md         # Experiências acumuladas — append-only (arquivo ativo)
│       └── memorias/           # Partes arquivadas (criadas pelo rpg-arquivista)
│           ├── indice.md       # Índice-mestre das sessões arquivadas
│           └── memorias-parte-NN.md    # Sessões antigas — imutáveis
│
└── npcs/
    └── [nome]/
        ├── ficha.md            # Perfil, motivações, segredos, agenda atual
        ├── estado.md           # Estado presente do NPC
        ├── memorias.md         # Histórico de interações — append-only (arquivo ativo)
        └── memorias/           # Partes arquivadas (criadas pelo rpg-arquivista)
            ├── indice.md       # Índice-mestre das sessões arquivadas
            └── memorias-parte-NN.md    # Sessões antigas — imutáveis
```

> As pastas de partes (`acontecimentos/`, `memorias/`) e seus arquivos só existem depois que o `rpg-arquivista` arquiva pela primeira vez. Até lá, há apenas o arquivo ativo. Ver seção **Arquivamento de Arquivos Longos**.

NPCs seguem um modelo progressivo de complexidade — veja a seção **Ciclo de Vida de NPCs** para detalhes.

---

## Ciclo de Vida de NPCs

NPCs não nascem com estrutura completa — eles a conquistam conforme ganham importância narrativa. Isso mantém o projeto organizado e evita criar pastas para personagens que aparecem uma vez.

### Estágio 1 — Figurante (só em `mundo.md`)

NPCs sem relevância ainda. Descrição inline, sem pasta própria.

```markdown
### Dona Zdenka
Dona do caderno de fiado do Armazém da Companhia, ~55 anos. Humana, sem contato com o sobrenatural.
Fonte útil de boatos sobre quem chega, quem deve e quem some na vila operária.
```

### Estágio 2 — NPC Relevante (pasta própria em `/npcs/`)

Quando um NPC começa a ter interações repetidas, segredos próprios ou objetivos que afetam a narrativa, o Guardião (ou o agente `rpg-estado`) cria a pasta com estrutura completa:

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
- O NPC é membro de uma facção ou culto relevante

**A promoção é feita pelo Guardião**, que move a descrição de `mundo.md` para uma pasta própria e expande o perfil. O agente `rpg-estado` pode sugerir a promoção no campo "Notas do Guardião" do `estado.md`.

### Agenda de NPCs

A agenda é um campo simples na `ficha.md` do NPC, atualizado pelo agente apenas quando muda.

```markdown
## Agenda Atual
**Atualizada em:** Sessão XX — Turno XX
- [Objetivo principal do NPC neste momento]
- [Como a última interação com o investigador afetou seus planos — se aplicável]
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

O Guardião introduz personagens potenciais naturalmente no decorrer da história — como aliados, figuras recorrentes ou simplesmente pessoas que cruzam o caminho do protagonista. Quando o relacionamento atingir um ponto natural de virada, o Guardião pergunta **in-game**, de forma narrativa, se o investigador deseja convidar aquela pessoa.

```markdown
## Composição do Grupo
- **Modo:** automático
- **Personagens iniciais:** xunda
```

**Como funciona na prática:**

1. O Guardião introduz o NPC como parte da história, sem sinalizar que é um "companheiro em potencial"
2. O relacionamento se desenvolve organicamente ao longo de sessões
3. Quando houver um momento natural (crise compartilhada, descoberta mútua, pedido de ajuda), o Guardião oferece a escolha in-game:
   - *"[NPC] para diante da porta e vira para você. 'Não consigo fazer isso sozinho. E você já sabe demais para parar agora.' — O que você faz?"*
4. Se o jogador aceitar, o NPC é promovido para `/personagens/` com ficha completa gerada pelo Guardião, baseada nas interações anteriores
5. Se o jogador recusar, o NPC continua como NPC em `/npcs/` — sem consequência artificial

**Regras do modo automático:**
- O Guardião nunca força ou pressiona a entrada de um companheiro
- A pergunta deve surgir de um momento narrativo real, não de um menu
- O jogador pode configurar o número máximo de companheiros em `config.md`
- NPCs rejeitados como companheiros continuam existindo na história normalmente

```markdown
## Composição do Grupo
- **Modo:** automático
- **Personagens iniciais:** xunda
- **Máximo de companheiros:** 2
- **Notas:** Prefiro companheiros com motivações próprias, não apenas seguidores
```

---

## Princípios de Memória

### Imutabilidade

Arquivos de memória (`memorias.md`) e o log de `acontecimentos.md` são **append-only** — nenhuma entrada existente pode ser alterada ou removida. Apenas novos blocos são adicionados ao final.

Isso garante:
- Integridade histórica da narrativa
- Rastreabilidade de decisões e mudanças de perspectiva
- Fidelidade ao passado mesmo quando personagens evoluem (ou decaem)

Os agentes `rpg-acontecimentos` e `rpg-memorias` usam **apenas `fs_append`** nesses arquivos, nunca `str_replace` ou `fs_write`. **Isso não muda.**

#### Exceção única: o `rpg-arquivista`

O agente `rpg-arquivista` é a **única** exceção autorizada, e apenas para a mecânica de arquivamento (ver seção **Arquivamento de Arquivos Longos**). A regra de imutabilidade passa a ter dois níveis:

| Camada | Mutabilidade | Quem escreve |
|---|---|---|
| Arquivo ativo (`acontecimentos.md`, `memorias.md`) | append pelos agentes de memória; **reescrito só pelo arquivista** ao arquivar | `rpg-memorias`/`rpg-acontecimentos` via `fs_append`; `rpg-arquivista` via `fs_write` |
| Arquivos-parte (`*-parte-NN.md`) | **permanentemente imutáveis** após criados | `rpg-arquivista` cria uma vez e nunca reabre |

O **conteúdo histórico continua imutável** no sentido original: nenhuma entrada é alterada ou apagada. Ao arquivar, o arquivista apenas **move blocos inteiros, verbatim**, do arquivo ativo para uma parte permanente. Nenhum outro agente escreve no arquivo ativo com algo diferente de `fs_append`.

### Perspectiva Individual

Um mesmo evento é registrado de formas diferentes em cada arquivo:

| Arquivo | O que registra |
|---|---|
| `acontecimentos.md` | O fato objetivo e neutro |
| `memorias.md` do personagem A | O que ele vivenciou, sentiu e concluiu |
| `memorias.md` do personagem B | O que *ele* vivenciou — pode divergir de A |

Informações que um personagem não tinha acesso **não aparecem em sua memória**, mesmo que o leitor (você) saiba. Isso preserva segredos, mentiras e percepções divergentes entre personagens — e é especialmente crítico em CoC, onde personagens descobrem verdades diferentes sobre o mesmo horror.

### Separação: Passado × Presente

| Arquivo | Natureza | Quem escreve |
|---|---|---|
| `memorias.md` | Passado imutável — o que aconteceu | `rpg-memorias` via `fs_append`; `rpg-arquivista` reescreve só ao arquivar |
| `estado.md` | Presente mutável — como está agora | `rpg-estado` via `fs_write` |
| `ficha.md` | Estrutura mecânica — características e perícias | `rpg-estado` via `str_replace` (campos específicos) |
| `*-parte-NN.md` | Passado arquivado — imutável permanente | `rpg-arquivista` cria uma vez, nunca reabre |

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

Usado para momentos de virada — primeiro contato com o Mitos, perda de sanidade significativa, morte de aliado, revelação que muda tudo.

```markdown
## Sessão XX — Turno XX ⚠️ EVENTO MARCANTE: [título curto]

**Local:** [onde aconteceu]
**Presentes:** [quem estava lá]

[Descrição narrativa do momento em prosa curta]

> *"Fala exata do personagem que impactou."*
> — [Quem disse]

[Como o personagem reagiu internamente e externamente]

**Impacto registrado:**
- [Personagem A]: [o que sentiu / perdeu de sanidade]
- [Personagem B]: [o que sentiu]
```

**Critérios para evento marcante:**
- Primeiro contato real com o Mitos (criatura, ritual, tomo proibido)
- Perda de sanidade significativa (5 pontos ou mais em uma rolagem)
- Morte de aliado ou NPC importante
- Revelação que inverte o que o investigador acreditava ser verdade
- Uso de feitiço pela primeira vez
- Insanidade temporária deflagrada
- Decisões irreversíveis com peso moral

### `estado.md`

Arquivo sobrescrito a cada turno. Reflete o estado *atual* do investigador — não o histórico.

```markdown
# Estado Atual de [Nome]
**Atualizado em:** Sessão XX — Turno XX

## Condição Física
- Pontos de Vida: [X/Y]
- Pontos de Magia: [X/Y]
- Condições especiais: [ferimentos, envenenamento, inconsciente, etc. — ou "nenhuma"]

## Condição Mental
- Sanidade atual: [X]
- Insanidades temporárias ativas: [lista ou "nenhuma"]
- Insanidades permanentes: [lista ou "nenhuma"]
- Último choque de sanidade: [o que causou e quanto perdeu — ou "nenhum recente"]

## Mitos de Cthulhu
- Conhecimento atual: [X]%
- Sanidade máxima: [99 − X]
- Últimas revelações: [o que o investigador descobriu sobre o Mitos recentemente — ou "nenhuma"]

## Sorte
- Valor atual: [X]

## Vínculos Ativos
- [Nome]: [natureza do vínculo — aliado, fonte, suspeito, ameaça, etc.]

## Objetivos Imediatos
- [O que o investigador está ativamente tentando descobrir ou fazer agora]

## Notas do Guardião
- [Informações que o Guardião deve ter em mente para a próxima cena com este personagem]
```

### `ficha.md` — Campo de Controle

O topo da ficha inclui um campo de controle de atualização:

```markdown
# Ficha de [Nome]
**Última atualização mecânica:** Sessão XX
**⚠️ ATENÇÃO:** Esta ficha não é atualizada desde a Sessão XX. Passaram-se Y sessões. Deseja revisar antes de continuar?
```

O campo `⚠️ ATENÇÃO` é inserido pelo agente `rpg-estado` quando detecta que a ficha não foi atualizada há mais de 5 sessões. Ele é removido quando a ficha é revisada.

### `ficha.md` de NPC — Agenda

A ficha de NPCs narrativamente relevantes inclui um campo `agenda_atual`, atualizado pelo agente quando a agenda muda:

```markdown
## Agenda Atual
**Atualizada em:** Sessão XX — Turno XX

- [O que esse NPC está tentando fazer agora]
- [Como a última interação com o investigador afetou seus planos]
```

---

## Mentiras e Omissões

| Perspectiva | O que registra |
|---|---|
| Quem mentiu | *"Disse X para [fulano], mas a verdade é Y"* |
| Quem ouviu a mentira | Apenas *"[fulano] disse X"* — sem saber que é falso |

Em CoC isso é especialmente relevante: cultos mentem sistematicamente, NPCs escondem pertencimento, e investigadores podem chegar a conclusões erradas que persistem em suas memórias como verdades — até serem corrigidas por uma nova descoberta.

---

## Carregamento de Contexto por Sessão

No início de cada sessão, os arquivos relevantes são fornecidos via `#File` no chat.

| Situação | Arquivos recomendados |
|---|---|
| Início de sessão | `config.md` + `acontecimentos.md` + fichas + estados dos presentes |
| Cena de combate ou perigo | `config.md` + fichas + estados dos combatentes |
| Cena de investigação | fichas + estados + `mundo.md` + memórias relevantes |
| Exploração de novo local | `mundo.md` + `acontecimentos.md` |
| Interrogatório ou social | Fichas + estados + `npcs/[nome]/ficha.md` + memórias |
| Contato com o Mitos | `config.md` (para regras de sanidade) + fichas + estados |

---

## Agentes de Memória

Quatro agentes com responsabilidades separadas e bem definidas. Cada um tem seu arquivo de design em `/agentes/`. Os três primeiros gravam os registros da sessão; o quarto arquiva arquivos longos e **nunca interfere** no trabalho dos demais.

### `rpg-acontecimentos`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, via script `ferramentas/fim-de-sessao.ps1`
- **Arquivos que toca:** `mundo/acontecimentos.md`
- **Operação permitida:** `fs_append` apenas
- **Responsabilidade:** Registrar em lote todos os turnos da sessão não registrados; manter o índice atualizado

### `rpg-memorias`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, coordenado pelo mesmo script (2º na sequência)
- **Arquivos que toca:** `memorias.md` de cada personagem/NPC presente nas cenas
- **Operação permitida:** `fs_append` apenas
- **Responsabilidade:** Registrar em lote a perspectiva individual de cada personagem por turno; detectar eventos marcantes; registrar mentiras e omissões corretamente; registrar perdas de sanidade

### `rpg-estado`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, coordenado pelo mesmo script (3º na sequência)
- **Arquivos que toca:** `estado.md` de cada personagem/NPC; campos específicos de `ficha.md`
- **Operações permitidas:** `fs_write` em `estado.md`; `str_replace` em campos específicos de `ficha.md`
- **Responsabilidade:** Atualizar estado presente ao fim da sessão (PV, PM, Sanidade, Mitos, Sorte, Insanidades); verificar desatualização da ficha (> 5 sessões); atualizar agenda de NPCs

### `rpg-arquivista`
- **Gatilho:** Hook `UserPromptSubmit` — dispara ao fim de sessão, coordenado pelo mesmo script (4º e último na sequência)
- **Arquivos que toca:** arquivos ativos `mundo/acontecimentos.md` e cada `memorias.md`; cria arquivos-parte e índices-mestre nas pastas de arquivamento
- **Operações permitidas:** `fs_write` nos arquivos ativos e nas partes; `fs_write`/`fs_append` nos índices-mestre — **única exceção à regra de append-only**
- **Responsabilidade:** Quando um arquivo ativo passa de 1500 linhas, mover as sessões completas mais antigas (nunca cortando no meio de um turno) para um arquivo-parte imutável e registrá-las no índice-mestre; não faz nada se nenhum arquivo passou do limite
- **Não interfere** nos três agentes anteriores: roda só depois que eles concluem e nunca reescreve o que gravaram

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
    → lê agentes/rpg-arquivista.md
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
    → atualiza Sanidade, PV, PM, Sorte, Mitos, Insanidades
    → str_replace em agenda de NPCs se mudou
    → verifica ficha: se > 5 sessões sem update, insere alerta
        ↓
[4] rpg-arquivista (manutenção — roda por último)
    → para cada arquivo ativo (acontecimentos.md e cada memorias.md):
        → conta linhas; se ≤ 1500, não faz nada
        → se > 1500: move sessões completas mais antigas para
          um novo arquivo-parte imutável (fs_write)
        → reescreve o arquivo ativo sem as sessões movidas (fs_write)
        → atualiza o índice-mestre indice.md da pasta de partes
        ↓
Sessão encerrada — todos os arquivos atualizados
```

---

## Arquivamento de Arquivos Longos

Os arquivos append-only crescem a cada sessão. Deixados sem controle, `acontecimentos.md` e os `memorias.md` ficariam grandes a ponto de pesar no contexto de cada turno — mais tokens, mais custo, leitura mais lenta. O agente `rpg-arquivista` resolve isso **sem perder nada do histórico**.

### Como funciona

- **Limite:** quando um arquivo ativo passa de **1500 linhas**, o arquivista entra em ação (no fim da sessão, depois dos outros três agentes).
- **Corte por sessão:** ele move as **sessões completas mais antigas** para um arquivo-parte. Nunca parte um turno, um evento marcante ou uma sessão no meio.
- **Partes imutáveis:** cada arquivo-parte (`*-parte-NN.md`) é fechado e nunca mais alterado. Novas sessões arquivadas vão sempre para uma parte nova.
- **Conteúdo verbatim:** as entradas são movidas exatamente como estavam — o arquivista não reescreve texto de turno.

### Estrutura resultante (Opção B — índice-mestre separado)

Cada arquivo append-only ganha, ao ser arquivado pela primeira vez, uma pasta própria com as partes e um índice-mestre:

```
mundo/
├── acontecimentos.md              # ATIVO: índice só das sessões ativas + entradas recentes
└── acontecimentos/
    ├── indice.md                  # ÍNDICE-MESTRE: aponta para as sessões arquivadas
    ├── acontecimentos-parte-01.md # imutável
    └── acontecimentos-parte-02.md # imutável
```

O **arquivo ativo** mantém só o índice das sessões que ainda estão nele e um aviso apontando para o `indice.md`. O **índice-mestre** concentra os links de tudo que foi arquivado, agrupado por parte, com links relativos (`acontecimentos-parte-01.md#âncora`). Durante o jogo normal carrega-se apenas o arquivo ativo; as partes só são abertas quando se precisa consultar o passado distante.

O design detalhado (formato das partes, do índice-mestre, regra de âncoras, checklist) está em `agentes/rpg-arquivista.md`.

---

## Tecnologia

| Componente | Descrição |
|---|---|
| **Plataforma** | Kiro IDE |
| **Guardião** | Kiro (Claude) em sessão Vibe |
| **Automação** | Hook do Kiro (`UserPromptSubmit` — fim de sessão) + script PowerShell |
| **Agentes** | 4 agentes customizados em `/agentes/` (3 de gravação + 1 arquivista) |
| **Ferramentas** | Rolador de dados opcional (`ferramentas/rolar.ps1`) — ver seção "Ferramentas da Mesa" |
| **Formato** | Markdown puro para todos os arquivos |
| **Persistência** | Garantida pelos arquivos — Kiro não tem memória nativa entre sessões |

---

## Ferramentas da Mesa

A pasta `ferramentas/` reúne utilitários **opcionais** que apoiam a mesa sem alterar a narrativa nem os arquivos de memória.

### `rolar.ps1` — Rolador de dados (CoC 7ª Edição)

Script PowerShell que rola d100, trata dado bônus/penalidade e classifica o grau de sucesso pelas regras da 7ª edição (ver `config.md`). Também faz rolagens genéricas (`NdX+M`, `NdX*M`) para dano, características e tabelas.

- **Opcional por design:** o projeto funciona 100% sem ele. O jogador pode sempre rolar seus próprios dados (físicos ou de qualquer app) e informar o resultado ao Guardião. O rolador é uma conveniência — útil para rolagens ocultas do Guardião (percepção, Sanidade, reações de NPC) ou por preferência pessoal. A escolha de usar ou não é sempre do jogador.
- **Execução portátil (Windows):** rode sempre com bypass por chamada, que vale só para aquela execução e não altera nenhuma configuração da máquina:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pericia 45 -Nome "Investigar"
  ```
  O Guardião **nunca** altera a execution policy da máquina do jogador. Em macOS/Linux, rodar `.ps1` exige PowerShell Core (`pwsh`); sem ele, basta informar as rolagens manualmente.
- **Não escreve em arquivo nenhum** — apenas imprime o resultado no terminal. Está fora do fluxo dos agentes de memória.
- **Uso detalhado:** `ferramentas/README.md`. Regras de conduta do Guardião quanto às rolagens: seção "Como as rolagens acontecem" em `config.md`.
