defmodule AgentLoop.Claude do
  @moduledoc "Thin wrapper over POST /v1/messages."

  @url "https://api.anthropic.com/v1/messages"
  @model "claude-opus-5"

  def chat(messages, opts) do
    body = %{
      model: @model,
      max_tokens: 16_000,
      system: opts[:system],
      tools: opts[:tools],
      messages: messages
    }

    Req.post!(@url,
      json: body,
      headers: [
        {"x-api-key", System.fetch_env!("ANTHROPIC_API_KEY")},
        {"anthropic-version", "2023-06-01"}
      ],
      receive_timeout: 600_000
    )
    |> case do
      %{status: 200, body: body} -> body
      %{status: status, body: body} -> raise "Claude API #{status}: #{inspect(body)}"
    end
  end
end
