defmodule Loom.AWORMap do
  @moduledoc """
  An add-wins observed-remove map, based on optimized sets.
  """

  alias Loom.AWORMap, as: M
  alias Loom.Dots

  defstruct dots: Dots.new()

  def new, do: %M{}

  def read(%M{dots: d}) do
    for {_, {k,v}} <- Dots.dots(d), into: %{}, do: {k,v}
  end

  def get(map, key, %{__struct__: module}), do: get(map, key, module)
  def get(%M{dots: d}, key, module) do
    for {_, {k, v}} <- Dots.dots(d), k == key,
      Map.get(v, :__struct__)==module do v
    end |> case do
      [value] -> value
      [] -> struct(module)
    end
  end

  def keys(%M{dots: d}) do
    for {_, {k,_}} <- Dots.dots(d), do: k
  end

  def values(%M{dots: d}) do
    for {_, {_,v}} <- Dots.dots(d), do: v
  end

  def has_key?(%M{dots: d}, key) do
    Dots.dots(d) |> Enum.any?(fn {_, {k,v}} -> k == key end)
  end

  def add(%M{}=set, actor, key, value), do: add({set, M.new}, actor, key, value)
  def add({%M{dots: d}, %M{dots: delta_dots}}, actor, key, value) do
    {new_dots, new_delta_dots} = {d, delta_dots}
                               |> Dots.remove(&match_keyspec(&1, key, value))
                               |> Dots.add(actor, {key, value})
    {%M{dots: new_dots}, %M{dots: new_delta_dots}}
  end

  def remove(%M{}=set, key, value), do: remove({set, M.new}, key, value)
  def remove({%M{dots: d}, %M{dots: delta_dots}}, key, value) do
    {new_dots, new_delta_dots} = {d, delta_dots}
                               |> Dots.remove(&match_keyspec(&1, key, value))
    {%M{dots: new_dots}, %M{dots: new_delta_dots}}

  end

  def join(%M{dots: d1}, %M{dots: d2}) do
    %M{dots: M.join(d1, d2)}
  end

  defp match_keyspec({key, %{__struct__: s}}, key, %{__struct__: s}), do: true
  defp match_keyspec(_, _, _), do: false

end
