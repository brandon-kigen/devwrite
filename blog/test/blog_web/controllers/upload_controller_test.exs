defmodule BlogWeb.UploadControllerTest do
  use BlogWeb.ConnCase, async: true

  import Blog.AccountsFixtures

  describe "POST /uploads" do
    setup do
      user = user_fixture()
      # Create a temporary file to upload
      tmp_path = Path.join(System.tmp_dir!(), "test_upload.png")
      File.write!(tmp_path, "fake image data content")

      on_exit(fn ->
        File.rm(tmp_path)
      end)

      %{user: user, tmp_path: tmp_path}
    end

    test "saves uploaded file and returns 201 with public URL when authenticated", %{
      conn: conn,
      user: user,
      tmp_path: tmp_path
    } do
      # 1. Log in the user
      conn = log_in_user(conn, user)

      # 2. Package as a Plug.Upload struct
      upload = %Plug.Upload{
        filename: "avatar.png",
        content_type: "image/png",
        path: tmp_path
      }

      # 3. Make the request
      conn = post(conn, ~p"/uploads", %{"file" => upload})

      assert json = json_response(conn, 201)
      assert url = json["url"]
      assert String.starts_with?(url, "/uploads/")
      assert String.ends_with?(url, ".png")

      # 4. Verify that the file was physically saved in priv/static/uploads/
      filename = Path.basename(url)
      saved_path = Path.join([:code.priv_dir(:blog), "static", "uploads", filename])
      assert File.exists?(saved_path)

      # Clean up the created file
      File.rm!(saved_path)
    end

    test "redirects guest (unauthenticated) user to login", %{
      conn: conn,
      tmp_path: tmp_path
    } do
      upload = %Plug.Upload{
        filename: "avatar.png",
        content_type: "image/png",
        path: tmp_path
      }

      conn = post(conn, ~p"/uploads", %{"file" => upload})
      assert redirected_to(conn) == "/users/log-in"
    end

    test "returns bad request if 'file' parameter is missing", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = post(conn, ~p"/uploads", %{})
      assert json_response(conn, 400) == %{"error" => "Missing required 'file' parameter"}
    end
  end
end
