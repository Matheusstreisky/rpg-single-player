# Primeiros Passos — Criando sua Campanha

Guia para montar uma campanha de RPG single-player usando este sistema com o Kiro como narrador.

---

## O que você vai precisar

- Kiro IDE instalado
- Esta estrutura de pastas (descrita em `arquitetura.md`)
- Vontade de jogar Vampiro: A Máscara

Não é necessário nenhum conhecimento técnico além de editar arquivos de texto.

---

## Passo 1 — Configure a campanha

Crie o arquivo `config.md` na raiz do projeto. Ele é o contrato entre você e o narrador — define o tom, as regras e as expectativas da campanha.

```markdown
# Configuração da Campanha

## Cenário
- **Cidade:** [nome e época — ex: São Paulo, anos 90]
- **Tom:** [gótico/noir/político/horror/etc.]
- **Nível de violência:** [leve / moderado / sem restrições]
- **Temas que prefiro evitar:** [liste aqui]

## Regras
- **Sistema:** Vampiro: A Máscara [edição]
- **House rules:** [liste aqui qualquer regra personalizada]
- **Rolagem de dados:** [como será feita — ex: o jogador rola e informa o resultado]

## Instruções ao Narrador
- [Qualquer instrução específica sobre como você quer que o Kiro narre]
- [Ex: "Prefiro narrações em segunda pessoa", "Quero que NPCs sejam moralmente ambíguos"]
```

---

## Passo 2 — Crie seu personagem

Crie a pasta `personagens/[nome-do-personagem]/` e os três arquivos dentro dela.

### `ficha.md`

```markdown
# Ficha de [Nome]
**Última atualização mecânica:** Sessão 00

## Identidade
- **Nome:** 
- **Clã:** 
- **Geração:** 
- **Sire:** 
- **Idade aparente / real:** 
- **Abraço:** [quando e onde foi abraçado]

## Atributos
### Físicos
- Força: • | Destreza: • | Vigor: •

### Sociais
- Carisma: • | Manipulação: • | Aparência: •

### Mentais
- Percepção: • | Inteligência: • | Raciocínio: •

## Habilidades
[Liste as principais com pontuação]

## Disciplinas
[Nome da disciplina]: •••

## Antecedentes
[Recursos, Status, Aliados, etc.]

## Humanidade
- Nível: 7/10

## Força de Vontade
- Permanente: •••••

## Background
[Quem era em vida. O que levou ao Abraço. Que tipo de vampiro quer — ou não quer — ser.]
```

### `memorias.md`

Começa vazio, com apenas o cabeçalho:

```markdown
# Memórias de [Nome]

## Índice

---
```

### `estado.md`

Estado inicial do personagem:

```markdown
# Estado Atual de [Nome]
**Atualizado em:** Sessão 00

## Condição Física
- Níveis de saúde: 7/7
- Sangue (Vitae): [pool máximo]/[pool máximo]

## Condição Emocional
- Humor predominante: [como o personagem está se sentindo ao início]
- Tensões ativas: nenhuma

## Humanidade
- Nível atual: 7/10
- Última mudança: —

## Vínculos Ativos
[Nenhum ainda — será preenchido conforme a campanha avança]

## Objetivos Imediatos
- [O que o personagem quer agora, no início da história]

## Notas do Narrador
[Vazio no início]
```

---

## Passo 3 — Prepare o mundo

### `mundo/mundo.md`

Descreva o cenário onde a campanha acontece. Não precisa ser extenso no início — vá expandindo conforme jogar.

```markdown
# O Mundo

## A Cidade
[Descrição geral da cidade — atmosfera, bairros importantes, perigos]

## A Camarilla Local
- **Príncipe:** [nome, clã, reputação]
- **Primogênitos conhecidos:** [lista]
- **Tensões políticas:** [o que está em jogo]

## Facções e Organizações
[Liste as que o personagem conhece ou suspeita existirem]

## Locais Importantes
[Elísio, refúgios conhecidos, lugares perigosos]

## NPCs Menores
[Figurantes, contatos, conhecidos sem papel narrativo central]
```

### `mundo/acontecimentos.md`

Começa vazio, com apenas o cabeçalho:

```markdown
# Acontecimentos

## Índice

---
```

---

## Passo 4 — Configure os hooks dos agentes

Os agentes já estão definidos nos arquivos em `/agentes/`. O que você precisa fazer é criar os **hooks** no Kiro para que eles sejam acionados automaticamente ao fim de cada turno.

### O que são os hooks

Hooks são automações do Kiro que disparam em eventos específicos. Neste sistema, os três agentes usam o trigger `Stop` — ou seja, rodam automaticamente quando o narrador encerra uma resposta.

### Como criar os hooks

Abra a paleta de comandos (`Ctrl+Shift+P`) e busque **"Open Kiro Hook UI"**. Crie um hook para cada agente:

| Hook | Trigger | Ação | Agente |
|---|---|---|---|
| `rpg-acontecimentos` | `Stop` | agent | Prompt do arquivo `agentes/rpg-acontecimentos.md` |
| `rpg-memorias` | `Stop` | agent | Prompt do arquivo `agentes/rpg-memorias.md` |
| `rpg-estado` | `Stop` | agent | Prompt do arquivo `agentes/rpg-estado.md` |

Para cada hook, o campo **prompt** deve conter o conteúdo da seção "Prompt do Agente" do arquivo correspondente em `/agentes/`.

### Personalizando o comportamento

O comportamento dos agentes é ajustado em dois lugares:

- **`config.md`** — define tom, modo de grupo, limites narrativos e instruções ao narrador. É o principal ponto de personalização por campanha.
- **Arquivos em `/agentes/`** — contêm as regras fixas de cada agente. Edite aqui apenas se quiser mudar o comportamento estrutural (ex: mudar critérios de evento marcante, adicionar novos campos ao `estado.md`).

Você **não precisa criar novos agentes** — os três arquivos em `/agentes/` já são a definição completa do sistema. Os hooks apenas os ativam.

---

## Passo 5 — Comece a jogar

Abra uma **sessão Vibe** no Kiro (não Spec). Forneça os arquivos de contexto no início do chat usando `#File`:

```
#File config.md
#File mundo/mundo.md
#File mundo/acontecimentos.md
#File personagens/[nome]/ficha.md
#File personagens/[nome]/estado.md
```

Depois escreva a instrução de início:

> *"Você é o narrador desta campanha de Vampiro: A Máscara. Leia os arquivos fornecidos para entender o cenário, as regras e o personagem. Meu personagem é [nome]. Pode começar a primeira cena — deixo a situação inicial a seu critério com base no que leu."*

Ou, se preferir definir a situação:

> *"Você é o narrador desta campanha. Começamos com [nome] em [lugar], [situação]. Sessão 01, Turno 01."*

---

## Iniciando com esta campanha (Xunda em Telêmaco Borba)

Se você está usando os arquivos de exemplo já criados, o contexto de início é:

```
#File config.md
#File mundo/mundo.md
#File mundo/acontecimentos.md
#File personagens/xunda/ficha.md
#File personagens/xunda/estado.md
```

Mensagem de início sugerida:

> *"Você é o narrador desta campanha de Vampiro: A Máscara. Leia os arquivos fornecidos. Meu personagem é Alexandra 'Xunda' Voss — Toreador, recém-Abraçada, morando em Telêmaco Borba. Pode começar a Sessão 01, Turno 01 onde achar mais interessante com base no que leu."*

---

## Dicas para uma boa campanha

**Sobre o contexto**
- Carregue apenas os arquivos relevantes para a cena. Quanto menos contexto desnecessário, melhor a qualidade da narração.
- Em cenas com NPCs importantes, carregue a ficha e as memórias deles também.
- Ao retomar após uma pausa longa, carregue `acontecimentos.md` + estados atuais para o narrador se situar.

**Sobre os personagens**
- Quanto mais detalhado o background inicial, mais o narrador tem para trabalhar.
- Defina ao menos um segredo, um medo e um objetivo de longo prazo para o personagem.
- NPCs que você imagina sendo recorrentes merecem uma pasta própria em `/npcs/` desde cedo.

**Sobre a narrativa**
- Os agentes de memória trabalham melhor quando você sinaliza o fim de um turno claramente.
- Eventos marcantes são detectados automaticamente, mas você pode sinalizar manualmente: *"Isso foi um momento importante para meu personagem."*
- Se quiser revisar o que foi registrado, leia `acontecimentos.md` — é o log mais limpo do que aconteceu.

---

## Estrutura final esperada antes da primeira sessão

```
rpg/
├── config.md                           ✓ criado
├── mundo/
│   ├── mundo.md                        ✓ criado
│   └── acontecimentos.md               ✓ criado (vazio)
├── personagens/
│   └── [nome]/
│       ├── ficha.md                    ✓ criado
│       ├── estado.md                   ✓ criado
│       └── memorias.md                 ✓ criado (vazio)
└── agentes/
    ├── rpg-acontecimentos.md           ✓ lido e configurado
    ├── rpg-memorias.md                 ✓ lido e configurado
    └── rpg-estado.md                   ✓ lido e configurado
```

Quando todos os itens estiverem marcados, você está pronto para jogar.
