defmodule Site.Repo do
  use Ecto.Repo,
    otp_app: :site,
    adapter: Ecto.Adapters.SQLite3

  import Ecto.Query

  alias Ecto.Query
  alias __MODULE__

  ## Transactions

  @doc """
  A small wrapper around `Repo.transaction/2'.

  Commits the transaction if the lambda returns `:ok` or `{:ok, result}`,
  rolling it back if the lambda returns `:error` or `{:error, reason}`. In both
  cases, the function returns the result of the lambda.

  This function accepts the same options as `Ecto.Repo.transaction/2`.

  Example:

    def register_user(params) do
      Repo.transaction_with(fn ->
        with {:ok, user} <- Accounts.create_user(params),
            {:ok, _log} <- Logs.log_action(:user_registered, user),
            {:ok, _job} <- Mailer.enqueue_email_confirmation(user) do
          {:ok, user}
        end
      end)
    end
  """
  @spec transaction_with((-> any()), keyword()) :: {:ok, any()} | {:error, any()}
  def transaction_with(fun, opts \\ []) do
    transaction_result =
      transaction(
        fn repo ->
          lambda_result =
            case Function.info(fun, :arity) do
              {:arity, 0} -> fun.()
              {:arity, 1} -> fun.(repo)
            end

          case lambda_result do
            :ok -> {__MODULE__, :transact, :ok}
            :error -> rollback({__MODULE__, :transact, :error})
            {:ok, result} -> result
            {:error, reason} -> rollback(reason)
          end
        end,
        opts
      )

    with {outcome, {__MODULE__, :transact, outcome}}
         when outcome in [:ok, :error] <- transaction_result,
         do: outcome
  end

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
  The function accepts either a map with the keys `:page` and `:page_size` or
  the `page` and `page_size` as keyword list
  """
  def paginate(query, %{page: page, page_size: size}) do
    paginate(query, size, get_offset(page, size))
  end

  def paginate(query, page: page, page_size: size) do
    paginate(query, size, get_offset(page, size))
  end

  @doc """
  Paginate the passed query using `limit` and `offset` values.
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

  defp get_offset(page, size) when is_number(page) and is_number(size) do
    max(0, (page - 1) * size)
  end

  defp get_offset(_, _), do: 0

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
