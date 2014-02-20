require 'spec_helper'

describe Bosh::Deployer::InstanceManager do
  describe '#create' do
    let(:config_hash) { { 'cloud' => { 'plugin' => 'fake-plugin' } } }
    let(:config) { instance_double('Bosh::Deployer::Configuration') }
    before do
      allow(Bosh::Deployer::Config).to receive(:configure).and_return(config)
    end

    it 'tries to require instance manager specific class' +
       '(this allows custom gems to specify instance manager plugin)' do
      described_class.should_receive(:require).with(
        'bosh/deployer/instance_manager/fake-plugin')
      allow(described_class).to receive(:new)
      described_class.create(config_hash)
    end

    it 'raises an error when requiring non-existent plugin' do
      expect {
        described_class.create(config_hash)
      }.to raise_error(
        Bosh::Cli::CliError,
        /Could not find Provider Plugin: fake-plugin/,
      )
    end

    it 'returns the plugin specific instance manager' do
      described_class.stub(:require)

      fingerprinter = instance_double('Bosh::Deployer::HashFingerprinter')
      Bosh::Deployer::HashFingerprinter
        .should_receive(:new)
        .and_return(fingerprinter)

      fingerprinter
        .should_receive(:sha1)
        .with(config_hash)
        .and_return('fake-config-hash-sha1')

      ui_messager = instance_double('Bosh::Deployer::UiMessager')
      Bosh::Deployer::UiMessager
        .should_receive(:for_deployer)
        .and_return(ui_messager)

      expect(Bosh::Deployer::Config).to receive(:configure).with(config_hash)

      allow(described_class).to receive(:new)

      described_class.create(config_hash)

      expect(described_class).to have_received(:new).
                                   with(config, 'fake-config-hash-sha1', ui_messager, 'fake-plugin')
    end
  end
end
