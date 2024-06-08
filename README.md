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

## Test Suite

Run the test suite by executing `bundle exec rspec`.

### Performance

The commands listed below will help assess the performance of the test suite and identity possible areas of improvement. Refer to the `test-prof` [documentation](https://test-prof.evilmartians.io) for more information.

Measure execution time by spec type:

```
TAG_PROF=type bundle exec rspec
```

Generate a chart showing execution time by spec type and event:

```
TAG_PROF=type TAG_PROF_FORMAT=html TAG_PROF_EVENT=sql.active_record,factory.create bundle exec rspec
```

Measure execution time for database interactions:

```
EVENT_PROF='sql.active_record' bundle exec rspec
```

Measure execution time for factories:

```
EVENT_PROF='factory.create' bundle exec rspec
```

Check for suboptimal usage of factories:

```
FDOC=1 bundle exec rspec
```

Identify all usages of factories:

```
FPROF=1 bundle exec rspec
```

Generate a flamegraph of factory usage:

```
FPROF=flamegraph bundle exec rspec
```

Check for possible usages of factory defaults:

```
FACTORY_DEFAULT_PROF=1 bundle exec rspec --tag slow:factory
```

Measure time spent in spec set-up:

```
RD_PROF=1 bundle exec rspec
```
