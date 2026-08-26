defmodule AgentLoop.CLI do
  @moduledoc "Escript entry point. Optional first prompt from args, then a REPL. `exit` or Ctrl-D to quit."

  def main(args) do
    Application.ensure_all_started(:req)
    ensure_api_key()
    {:ok, pid} = AgentLoop.Session.start_link()
    if args != [], do: AgentLoop.Session.ask(pid, Enum.join(args, " "))
    repl(pid)
  end

  defp ensure_api_key do
    if System.get_env("ANTHROPIC_API_KEY") in [nil, ""] do
      key = IO.gets("ANTHROPIC_API_KEY not set. Paste key: ") |> to_string() |> String.trim()
      if key == "", do: (IO.puts("no key, bye"); System.halt(1))
      System.put_env("ANTHROPIC_API_KEY", key)
    end
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
