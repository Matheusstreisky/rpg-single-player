# Primeiros Passos — Criando sua Campanha

Guia para montar uma campanha de RPG single-player usando este sistema com o Kiro como Guardião.

---

## O que você vai precisar

- Kiro IDE instalado
- Esta estrutura de pastas (descrita em `arquitetura.md`)
- Vontade de investigar o que não deveria existir

Não é necessário nenhum conhecimento técnico além de editar arquivos de texto.

---

## Passo 1 — Configure a campanha

Crie o arquivo `config.md` na raiz do projeto. Ele é o contrato entre você e o Guardião — define o tom, as regras e as expectativas da campanha.

```markdown
# Configuração da Campanha

## Cenário
- **Cidade e época:** [ex: Telêmaco Borba / Ponta Grossa, PR — 1959 | Rio de Janeiro — 1920s | São Paulo contemporâneo]
- **Tom:** [investigativo / horror puro / pulp / noir / etc.]
- **Nível de violência:** [leve / moderado / sem restrições]
- **Temas que prefiro evitar:** [liste aqui]

## Composição do Grupo
- **Modo:** [manual / automático]
- **Personagens iniciais:** [nome do investigador]
- **Máximo de companheiros:** [número — ou "sem limite"]

## Instruções ao Guardião
- [Qualquer instrução específica sobre como você quer que o Kiro narre]
- [Ex: "Prefiro narrações em segunda pessoa", "Quero que a morte do investigador seja possível mas não fácil"]
```

---

## Passo 2 — Crie seu investigador

Crie a pasta `personagens/[nome]/` e os três arquivos dentro dela.

### `ficha.md`

```markdown
# Ficha de [Nome]
**Última atualização mecânica:** Sessão 00

## Identidade
- **Nome completo:**
- **Ocupação:**
- **Idade:**
- **Residência:**
- **Local de Origem:**

## Características
| Característica | Valor | Metade | Quinto |
|---|---|---|---|
| Força (FOR) | | | |
| Constituição (CON) | | | |
| Tamanho (TAM) | | | |
| Destreza (DES) | | | |
| Aparência (AP) | | | |
| Inteligência (INT) | | | |
| Poder (POD) | | | |
| Educação (EDU) | | | |

## Valores Derivados
| Valor | Resultado |
|---|---|
| Pontos de Vida (PV) | (CON+TAM)/10 |
| Pontos de Magia (PM) | POD/5 |
| Sanidade inicial | POD |
| Sorte | |
| Bônus de Dano | |
| Construção | |

## Perícias
### Investigativas
| Perícia | Valor base | Valor atual |
|---|---|---|
| Biblioteca | 20% | |
| Investigar | 20% | |
| Escutar | 20% | |
| Psicologia | 10% | |
| Ocultismo | 5% | |
| História | 5% | |
| Mitos de Cthulhu | 0% | |

### Sociais
| Perícia | Valor base | Valor atual |
|---|---|---|
| Charme | 15% | |
| Intimidar | 15% | |
| Persuadir | 10% | |
| Lábia | 5% | |

### Físicas / Combate
| Perícia | Valor base | Valor atual |
|---|---|---|
| Briga | 25% | |
| Esquivar | DES/2 | |
| Arma de Fogo (Pistola) | 20% | |
| Escalar | 20% | |
| Furtividade | 20% | |

### Outras
[Liste perícias de ocupação e interesse pessoal aqui]

## Sanidade
- **Sanidade atual:** [igual a POD]
- **Sanidade máxima:** 99
- **Mitos de Cthulhu:** 0%

## Insanidades Registradas
- nenhuma

## Feitiços Conhecidos
- nenhum

## Equipamento Principal
[Armas, ferramentas, documentos importantes]

## Background
[Quem é este investigador. O que o levou a investigar o sobrenatural.
Um medo central. Um objetivo de longo prazo. Um segredo.]
```

### `memorias.md`

Começa vazio, com apenas o cabeçalho:

```markdown
# Memórias de [Nome]

## Índice

---
```

### `estado.md`

Estado inicial do investigador:

```markdown
# Estado Atual de [Nome]
**Atualizado em:** Sessão 00

## Condição Física
- Pontos de Vida: [PV máximo]/[PV máximo]
- Pontos de Magia: [PM máximo]/[PM máximo]
- Condições especiais: nenhuma

## Condição Mental
- Sanidade atual: [igual a POD]
- Insanidades temporárias ativas: nenhuma
- Insanidades permanentes: nenhuma
- Último choque de sanidade: nenhum

## Mitos de Cthulhu
- Conhecimento atual: 0%
- Sanidade máxima: 99
- Últimas revelações: nenhuma

## Sorte
- Valor atual: [Sorte inicial]

## Vínculos Ativos
[Nenhum ainda — será preenchido conforme a campanha avança]

## Objetivos Imediatos
- [O que o investigador quer descobrir ou fazer no início da história]

## Notas do Guardião
[Vazio no início]
```

---

## Passo 3 — Prepare o mundo

### `mundo/mundo.md`

Descreva o cenário onde a campanha acontece. Não precisa ser extenso no início — vá expandindo conforme jogar.

```markdown
# O Mundo

## A Cidade
[Descrição geral — atmosfera, bairros importantes, o cotidiano antes do horror]

## O Horror Subjacente
[O que está acontecendo por baixo da superfície — apenas o suficiente para começar]

## Facções e Organizações
[Grupos que o investigador pode encontrar — cultos, sociedades secretas, grupos de resistência]

## Locais Importantes
[Pontos de investigação potencial — onde as pistas podem estar]

## NPCs Menores
[Figurantes, contatos, conhecidos sem papel narrativo central ainda]
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

Hooks são automações do Kiro que disparam em eventos específicos. Neste sistema, os três agentes usam o trigger `Stop` — ou seja, rodam automaticamente quando o Guardião encerra uma resposta.

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

- **`config.md`** — define tom, modo de grupo, limites narrativos e instruções ao Guardião. É o principal ponto de personalização por campanha.
- **Arquivos em `/agentes/`** — contêm as regras fixas de cada agente. Edite aqui apenas se quiser mudar o comportamento estrutural (ex: mudar critérios de evento marcante, adicionar novos campos ao `estado.md`).

Você **não precisa criar novos agentes** — os três arquivos em `/agentes/` já são a definição completa do sistema. Os hooks apenas os ativam.

---

## Passo 5 — Comece a investigar

Abra uma **sessão Vibe** no Kiro (não Spec). Forneça os arquivos de contexto no início do chat usando `#File`:

```
#File config.md
#File mundo/mundo.md
#File mundo/acontecimentos.md
#File personagens/[nome]/ficha.md
#File personagens/[nome]/estado.md
```

Depois escreva a instrução de início:

> *"Você é o Guardião desta campanha de Call of Cthulhu 7ª Edição. Leia os arquivos fornecidos para entender o cenário, as regras e o investigador. Meu personagem é [nome]. Pode começar a primeira cena — deixo a situação inicial a seu critério com base no que leu."*

Ou, se preferir definir a situação:

> *"Você é o Guardião desta campanha. Começamos com [nome] em [lugar], [situação]. Sessão 01, Turno 01."*

---

## Iniciando com esta campanha (Xunda em Telêmaco Borba / Ponta Grossa, 1959)

Se você está usando os arquivos de exemplo já criados, o contexto de início é:

```
#File config.md
#File mundo/mundo.md
#File mundo/acontecimentos.md
#File personagens/xunda/ficha.md
#File personagens/xunda/estado.md
```

Mensagem de início sugerida:

> *"Você é o Guardião desta campanha de Call of Cthulhu 7ª Edição. Leia os arquivos fornecidos. Meu investigador é Xunda — mecânico de manutenção da fábrica da Klabin, na Cidade Nova (futura Telêmaco Borba), Paraná, 1959. Pode começar a Sessão 01, Turno 01 onde achar mais interessante com base no que leu."*

---

## Dicas para uma boa campanha

**Sobre o contexto**
- Carregue apenas os arquivos relevantes para a cena. Quanto menos contexto desnecessário, melhor a qualidade da narração.
- Em cenas com NPCs importantes, carregue a ficha e as memórias deles também.
- Ao retomar após uma pausa longa, carregue `acontecimentos.md` + estados atuais para o Guardião se situar.

**Sobre o investigador**
- Quanto mais detalhado o background inicial, mais o Guardião tem para trabalhar.
- Defina ao menos um segredo, um medo e uma conexão humana que o investigador não quer perder.
- Conexões humanas (família, amigos, amores) são a Sanidade em forma de narrativa — o Guardião pode usá-las como âncora e como pressão.

**Sobre a narrativa**
- Os agentes de memória trabalham melhor quando você sinaliza o fim de um turno claramente.
- Eventos marcantes são detectados automaticamente, mas você pode sinalizar manualmente: *"Isso foi um momento importante para o Xunda."*
- Se quiser revisar o que foi registrado, leia `acontecimentos.md` — é o log mais limpo do que aconteceu.
- A morte do investigador é possível. Se acontecer, `primeiros-passos.md` tem o template para criar um novo.

**Sobre a Sanidade**
- Acompanhe o valor atual em `estado.md`. Um investigador com Sanidade baixa começa a perceber o mundo de forma diferente.
- Insanidades temporárias são oportunidade narrativa, não punição. Deixe o Guardião interpretá-las com drama.
- Mitos de Cthulhu crescendo é sinal de que o investigador está chegando perto da verdade — e pagando o preço.

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

Quando todos os itens estiverem marcados, você está pronto para investigar.
