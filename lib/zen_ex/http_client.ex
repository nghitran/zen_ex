defmodule ZenEx.HTTPClient do

  @moduledoc false

  @content_type "application/json"

  alias ZenEx.Collection

  def get("https://" <> _ = url) do
    url |> HTTPotion.get([headers: required_headers()])
  end
  def get(endpoint) do
    endpoint |> build_url |> get
  end
  def get("https://" <> _ = url, decode_as) do
    url |> get |> _build_entity(decode_as)
  end
  def get(endpoint, decode_as) do
    endpoint |> build_url |> get(decode_as)
  end

  def post(endpoint, %{} = param, decode_as) do
    build_url(endpoint)
    |> HTTPotion.post([body: Poison.encode!(param), headers: required_headers()])
    |> _build_entity(decode_as)
  end

  def put(endpoint, %{} = param, decode_as) do
    build_url(endpoint)
    |> HTTPotion.put([body: Poison.encode!(param), headers: required_headers()])
    |> _build_entity(decode_as)
  end

  def delete(endpoint, decode_as), do: delete(endpoint) |> _build_entity(decode_as)
  def delete(endpoint) do
    build_url(endpoint) |> HTTPotion.delete([headers: required_headers()])
  end

  def build_url(endpoint) do
    "https://#{Application.get_env(:zen_ex, :subdomain)}.zendesk.com#{endpoint}"
  end

  def required_headers() do
    ["Content-Type": @content_type, "Authorization": "Basic #{Application.get_env(:zen_ex, :basic_auth_token)}"]
  end

  def _build_entity(%HTTPotion.Response{status_code: status_code} = res, _) when status_code != 200 do
    error_result = res.body
                   |> Poison.decode!(keys: :atoms)

    error_message = case error_result.error do
      %{message: message} -> message
      message when is_binary(message) -> message
      anything_else -> "#{inspect anything_else}"
    end

    {:error, error_message}
  end
  def _build_entity(%HTTPotion.Response{} = res, [{key, [module]}]) do
    {entities, page} =
      res.body
      |> Poison.decode!(keys: :atoms, as: %{key => [struct(module)]})
      |> Map.pop(key)

    struct(Collection, Map.merge(page, %{entities: entities, decode_as: [{key, [module]}]}))
  end
  def _build_entity(%HTTPotion.Response{} = res, [{key, module}]) do
    res.body |> Poison.decode!(keys: :atoms, as: %{key => struct(module)}) |> Map.get(key)
  end
  def _build_entity(%HTTPotion.ErrorResponse{message: error}, _) do
    {:error, error}
  end
end
