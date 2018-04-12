fixtures = {}
[
  'vpc_default_vpc_id',
  'vpc_default_cidr_block',
  'vpc_default_dhcp_options_id',  
  'vpc_non_default_id',
  'vpc_non_default_cidr_block',
  'vpc_non_default_instance_tenancy',
  'vpc_non_default_dhcp_options_id',    
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/ec2.tf',
  )
end

control "aws_vpcs recall" do
    describe aws_vpcs do
      it { should exist }
      its('vpc_ids') { should include fixtures['vpc_default_vpc_id'] }
      its('vpc_ids') { should include fixtures['vpc_non_default_vpc_id'] }
      its('entries.count') { should cmp 2 }
    end
end

control "aws_vpcs filtering" do
  describe aws_vpcs.where { cidr_block.starts_with? '179'} do
    its('vpc_ids.first') { should cmp fixtures['vpc_non_default_vpc_id'] }
  end

  describe aws_vpcs.where { dhcp_option_set_id == fixtures['vpc_default_dhcp_option_set_id']} do
    its('vpc_ids') { should include fixtures['vpc_default_vpc_id']}
  end
end

control "aws_vpcs properties" do
  describe aws_vpcs do
    its('vpc_ids') { should include fixtures['vpc_default_vpc_id'] }
    its('vpc_ids') { should include fixtures['vpc_non_default_vpc_id'] }
    its('cidr_blocks') { should include fixtures['vpc_default_cidr_block']}
    its('cidr_blocks') { should include fixtures['vpc_non_default_cidr_block']}
    its('dhcp_option_set_ids') { should include fixtures['vpc_default_dhcp_option_set_id']}
    its('dhcp_option_set_ids') { should include fixtures['vpc_non_default_dhcp_option_set_id']} 
  end
end
