defmodule TrebekWeb.APIController do
  use TrebekWeb, :controller

  def peers(conn, _params) do
    json(conn, %{
      status: :ok,
      data: %{
        self: %{
          name: Node.self(),
          alive: Node.alive?()
        },
        peers: Node.list(:visible)
      }
    })
  end

  def export_response(conn, %{"room_id" => room_id}) do
    current_user = conn.assigns.current_user

    case Trebek.Credo.get({"room<#{room_id}>", :owner}) do
      ^current_user ->
        data =
          Trebek.Credo.get_topic("room<#{room_id}>")
          |> Enum.map(fn {{_topic, k}, v} ->
            case k do
              :owner ->
                {:owner, %{id: v.id, username: v.username}}

              {:responses, user_id} ->
                {"response<#{user_id}><#{Trebek.Credo.get({:credential, user_id}).username}>", v}

              {:votes, user_id} ->
                {"votes<#{user_id}><#{Trebek.Credo.get({:credential, user_id}).username}>", v}

              k ->
                {k, v}
            end
          end)
          |> Map.new()

        json(conn, data)

      _ ->
        conn |> redirect(to: ~p"/auth/login")
    end
  end
end
