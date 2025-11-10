defmodule Site.Workers.BlueskySyncWorker do
  use Oban.Worker, queue: :scheduled, max_attempts: 5

  def perform(_job) do
    handle = Application.get_env(:site, :bluesky_handle, "nuno.site")
    Site.Services.sync_bluesky_posts(handle)
  end
end
