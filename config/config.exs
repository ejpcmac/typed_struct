use Mix.Config

# This configuration is loaded before any dependency and is restricted to this
# project. If another project depends on this project, this file won’t be loaded
# nor affect the parent project. For this reason, if you want to provide default
# values for your application for 3rd-party users, it should be done in your
# "mix.exs" file.

if Mix.env() == :dev do
  # Clear the console before each test run
  config :mix_test_watch, clear: true
end

# # Import environment specific config. This must remain at the bottom of this
# # file so it overrides the configuration defined above.
# import_config "#{Mix.env()}.exs"
