# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased


## 0.2.1 2020-05-18

### Compatible changes
- Fixed deprecation warnings on modern Bundlers. We are now using `Bundler.with_original_env`.


## 0.2.0 2019-11-08

### Compatible changes
- Added CHANGELOG to satisfy [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
- Fix: now considering the configured Sidekiq timeout when running
  `sidekiqctl stop` through `sidekiq:stop`. Previously, long-running jobs would
  get lost!


## 0.1.3 2017-02-13

### Changed
- Gem no longer depends on `capistrano`, since using its Capistrano recipes is optional.


## 0.1.2 2017-01-12

### Added
- `sidekiq:start` checks that sidekiq really comes up and will retry a few times.


## 0.1.1 2016-09-29

### Fixed
- Do not fail on first deploy.


## 0.1.0 2016-09-29

### Added
- Initial release.
