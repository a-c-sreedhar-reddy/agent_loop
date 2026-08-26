defmodule AgentLoop.CLI do
  def main(args) do
    Application.ensure_all_started(:req)
    AgentLoop.run(Enum.join(args, " "))
  end
end
