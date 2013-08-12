defmodule Poxa.EventHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/events

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/http_handlers

  More info on Pusher events at: http://pusher.com/docs/rest_api
  """
  alias Poxa.AuthorizationHelper
  alias Poxa.PusherEvent
  require Lager

  def init(_transport, _req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["POST"], req, state}
  end

  def is_authorized(req, state) do
    AuthorizationHelper.is_authorized(req, state)
  end

  def content_types_accepted(req, state) do
    {[{{"application", "json", []}, :post_json},
      {{"application", "x-www-form-urlencoded", []}, :post_form}],
      req, state}
  end

  def post_json(req, body) do
    request_data = JSEX.decode!(body)
    post(req, request_data)
  end

  def post_form(req, request_data) do
    {:ok, body, req} = :cowboy_req.body_qs(req)
    IO.inspect body
    post(req, request_data)
  end

  @invalid_event_json JSEX.encode!([error: "Event must have channel(s), name, and data"])

  defp post(req, request_data) do
    {request_data, channels, exclude} = PusherEvent.parse_channels(request_data)
    if channels && PusherEvent.valid?(request_data) do
      message = prepare_message(request_data)
      PusherEvent.send_message_to_channels(channels, message, exclude)
      req = :cowboy_req.set_resp_body("", req)
      {true, req, nil}
    else
      Lager.info("Event must have channel(s), name and data")
      {:ok, req} = :cowboy_req.reply(400, [], @invalid_event_json, req)
      {:halt, req, nil}
    end
  end

  # Remove name and add event to the response
  defp prepare_message(message) do
    {event, message} = ListDict.pop(message, "name")
    List.concat(message, [{"event", event}])
  end

end
