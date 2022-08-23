defmodule Warehouse.Supervisor do
  def start_link do
    children = [
      Warehouse.Receiver
    ]

    opts = [strategy: :one_for_all]

    Supervisor.start_link(children, opts)
  end
end
