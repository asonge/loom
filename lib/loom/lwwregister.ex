defmodule Loom.LWWRegister do
  @moduledoc """
  A Last-write-wins register

  While alone, this kinda defeats the point of a CRDT, there are times, such as
  in a map or other kind of composite CRDT, where an individual value should
  be last-write-wins, but we'd like to preserve causality between all the
  properties.

  This is one of the most simple CRDT's possible.
  """
  alias __MODULE__, as: Reg
  @type t :: %Reg{
    value: term,
    clock: nil | pos_integer
  }

  defstruct value: nil, clock: nil

  @doc """
  Returns a new LWWRegister CRDT.

  `nil` is a new CRDT's identity value, and by default the system time in
  microseconds is used as the clock value.

      iex> Loom.LWWRegister.new |> Loom.LWWRegister.value
      nil

  """
  @spec new :: t
  def new, do: %Reg{}

  @doc """
  Returns a new LWWRegister CRDT. Initializes to `value`.

      iex> Loom.LWWRegister.new("test") |> Loom.LWWRegister.value
      "test"

  """
  @spec new(term) :: t
  def new(value), do: new |> set(value)

  @doc """
  Returns a new LWWRegister CRDT. Initializes to `value` with another clock

      iex> Loom.LWWRegister.new("test", 5) |> Loom.LWWRegister.value
      "test"

  """
  @spec new(term, pos_integer) :: t
  def new(value, clock), do: new |> set(value, clock)


  @doc """
  Sets a value using the built-in clock

      iex> alias Loom.LWWRegister, as: Reg
      iex> Reg.new("test")
      ...> |> Reg.set("test2")
      ...> |> Reg.value
      "test2"

  """
  @spec set(t, term) :: t
  def set(reg, value), do: set(reg, value, make_microtime)

  @doc """
  Set a value according to your own clock.

      iex> alias Loom.LWWRegister, as: Reg
      iex> Reg.new("test", 5)
      ...> |> Reg.set("test2", 10)
      ...> |> Reg.set("won't set.", 2)
      ...> |> Reg.value
      "test2"

  """
  @spec set(t, term, pos_integer) :: t
  def set(%Reg{value: nil}, value, clock), do: %Reg{value: value, clock: clock}
  def set(reg, value, clock), do: join(reg, %Reg{value: value, clock: clock})

  @doc """
  Joins 2 LWWRegisters

      iex> alias Loom.LWWRegister, as: Reg
      iex> a = Reg.new("test") |> Reg.set("test2")
      iex> :timer.sleep(1)
      iex> Reg.new("take over") |> Reg.join(a) |> Reg.value
      "take over"

  In the event that 2 have the same clock, it simply takes the biggest according
  to Elixir's rules. If you want something more portable, string comparisons are
  likely to be the same across languages.

      iex> alias Loom.LWWRegister, as: Reg
      iex> a = Reg.new("test", 10) |> Reg.set("test2", 11)
      iex> b = Reg.new("take over", 11)
      ...> Reg.join(a,b) |> Reg.value
      "test2"

  """
  @spec join(t, t) :: t
  def join(a, a), do: a
  def join(a, %Reg{clock: nil}=b), do: a
  def join(%Reg{clock: nil}=a, b), do: b
  def join(%Reg{clock: c}=a, %Reg{clock: c}=b) do
    if a > b, do: a, else: b
  end
  def join(%Reg{clock: ac}=a, %Reg{clock: bc}) when ac > bc, do: a
  def join(%Reg{clock: ac}, %Reg{clock: bc}=b) when ac < bc, do: b

  @doc """
  Returns the natural value of the register. Can be any type, really.
  """
  @spec value(t) :: term
  def value(%Reg{value: value}), do: value

  defp make_microtime do
    {mega, sec, micro} = :os.timestamp
    (mega * 1000000 + sec) * 1000000 + micro
  end

end

defimpl Loom.CRDT, for: Loom.LWWRegister do

  alias Loom.LWWRegister, as: Reg

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This register
  returns a value.
  """
  def ops(_crdt) do
    [ update: [
      set: [:value],
      set: [:value, :clock]
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
      iex> alias Loom.LWWRegister, as: Reg
      iex> ctr = Reg.new |> CRDT.apply({:set, "test"}) |> CRDT.apply({:set, "testing"})
      iex> CRDT.value(ctr)
      "testing"

      iex> alias Loom.CRDT
      iex> alias Loom.LWWRegister, as: Reg
      iex> ctr = Reg.new |> CRDT.apply({:set, "test", 10}) |> CRDT.apply({:set, "testing", 11})
      iex> CRDT.apply(ctr, :value)
      "testing"

  """
  def apply(crdt, {:set, value}), do: Reg.set(crdt, value)
  def apply(crdt, {:set, value, clock}), do: Reg.set(crdt, value, clock)
  def apply(crdt, :value), do: Reg.value(crdt)
  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet). In the future, we may be able to join
  different counters and merge their semantics, as long as the datatype grows
  monotonically.

      iex> alias Loom.CRDT
      iex> a = Loom.LWWRegister.new |> CRDT.apply({:set, "test", 10})
      iex> b = Loom.LWWRegister.new |> CRDT.apply({:set, "test2", 11})
      iex> CRDT.join(a,b) |> CRDT.value
      "test2"

      iex> alias Loom.CRDT
      iex> a = Loom.LWWRegister.new("test")
      iex> CRDT.join(a,a) |> CRDT.value()
      "test"

  """
  def join(a, %Reg{}=b), do: Reg.join(a, b)

  @doc """
  Returns the most natural value for a counter, an integer.
  """
  def value(crdt), do: Reg.value(crdt)

end
