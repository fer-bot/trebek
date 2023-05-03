defmodule TrebekWeb.RoomLive.Index do
  alias TrebekWeb.AuthController
  use TrebekWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("go", data, socket) do
    IO.inspect({"asdf", data})
    %{"room" => %{"room_id" => id}} = data
    {:noreply, push_redirect(socket, to: "/room/" <> id)}
  end
end
