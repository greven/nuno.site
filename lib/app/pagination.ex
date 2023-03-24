defmodule App.Pagination do
  @moduledoc """
  Add pagination support to Ecto queries.
  """

  import Ecto.Query

  alias App.Repo

  @default_limit 10

  @doc """
  Pagination query that sets a limit and offset
  """
  def query(query, offset, limit: limit) when is_binary(offset) do
    query(query, String.to_integer(offset), limit: limit)
  end

  def query(query, offset, limit: limit) do
    query
    |> limit(^(limit + 1))
    |> offset(^(limit * (offset - 1)))
  end

  @doc """
  Paginate the passed query
  """
  def paginate(query, offset, limit: limit) when is_binary(offset) do
    paginate(query, String.to_integer(offset), limit: limit)
  end

  def paginate(query, nil, limit: _limit), do: query |> Repo.all()

  def paginate(query, offset, limit: limit) do
    limit = limit || @default_limit
    results = query(query, offset, limit: limit) |> Repo.all()
    count = from(t in subquery(query), select: count("*")) |> Repo.one()
    has_next = length(results) > limit
    has_prev = offset > 1

    %{
      has_next: has_next,
      has_prev: has_prev,
      page: offset,
      prev_page: offset - 1,
      next_page: offset + 1,
      first_page: (offset - 1) * limit + 1,
      last_page: Enum.min([offset * limit, count]),
      entries: Enum.slice(results, 0, limit),
      count: count
    }
  end
end
