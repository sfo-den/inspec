class AwsIamRootUser < Inspec.resource(1)
  name 'aws_iam_root_user'
  desc 'Verifies settings for AWS root account'
  example "
    describe aws_iam_root_user do
      it { should have_access_key }
    end
  "
  supports platform: 'aws'

  # TODO: rewrite to avoid direct injection, match other resources, use AwsSingularResourceMixin
  def initialize(conn = nil)
    @client = conn ? conn.iam_client : inspec_runner.backend.aws_client(Aws::IAM::Client)
  end

  # TODO: DRY up, see https://github.com/chef/inspec/issues/2633
  # Copied from resource_support/aws/aws_resource_mixin.rb
  def catch_aws_errors
    yield
  rescue Aws::Errors::MissingCredentialsError
    # The AWS error here is unhelpful:
    # "unable to sign request without credentials set"
    Inspec::Log.error "It appears that you have not set your AWS credentials.  You may set them using environment variables, or using the 'aws://region/aws_credentials_profile' target.  See https://www.inspec.io/docs/reference/platforms for details."
    fail_resource('No AWS credentials available')
  rescue Aws::Errors::ServiceError => e
    fail_resource e.message
  end

  # TODO: DRY up, see https://github.com/chef/inspec/issues/2633
  # Copied from resource_support/aws/aws_singular_resource_mixin.rb
  def inspec_runner
    # When running under inspec-cli, we have an 'inspec' method that
    # returns the runner. When running under unit tests, we don't
    # have that, but we still have to call this to pass something
    # (nil is OK) to the backend.
    # TODO: remove with https://github.com/chef/inspec-aws/issues/216
    # TODO: remove after rewrite to include AwsSingularResource
    inspec if respond_to?(:inspec)
  end

  def has_access_key?
    summary_account['AccountAccessKeysPresent'] == 1
  end

  def has_mfa_enabled?
    summary_account['AccountMFAEnabled'] == 1
  end

  def to_s
    'AWS Root-User'
  end

  private

  def summary_account
    catch_aws_errors do
      @summary_account ||= @client.get_account_summary.summary_map
    end
  end
end
