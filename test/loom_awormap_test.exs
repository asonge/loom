defmodule LoomAwormapTest do
  use ExUnit.Case
  use Loom

  test "Basic add" do
    ctr = GCounter.new
    {map, _} = KVSet.new |> KVSet.add(:a, 1, ctr)
    assert ctr == KVSet.get(map, 1, GCounter)
    assert nil == KVSet.get(map, 3, GCounter)
    assert true == KVSet.has_key?(map, 1, GCounter)
    assert false == KVSet.has_key?(map, 2, GCounter)
    assert %{ {1,GCounter} => ctr } == map |> KVSet.value
  end

  test "Basic add and remove" do
    ctr = GCounter.new
    {map, _} = KVSet.new |> KVSet.add(:a, 1, ctr)
    assert ctr == KVSet.get(map, 1, ctr)
    {map2, _} = KVSet.remove(map, 1, ctr)
    assert true == KVSet.has_key?(map, 1, GCounter)
    assert false == KVSet.has_key?(map, 2, GCounter)
    assert false == KVSet.has_key?(map2, 1, GCounter)
  end

  test "Keys and values" do
    ctr = GCounter.new |> GCounter.inc(:a, 5)
    ctr1  = ctr |> GCounter.inc(:b, 10)
    {map,_} = KVSet.new
        |> KVSet.add(:a, 1, ctr)
        |> KVSet.add(:a, 1, ctr)
        |> KVSet.add(:b, 1, ctr1)
        |> KVSet.add(:a, 3, ctr)
    assert ctr1 != ctr
    assert [{1,GCounter},{3,GCounter}] == KVSet.keys(map) |> Enum.sort
  end

  test "Dict merge" do
    ctrA = GCounter.new |> GCounter.inc(:a, 10)
    ctrB = GCounter.new |> GCounter.inc(:b, 10)
    ctrC = GCounter.join(ctrA, ctrB)
    {setA, deltaA} = KVSet.new |> KVSet.add(:a, "counter", ctrA) |> KVSet.add(:a, "lft", ctrA)
    {setB, deltaB} = KVSet.new |> KVSet.add(:b, "counter", ctrB) |> KVSet.add(:b, "rgt", ctrB)
    expected = %{{"counter",GCounter} => ctrC, {"lft",GCounter} => ctrA, {"rgt",GCounter} => ctrB}
    assert expected == KVSet.join(setA, setB) |> KVSet.value
    assert expected == KVSet.join(setA, deltaB) |> KVSet.value
    assert expected == KVSet.join(deltaA, setB) |> KVSet.value
  end

end
