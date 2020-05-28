# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

**TODO**

## [0.1.4] - 2018-11-13

### Added

* Add the ability to generate an opaque type (#10)

## [0.1.3] - 2019-09-06

### Fixed

* Fix a bug where fields with `default: false` where still enforced when setting
    `enforce: true` at top-level

## [0.1.2] - 2018-09-06

### Added

* Add the ability to enforce keys by default (#6)

### Fixed

* Clarify the documentation about `runtime: false`

## [0.1.1] - 2018-06-20

### Fixed

* Do not make the type nullable when there is a default value

## [0.1.0] - 2018-06-19

### Added

* Struct definition
* Type definition
* Default values
* Enforced keys

[Unreleased]:https://github.com/ejpcmac/typed_struct/compare/master...develop
[0.1.4]: https://github.com/ejpcmac/typed_struct/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/ejpcmac/typed_struct/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/ejpcmac/typed_struct/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/ejpcmac/typed_struct/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ejpcmac/typed_struct/releases/tag/v0.1.0
