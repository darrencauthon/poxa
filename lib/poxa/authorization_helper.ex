defmodule Poxa.AuthorizationHelper do
  alias Poxa.Authentication

  @spec is_authorized(:cowboy.req, any) :: {true, :cowboy.req, any} |
                                           {{false, binary}, :cowboy.req, nil}
  def is_authorized(req, state) do
    {method, req} = :cowboy_req.method(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {path, req} = :cowboy_req.path(req)
    {body, qs_vals, req} = parse_body_and_qs_vals(qs_vals, req)
    auth = Authentication.check(method, path, body, qs_vals)
    if auth == :ok do
      if state in [:undefined, nil] do
        {true, req, body}
      else
        {true, req, state}
      end
    else
      {{false, "authentication failed"}, req, nil}
    end
  end

  @doc """
  If the request ia a form, add the body to qs_vals as it's a query string
  """
  defp parse_body_and_qs_vals(qs_vals, req) do
    {:ok, value, req} = :cowboy_req.parse_header("content-type", req, :header)
    case value do
      {"application", "json", _} ->
        {:ok, body, req} = :cowboy_req.body(req)
        {body, qs_vals, req}
      {"application", "x-www-form-urlencoded", _} ->
        {:ok, body_qs, req} = :cowboy_req.body_qs(req)
        {body_qs, qs_vals ++ body_qs, req}
      _ -> {"", qs_vals, req}
    end
  end
end
