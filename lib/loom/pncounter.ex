defmodule Loom.PNCounter do
  alias Loom.PNCounter, as: Counter

  defstruct p: %{}, n: %{}

  def new, do: %Counter{}

  def inc(%Counter{p: p}=c, actor, int \\ 1) when int > 0 do
    %Counter{c|p: Map.update(p, actor, int, &(&1+int))}
  end

  def dec(%Counter{n: n}=c, actor, int \\ 1) when int > 0 do
    %Counter{c|n: Map.update(n, actor, int, &(&1+int))}
  end

  def value(%Counter{p: p, n: n}) do
    (Dict.values(p) |> Enum.sum) - (Dict.values(n) |> Enum.sum)
  end

  def join(%Counter{p: p1, n: n1}, %Counter{p: p2, n: n2}) do
    %Counter{
      p: Dict.merge(p1, p2, fn (_,v1,v2) -> max(v1,v2) end),
      n: Dict.merge(n1, n2, fn (_,v1,v2) -> max(v1,v2) end)
    }
  end

end
