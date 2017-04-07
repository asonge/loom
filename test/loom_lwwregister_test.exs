defmodule LoomLwwregisterTest do
  use ExUnit.Case
  alias Loom.LWWRegister, as: Reg

  doctest Loom.LWWRegister
  doctest Loom.CRDT.Loom.LWWRegister # The Protocol implementation

  test "Basic value setting" do
    reg = Reg.new |> Reg.set("test")
    assert "test" == reg |> Reg.value
  end

  describe "Join" do
    test "with default clock" do
      a = Reg.new("a")
      b = Reg.new("b")
      ab_value = a |> Reg.join(b) |> Reg.value
      assert "b" == ab_value
    end

    test "with explicit clocks" do
      a = Reg.new("a", 2)
      b = Reg.new("b", 1)
      ab_value = a |> Reg.join(b) |> Reg.value
      assert "a" == ab_value
    end

    test "with equal crdt" do
      a = Reg.new("a")
      value = a |> Reg.join(a) |> Reg.value
      assert "a" == value
    end

    test "with equal clocks" do
      a = Reg.new("a", 1)
      b = Reg.new("b", 1)
      ab_value = a |> Reg.join(b) |> Reg.value
      assert "b" == ab_value
    end

    test "with nil clock" do
      a = Reg.new("a")
      b = Reg.new("b", nil)
      ab_value = a |> Reg.join(b) |> Reg.value
      assert "a" == ab_value
    end
  end
end
