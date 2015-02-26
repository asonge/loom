defmodule Loom.AWORMap do
  @moduledoc """
  An add-wins observed-remove map or CRDTs, based on optimized sets.

  Compose any CRDT that implements the `Loom.CRDT` protocol. This is awkward by
  itself because of the use of copious key-module pairs.
  """

  alias Loom.AWORMap, as: M
  alias Loom.Dots, as: Dots
  alias Loom.CRDT

  @type key :: term
  @type actor :: term
  @type crdt :: term
  @type type :: atom | %{__struct__: atom}
  @opaque t :: %M{
    dots: Dots.t,
    keep_delta: boolean,
    delta: Dots.t
  }

  defstruct dots: Dots.new, keep_delta: true, delta: nil

  @doc """
  Returns a new AWORMap

  The identity value of an empty AWORMap is `nil` because of the difficulties
  of matching against `%{}`, which is not the equivalent of `[]`.

      iex> Loom.AWORMap.new |> Loom.AWORMap.value
      nil
  """
  @spec new() :: t
  def new, do: %M{delta: Dots.new}

  @doc """
  Returns the currently-running delta of an AWORMap
  """
  @spec delta(t) :: t
  def delta(%M{delta: delta}), do: %M{dots: delta}

  @doc """
  You can use this to clear the delta from an AWORMap. Clearing the delta can
  help shrink the memory usage of this CRDT.
  """
  @spec clear_delta(t) :: t
  def clear_delta(%M{}=m), do: %M{m|delta: Dots.new}

  @doc """
  Insert a value, and merge it with any that exist already
  """
  @spec put(t, actor, key, crdt) :: t
  def put(%M{dots: d, delta: d_dots}=m, actor, key, crdt) do
    %{__struct__: struct_name} = crdt
    new_crdt = case get(m, key, crdt) do
      nil -> crdt
      old_crdt -> CRDT.join(crdt, old_crdt)
    end
    {new_dots, new_d_dots} = {d, d_dots}
                             |> Dots.remove(fn {dk, %{__struct__: ds}} ->
                                  dk == key && ds == struct_name
                                end)
                             |> Dots.add(actor, {key, new_crdt})
    %M{dots: new_dots, delta: new_d_dots}
  end

  @doc """
  Delete an entry for a key-module pair
  """
  # This really just empties the old CRDT. We'll figure out a way to prune these
  # in future time. This might require trying to manage CRDT's via some kind of
  # global context, but that breaks internal contiguity needed for delta-CRDT's.
  @spec delete(t, key, type) :: t
  def delete(set, key, %{__struct__: module}), do: delete(set, key, module)
  def delete(%M{dots: d, delta: d_dots}, key, module) do
    {new_dots, new_d_dots} = {d, d_dots}
                              |> Dots.remove(fn {dk, %{__struct__: ds}} ->
                                dk == key && ds == module
                              end)
    %M{dots: new_dots, delta: new_d_dots}
  end

  @doc """
  Join a map
  """
  @spec join(t, t) :: t
  def join(%M{dots: d1}=m, %M{dots: d2}) do
    %M{m|dots: Dots.join(d1, d2)}
  end

  @doc """
  Empties out an existing map.

  iex> alias Loom.CRDT
  iex> alias Loom.AWORMap, as: KVMap
  iex> KVMap.new
  iex> |> KVMap.put(:a, "key", Loom.LWWRegister.new("test"))
  iex> |> KVMap.empty
  iex> |> CRDT.value
  nil
  """
  @spec empty(t) :: t
  def empty(%M{dots: d, delta: d_dots}=m) do
    {new_d, new_d_dots} = Dots.empty({d, d_dots})
    %M{m|dots: new_d, delta: new_d_dots}
  end

  @doc """
  Get a value for a key-module pair
  """
  @spec get(t, key, type) :: term
  def get(map, key, module) when is_atom(module), do: get(map, key, struct(module))
  def get(%M{dots: d}, key, %{__struct__: module}=old_crdt) do
    (for {_,{k, crdt}} <- Dots.dots(d),
        k == key,
        module == get_structname(crdt),
        do: crdt)
    |> Enum.reduce(old_crdt, &CRDT.join(&1, &2))
  end

  defp get_structname(%{__struct__: module}), do: module

  @doc """
  Get a value's value for a key-module pair
  """
  @spec get_value(t, key, type) :: term
  def get_value(map, key, module), do: get(map, key, module) |> CRDT.value

  @doc """
  Returns the set of all key-module pairs
  """
  @spec keys(t) :: [{key,type}]
  def keys(%M{dots: d}) do
    (for {_,{k, %{__struct__: module}}} <- Dots.dots(d), do: {k, module})
    |> Enum.uniq
  end

  @doc """
  Tests to see if the CRDT is empty.

  This is used in compositing CRDT's because CRDT's with dots might actually be
  full of empty CRDT's, because we have to remain robust against undead updates
  that want to feast on our collective brains. Time is a flat circle.

  iex> alias Loom.CRDT
  iex> alias Loom.AWORMap, as: KVMap
  iex> KVMap.new |> KVMap.empty?
  true
  """
  def empty?(%M{dots: d}) do
    # (Dots.dots(d) |> Enum.filter(fn {_, {_,crdt}} -> CRDT.empty?(crdt) end) |> Enum.count) == 0
    # TODO: implement empty:
    (Dots.dots(d) |> Enum.count) == 0
  end

  @doc """
  Checks if a key-module pair exists in the map already for the key.
  """
  @spec has_key?(t, key, module) :: boolean
  def has_key?({set, %M{}}, key, module), do: has_key?(set, key, module)
  def has_key?(%M{dots: d}, key, module) do
    Dots.dots(d) |> Enum.any?(fn
      {_,{k, %{__struct__: m}}} when k == key and m == module -> true
      _ -> false
    end)
  end

  @doc """
  Returns a map of values for key-module pairs
  """
  @spec value(t) :: [{key,term}] | nil
  def value(%M{dots: d}) do
    res = Enum.reduce(Dots.dots(d), %{}, fn {_, {k, %{__struct__: module}=crdt}}, values ->
            Dict.update(values, {k, module}, crdt, &CRDT.join(crdt,&1))
          end)
          |> Enum.map(fn {k,v} -> {k, CRDT.value(v)} end)
          |> Enum.into %{}
    case map_size(res) do
      0 -> nil
      _ -> res
    end
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
      iex> Loom.AWORMap.new |> CRDT.apply({:get_value, :none, Loom.LWWRegister})
      nil

      iex> alias Loom.CRDT
      iex> Loom.AWORMap.new |> CRDT.apply(:keys)
      []

  """
  def apply(crdt, {:put, actor, key, value}) do
    KVSet.put(crdt, actor, key, value)
  end
  def apply(crdt, {:delete, key, module}) do
    KVSet.delete(crdt, key, module)
  end
  def apply(crdt, {:get, key, module}), do: KVSet.get(crdt, key, module)
  def apply(crdt, {:get_value, key, module}), do: KVSet.get_value(crdt, key, module)
  def apply(crdt, {:has_key, key, module}), do: KVSet.has_key?(crdt, key, module)
  def apply(crdt, :keys), do: KVSet.keys(crdt)
  def apply(crdt, :value), do: KVSet.value(crdt)

  @doc """
  Joins 2 CRDT's of the same type.

  2 different types cannot mix (yet).

      iex> alias Loom.CRDT
      iex> alias Loom.MVRegister, as: Reg
      iex> test_a = Reg.new |> Reg.set(:a, 1)
      iex> test_b = Reg.new |> Reg.set(:b, 2)
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
