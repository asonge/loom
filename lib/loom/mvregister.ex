defmodule Loom.MVRegister do
  @moduledoc """
  A causally consistent multi-value register.

  A bit more causally rigorous than LWWRegister, MVRegister will replace
  observed values when they are set, but concurrent additions will co-occur,
  and a list will be returned for the value.

  This is good if you have some reasonable way of figuring out how to resolve
  this further down your app keychain (including user resolution), but you can't
  make it generic enough to work as a CRDT.
  """

  alias __MODULE__, as: Reg
  alias Loom.Dots

  @type actor :: term
  @type value :: term
  @type t :: %Reg{
    dots: Dots.t,
    keep_delta: boolean,
    delta: Dots.t | nil
  }

  defstruct dots: %Dots{}, keep_delta: true, delta: nil

  @doc """
  Returns a new MVRegister CRDT.

  `nil` is a new CRDT's identity value, and by default the system time in
  microseconds is used as the clock value.

      iex> Loom.MVRegister.new |> Loom.MVRegister.value
      nil

  """
  @spec new :: t
  def new, do: %Reg{delta: Dots.new}

  @doc """
  Grab the delta from an MVRegister for lower-cost synchronization.

      iex> alias Loom.MVRegister, as: Reg
      iex> a = Reg.new |> Reg.set(:a, 5)
      iex> delta_b = Reg.new |> Reg.set(:b, 2) |> Reg.delta
      iex> Reg.join(a, delta_b) |> Reg.value |> Enum.sort
      [2,5]

  """
  @spec delta(t) :: t
  def delta(%Reg{delta: delta}), do: %Reg{dots: delta}

  @doc """
  Clear the delta from an MVRegister to preserve space. Do this after you sync
  "enough".

      iex> alias Loom.MVRegister, as: Reg
      iex> Reg.new |> Reg.set(:a, 5) |> Reg.clear_delta |> Reg.delta == Reg.new |> Reg.delta
      true
  """
  @spec clear_delta(t) :: t
  def clear_delta(%Reg{}=reg), do: %Reg{reg|delta: Dots.new}

  @doc """
  Sets a value, erasing any current values.

      iex> alias Loom.MVRegister, as: Reg
      iex> Reg.new
      ...> |> Reg.set(:a, "test")
      ...> |> Reg.set(:a, "test2")
      ...> |> Reg.value
      "test2"

  """
  @spec set(t, actor, term) :: t
  def set(%Reg{dots: d, delta: delta}=reg, actor, value) do
    {new_dots, new_delta_dots} = {d, delta}
                                |> Dots.remove()
                                |> Dots.add(actor, value)
    %Reg{reg|dots: new_dots, delta: new_delta_dots}
  end

  @doc """
  Clear out an MVRegister

      iex> alias Loom.MVRegister, as: Reg
      iex> Reg.new
      ...> |> Reg.set(:a, 1)
      ...> |> Reg.empty()
      ...> |> Reg.value
      nil
  """
  @spec empty(t) :: t
  def empty(%Reg{dots: d, delta: delta}=reg) do
    {new_dots, new_delta_dots} = {d, delta} |> Dots.remove()
    %Reg{reg|dots: new_dots, delta: new_delta_dots}
  end


  @doc """
  Joins 2 MVRegisters

      iex> alias Loom.MVRegister, as: Reg
      iex> a = Reg.new |> Reg.set(:a, "test") |> Reg.set(:a, "test2")
      iex> b = Reg.new |> Reg.set(:b, "take over")
      iex> Reg.join(a, b) |> Reg.value
      ["test2", "take over"]
  """
  @spec join(t, t) :: t
  def join(%Reg{dots: d1}=reg, %Reg{dots: d2}) do
    %Reg{reg|dots: Dots.join(d1, d2)}
  end

  @doc """
  Returns the natural value of the register. If there is nothing, it's nil. If
  it's one thing, it's that value (this is the normal case). If it's more than
  one thing, all values are returned in a list.
  """
  @spec value(t) :: [term] | term | nil
  def value(%Reg{dots: d}) do
    values = (for {_, v} <- Dots.dots(d), do: v) |> Enum.uniq
    case values do
      [] -> nil
      [singleton] -> singleton
      mv -> mv
    end
  end

end

defimpl Loom.CRDT, for: Loom.MVRegister do

  alias Loom.MVRegister, as: Reg

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This register
  returns a value.
  """
  def ops(_crdt) do
    [ update: [
        set: [:actor, :value],
      ],
      read: [
        value: []
      ]
    ]
  end

  @doc """
  Applies a CRDT to a counter in an abstract way.

  This is for ops-based support.

      iex> alias Loom.CRDT
      iex> alias Loom.MVRegister, as: Reg
      iex> reg = Reg.new |> CRDT.apply({:set, :a, "test"}) |> CRDT.apply({:set, :a, "testing"})
      iex> CRDT.apply(reg, :value)
      "testing"

  """
  def apply(crdt, {:set, actor, value}) do
    Reg.set(crdt, actor, value)
  end
  def apply(crdt, :value), do: Reg.value(crdt)

  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet). In the future, we may be able to join
  different counters and merge their semantics, as long as the datatype grows
  monotonically.

      iex> alias Loom.CRDT
      iex> a = Loom.MVRegister.new |> CRDT.apply({:set, :a, "test"})
      iex> b = Loom.MVRegister.new |> CRDT.apply({:set, :b, "test2"})
      iex> CRDT.join(a,b) |> CRDT.value |> Enum.sort
      ["test","test2"]

  """
  def join(a, b), do: Reg.join(a, b)

  @doc """
  Returns the most natural value for a counter, an integer.
  """
  def value(crdt), do: Reg.value(crdt)

end
