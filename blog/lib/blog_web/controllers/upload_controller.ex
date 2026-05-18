defmodule BlogWeb.UploadController do
  @moduledoc """
  Handles secure user file uploads (e.g., Trix rich text editor image attachments).
  """

  use BlogWeb, :controller

  @doc """
  Handles incoming file uploads, saves them to `priv/static/uploads/`,
  and returns the public URL in JSON.
  """
  def create(conn, %{"file" => %Plug.Upload{} = upload}) do
    # 1. Determine local uploads directory in the application's priv/ static space
    upload_dir = Path.join(:code.priv_dir(:blog), "static/uploads")

    # 2. Ensure the uploads directory exists
    File.mkdir_p!(upload_dir)

    # 3. Generate a secure, unique filename to prevent collisions and path injection
    ext = Path.extname(upload.filename) |> String.downcase()
    unique_name = "#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}#{ext}"
    dest_path = Path.join(upload_dir, unique_name)

    # 4. Copy the temporary upload file to its permanent destination
    case File.cp(upload.path, dest_path) do
      :ok ->
        conn
        |> put_status(:created)
        |> json(%{url: "/uploads/#{unique_name}"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to save file: #{inspect(reason)}"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required 'file' parameter"})
  end
end
