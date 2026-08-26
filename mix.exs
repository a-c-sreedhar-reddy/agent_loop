defmodule AgentLoop.MixProject do
  use Mix.Project

  def project do
    [
      app: :agent_loop,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: AgentLoop.CLI]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
