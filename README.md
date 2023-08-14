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

Note: It's important to use `bin/dev` to run the server as it uses Foreman to manage both the Rails server and the TailwindCSS compiler.
