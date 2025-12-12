name: conversation-logging
description: Use when running Claude/Superpowers chats that could lose state or need to resume later – enforces per-turn logging into docs/conversations/chat-XXXXXX.md files with padded numbering, new-file-by-default behavior, and explicit continuation rules when asked to keep a specific chat number.

# Conversation Logging

## Overview
Losing session context is expensive. This skill forces you to journal every Claude/Superpowers turn into numbered Markdown files so you can resume any chat after disconnects, restarts, or handoffs.

## When to Use
- Connectivity is flaky, browser crashed, or Superpowers session might drop
- Multi-step or multi-day conversations that you may need to resume
- Partner asks to “continuar o chat 000123” or similar
- Any time you want an auditable trail of prompts, replies, and plans

## Core Pattern
1) Start new chats in `docs/conversations/chat-XXXXXX.md`, zero-padded to 6 digits, always incrementing unless explicitly told to continue a numbered chat.  
2) For continuations, append to the specified file; never re-use another file number.  
3) Log every turn imediatamente: timestamp (formato `YYYY-MM-DDTHH:MM:SS` sem fuso), quem falou (emoji: 🙋 para user, 🤖 para assistant), texto completo e breve resumo.  
4) Close with a quick recap and any open TODOs.

## Quick Reference
- **Novo chat**: compute next id, create `docs/conversations/chat-XXXXXX.md`, add header (started timestamp, topic/context).  
- **Continuar chat N**: open `docs/conversations/chat-00NNNN.md`, append new table rows, keep numbering (implícito) increasing.  
- **Turno**: adicionar `<tr><td>🙋|🤖</td><td>YYYY-MM-DDTHH:MM:SS</td><td>texto (use <br> para quebras)</td></tr>` dentro de uma única `<table>` com cabeçalho `Quem? | Data | Texto`.  
- **Finalizar**: opcional `## Recap` após a tabela com estado + TODOs.

## Implementation Steps
1) If `docs/conversations` is missing, create it.  
2) **Determine file**  
   - If partner says “continuar chat <id>”, use `docs/conversations/chat-<id>.md` (pad to 6 digits).  
   - Otherwise, set `next_id` to last existing number + 1 (0 if none), padded to 6, file `docs/conversations/chat-<next_id>.md`.  
3) **Initialize new file** (only for new chats): title with chat number/topic, `Started: <ISO timestamp>`, `Context`, `Who requested`, then open a single HTML table with header (`Quem?`, `Data`, `Texto`).  
4) **Log each turn immediately** (não deixe para o fim):  
   - Append `<tr><td>🙋|🤖</td><td>YYYY-MM-DDTHH:MM:SS</td><td>texto completo (use <br> para múltiplas linhas) + Resumo: ...</td></tr>`  
   - Keep all turns in the same `<tbody>`; preserve order.  
5) **Close session**: add `## Recap` capturing current state, decisions, open TODOs, and “Next to pick up” instructions.  
6) If asked to continue later, re-open the same file and keep numbering; never start a new file for a requested continuation.

## Example (shell + skeleton)
```sh
# Novo chat
last_id=$(ls docs/conversations/chat-*.md 2>/dev/null | sed -E 's/.*chat-([0-9]+)\.md/\1/' | sort -n | tail -1)
next_id=$(printf "%06d" $(( ${last_id:-0} + 1 )))
file="docs/conversations/chat-$next_id.md"
cat <<EOF > "$file"
# Chat $next_id - <tema>
- Started: $(date -Iseconds)
- Contexto: <resumo curto>

- Who requested: user

<table>
  <thead>
    <tr><th>Quem?</th><th>Data</th><th>Texto</th></tr>
  </thead>
  <tbody>
    <tr><td>🙋</td><td>$(date -Iseconds | sed 's/[+-][0-9:]*$//')</td><td><texto completo><br>Resumo: <1-3 linhas></td></tr>
    <tr><td>🤖</td><td>$(date -Iseconds | sed 's/[+-][0-9:]*$//')</td><td><texto completo><br>Resumo: <plano + pontos-chave></td></tr>
  </tbody>
</table>
EOF
```
To continue chat `000042`, append new `<tr>...</tr>` rows inside the existing `<tbody>` in `docs/conversations/chat-000042.md` (order preserved).

## Rationalizações comuns (e por que ignorá-las)
| Desculpa | Realidade |
| --- | --- |
| “A conversa é curta, lembro de cabeça” | Reconstruções perdem nuance; logar leva menos de 1 minuto. |
| “Anoto no final” | Quedas de conexão tornam impossível recuperar; logue a cada turno. |
| “Vou usar o mesmo arquivo, mais simples” | Mistura sessões e quebra continuidade; cada chat tem seu número. |
| “Posso pular a numeração” | Números ordenados são a chave para retomar; padronize 6 dígitos sempre. |

## Red Flags — pare e registre agora
- Rede instável ou janela do navegador pesada
- Conversa extensa com múltiplas decisões ou TODOs
- Pedido explícito para continuar um chat numerado
- Vontade de “anotar depois” ou reutilizar um arquivo anterior

## Common Mistakes
- Esquecer de padronizar 6 dígitos (gera conflitos)  
- Não incrementar `Turn NN`, dificultando retomada  
- Não registrar plano/decisões no bloco do assistant  
- Iniciar novo arquivo quando foi pedido “continuar chat <id>”
