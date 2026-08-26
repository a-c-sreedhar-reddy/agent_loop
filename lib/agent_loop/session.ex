defmodule AgentLoop.Session do
  use GenServer
  alias AgentLoop.{Claude, Tools}

  @system """
  You are a coding agent running in #{File.cwd!()}.
  Use the tools to inspect and change files. Be terse.
  """

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, [])
  def ask(pid, prompt), do: GenServer.call(pid, {:ask, prompt}, :infinity)

  # state = messages
  def init(_), do: {:ok, []}

  def handle_call({:ask, prompt}, _from, messages) do
    messages = loop(messages ++ [%{role: "user", content: prompt}])
    {:reply, :ok, messages}
  end

  defp loop(messages) do
    resp = Claude.chat(messages, system: @system, tools: Tools.specs())
    content = resp["content"]
    for %{"type" => "text", "text" => t} <- content, do: IO.puts(t)
    messages = messages ++ [%{role: "assistant", content: content}]

    case resp["stop_reason"] do
      "tool_use" ->
        tool_uses = Enum.filter(content, &(&1["type"] == "tool_use"))

        results =
          tool_uses
          |> Task.async_stream(&Tools.exec/1, timeout: :infinity, ordered: true)
          |> Enum.map(fn {:ok, r} -> r end)

        loop(messages ++ [%{role: "user", content: results}])

      _ ->
        messages
    end
  end
end
