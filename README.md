# agent_loop

A coding agent in ~150 lines of Elixir. One GenServer per conversation, four tools, subagents via `Task.async_stream`.

```
lib/agent_loop/session.ex  ← the loop. A GenServer whose state is the message history.
lib/agent_loop/tools.ex    ← bash, read_file, edit_file, spawn_agent
lib/agent_loop/claude.ex   ← POST /v1/messages
lib/agent_loop/cli.ex      ← escript REPL
```

## Run

```sh
export ANTHROPIC_API_KEY=sk-ant-...   # or skip this and the CLI will ask for it
mix deps.get
mix escript.build
./agent_loop                          # REPL; `exit` or Ctrl-D to quit
./agent_loop "what's in lib/?"        # first prompt from args, then REPL
```

Or in iex:

```sh
iex -S mix
```

```elixir
{:ok, pid} = AgentLoop.Session.start_link()
AgentLoop.Session.ask(pid, "what's in lib/?")
AgentLoop.Session.ask(pid, "add a test for edit_file")   # same pid = same history
AgentLoop.Session.ask(pid, "spawn two agents: review tools.ex and session.ex for bugs, merge findings")
```

## How it works

```
messages = [user prompt]
loop:
  response = Claude(messages, tools)
  if stop_reason != "tool_use" → done
  run every tool_use concurrently, collect tool_results
  messages += [assistant response, user tool_results]
```

- The model never executes anything — it emits `tool_use` blocks, we run them and send back `tool_result` with the matching id.
- The model is stateless; "memory" is resending the full history every call.
- `spawn_agent` starts a fresh `Session` process and asks it the task. Parallel `spawn_agent` calls run as parallel BEAM processes.
- A tool error goes back as `is_error: true`; the model adapts. A crash kills only that session process.

## Not done yet
- Permission gate before `bash`
- Streaming (SSE) output
- Supervisor / `DynamicSupervisor` for sessions so a subagent crash doesn't take the parent down
- Depth limit on recursive `spawn_agent`
