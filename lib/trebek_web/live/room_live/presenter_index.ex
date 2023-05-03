defmodule TrebekWeb.RoomLive.PresenterIndex do
  alias TrebekWeb.AuthController
  use TrebekWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    case current_user do
      nil ->
        {:ok, socket |> redirect(to: "/auth/login")}

      user ->
        if AuthController.is_guest?(user.id) do
          {:ok, socket |> redirect(to: "/auth/login")}
        else
          {:ok, socket}
        end
    end
  end

  @impl true
  def handle_event("create-room", _params, socket) do
    case AuthController.is_guest?(socket.assigns.current_user.id) do
      true ->
        {:noreply, push_redirect(socket, to: "/auth/login")}

      false ->
        room_id = Petname.gen()
        Trebek.Credo.put({"room<#{room_id}>", :owner}, socket.assigns.current_user)

        Horde.DynamicSupervisor.start_child(
          Trebek.DynamicSupervisor,
          {Trebek.RoomDaemon, room: room_id}
        )

        {:noreply, push_redirect(socket, to: "/room/#{room_id}/manage")}
    end
  end

  @impl true
  def handle_event("go", %{"room" => %{"action" => action, "room_id" => id}}, socket) do
    case action do
      "manage" -> {:noreply, push_redirect(socket, to: "/room/" <> id <> "/manage")}
      "present" -> {:noreply, push_redirect(socket, to: "/room/" <> id <> "/present")}
      _ -> {:noreply, push_redirect(socket, to: "/room/presenter")}
    end
  end
end
