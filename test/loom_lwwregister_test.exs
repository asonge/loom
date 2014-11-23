defmodule LoomLwwregisterTest do
  use ExUnit.Case

  doctest Loom.LWWRegister
  doctest Loom.CRDT.Loom.LWWRegister # The Protocol implementation

end
