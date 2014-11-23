defmodule LoomGcounterTest do
  use ExUnit.Case

  doctest Loom.GCounter
  doctest Loom.CRDT.Loom.GCounter # The Protocol implementation

  test "Stupid test for CRDT ops" do
    assert [_,_] = Keyword.take(Loom.CRDT.ops(Loom.GCounter.new), [:update, :read])
  end

end
