defmodule Warehouse.Receiver do
  use GenServer
  alias Warehouse.{Deliverator, DeliveratorPool}
  @batch_size 20

  def start_link(_state \\[]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = %{
      assignments: [],
      batch_size: @batch_size,
      packages_buffer: [],
      delivered_packages: []
    }

    {:ok, state}
  end

  def receive_packages(packages) do
    GenServer.cast(__MODULE__, {:receive_packages, packages})
  end

  # Callbacks
  def handle_cast({:receive_packages, packages}, state) do
    IO.puts "Received #{Enum.count(packages)} packages"

    state = case DeliveratorPool.available_deliverator() do
      {:ok, deliverator} ->
        IO.puts "deliverator #{inspect deliverator} acquierd, assigning batch"

        {package_batch, remaining_packages} = Enum.split(packages, @batch_size)
        Process.monitor(deliverator)

        DeliveratorPool.flag_deliverator_busy(deliverator)
        Deliverator.deliver_packages(deliverator, package_batch)

        if Enum.count(remaining_packages) > 0 do
          receive_packages(remaining_packages)
        end

        assign_packages(state, package_batch, deliverator)

      {:error, message} ->
        IO.puts "#{message}"
        IO.puts "buffering #{Enum.count(packages)} packages"
    end
    {:noreply, state}
  end

  def handle_info({:package_delivered, package}, state) do
    IO.puts "package #{inspect package} was delivered"
    assignments =
      state.assignments
      |> Enum.filter(fn {p,_pid} -> p.id != package.id end)

    delivered_packages = [package | state.delivered_packages]
    state = %{state | assignments: assignments, delivered_packages: delivered_packages}
    {:noreply, state}
  end

  def handle_info({:deliverator_idle, deliverator}, state) do
    IO.puts "deliverator #{inspect deliverator} completed the mission"
    DeliveratorPool.flag_deliverator_idle(deliverator)

    {next_batch, remaining_packages} = Enum.split(state.packages_buffer, @batch_size)

    if Enum.count(next_batch) > 0 do
      receive_packages(next_batch)
    end

    state = %{state | packages_buffer: remaining_packages}

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, deliverator, reason}, state) do
    IO.puts "deliverator #{inspect deliverator} could not complete the mission for the reason #{inspect reason}"

    failed_assignments = filter_by_deliverator(deliverator, state.assignments)
    failed_packages = failed_assignments |> Enum.map(fn {p, _pid} -> p end)

    DeliveratorPool.remove_deliverator(deliverator)

    assignments = state.assignments -- failed_assignments
    state = %{state | assignments: assignments}
    receive_packages(failed_packages)

    {:noreply, state}
  end

  defp filter_by_deliverator(deliverator, assignments) do
    assignments
    |> Enum.filter(fn {_p, d} -> d == deliverator end)
  end

  defp assign_packages(state, packages, deliverator) do
    new_assignments = packages |> Enum.map(fn p -> {p, deliverator} end)
    assignments = state.assignments ++ new_assignments
    %{state | assignments: assignments}
  end
end
