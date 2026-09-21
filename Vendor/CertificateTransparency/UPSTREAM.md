# Domestic Roots Mobile

Source: https://github.com/yandex/domestic-roots-mobile
Revision: `6441cf22bafc37ab4d71841d9db4f1df145c8703`
Directory: `ios`
License: MIT (see LICENSE).

The production sources and upstream build manifests are copied without changes.
Upstream tests are not included. LoginSDK declares its own SPM target and compiles
these sources into its CocoaPods module. This makes the dependency mandatory for
both distributions without requiring a package manifest at the upstream repository
root or a separately published pod.

To update, replace the production sources and include directory from a reviewed
upstream revision, retain LICENSE, update this revision, and check both builds.
