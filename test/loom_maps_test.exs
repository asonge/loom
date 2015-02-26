defmodule LoomMapsTest do
  use ExUnit.Case
  import Loom.TypedORMap
  alias Loom.PNCounter, as: C
  alias Loom.PNCounterMap, as: CMap

  test "Basic definition..." do
    defmap C
    m = C.new |> C.inc(:a, 5) |> C.dec(:a, 3)
    c = CMap.new |> CMap.put(:a, "omg", m)
    assert 2 == CMap.get_value(c, "omg")
  end

end
