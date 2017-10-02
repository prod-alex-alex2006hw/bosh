module Bosh::Director
  module DeploymentPlan
    class VmRequirementsCache
      def initialize(cloud_factory)
        @cloud_factory = cloud_factory
        @cached_cloud_properties = {}
      end

      def get_vm_cloud_properties(az, vm_requirements_hash)
        cpi_name = @cloud_factory.get_name_for_az(az)

        if @cached_cloud_properties[{cpi_name => vm_requirements_hash}].nil?
          cpi = @cloud_factory.get(cpi_name)
          @cached_cloud_properties[{cpi_name => vm_requirements_hash}] = cpi.calculate_vm_cloud_properties(vm_requirements_hash)
        end

        @cached_cloud_properties[{cpi_name => vm_requirements_hash}]
      end
    end
  end
end