# makandra_sidekiq [![Build Status](https://travis-ci.org/makandra/makandra_sidekiq.svg?branch=master)](https://travis-ci.org/makandra/makandra_sidekiq)

Support code for our default sidekiq setup.

Includes rake tasks to start and stop sidekiq, capistrano recipes for deployment, and a way to restart sidekiq on reboot.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'makandra_sidekiq'
```


## Usage

### Prerequisites

Your sidekiq configuration has to live in `config/sidekiq.yml`.

Make sure you include at least `:pidfile` and `:logfile`. Sane values are

```
:pidfile: ./tmp/pids/sidekiq.pid
:logfile: ./log/sidekiq.log
```

### Capistrano

makandra_sidekiq requires [capistrano](https://github.com/capistrano/capistrano) >= 3.

- Add the following line to your Capfile:

  ```
  require 'makandra_sidekiq/capistrano'
  ```

- Give one or more servers the `sidekiq` role.

- Make sure that your pidfile is symlinked to a shared directory. For the example above, make sure that `set :linked_dirs` includes `tmp/pids`.


### Restart sidekiq on reboot

Simply add `rake sidekiq:start` as a @reboot task to your crontab.

When using [whenever](https://github.com/javan/whenever), add this to your schedule.rb:

```
every :reboot do
  rake 'sidekiq:start'
end
```

In case you don't use whenever, this crontab entry will work:
```
@reboot /bin/bash -l -c 'cd /path/to/rails/root && RAILS_ENV=environment bundle exec rake sidekiq:start --silent'
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/makandra/makandra_sidekiq.


## Credits

Tobias Kraze, makandra GmbH

Arne Hartherz, makandra GmbH
