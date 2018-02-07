---
title: About the aws_iam_role Resource
---

# aws_iam_role

Use the `aws_iam_role` InSpec audit resource to test properties of a single IAM Role.  A Role is a collection of permissions that may be temporarily assumed by a user, EC2 Instance, Lambda Function, or certain other resources.

<br>

## Syntax

  # Ensure that a certain role exists by name
  describe aws_iam_role('my-role') do
    it { should exist }
  end

## Resource Parameters

### role_name

This resource expects a single parameter that uniquely identifes the IAM Role, the Role Name.  You may pass it as a string, or as the value in a hash:

  describe aws_iam_role('my-role') do
    it { should exist }
  end
  # Same
  describe aws_iam_role(role_name: 'my-role') do
    it { should exist }
  end

## Matchers

### exist

Indicates that the Role Name provided was found.  Use should_not to test for IAM Roles that should not exist.

    describe aws_iam_role('should-be-there') do
      it { should exist }
    end

    describe aws_iam_role('should-not-be-there') do
      it { should_not exist }
    end

## Properties

### description

A textual description of the IAM Role.

    describe aws_iam_role('my-role') do
      its('description') { should be('Our most important Role')}
    end
