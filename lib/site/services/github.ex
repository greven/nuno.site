defmodule Site.Services.Github do
  @moduledoc """
  GitHub API service for fetching user activity.
  """
  require Logger

  @api_endpoint "https://api.github.com"

  @doc """
  Fetches the commit activity for a given GitHub user.
  Returns a list of recent commits across all repositories.

  Note: To include private commits, you must provide a Personal Access Token
  with the `repo` scope in your config.
  """
  def get_user_activity(username) do
    case access_token() do
      {:ok, token} ->
        (@api_endpoint <> "/users/#{username}/events")
        |> Req.get(
          auth: {:bearer, token},
          headers: %{
            "Accept" => "application/vnd.github+json",
            "X-GitHub-Api-Version" => "2022-11-28"
          },
          params: [per_page: 100]
        )
        |> parse_activity_response()

      {:error, :no_token} ->
        # Fall back to unauthenticated request (public activity only)
        (@api_endpoint <> "/users/#{username}/events/public")
        |> Req.get(
          headers: %{
            "Accept" => "application/vnd.github+json",
            "X-GitHub-Api-Version" => "2022-11-28"
          },
          params: [per_page: 100]
        )
        |> parse_activity_response()
    end
  end

  @doc """
  Fetches the authenticated user's commit activity (includes private commits).
  Requires a valid access token.
  """
  def get_authenticated_user_activity do
    case access_token() do
      {:ok, token} ->
        (@api_endpoint <> "/users/greven/events")
        |> Req.get(
          auth: {:bearer, token},
          headers: %{
            "Accept" => "application/vnd.github+json",
            "X-GitHub-Api-Version" => "2022-11-28"
          },
          params: [per_page: 100]
        )
        |> parse_activity_response()

      {:error, :no_token} ->
        Logger.error("No GitHub access token configured")
        {:error, :no_token}
    end
  end

  @doc """
  Fetches commit history for a specific repository.
  """
  def get_repo_commits(owner, repo, opts \\ []) do
    case access_token() do
      {:ok, token} ->
        params = Keyword.merge([per_page: 30], opts)

        (@api_endpoint <> "/repos/#{owner}/#{repo}/commits")
        |> Req.get(
          auth: {:bearer, token},
          headers: %{
            "Accept" => "application/vnd.github+json",
            "X-GitHub-Api-Version" => "2022-11-28"
          },
          params: params
        )
        |> parse_commits_response()

      {:error, :no_token} ->
        # Try public access
        params = Keyword.merge([per_page: 30], opts)

        (@api_endpoint <> "/repos/#{owner}/#{repo}/commits")
        |> Req.get(
          headers: %{
            "Accept" => "application/vnd.github+json",
            "X-GitHub-Api-Version" => "2022-11-28"
          },
          params: params
        )
        |> parse_commits_response()
    end
  end

  defp parse_activity_response({:ok, resp}) do
    cond do
      resp.status == 200 ->
        events =
          resp.body
          |> Enum.filter(&(&1["type"] == "PushEvent"))
          |> Enum.flat_map(fn event ->
            repo_name = event["repo"]["name"]

            event["payload"]["commits"]
            |> Enum.map(fn commit ->
              %{
                sha: commit["sha"],
                message: commit["message"],
                author: commit["author"]["name"],
                repo: repo_name,
                timestamp: event["created_at"],
                url: "https://github.com/#{repo_name}/commit/#{commit["sha"]}"
              }
            end)
          end)

        {:ok, events}

      resp.status == 404 ->
        Logger.error("GitHub user not found")
        {:error, :not_found}

      true ->
        Logger.error("GitHub API error: #{resp.status}")
        {:error, resp.status}
    end
  end

  defp parse_activity_response({:error, _} = error) do
    Logger.error("GitHub API request failed: #{inspect(error)}")
    error
  end

  defp parse_commits_response({:ok, resp}) do
    cond do
      resp.status == 200 ->
        commits =
          resp.body
          |> Enum.map(fn commit ->
            %{
              sha: commit["sha"],
              message: commit["commit"]["message"],
              author: commit["commit"]["author"]["name"],
              author_email: commit["commit"]["author"]["email"],
              timestamp: commit["commit"]["author"]["date"],
              url: commit["html_url"]
            }
          end)

        {:ok, commits}

      resp.status == 404 ->
        Logger.error("GitHub repository not found")
        {:error, :not_found}

      true ->
        Logger.error("GitHub API error: #{resp.status}")
        {:error, resp.status}
    end
  end

  defp parse_commits_response({:error, _} = error) do
    Logger.error("GitHub API request failed: #{inspect(error)}")
    error
  end

  ## Authentication

  defp access_token do
    case Application.get_env(:site, :github)[:access_token] do
      nil -> {:error, :no_token}
      token -> {:ok, token}
    end
  end
end
