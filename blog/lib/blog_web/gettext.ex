defmodule BlogWeb.Gettext do
  @moduledoc """
  Internationalization (i18n) and localization (l10n) support.

  Provides translation infrastructure for the Blog application.
  Uses GNU gettext for translation file management.

  ## What is Gettext?

  Gettext is a standard translation system used across many applications.

  Concept:
  1. Mark strings in code as translatable using `gettext/1`, `ngettext/2`, `dgettext/2`
  2. Extract strings into translation files (*.po files)
  3. Translators fill in translations for each language
  4. Compiled strings used at runtime based on user's locale

  Benefits:
  - Scalable: Add translations without code changes
  - Standard: Uses industry-standard .po file format
  - Efficient: Compiled translations (zero runtime cost)
  - Flexible: Plural forms, context-aware translations

  ## Current Status

  **Infrastructure ready, not yet in use.**

  Translation files exist in priv/gettext/:
  - en/LC_MESSAGES/ — English (translations, reference language)
  - (other languages can be added)

  Currently, code uses English strings directly.
  To enable translations, strings need to be wrapped with gettext/1.

  ## Using Translations

  ### Simple Translation

  Mark a string as translatable:
  ```elixir
  use Gettext, backend: BlogWeb.Gettext

  # In code:
  gettext("Welcome")  # Returns translated string for user's locale
  ```

  In components (HEEX):
  ```heex
  <p>{gettext("Welcome to the blog")}</p>
  ```

  In LiveView:
  ```elixir
  defmodule BlogWeb.PostLive.Show do
    use Gettext, backend: BlogWeb.Gettext

    def mount(_params, _session, socket) do
      title = gettext("Post Details")
      {:ok, assign(socket, :title, title)}
    end
  end
  ```

  ### Plural Translations

  Handles singular/plural forms (different in different languages):
  ```elixir
  ngettext("1 comment", "%{count} comments", comment_count)
  ```

  Example output:
  - comment_count = 1 → "1 comment"
  - comment_count = 5 → "5 comments"

  Used in templates:
  ```heex
  <p>{ngettext("1 comment", "%{count} comments", length(@comments))}</p>
  ```

  ### Domain-Based Translation

  Gettext can organize translations by domain (category).

  Example domain: "errors" for error messages
  ```elixir
  dgettext("errors", "Invalid email address")
  dgettext("errors", "Password is too short")
  ```

  Domains keep related strings organized in translation files.

  Common domains:
  - "errors" — Error messages
  - "buttons" — Button labels
  - "pages" — Page titles
  - "emails" — Email templates

  Usage in components/translations:
  ```elixir
  dgettext("errors", "This field is required")  # From errors.po
  dgettext("buttons", "Save")                    # From buttons.po
  ```

  ### Interpolation

  Include variables in translated strings:
  ```elixir
  gettext("Hello, %{name}!", name: "Alice")
  ```

  Translation file (.po):
  ```
  msgid "Hello, %{name}!"
  msgstr "Bonjour, %{name}!"
  ```

  Example in component:
  ```heex
  <p>{gettext("Welcome back, %{user}!", user: @current_scope.user.email)}</p>
  ```

  ## Translation Workflow

  ### 1. Mark Strings as Translatable

  In code:
  ```elixir
  # Before:
  error_message = "Invalid email"

  # After:
  error_message = gettext("Invalid email")
  ```

  In HEEX templates:
  ```heex
  <!-- Before -->
  <p>No posts found</p>

  <!-- After -->
  <p>{gettext("No posts found")}</p>
  ```

  ### 2. Extract Translatable Strings

  Run command:
  ```bash
  mix gettext.extract
  ```

  Creates/updates translation files in priv/gettext/:
  - en/LC_MESSAGES/default.po — Default domain
  - en/LC_MESSAGES/errors.po — Errors domain
  - etc.

  The .po file contains all strings to translate:
  ```
  msgid "No posts found"
  msgstr ""  # Translator fills this in
  ```

  ### 3. Add Translations

  For a new language (e.g., Spanish):

  Create directory:
  ```
  priv/gettext/es/LC_MESSAGES/
  ```

  Copy default.po and translate:
  ```
  # priv/gettext/es/LC_MESSAGES/default.po
  msgid "No posts found"
  msgstr "No se encontraron publicaciones"

  msgid "Welcome"
  msgstr "Bienvenido"
  ```

  ### 4. Compile Translations

  ```bash
  mix gettext.merge
  ```

  Compiles .po files into binary .mo files (faster, smaller).

  ### 5. Set Locale at Runtime

  In LiveView:
  ```elixir
  def mount(params, session, socket) do
    locale = session["locale"] || "en"
    Gettext.put_locale(BlogWeb.Gettext, locale)
    {:ok, socket}
  end
  ```

  Or in Plug (global):
  ```elixir
  def fetch_locale(conn, _opts) do
    locale = conn.params["locale"] || conn.cookies["locale"] || "en"
    Gettext.put_locale(BlogWeb.Gettext, locale)
    conn
  end
  ```

  ## File Structure

  ```
  priv/gettext/
    default.pot                 # Template (source strings)
    en/                         # English translations
      LC_MESSAGES/
        default.po              # Translations
        default.mo              # Compiled (generated)
    es/                         # Spanish translations
      LC_MESSAGES/
        default.po
        default.mo
    fr/                         # French translations
      LC_MESSAGES/
        default.po
        default.mo
  ```

  .po format:
  ```
  # Comment
  msgid "Source string"
  msgstr "Translated string"

  msgid "One item"
  msgid_plural "%{count} items"
  msgstr[0] "Un elemento"
  msgstr[1] "%{count} elementos"
  ```

  ## Language Detection

  Strategies for detecting user's language:

  1. **URL parameter**: ?locale=es
  2. **Cookie**: Persist user choice
  3. **HTTP header**: Accept-Language header from browser
  4. **User account**: Store language preference in database
  5. **Subdomain**: example.es.com vs example.com

  In Blog, could implement:
  ```elixir
  def fetch_locale(conn, _opts) do
    locale = get_locale(conn)
    Gettext.put_locale(BlogWeb.Gettext, locale)
    conn
  end

  defp get_locale(conn) do
    # Priority: URL param > cookie > browser > default
    conn.params["locale"] ||
      conn.cookies["locale"] ||
      parse_accept_language(conn.request_headers) ||
      "en"
  end
  ```

  ## Right-to-Left (RTL) Languages

  For Arabic, Hebrew, Urdu, etc., additional configuration needed:

  ```elixir
  def is_rtl_locale?(locale) do
    locale in ["ar", "he", "ur", "fa"]
  end
  ```

  In template:
  ```heex
  <html dir={is_rtl_locale?(@locale) && "rtl"}>
  ```

  CSS adjustments for RTL:
  ```css
  [dir="rtl"] {
    direction: rtl;
    text-align: right;
  }
  ```

  ## Date/Time Localization

  Gettext doesn't handle date formatting; use separate library:

  ```elixir
  # Add dependency: {:ex_cldr, "~> 2.0"}

  Cldr.DateTime.to_string(~U[2024-01-15 12:30:00Z], locale: "es")
  # => "15 de enero de 2024 12:30"
  ```

  ## Performance

  Gettext is very efficient:
  - Translations compiled at build time
  - Zero runtime lookup cost
  - No database queries
  - Binary .mo files are compact

  Memory usage: ~1KB per 100 strings

  ## Testing Translations

  In tests, set locale before rendering:

  ```elixir
  setup do
    Gettext.put_locale(BlogWeb.Gettext, "es")
    :ok
  end

  test "renders translated text" do
    rendered = render_component(&component/1, %{})
    assert rendered =~ "Bienvenido"  # Spanish translation
  end
  ```

  ## Common Mistakes

  1. **Forgetting to extract strings**
     ```bash
     mix gettext.extract  # Must run after code changes
     ```

  2. **Leaving %{variables} without curly braces**
     ```elixir
     # Wrong:
     gettext("Hello name")

     # Right:
     gettext("Hello, %{name}!", name: user_name)
     ```

  3. **Not setting locale** — Defaults to "en"
     ```elixir
     Gettext.put_locale(BlogWeb.Gettext, user.locale)  # Must do this
     ```

  4. **Marking strings in constants**
     ```elixir
     # Wrong: gettext called at compile time (always English)
     @greeting = gettext("Hello")

     # Right: Call at runtime
     def get_greeting, do: gettext("Hello")
     ```

  5. **Translations with raw HTML**
     ```elixir
     # Wrong: HTML not translated
     gettext("<b>Bold</b> text")

     # Right: Mark only text
     "<b>" <> gettext("Bold") <> "</b> text"
     ```

  ## Pluralization Rules

  Each language has different plural rules:

  English:
  - 1 item (singular)
  - 0, 2+ items (plural)

  Russian:
  - 1, 21, 31, ... (form 1)
  - 2-4, 22-24, ... (form 2)
  - 0, 5-20, 25-30, ... (form 3)

  Japanese:
  - Same form for all (no pluralization)

  Gettext automatically handles plural rules per language.

  ## Future Enhancements

  ### Plurals with Gender

  Some languages need to agree gender with plurals:
  ```
  msgid "He has one apple"
  msgid_plural "He has %{count} apples"
  msgstr[0] "..."
  msgstr[1] "..."
  ```

  ### Contexts (Advanced)

  Distinguish same string with different meanings:
  ```elixir
  pgettext("menu", "File")  # File menu
  pgettext("document", "File")  # A file (noun)
  ```

  ### Machine Translation

  Could integrate with translation APIs:
  - Google Translate
  - DeepL
  - AWS Translate

  ```elixir
  # Generate initial translations
  mix gettext.extract
  mix gettext.translate --service google --api-key "..."
  ```

  ### Translation Management UI

  Could build admin panel for translators:
  - List untranslated strings
  - Edit translations directly in UI
  - See live translations
  - Track translation progress

  ### Namespace Translations

  Keep different parts of app separate:
  ```
  priv/gettext/
    blog/              # Blog posts
    comments/          # Comment threads
    emails/            # Transactional emails
  ```

  ## Reference

  - [Gettext Docs](https://hexdocs.pm/gettext)
  - [GNU gettext Manual](https://www.gnu.org/software/gettext/manual/)
  - [Unicode CLDR](http://cldr.unicode.org/) — Locale data standards
  """
  use Gettext.Backend, otp_app: :blog
end
