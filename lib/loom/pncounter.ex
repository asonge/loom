defmodule Loom.PNCounter do
  @moduledoc """
  Positive-negative counters
  
  PNCounters are counters that are capable of incrementing and decrementing.
  They are useful for like counters, where a user may like and then unlike
  something in succession.

  They are not delta-CRDT's, as they are rather lightweight in general. A delta-
  CRDT implementation would just return the latest value for an actor.

  They do, however, implement the CRDT protocol, and can be coposed into larger
  CRDT datastructures.
  """

  alias Loom.PNCounter, as: Counter

  @type actor :: term
  @type dot :: {actor, pos_integer}
  @type t :: %Counter{
    p: %{
      actor => pos_integer
    },
    n: %{
      actor => pos_integer
    }
  }

  defstruct p: %{}, n: %{}

  @doc """
  Instantiate a new PNCounter. Starts at 0.

      iex> Loom.PNCounter.new |> Loom.PNCounter.value
      0

  """
  @spec new() :: t
  def new, do: %Counter{}

  @doc """
  Instantiate a new PNCounter with previous values.

      iex> alias Loom.PNCounter, as: Counter
      iex> values = [a: {10,0}, b: {5,5}, c: {37,5}]
      iex> Counter.new(values: values) |> Counter.value
      42

  """
  @spec new([values: [{actor, {non_neg_integer,non_neg_integer}}]]) :: t
  def new(opts) do
    values = Keyword.get(opts, :values, [])
    if Enum.any?(values, fn {_, {v1,v2}} -> v1 < 0 || v2 < 0 end) do
      raise ArgumentError, "Values must be >= 0"
    end
    {p, n} = Enum.reduce(values, {%{},%{}}, fn {actor, {inc,dec}}, {p, n} ->
                {
                  (if inc, do: Dict.put(p, actor, inc), else: p),
                  (if dec, do: Dict.put(n, actor, dec), else: n)
                }
              end)
    %Counter{p: p, n: n}
  end

  @doc """
  Increment a counter on behalf of the actor.

      iex> alias Loom.PNCounter, as: Counter
      iex> Counter.new
      ...> |> Counter.inc(:a, 1)
      ...> |> Counter.inc(:a, 29)
      ...> |> Counter.value
      30

  """
  @spec inc(t, actor, pos_integer) :: t
  def inc(%Counter{p: p}=c, actor, int \\ 1) when int > 0 do
    %Counter{c|p: Map.update(p, actor, int, &(&1+int))}
  end

  @doc """
  Decrement a counter on behalf of the actor.

      iex> alias Loom.PNCounter, as: Counter
      iex> Counter.new
      ...> |> Counter.dec(:a, 1)
      ...> |> Counter.dec(:a, 29)
      ...> |> Counter.value
      -30
      iex> Counter.new
      ...> |> Counter.inc(:a, 1)
      ...> |> Counter.dec(:a, 1)
      ...> |> Counter.value
      0

  """
  @spec dec(t, actor, pos_integer) :: t
  def dec(%Counter{n: n}=c, actor, int \\ 1) when int > 0 do
    %Counter{c|n: Map.update(n, actor, int, &(&1+int))}
  end

  @doc """
  Gets a natural value for the counter.

  For counters, it is an integer.
  """
  @spec value(t) :: integer
  def value(%Counter{p: p, n: n}) do
    (Dict.values(p) |> Enum.sum) - (Dict.values(n) |> Enum.sum)
  end

  @doc """
  Joins 2 counters together.

      iex> alias Loom.PNCounter, as: Counter
      iex> ctr1 = Counter.new |> Counter.inc(:a) |> Counter.dec(:a, 10)
      iex> ctr2 = Counter.new |> Counter.dec(:b) |> Counter.inc(:b, 5)
      iex> Counter.join(ctr1,ctr2) |> Counter.value
      -5

  """
  @spec join(t, t) :: t
  def join(%Counter{p: p1, n: n1}, %Counter{p: p2, n: n2}) do
    %Counter{
      p: Dict.merge(p1, p2, fn (_,v1,v2) -> max(v1,v2) end),
      n: Dict.merge(n1, n2, fn (_,v1,v2) -> max(v1,v2) end)
    }
  end

end

defimpl Loom.CRDT, for: Loom.PNCounter do

  alias Loom.PNCounter, as: Ctr

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This counter
  returns an integer.
  """
  def ops(_crdt) do
    [ update: [
      inc: [:actor],
      inc: [:actor, :int],
      dec: [:actor],
      dec: [:actor, :int]
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
      iex> alias Loom.PNCounter, as: Counter
      iex> ctr = Counter.new |> CRDT.apply({:inc, :a}) |> CRDT.apply({:inc, :a, 3})
      iex> CRDT.value(ctr)
      4
      iex> ctr = ctr |> CRDT.apply({:dec, :a}) |> CRDT.apply({:dec, :a, 5})
      iex> CRDT.apply(ctr, :value)
      -2

  """
  def apply(crdt, {:inc, actor}), do: Ctr.inc(crdt, actor)
  def apply(crdt, {:inc, actor, int}), do: Ctr.inc(crdt, actor, int)
  def apply(crdt, {:dec, actor}), do: Ctr.dec(crdt, actor)
  def apply(crdt, {:dec, actor, int}), do: Ctr.dec(crdt, actor, int)
  def apply(crdt, :value), do: Ctr.value(crdt)
  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet). In the future, we may be able to join
  different counters and merge their semantics, as long as the datatype grows
  monotonically.

      iex> alias Loom.CRDT
      iex> alias Loom.PNCounter, as: Counter
      ...> Counter.new |> CRDT.apply({:inc, :a, 2})
      ...> |> CRDT.join(Counter.new |> CRDT.apply({:dec, :b, 5}))
      ...> |> CRDT.value
      -3

  """
  def join(%Ctr{}=a, %Ctr{}=b), do: Ctr.join(a, b)
  @doc """
  Returns the most natural value for a counter, an integer.
  """
  def value(crdt), do: Ctr.value(crdt)

end
