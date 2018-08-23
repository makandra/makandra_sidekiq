# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

### Compatible changes
- CHANGELOG to satisfy [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) format

## 0.1.3 2017-02-13

### Changed
- Gem no longer depends on `capistrano`, since using its Capistrano recipes is optional.

## 0.1.2 2017-01-12

### Added
- `sidekiq:start` checks that sidekiq really comes up and will retry a few times.

## 0.1.1 2016-09-29

### Fixed
- Do not fail on first deploy.

## 0.1.0] 2016-09-29

### Added
- Initial release.
