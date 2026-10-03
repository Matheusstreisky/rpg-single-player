# Como Rodar o Sistema Localmente com DeepSeek + Ollama

Guia para rodar o mestre (Guardião no cthulhu, Narrador no vampiro) e os agentes de
memória inteiramente no seu computador, sem depender de APIs externas ou do Kiro como
plataforma de narração.

> **Vale para os dois sistemas.** Este guia é agnóstico de sistema: funciona tanto para
> `cthulhu/` (Call of Cthulhu 7ª Edição) quanto para `vampiro/` (Vampiro: A Máscara 5ª
> Edição). Onde um exemplo cita um sistema específico, troque o texto e os caminhos pela
> pasta do sistema que você vai jogar. Rode os comandos a partir da pasta do sistema
> escolhido (ex: `cd cthulhu` ou `cd vampiro`).

---

## Comparativo de modelos

Antes de escolher o caminho, entenda as diferenças entre as opções disponíveis:

| Modelo | Function Calling | Roda local? | Hardware necessário | Recomendado para |
|---|---|---|---|---|
| **DeepSeek R1** (oficial) | ❌ Não suportado | ✅ Sim | 8–48 GB VRAM | Apenas narração manual |
| **DeepSeek R1 + tool calling** (community) | ⚠️ Experimental | ✅ Sim | 8–48 GB VRAM | **Agentes automáticos — opção recomendada** |
| **DeepSeek V3 / V3-0324** | ✅ Suporte nativo | ❌ Não viável | ~160–400 GB RAM/VRAM | Curiosidade — hardware inviável localmente |

### Sobre o DeepSeek V3 local (por curiosidade)

O V3 é o modelo mais capaz da família DeepSeek e tem suporte nativo a function calling — o que permitiria agentes completamente automáticos com a mesma qualidade de modelos comerciais. O problema é tamanho: são 671 bilhões de parâmetros. Mesmo na quantização mais agressiva disponível (1.78-bit, via Unsloth), ocupa ~151 GB de memória. Na Q4 padrão, são ~400 GB. Isso exige múltiplas GPUs de alto nível ou servidores dedicados — completamente fora do alcance de um PC doméstico.

**Conclusão:** o V3 local é para quem tem infraestrutura de data center. Para uso doméstico, a versão via API é o caminho se quiser V3 com function calling.

### Opção recomendada para este guia

O **DeepSeek R1 destilado com suporte a tool calling**, mantido pela comunidade no Ollama Hub. Roda local, cabe em hardware comum, e tem function calling experimental funcional o suficiente para os agentes deste sistema.

---

## O que muda em relação ao Kiro

| Aspecto | Kiro + Claude | R1 com tool calling (local) |
|---|---|---|
| Qualidade de narração | Alta | Boa (depende do tamanho do modelo) |
| Agentes automáticos | ✅ Nativos via hooks | ⚠️ Experimental — funciona na maioria dos casos |
| Tool use (`fs_append`, etc.) | Nativo | Suporte via modelfile customizado |
| Janela de contexto | 200k tokens | 8k–32k (depende do modelo) |
| Custo | Por uso | Zero após hardware |
| Privacidade | Dados na nuvem | Tudo local |

O function calling experimental significa que ocasionalmente o modelo pode gerar a chamada de ferramenta em formato incorreto ou ignorar uma instrução. Se isso acontecer, rode o agente manualmente naquele turno (veja a seção de fallback no Passo 5).

---

## Requisitos de Software

### Obrigatório

| Software | Versão mínima | Para que serve |
|---|---|---|
| **Ollama** | 0.22.0+ | Motor que baixa e roda os modelos localmente |
| **Windows** | 10 ou 11 (64-bit) | Sistema operacional suportado |

### Opcional mas recomendado

| Software | Para que serve |
|---|---|
| **Open WebUI** | Interface gráfica estilo ChatGPT no navegador |
| **Docker Desktop** | Necessário para instalar o Open WebUI no Windows |

---

## Requisitos de Hardware

### Por tamanho de modelo (R1 com tool calling)

| Modelo | VRAM/RAM necessária | GPU de exemplo | Qualidade esperada |
|---|---|---|---|
| `r1-tool:7b` | 8 GB | RTX 3060, RX 6600 | Razoável — pode escorregar em contextos longos |
| `r1-tool:14b` | 12–16 GB | RTX 3080, RX 6800 XT | Boa — recomendada para este sistema |
| `r1-tool:32b` | 24 GB | RTX 3090, RTX 4090 | Muito boa — qualidade próxima de modelos comerciais |
| `r1-tool:70b` | 48 GB+ | Dois GPUs ou muita RAM | Excelente — inviável na maioria dos PCs |

> `r1-tool` é a abreviação usada neste guia para `MFDoom/deepseek-r1-tool-calling`. O nome completo é necessário apenas no comando `ollama pull` — veja o Passo 2.

> Se você não tem GPU dedicada, o Ollama roda na **CPU + RAM**. É lento, mas funciona. Para o 7b, você precisa de pelo menos 16 GB de RAM; para o 14b, 32 GB.

### Recomendação para este sistema

O **14b** é o mínimo viável para narração de RPG com múltiplos arquivos de contexto e agentes funcionando. O 7b serve para testar a instalação, mas tende a perder coerência em sessões longas.

---

## Passo 1 — Instalar o Ollama

1. Acesse [ollama.com](https://ollama.com) e baixe o instalador para Windows
2. Execute o `.exe` — não requer privilégios de administrador
3. O Ollama instala e sobe como serviço em segundo plano automaticamente
4. Confirme a instalação abrindo o PowerShell e rodando:

```powershell
ollama --version
```

Deve retornar algo como `ollama version 0.x.x`.

---

## Passo 2 — Baixar o modelo com tool calling

O modelo recomendado é o `MFDoom/deepseek-r1-tool-calling`, que é o DeepSeek R1 destilado com um modelfile customizado que habilita function calling:

```powershell
ollama pull MFDoom/deepseek-r1-tool-calling:14b
```

Tamanhos aproximados por versão:
- `:7b` — ~4.7 GB
- `:14b` — ~9 GB
- `:32b` — ~20 GB

Para testar se está funcionando:

```powershell
ollama run MFDoom/deepseek-r1-tool-calling:14b
```

Use `Ctrl+D` ou `/bye` para sair.

### Criando o modelo do mestre

Crie um `Modelfile` na pasta do sistema que você vai jogar (ex: `cthulhu/` ou `vampiro/`) para configurar o modelo com contexto estendido:

```
FROM MFDoom/deepseek-r1-tool-calling:14b
PARAMETER num_ctx 16384
SYSTEM """
Você é o mestre de uma campanha de RPG single-player.
Siga estritamente as instruções do arquivo config.md fornecido no início de cada sessão.
Narre sempre em segunda pessoa.
Mantenha coerência com todos os arquivos de contexto fornecidos.
Ao fim de cada turno, aguarde instrução do jogador antes de continuar.
"""
```

> Ajuste a primeira linha do `SYSTEM` ao seu sistema: *"Você é o Guardião de uma campanha
> de Call of Cthulhu 7ª Edição single-player."* para o cthulhu, ou *"Você é o Narrador de
> uma campanha de Vampiro: A Máscara single-player."* para o vampiro.

Registre o modelo customizado:

```powershell
ollama create rpg-narrator -f Modelfile
```

A partir daí, use sempre `rpg-narrator` ao invés do modelo base.

---

## Passo 3 — Instalar o Open WebUI (opcional)

O Open WebUI dá uma interface gráfica de chat no navegador — muito mais confortável do que o terminal para sessões longas.

### Pré-requisito: Docker Desktop

1. Acesse [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) e baixe o instalador
2. Instale e reinicie o computador se solicitado
3. Confirme com:

```powershell
docker --version
```

### Instalar o Open WebUI

Com o Ollama rodando em segundo plano:

```powershell
docker run -d -p 3000:80 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```

Acesse [http://localhost:3000](http://localhost:3000) no navegador. Na primeira vez, crie uma conta local (fica só na sua máquina). O Open WebUI detecta automaticamente o Ollama e lista os modelos disponíveis — incluindo o `rpg-narrator`.

---

## Passo 4 — Configurar os agentes como funções

Para que os agentes rodem automaticamente ao fim de cada turno, você precisa registrá-los como **ferramentas** no Open WebUI ou como scripts que o modelo pode chamar via Ollama.

### Opção A — Open WebUI Tools (mais simples)

O Open WebUI suporta ferramentas customizadas em Python. Crie uma ferramenta para cada operação de arquivo que os agentes usam:

> **Ajuste o caminho base.** Nos exemplos abaixo, troque `c:/Projetos/rpg-single-player/vampiro`
> pelo caminho da pasta do sistema que você está jogando (ex:
> `c:/Projetos/rpg-single-player/cthulhu`). Todos os caminhos de arquivo passados às
> ferramentas são relativos a essa pasta base.

1. No Open WebUI, acesse **Settings → Tools → Create Tool**
2. Crie as seguintes ferramentas:

**Ferramenta `append_file`:**
```python
def append_file(path: str, content: str) -> str:
    """Adiciona conteúdo ao final de um arquivo sem sobrescrever."""
    import os
    full_path = os.path.join("c:/Projetos/rpg-single-player/vampiro", path)
    with open(full_path, "a", encoding="utf-8") as f:
        f.write("\n" + content)
    return f"Conteúdo adicionado em {path}"
```

**Ferramenta `write_file`:**
```python
def write_file(path: str, content: str) -> str:
    """Sobrescreve um arquivo com novo conteúdo."""
    import os
    full_path = os.path.join("c:/Projetos/rpg-single-player/vampiro", path)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)
    return f"Arquivo {path} atualizado"
```

**Ferramenta `read_file`:**
```python
def read_file(path: str) -> str:
    """Lê o conteúdo de um arquivo."""
    import os
    full_path = os.path.join("c:/Projetos/rpg-single-player/vampiro", path)
    with open(full_path, "r", encoding="utf-8") as f:
        return f.read()
```

3. Com as ferramentas criadas, o modelo `rpg-narrator` pode chamá-las diretamente durante a conversa quando instruído pelos prompts dos agentes.

### Opção B — Execução manual como fallback

Se o function calling falhar num turno específico, rode o agente manualmente:

1. Abra uma nova conversa com `rpg-narrator`
2. Cole o prompt do agente correspondente (`agentes/rpg-acontecimentos.md`, etc.)
3. Cole o conteúdo dos arquivos relevantes
4. Copie a saída gerada e aplique nos arquivos manualmente

---

## Passo 5 — Estrutura de uma sessão

### Início de sessão

1. Abra o Open WebUI e selecione o modelo `rpg-narrator`
2. Ative as ferramentas `append_file`, `write_file` e `read_file` na conversa
3. Cole os arquivos de contexto na primeira mensagem:

```
[config.md]
<conteúdo do config.md>

[mundo/acontecimentos.md]
<conteúdo do acontecimentos.md>

[personagens/xunda/ficha.md]
<conteúdo da ficha>

[personagens/xunda/estado.md]
<conteúdo do estado>

---
Você é o mestre desta campanha. Sessão XX, Turno 01. Pode começar.
```

### Durante a sessão

Jogue normalmente. Ao fim de cada turno, escreva:

```
[FIM DO TURNO — rodar agentes]
```

O modelo deve chamar as ferramentas automaticamente para atualizar os arquivos. Se não chamar, use o fallback manual descrito no Passo 4, Opção B.

### Ao retomar após uma pausa

Carregue `acontecimentos.md` + os estados atuais para o modelo se situar antes de continuar.

---

## Problemas comuns

**Function calling não está sendo chamado automaticamente**
- Verifique se as ferramentas estão ativas na conversa (ícone de ferramentas no Open WebUI)
- Adicione explicitamente no prompt: `Ao fim de cada turno, use as ferramentas para atualizar os arquivos de memória.`
- Se persistir, use o fallback manual para aquele turno

**Modelo lento demais**
- Verifique onde o Ollama está rodando: `ollama ps` — deve mostrar GPU, não CPU
- Feche programas que consomem VRAM
- Troque para o modelo `:7b` para testar

**Out of memory (OOM)**
- Reduza o contexto no Modelfile: `PARAMETER num_ctx 8192`
- Recrie o `rpg-narrator` com `ollama create rpg-narrator -f Modelfile`

**Open WebUI não conecta ao Ollama**
- Confirme que o Ollama está no system tray do Windows
- Acesse `http://localhost:11434` — se aparecer `Ollama is running`, está OK
- Reinicie o container: `docker restart open-webui`

---

## Resumo do que você precisa instalar

```
[ ] Ollama          → ollama.com
[ ] Modelo          → ollama pull MFDoom/deepseek-r1-tool-calling:14b
[ ] Modelfile       → criar rpg-narrator (instruções no Passo 2)
[ ] Docker Desktop  → docker.com  (apenas se quiser Open WebUI)
[ ] Open WebUI      → docker run ... (comando no Passo 3)
[ ] Ferramentas     → criar append_file, write_file, read_file no Open WebUI (Passo 4)
```

Com isso, você tem um mestre de RPG com agentes automáticos rodando inteiramente no seu computador.
