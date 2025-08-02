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

## Current Features
- 🔐 **Token generation**: Create invitation with a single API call
- 🏗️ **Framework agnostic**: Works with any Ecto-based application
- 🤝 **Flexible usage tracking**: For tracking invitation link usage
- ⏰ **Expiration management**: Extend, set, or remove expiration dates from invitations

## What's planned?
- [ ] Auto-cleanup of expired invitations.
- [ ] More advanced usage tracking.
   - [ ] Metadata about those who visited and used the invitation (approx. location, user agent, etc.).
   - [x] Linking invitation tokens to user accounts (e.g. to track which user registered with which invitation): Added in v0.3.0.
- [ ] Invitation expiration after X number of uses (including one-time use links).
- [ ] One-time use invitation links tied to specific email addresses.
- [ ] Descriptions for invitation links so you can provide context for its usage.
- [ ] Cryptographic signing of invitation tokens to prevent tampering.
- [ ] Add credo checks to ensure code quality.
- [ ] Add status checks and run tests on pull requests.
- [ ] Soft delete for invitations to keep them in the database for analytics purposes.



## Installation
Add `usher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:usher, "~> 0.3.0"}
  ]
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
