defmodule Warehouse do
  use Application

  def start(_start_type, _start_args) do
    Warehouse.Supervisor.start_link()
  end
end
