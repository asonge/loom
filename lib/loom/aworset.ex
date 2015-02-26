defmodule Loom.AWORSet do
  @moduledoc """
  An add-removed (optimized) observed-remove set (without tombstones).

  This CRDT respects adds over removes in the event a simultaneous update. It
  most naturally matches what most users expect when they add/remove items. It
  also forms the foundation for other kinds of CRDT's, such as our AWORMap and
  MVRegister.
  """

  alias __MODULE__, as: Set
  alias Loom.Dots

  @type actor :: term
  @type value :: term
  @opaque t :: %Set{
    dots: Dots.t,
    keep_delta: boolean,
    delta: Dots.t | nil
  }

  defstruct dots: %Dots{}, keep_delta: true, delta: nil

  @doc """
  Creates a new AWORSet

  The identity value for this is `[]`, an empty set.

      iex> alias Loom.AWORSet, as: Set
      iex> Set.new |> Set.value
      []

  """
  @spec new() :: t
  def new, do: %Set{dots: Dots.new, delta: Dots.new}

  @doc """
  Grab the delta from an AWORSet for lower-cost synchronization.
  """
  @spec delta(t) :: t
  def delta(%Set{delta: delta}), do: %Set{dots: delta}

  @doc """
  Clear the delta from an AWORSet to preserve space. Do this after you sync
  "enough".
  """
  @spec clear_delta(t) :: t
  def clear_delta(%Set{}=set), do: %Set{set|delta: Dots.new}

  @doc """
  Add an element to an AWORSet

      iex> alias Loom.AWORSet, as: Set
      iex> Set.new |> Set.add(:a, 1) |> Set.add(:b, 2) |> Set.value |> Enum.sort
      [1,2]
  """
  @spec add(t, actor, value) :: t
  def add(%Set{dots: d, delta: delta_dots}=set, actor, value) do
    {new_dots, new_delta_dots} = {d, delta_dots}
                               |> Dots.remove(value)
                               |> Dots.add(actor, value)
    %Set{set|dots: new_dots, delta: new_delta_dots}
  end

  @doc """
  Remove an element from an AWORSet

      iex> alias Loom.AWORSet, as: Set
      iex> Set.new
      ...> |> Set.add(:a, 1)
      ...> |> Set.add(:a, 2)
      ...> |> Set.remove(1)
      ...> |> Set.value
      [2]
  """
  @spec remove(t, value) :: t
  def remove(%Set{dots: d, delta: delta_dots}=set, value) do
    if member?(set, value) do
      {new_dots, new_delta_dots} = {d, delta_dots} |> Dots.remove(value)
      %Set{dots: new_dots, delta: new_delta_dots}
    else
      raise Loom.PreconditionError, unobserved: value
    end
  end

  @doc """
  Empties a CRDT of all elements

      iex> alias Loom.AWORSet, as: Set
      iex> Set.new
      ...> |> Set.add(:a, 1)
      ...> |> Set.empty
      ...> |> Set.value
      []
  """
  @spec empty(t) :: t
  def empty(%Set{dots: d, delta: delta_dots}=set) do
    {new_dots, new_delta_dots} = Dots.remove({d, delta_dots})
    %Set{set|dots: new_dots, delta: new_delta_dots}
  end

  @doc """
  Join 2 CRDTs together

      iex> alias Loom.AWORSet, as: Set
      iex> a = Set.new |> Set.add(:a, 1)
      iex> b = Set.new |> Set.add(:b, 2)
      iex> Set.join(a, b) |> Set.value |> Enum.sort
      [1,2]
  """
  @spec join(t,t) :: t
  def join(%Set{dots: d1}=set, %Set{dots: d2}) do
    %Set{set|dots: Dots.join(d1, d2)}
  end

  @doc """
  Check to see if an element is a member of a set.

      iex> alias Loom.AWORSet, as: Set
      iex> Set.new
      ...> |> Set.add(:a, 1)
      ...> |> Set.member?(1)
      true

  """
  @spec member?(t, value) :: boolean
  def member?(%Set{dots: d}, value) do
    Dots.dots(d) |> Enum.any?(fn {_, v} -> v == value end)
  end

  @doc """
  Returns a list of set elements.

  See other examples for details.
  """
  @spec value(t) :: [value]
  def value(%Set{dots: d}) do
    (for {_, v} <- Dots.dots(d), do: v) |> Enum.uniq
  end

end

defimpl Loom.CRDT, for: Loom.AWORSet do

  alias Loom.AWORSet, as: Set

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This register
  returns a value.
  """
  def ops(_crdt) do
    [
      update: [
        add: [:actor, :value],
        remove: [:actor],
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
      iex> reg = Loom.AWORSet.new |> CRDT.apply({:add, :a, "test"}) |> CRDT.apply({:add, :a, "testing"}) |> CRDT.apply({:remove, "test"})
      iex> {CRDT.apply(reg, {:is_member, "testing"}), CRDT.apply(reg, {:is_member, "test"})}
      {true, false}

  """
  def apply(crdt, {:add, actor, value}) do
    Set.add(crdt, actor, value)
  end
  def apply(crdt, {:remove, value}) do
    Set.remove(crdt, value)
  end
  def apply(crdt, {:is_member, value}), do: Set.member?(crdt, value)
  def apply(crdt, :value), do: Set.value(crdt)

  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet).

      iex> alias Loom.CRDT
      iex> a = Loom.AWORSet.new |> CRDT.apply({:add, :a, "test"})
      iex> b = Loom.AWORSet.new |> CRDT.apply({:add, :b, "test2"})
      iex> CRDT.join(a,b) |> CRDT.apply(:value) |> Enum.sort
      ["test","test2"]

  """
  def join(a, b), do: Set.join(a, b)

  @doc """
  Returns the most natural primitive value for a set, a list.

  iex> Loom.AWORSet.new |> Loom.CRDT.value
  []

  """
  def value(crdt), do: Set.value(crdt)

end
