defmodule Mix.Tasks.Release.Bump do
  use Mix.Task

  @shortdoc "Bumps the application version and creates a release"

  @moduledoc """
  Bumps the application version, creates a git tag, and optionally creates a GitHub release.

  ## Usage

      mix release.bump [major|minor|patch] [options]

  ## Examples

      mix release.bump patch              # 0.1.0 → 0.1.1 (bug fixes, content)
      mix release.bump minor              # 0.1.0 → 0.2.0 (new features)
      mix release.bump major              # 0.1.0 → 1.0.0 (breaking changes)
      mix release.bump patch --no-push    # bump but don't push/release
      mix release.bump minor --yes        # skip confirmation prompt
      mix release.bump patch --dry-run    # preview changes without making them

  ## Options

    * `--no-push` - Don't push to GitHub (default: false, will push)
    * `--yes` - Skip confirmation prompt (default: false)
    * `--message` - Custom commit message (default: "chore: bump version to vX.Y.Z")
    * `--dry-run` - Show what would happen without doing it (default: false)

  ## Version Strategy

    * **Patch** (v0.1.1): Bug fixes, typos, blog posts, minor tweaks
    * **Minor** (v0.2.0): New features, new pages, significant enhancements
    * **Major** (v1.0.0): Breaking changes, major redesigns

  ## Safety Features

  The task includes several safety checks:
  - Verifies git working directory is clean
  - Warns if not on main/master branch
  - Checks if tag already exists
  - Verifies remote exists before pushing
  - Requires confirmation before pushing (unless --yes)
  """

  @switches [
    no_push: :boolean,
    yes: :boolean,
    message: :string,
    dry_run: :boolean
  ]

  @aliases [
    y: :yes,
    n: :no_push
  ]

  @mix_exs_path "mix.exs"

  @doc false
  def run([]), do: Mix.raise("You must specify a bump type: major, minor, or patch")

  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches, aliases: @aliases)

    case argv do
      [bump_type] when bump_type in ["major", "minor", "patch"] ->
        bump_version(String.to_atom(bump_type), opts)

      [invalid] ->
        Mix.raise("Invalid bump type '#{invalid}'. Must be: major, minor, or patch")

      _ ->
        Mix.raise("You must specify exactly one bump type: major, minor, or patch")
    end
  end

  defp bump_version(bump_type, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)

    if dry_run?, do: Mix.shell().info("🔍 DRY RUN MODE - No changes will be made\n")

    # Safety checks
    check_git_status!(dry_run?)
    check_git_branch()
    check_git_remote!(dry_run?)

    # Read current version
    current_version = read_current_version()
    Mix.shell().info("📌 Current version: #{current_version}")

    # Calculate new version
    new_version = calculate_new_version(current_version, bump_type)
    new_tag = "v#{new_version}"
    Mix.shell().info("🎯 New version: #{new_version} (tag: #{new_tag})")

    # Check if tag exists
    check_tag_exists!(new_tag, dry_run?)

    # Update mix.exs
    unless dry_run? do
      update_mix_exs(new_version)
      Mix.shell().info("✅ Updated mix.exs")
    else
      Mix.shell().info("   Would update mix.exs")
    end

    # Create git commit
    commit_message =
      Keyword.get(opts, :message, "chore: bump version to #{new_tag}")

    unless dry_run? do
      create_commit(commit_message)
      Mix.shell().info("✅ Created commit: #{commit_message}")
    else
      Mix.shell().info("   Would create commit: #{commit_message}")
    end

    # Create git tag
    tag_message = "Release #{new_tag}"

    unless dry_run? do
      create_tag(new_tag, tag_message)
      Mix.shell().info("✅ Created tag: #{new_tag}")
    else
      Mix.shell().info("   Would create tag: #{new_tag}")
    end

    # Push to GitHub and create release
    should_push? = not Keyword.get(opts, :no_push, false)
    skip_confirm? = Keyword.get(opts, :yes, false)

    if should_push? do
      if dry_run? do
        Mix.shell().info("\n   Would push to GitHub and create release")
        Mix.shell().info("   Release notes would be auto-generated from git commits")
      else
        if skip_confirm? or confirm_push?(new_tag) do
          push_to_github(new_tag)
          create_github_release(new_tag)
          Mix.shell().info("\n🚀 Successfully released #{new_tag}!")
          Mix.shell().info("   GitHub Actions will automatically deploy this release.")
        else
          Mix.shell().info("\n❌ Push cancelled. Tag and commit created locally.")
          Mix.shell().info("   To push later, run: git push && git push origin #{new_tag}")
        end
      end
    else
      Mix.shell().info("\n✅ Version bumped locally (not pushed)")
      Mix.shell().info("   To push, run: git push && git push origin #{new_tag}")
    end
  end

  defp read_current_version do
    content = File.read!(@mix_exs_path)

    case Regex.run(~r/version:\s*"([^"]+)"/, content) do
      [_, version] -> version
      _ -> Mix.raise("Could not find version in mix.exs")
    end
  end

  defp calculate_new_version(current, bump_type) do
    [major, minor, patch] =
      current
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)

    case bump_type do
      :major -> "#{major + 1}.0.0"
      :minor -> "#{major}.#{minor + 1}.0"
      :patch -> "#{major}.#{minor}.#{patch + 1}"
    end
  end

  defp update_mix_exs(new_version) do
    content = File.read!(@mix_exs_path)

    new_content =
      Regex.replace(
        ~r/version:\s*"[^"]+"/,
        content,
        "version: \"#{new_version}\""
      )

    File.write!(@mix_exs_path, new_content)
  end

  defp create_commit(message) do
    run_cmd!("git", ["add", @mix_exs_path])
    run_cmd!("git", ["commit", "-m", message])
  end

  defp create_tag(tag, message) do
    run_cmd!("git", ["tag", "-a", tag, "-m", message])
  end

  defp push_to_github(tag) do
    Mix.shell().info("\n📤 Pushing to GitHub...")
    run_cmd!("git", ["push"])
    run_cmd!("git", ["push", "origin", tag])
    Mix.shell().info("✅ Pushed commit and tag")
  end

  defp create_github_release(tag) do
    Mix.shell().info("\n📝 Creating GitHub release with auto-generated notes...")

    result =
      run_cmd("gh", [
        "release",
        "create",
        tag,
        "--generate-notes",
        "--title",
        "Release #{tag}"
      ])

    case result do
      {output, 0} ->
        Mix.shell().info("✅ Created GitHub release")
        Mix.shell().info(String.trim(output))

      {error, _} ->
        Mix.shell().error("⚠️  Failed to create GitHub release: #{error}")
        Mix.shell().info("   You can create it manually from GitHub UI")
    end
  end

  defp check_git_status!(dry_run?) do
    if dry_run?, do: return_if_dry_run()

    {output, status} = run_cmd("git", ["status", "--porcelain"])

    if status == 0 and String.trim(output) != "" do
      Mix.raise("""
      Git working directory is not clean. Please commit or stash your changes first.

      Uncommitted changes:
      #{output}
      """)
    end
  end

  defp check_git_branch do
    {branch, 0} = run_cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
    branch = String.trim(branch)

    unless branch in ["main", "master"] do
      Mix.shell().info("⚠️  Warning: You are on branch '#{branch}', not main/master")

      unless Mix.shell().yes?("   Continue anyway?") do
        Mix.raise("Aborted by user")
      end
    end
  end

  defp check_git_remote!(dry_run?) do
    if dry_run?, do: return_if_dry_run()

    case run_cmd("git", ["remote", "get-url", "origin"]) do
      {_, 0} -> :ok
      _ -> Mix.raise("No git remote 'origin' found. Cannot push to GitHub.")
    end
  end

  defp check_tag_exists!(tag, dry_run?) do
    if dry_run?, do: return_if_dry_run()

    case run_cmd("git", ["tag", "-l", tag]) do
      {output, 0} when output != "" ->
        Mix.raise("Tag #{tag} already exists. Cannot create duplicate tag.")

      _ ->
        :ok
    end
  end

  defp confirm_push?(tag) do
    Mix.shell().info("\n⚠️  This will:")
    Mix.shell().info("   1. Push the commit to GitHub")
    Mix.shell().info("   2. Create and push tag #{tag}")
    Mix.shell().info("   3. Create a GitHub release")
    Mix.shell().info("   4. Trigger automatic deployment via GitHub Actions")

    Mix.shell().yes?("\n   Continue?")
  end

  defp run_cmd(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {output, status} -> {output, status}
    end
  rescue
    e in ErlangError ->
      Mix.raise("Failed to run command '#{cmd}': #{inspect(e)}")
  end

  defp run_cmd!(cmd, args) do
    case run_cmd(cmd, args) do
      {output, 0} -> output
      {error, _} -> Mix.raise("Command failed: #{cmd} #{Enum.join(args, " ")}\n#{error}")
    end
  end

  defp return_if_dry_run, do: :ok
end
