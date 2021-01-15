# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_There are no unreleased changes at the moment._

## [2.0.2] - 2021-01-15

### Fixed

* Fix upload of large files to MinIO.

## [2.0.1] - 2021-01-13

### Fixed

* Fix certificate checking bypass when `--no-check-certificate` is used.
* Improve error messages.

## [2.0.0] - 2020-12-17

### Changed

* Support of HTTP and SOCKS5 proxies thanks to libcurl.
* Use Cryptosense v2 API to create traces.

## [1.0.0] - 2020-04-06

### Changed

* Make trace upload a subcommand: `cs-api upload-trace`.
* The `/api/v1` URL segment must not be specified in the URL passed with `--api-base-url`.

### Fixed

* Fix flickering of progress bar.
* Fix API key header for on-premises installations: `API_KEY` -> `API-KEY`.

### Added

* Add a release compatible with CentOS 7 and derived distributions (e.g. RHEL 7).
* Add `--no-check-certificate` option

## [0.0.4] - 2020-02-17

### Security

* Use OpenSSL backend of Conduit instead of the default.

## [0.0.3] - 2019-12-09

### Changed

* Use AWS S3 v4 signature scheme.

## [0.0.2] - 2019-07-18

### Added

* Upload progress bar.

## [0.0.1] - 2019-04-29

Initial release.

[Unreleased]: https://github.com/cryptosense/api-client/compare/2.0.2...HEAD
[2.0.2]: https://github.com/cryptosense/api-client/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/cryptosense/api-client/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/cryptosense/api-client/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/cryptosense/api-client/compare/0.0.4...1.0.0
[0.0.4]: https://github.com/cryptosense/api-client/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/cryptosense/api-client/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/cryptosense/api-client/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/cryptosense/api-client/releases/tag/0.0.1
