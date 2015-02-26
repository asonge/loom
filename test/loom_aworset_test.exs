defmodule LoomAworsetTest do
  use ExUnit.Case
  use Loom
  alias Loom.CRDT

  doctest Loom.AWORSet
  doctest Loom.CRDT.Loom.AWORSet # The Protocol implementation

  test "Basic add to set" do
    set = Set.new |> Set.add(:a, 1)
    assert [1] == Set.value(set)
    assert true == Set.member?(set, 1)
    assert false == Set.member?(set, 2)
    empty = Set.empty(set)
    assert [] == empty |> Set.value
  end

  test "Precondition fail" do
    assert_raise Loom.PreconditionError, fn ->
      Set.new |> Set.remove(1)
    end
  end

  test "See if we can remove" do
    set = Set.new |> Set.add(:a, 1)
    assert true == Set.member?(set, 1)
    set = Set.remove(set, 1)
    assert false == Set.member?(set, 1)
  end

  test "Add/remove/add" do
    set = Set.new |> Set.add(:a, 1)
    assert true == Set.member?(set, 1)
    set = Set.remove(set, 1)
    assert false == Set.member?(set, 1)
    set = Set.add(set, :a, 1)
    assert true == Set.member?(set, 1)
  end

  test "Simple merge + commutivity of sets and deltas" do
    setA = Set.new |> Set.add(:a, 1)
    deltaA = Set.delta(setA)
    setB = Set.new |> Set.add(:b, 2)
    deltaB = Set.delta(setB)
    setAB = Set.join(setA, setB)
    assert [1,2] == setAB |> Set.value
    ab_values = Enum.sort(CRDT.value(setAB))
    assert ab_values == Set.join(setB, setA) |> CRDT.value |> Enum.sort
    assert ab_values == Set.join(setA, deltaB) |> CRDT.value |> Enum.sort
    assert ab_values == Set.join(setB, deltaA) |> CRDT.value |> Enum.sort
    assert ab_values == Set.join(setAB, deltaA) |> CRDT.value |> Enum.sort
  end

  test "Simple merge + commutivity of sets and deltas + remove" do
    setA = Set.new |> Set.add(:a, 1)
    setB = Set.new |> Set.add(:b, 2)
    deltaB = Set.delta(setB)
    setA = Set.remove(Set.join(setA, setB), 2)
    deltaA = Set.delta(setA)
    setAB = Set.join(setA, setB)
    assert [1] == setAB |> Set.value
    ab_values = Enum.sort(CRDT.value(setAB))
    assert ab_values == Set.join(setB, setA) |> CRDT.value |> Enum.sort
    assert ab_values == Set.join(setA, deltaB) |> CRDT.value |> Enum.sort
    assert ab_values == Set.join(setB, deltaA) |> CRDT.value |> Enum.sort
  end

  test "Disjoint adds + a remove" do
    setA = Set.new |> Set.add(:a, 1) |> Set.add(:a, 3)
    deltaA = Set.delta(setA)
    setB = Set.new |> Set.add(:b, 1) |> Set.add(:b, 2)
    deltaB = Set.delta(setB)
    assert [1,2,3] = Set.join(setA, deltaB) |> Set.value |> Enum.sort
    setA2 = Set.join(setA, deltaB) |> Set.remove(2)
    deltaA2 = Set.delta(setA2)
    assert [1,3] = setA2 |> Set.value |> Enum.sort
    setB2 = Set.join(setB, deltaA2)
    assert [1,3] = setB2 |> Set.value |> Enum.sort
    setB3 = Set.join(setB2, deltaA) # Make sure we don't get a resurrected 2.
    assert [1,3] = setB3 |> Set.value |> Enum.sort
  end

  test "Out of order delta application" do
    set1 = Set.new |> Set.add(:a, 1)
    d1 = Set.delta(set1)
    set2 = Set.add(set1, :a, 2)
    d2 = Set.delta(set2)
    set3 = set2 |> Set.clear_delta |> Set.add(:a, 3)
    d3 = Set.delta(set3)
    assert [1,2,3] = Set.join(set1, set3) |> Set.value |> Enum.sort
    assert [1,3] = Set.join(set1, d3) |> Set.value |> Enum.sort
    assert Enum.sort(CRDT.value(set3)) == Set.join(d1, d3) |> Set.join(d2) |> CRDT.value |> Enum.sort
  end

  test "Out of order delete delta application" do
    set1 = Set.new |> Set.add(:a, 1)
    set2 = Set.remove(set1, 1)
    d3 = Set.add(set2, :a, 3) |> Set.delta
    assert [3] = Set.join(set1, d3) |> Set.value |> Enum.sort
  end

end
