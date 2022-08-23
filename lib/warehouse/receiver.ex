defmodule Warehouse.Receiver do
  use GenServer
  alias Warehouse.Deliverator

  def start_link(_state \\[]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = %{
      assignments: []
    }

    {:ok, state}
  end

  def receive_packages(packages) do
    GenServer.cast(__MODULE__, {:receive_packages, packages})
  end

  # Callbacks
  def handle_cast({:receive_packages, packages}, state) do
    IO.puts "Received #{Enum.count(packages)} packages"

    {:ok, deliverator} = Deliverator.start()
    state = assign_packages(state, packages, deliverator)

    Deliverator.deliver_packages(deliverator, packages)

    {:noreply, state}
  end

  defp assign_packages(state, packages, deliverator) do
    new_assignments = packages |> Enum.map(fn p -> {p, deliverator} end)
    assignments = state.assignments ++ new_assignments
    %{state | assignments: assignments}
  end
end
