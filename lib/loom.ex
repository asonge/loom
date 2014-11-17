defmodule Loom do

  defmacro __using__(_) do
    quote do
      alias Loom.Dot
      alias Loom.AWORSet, as: Set
    end
  end

end
