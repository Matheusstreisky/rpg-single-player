# Pendências

## P01 — Testes do arquivista para `memorias.md` dos NPCs

O Teste 5 (`como-testar-sistema.md`) usa apenas `acontecimentos.md` como arquivo sintético.
O arquivista também arquiva `memorias.md` de personagens e NPCs, mas esse caminho não é
testado. A lógica é a mesma, então o risco é baixo — mas é um gap formal na cobertura.

**O que fazer:** replicar as Fases A–E do Teste 5 usando um arquivo `memorias.md` sintético
em vez de `acontecimentos.md`, cobrindo pelo menos um personagem e um NPC.

---

## P02 — Adicionar regras dos sistemas de RPG nas pastas de cada sistema

Cada sistema (`vampiro/`, `cthulhu/`) deveria ter o seu respectivo documento de regras
(ou referência rápida de regras) dentro da própria pasta, para que o narrador/IA tenha
acesso durante a sessão sem precisar buscar em fonte externa.

**O que fazer:** criar `vampiro/regras.md` e `cthulhu/regras.md` com as regras relevantes
de cada sistema (mecânicas de dados, atributos, condições, testes, etc.), mantendo o padrão
de documentação do projeto.
