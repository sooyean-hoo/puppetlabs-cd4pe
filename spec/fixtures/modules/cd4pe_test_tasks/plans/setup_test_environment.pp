plan cd4pe_test_tasks::setup_test_environment(
  Enum['scale', 'acceptance'] $environment_type,
  Enum['installer_task', 'module'] $cd4pe_install_type,
  Enum['ci-ready', 's3'] $pe_source_provider,
  String[1] $pe_version,
  String[1] $cd4pe_version = 'latest',
  Optional[Enum['mysql', 'postgres']] $cd4pe_db_provider = 'postgres',
  Enum['DISK', 'S3', 'ARTIFACTORY'] $cd4pe_storage_provider = 'DISK',
) {
  # Is there a way to just get all tagets?
  $target = get_targets('ssh_nodes')
  $pe_host = $target[0]
  $console_password = 'puppetlabs'

  #TODO: Reference project root in a better way
  $pwd = system::env('PWD')
  $secrets_path = "${pwd}/spec/fixtures/secrets"

  if $environment_type == 'acceptance' {
    $r10k_private_key = '/etc/puppetlabs/r10k-github'
    $module_private_key = '/etc/puppetlabs/r10k-cd4pe-module'
    run_plan('cd4pe_test_tasks::install_pe_mono',
      console_password => $console_password,
      pe_host => $pe_host,
      pe_version =>  $pe_version,
      pe_source_provider => $pe_source_provider,
      r10k_remote => 'git@github.com:puppetlabs/cd4pe-acceptance-control-repo.git',
      git_settings => {
        'private-key' => $r10k_private_key,
        'repositories' => [
          {
             'remote' => 'git@github.com:puppetlabs/puppetlabs-cd4pe.git',
             'private-key' => $module_private_key,
          }
        ]
      }
    )

    upload_file("${secrets_path}/cd4pe-acceptance-control-repo", $r10k_private_key, $pe_host)
    upload_file("${secrets_path}/cd4pe-acceptance-module", $module_private_key, $pe_host)
    run_command("chown pe-puppet:pe-puppet ${r10k_private_key}", $pe_host, _catch_errors => true)
    run_command("chown pe-puppet:pe-puppet ${module_private_key}", $pe_host, _catch_errors => true)
    run_task('pe_xl::code_manager', $pe_host,
      'action' => 'deploy',
      'environment' => 'production'
    )
    # Set up the CD4PE host
    $cd4pe_host = $target[1]
    run_plan('cd4pe_test_tasks::install_cd4pe',
      install_type => $cd4pe_install_type,
      cd4pe_host => $cd4pe_host,
      pe_host => $pe_host,
      version => $cd4pe_version,
      db_provider => $cd4pe_db_provider,
      storage_provider => $cd4pe_storage_provider,
      secrets_path => $secrets_path,
      )

  } else {
    return "The 'scale' test environment has not been implemented yet."
  }
}
