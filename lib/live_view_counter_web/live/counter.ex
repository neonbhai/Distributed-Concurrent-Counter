defmodule LiveViewCounterWeb.Counter do
  use LiveViewCounterWeb, :live_view
  alias LiveViewCounter.Count
  alias Phoenix.PubSub
  alias LiveViewCounter.Presence

  @topic Count.topic()
  @presence_topic "presence"

  def mount(_params, _session, socket) do
    PubSub.subscribe(LiveViewCounter.PubSub, @topic)

    Presence.track(self(), @presence_topic, socket.id, %{})

    initial_present =
      Presence.list(@presence_topic)
      |> map_size

    LiveViewCounterWeb.Endpoint.subscribe(@presence_topic)

    {:ok, assign(socket, val: Count.current(), present: initial_present)}
  end

  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, val: Count.incr())}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, val: Count.decr())}
  end

  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, val: count)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do
    new_present = present + map_size(joins) - map_size(leaves)

    {:noreply, assign(socket, :present, new_present)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:shadow-lg hover:border-black-500 transition duration-500 ease-in-out">
      <h1 class="mb-2 text-4xl font-semibold tracking-tight text-gray-900 text-center">
        The count is:
        <div class="text-8xl"><%= @val %></div>
      </h1>

      <p class="text-center">
        <.button
          phx-click="dec"
          class="text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-4 focus:ring-gray-300 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 mb-2 dark:bg-gray-800 dark:hover:bg-gray-700 dark:focus:ring-gray-700 dark:border-gray-700"
        >
          -
        </.button>
        <.button
          phx-click="inc"
          class="text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-4 focus:ring-gray-300 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 mb-2 dark:bg-gray-800 dark:hover:bg-gray-700 dark:focus:ring-gray-700 dark:border-gray-700"
        >
          +
        </.button>
      </p>

      <h1 class="mb-2 text-4xl font-semibold text-center">Current users: <%= @present %></h1>
    </div>
    """
  end
end
