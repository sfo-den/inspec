---
title: About the aws_iam_policies Resource
platform: aws
---

# aws_iam_policies

Use the `aws_iam_policies` InSpec audit resource to test properties of some or all AWS IAM Policies.

An AWS IAM policy attaches to an identity or resource, defining their permissions. AWS evaluates these policies when a principal, such as a user, makes a request. Permissions defined in the identity or resource policies determines whether the request is allowed or denied.

Each IAM Policy is uniquely identified by either its policy_name or arn.

<br>

## Syntax

An `aws_iam_policies` resource block collects a group of IAM Policies and then tests that group.

    # Verify the policy specified by the policy name is included in IAM Policies in the AWS account.
    describe aws_iam_policies do
      its('policy_names') { should include('test-policy-1') }
    end

<br>

## Examples

The following examples show how to use this InSpec audit resource.

As this is the initial release of `aws_iam_policies`, its limited functionality precludes examples.

<br>

## Properties

* `arns`, `entries`, `policy_names`

<br>

## Examples

### policy_names

Provides a list of policy names for all IAM Policies in the AWS account.

    describe aws_iam_policies do
      its('policy_names') { should include('test-policy-1') }
    end

### arns

Provides a list of policy arns for all IAM Policies in the AWS account.

    describe aws_iam_policies do
      its('arns') { should include('arn:aws:iam::aws:policy/test-policy-1') }
    end

### entries

Provides access to the raw results of the query.  This can be useful for checking counts and other advanced operations.

    # Allow at most 100 IAM Policies on the account
    describe aws_iam_policies do
      its('entries.count') { should be <= 100}
    end

<br>

## Matchers

For a full list of available matchers please visit our [matchers page](https://www.inspec.io/docs/reference/matchers/). 

### exists

The control will pass if the filter returns at least one result. Use should_not if you expect zero matches.

    # Verify that at least one IAM Policies exists.
    describe aws_iam_policies
      it { should exist }
    end   

