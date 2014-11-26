defmodule LoomMvregisterTest do
  use ExUnit.Case
  use ExCheck
  alias Loom.CRDT

  doctest Loom.MVRegister
  doctest Loom.CRDT.Loom.MVRegister # The Protocol implementation

  property :testing do
    a = Loom.MVRegister.new
    b = Loom.MVRegister.new
    c = Loom.MVRegister.new
    al = nil
    bl = nil
    cl = nil
    for_all ops in list(oneof([{:set, oneof([:a, :b, :c]), int}])) do
      {al1, bl1, cl1} = Enum.reduce(ops, {al, bl, cl}, fn
                          {:set, :a, v}, {_, b, c} -> {v, b, c}
                          {:set, :b, v}, {a, _, c} -> {a, v, c}
                          {:set, :c, v}, {a, b, _} -> {a, b, v}
                        end)
      value = Enum.uniq([al1, bl1, cl1]) |> Enum.reject(&(&1===nil)) |> singletonize
      {a1, b1, c1} = Enum.reduce(ops, {a,b,c}, fn
                       {:set, :a, _}=op, {a, b, c} -> {CRDT.apply(a, op), b, c}
                       {:set, :b, _}=op, {a, b, c} -> {a, CRDT.apply(b, op), c}
                       {:set, :c, _}=op, {a, b, c} -> {a, b, CRDT.apply(c, op)}
                     end)
      crdt_value = CRDT.join(a1, b1) |> CRDT.join(c1) |> CRDT.value
      when_fail(IO.inspect({crdt_value, value})) do
        value == crdt_value
      end
    end
  end

  defp singletonize([]), do: nil
  defp singletonize([foo]), do: foo
  defp singletonize(any), do: any

end
