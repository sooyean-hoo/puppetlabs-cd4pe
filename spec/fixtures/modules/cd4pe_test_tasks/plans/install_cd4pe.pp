plan cd4pe_test_tasks::install_cd4pe(
  TargetSpec $cd4pe_host,
  Optional[TargetSpec] $pe_host,
  Enum['installer_task', 'module'] $install_type,
  String[1] $version,
  Enum['DISK', 'S3', 'ARTIFACTORY'] $storage_provider,
  Optional[Enum['postgres', 'mysql']] $db_provider = undef,
  String[1] $secrets_path,
) {
  # This is absurd, but we need to do this in case TargetSpec is actually a String because it won't have the 'host' method defined
  $cd4pe_target_spec = get_targets($cd4pe_host)[0]
  $pe_target_spec = get_targets($pe_host)[0]
  notice($cd4pe_target_spec.host)
  run_task('pe_xl::agent_install', $cd4pe_target_spec,
    install_flags => [],
    server => $pe_target_spec.host,
    _catch_errors => true,
  )
  run_task('pe_xl::puppet_runonce', $cd4pe_target_spec, _catch_errors => true)
  case $storage_provider {
    'S3': {
      $s3_bucket = 'cd4pe-acceptance-tests'
      $aws_creds = cd4pe_test_tasks::get_aws_creds("${secrets_path}/cd4pe-acceptance-s3-creds.csv")
      $storage_endpoint = "s3.us-west-2.amazonaws.com/${s3_bucket}"
      $current_time = strftime('%s')
      # Set the s3 storage prefix to something unique but also useful
      $storage_prefix = "${cd4pe_target_spec.host}-${current_time}"
    }
    'DISK': {
      # Do nothing right now because it's the default for the module
    }
  }
  $cd4pe_image = 'pcr-internal.puppet.net/pipelines/pfi'
  #TODO: Note that the installer task doesn't support all the CD4PE settings that are passed in to this plan. We should probably log that whenever we can figure out how to fix logging.
  if ($install_type == 'installer_task') {
    $cd4pe_install_task_params = "master_host='${pe_target_spec.host}' cd4pe_admin_email='admin@example.com' cd4pe_admin_password='puppetlabs' cd4pe_image='${cd4pe_image}' cd4pe_version='${version}'"
    run_command("puppet task run pe_installer_cd4pe::install --nodes ${cd4pe_target_spec.host} ${cd4pe_install_task_params}", $pe_target_spec)
  } elsif $install_type == 'module' {

    # Terrible
    $cd4pe_target_spec.set_var('puppet_enterprise::params::ssl_dir', '/etc/puppetlabs/puppet/ssl')
    set_feature($cd4pe_target_spec, 'puppet-agent')
    run_plan('facts', nodes => $cd4pe_target_spec)
    add_facts($cd4pe_target_spec, { 'cd4pe_multimodule_packaging' => false })
    $cd4pe_resolvable_hostname = "http://${cd4pe_target_spec.host}"
    apply($cd4pe_target_spec) {
      class { 'cd4pe':
        cd4pe_image => $cd4pe_image,
        cd4pe_version => $version,
        db_provider => $db_provider,
        resolvable_hostname => $cd4pe_resolvable_hostname,
      }
  }
    #TODO: Write a function to block until the service comes up with some kind of timeout
    ctrl::sleep(60)
    notice("Storage prefix: ${storage_prefix}")
    $root_email = 'noreply@puppet.com'
    $root_password = 'puppetlabs'
    run_task('cd4pe::root_configuration', $cd4pe_target_spec,
      storage_provider => $storage_provider,
      storage_endpoint => $storage_endpoint,
      s3_access_key => $aws_creds['access_key_id'],
      s3_secret_key => $aws_creds['secret_access_key'],
      storage_bucket => $s3_bucket,
      storage_prefix => $storage_prefix,
      root_password => 'puppetlabs',
      root_email => 'noreply@puppet.com',

    )
    run_task('pe_xl::puppet_runonce', $cd4pe_target_spec, _catch_errors => true)
    notice("CD4PE Web URL: ${cd4pe_resolvable_hostname}:8080")
    notice("root user: ${root_email}")
    notice("root password: ${root_password}")
  }
}

