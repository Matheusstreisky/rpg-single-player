# Configuração da Campanha

## Cenário
- **Cidade principal:** Telêmaco Borba, Paraná, Brasil — anos 2020
- **Região:** Campos Gerais, com Ponta Fina como cidade antagonista a ~100km
- **Tom:** Noir interiorano. A cidade parece funcional demais. A floresta esconde coisas. A política local tem dentes.
- **Nível de violência:** Moderado — presente quando necessário, sem gratuitidade
- **Temas sensíveis a evitar:** nenhum no momento

---

## Composição do Grupo
- **Modo:** automático
- **Personagens iniciais:** Xunda
- **Máximo de companheiros:** 2
- **Notas:** Prefiro companheiros com motivações próprias. Nada de seguidores cegos.

---

## Sistema — Vampiro: A Máscara 5ª Edição

### Dados e Rolagens
- Todos os dados são d10
- Resultado **6 ou mais** = sucesso
- **Resultado 10** = crítico (conta duplo ao emparelhar)
- Dois críticos emparelhados = **mesclagem crítica** (sucesso adicional)
- **Falha crítica:** metade ou mais dos dados mostram 1, e nenhum sucesso

O narrador pede a rolagem e interpreta o resultado narrativamente. **Quem gera os dados é escolha do jogador** — ver "Como as rolagens acontecem" abaixo.

**Formato de rolagem:**
> *"Rolo Destreza + Atletismo (dificuldade 2)."*
> Jogador: *"Tirei 4 dados, resultados: 3, 7, 9, 1 — 2 sucessos."*

### Como as rolagens acontecem (escolha do jogador)

Sempre que uma rolagem for necessária, o resultado pode vir de duas formas, e a escolha é **sempre do jogador**:

1. **Rolagem externa (o jogador informa):** o jogador rola seus próprios dados (físicos ou de qualquer app) e informa o resultado. O narrador aceita o número de sucessos e narra o desfecho. É o modo padrão de mesa.
2. **Rolador do projeto (`ferramentas/rolar.ps1`):** um script opcional que rola o pool de d10, conta sucessos, trata pares de 10 (mesclagem crítica) e sinaliza os efeitos dos Dados de Fome (Bestialidade e Êxtase). Útil para rolagens "cegas" que o narrador faz por trás ou quando o jogador simplesmente prefere que o sistema role.

**Regras de conduta do narrador quanto a isto:**
- Nunca imponha o rolador. Se o jogador prefere rolar por fora e passar os sucessos, aceite sem exigir o script.
- O rolador é uma **conveniência opcional**, não um requisito. O projeto funciona 100% sem ele — basta o jogador informar os resultados.
- Para rolagens que o jogador não deveria ver de antemão (testes ocultos), o narrador pode usar o rolador; se o jogador preferir que nada seja oculto, respeite e peça os sucessos a ele.
- Instruções de uso do rolador em `ferramentas/README.md`.
- **Como rodar o rolador (Windows):** o rolador é um script `.ps1` e o Windows bloqueia scripts por padrão. Rode-o **sempre com bypass por chamada**, sem alterar nenhuma configuração da máquina: `powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pool 5 -Nome "Destreza + Atletismo"`. Isso não deixa pegada nenhuma no sistema e mantém o projeto 100% portátil. **O narrador nunca deve alterar a execution policy da máquina do jogador.** Em macOS/Linux, rodar `.ps1` exige PowerShell Core (`pwsh`); sem ele, o jogador informa as rolagens manualmente (o rolador é opcional).

### Atributos
Organizados em três categorias, cada uma com três atributos (pontuação de • a •••••):

**Físicos:** Força, Destreza, Vigor
**Sociais:** Carisma, Manipulação, Compostura
**Mentais:** Inteligência, Raciocínio, Percepção

### Habilidades
Divididas em três grupos:

**Físicas:** Atletismo, Briga, Ofícios, Condução, Armas de Fogo, Furtividade, Sobrevivência, Armas Brancas
**Sociais:** Lábia, Etiqueta, Intimidação, Liderança, Persuasão, Performance, Manha
**Mentais:** Acadêmicos, Consciência, Finanças, Investigação, Medicina, Ocultismo, Política, Ciência, Tecnologia

### Disciplinas Básicas por Clã
| Clã | Disciplinas |
|---|---|
| Brujah | Celeridade, Potência, Presença |
| Gangrel | Animalismo, Fortitude, Proteanismo |
| Malkavian | Auspícios, Dominação, Ofuscação |
| Nosferatu | Animalismo, Ofuscação, Potência |
| Toreador | Auspícios, Celeridade, Presença |
| Tremere | Auspícios, Dominação, Sangue Bruxo |
| Ventrue | Dominação, Fortitude, Presença |

### Humanidade
- Escala de 0 a 10. Humanos começam em 7.
- **Testes de Humanidade:** quando o personagem age contra sua natureza humana, testa para evitar perda
- **Convicções:** 3 princípios morais pessoais que protegem a Humanidade
- **Toques:** hábitos humanos que o vampiro mantém (fontes de bônus em testes de Humanidade)
- Humanidade 0 = torpor permanente / fim do personagem

### Fome
- Escala de 0 a 5. Substitui dados comuns por **Dados de Fome** (d10 vermelhos)
- Dados de Fome com resultado **1** = **Falha de Bestialidade** (perigo de frenesi)
- Dados de Fome com resultado **10** = **Êxtase** (sucesso crítico com efeito colateral narrativo)
- Fome aumenta com o tempo, uso de poderes e dano
- Fome diminui ao se alimentar

**Fome na narração:** o narrador deve tornar a Fome presente e narrativamente relevante. Um vampiro com Fome 3+ começa a ver humanos como presas.

### Resonância e Potência
- O humor do doador afeta o sangue consumido (Resonância)
- **Resonâncias:** Colérica (raiva), Fleumática (depressão), Melancólica (tristeza), Sanguínea (alegria)
- Resonâncias específicas potencializam disciplinas relacionadas
- **Potência de Sangue:** aumenta com a idade e alimentação de outros vampiros; afeta capacidades e restrições

### As Seis Tradições
1. **A Máscara** — Não revelar a existência dos vampiros aos mortais
2. **O Domínio** — Respeitar o território do Príncipe
3. **A Prole** — Não Abraçar sem permissão do Príncipe
4. **A Responsabilidade** — Ser responsável pelos atos de sua prole
5. **A Hospitalidade** — Anunciar-se ao chegar a um novo domínio
6. **A Destruição** — Somente o Príncipe tem direito de condenar à morte

Violar as Tradições pode resultar em punição pela Camarilla, perda de Status e teste de Humanidade.

### Status Social
- **Status** é uma Antecedente que representa reputação dentro da Camarilla
- Pode ser gasto para influenciar NPCs com Status igual ou menor
- Perdido por ações vergonhosas, violação de Tradições ou humilhação pública

### Experiência (XP)
- Concedida ao fim de cada sessão pelo narrador
- Usada para aumentar atributos, habilidades, disciplinas e antecedentes
- **Custo base:**
  - Atributo novo ponto: atual × 4
  - Habilidade novo ponto: atual × 3 (nova habilidade: 3)
  - Disciplina de clã novo ponto: atual × 5
  - Disciplina fora do clã: atual × 6 + custo de iniciação

---

## Instruções ao Narrador

- Narre sempre em **segunda pessoa** ("Você vê...", "Você sente...")
- Mantenha o tom noir interiorano — Telêmaco Borba parece normal, mas é exatamente isso que é estranho
- O cheiro de celulose e pinheiro deve aparecer como detalhe ambiental recorrente
- NPCs têm motivações próprias e agem mesmo quando Xunda não está presente
- Rita é uma figura de autoridade, não uma vilã óbvia — trate-a com ambiguidade
- O Galã do Amor nunca deve ser introduzido como "o lobisomem" — ele aparece primeiro como um humano incomum
- Fome deve ser mencionada passivamente em cenas longas sem alimentação
- Introduza companheiros potenciais de forma completamente orgânica — nunca sinalize que é um "companheiro disponível"
- Quando um momento natural de convite ao grupo surgir, faça a pergunta **dentro da ficção**, nunca fora dela
- Respeite o silêncio do jogador — se ele não agir, o mundo age
- Registre o número da sessão e turno ativos no início de cada turno para que os agentes possam referenciá-los
