require 'spec_helper'

module Bosh::Director
  describe Api::DeploymentManager do
    let(:deployment) { Models::Deployment.make(name: 'DEPLOYMENT_NAME') }
    let(:task) { double('Task') }
    let(:username) { 'FAKE_USER' }
    let(:options) { {foo: 'bar'} }

    before do
      Bosh::Director::Models::DirectorAttribute.make(name: 'uuid', value: 'fake-director-uuid')
      allow(Config).to receive(:base_dir).and_return('/tmp')
    end

    describe '#create_deployment' do
      let(:runtime_configs) { [Models::Config.make(type: 'runtime'), Models::Config.make(type: 'runtime')] }

      it 'enqueues a DJ job' do
        cloud_configs = [Models::Config.make(:cloud)]

        create_task = subject.create_deployment(username, 'manifest', cloud_configs, runtime_configs, deployment, options)

        expect(create_task.description).to eq('create deployment')
        expect(create_task.deployment_name).to eq('DEPLOYMENT_NAME')
        expect(create_task.context_id).to eq('')
      end

      it 'passes empty cloud config id array and an empty runtime config id array if there are no cloud configs or runtime configs' do
        expect(JobQueue).to receive_message_chain(:new, :enqueue) do |_, job_class, _, params, _|
          expect(job_class).to eq(Jobs::UpdateDeployment)
          expect(params).to eq(['manifest', [], [], options])
        end

        subject.create_deployment(username, 'manifest', [], [], deployment, options)
      end

      it 'passes context id' do
        cloud_configs = [Models::Config.make(:cloud)]
        context_id = 'example-context-id'
        create_task = subject.create_deployment(username, 'manifest', cloud_configs, runtime_configs, deployment, options, context_id)

        expect(create_task.context_id).to eq context_id
      end
    end

    describe '#delete_deployment' do
      it 'enqueues a DJ job' do
        delete_task = subject.delete_deployment(username, deployment, options)

        expect(delete_task.description).to eq('delete deployment DEPLOYMENT_NAME')
        expect(delete_task.deployment_name).to eq('DEPLOYMENT_NAME')
      end

      it 'passes context id' do
        context_id = 'example-context-id'
        delete_task = subject.delete_deployment(username, deployment, options, context_id)
        expect(delete_task.context_id).to eq context_id
      end
    end

    describe '#find_by_name' do
      it 'finds a deployment by name' do
        expect(subject.find_by_name(deployment.name)).to eq deployment
      end
    end
  end
end
