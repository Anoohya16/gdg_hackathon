defmodule Gitmind.Router do
  use Plug.Router
  import Ecto.Query

  alias Gitmind.{Repo, Card, DiscordClient}

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :dispatch

  # Root endpoint: Serves as a keep-alive/health check to wake up the Render container
  get "/" do
    send_resp(conn, 200, "GitMind Discord API is running.")
  end

  # Daily/Hourly Cron trigger from Supabase pg_cron
  post "/api/internal/daily-cron" do
    cron_secret = System.get_env("CRON_SECRET")
    auth_header = Plug.Conn.get_req_header(conn, "authorization") |> List.first()

    cond do
      is_binary(cron_secret) and cron_secret != "" and auth_header != "Bearer #{cron_secret}" ->
        send_resp(conn, 401, "Unauthorized")

      true ->
        now = DateTime.utc_now()

        # Query all active due cards
        query = from(c in Card, where: c.next_review_at <= ^now)
        due_cards = Repo.all(query)

        # Send each due card to its respective user concurrently via Discord DMs
        due_cards
        |> Task.async_stream(
          fn card ->
            DiscordClient.send_review_card_to_user(card.user_id, card.id, card.fact)
          end,
          max_concurrency: 5,
          on_timeout: :kill_task
        )
        |> Stream.run()

        IO.puts("Triggered reviews for #{length(due_cards)} cards.")
        send_resp(conn, 200, "Triggered reviews for #{length(due_cards)} cards.")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
