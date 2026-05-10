defmodule BlogWeb.RedirectController do
  @moduledoc """
  URL redirects for backwards compatibility and canonical routes.

  ## Routes

  GET `/posts` → Redirect to `/feed`

  ## Why This Redirect?

  Both `/posts` and `/feed` display the list of published posts:
  - `/posts` - was the original route name
  - `/feed` - is the canonical authenticated route

  Problem: Having multiple routes for same content creates:
  - Confusion (which route is correct?)
  - Search engine issues (duplicate content)
  - Session management inconsistency

  Solution: Permanently redirect `/posts` to `/feed`

  ## Implementation

  Simple HTTP 301 (permanent) redirect:
  - Browser caches the redirect
  - Search engines update links
  - Users bookmarked on `/posts` are automatically redirected
  - No content duplication

  ## Future Use

  This controller can be extended for other redirects:
  - Route consolidation (old API → new API)
  - URL migration (rename pages)
  - Backwards compatibility (old links still work)

  Examples of possible future redirects:
  - `/blog` → `/feed` (blog renamed to feed)
  - `/posts/:id` → `/posts/view/:id` (route restructure)
  - `/articles` → `/posts` (renamed section)

  Always use permanent redirects (301) for SEO benefits.
  """

  use BlogWeb, :controller

  @doc """
  Redirects /posts to /feed — both show all posts, /feed is the canonical route.
  """
  def posts(conn, _params) do
    redirect(conn, to: ~p"/feed")
  end
end
