defmodule Usher.ConfigTest do
  use ExUnit.Case, async: true

  describe "repo/0" do
    test "returns configured repo" do
      assert Usher.Config.repo() == Usher.Test.Repo
    end
  end

  describe "token_length/0" do
    test "returns configured token length" do
      assert Usher.Config.token_length() == 16
    end
  end

  describe "default_expires_in/0" do
    test "returns configured expiration duration" do
      assert Usher.Config.default_expires_in() == {7, :day}
    end
  end
end
