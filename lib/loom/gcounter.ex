defmodule Loom.GCounter do
  alias Loom.GCounter, as: Counter

  defstruct counter: %{}

  def new, do: %Counter{}

  def inc(%Counter{counter: c}, actor, int \\ 1) when int > 0 do
    %Counter{counter: Map.update(c, actor, int, &(&1+int))}
  end

  def value(%Counter{counter: c}) do
    Dict.values(c) |> Enum.sum
  end

  def join(%Counter{counter: c1}, %Counter{counter: c2}) do
    %Counter{counter: Dict.merge(c1, c2, fn (_,v1,v2) -> max(v1,v2) end)}
  end

end
