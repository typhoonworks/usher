# Test configuration for testing embedded schemas for the custom_attributes
# field of the `Usher.Invitation` schema

import Config

config :usher,
  schema_overrides: %{
    invitation: %{
      custom_attributes_type: Usher.CustomAttributesEmbeddedSchema
    }
  }
