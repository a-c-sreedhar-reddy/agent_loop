defmodule AgentLoopTest do
  use ExUnit.Case
  doctest AgentLoop

  test "greets the world" do
    assert AgentLoop.hello() == :world
  end
end
