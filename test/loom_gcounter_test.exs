defmodule LoomGcounterTest do
  use ExUnit.Case
  use ExCheck

  doctest Loom.GCounter
  doctest Loom.CRDT.Loom.GCounter # The Protocol implementation

  # defmodule FSMTest do
  #   alias Loom.GCounter, as: Counter
  #
  #   def actor, do: oneof([:a, :b])
  #
  #   def command(_) do
  #     oneof([{:call, Counter, :inc, [actor, such_that(i in int when i > 0)]}])
  #   end
  #
  #   def initial_state, do: %{ flat: 0, a: Counter.new, b: Counter.new}
  #
  #   def next_state(%{flat: f}=val, _var, {:call, _, :inc, [actor, int]}) do
  #     IO.inspect _var
  #     IO.inspect {:call, :inc, [actor, int]}
  #     IO.inspect val[actor]
  #     val
  #     |> Dict.put(:flat, f+int)
  #     |> Dict.put(actor, Counter.inc(val[actor], actor, int))
  #   end
  #
  #   def precondition(val, {:call, _, :inc, [_, _]}) do
  #     IO.inspect val
  #     true
  #   end
  #
  #   def postcondition(%{flat: f, a: a, b: b}, _) do
  #     f == Counter.join(a, b) |> Counter.value
  #   end
  #
  #   def run do
  #     IO.inspect "running!"
  #     for_all cmds in :triq_statem.commands(__MODULE__) do
  #       :triq_statem.run_commands(__MODULE__, cmds)
  #     end
  #   end
  #
  # end

  test "Stupid test for CRDT ops" do
    assert [_,_] = Keyword.take(Loom.CRDT.ops(Loom.GCounter.new), [:update, :read])
  end

  # property :fsm do
  #   FSMTest.run
  # end

end
