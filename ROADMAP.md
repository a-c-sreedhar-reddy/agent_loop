# Roadmap

Rule from my own GitHub history: person + tiny scope + post it. Every finished project 2016–2020 was a
weekend thing for a specific person, pushed with a one-line description. Everything longer than a week died.
Keep that rule.

## Done
- [x] Agent loop: model emits `tool_use`, we run it, send `tool_result` back with the matching id
- [x] `Session` GenServer — state is the message history, one process per conversation
- [x] Tools: bash, read_file, edit_file, spawn_agent
- [x] Parallel tool execution via `Task.async_stream`
- [x] Subagents = `spawn_agent` starts a fresh Session process
- [x] escript REPL (`./agent_loop`), prompts for API key if unset
- [x] Pushed to GitHub. Tweeted.

## Next (in order, each one small)

### 1. Permission gate — tonight, 5 lines
`IO.gets("run `#{cmd}`? [y/N]")` before `bash`. Decline → return `{:error, "user declined"}`; the model adapts.
Enforcement lives in `Tools.exec`, not the system prompt. *You are the sandbox.*

### 2. Telegram bot — weekend
- `@BotFather` → `/newbot` → token. Free, no approval.
- `Telegram` GenServer: poll `getUpdates` every ~2s, `sendMessage` to reply. Two `Req` calls, ~40 lines.
- Map `chat_id → Session pid`. Each chat is its own conversation.
- **Allowlist of chat_ids.** It's my laptop on the other end.
- Runs only while my Mac is up. That's fine — it's a remote control for my Mac from my phone.

### 3. Per-session workspace + per-user tools
- Each session gets `sessions/<chat_id>/`. System prompt says "work only here" (the sign on the door).
- `Tools.exec` enforces it (the lock): `Path.expand(path, workspace)` must start with `workspace`;
  `System.cmd(..., cd: workspace)`.
- Me: full tools incl. bash. Cousins: read_file / edit_file / maybe a sandboxed `python` — no bash.
  Same Session, different `tools:` in state.

### 4. Persist history to disk
Dump `messages` to `data/<chat_id>.json` after each turn; load in `init`. Restart → still remembers.
First thing cousins will notice if it's missing.

### 5. `/reset` command
Kill that chat's session pid, delete its file. Trivial; people will ask.

**→ Share the bot with cousins after 4 and 5.** Watch what they ask. The next items come from them.

### 6. Cost visibility
Log `usage.input_tokens` / `output_tokens` per turn to a file. Several people on Opus adds up.

### 7. Compaction
Long chats blow the context window. Server-side beta header `compact-2026-01-12`; keep echoing the full
`content` back (compaction blocks live in it). Do this when it bites, not before.

### 8. Supervisor tree
`DynamicSupervisor` for sessions so a subagent crash doesn't take the parent down. `start` vs `start_link`.
Depth counter in state to cap recursive `spawn_agent`.

## Later / when bored
- **LiveView dashboard on localhost** — every live session, who's chatting, message count, tokens, click to
  read the conversation. First LiveView. Elixir's best trick, over GenServers that already exist.
- **Streaming (SSE)** — `stream: true`, reduce `content_block_start/delta/stop` events back into the same
  `%{content, stop_reason}` shape so `Session.loop` doesn't change. Tool input arrives as JSON string
  fragments; join and decode at `content_block_stop`. Skipped for now — polish, not substance.
- Raycast scripts as tools — let the agent drive the Mac.
- Advent of Code in December, new language. Haven't missed one 2020–2022; missed 2023–2025.

## Not doing
- Hosting (Fly etc.) — everything local for now.
- WhatsApp — needs Meta business approval. Telegram is free and instant.

## Reminders to self
- The model never executes anything. It's stateless. "Memory" is resending history.
- Everything Claude Code does — permissions, subagents, hooks — happens between receiving `tool_use` and
  sending `tool_result`.
- GenServer isn't for "remembering history"; it's for "this conversation is a living process other
  processes talk to." Needed the moment there are subagents, a UI, or streaming.
- If it's day 3 and not done, push what exists and stop.
- Tweet when something works. Posting is the half of the loop I've skipped for 2 years.
