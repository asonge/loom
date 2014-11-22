defmodule LoomAwormapTest do
  use ExUnit.Case
  use Loom

  test "Basic add" do
    ctr = GCounter.new
    {map, _} = KVSet.new |> KVSet.add(:a, 1, ctr)
    assert ctr == KVSet.get(map, 1, ctr)
    assert true == KVSet.has_key?(map, 1)
    assert false == KVSet.has_key?(map, 2)
  end

  test "Basic add and remove" do
    ctr = GCounter.new
    {map, _} = KVSet.new |> KVSet.add(:a, 1, ctr)
    assert ctr == KVSet.get(map, 1, ctr)
    {map2, _} = KVSet.remove(map, 1, ctr)
    assert true == KVSet.has_key?(map, 1)
    assert false == KVSet.has_key?(map, 2)
    assert false == KVSet.has_key?(map2, 1)
  end

  test "Keys and values" do
    ctr = GCounter.new |> GCounter.inc(:a, 5)
    ctr1  = ctr |> GCounter.inc(:b, 10)
    {map,_} = KVSet.new
        |> KVSet.add(:a, 1, ctr)
        |> KVSet.add(:a, 1, ctr)
        |> KVSet.add(:a, 1, ctr)
        |> KVSet.add(:b, 1, ctr1)
        |> KVSet.add(:a, 3, ctr)
    assert ctr1 != ctr
    assert [1,3] = KVSet.keys(map) |> Enum.sort
    assert Enum.sort([ctr,ctr1]) == KVSet.values(map) |> Enum.sort
  end

end
