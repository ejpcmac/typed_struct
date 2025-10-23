#!/usr/bin/env elixir

defmodule CheckCommits do
  def run do
    commits = commits_to_check()

    if commits do
      IO.puts("==> Commits to check\n")
      list_commits(commits)

      IO.puts("\n\n==> Running committed\n")
      status = check_commits(commits)
      if status == :error, do: System.halt(1)
    else
      IO.puts("No commit to check")
    end
  end

  defp commits_to_check do
    is_pull_request = System.get_env("IS_PULL_REQUEST") == "true"

    if is_pull_request do
      "HEAD~..HEAD^2"
    else
      branch = get_current_branch()

      if branch in ["main", "develop"] do
        nil
      else
        merge_base = get_merge_base("origin/develop")
        "#{merge_base}..HEAD"
      end
    end
  end

  defp list_commits(commits) do
    {_, status} =
      System.cmd(
        "git",
        [
          "--no-pager",
          "log",
          "--pretty=format:%C(yellow)%h%Creset %s",
          commits
        ],
        use_stdio: false
      )

    if status != 0, do: raise("Failed to run `git log`")
  end

  defp check_commits(commits) do
    with {_, 0} <- System.cmd("committed", [commits], use_stdio: false) do
      :ok
    else
      _ -> :error
    end
  end

  defp get_current_branch do
    {output, status} = System.cmd("git", ~w(branch --show-current))
    if status != 0, do: raise("Failed to run `git branch --show-current`")
    String.trim(output)
  end

  defp get_merge_base(into) do
    {output, status} = System.cmd("git", ~w(merge-base #{into} HEAD))
    if status != 0, do: raise("Failed to run `git merge-base`")
    String.trim(output)
  end
end

CheckCommits.run()
