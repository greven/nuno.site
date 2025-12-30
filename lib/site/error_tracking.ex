defmodule Site.ErrorTracking do
  @moduledoc """
  Error tracking helper module around `ErrorTracker` library functionality.
  """

  import Ecto.Query

  alias Site.Repo

  def total_errors_count do
    Repo.aggregate(ErrorTracker.Error, :count)
  end

  def total_unresolved_errors_count do
    query = from(e in ErrorTracker.Error, where: e.status == :unresolved)
    Repo.aggregate(query, :count)
  end

  def delete_all_errors(with_status \\ :resolved)
      when with_status in ~w(resolved unresolved all)a do
    case with_status do
      :all ->
        Repo.delete_all(ErrorTracker.Error)

      status when status in ~w(resolved unresolved)a ->
        query = from(e in ErrorTracker.Error, where: e.status == ^status)
        Repo.delete_all(query)
    end
  end
end
