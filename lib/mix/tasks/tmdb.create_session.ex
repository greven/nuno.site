defmodule Mix.Tasks.Tmdb.CreateSession do
  use Mix.Task

  @shortdoc "Creates a TMDB user session used to read your native favourites"

  @moduledoc """
  Creates a TMDB user session id, required to read your native favourites.

  The TMDB favourites API needs a `session_id` alongside the v4 read access
  token. This task walks you through the one-time authentication flow:

      mix tmdb.create_session

  1. Creates a request token.
  2. Prints a URL for you to approve in the browser.
  3. Exchanges the approved token for a session id.

  Add the printed `TMDB_SESSION_ID` value to your `.env` file.
  """

  @api_endpoint "https://api.themoviedb.org/3"

  @doc false
  def run(_args) do
    Mix.Task.run("app.start")

    access_token = Application.get_env(:site, :tmdb)[:access_token]

    if is_nil(access_token) or access_token == "tmdb-access-token" do
      Mix.raise("TMDB_ACCESS_TOKEN is not set. Add it to your .env file first.")
    end

    request_token = create_request_token(access_token)

    Mix.shell().info("""

    Open the following URL, log in to TMDB and approve the request:

        https://www.themoviedb.org/authenticate/#{request_token}

    """)

    IO.gets("Press Enter once you have approved the request...")

    session_id = create_session(access_token, request_token)

    Mix.shell().info("""

    ✅ Session created. Add the following line to your .env file:

        TMDB_SESSION_ID=#{session_id}
    """)
  end

  defp create_request_token(access_token) do
    "#{@api_endpoint}/authentication/token/new"
    |> Req.get!(headers: headers(access_token))
    |> Map.fetch!(:body)
    |> Map.fetch!("request_token")
  end

  defp create_session(access_token, request_token) do
    "#{@api_endpoint}/authentication/session/new"
    |> Req.post!(headers: headers(access_token), json: %{request_token: request_token})
    |> Map.fetch!(:body)
    |> Map.fetch!("session_id")
  end

  defp headers(access_token), do: [{"authorization", "Bearer #{access_token}"}]
end
