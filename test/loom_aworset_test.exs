defmodule LoomAworsetTest do
  use ExUnit.Case
  use Loom

  test "Basic add to set" do
    {set, _} = Set.new |> Set.add(:a, 1)
    assert [1] == Set.value(set)
    assert true == Set.member?(set, 1)
    assert false == Set.member?(set, 2)
    {empty, _} = Set.empty(set)
    assert [] == empty |> Set.value
  end

  test "Precondition fail" do
    assert_raise Loom.PreconditionError, fn ->
      Set.new |> Set.remove(1)
    end
  end

  test "See if we can remove" do
    {set, _} = Set.new |> Set.add(:a, 1)
    assert true == Set.member?(set, 1)
    {set, _} = Set.remove(set, 1)
    assert false == Set.member?(set, 1)
  end

  test "Add/remove/add" do
    {set, _} = Set.new |> Set.add(:a, 1)
    assert true == Set.member?(set, 1)
    {set, _} = Set.remove(set, 1)
    assert false == Set.member?(set, 1)
    {set, _} = Set.add(set, :a, 1)
    assert true == Set.member?(set, 1)
  end

  test "Simple merge + commutivity of sets and deltas" do
    {setA, deltaA} = Set.new |> Set.add(:a, 1)
    {setB, deltaB} = Set.new |> Set.add(:b, 2)
    setAB = Set.join(setA, setB)
    assert [1,2] == setAB |> Set.value
    assert setAB == Set.join(setB, setA)
    assert setAB == Set.join(setA, deltaB)
    assert setAB == Set.join(setB, deltaA)
    assert setAB == Set.join(setAB, deltaA)
  end

  test "Simple merge + commutivity of sets and deltas + remove" do
    {setA, deltaA} = Set.new |> Set.add(:a, 1)
    {setB, deltaB} = Set.new |> Set.add(:b, 2)
    {setA, deltaA} = Set.remove({Set.join(setA, setB), deltaA}, 2)
    setAB = Set.join(setA, setB)
    assert [1] == setAB |> Set.value
    assert setAB == Set.join(setB, setA)
    assert setAB == Set.join(setA, deltaB)
    assert setAB == Set.join(setB, deltaA)
  end

  test "Disjoint adds + a remove" do
    {setA, deltaA} = Set.new |> Set.add(:a, 1) |> Set.add(:a, 3)
    {setB, deltaB} = Set.new |> Set.add(:b, 1) |> Set.add(:b, 2)
    assert [1,2,3] = Set.join(setA, deltaB) |> Set.value |> Enum.sort
    {setA2, deltaA2} = Set.join(setA, deltaB) |> Set.remove(2)
    assert [1,3] = setA2 |> Set.value |> Enum.sort
    setB2 = Set.join(setB, deltaA2)
    assert [1] = setB2 |> Set.value |> Enum.sort
    setB3 = Set.join(setB2, deltaA) # Make sure we don't get a resurrected 2.
    assert [1,3] = setB3 |> Set.value |> Enum.sort
  end

  test "Out of order delta application" do
    {set1, d1} = Set.new |> Set.add(:a, 1)
    {set2, d2} = Set.add(set1, :a, 2)
    {set3, d3} = Set.add(set2, :a, 3)
    assert [1,2,3] = Set.join(set1, set3) |> Set.value |> Enum.sort
    assert [1,3] = Set.join(set1, d3) |> Set.value |> Enum.sort
    assert set3 == Set.join(d1, d3) |> Set.join(d2)
  end

  test "Out of order delete delta application" do
    {set1, _} = Set.new |> Set.add(:a, 1)
    {set2, _} = Set.remove(set1, 1)
    {_, d3} = Set.add(set2, :a, 3)
    assert [1,3] = Set.join(set1, d3) |> Set.value |> Enum.sort
  end

end
