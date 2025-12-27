defmodule Site.Services.Github do
  @moduledoc """
  GitHub API service for fetching user activity.
  """

  require Logger

  @github_user "greven"

  @doc """
  Fetch contributions from Gihub GraphQl API between two dates,
  where both dates are inclusive and `from_date` is earlier than `to_date`.
  It returns a list of daily contributions.
  """
  def get_contributions_by_date_range(from_date, to_date) do
    case fetch_contributions(from_date, to_date) do
      {:ok, contributions} -> contributions.days
      {:error, _reason} -> []
    end
  end

  @doc """
  Fetch contributions from Gihub GraphQl API for the past year.
  It returns a map with total contributions and a list of daily contributions.
  """
  def get_yearly_contributions do
    to_date = Date.utc_today()
    from_date = Date.shift(to_date, year: -1)

    fetch_contributions(from_date, to_date)
  end

  @doc """
  Fetch contributions from Gihub GraphQl API between two dates,
  where both dates are inclusive and `from_date` is earlier than `to_date`.
  It returns a map with total contributions and a list of daily contributions.
  """
  def fetch_contributions(from_date, to_date) do
    from_date = DateTime.new!(from_date, ~T[00:00:00], "Etc/UTC")
    to_date = DateTime.new!(to_date, ~T[23:59:59], "Etc/UTC")

    case access_token() do
      {:ok, token} ->
        query = """
        query($userName: String!, $from: DateTime!, $to: DateTime!) {
          user(login: $userName) {
            contributionsCollection(from: $from, to: $to) {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                    weekday
                  }
                }
              }
              totalCommitContributions
              totalIssueContributions
              totalPullRequestContributions
              totalPullRequestReviewContributions
            }
          }
        }
        """

        variables = %{
          "userName" => @github_user,
          "from" => DateTime.to_iso8601(from_date),
          "to" => DateTime.to_iso8601(to_date)
        }

        req =
          Req.post("https://api.github.com/graphql",
            json: %{query: query, variables: variables},
            auth: {:bearer, token},
            headers: %{
              "Accept" => "application/vnd.github+json",
              "X-GitHub-Api-Version" => "2022-11-28"
            }
          )

        case req do
          {:ok, %{status: 200, body: %{"data" => data}}} ->
            parse_contributions(data)

          {:ok, %{status: 200, body: %{"errors" => errors}}} ->
            Logger.error("GitHub GraphQL errors: #{inspect(errors)}")
            {:error, :graphql_error}

          {:ok, %{status: status, body: body}} ->
            Logger.error("GitHub API returned status #{status}: #{inspect(body)}")
            {:error, {:http_error, status}}

          {:error, reason} ->
            Logger.error("Failed to fetch contributions: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, :no_token} ->
        Logger.error("GitHub access token is not configured.")
        {:error, :no_token}
    end
  end

  defp parse_contributions(%{"user" => %{"contributionsCollection" => collection}}) do
    calendar = collection["contributionCalendar"]

    days =
      calendar["weeks"]
      |> Enum.flat_map(fn week ->
        Enum.map(week["contributionDays"], fn day ->
          {:ok, date, _} = DateTime.from_iso8601(day["date"] <> "T00:00:00Z")

          %{
            date: Date.from_iso8601!(day["date"]),
            datetime: date,
            count: day["contributionCount"],
            weekday: day["weekday"]
          }
        end)
      end)

    {:ok,
     %{
       total: calendar["totalContributions"],
       total_commits: collection["totalCommitContributions"],
       total_issues: collection["totalIssueContributions"],
       total_prs: collection["totalPullRequestContributions"],
       total_reviews: collection["totalPullRequestReviewContributions"],
       days: days
     }}
  end

  defp parse_contributions(_), do: {:error, :invalid_response}

  ## Authentication

  defp access_token do
    case Application.get_env(:site, :github)[:access_token] do
      nil -> {:error, :no_token}
      token -> {:ok, token}
    end
  end
end
