# Qmd For Agent Knowledge Search

`qmd` is a local search tool for Markdown-heavy knowledge bases, notes, docs,
and meeting transcripts. Use it when plain `rg` is too literal and you need
retrieval over a curated local corpus.

## When To Use It

Prefer `qmd` when:

- you need semantic or hybrid search across docs, notes, and design records
- the repo has too much prose for ad hoc `rg` searches to stay precise
- you want structured search results for an agent or script
- you need to retrieve a document by search result, doc id, or glob

Prefer `rg` when:

- you already know the exact string, symbol, or file path
- you are searching code identifiers rather than a document corpus
- the repo has not been indexed into `qmd`

## Basic Setup

Create one or more collections:

```bash
qmd collection add . --name myproject
qmd collection add ~/notes --name notes
```

Add context where it improves retrieval quality:

```bash
qmd context add qmd://myproject "Repository docs and design notes"
qmd context add qmd://notes "Personal notes and meeting follow-ups"
```

Index and embed the corpus:

```bash
qmd update
qmd embed
```

## Search Workflow

Use the lightest query mode that fits:

```bash
qmd search "github token fallback"
qmd vsearch "how do we rotate credentials"
qmd query "why was this wrapper policy chosen"
```

For agent or script consumption, prefer structured output:

```bash
qmd query --json -n 10 "router observability"
qmd query --all --files --min-score 0.4 "agent planning"
```

Retrieve source documents after search:

```bash
qmd get "docs/architecture.md"
qmd get "#abc123"
qmd multi-get "docs/*.md" --json
```

## Agent Guidance

- Use `qmd` for document retrieval, not as a replacement for source-code search.
- Start with `qmd search` or `qmd query` to find likely documents, then read the
  returned files directly.
- Prefer `--json` or `--files` when passing results into another command or
  agent flow.
- Use `qmd get` after search instead of asking an agent to guess which file a
  result referred to.
- Refresh the index with `qmd update` and `qmd embed` when the corpus has
  changed materially.

## MCP

`qmd` also exposes an MCP server:

```bash
qmd mcp
qmd mcp --http
qmd mcp --http --daemon
```

Use MCP only when your agent/client already supports that integration cleanly.
For most terminal workflows, the CLI is enough and easier to debug.
