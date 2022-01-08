defmodule StringHelperTest do
  use ExUnit.Case

  describe "replace_at" do
    test "replaces character" do
      assert StringHelper.replace_at("abcde", 0, ".") == ".bcde"
    end
  end
end
