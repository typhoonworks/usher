# Phoenix Integration

This guide shows how to integrate Usher with Phoenix applications, including controllers, LiveView, and custom plugs.

## Controller Integration

### Basic Registration Controller

```elixir
defmodule MyAppWeb.UserRegistrationController do
  use MyAppWeb, :controller
  
  def new(conn, params) do
    case validate_invitation_from_params(params) do
      {:ok, invitation} ->
        conn
        |> assign(:invitation, invitation)
        |> render(:new)
        
      {:error, reason} ->
        message = invitation_error_message(reason)
        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/")
    end
  end
  
  def create(conn, %{"user" => user_params} = params) do
    case validate_invitation_from_params(params) do
      {:ok, invitation} ->
        # Create user and increment invitation count
        create_user(invitation, user_params)
        
      {:error, reason} ->
        # This is a function that you can define,
        # e.g. in the fallback controller.
        handle_invitation_error(conn, reason)
    end
  end

  defp create_user(invitation, user_params) do
    MyApp.Repo.transaction(fn ->
      with {:ok, user} <- create_user(user_params),
          {:ok, _} <- Usher.track_invitation_usage(invitation, :user, user.id, :registered) do
        conn
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: ~p"/dashboard")
      end
    end)
  end
  
  defp validate_invitation_from_params(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)
      
      _ ->
        {:error, :missing_token}
    end
  end
  
  defp create_user(params) do
    # Your user creation logic here
    MyApp.Users.create_user(params)
  end
  
  defp handle_invitation_error(conn, reason) do
    message = invitation_error_message(reason)
    
    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/")
  end
end
```

### Admin Invitation Management Controller

```elixir
defmodule MyAppWeb.Admin.InvitationController do
  use MyAppWeb, :controller
  
  def index(conn, _params) do
    invitations = Usher.list_invitations()
    render(conn, :index, invitations: invitations)
  end
  
  def new(conn, _params) do
    render(conn, :new)
  end
  
  def create(conn, %{"invitation" => invitation_params}) do
    expires_in_days = Map.get(invitation_params, "expires_in_days", "7")
    
    attrs = %{
      expires_at: DateTime.add(DateTime.utc_now(), String.to_integer(expires_in_days), :day)
    }
    
    case Usher.create_invitation(attrs) do
      {:ok, invitation} ->
        invite_url = Usher.invitation_url(invitation.token, url(~p"/signup"))
        
        conn
        |> put_flash(:info, "Invitation created! URL: #{invite_url}")
        |> redirect(to: ~p"/admin/invitations")
        
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to create invitation")
        |> render(:new, changeset: changeset)
    end
  end
  
  def delete(conn, %{"id" => id}) do
    invitation = Usher.get_invitation!(id)
    
    case Usher.delete_invitation(invitation) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Invitation deleted successfully")
        |> redirect(to: ~p"/admin/invitations")
        
      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to delete invitation")
        |> redirect(to: ~p"/admin/invitations")
    end
  end
end
```

## LiveView Integration

### Registration LiveView

```elixir
defmodule MyAppWeb.RegistrationLive do
  use MyAppWeb, :live_view

  def mount(params, _session, socket) do
    case validate_invitation_from_params(params) do
      {:ok, invitation} ->
        {:ok, assign(socket, :invitation, invitation)}
        
      {:error, reason} ->
        message = invitation_error_message(reason)
        {:ok, 
         socket
         |> put_flash(:error, message)
         |> redirect(to: ~p"/")}
    end
  end
  
  def handle_event("register", %{"user" => user_params}, socket) do
    case MyApp.Users.create_user(user_params) do
      {:ok, user} ->
        # Increment invitation usage
        invitation = socket.assigns.invitation
        {:ok, _} = Usher.track_invitation_usage(invitation, :user, user.id, :registered)

        {:noreply,
         socket
         |> put_flash(:info, "Registration successful!")
         |> redirect(to: ~p"/dashboard")}
         
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
  
  defp validate_invitation_from_params(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)
      
      _ ->
        {:error, :missing_token}
    end
  end
end
```

### Admin Dashboard LiveView

```elixir
defmodule MyAppWeb.Admin.InvitationDashboardLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    invitations = Usher.list_invitations()
    
    socket = 
      socket
      |> assign(:invitations, invitations)
      |> assign(:form, to_form(%{}, as: :invitation))
    
    {:ok, socket}
  end
  
  def handle_event("create_invitation", %{"invitation" => params}, socket) do
    expires_in_days = Map.get(params, "expires_in_days", "7") |> String.to_integer()
    
    attrs = %{
      expires_at: DateTime.add(DateTime.utc_now(), expires_in_days, :day)
    }
    
    case Usher.create_invitation(attrs) do
      {:ok, invitation} ->
        updated_invitations = [invitation | socket.assigns.invitations]
        
        {:noreply,
         socket
         |> assign(:invitations, updated_invitations)
         |> put_flash(:info, "Invitation created successfully!")}
         
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create invitation")}
    end
  end
  
  def handle_event("delete_invitation", %{"id" => id}, socket) do
    invitation = Enum.find(socket.assigns.invitations, &(&1.id == id))
    
    case Usher.delete_invitation(invitation) do
      {:ok, _} ->
        updated_invitations = Enum.reject(socket.assigns.invitations, &(&1.id == id))
        
        {:noreply,
         socket
         |> assign(:invitations, updated_invitations)
         |> put_flash(:info, "Invitation deleted successfully!")}
         
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete invitation")}
    end
  end
  
  def handle_event("copy_url", %{"token" => token}, socket) do
    url = Usher.invitation_url(token, url(~p"/signup"))
    
    {:noreply,
     socket
     |> push_event("copy-to-clipboard", %{text: url})
     |> put_flash(:info, "Invitation URL copied to clipboard!")}
  end
end
```

## Custom Plug Implementation

Create a reusable plug for invitation validation:

```elixir
defmodule MyApp.InvitationPlug do
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, opts) do
    redirect_on_error_to = Keyword.get(opts, :redirect_on_error_to, "/")
    flash_key = Keyword.get(opts, :flash_key, :error)

    case validate_invitation_from_params(conn.params) do
      {:ok, invitation} ->
        conn
        |> assign(:invitation, invitation)
        # Store invitation token in session for later use
        |> put_invitation_token_in_session(invitation.token)

      {:error, reason} ->
        message = invitation_error_message(reason)

        conn
        |> put_flash(flash_key, message)
        |> redirect(to: redirect_on_error_to)
        |> halt()
    end
  end

  def put_invitation_token_in_session(conn, token) do
    put_session(conn, :invitation_token, token)
  end

  def get_invitation_token_from_session(conn) do
    get_session(conn, :invitation_token)
  end

  def validate_invitation_from_session(conn) do
    case get_invitation_token_from_session(conn) do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)

      _ ->
        {:error, :missing_token}
    end
  end

  defp validate_invitation_from_params(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)

      _ ->
        {:error, :missing_token}
    end
  end
end
```

### Using the Custom Plug

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # ... other pipelines

  pipeline :invitation_required do
    plug MyApp.InvitationPlug, 
      redirect_on_error_to: "/contact",
      flash_key: :error
  end

  scope "/signup", MyAppWeb do
    pipe_through [:browser, :invitation_required]
    
    get "/", UserRegistrationController, :new
    post "/", UserRegistrationController, :create
    live "/live", RegistrationLive
  end

  scope "/admin", MyAppWeb.Admin do
    pipe_through [:browser, :require_admin]
    
    resources "/invitations", InvitationController, except: [:show, :edit, :update]
    live "/dashboard", InvitationDashboardLive
  end
end
```