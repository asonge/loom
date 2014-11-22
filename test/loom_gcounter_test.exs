defmodule LoomGcounterTest do
  use ExUnit.Case
  use Loom

  test "Identity and basic increment" do
    assert 0 = GCounter.new |> GCounter.value
    assert 30 = GCounter.new |> GCounter.inc(:a, 1) |> GCounter.inc(:a, 29) |> GCounter.value()
  end

  test "Increment and join" do
    ctr1 = GCounter.new |> GCounter.inc(:a) |> GCounter.inc(:a, 10)
    ctr2 = GCounter.new |> GCounter.inc(:b) |> GCounter.inc(:b, 5)
    assert 17 = GCounter.join(ctr1,ctr2) |> GCounter.value
  end

end
