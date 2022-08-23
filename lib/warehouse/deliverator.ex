defmodule Warehouse.Deliverator do
  use GenServer
  alias Warehouse.Receiver

  def start(state \\[]) do
    GenServer.start(__MODULE__, state)
  end

  def deliver_packages(pid, packages) do
    GenServer.cast(pid, {:deliver_packages, packages})
  end

  # Callbacks
  def handle_cast({:deliver_packages, packages}, state) do
    deliver(packages)
    {:noreply, state}
  end

  defp deliver([]), do: send(Receiver, {:deliverator_idle, self()})
  defp deliver([package | remaining]) do
    IO.puts "Deliverator #{inspect self()} deliverying #{inspect package}"
    make_delivery()
    send(Receiver, {:package_delivered, package})
    deliver(remaining)
  end

  defp make_delivery do
    :timer.sleep(:rand.uniform(3_000))
    maybe_crash()
  end

  defp maybe_crash do
    crash_factor = :rand.uniform(100)
    if crash_factor > 80, do: raise "Oh no! going down, Bye!"
  end
end
