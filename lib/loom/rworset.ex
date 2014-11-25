defmodule Loom.RWORSet do
  alias Loom.RWORSet, as: Set
  alias Loom.Dots

  @moduledoc """
  A remove-wins (optimized) oberserved-remove set (without tombstones).

  This CRDT breaks ties (concurrency) in favor of removing an element from a set.
  This CRDT isn't as "natural" as the add-wins set, which usually matches user
  expectations a bit more closely.
  """

  @type actor :: term
  @type value :: term
  @opaque t :: %Set{
    dots: Dots.t
  }

  defstruct dots: Dots.new()

  @doc """
  Creates a new RWORSet.

  The identity value is `[]`, an empty list.

      iex> alias Loom.RWORSet, as: Set
      iex> Set.new |> Set.value
      []

  """
  @spec new() :: t
  def new, do: %Set{}

  @doc """
  Add a term to the set.

      iex> alias Loom.RWORSet, as: Set
      iex> Set.new |> Set.add(:a, "test1") |> Set.add(:a, "test2") |> Set.value |> Enum.sort
      ["test1", "test2"]

  """
  @spec add(t, actor, value) :: {t,t}
  @spec add({t,t}, actor, value) :: {t,t}
  def add(%Set{}=set, actor, value), do: add({set, Set.new}, actor, value)
  def add({%Set{dots: d}, %Set{dots: delta_dots}}, actor, value) do
    {new_dots, new_delta_dots} = {d, delta_dots}
                               |> Dots.remove(&({value,true}==&1 || {value,false}==&1))
                               |> Dots.add(actor, {value, true})
    {%Set{dots: new_dots}, %Set{dots: new_delta_dots}}
  end

  @doc """
  Removes a term from the set.

      iex> alias Loom.RWORSet, as: Set
      iex> Set.new |> Set.add(:a, "test1") |> Set.remove(:a, "test1") |> Set.member?("test1")
      false

  """
  @spec remove(t, actor, value) :: {t,t}
  @spec remove({t,t}, actor, value) :: {t,t}
  def remove(%Set{}=set, actor, value), do: remove({set, Set.new}, actor, value)
  def remove({%Set{dots: d}=set, %Set{dots: delta_dots}}, actor, value) do
    if member?(set, value) do
      {new_dots, new_delta_dots} = {d, delta_dots}
                                 |> Dots.remove(&({value,true}==&1 || {value,false}==&1))
                                 |> Dots.add(actor, {value, false})
      {%Set{dots: new_dots}, %Set{dots: new_delta_dots}}
    else
      raise Loom.PreconditionError, [unobserved: value]
    end
  end

  @doc """
  Tests if a value is an element of the set.

      iex> alias Loom.RWORSet, as: Set
      iex> Set.new |> Set.add(:a, "test1") |> Set.member?("test1")
      true

  """
  @spec member?({t, t}, value) :: boolean
  @spec member?(t, value) :: boolean
  def member?({set, _}, value), do: member?(set, value)
  def member?(%Set{dots: d}, value) do
    Dots.dots(d) |> Enum.any?(fn {_, term_pair} -> term_pair == {value,true} end)
  end

  @doc """
  Returns a list of set members

      iex> alias Loom.RWORSet, as: Set
      iex> Set.new |> Set.add(:a, "test1") |> Set.value
      ["test1"]

  """
  @spec value({t, t}) :: [value]
  @spec value(t) :: [value]
  def value({set, %Set{}}), do: value(set)
  def value(%Set{dots: d}) do
    (for {_, {v, true}} <- Dots.dots(d), do: v) |> Enum.uniq
  end


  @doc """
  Joins 2 sets together.

      iex> alias Loom.RWORSet, as: Set
      iex> {setA, _} = Set.new |> Set.add(:a, 1)
      iex> {setB, _} = Set.new |> Set.add(:b, 2)
      iex> Set.join(setA, setB) |> Set.value
      [1,2]

  """
  @spec join(t,t) :: t
  def join(%Set{dots: d1}, %Set{dots: d2}) do
    %Set{dots: Dots.join(d1, d2)}
  end

end

defimpl Loom.CRDT, for: Loom.RWORSet do

  alias Loom.RWORSet, as: Set

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This register
  returns a value.
  """
  def ops(_crdt) do
    [
      update: [
        add: [:actor, :value],
        remove: [:actor, :value],
      ],
      read: [
        is_member: [:value],
        value: []
      ]
    ]
  end

  @doc """
  Applies a CRDT to a counter in an abstract way.

  This is for ops-based support.

      iex> alias Loom.CRDT
      iex> reg = Loom.RWORSet.new |> CRDT.apply({:add, :a, "test"}) |> CRDT.apply({:add, :a, "testing"}) |> CRDT.apply({:remove, :a, "test"})
      iex> {CRDT.apply(reg, {:is_member, "testing"}), CRDT.apply(reg, {:is_member, "test"})}
      {true, false}

  """
  def apply(crdt, {:add, actor, value}) do
    {reg, _} = Set.add(crdt, actor, value)
    reg
  end
  def apply(crdt, {:remove, actor, value}) do
    {reg, _} = Set.remove(crdt, actor, value)
    reg
  end
  def apply(crdt, {:is_member, value}), do: Set.member?(crdt, value)
  def apply(crdt, :value), do: Set.value(crdt)

  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet).

      iex> alias Loom.CRDT
      iex> a = Loom.RWORSet.new |> CRDT.apply({:add, :a, "test"})
      iex> b = Loom.RWORSet.new |> CRDT.apply({:add, :b, "test2"})
      iex> CRDT.join(a,b) |> CRDT.apply(:value) |> Enum.sort
      ["test","test2"]

  """
  @spec join(Set.t, Set.t) :: Set.t
  def join(a, b), do: Set.join(a, b)

  @doc """
  Returns the most natural primitive value for a set, a list.

      iex> Loom.RWORSet.new |> Loom.CRDT.value
      []

  """
  def value(crdt), do: Set.value(crdt)

end
