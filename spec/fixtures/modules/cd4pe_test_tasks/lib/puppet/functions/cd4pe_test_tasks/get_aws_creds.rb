require 'csv'

Puppet::Functions.create_function(:'cd4pe_test_tasks::get_aws_creds') do
  dispatch :get_aws_creds do
    param 'String[1]', :file
  end

  def get_aws_creds(file)
    aws_creds = CSV.read(file)
    return {
        'access_key_id' => aws_creds[1][2],
        'secret_access_key' => aws_creds[1][3],
    }
  end
end