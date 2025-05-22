defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-4xl font-bold mb-12 text-center text-gray-800 dark:text-white">
          Welcome to my Website!
        </h1>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <%!-- Travel Card --%>
          <.link
            navigate="/travel"
            class="block md:col-span-2 p-6 rounded-xl shadow-xl transition-all duration-300 ease-in-out transform hover:scale-[1.03] focus:scale-[1.03] bg-gradient-to-br from-sky-500 to-blue-600 text-white"
          >
            <h2 class="text-2xl lg:text-3xl font-bold mb-3">Travel Adventures</h2>
            <p class="text-base lg:text-lg opacity-90 mb-1">
              Placeholder: <strong>XX</strong> trips taken and counting!
            </p>
            <p class="mt-4 text-sm font-semibold inline-flex items-center opacity-90 hover:opacity-100">
              Explore my journeys
              <span class="ml-2 transition-transform group-hover:translate-x-1">&rarr;</span>
            </p>
          </.link>

          <%!-- Latest Article Card --%>
          <.link
            navigate="/articles"
            class="block p-6 rounded-xl shadow-xl transition-all duration-300 ease-in-out transform hover:scale-[1.03] focus:scale-[1.03] bg-gradient-to-br from-emerald-500 to-green-600 text-white"
          >
            <h2 class="text-2xl lg:text-3xl font-bold mb-3">Latest Article</h2>
            <p class="text-base lg:text-lg opacity-90 mb-1">
              Placeholder: Title of the Latest Article...
            </p>
            <p class="mt-4 text-sm font-semibold inline-flex items-center opacity-90 hover:opacity-100">
              Read more
              <span class="ml-2 transition-transform group-hover:translate-x-1">&rarr;</span>
            </p>
          </.link>

          <%!-- About Me Card --%>
          <.link
            navigate="/about"
            class="block p-6 rounded-xl shadow-xl transition-all duration-300 ease-in-out transform hover:scale-[1.03] focus:scale-[1.03] bg-gradient-to-br from-amber-500 to-yellow-600 text-white"
          >
            <h2 class="text-2xl lg:text-3xl font-bold mb-3">About Me</h2>
            <p class="text-base lg:text-lg opacity-90 mb-1">
              Discover more about my background and interests.
            </p>
            <p class="mt-4 text-sm font-semibold inline-flex items-center opacity-90 hover:opacity-100">
              Get to know me
              <span class="ml-2 transition-transform group-hover:translate-x-1">&rarr;</span>
            </p>
          </.link>

          <%!-- Music Card --%>
          <.link
            navigate="/music"
            class="block p-6 rounded-xl shadow-xl transition-all duration-300 ease-in-out transform hover:scale-[1.03] focus:scale-[1.03] bg-gradient-to-br from-purple-500 to-indigo-600 text-white"
          >
            <h2 class="text-2xl lg:text-3xl font-bold mb-3">Music Corner</h2>
            <p class="text-base lg:text-lg opacity-90 mb-1">
              Placeholder: Currently Playing - Track Name
            </p>
            <p class="mt-4 text-sm font-semibold inline-flex items-center opacity-90 hover:opacity-100">
              Tune in <span class="ml-2 transition-transform group-hover:translate-x-1">&rarr;</span>
            </p>
          </.link>

          <%!-- Books Card --%>
          <.link
            navigate="/books"
            class="block p-6 rounded-xl shadow-xl transition-all duration-300 ease-in-out transform hover:scale-[1.03] focus:scale-[1.03] bg-gradient-to-br from-rose-500 to-red-600 text-white"
          >
            <h2 class="text-2xl lg:text-3xl font-bold mb-3">Reading List</h2>
            <p class="text-base lg:text-lg opacity-90 mb-1">
              Check out what I've been reading.
            </p>
            <p class="mt-4 text-sm font-semibold inline-flex items-center opacity-90 hover:opacity-100">
              My bookshelf
              <span class="ml-2 transition-transform group-hover:translate-x-1">&rarr;</span>
            </p>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
