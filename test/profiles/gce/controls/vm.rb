# frozen_string_literal: true

control 'status' do
  title 'Verify BIG-IP Next VMs are running'
  impact 1.0
  self_links = input('output_self_links')

  self_links.each do |url|
    params = url.match(%r{/projects/(?<project>[^/]+)/zones/(?<zone>[^/]+)/instances/(?<name>.+)$}).named_captures
    describe google_compute_instance(project: params['project'], zone: params['zone'], name: params['name']) do
      it { should exist }
      its('status') { should cmp 'RUNNING' }
    end
  end
end
