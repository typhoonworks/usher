# Test configuration for testing embedded schemas for the custom_attributes
# field of the `Usher.Invitation` schema

import Config

config :usher,
  schemas: %{
    invitation: %{
      custom_attributes_embedded_schema: Usher.CustomAttributesEmbeddedSchema
    }
  }
