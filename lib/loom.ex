defmodule Loom do

  defmacro __using__(_) do
    quote do
      alias Loom.Dot
      alias Loom.GCounter, as: GCounter
      alias Loom.PNCounter, as: Counter
      alias Loom.AWORSet, as: Set
      alias Loom.AWORMap, as: KVSet
    end
  end

  defmodule PreconditionError do
    defexception [:details, :message]

    def exception(e) do
      msg = "Precondition failed: #{inspect e}"
      %Loom.PreconditionError{message: msg, details: e}
    end
  end

  defprotocol CRDT do

    def operations(crdt)
    def join(a,b)
    def update_op(crdt, actor, op)
    def read_op(crdt, op)
    def value(crdt)

  end

end
