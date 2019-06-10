# PoorManSpa

## Tutorial - Setup a poor mans SPA with Phoenix LiveView and Tubolinks

I started a new Phoenix app called PoorManSpa with:
    
    mix phx.new poor_man_spa
    
 
And I wanted some dynamic data so I generated a CRUD for posts. 
 
     mix phx.gen.html Blog Post posts title content:text
 

When that was done the next task was to set up Live View from the instructions provided at the GitHub page.

Currently LiveView is only available from GitHub. To use it, add to your `mix.exs` and run `mix deps.get`:

    def deps do
      [
        {:phoenix_live_view, github: "phoenixframework/phoenix_live_view"}
      ]
    end

Once I installed it, I updated the endpoint's configuration to include a signing salt. You get the signing salt by running the command 

	mix phx.gen.secret 32

And added it in the config


    # config/config.exs
    config :poor_man_spa, PoorManSpaWeb.Endpoint,
       live_view: [
         signing_salt: "SECRET_SALT"
       ]

Next, I updated the router and adde the LiveView flash plug.

    # lib/poor_man_spa_web/router.ex
    pipeline :browser do
      ...
      plug :fetch_flash
      plug Phoenix.LiveView.Flash
    end

I also needed to make some changes to `poor_man_spa_web.ex`

    # lib/poor_man_spa_web.ex
    def controller do
      quote do
        ...
        import Phoenix.LiveView.Controller, only: [live_render: 3]
      end
    end

    def view do
      quote do
        ...
        import Phoenix.LiveView, only: [live_render: 2, live_render: 3]
      end
    end

    def router do
      quote do
        ...
        import Phoenix.LiveView.Router
      end
    end

After that, I exposed a new socket for LiveView updates in the app's endpoint module.

    # lib/poor_man_spa_web/endpoint.ex
    defmodule PoorManSpaWeb.Endpoint do
      use Phoenix.Endpoint

      socket "/live", Phoenix.LiveView.Socket

      # ...
    end

To get the frontend part of this working, I also needed to add the LiveView NPM dependency in `assets/package.json`.

    # assets/package.json
    {
      "dependencies": {
        "phoenix": "file:../deps/phoenix",
        "phoenix_html": "file:../deps/phoenix_html",
        "phoenix_live_view": "file:../deps/phoenix_live_view"
      }
    }

Then I installed the new npm dependency with yarn.

    cd assets && yarn && cd ..

And added it in `app.js` and enabled a connecting to a LiveView socket.

    // assets/js/app.js
    import LiveSocket from "phoenix_live_view"

    let liveSocket = new LiveSocket("/live")
    liveSocket.connect()

Finally, for live page reload support, I needed to change to the following pattern.

    # config/dev.exs
    config :demo, PoorManSpaWeb.Endpoint,
      live_reload: [
        patterns: [
          ...,
          ~r{lib/poor_man_spa_web/live/.*(ex)$}
        ]
      ]

I also imported the styles just to get some default CSS classes.

    /* assets/css/app.css */
    @import "../../deps/phoenix_live_view/assets/css/live_view.css"; 


### Setup Turbolinks and Rails UJS

Even though these technilogies as some bad rep, they are widely used and battle tested in Ruby on Rails. I personally havent used Turbolinks in the past, but as I understand it, it seems to work just fine. 

So, to set this up, install their pagackes
 
     cd assets && yarn add turbolinks rails-ujs && cd ..
     
Turbolinks requires that the javascript file tag is moved up to the page head, which blocks rendering on the initial page load but the idea is that it a visitor might not need to do it again. And Rails UJS needs two meta tags in the header to pass in when doing remote form posts. So, inside the `<head>`:

    # lib/poor_man_spa_web/templates/layout/app.html.eex
    # Add these meta tags
    <meta name="csrf-param" content="authenticity_token" />
	<meta name="csrf-token" content="<%= Plug.CSRFProtection.get_csrf_token() %>"/>
	
	# Move this from the bottom of the page
    <script type="text/javascript" data-turbolinks-track="reload" src="<%= Routes.static_path(@conn, "/js/app.js") %>"></script>

The javascript that is needed for this to work is basically just:

    # assets/js/app.js
    require("rails-ujs").start()
    var Turbolinks = require("turbolinks")
    Turbolinks.start()
    document.addEventListener("turbolinks:load", function() {
      // Javascript that should be reenabled after a new page visit
      liveSocket.connect()
    })


### Setup Hello World in Live View!

Now I want do start with a basic Hello world. For this I will just render a partial in the posts index view. 

    # lib/poor_man_spa_web/live/post_live.ex
    defmodule PoorManSpaWeb.PostLive do
	  use Phoenix.LiveView
	
	  def render(assigns) do
	    PoorManSpaWeb.PostView.render("live_posts.html", assigns)
	  end
	
	  def mount(_session, socket) do
	    {:ok, assign(socket, message: "Hello World!")}
	  end
	end

And in add a simple place holder template

    # lib/poor_man_spa_web/templates/post/live_posts.html.leex
    <%= @message %>

Finally, just render the partial in the index view.

    # lib/poor_man_spa_web/templates/post/index.html.eex
    <h1>Listing Posts</h1>
	
	<%= Phoenix.LiveView.live_render(@conn, PoorManSpaWeb.PostLive, session: %{}) %>

	...rest of the template code
	

My first objectitve is to render posts with Live View. I just need to update the component to:
	
	# lib/poor_man_spa_web/live/post_live.ex
	defmodule PoorManSpaWeb.PostLive do
	  use Phoenix.LiveView
	
	  alias PoorManSpa.Blog
	
	  def render(assigns) do
	    PoorManSpaWeb.PostView.render("live_posts.html", assigns)
	  end
	
	  def mount(_session, socket) do
	    posts = Blog.list_posts()
	    {:ok, assign(socket, posts: posts, conn: socket)}
	  end
	end

I also needed to move the posts table to the template file

    # lib/poor_man_spa_web/templates/post/live_posts.html.leex
    <table>
	  <thead>
	    <tr>
	      <th>Title</th>
	      <th>Content</th>
	
	      <th></th>
	    </tr>
	  </thead>
	  <tbody>
	<%= for post <- @posts do %>
	    <tr>
	      <td><%= post.title %></td>
	      <td><%= post.content %></td>
	
	      <td>
	        <%= link "Show", to: Routes.post_path(@conn, :show, post) %>
	        <%= link "Edit", to: Routes.post_path(@conn, :edit, post) %>
	        <%= link "Delete", to: Routes.post_path(@conn, :delete, post), method: :delete, data: [confirm: "Are you sure?"] %>
	      </td>
	    </tr>
	<% end %>
	  </tbody>
	</table>

At this point everything should look the same. After the page is refreshed, the Live View component should render the page. It doesnt display realtime data yet. To get that working, I need to setup a way so the Live View component subscribes to changes in the Blog context. This is simple enough:

	# lib/poor_man_spa/blog.ex
	@topic inspect(__MODULE__)
	  
	def subscribe do
	  Phoenix.PubSub.subscribe(PoorManSpa.PubSub, @topic)
	end
	
	def notify_subscribers(data, message \\ :posts_updated) do
	  Phoenix.PubSub.broadcast(PoorManSpa.PubSub, @topic, {__MODULE__, message})
	  data
	end

And in each of the functions that updates data, I needed to append `notify_subscribers` function. 

	def create_post(attrs \\ %{}) do
	  %Post{}
	  |> Post.changeset(attrs)
	  |> Repo.insert()
	  |> notify_subscribers()
	end

When I have this setup in create, update and delete post, I need to make the Live View component subscribe to these changes. That would be done in the `mount`-function. There also needs to be a function that listens for the subscription events. That would look like:
    
    # lib/poor_man_spa_web/live/post_live.ex
 	def mount(_session, socket) do
	  if connected?(socket), do: Blog.subscribe
	
      ...
	end
	
	def handle_info({Blog, _}, socket) do
	  posts = Blog.list_posts()
	  {:noreply, assign(socket, posts: posts, conn: socket)}
	end

At this point I can open up two browser windows and test that create, update and delete sync properly.


### Start using Rails UJS

I have added the Rails UJS but I havent yet implemented it. Something I usually do is to set up delete-links to be triggered with ajax and then just remove the line with javascript to avaoid a full page refresh.

So, I set that up by adding remote true to the delete button in the template.

	# lib/poor_man_spa_web/templates/post/live_posts.html.leex
	<%= link "Delete", to: Routes.post_path(@conn, :delete, post), method: :delete, data: [confirm: "Are you sure?", remote: true] %>
	
This is however not enough. Phoenix will respond with the default html template so I had two options. Either update the delete-function to return an appropiate response or leave it as-is in case I would like to trigger it from somewhere else in the UI. I solved it by adding an extra delete function:

	# lib/poor_man_spa_web/controllers/post_controller.ex
    def delete(%{assigns: %{format: :js}} = conn, %{"id" => id}) do
	  post = Blog.get_post!(id)
	  {:ok, _post} = Blog.delete_post(post)
	
	  conn
	  |> put_resp_content_type("text/plain")
	  |> send_resp(:ok, "")
	end
	
Finally to get this work, I wrote a plug to identify if this was a js request and added it to the router. 

	# lib/poor_man_spa_web/plugs/request_format.ex
    defmodule PoorManSpaWeb.Plugs.RequestFormat do
	  import Plug.Conn
	
	  def init(options), do: options
	
	  def call(conn, _opts) do
	    [accept_string|_] = get_req_header(conn, "accept")
	
	    case accept_string =~ "javascript" do
	      true -> assign(conn, :format, :js)
	      _ -> assign(conn, :format, :html)
	    end
	  end
	end
	
	# lib/poor_man_spa_web/router.ex
	plug PoorManSpaWeb.Plugs.RequestFormat
	

### Add a layer of extra complexity

I wanted to test something more comeplex and was thinking that a inmemory like system could be fun to test. The idea is that one single user should only be able to like a post once.

Instead of persisting the likes in a database, I just stored them in an Agent. Also, I made sure that the Live View component can subscribe to the likes.

	# lib/poor_man_spa/blog/likes.ex
	defmodule PoorManSpa.Blog.Likes do
	  use Agent
	
	  def start_link(state \\ MapSet.new()) do
	    Agent.start_link(fn -> state end, name: __MODULE__)
	  end
	
	  @topic inspect(__MODULE__)
	  def subscribe do
	    Phoenix.PubSub.subscribe(PoorManSpa.PubSub, @topic)
	  end
	
	  def notify_subscribers(data, message \\ :likes_updated) do
	    Phoenix.PubSub.broadcast(PoorManSpa.PubSub, @topic, {__MODULE__, message})
	    data
	  end
	
	  def like(id, user_id) do
	    get_state()
	    |> Enum.member?({id, user_id})
	    |> case do
	      true -> :ok
	      false ->
	        Agent.update(__MODULE__, fn state ->
	          MapSet.put(MapSet.new(state), {id, user_id})
	        end)
	        |> notify_subscribers()
	    end
	  end
	
	  def likes_count do
	    get_state()
	    |> Enum.reduce(%{}, fn {id, _}, acc ->
	      count = Map.get(acc, id, 0)
	      Map.put(acc, id, count + 1)
	    end)
	  end
	
	  defp get_state, do: Agent.get(__MODULE__, & &1)
	end

Since I wanted this to start when the app starts, I needed to add it `Application`

    #lib/poor_man_spa/application.ex
    children = [
      ...
      {PoorManSpa.Blog.Likes, []}
    ]
    

To keep track of users, I needed to set up an autogerenerated `user_id` and store it in the session. So, I needed ti write another plug for that and add it to the router.

	# lib/poor_man_spa_web/plugs/assign_session.ex
	defmodule PoorManSpaWeb.Plugs.AssignSession do
	  import Plug.Conn
	
	  def init(options), do: options
	
	  def call(conn, _opts) do
	    case get_session(conn, :user_id) do
	      nil -> put_session(conn, :user_id, generate_user_id())
	      _ -> conn
	    end
	  end
	
	  defp generate_user_id, do: :crypto.strong_rand_bytes(10) |> Base.url_encode64()
	end
	
	# lib/poor_man_spa_web/router.ex
	plug PoorManSpaWeb.Plugs.AssignSession
	
And to add the `user_id` to the Live View component, I just needed to pass it where I mounted it.

	# lib/poor_man_spa_web/templates/post/index.html.eex
	<%= Phoenix.LiveView.live_render(@conn, PoorManSpaWeb.PostLive, session: %{user_id: Plug.Conn.get_session(@conn, :user_id)}) %>
	

And add some code to the component:

	# lib/poor_man_spa_web/live/post_live.ex
	alias PoorManSpa.Blog.Likes
	
	def mount(session, socket) do
	  if connected?(socket), do: Blog.subscribe
	  if connected?(socket), do: Likes.subscribe
	
	  user_id = session |> Map.get(:user_id)
	  posts = Blog.list_posts()
	  
	  {:ok, assign(socket, posts: posts, conn: socket, user_id: user_id, likes: Likes.likes_count())}
	end
	  
	def handle_info({Likes, _}, socket) do
	  {:noreply, assign(socket, likes: Likes.likes_count())}
	end

    def handle_event("like", post_id, socket) do
      post_id = String.to_integer(post_id)
      user_id = socket.assigns[:user_id]
      Likes.like(post_id, user_id)

      {:noreply, socket}
    end

Only ting left to get this to work was to add the actual _like_ element in the template. And Live View provides a click handler that we can use. 

    # lib/poor_man_spa_web/templates/post/live_posts.html.leex
    <td nowrap>
	  <a href="#" phx-click="like" phx-value="<%= post.id %>">
	    <svg class="" style="max-width: 18px" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
	      <path d="M12.76 3.76a6 6 0 0 1 8.48 8.48l-8.53 8.54a1 1 0 0 1-1.42 0l-8.53-8.54a6 6 0 0 1 8.48-8.48l.76.75.76-.75zm7.07 7.07a4 4 0 1 0-5.66-5.66l-1.46 1.47a1 1 0 0 1-1.42 0L9.83 5.17a4 4 0 1 0-5.66 5.66L12 18.66l7.83-7.83z"></path>
	    </svg>
	  </a>
	  <%= Map.get(@likes, post.id, 0) %>
	</td>




