---
title: InSpec Reporters
---

# InSpec Reporters

Introduced in InSpec 1.51.6

InSpec allows you to output your test results to one or more reporters. You can configure the reporter(s) using either the `--json-config` option or the `--reporter` option. While you can configure multiple reporters to write to different files, only one reporter can output to the screen(stdout).

## Syntax

You can specify one or more reporters using the `--reporter` cli flag. You can also specify a output by appending a path separated by a colon.

Output json to screen.

```bash
inspec exec example_profile --reporter json
or
inspec exec example_profile --reporter json:-
```

Output yaml to screen

```bash
inspec exec example_profile --reporter yaml
or
inspec exec example_profile --reporter yaml:-
```

Output cli to screen and write json to a file.

```bash
inspec exec example_profile --reporter cli json:/tmp/output.json
```

Output nothing to screen and write junit and html to a file.

```bash
inspec exec example_profile --reporter junit:/tmp/junit.xml html:www/index.html
```

Output json to screen and write to a file. Write junit to a file.

```bash
inspec exec example_profile --reporter json junit:/tmp/junit.xml | tee out.json
```

If you wish to pass the profiles directly after specifying the reporters you will need to use the end of options flag `--`.

```bash
inspec exec --reporter json junit:/tmp/junit.xml -- profile1 profile2
```

If you are using the cli option `--json-config` you can also set reporters.

Output cli to screen.

```json
{
    "reporter": {
        "cli" : {
            "stdout" : true
        }
    }
}
```

Output cli to screen and write json to a file.

```json
{
    "reporter": {
        "cli" : {
            "stdout" : true
        },
        "json" : {
            "file" : "/tmp/output.json",
            "stdout" : false
        }
    }
}
```

## Supported Reporters

The following are the current supported reporters:

### cli

This is the basic text base report. It includes details about which tests passed and failed and includes an overall summary at the end.

### json

This reporter includes all information about the profiles and test results in standard json format.

### json-min

This reporter is a redacted version of the json and only includes test results.

### yaml

This reporter includes all information about the profiles and test results in standard yaml format.

### documentation

This reporter is a very minimal text base report. It shows you which tests passed by name and has a small summary at the end.

### junit

This reporter outputs the standard junit spec in xml format.

### progress

This reporter is very condensed and gives you a `.`(pass), `f`(fail), or `*`(skip) character per test and a small summary at the end.

### json-rspec

This reporter includes all information from the rspec runner. Unlike the json reporter this includes rspec specific details.

### html

This renders html code to view your tests in a browser. It includes all the test and summary information.

## Automate Reporter

The automate reporter type is a special reporter used with the Automate 2 suite. To use this reporter you must pass in the correct configuration via a json config `--json-config`.

Example config:

```json
"reporter": {
    "automate" : {
        "stdout" : false,
        "url" : "https://YOUR_A2_URL/data-collector/v0/",
        "token" : "YOUR_A2_ADMIN_TOKEN",
        "insecure" : true,
        "node_name" : "inspec_test_node",
        "environment" : "prod"
    }
}
```

### Mandatory fields

#### stdout

This will either suppress or show the automate report in the CLI screen on completion

#### url

This is your Automate 2 url. Append `data-collector/v0/` at the end.

#### token

This is your Automate 2 token. You can generate this token by navigating to the admin tab of A2 and then api keys.

### Optional fields

#### insecure

This will disable or enable the ssl check when accessing the Automate 2 instance.

PLEASE NOTE: These fields are ONLY needed if you do not have chef-client attached to a chef server running on your node. The fields below will be automatically pulled from the chef server.

#### node_name

This will be the node name which shows up in Automate 2.

#### node_uuid

This overrides the node uuid sent up to Automate 2. On non-chef nodes we will try to generate a static node uuid for you from your hardware. This will almost never be needed unless your working with a unique virtual setup.

#### environment

This will set the environment metadata for Automate 2.
