# frozen_string_literal: true

control 'os-name' do
  title 'Verify BIG-IP Next operating system'
  impact 0.8
  describe os.name do
    it { should eq 'ubuntu' }
  end
end

control 'test-file' do
  title 'Verify existence of test files'
  impact 0.5
  verify_files = input('input_verify_files', value: '[]').gsub(/(?:[\[\]]|\\?")/, '').gsub(', ', ',').split(',')

  only_if('test case is not expected to create files through cloud-init') do
    !verify_files.empty?
  end

  verify_files.each do |f|
    describe file(f) do
      it { should exist }
    end
  end
end
