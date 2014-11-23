defmodule LoomPncounterTest do
  use ExUnit.Case
  use Loom

  doctest Loom.PNCounter
  doctest Loom.CRDT.Loom.PNCounter

  test "Exception on creation for negative values" do
    assert_raise ArgumentError, fn -> Counter.new(values: [a: {5,-1}]) end
  end

  test "Increment/decrement and join, see if double-merge causes no issues." do
    ctr1 = Counter.new |> Counter.inc(:a) |> Counter.dec(:a, 10)
    ctr2 = Counter.new |> Counter.dec(:b) |> Counter.inc(:b, 5)
    assert -5 = Counter.join(ctr1,ctr2) |> Counter.join(ctr1) |> Counter.value
  end

  test "Stupid test for CRDT ops" do
    assert [_,_] = Keyword.take(Loom.CRDT.ops(Loom.PNCounter.new), [:update, :read])
  end

end
