defmodule Loom.RWORSet do
  alias Loom.RWORSet, as: Set
  alias Loom.Dots

  defstruct dots: Dots.new()

  def new, do: %Set{}

  def read(%Set{dots: d}) do
    (for {_, {v, true}} <- Dots.dots(d), do: v) |> Enum.uniq
  end

  def member?(%Set{dots: d}, value) do
    Dots.dots(d) |> Enum.any?(fn {_, term_pair} -> term_pair == {value,true} end)
  end

  def add(%Set{}=set, actor, value), do: add({set, Set.new}, actor, value)
  def add({%Set{dots: d}, %Set{dots: delta_dots}}, actor, value) do
    {new_dots, new_delta_dots} = {d, delta_dots}
                               |> Dots.remove({value, true})
                               |> Dots.remove({value, false})
                               |> Dots.add(actor, value)
    {%Set{dots: new_dots}, %Set{dots: new_delta_dots}}
  end

  def remove(%Set{}=set, value), do: remove({set, Set.new}, value)
  def remove({%Set{dots: d}, %Set{dots: delta_dots}}, id, value) do
    {new_dots, new_delta_dots} = {d, delta_dots}
                               |> Dots.remove({value, true})
                               |> Dots.remove({value, false})
                               |> Dots.add(id, {value, false})
    {%Set{dots: new_dots}, %Set{dots: new_delta_dots}}
  end

  def join(%Set{dots: d1}, %Set{dots: d2}) do
    %Set{dots: Dots.join(d1, d2)}
  end

end
