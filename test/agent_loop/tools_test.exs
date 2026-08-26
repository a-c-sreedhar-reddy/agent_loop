defmodule AgentLoop.ToolsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  alias AgentLoop.Tools

  @moduletag :tmp_dir

  describe "edit_file" do
    test "replaces a unique match", %{tmp_dir: dir} do
      path = Path.join(dir, "a.txt")
      File.write!(path, "hello world\n")

      result = exec("edit_file", %{"path" => path, "old" => "world", "new" => "there"})

      assert result.content == "edited #{path}"
      refute Map.has_key?(result, :is_error)
      assert File.read!(path) == "hello there\n"
    end

    test "empty `old` creates a new file", %{tmp_dir: dir} do
      path = Path.join(dir, "new.txt")

      result = exec("edit_file", %{"path" => path, "old" => "", "new" => "fresh"})

      assert result.content == "wrote #{path}"
      assert File.read!(path) == "fresh"
    end

    test "empty `old` overwrites an existing file wholesale", %{tmp_dir: dir} do
      path = Path.join(dir, "b.txt")
      File.write!(path, "old contents")

      exec("edit_file", %{"path" => path, "old" => "", "new" => "new contents"})

      assert File.read!(path) == "new contents"
    end

    test "refuses an ambiguous match and leaves the file untouched", %{tmp_dir: dir} do
      path = Path.join(dir, "dup.txt")
      File.write!(path, "x = 1\nx = 1\n")

      result = exec("edit_file", %{"path" => path, "old" => "x = 1", "new" => "x = 2"})

      assert result.is_error
      assert result.content == "`old` found 2 times, need exactly 1"
      assert File.read!(path) == "x = 1\nx = 1\n"
    end

    test "refuses a match that is not found", %{tmp_dir: dir} do
      path = Path.join(dir, "c.txt")
      File.write!(path, "hello\n")

      result = exec("edit_file", %{"path" => path, "old" => "nope", "new" => "!"})

      assert result.is_error
      assert result.content == "`old` found 0 times, need exactly 1"
      assert File.read!(path) == "hello\n"
    end

    test "reports a missing file as an error rather than raising", %{tmp_dir: dir} do
      path = Path.join(dir, "ghost.txt")

      result = exec("edit_file", %{"path" => path, "old" => "a", "new" => "b"})

      assert result.is_error
      assert result.content == "#{path}: enoent"
    end

    test "carries the tool_use id through to the result", %{tmp_dir: dir} do
      path = Path.join(dir, "d.txt")
      File.write!(path, "a")

      block = %{
        "id" => "toolu_123",
        "name" => "edit_file",
        "input" => %{"path" => path, "old" => "a", "new" => "b"}
      }

      result = capture_result(block)

      assert result.type == "tool_result"
      assert result.tool_use_id == "toolu_123"
    end
  end

  describe "bash" do
    test "returns stdout on success" do
      result = exec("bash", %{"command" => "echo hello"})

      assert result.content == "hello\n"
      refute Map.has_key?(result, :is_error)
    end

    test "merges stderr into stdout" do
      result = exec("bash", %{"command" => "echo oops >&2"})

      assert result.content == "oops\n"
      refute Map.has_key?(result, :is_error)
    end

    test "reports a non-zero exit as an error, keeping the output" do
      result = exec("bash", %{"command" => "echo failing; exit 3"})

      assert result.is_error
      assert result.content == "exit 3\nfailing\n"
    end

    test "a failing command does not raise out of the loop" do
      result = exec("bash", %{"command" => "false"})

      assert result.is_error
      assert result.content == "exit 1\n"
    end
  end

  describe "read_file" do
    test "returns the file contents", %{tmp_dir: dir} do
      path = Path.join(dir, "r.txt")
      File.write!(path, "line one\nline two\n")

      result = exec("read_file", %{"path" => path})

      assert result.content == "line one\nline two\n"
      refute Map.has_key?(result, :is_error)
    end

    test "reports a missing file as an error", %{tmp_dir: dir} do
      path = Path.join(dir, "absent.txt")

      result = exec("read_file", %{"path" => path})

      assert result.is_error
      assert result.content == "#{path}: enoent"
    end
  end

  describe "unknown tools" do
    test "a hallucinated tool name comes back as an error, not a crash" do
      result = exec("write_file", %{"path" => "x", "contents" => "y"})

      assert result.is_error
      assert result.content == "unknown tool write_file"
    end
  end

  # Tools.exec/1 echoes the call to stdout; swallow it so test output stays clean.
  defp exec(name, input) do
    capture_result(%{"id" => "toolu_test", "name" => name, "input" => input})
  end

  defp capture_result(block) do
    {result, _io} = with_io(fn -> Tools.exec(block) end)
    result
  end
end
