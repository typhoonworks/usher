# Overview

Usher is a web framework-agnostic invitation link management library for any Elixir application with Ecto.

>🚧 This library is in its infancy so you should treat all versions as early pre-release versions. We'll make the best effort to give heads up about breaking changes; however we can't guarantee backwards compatibility for every change.

## Core Use Cases

Usher is designed to handle invitation-based access control for applications where:

- You need to control who can register or access specific features
- You need time-limited access tokens
- You want web framework-agnostic invitation management that works with Phoenix, Plug, or any Ecto-based application

The library is designed to be lightweight and focused, handling the core invitation logic while leaving application-specific concerns (like user registration, email sending, etc.) to your application code.

Get started by checking out the [installation guide](guides/installation.md) and the [getting started guide](guides/getting-started.md).