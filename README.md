# oauth-flow-demo

## Getting Started

Clone the repo.

```
git clone git@github.com:dickdavis/oauth-flow-demo.git
```

Install the dependencies.

```
bundle install
```

Set-up the database.

```
bin/rails db:setup
```

Run the server.

```
bin/dev
```


Note: It's important to use `bin/dev` to run the server as it uses Foreman to manage both the Rails server and the TailwindCSS JIT compiler.

If you are experiencing any TailwindCSS-related errors, you should ensure you have a recent version of Node.js installed locally. It may also be necessary to change some bundler platform configuration to build the gems native for your platform. See [here](https://github.com/rails/tailwindcss-rails#check-bundle_force_ruby_platform)
