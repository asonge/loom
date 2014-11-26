defmodule LoomPncounterTest do
  use ExUnit.Case
  use Loom
  use ExCheck

  alias Loom.CRDT, as: CRDT

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

  property :testing do
    a = Counter.new
    b = Counter.new
    for_all list in list({oneof([:a, :b]), oneof([:inc, :dec]), such_that(i in int when i > 0)}) do
      sum = Enum.reduce(list, 0, fn
              {_, :inc, n}, acc -> acc + n
              {_, :dec, n}, acc -> acc - n
            end)
      {new_a, new_b} = Enum.reduce(list, {a,b}, fn
                         {:a, op, amount}, {a1,b1} -> {CRDT.apply(a1, {op, :a, amount}), b1}
                         {:b, op, amount}, {a1,b1} -> {a1, CRDT.apply(b1, {op, :b, amount})}
                       end)
      c = CRDT.join(new_a, new_b)
      CRDT.value(c) == sum
    end
  end

end
