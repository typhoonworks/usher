# Contributing

Thank you for your interest in contributing to Usher! This guide will help you get started with development and understand our contribution process.

## Development Setup

### Prerequisites

- Elixir 1.14 or later
- OTP 25 or later
- PostgreSQL (for running tests)
- Git

### Getting Started

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/your-username/usher.git
   cd usher
   ```

2. **Install dependencies**:
   ```bash
   mix deps.get
   ```

3. **Set up the database**:
   ```bash
   # Using Docker (recommended)
   docker-compose up -d
   
   # Or start PostgreSQL manually on port 2345
   # Then create and migrate the test database
   mix test.setup
   ```

4. **Run the tests to ensure everything works**:
   ```bash
   mix test
   ```

## Development Commands

### Testing
- `mix test` - Run all tests
- `mix test.setup` - Set up test database (drops, creates, migrates)
- `docker-compose up -d` - Start PostgreSQL for testing

### Database Operations
- `mix ecto.setup` - Create and migrate database
- `mix ecto.reset` - Drop and recreate database
- `mix ecto.migrate` - Run pending migrations

### Code Quality
- `mix lint` - Run formatter and dialyzer
- `mix format` - Format code according to project standards
- `mix dialyzer` - Run static analysis

### Documentation
- `mix docs` - Generate documentation locally
- `mix hex.publish` - Publish to Hex.pm (maintainers only)

## Code Style and Quality

### Formatting

We use the standard Elixir formatter. Before submitting code:

```bash
mix format
```

### Static Analysis

We use Dialyzer for static analysis. Run it before submitting:

```bash
mix dialyzer
```

### Code Standards

- Follow Elixir naming conventions
- Write clear, descriptive function and variable names
- Add documentation for public functions
- Include type specs for public functions
- Keep functions small and focused
- Write comprehensive tests for new functionality

If you notice any code that does not follow these standards, please let us know or submit a pull request to fix it. We strive for a clean and maintainable codebase.

## Submitting Changes

### 1. Create a Feature Branch

```bash
git checkout -b feature/amazing-feature
```

Use descriptive branch names:
- `feature/add-bulk-invitations`
- `fix/token-validation-bug`

### 2. Make Your Changes

- Write code following our style guidelines
- Add tests for new functionality
- Update documentation if needed
- Ensure all tests pass

### 3. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git commit -am 'Add bulk invitation creation feature

- Add Usher.create_bulk_invitations/2 function
- Include error handling for partial failures
- Add comprehensive tests for bulk operations
- Update documentation with usage examples'
```

### 4. Run Quality Checks

Before pushing, ensure code quality:

```bash
# Run tests
mix test

# Run all quality checks
mix lint
```

### 5. Push and Create Pull Request

```bash
git push origin feature/amazing-feature
```

Then create a pull request on GitHub with:
- Clear description of changes
- Reference to any related issues

## Pull Request Guidelines

### PR Description Template

```markdown
## Summary
Brief description of what this PR does.

## Changes
- List of specific changes made
- Any breaking changes
- New features added

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Documentation
- [ ] Updated relevant documentation
- [ ] Added docstrings for new public functions
- [ ] Updated CHANGELOG.md if applicable

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Tests added and passing
- [ ] Documentation updated
```

### Review Process

1. **Automated Checks**: CI will run tests and quality checks
2. **Code Review**: Maintainers will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged

## Reporting Issues

### Bug Reports

When reporting bugs, include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Exact steps to trigger the bug
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: Elixir/OTP versions, database version
- **Code Examples**: Minimal code that reproduces the issue

### Feature Requests

For feature requests, include:

- **Use Case**: Why is this feature needed?
- **Proposed Solution**: How should it work?
- **Alternatives**: Other ways to solve the problem
- **Examples**: Code examples of proposed API

## Documentation

### Writing Documentation

- Use clear, concise language
- Include code examples
- Document all public functions with `@doc`
- Add type specs with `@spec`
- Update guides when adding new features

### Building Documentation

```bash
# Generate docs locally
mix docs

# Open docs in browser
open doc/index.html
```

## Releasing

For maintainers only:

1. Update version in `mix.exs`
2. Update `CHANGELOG.md`
3. Run tests and quality checks
4. Publish to Hex: `mix hex.publish`
5. Create release on GitHub, with tag matching version in `mix.exs`

## Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Email**: Reach out to maintainers for sensitive issues

## Code of Conduct

Please be respectful and constructive in all interactions. We want Usher to be a welcoming project for contributors of all backgrounds and experience levels.

Thank you for contributing to Usher! 🎉