defmodule Loom.GCounter do
  alias Loom.GCounter, as: Counter

  @type actor :: term
  @type dot :: {actor, pos_integer}
  @type t :: %Counter{
    counter: %{
      actor => pos_integer
    },
    ctx: %{
      actor => pos_integer
    }
  }

  defstruct counter: %{}, ctx: %{}

  @doc """
  Instantiate a new GCounter. Starts at 0.

    iex> Loom.GCounter.new |> Loom.GCounter.value
    0

  """
  @spec new() :: t
  def new, do: %Counter{}

  @doc """
  Instantiate a new GCounter with previous values.


    iex> Loom.GCounter.new(values: [a: 10, b: 5, c: 27]) |> Loom.GCounter.value
    42

  """
  @spec new([values: [{actor, pos_integer}]]) :: t
  def new(opts) do
    new_values = Keyword.get(opts, :values, []) |> Enum.into %{}
    %Counter{counter: new_values}
  end

  @doc """
  Increment a counter on behalf of the actor.

  If you need to decrement, see `Loom.PNCounter`

    iex> Loom.GCounter.new |> Loom.GCounter.inc(:a, 1) |> Loom.GCounter.inc(:a, 29) |> Loom.GCounter.value()
    30

  """
  @spec inc(t, actor, pos_integer) :: t
  def inc(%Counter{counter: c}, actor, int \\ 1) when int > 0 do
    %Counter{counter: Map.update(c, actor, int, &(&1+int))}
  end

  @doc """
  Get the value of a counter.

  Will always be >=0.
  """
  @spec value(t) :: non_neg_integer
  def value(%Counter{counter: c}) do
    Dict.values(c) |> Enum.sum
  end

  @doc """
  Joins 2 counters.

  Because counters monotonically increase, we can just merge them.

    iex> alias Loom.GCounter
    iex> ctr1 = GCounter.new |> GCounter.inc(:a) |> GCounter.inc(:a, 10)
    iex> ctr2 = GCounter.new |> GCounter.inc(:b) |> GCounter.inc(:b, 5)
    iex> GCounter.join(ctr1,ctr2) |> GCounter.value
    17

  """
  @spec join(t, t) :: t
  def join(%Counter{counter: c1}, %Counter{counter: c2}) do
    %Counter{counter: Dict.merge(c1, c2, fn (_,v1,v2) -> max(v1,v2) end)}
  end

end

defimpl Loom.CRDT, for: Loom.GCounter do

  alias Loom.GCounter, as: Ctr

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This counter
  returns an integer.
  """
  def ops(_crdt) do
    [ update: [
        inc: [:actor],
        inc: [:actor, :int]
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
    iex> alias Loom.GCounter
    iex> GCounter.new |> CRDT.apply({:inc, :a}) |> CRDT.apply({:inc, :a, 3}) |> CRDT.value
    4

  """
  def apply(crdt, {:inc, actor}), do: Ctr.inc(crdt, actor)
  def apply(crdt, {:inc, actor, int}), do: Ctr.inc(crdt, actor, int)
  def apply(crdt, :value), do: Ctr.value(crdt)
  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet). In the future, we may be able to join
  different counters and merge their semantics, as long as the datatype grows
  monotonically.
  """
  def join(%Ctr{}=a, %Ctr{}=b), do: Ctr.join(a, b)
  @doc """
  Returns the most natural value for a counter, an integer.
  """
  def value(crdt), do: Ctr.value(crdt)

end
