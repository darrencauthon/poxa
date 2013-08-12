Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.AuthorizarionHelperTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import :meck
  import Poxa.AuthorizationHelper

  setup do
    new Authentication
    new :cowboy_req
  end

  teardown do
    unload Authentication
    unload :cowboy_req
  end

  test "is_authorized returns true if Authentication is ok on JSON body" do
    expect(:cowboy_req, :method, 1, {:method, :req1})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :parse_header, 3, {:ok, {"application", "json", []}, :req4})
    expect(:cowboy_req, :body, 1, {:ok, :body, :req5})
    expect(Authentication, :check, 4, :ok)

    assert is_authorized(:req, :state) == {true, :req5, :state}
    assert is_authorized(:req, :undefined) == {true, :req5, :body}
    assert is_authorized(:req, nil) == {true, :req5, :body}

    assert validate(Authentication)
    assert validate(:cowboy_req)
  end

  test "is_authorized returns true if Authentication is ok on form body" do
    expect(:cowboy_req, :method, 1, {:method, :req1})
    expect(:cowboy_req, :qs_vals, 1, {[:qs_vals], :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :parse_header, 3, {:ok, {"application", "x-www-form-urlencoded", []}, :req4})
    expect(:cowboy_req, :body_qs, 1, {:ok, [:body_qs], :req5})
    expect(Authentication, :check, 4, :ok)

    assert is_authorized(:req, :state) == {true, :req5, :state}
    assert is_authorized(:req, :undefined) == {true, :req5, [:body_qs]}
    assert is_authorized(:req, nil) == {true, :req5, [:body_qs]}

    assert validate(Authentication)
    assert validate(:cowboy_req)
  end

  test "is_authorized returns false if Authentication is not ok" do
    expect(:cowboy_req, :method, 1, {:method, :req1})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :parse_header, 3, {:ok, {"application", "json", []}, :req4})
    expect(:cowboy_req, :body, 1, {:ok, :body, :req5})
    expect(Authentication, :check, 4, {:badauth, "error"})

    assert is_authorized(:req, :state) == {{false, "authentication failed"}, :req5, nil}

    assert validate(Authentication)
    assert validate(:cowboy_req)
  end

end

