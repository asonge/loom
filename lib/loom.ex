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
    @moduledoc """
    Implement this callback to compose new CRDT's.
    """

    @doc "A list of supported operations"
    def ops(crdt)

    @doc "Apply an op to a CRDT"
    def apply(crdt, op)

    @doc "Join 2 CRDT's"
    def join(a,b)

    @doc "Returns a natural value"
    def value(crdt)

  end

end
