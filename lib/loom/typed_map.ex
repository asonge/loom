defmodule Loom.TypedORMap do
  @moduledoc """
  Contains a macro that creates typed maps of CRDT's.
  """

  @doc """
  Creates a module that creates a map and implements the CRDT protocol for that
  type.
  """
  defmacro defmap(type) do
    type = Macro.expand_once(type, __ENV__)
    name = :"#{type}Map"
    quote location: :keep do

      defmodule unquote(name) do
        @moduledoc """
        This module is automatically created via #{unquote(__MODULE__)}.defmap

        It provides an interface for a CRDT to be defined for each map type.
        """

        alias Loom.AWORMap, as: M
        alias unquote(type), as: Type

        @compile :debug_info

        @type actor :: term
        @type key :: term
        @type crdt :: %Type{}
        @type value :: term
        @opaque t :: %__MODULE__{
          map: M.t
        }

        defstruct map: M.new

        @doc """
        Returns a new #{unquote(name)}.

        The identity value of an empty AWORMap is `nil` because of the difficulties
        of matching against `%{}`, which is not the equivalent of `[]`.

            iex> #{unquote(name)}.new |> #{unquote(name)}.value
            nil
        """
        @spec new :: t
        def new, do: %__MODULE__{}

        @doc """
        Returns the currently-running delta of an #{unquote(name)}
        """
        @spec delta(t) :: t
        def delta(%__MODULE__{map: map}) do
          M.delta(map)
          |> to_type
        end

        @doc """
        You can use this to clear the delta from an #{unquote(name)}. Clearing the delta can
        help shrink the memory usage of this CRDT.
        """
        @spec clear_delta(t) :: t
        def clear_delta(%__MODULE__{map: map}) do
          M.clear_delta(map)
          |> to_type
        end

        @doc """
        Insert a value, and merge it with any that exist already
        """
        @spec put(t, actor, key, crdt) :: t
        def put(%__MODULE__{map: map}, actor, key, %Type{}=value) do
          M.put(map, actor, key, value)
          |> to_type
        end

        @doc """
        Delete an entry for a key-module pair
        """
        @spec delete(t, key) :: t
        def delete(%__MODULE__{map: map}, key) do
          M.delete(map, key, Type)
          |> to_type
        end

        @doc """
        Join a map
        """
        @spec join(t, t) :: t
        def join(%__MODULE__{map: map1}, %__MODULE__{map: map2}) do
          M.join(map1, map2)
          |> to_type
        end

        @doc """
        Empties out an existing map.
        """
        @spec empty(t) :: t
        def empty(%__MODULE__{map: map}) do
          M.empty(map)
          |> to_type
        end

        @doc """
        Get a value for a key-module pair
        """
        @spec get(t, key) :: crdt
        def get(%__MODULE__{map: map}, key), do: M.get(map, key, Type)

        @doc """
        Get a value's value for a key-module pair
        """
        @spec get_value(t, key) :: value
        def get_value(%__MODULE__{map: map}, key), do: M.get_value(map, key, Type)

        @doc """
        Returns the set of all key-module pairs
        """
        @spec keys(t) :: [key]
        def keys(%__MODULE__{map: map}), do: M.keys(map)

        @doc """
        Tests to see if the CRDT is empty.

        This is used in compositing CRDT's because CRDT's with dots might actually be
        full of empty CRDT's, because we have to remain robust against undead updates
        that want to feast on our collective brains. Time is a flat circle.
        """
        @spec empty?(t) :: boolean
        def empty?(%__MODULE__{map: map}), do: M.empty?(map)

        @doc """
        Checks if a key-module pair exists in the map already for the key.
        """
        @spec has_key?(t, key) :: boolean
        def has_key?(%__MODULE__{map: map}, key), do: M.has_key?(map, key, Type)

        @doc """
        Returns a map of values for key-module pairs
        """
        @spec value(t) :: value
        def value(%__MODULE__{map: map}), do: M.value(map)

        # defoverridable [new: 0, delta: 1, clear_delta: 2, put: 3, delta: ]
        @spec to_type(M.t) :: t
        defp to_type(map), do: %__MODULE__{map: map}

      end

      defimpl Loom.CRDT, for: unquote(name) do
        alias unquote(name), as: NMap
        alias unquote(type), as: Type

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
                get: [:key],
                get_value: [:key],
                keys: [],
                has_key: [],
                value: []
              ]
            ]
          end

          @doc """
          Applies a CRDT to a counter in an abstract way.

          This is for ops-based support.
          """
          def apply(crdt, {:put, actor, key, value}) do
            NMap.put(crdt, actor, key, value)
          end
          def apply(crdt, {:delete, key}) do
            NMap.delete(crdt, key)
          end
          def apply(crdt, {:get, key}), do: NMap.get(crdt, key)
          def apply(crdt, {:get_value, key}), do: NMap.get_value(crdt, key)
          def apply(crdt, {:has_key, key}), do: NMap.has_key?(crdt, key)
          def apply(crdt, :keys), do: NMap.keys(crdt)
          def apply(crdt, :value), do: NMap.value(crdt)

          @doc """
          Joins 2 CRDT's of the same type.

          2 different types cannot mix (yet).
          """
          def join(a, b), do: NMap.join(a, b)

          @doc """
          Returns the most natural primitive value for a set, a list.
          """
          def value(crdt), do: NMap.value(crdt)

      end

    end

  end

end
