defmodule AgentLoop.Tools do
  @moduledoc "Tool definitions (sent to Claude) and their executors (run locally)."

  @doc """
  JSON schemas for every tool exposed to the model.

  Descriptions matter: they are the only instructions the model gets about
  how each tool behaves.
  """
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
        description:
          "Replace `old` with `new` in a file. `old` must appear exactly once. Empty `old` creates/overwrites the file with `new`.",
        input_schema: %{
          type: "object",
          properties: %{
            path: %{type: "string"},
            old: %{type: "string"},
            new: %{type: "string"}
          },
          required: ["path", "old", "new"]
        }
      },
      %{
        name: "spawn_agent",
        description:
          "Delegate a self-contained task to a fresh agent with its own context. Returns its final answer. Use for parallelisable or context-heavy work (e.g. 'read all files in lib/ and summarise').",
        input_schema: %{
          type: "object",
          properties: %{task: %{type: "string"}},
          required: ["task"]
        }
      }
    ]
  end

  @doc """
  Runs one `tool_use` block and wraps the outcome in a `tool_result` block.

  Echoes the call to stdout for visibility, then dispatches to `run/2`. Failures
  are returned to the model as `is_error: true` results rather than raising, so
  the loop can keep going and let the model recover.
  """
  def exec(%{"id" => id, "name" => name, "input" => input}) do
    IO.puts(IO.ANSI.faint() <> "▸ #{name} #{inspect(input, limit: 5)}" <> IO.ANSI.reset())

    case run(name, input) do
      {:ok, out} -> %{type: "tool_result", tool_use_id: id, content: out}
      {:error, err} -> %{type: "tool_result", tool_use_id: id, content: err, is_error: true}
    end
  end

  # Actual tool implementations. Each returns {:ok, output} | {:error, message}.

  # Shell out via `sh -c`, merging stderr into stdout; non-zero exit is an error.
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

  # Empty `old` means "create or overwrite the file wholesale".
  defp run("edit_file", %{"path" => path, "old" => "", "new" => new}) do
    File.write!(path, new)
    {:ok, "wrote #{path}"}
  end

  # Otherwise require `old` to occur exactly once, so edits are unambiguous.
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

  defp run("spawn_agent", %{"task" => task}) do
    # unnamed — drop `name:` from Session
    {:ok, pid} = AgentLoop.Session.start_link([])
    # ask/2 now takes a pid
    answer = AgentLoop.Session.ask(pid, task)
    GenServer.stop(pid)
    {:ok, answer}
  end

  # Model hallucinated a tool we don't have.
  defp run(name, _), do: {:error, "unknown tool #{name}"}
end
