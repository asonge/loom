defmodule LoomPncounterTest do
  use ExUnit.Case
  use Loom

  test "Identity and basic increment/decrement" do
    assert 0 = Counter.new |> Counter.value
    assert 30 = Counter.new |> Counter.inc(:a, 1) |> Counter.inc(:a, 29) |> Counter.value()
    assert -10 = Counter.new |> Counter.dec(:a, 10) |> Counter.value
    assert 0 = Counter.new |> Counter.inc(:a, 10) |> Counter.dec(:a, 10) |> Counter.value
  end

  test "Increment and join" do
    ctr1 = Counter.new |> Counter.inc(:a) |> Counter.inc(:a, 10)
    ctr2 = Counter.new |> Counter.inc(:b) |> Counter.inc(:b, 5)
    assert 17 = Counter.join(ctr1,ctr2) |> Counter.value
  end

  test "Increment/decrement and join" do
    ctr1 = Counter.new |> Counter.inc(:a) |> Counter.dec(:a, 10)
    ctr2 = Counter.new |> Counter.dec(:b) |> Counter.inc(:b, 5)
    assert -5 = Counter.join(ctr1,ctr2) |> Counter.join(ctr1) |> Counter.value
  end

end
