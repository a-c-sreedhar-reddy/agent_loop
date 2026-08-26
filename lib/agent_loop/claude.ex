defmodule AgentLoop.Claude do
  @moduledoc "Thin wrapper over POST /v1/messages."

  @url "https://api.anthropic.com/v1/messages"
  @model "claude-opus-5"

  @doc """
  Sends `messages` to the Messages API and returns the decoded response body.

  Options:

    * `:system` — system prompt string
    * `:tools`  — list of tool specs the model may call

  Raises if the API responds with anything other than 200. The receive timeout
  is generous (10 min) because long tool-using turns can be slow.
  """
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
