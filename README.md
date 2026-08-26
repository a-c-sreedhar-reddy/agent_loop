# agent_loop

A coding agent in ~100 lines of Elixir. Three tools, one recursive function.

```sh
export ANTHROPIC_API_KEY=...
mix deps.get
mix run -e 'AgentLoop.run("list the files here and tell me what this project is")'
```

Or as a binary: `mix escript.build && ./agent_loop "fix the failing test"`.

## Where the loop is
`lib/agent_loop.ex` — read that first. Everything else is plumbing.

## Next steps (pick one)
- Wrap `run/1` in a GenServer so a conversation survives across prompts
- Spawn subagents with `Task.async_stream` — the model calls a `spawn_agent` tool
- Stream tokens (`Req` + SSE) instead of waiting for the full response
- Add a permission gate before `bash` runs
