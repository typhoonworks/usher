# Usher
<p>
  <a href="https://hex.pm/packages/usher">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/usher.svg">
  </a>
  <a href="https://hexdocs.pm/usher">
    <img src="https://img.shields.io/badge/docs-hexdocs-blue" alt="HexDocs">
  </a>
  <a href="https://github.com/typhoonworks/usher/actions">
    <img alt="CI Status" src="https://github.com/typhoonworks/usher/workflows/ci/badge.svg">
  </a>
</p>

Usher is a web framework-agnostic invitation link management library for any Elixir application with Ecto.

>🚧 This library is in its infancy so you should treat all versions as early pre-release versions. We'll make the best effort to give heads up about breaking changes; however we can't guarantee backwards compatibility for every change.
>
> Have use cases not covered by Usher? Open an issue, we'd love to help you out ❤️.
>
> Our use cases don't require heavy uses of invitation links. Have use cases that require a heavy use of invitiation links? Open an issue and we'd love to optimize Usher 🏃.

## Current Features
- 🔐 **Token generation**: Create invitation with a single API call
- 🏗️ **Framework agnostic**: Works with any Ecto-based application
- 🤝 **Flexible usage tracking**: For tracking invitation link usage
- ⏰ **Expiration management**: Extend or set expiration dates for invitations, or create never-expiring invitations

## What's planned?
- [x] Invitations with no expiration date.
- [x] Linking invitation tokens to user accounts (e.g. to track which user registered with which invitation): Added in v0.3.0.
- [x] Cryptographic signing of invitation tokens to prevent guessing tokens.
- [x] Web UI for managing invitation tokens.
- [x] Soft delete for invitations to keep them in the database for analytics purposes. 
- [x] Clean-up functions for expired invitations.
- [ ] Invitation expiration after X number of uses (including one-time use links).
- [ ] One-time use invitation links tied to specific email addresses.
- [ ] Descriptions for invitation links so you can provide context for its usage.
- [ ] Add credo checks to ensure code quality.
- [ ] Add status checks and run tests on pull requests.

## Installation
Add `usher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:usher, "~> 0.5.1"}
  ]
end
```
Run the install script to create your migrations

```bash
mix Usher.install
```
Add the following to routes.ex

```elixir
defmodule Router do
use Kaffy.Routes,
    scope: "/admin/crm",
    pipe_through: [:browser, :kaffy_browser]

  pipeline :kaffy_browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  end
```

Usher requires Elixir 1.14 or later, and OTP 25 or later. It may work with earlier versions, but it wasn't tested against them.

Follow the [installation instructions](guides/installation.md) to set up Usher in your application.

## Getting Started
Take a look at the [overview guide](guides/overview.md) for a quick introduction to Usher.

## Phoenix Integration
Take a look at the [Phoenix integration guide](guides/phoenix-integration.md) for details on how to set up Usher in your Phoenix application.

## Configuration Options
View all the configuration options in the [configuration guide](guides/configuration.md).

## Contributing
See the [contribution guide](guides/contributing.md) for details on how to contribute to Usher.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Inspiration
We first built this invitation system into [Accomplish](https://github.com/typhoonworks/accomplish) and then decided to open-source it.
