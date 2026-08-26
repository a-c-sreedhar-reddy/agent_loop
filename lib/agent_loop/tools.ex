defmodule AgentLoop.Tools do
  @moduledoc "Tool definitions (sent to Claude) and their executors (run locally)."

  def specs do
    [
      %{
        name: "bash",
        description: "Run a shell command and return stdout+stderr.",
        input_schema: %{
          type: "object",
          properties: %{command: %{type: "string"}},
          required: ["command"]
        }
      },
      %{
        name: "read_file",
        description: "Read a file's contents.",
        input_schema: %{
          type: "object",
          properties: %{path: %{type: "string"}},
          required: ["path"]
        }
      },
      %{
        name: "edit_file",
        description: "Replace `old` with `new` in a file. `old` must appear exactly once. Empty `old` creates/overwrites the file with `new`.",
        input_schema: %{
          type: "object",
          properties: %{
            path: %{type: "string"},
            old: %{type: "string"},
            new: %{type: "string"}
          },
          required: ["path", "old", "new"]
        }
      }
    ]
  end

  def exec(%{"id" => id, "name" => name, "input" => input}) do
    IO.puts(IO.ANSI.faint() <> "▸ #{name} #{inspect(input, limit: 5)}" <> IO.ANSI.reset())

    case run(name, input) do
      {:ok, out} -> %{type: "tool_result", tool_use_id: id, content: out}
      {:error, err} -> %{type: "tool_result", tool_use_id: id, content: err, is_error: true}
    end
  end

  defp run("bash", %{"command" => cmd}) do
    {out, code} = System.cmd("sh", ["-c", cmd], stderr_to_stdout: true)
    if code == 0, do: {:ok, out}, else: {:error, "exit #{code}\n#{out}"}
  end

  defp run("read_file", %{"path" => path}) do
    case File.read(path) do
      {:ok, s} -> {:ok, s}
      {:error, r} -> {:error, "#{path}: #{r}"}
    end
  end

  defp run("edit_file", %{"path" => path, "old" => "", "new" => new}) do
    File.write!(path, new)
    {:ok, "wrote #{path}"}
  end

  defp run("edit_file", %{"path" => path, "old" => old, "new" => new}) do
    with {:ok, s} <- File.read(path),
         1 <- length(String.split(s, old)) - 1 do
      File.write!(path, String.replace(s, old, new))
      {:ok, "edited #{path}"}
    else
      {:error, r} -> {:error, "#{path}: #{r}"}
      n -> {:error, "`old` found #{n} times, need exactly 1"}
    end
  end

  defp run(name, _), do: {:error, "unknown tool #{name}"}
end
