# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed

- The default value of `--api-base-url` is changed to
  `https://aqtiveguard.cryptosense.com`. The former value caused the client to exit early
  with an HTTP 308 response code (permanent redirect).
- Fix a bug which would prevent upload from working on Windows (an error would be returned
  by the client).
- Fix an API server error when `--filename` is absent.

### Added


- Add more logging. The verbosity is controlled with two new flags:
  `--quiet` and `--verbose`. The coloring is controlled with a new parameter: `--color`.

## [2.6.0] - 2024-07-24

### Added

- Add the ability for `--filename` to accept a directory. The client will upload the file
  in that directory only if it contains a single file.
- Add more details to error messages if the client fails to read a directory or trace
  file.

### Changed

- Make `--trace-name` optional. If not provided, the server will pick the name for the
  newly uploaded trace. This is useful because trace names must be unique within a project
  on the server, and users may not know what names are already taken.

## [2.5.2] - 2024-04-16

### Fixed

- Fix trace uploading.

## [2.5.1] - 2023-11-08

### Fixed

- Fix compatibility with SeaweedFS API responses.

## [2.5.0] - 2023-10-19

### Fixed

- Fix GraphQL query to be compatible with backend version 23.09.7 and onward.

## [2.4.0] - 2023-06-03

### Added

- Added compatibility of the client with PUT uploads.

## [2.3.0] - 2023-04-22

### Added

- Add `--slot-name` command-line argument.

## [2.2.0] - 2022-05-20

### Fixed

- Fix exit code and error message for several error cases (project not found, trace name
  already taken, etc).
- Improve error message when certificate validation fails.
- Initialize libcurl only once per run instead of once per request.

### Added

- Add `--ca-file` option to choose trusted CAs.
- Add support for Windows.

## [2.1.0] - 2021-04-13

### Added

- Add `--project-name` command-line argument.

## [2.0.2] - 2021-01-15

### Fixed

- Fix upload of large files to MinIO.

## [2.0.1] - 2021-01-13

### Fixed

- Fix certificate checking bypass when `--no-check-certificate` is used.
- Improve error messages.

## [2.0.0] - 2020-12-17

### Changed

- Support of HTTP and SOCKS5 proxies thanks to libcurl.
- Use Cryptosense v2 API to create traces.

## [1.0.0] - 2020-04-06

### Changed

- Make trace upload a subcommand: `cs-api upload-trace`.
- The `/api/v1` URL segment must not be specified in the URL passed with `--api-base-url`.

### Fixed

- Fix flickering of progress bar.
- Fix API key header for on-premises installations: `API_KEY` -> `API-KEY`.

### Added

- Add a release compatible with CentOS 7 and derived distributions (e.g. RHEL 7).
- Add `--no-check-certificate` option.

## [0.0.4] - 2020-02-17

### Security

- Use OpenSSL backend of Conduit instead of the default.

## [0.0.3] - 2019-12-09

### Changed

- Use AWS S3 v4 signature scheme.

## [0.0.2] - 2019-07-18

### Added

- Upload progress bar.

## [0.0.1] - 2019-04-29

Initial release.

[Unreleased]: https://github.com/cryptosense/api-client/compare/2.6.0..HEAD
[2.6.0]: https://github.com/cryptosense/api-client/compare/2.5.1...2.6.0
[2.5.2]: https://github.com/cryptosense/api-client/compare/2.5.1...2.5.2
[2.5.1]: https://github.com/cryptosense/api-client/compare/2.5.0...2.5.1
[2.5.0]: https://github.com/cryptosense/api-client/compare/2.4.0...2.5.0
[2.4.0]: https://github.com/cryptosense/api-client/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/cryptosense/api-client/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/cryptosense/api-client/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/cryptosense/api-client/compare/2.0.2...2.1.0
[2.0.2]: https://github.com/cryptosense/api-client/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/cryptosense/api-client/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/cryptosense/api-client/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/cryptosense/api-client/compare/0.0.4...1.0.0
[0.0.4]: https://github.com/cryptosense/api-client/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/cryptosense/api-client/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/cryptosense/api-client/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/cryptosense/api-client/releases/tag/0.0.1
