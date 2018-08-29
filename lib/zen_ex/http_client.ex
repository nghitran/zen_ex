defmodule ZenEx.HTTPClient do

  @moduledoc false

  @content_type "application/json"

  alias ZenEx.Collection

  def get("https://" <> _ = url) do
    url |> HTTPotion.get([headers: api_headers()])
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
    |> HTTPotion.post([body: Poison.encode!(param), headers: api_headers()])
    |> _build_entity(decode_as)
  end

  def put(endpoint, %{} = param, decode_as) do
    build_url(endpoint)
    |> HTTPotion.put([body: Poison.encode!(param), headers: api_headers()])
    |> _build_entity(decode_as)
  end

  def delete(endpoint, decode_as), do: delete(endpoint) |> _build_entity(decode_as)
  def delete(endpoint) do
    build_url(endpoint) |> HTTPotion.delete([headers: api_headers()])
  end

  def build_url(endpoint) do
    "https://#{Application.get_env(:zen_ex, :subdomain)}.zendesk.com#{endpoint}"
  end

  def api_headers() do
    ["Content-Type": @content_type, "Authorization": "Bearer #{Application.get_env(:zen_ex, :oauth_token)}"]
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
