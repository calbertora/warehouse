defmodule Warehouse.Supervisor do
  def start_link do
    children = [
      Warehouse.Receiver,
      Warehouse.DeliveratorPool
    ]

    opts = [strategy: :one_for_all]

    Supervisor.start_link(children, opts)
  end
end
