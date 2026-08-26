defmodule AgentLoop do
  @moduledoc """
  The whole agent, in one recursive function.

      messages = [user prompt]
      loop:
        response = Claude(messages, tools)
        if no tool_use -> print text, stop
        run each tool, append results, recurse
  """

  alias AgentLoop.{Claude, Tools}

  @system """
  You are a coding agent running in #{File.cwd!()}.
  Use the tools to inspect and change files. Be terse.
  """

  def run(prompt) when is_binary(prompt) do
    run([%{role: "user", content: prompt}])
  end

  def run(messages) do
    response = Claude.chat(messages, system: @system, tools: Tools.specs())
    content = response["content"]

    print_text(content)

    case response["stop_reason"] do
      "tool_use" ->
        results =
          content
          |> Enum.filter(&(&1["type"] == "tool_use"))
          |> Enum.map(&Tools.exec/1)

        # Assistant content goes back *unchanged* (thinking blocks included);
        # all tool_results go in ONE user message.
        run(messages ++ [%{role: "assistant", content: content}, %{role: "user", content: results}])

      _ ->
        :done
    end
  end

  defp print_text(content) do
    for %{"type" => "text", "text" => t} <- content, do: IO.puts(t)
  end
end
