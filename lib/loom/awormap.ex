defmodule Loom.AWORMap do
  @moduledoc """
  An add-wins observed-remove map or CRDTs, based on optimized sets.

  Compose any CRDT that implements the `Loom.CRDT` protocol. This is awkward by
  itself because of the use of copious key-module pairs.
  """

  alias Loom.AWORMap, as: M
  alias Loom.AWORSet, as: Set

  @type key :: term
  @type actor :: term
  @type crdt :: term
  @type type :: atom | %{__struct__: atom}
  @opaque t :: %M{
    keys: Set.t,
    values: %{key => crdt}
  }

  defstruct keys: Set.new, values: %{}

  @doc """
  Returns a new AWORMap

  The identity value of an empty AWORMap is `nil` because of the difficulties
  of matching against `%{}`, which is not the equivalent of `[]`.

      iex> Loom.AWORMap.new |> Loom.AWORMap.value
      nil
  """
  @spec new() :: t
  def new, do: %M{}

  @doc """
  Insert a value, and merge it with any that exist already
  """
  @spec put(t | {t,t}, actor, key, crdt) :: {t,t}
  def put(%M{}=map, actor, key, value), do: put({map, M.new}, actor, key, value)
  def put({%M{keys: set, values: vals}=m, %M{keys: delta_set, values: delta_vals}=d}, actor, key, value) do
    %{__struct__: struct_name} = value
    key_struct = {key, struct_name}
    {new_set, new_delta_set} = Set.add({set, delta_set}, actor, key_struct)
    new_values = Map.update(vals, key_struct, value, &Loom.CRDT.join(value,&1))
    new_delta_values = Map.update(delta_vals, key_struct, value, &Loom.CRDT.join(value,&1))
    {%M{m|keys: new_set, values: new_values}, %M{d|keys: new_delta_set, values: new_delta_values}}
  end

  @doc """
  Delete an entry for a key-module pair
  """
  @spec delete(t | {t,t}, key, type) :: {t,t}
  def delete(set, key, %{__struct__: module}), do: delete(set, key, module)
  def delete(%M{}=set, key, module), do: delete({set, M.new}, key, module)
  def delete({%M{keys: set, values: vals}=m, %M{keys: delta_set, values: delta_vals}=d}, key, module) do
    key_struct = {key, module}
    {new_set, new_delta_set} = Set.remove({set, delta_set}, key_struct)
    new_values = Map.delete(vals, key_struct)
    new_delta_values = Map.delete(delta_vals, key_struct)
    {%M{m|keys: new_set, values: new_values}, %M{d|keys: new_delta_set, values: new_delta_values}}
  end

  @doc """
  Join a map
  """
  @spec join(t, t) :: t
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

  @doc """
  Get a value for a key-module pair
  """
  @spec get(t | {t,t}, key, type) :: term
  def get(map, key, %{__struct__: module}), do: get(map, key, module)
  def get(%M{values: values}=map, key, module) do
    for {k,mod} <- keys(map), k == key, mod == module do
      values[{k,mod}]
    end |> case do
      [value] -> value
      [] -> struct(module)
    end |> Loom.CRDT.value
  end

  @doc """
  Returns the set of all key-module pairs
  """
  @spec keys(t) :: [{key,type}]
  def keys(%M{keys: set}), do: Set.value(set)

  @doc """
  Checks if a key-module pair exists in the map already for the key.
  """
  @spec has_key?(t | {t,t}, key, module) :: boolean
  def has_key?({set, %M{}}, key, module), do: has_key?(set, key, module)
  def has_key?(%M{keys: set}, key, module), do: Set.member?(set, {key, module})

  @doc """
  Returns a map of values for key-module pairs
  """
  @spec value(t) :: [{key,term}] | nil
  def value(%M{values: values}) when map_size(values)==0, do: nil
  def value(%M{values: values}) do
    for {k, crdt} <- values, into: %{}, do: {k, Loom.CRDT.value(crdt)}
  end

end

defimpl Loom.CRDT, for: Loom.AWORMap do

  alias Loom.AWORMap, as: KVSet

  @doc """
  Returns a description of the operations that this CRDT takes.

  Updates return a new CRDT, reads can return any natural datatype. This register
  returns a value.
  """
  def ops(_crdt) do
    [
      update: [
        delete: [:key, :value_type],
        put: [:actor, :key, :value]
      ],
      read: [
        get: [:value],
        keys: [],
        has_key: [],
        value: []
      ]
    ]
  end

  @doc """
  Applies a CRDT to a counter in an abstract way.

  This is for ops-based support.

      iex> alias Loom.CRDT
      iex> alias Loom.LWWRegister
      iex> bar = LWWRegister.new("bar")
      iex> wtf = LWWRegister.new("wtf")
      iex> Loom.AWORMap.new
      ...> |> CRDT.apply({:put, :a, "foo", bar})
      ...> |> CRDT.apply({:put, :a, "omg", wtf})
      ...> |> CRDT.apply({:delete, "omg", LWWRegister})
      ...> |> CRDT.apply(:value)
      %{{"foo", Loom.LWWRegister} => "bar"}

      iex> alias Loom.CRDT
      iex> Loom.AWORMap.new |> CRDT.apply({:has_key, :none, Loom.LWWRegister})
      false

      iex> alias Loom.CRDT
      iex> Loom.AWORMap.new |> CRDT.apply({:get, :none, Loom.LWWRegister})
      nil

      iex> alias Loom.CRDT
      iex> Loom.AWORMap.new |> CRDT.apply(:keys)
      []

  """
  def apply(crdt, {:put, actor, key, value}) do
    {map, _} = KVSet.put(crdt, actor, key, value)
    map
  end
  def apply(crdt, {:delete, key, module}) do
    {map, _} = KVSet.delete(crdt, key, module)
    map
  end
  def apply(crdt, {:get, key, module}), do: KVSet.get(crdt, key, module)
  def apply(crdt, {:has_key, key, module}), do: KVSet.has_key?(crdt, key, module)
  def apply(crdt, :keys), do: KVSet.keys(crdt)
  def apply(crdt, :value), do: KVSet.value(crdt)

  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet).

      iex> alias Loom.CRDT
      iex> alias Loom.MVRegister, as: Reg
      iex> {test_a,_} = Reg.new |> Reg.set(:a, 1)
      iex> {test_b,_} = Reg.new |> Reg.set(:b, 2)
      iex> a = Loom.AWORMap.new |> CRDT.apply({:put, :a, :test, test_a})
      iex> b = Loom.AWORMap.new |> CRDT.apply({:put, :b, :test, test_b})
      iex> CRDT.join(a,b) |> CRDT.apply(:value)
      %{{:test, Loom.MVRegister} => [1,2]}

  """
  def join(a, b), do: KVSet.join(a, b)

  @doc """
  Returns the most natural primitive value for a set, a list.

  iex> Loom.AWORMap.new |> Loom.CRDT.value
  nil

  """
  def value(crdt), do: KVSet.value(crdt)

end
