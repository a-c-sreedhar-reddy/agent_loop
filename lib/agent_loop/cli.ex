defmodule AgentLoop.CLI do
  @moduledoc "Escript entry point: `agent_loop <prompt words...>`."

  def main(args) do
    Application.ensure_all_started(:req)
    {:ok, pid} = AgentLoop.Session.start_link()
    AgentLoop.Session.ask(pid, Enum.join(args, " "))
  end
end
