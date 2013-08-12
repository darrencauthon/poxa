Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.EventHandlerTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Authentication
  import :meck
  import Poxa.EventHandler

  setup do
    new PusherEvent
    new Authentication
    new JSEX
    new :cowboy_req
  end

  teardown do
    unload PusherEvent
    unload Authentication
    unload JSEX
    unload :cowboy_req
  end

  test "single channel event using JSON" do
    expect(JSEX, :decode!, 1,
                [{"channel", "channel_name"},
                 {"name", "event_etc"} ])
    expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, nil})
    expect(PusherEvent, :valid?, 1, true)
    expect(PusherEvent, :send_message_to_channels, 3, :ok)
    expect(:cowboy_req, :set_resp_body, 2, :req1)

    assert post_json(:req, :body) == {true, :req1, nil}

    assert validate PusherEvent
    assert validate Authentication
    assert validate :cowboy_req
    assert validate JSEX
  end

  test "single channel event excluding socket_id using JSON" do
    expect(JSEX, :decode!, 1, :decoded_json)
    expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, :exclude})
    expect(PusherEvent, :valid?, 1, true)
    expect(PusherEvent, :send_message_to_channels, 3, :ok)
    expect(:cowboy_req, :set_resp_body, 2, :req1)

    assert post_json(:req, :body) == {true, :req1, nil}

    assert validate PusherEvent
    assert validate Authentication
    assert validate :cowboy_req
    assert validate JSEX
  end

  test "multiple channel event using JSON" do
    expect(JSEX, :decode!, 1, :decoded_json)
    expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, nil})
    expect(PusherEvent, :send_message_to_channels, 3, :ok)
    expect(PusherEvent, :valid?, 1, true)
    expect(:cowboy_req, :set_resp_body, 2, :req1)

    assert post_json(:req, :body) == {true, :req1, nil}

    assert validate PusherEvent
    assert validate Authentication
    assert validate :cowboy_req
    assert validate JSEX
  end

  test "invalid event using JSON" do
    expect(JSEX, :decode!, 1, :decoded_json)
    expect(:cowboy_req, :reply, 4, {:ok, :req1})
    expect(PusherEvent, :valid?, 1, false)
    expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, nil})

    assert post_json(:req, :body) == {:halt, :req1, nil}

    assert validate Authentication
    assert validate PusherEvent
    assert validate :cowboy_req
    assert validate JSEX
  end

  test "undefined channel event using JSON" do
    expect(JSEX, :decode!, 1, :decoded_json)
    expect(PusherEvent, :valid?, 1, true)
    expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], nil, nil})
    expect(:cowboy_req, :reply, 4, {:ok, :req1})

    assert post_json(:req, :state) == {:halt, :req1, nil}

    assert validate Authentication
    assert validate PusherEvent
    assert validate :cowboy_req
    assert validate JSEX
  end

end
