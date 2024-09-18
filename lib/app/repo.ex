defmodule App.Repo do
  use Ecto.Repo,
    otp_app: :app,
    adapter: Ecto.Adapters.SQLite3

  import Ecto.Query

  alias Ecto.Query
  alias __MODULE__

  ## Aggregations

  @doc """
  Count the number of entries in the passed query.
  This is a shortcut to `Repo.aggregate/3` with the `:count` as the `aggregate`.
  """
  def count(queryable, opts \\ []) do
    Repo.aggregate(queryable, :count, opts)
  end

  @doc """
  Count the total number of entries in the passed query.
  Contrary to `Repo.count/3`, this function is meant to be used for counting
  the total number of entries in a query, disregarding any limit, offset, distinct, etc.
  """
  def total(queryable, opts \\ []) do
    queryable
    |> exclude(:limit)
    |> exclude(:offset)
    |> exclude(:distinct)
    |> exclude(:group_by)
    |> Repo.aggregate(:count, opts)
  end

  ## Pagination

  @doc """
  Paginate the passed query.
  Offset represents the current page where limit is the number of entries per page.
  """
  def paginate(query, limit, offset) when is_binary(offset) do
    paginate(query, String.to_integer(offset), limit: limit)
  end

  def paginate(query, limit, offset) do
    count = total(query)
    items = query |> apply_limit(limit) |> apply_offset(offset) |> Repo.all()
    total_pages = ceil(count / limit)

    cur_page = get_current_page(limit, offset, total_pages)
    {has_prev?, prev_page} = get_previous_page(offset, cur_page)
    {has_next?, next_page} = get_next_page(limit, offset, cur_page, count, total_pages)

    {items,
     %{
       page_size: limit,
       cur_page: cur_page,
       prev_page: prev_page,
       next_page: next_page,
       has_prev?: has_prev?,
       has_next?: has_next?,
       total_count: count,
       total_pages: total_pages
     }}
  end

  defp apply_limit(query, nil), do: query
  defp apply_limit(query, limit), do: Query.limit(query, ^limit)

  defp apply_offset(query, nil), do: query
  defp apply_offset(query, offset), do: Query.offset(query, ^offset)

  defp get_current_page(limit, offset, total_pages) when is_number(offset) and offset > 0 do
    min(ceil(offset / limit) + 1, total_pages)
  end

  defp get_current_page(_, _, _), do: 1

  defp get_previous_page(offset, cur_page) when is_number(offset) and offset > 0 do
    {true, if(cur_page > 1, do: cur_page - 1, else: nil)}
  end

  defp get_previous_page(_, cur_page) when cur_page > 1 do
    {false, cur_page - 1}
  end

  defp get_previous_page(_, _),
    do: {false, nil}

  defp get_next_page(limit, offset, _, total_count, _) when limit + offset >= total_count do
    {false, nil}
  end

  defp get_next_page(_, _, cur_page, _, total_pages) do
    {true, min(total_pages, cur_page + 1)}
  end
end
