# Changelog

## v0.1.4

* Add the ability to generate an opaque type (#10)

## v0.1.3

* Fix a bug where fields with `default: false` where still enforced when setting
    `enforce: true` at top-level

## v0.1.2

* Add the ability to enforce keys by default (#6)
* Clarify the documentation about `runtime: false`

## v0.1.1

* Do not make the type nullable when there is a default value

## v0.1.0

* Initial version
    * Struct definition
    * Type definition
    * Default values
    * Enforced keys
