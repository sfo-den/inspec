fixtures = {}
[
  'aws_iam_policy_alpha_name',
  'aws_iam_policy_beta_name',
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/iam.tf',
  )
end

control "aws_iam_policy recall" do
  describe aws_iam_policy("AWSSupportAccess") do
    it { should exist }
  end

  describe aws_iam_policy(policy_name: "AWSSupportAccess") do
    it { should exist }
  end

  describe aws_iam_policy(fixtures['aws_iam_policy_alpha_name']) do
    it { should exist }
  end
end

control "aws_iam_policy properties" do
  describe aws_iam_policy("AdministratorAccess") do
    its('arn') { should cmp "arn:aws:iam::aws:policy/AdministratorAccess" }
    its('default_version_id') { should cmp 'v1' }
    its('attachment_count') { should cmp 1 }
    its('attached_users') { should include "test-fixture-maker" }
    its('attached_groups') { should be_empty }
    its('attached_roles') { should be_empty }
  end

  describe aws_iam_policy(fixtures['aws_iam_policy_alpha_name']) do
    its('statement_count') { should cmp 2 }
    its('policy') { should be_kind_of(Hash) }
  end
end

control "aws_iam_policy matchers" do
  describe aws_iam_policy("AdministratorAccess") do
    it { should be_attached }
  end
  describe aws_iam_policy("AdministratorAccess") do
    it { should be_attached_to_user("test-fixture-maker") }
  end

  describe aws_iam_policy(fixtures['aws_iam_policy_alpha_name']) do
    it { should have_statement('Resource' => '*')}
    it { should have_statement('Resource' => '*', 'Sid' => 'alpha01')}
    it { should have_statement('Resource' => 'arn:aws:s3:::bobs-stuff', 'Sid' => 'alpha02')}

    it { should have_statement('Effect' => 'Allow', 'Sid' => 'alpha01')}
    it { should have_statement('Effect' => 'Deny', 'Sid' => 'alpha02')}

    it { should have_statement('Action' => 'ec2:Describe*', 'Sid' => 'alpha01')}
    it { should_not have_statement('Action' => 'ec2:Describe')}
    it { should have_statement('Action' => /^ec2:Describe\*$/, 'Sid' => 'alpha01')}
    it { should have_statement('Action' => /^ec2:.+$/, 'Sid' => 'alpha01')}

    it { should have_statement('Action' => 'ec2:Describe*', 'Resource' => '*', 'Effect' => 'Allow') }
    it { should_not have_statement('Action' => 'ec2:Describe*', 'Resource' => 'arn:aws:s3:::bobs-stuff') }
  end

  describe aws_iam_policy(fixtures['aws_iam_policy_beta_name']) do
    it { should have_statement('Action' => 'ec2:DescribeSubnets')}
    it { should have_statement('Action' => 'ec2:DescribeSecurityGroups')}
    # Array indicates all must match
    it { should_not have_statement('Action' => ['ec2:DescribeSecurityGroups'])}
    it { should have_statement('Action' => ['ec2:DescribeSubnets', 'ec2:DescribeSecurityGroups'])}
    it { should have_statement('Action' => ['ec2:DescribeSecurityGroups', 'ec2:DescribeSubnets'])}
    
    it { should have_statement('Resource' => 'arn:aws:ec2:::*')}
    it { should have_statement('Resource' => '*')}
    it { should_not have_statement('Resource' => ['*'])}    
    it { should have_statement('Resource' => ['arn:aws:ec2:::*', '*'])}
    it { should have_statement('Resource' => ['*', 'arn:aws:ec2:::*'])}
  end  
end