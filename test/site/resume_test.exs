defmodule Site.ResumeTest do
  use ExUnit.Case

  alias Site.Resume

  describe "data/0" do
    test "loads the resume JSON with expected sections" do
      data = Resume.data()

      assert is_map(data)

      for key <- ["profile", "work", "education", "skills", "languages", "awards"] do
        assert Map.has_key?(data, key), "missing #{key} section in resume data"
      end
    end
  end

  describe "getters" do
    test "return non-empty data" do
      assert is_map(Resume.get_profile())
      assert Resume.get_profile()["name"] != nil
      assert is_list(Resume.get_experience()) and Resume.get_experience() != []
      assert is_list(Resume.get_skills()) and Resume.get_skills() != []
      assert is_list(Resume.get_languages())
      assert is_list(Resume.get_education())
    end
  end

  describe "list_skills/0" do
    test "returns {name, favourite} tuples with favourites first" do
      skills = Resume.list_skills()

      assert is_list(skills) and skills != []

      assert Enum.all?(skills, fn {name, favourite} ->
               is_binary(name) and is_boolean(favourite)
             end)

      {favourites, rest} = Enum.split_while(skills, fn {_, favourite} -> favourite end)

      assert favourites != []
      assert Enum.all?(favourites, fn {_, favourite} -> favourite end)
      assert Enum.all?(rest, fn {_, favourite} -> not favourite end)
    end
  end

  describe "list_favourite_skills/0" do
    test "returns only favourite skills" do
      favourites = Resume.list_favourite_skills()

      assert favourites != []
      assert Enum.all?(favourites, fn {_, favourite} -> favourite end)
    end
  end
end
