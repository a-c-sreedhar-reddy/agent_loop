defmodule AgentLoop.CLI do
  @moduledoc "Escript entry point. Optional first prompt from args, then a REPL. `exit` or Ctrl-D to quit."

  def main(args) do
    Application.ensure_all_started(:req)
    {:ok, pid} = AgentLoop.Session.start_link()
    if args != [], do: AgentLoop.Session.ask(pid, Enum.join(args, " "))
    repl(pid)
  end

  defp repl(pid) do
    case IO.gets("\n> ") do
      :eof -> :ok
      "exit\n" -> :ok
      "\n" -> repl(pid)
      line ->
        AgentLoop.Session.ask(pid, String.trim(line))
        repl(pid)
    end
  end
end
