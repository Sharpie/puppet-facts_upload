step 'Test Puppet Facts upload' do
  on(hosts, puppet('facts', 'upload'))
end
