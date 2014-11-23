defmodule Loom.AWORMap do
  @moduledoc """
  An add-wins observed-remove map, based on optimized sets.
  """

  alias Loom.AWORMap, as: M
  alias Loom.AWORSet, as: Set
  # alias Loom.Dots

  #defstruct dots: Dots.new()
  defstruct keys: Set.new, values: %{}

  def new, do: %M{}

  def value(%M{values: values}), do: values

  def get(map, key, %{__struct__: module}), do: get(map, key, module)
  def get(%M{values: values}=map, key, module) do
    for {k,mod} <- keys(map), k == key, mod == module do
      values[{k,mod}]
    end |> case do
      [value] -> value
      [] -> nil
    end
  end

  def keys(%M{keys: set}), do: Set.value(set)

  def has_key?(%M{keys: set}, key, module), do: Set.member?(set, {key, module})

  def add(%M{}=map, actor, key, value), do: add({map, M.new}, actor, key, value)
  def add({%M{keys: set, values: vals}=m, %M{keys: delta_set, values: delta_vals}=d}, actor, key, value) do
    %{__struct__: struct_name} = value
    key_struct = {key, struct_name}
    {new_set, new_delta_set} = Set.add({set, delta_set}, actor, key_struct)
    new_values = Map.update(vals, key_struct, value, &Loom.CRDT.join(value,&1))
    new_delta_values = Map.update(delta_vals, key_struct, value, &Loom.CRDT.join(value,&1))
    {%M{m|keys: new_set, values: new_values}, %M{d|keys: new_delta_set, values: new_delta_values}}
  end

  def remove(%M{}=set, key, value), do: remove({set, M.new}, key, value)
  def remove({%M{keys: set, values: vals}=m, %M{keys: delta_set, values: delta_vals}=d}, key, value) do
    %{__struct__: struct_name} = value
    key_struct = {key, struct_name}
    {new_set, new_delta_set} = Set.remove({set, delta_set}, key_struct)
    new_values = Map.delete(vals, key_struct)
    new_delta_values = Map.delete(delta_vals, key_struct)
    {%M{m|keys: new_set, values: new_values}, %M{d|keys: new_delta_set, values: new_delta_values}}
  end

  def join(%M{keys: set1, values: values1}, %M{keys: set2, values: values2}) do
    new_set = Set.join(set1, set2)
    new_values = for key <- Set.value(new_set), into: %{} do
      new_value = case {Set.member?(set1, key), Set.member?(set2, key)} do
        {true, true} -> Loom.CRDT.join(values1[key], values2[key])
        {true, _} -> values1[key]
        {_, true} -> values2[key]
      end
      {key, new_value}
    end
    %M{keys: new_set, values: new_values}
  end

  # defp match_keyspec({key, %{__struct__: s}}, key, %{__struct__: s}), do: true
  # defp match_keyspec(_, _, _), do: false

end
