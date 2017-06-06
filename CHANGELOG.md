# Change Log

## [v1.27.0](https://github.com/chef/inspec/tree/v1.27.0) (2017-06-06)
[Full Changelog](https://github.com/chef/inspec/compare/v1.26.0...v1.27.0)

**Implemented enhancements:**

- Support special cases for crontab resource [\#1893](https://github.com/chef/inspec/pull/1893) ([arlimus](https://github.com/arlimus))
- add the Nginx parser [\#1888](https://github.com/chef/inspec/pull/1888) ([arlimus](https://github.com/arlimus))
- support FIPS 140-2 compliant digest calls [\#1887](https://github.com/chef/inspec/pull/1887) ([arlimus](https://github.com/arlimus))
- Add windows support to the `processes` resource [\#1878](https://github.com/chef/inspec/pull/1878) ([username-is-already-taken2](https://github.com/username-is-already-taken2))
- add bitbucket repo url handling [\#1866](https://github.com/chef/inspec/pull/1866) ([stubblyhead](https://github.com/stubblyhead))
- Commenting the `contain\_duplicates` deprecation until we have a good alternative [\#1860](https://github.com/chef/inspec/pull/1860) ([alexpop](https://github.com/alexpop))
- verifies that inspec.yml uses licenses in SPDX format [\#1858](https://github.com/chef/inspec/pull/1858) ([chris-rock](https://github.com/chris-rock))
- funtion to get pgsql version, exposed version, cluster and fixed session [\#1758](https://github.com/chef/inspec/pull/1758) ([aaronlippold](https://github.com/aaronlippold))

**Fixed bugs:**

- Use RubyGems version for habitat plan [\#1883](https://github.com/chef/inspec/pull/1883) ([smith](https://github.com/smith))
- Fix version method call for refresh token [\#1875](https://github.com/chef/inspec/pull/1875) ([ndobson](https://github.com/ndobson))
- Add warningaction to test-netconnection [\#1869](https://github.com/chef/inspec/pull/1869) ([seththoenen](https://github.com/seththoenen))
- Fix parameters to `find` commands [\#1856](https://github.com/chef/inspec/pull/1856) ([chris-rock](https://github.com/chris-rock))
- Fix command exists check on Windows with full paths [\#1850](https://github.com/chef/inspec/pull/1850) ([username-is-already-taken2](https://github.com/username-is-already-taken2))
- Fix compliance uploads when version is not present [\#1849](https://github.com/chef/inspec/pull/1849) ([adamleff](https://github.com/adamleff))

## [v1.26.0](https://github.com/chef/inspec/tree/v1.26.0) (2017-05-31)
[Full Changelog](https://github.com/chef/inspec/compare/v1.25.1...v1.26.0)

**Implemented enhancements:**

- Bump default timeouts for `http` resource [\#1835](https://github.com/chef/inspec/pull/1835) ([schisamo](https://github.com/schisamo))
- Improvements to Habitat plan [\#1820](https://github.com/chef/inspec/pull/1820) ([smith](https://github.com/smith))

**Fixed bugs:**

- adjust localhost+sudo test output to train update [\#1873](https://github.com/chef/inspec/pull/1873) ([arlimus](https://github.com/arlimus))
- sudo-detection for target execution [\#1870](https://github.com/chef/inspec/pull/1870) ([arlimus](https://github.com/arlimus))
- bugfix: do not send nil to command on unsupported OS [\#1865](https://github.com/chef/inspec/pull/1865) ([arlimus](https://github.com/arlimus))
- bugfix: non-url servers with compliance login [\#1861](https://github.com/chef/inspec/pull/1861) ([arlimus](https://github.com/arlimus))
- Raise exception if profile target URL cannot be parsed [\#1853](https://github.com/chef/inspec/pull/1853) ([adamleff](https://github.com/adamleff))
- postgres relative path includes [\#1852](https://github.com/chef/inspec/pull/1852) ([aaronlippold](https://github.com/aaronlippold))
- Amended the processes resource to skip on windows [\#1851](https://github.com/chef/inspec/pull/1851) ([username-is-already-taken2](https://github.com/username-is-already-taken2))
- Fix assert that a gem is not installed [\#1844](https://github.com/chef/inspec/pull/1844) ([cattywampus](https://github.com/cattywampus))
- Habitat Profiles: redirect stderr to stdout [\#1826](https://github.com/chef/inspec/pull/1826) ([adamleff](https://github.com/adamleff))

## [v1.25.1](https://github.com/chef/inspec/tree/v1.25.1) (2017-05-20)
[Full Changelog](https://github.com/chef/inspec/compare/v1.25.0...v1.25.1)

**Implemented enhancements:**

- throw an error during inspec check if the version is not correct [\#1832](https://github.com/chef/inspec/pull/1832) ([chris-rock](https://github.com/chris-rock))

**Fixed bugs:**

- Fixing typo on method name [\#1841](https://github.com/chef/inspec/pull/1841) ([cheeseplus](https://github.com/cheeseplus))

## [v1.25.0](https://github.com/chef/inspec/tree/v1.25.0) (2017-05-17)
[Full Changelog](https://github.com/chef/inspec/compare/v1.24.0...v1.25.0)

**Implemented enhancements:**

- return version as json [\#1822](https://github.com/chef/inspec/pull/1822) ([chris-rock](https://github.com/chris-rock))
- support new automate compliance backend [\#1819](https://github.com/chef/inspec/pull/1819) ([chris-rock](https://github.com/chris-rock))

**Fixed bugs:**

- read source code if profile is in tgz/zip [\#1816](https://github.com/chef/inspec/pull/1816) ([arlimus](https://github.com/arlimus))

## [v1.24.0](https://github.com/chef/inspec/tree/v1.24.0) (2017-05-11)
[Full Changelog](https://github.com/chef/inspec/compare/v1.23.0...v1.24.0)

**Implemented enhancements:**

- minor ui fix [\#1807](https://github.com/chef/inspec/pull/1807) ([echohack](https://github.com/echohack))
- Add busybox-static to habitat plan so netstat works for port resource on linux [\#1805](https://github.com/chef/inspec/pull/1805) ([elliott-davis](https://github.com/elliott-davis))
- add sha256 checksum to json [\#1796](https://github.com/chef/inspec/pull/1796) ([arlimus](https://github.com/arlimus))
- add platform info to json formatter [\#1792](https://github.com/chef/inspec/pull/1792) ([arlimus](https://github.com/arlimus))
- Update hab exporter to use inspec in path over calling to hab sup [\#1791](https://github.com/chef/inspec/pull/1791) ([elliott-davis](https://github.com/elliott-davis))
- Add support for Windows auth in mssql\_resourcet [\#1786](https://github.com/chef/inspec/pull/1786) ([arlimus](https://github.com/arlimus))
- Allow mysql\_session to test databases on different hosts [\#1779](https://github.com/chef/inspec/pull/1779) ([aaronlippold](https://github.com/aaronlippold))
- Handle parse errors for attrs/secrets [\#1775](https://github.com/chef/inspec/pull/1775) ([adamleff](https://github.com/adamleff))

## [v1.23.0](https://github.com/chef/inspec/tree/v1.23.0) (2017-05-04)
[Full Changelog](https://github.com/chef/inspec/compare/v1.22.0...v1.23.0)

**Implemented enhancements:**

- Add command-line completions for fish shell [\#1760](https://github.com/chef/inspec/pull/1760) ([smith](https://github.com/smith))

**Merged pull requests:**

- rake: lint before test [\#1755](https://github.com/chef/inspec/pull/1755) ([arlimus](https://github.com/arlimus))

## [v1.22.0](https://github.com/chef/inspec/tree/v1.22.0) (2017-04-27)
[Full Changelog](https://github.com/chef/inspec/compare/v1.21.0...v1.22.0)

## [v1.21.0](https://github.com/chef/inspec/tree/v1.21.0) (2017-04-24)
[Full Changelog](https://github.com/chef/inspec/compare/v1.20.0...v1.21.0)



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*