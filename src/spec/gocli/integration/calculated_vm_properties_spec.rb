require_relative '../spec_helper'

describe 'calculated vm properties', type: :integration do
  with_reset_sandbox_before_each

  let(:vm_requirements) {
    {
      'cpu' => 2,
      'ram' => 1024,
      'ephemeral_disk_size' => 10
    }
  }

  let(:cloud_config_without_vm_types) do
    cloud_config = Bosh::Spec::Deployments.simple_cloud_config
    cloud_config.delete('resource_pools')
    cloud_config.delete('vm_types')
    cloud_config['compilation']['vm'] = vm_requirements
    cloud_config
  end

  let(:deployment_manifest_with_vm_block) do
    {
      'name' => 'simple',
      'director_uuid'  => 'deadbeef',

      'releases' => [{
        'name'    => 'bosh-release',
        'version' => '0.1-dev',
      }],

      'instance_groups' => [
        {
          'name' => 'dummy',
          'instances' => 1,
          'vm' => vm_requirements,
          'jobs' => [{'name'=> 'foobar', 'release' => 'bosh-release'}],
          'stemcell' => 'default',
          'networks' => [
            {
              'name' => 'a',
              'static_ips' => ['192.168.1.10']
            }
          ]
        }
      ],

      'stemcells' => [
        {
          'alias' => 'default',
          'os' => 'toronto-os',
          'version' => '1',
        }
      ],

      'update' => {
        'canaries'          => 2,
        'canary_watch_time' => 4000,
        'max_in_flight'     => 1,
        'update_watch_time' => 20
      }
    }
  end

  before do
    create_and_upload_test_release
    upload_stemcell
    upload_cloud_config(cloud_config_hash: cloud_config_without_vm_types)
    deploy_simple_manifest(manifest_hash: deployment_manifest_with_vm_block)
  end

  it 'deploys vms with size calculated from vm block' do
    invocations = current_sandbox.cpi.invocations

    expect(invocations.select {|inv| inv.method_name == 'calculate_vm_cloud_properties'}.count).to eq(1)

    expect(invocations[2].method_name).to eq('calculate_vm_cloud_properties')
    expect(invocations[2].inputs['vm_requirements']).to eq(deployment_manifest_with_vm_block['instance_groups'][0]['vm'])

    invocations.select {|inv| inv.method_name == 'create_vm'}.each do |inv|
      expect(inv.inputs['cloud_properties']).to eq({"instance_type"=>"dummy", "ephemeral_disk"=>{"size"=>10}})
    end
  end

  context 'when deploying again without changes' do
    it 'uses the CPI again to calculate the vm cloud properties' do
      deploy_simple_manifest(manifest_hash: deployment_manifest_with_vm_block)

      invocations = current_sandbox.cpi.invocations

      expect(invocations.select {|inv| inv.method_name == 'calculate_vm_cloud_properties'}.count).to eq(2)
      expect(invocations.select {|inv| inv.method_name == 'create_vm'}.count).to eq(3)
    end
  end

  context 'when deploying again with changes to the vm requirements' do
    it 'uses the CPI again to calculate the vm cloud properties' do
      vm_requirements['ephemeral_disk_size'] = 20
      deploy_simple_manifest(manifest_hash: deployment_manifest_with_vm_block)

      invocations = current_sandbox.cpi.invocations

      expect(invocations.select {|inv| inv.method_name == 'calculate_vm_cloud_properties'}.count).to eq(2)
      expect(invocations.select {|inv| inv.method_name == 'create_vm'}.count).to eq(4)
    end
  end

end