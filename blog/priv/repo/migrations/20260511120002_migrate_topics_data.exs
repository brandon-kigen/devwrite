defmodule Blog.Repo.Migrations.MigrateTopicsData do
  use Ecto.Migration

  def up do
    # Read all posts with topics array
    {:ok, result} =
      Ecto.Adapters.SQL.query(
        Blog.Repo,
        "SELECT id, topics FROM posts WHERE topics IS NOT NULL AND array_length(topics, 1) > 0"
      )

    topic_count = 0
    post_count = 0

    {final_topic_count, final_post_count} =
      Enum.reduce(result.rows, {topic_count, post_count}, fn [post_id, topics], acc ->
        {topic_count, post_count} = acc

        # Process each topic for this post
        topic_count =
          Enum.reduce(topics, topic_count, fn topic_name, count ->
            # Normalize: trim and lowercase
            normalized_name = topic_name |> String.trim() |> String.downcase()

            # Insert or find topic
            {:ok, _topic} =
              Ecto.Adapters.SQL.query(
                Blog.Repo,
                "INSERT INTO topics (name, inserted_at, updated_at) VALUES ($1, NOW(), NOW()) ON CONFLICT (name) DO NOTHING",
                [normalized_name]
              )

            # Get the topic ID
            {:ok, topic_result} =
              Ecto.Adapters.SQL.query(
                Blog.Repo,
                "SELECT id FROM topics WHERE name = $1",
                [normalized_name]
              )

            case topic_result.rows do
              [[topic_id]] ->
                # Create posts_topics entry
                Ecto.Adapters.SQL.query(
                  Blog.Repo,
                  "INSERT INTO posts_topics (post_id, topic_id, inserted_at, updated_at) VALUES ($1, $2, NOW(), NOW()) ON CONFLICT (post_id, topic_id) DO NOTHING",
                  [post_id, topic_id]
                )

                count + 1

              _ ->
                count
            end
          end)

        {topic_count, post_count + 1}
      end)

    IO.puts(
      "✅ Migrated topics: #{final_topic_count} topic associations created for #{final_post_count} posts"
    )
  end

  def down do
    # This migration cannot be safely rolled back
    raise "Cannot rollback topics migration - data loss would occur"
  end
end
