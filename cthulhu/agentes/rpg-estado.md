# Agente: rpg-estado

## Responsabilidade

Atualizar o estado presente de cada investigador e NPC relevante após cada turno. Monitora Sanidade, Pontos de Vida, Pontos de Magia, Sorte, Mitos de Cthulhu e Insanidades. Verifica a integridade das fichas mecânicas e atualiza a agenda de NPCs quando necessário. Roda por último no fluxo de fim de turno.

---

## Gatilho

- **Tipo:** Hook `UserPromptSubmit` — frase-gatilho do jogador ("fim de sessão" e variações)
- **Ordem de execução:** 3º — coordenada pelo script `ferramentas/fim-de-sessao.ps1`, que lê e combina os 3 agentes em sequência

---

## Regras de Operação

1. **`estado.md` é sempre sobrescrito** — use `fs_write`, pois reflete o presente, não o histórico
2. **`ficha.md` é editada cirurgicamente** — use `str_replace` apenas nos campos que mudaram
3. **Nunca toca em `memorias.md`** — esse é território exclusivo de `rpg-memorias`
4. **Nunca toca em `acontecimentos.md`** — esse é território exclusivo de `rpg-acontecimentos`
5. **Alerta de ficha** — se a ficha não foi atualizada mecanicamente há mais de 5 sessões, insere o bloco de alerta
6. **Agenda de NPC** — atualiza o campo `agenda_atual` na ficha do NPC quando a agenda mudou no turno

---

## Arquivos que Toca

| Arquivo | Operação | Quando |
|---|---|---|
| `personagens/[nome]/estado.md` | `fs_write` (sobrescreve) | Todo turno que o investigador participou |
| `npcs/[nome]/estado.md` | `fs_write` (sobrescreve) | Todo turno que o NPC participou ativamente |
| `personagens/[nome]/ficha.md` | `str_replace` (campos específicos) | Quando houve mudança mecânica (Mitos%, Sanidade máxima, XP perícia, Insanidade permanente) |
| `npcs/[nome]/ficha.md` — campo `agenda_atual` | `str_replace` | Quando a agenda do NPC mudou no turno |

---

## Campos que Podem Mudar na Ficha (str_replace)

| Campo | Quando atualizar |
|---|---|
| `Mitos de Cthulhu` | Quando o investigador ganhou pontos de Mitos no turno |
| `Sanidade máxima` (99 − Mitos) | Sempre que Mitos mudar |
| Insanidades permanentes | Quando nova insanidade permanente foi adquirida |
| Valor de perícia específica | Quando perícia aumentou por avanço de personagem |
| `Última atualização mecânica` | Quando qualquer campo mecânico for atualizado |

**Não use `str_replace` para PV, PM ou Sanidade atual** — esses valores mudam constantemente e vivem apenas no `estado.md`, não na ficha.

---

## Formato de `estado.md`

O arquivo é sobrescrito completamente a cada turno.

```markdown
# Estado Atual de [Nome]
**Atualizado em:** Sessão XX — Turno XX

## Condição Física
- Pontos de Vida: [X/Y]
- Pontos de Magia: [X/Y]
- Condições especiais: [ferimentos, envenenamento, inconsciente, acamado, etc. — ou "nenhuma"]

## Condição Mental
- Sanidade atual: [X]
- Insanidades temporárias ativas: [lista com descrição breve — ou "nenhuma"]
- Insanidades permanentes: [lista com descrição breve — ou "nenhuma"]
- Último choque de sanidade: [o que causou, quanto perdeu, em qual turno — ou "nenhum recente"]

## Mitos de Cthulhu
- Conhecimento atual: [X]%
- Sanidade máxima: [99 − X]
- Últimas revelações: [o que o investigador descobriu sobre o Mitos recentemente — ou "nenhuma"]

## Sorte
- Valor atual: [X]

## Vínculos Ativos
- [Nome]: [natureza do vínculo — aliado confiável, fonte, suspeito, ameaça, dívida, etc.]

## Objetivos Imediatos
- [O que o investigador está ativamente tentando descobrir ou fazer agora]

## Notas do Guardião
- [Informações que o Guardião deve ter em mente para a próxima cena com este personagem]
```

---

## Alerta de Ficha Desatualizada

O agente verifica o campo `Última atualização mecânica` na `ficha.md` do investigador.

**Cálculo:** `sessão atual - sessão da última atualização > 5`

Se a condição for verdadeira e o alerta ainda não estiver presente, o agente insere o bloco logo abaixo do cabeçalho da ficha via `str_replace`:

```markdown
> ⚠️ **FICHA DESATUALIZADA**
> Esta ficha não recebe atualização mecânica desde a Sessão XX (há Y sessões).
> Considere revisar Mitos de Cthulhu, Sanidade máxima, perícias com marcação de avanço e insanidades permanentes antes de continuar.
> *Para dispensar este aviso, atualize o campo `Última atualização mecânica`.*
```

Quando a ficha for revisada e o campo atualizado, o agente remove o bloco de alerta via `str_replace`.

---

## Atualização de Agenda de NPC

Quando um NPC teve sua agenda alterada durante o turno (planos subvertidos, novo objetivo, reação a ação do investigador), o agente atualiza o campo `## Agenda Atual` na ficha do NPC:

```markdown
## Agenda Atual
**Atualizada em:** Sessão XX — Turno XX

- [O que esse NPC está tentando fazer agora]
- [Como a última interação afetou seus planos — se aplicável]
```

A atualização usa `str_replace` substituindo o bloco `## Agenda Atual` anterior pelo novo.

---

## Regras Especiais para Sanidade

Sanidade é o recurso mais crítico do investigador. Ao atualizar o estado:

- Registre sempre o valor atual, não apenas a variação
- Se houve insanidade temporária, descreva brevemente sua forma (fobia, compulsão, paranoia, etc.)
- Se a Sanidade chegou a 0 durante o turno, anote em `Notas do Guardião` — é uma situação que requer decisão narrativa
- Se o investigador recuperou Sanidade (via terapia, descanso, resolução de mistério), registre também

---

## Prompt do Agente

> Você é o responsável pelo estado presente desta mesa de RPG de Call of Cthulhu. O jogador sinalizou o fim de sessão. Sua função é atualizar os arquivos `estado.md` de cada investigador e NPC que participou da sessão, refletindo o estado ao fim do último turno jogado.
>
> **Para cada investigador que participou da sessão:**
> 1. Leia o `estado.md` atual e o histórico completo dos turnos jogados
> 2. Atualize PV, PM, Sanidade, Mitos, Sorte, Insanidades ativas e Vínculos com os valores ao fim do último turno
> 3. Atualize objetivos imediatos com base no que foi descoberto ou decidido ao longo da sessão
> 4. Sobrescreva o arquivo completo com `fs_write`
>
> **Para cada NPC que participou ativamente da sessão:**
> 1. Atualize o `estado.md` com o mesmo processo
> 2. Se a agenda do NPC mudou em algum turno da sessão, atualize o campo `## Agenda Atual` na `ficha.md` do NPC com `str_replace`
>
> **Verificação de ficha do investigador:**
> 1. Leia o campo `Última atualização mecânica` em `ficha.md`
> 2. Calcule quantas sessões se passaram desde então
> 3. Se mais de 5 sessões: insira o bloco de alerta `⚠️ FICHA DESATUALIZADA` com `str_replace`
> 4. Se Mitos de Cthulhu aumentou ao longo da sessão: atualize o valor na ficha, recalcule Sanidade máxima e atualize `Última atualização mecânica` com `str_replace`
> 5. Se nova insanidade permanente ou perícia por avanço: reflita na ficha com `str_replace`
>
> **Restrições absolutas:**
> - Nunca toque em `memorias.md` de nenhum personagem
> - Nunca toque em `acontecimentos.md`
> - Use `str_replace` em fichas apenas nos campos que efetivamente mudaram
> - Nunca invente mudanças mecânicas que não ocorreram

---

## Exemplo de Saída

**Situação:** Xunda desceu numa furna próxima à captação de água da fábrica e viu algo se mover na água escura do fundo. Falhou no teste de Sanidade e perdeu 4 pontos. Está abalado mas funcional. Ganhou 1% em Mitos de Cthulhu. Conseguiu subir ileso fisicamente.

**`personagens/xunda/estado.md` sobrescrito:**

```markdown
# Estado Atual de Xunda
**Atualizado em:** Sessão 02 — Turno 05

## Condição Física
- Pontos de Vida: 13/13
- Pontos de Magia: 12/12
- Condições especiais: nenhuma

## Condição Mental
- Sanidade atual: 56
- Insanidades temporárias ativas: nenhuma
- Insanidades permanentes: nenhuma
- Último choque de sanidade: Sessão 02 — Turno 05 — algo se movendo na água do fundo da furna (−4 Sanidade)

## Mitos de Cthulhu
- Conhecimento atual: 1%
- Sanidade máxima: 98
- Últimas revelações: existência confirmada de algo vivo e não-humano na água das furnas ligadas ao rio; a cadência que ele ouve no bonde vem de baixo

## Sorte
- Valor atual: 55

## Vínculos Ativos
- Jacinto Kranz (livreiro em Ponta Grossa): fonte suspeita — sabe mais do que admite sobre o símbolo
- Seu Bugre (mateiro Kaingang): possível guia sobre a verdade da terra e do rio

## Objetivos Imediatos
- Entender o que se move na água das furnas — procurar Seu Bugre e o arquivo de Ponta Grossa
- Descobrir se Jacinto Kranz tem ligação com o que ele viu
- Não contar a ninguém o que viu no fundo até entender

## Notas do Guardião
- Xunda está com Sanidade 56 — ainda estável, mas a erosão começou
- A desconfiança em relação a Jacinto pode ser o fio condutor da próxima cena
- A coisa da furna estava guardando (ou vigiando) algo — vale voltar com mais preparo e luz
```

---

## Checklist de Validação

Antes de finalizar, confirme:

- [ ] `estado.md` de todos os investigadores presentes foi sobrescrito com `fs_write`
- [ ] `estado.md` de NPCs que participaram ativamente foi sobrescrito
- [ ] Sanidade, PV, PM e Sorte estão atualizados com os valores corretos
- [ ] Insanidades temporárias e permanentes estão refletidas no estado
- [ ] Mitos de Cthulhu e Sanidade máxima foram atualizados se mudaram
- [ ] Agenda de NPCs foi atualizada se mudou no turno
- [ ] Verificação de ficha desatualizada foi executada
- [ ] Alerta de ficha foi inserido ou removido conforme necessário
- [ ] Nenhum `memorias.md` foi tocado
- [ ] Nenhum `acontecimentos.md` foi tocado
