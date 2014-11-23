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

  @doc "Return a new GCounter"
  @spec new() :: t
  def new, do: %Counter{}

  @doc """
  Instantiate a new GCounter with context ctx. Use this when composing nested
  CRDT's to prevent updates from previous versions from leaking through.
  """
  @spec new([ctx: [dot], values: [{actor, pos_integer}]]) :: t
  def new(_opts) do
    # values = Keyword.pop
    # context = ctx
    %Counter{}
  end

  @doc "Increment a counter on behalf of the actor."
  @spec inc(t, actor, pos_integer) :: t
  def inc(%Counter{counter: c}, actor, int \\ 1) when int > 0 do
    %Counter{counter: Map.update(c, actor, int, &(&1+int))}
  end

  @doc "Return a new GCounter"
  @spec op({:inc, t, actor}) :: t
  @spec op({:inc, t, actor, pos_integer}) :: t
  def op({:inc, counter, actor}), do: inc(counter, actor)
  def op({:inc, counter, actor, int}), do: inc(counter, actor, int)

  @doc "Return a new GCounter"
  @spec value(t) :: non_neg_integer
  def value(%Counter{counter: c}) do
    Dict.values(c) |> Enum.sum
  end

  @doc "Return a new GCounter"
  @spec join(t, t) :: t
  def join(%Counter{counter: c1}, %Counter{counter: c2}) do
    %Counter{counter: Dict.merge(c1, c2, fn (_,v1,v2) -> max(v1,v2) end)}
  end

end

defimpl Loom.CRDT, for: Loom.GCounter do

  def join(a, b), do: Loom.GCounter.join(a, b)

end
