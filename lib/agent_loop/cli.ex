defmodule AgentLoop.CLI do
  @moduledoc "Escript entry point: `agent_loop <prompt words...>`."

  @doc """
  Boots the HTTP client and runs the agent with all CLI args joined as the prompt.
  """
  def main(args) do
    Application.ensure_all_started(:req)
    AgentLoop.run(Enum.join(args, " "))
  end
end
