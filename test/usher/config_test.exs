defmodule Usher.ConfigTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Usher.Config

  setup :verify_on_exit!

  setup do
    Mimic.copy(Application)

    :ok
  end

  describe "repo/0" do
    test "returns configured repo" do
      assert Config.repo() == Usher.Test.Repo
    end
  end

  describe "token_length/0" do
    test "returns configured token length" do
      assert Config.token_length() == 16
    end
  end

  describe "default_expires_in/0" do
    test "returns configured expiration duration" do
      assert Config.default_expires_in() == {7, :day}
    end
  end

  describe "validations/0" do
    test "returns configured validations" do
      assert Config.validations() == %{
               invitation_usage: %{
                 valid_usage_entity_types: [:user, :company, :device],
                 valid_usage_actions: [:visited, :registered, :activated]
               }
             }
    end
  end

  describe "name_required?/0" do
    test "returns true when name is required" do
      expect(Application, :get_env, fn :usher, :validations, _ ->
        %{invitation: %{name_required: true}}
      end)

      assert Config.name_required?()
    end

    test "returns false when name is not required" do
      expect(Application, :get_env, fn :usher, :validations, _ ->
        %{invitation: %{name_required: false}}
      end)

      refute Config.name_required?()
    end

    test "returns true when name_required is not defined" do
      expect(Application, :get_env, fn :usher, :validations, _ ->
        %{}
      end)

      assert Config.name_required?()
    end
  end
end
