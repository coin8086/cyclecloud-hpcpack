include_recipe "hpcpack::_get_secrets"

bootstrap_dir = node['cyclecloud']['bootstrap']

cookbook_file "#{bootstrap_dir}\\unzip.ps1" do
  source "unzip.ps1"
  action :create
end

reboot 'Restart Computer' do
    action :nothing
end

# KB3134758 should be superceded by WMF 5.1 which is pre-installed
# jetpack_download "Win8.1AndW2K12R2-KB3134758-x64.msu" do
#   project "hpcpack"
#   not_if { ::File.exists?("#{node['jetpack']['downloads']}/Win8.1AndW2K12R2-KB3134758-x64.msu") }
# end

# msu_package 'Install WMF Update KB3134758' do
#   source "#{node['jetpack']['downloads']}/Win8.1AndW2K12R2-KB3134758-x64.msu"
#   action :install
# end

powershell_script "Install NuGet" do
    code "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
    only_if "!(Get-PackageProvider NuGet -ListAvailable)"
end

powershell_script "enable wsman" do
    code 'winrm quickconfig -quiet'
    not_if 'Test-WSMan -ComputerName localhost'
end

jetpack_download node['hpcpack']['cert']['filename'] do
  project "hpcpack"
  not_if { ::File.exists?("#{node['jetpack']['downloads']}/#{node['hpcpack']['cert']['filename']}") }
end

log "Installing hpc comm cert with pass :  [#{node['hpcpack']['cert']['password']}]..." do level :warn end
powershell_script 'install hpc comm cert' do
    code <<-EOH
    $secpasswd = ConvertTo-SecureString '#{node['hpcpack']['cert']['password']}' -AsPlainText -Force
    Get-ChildItem -Path #{node['jetpack']['downloads']}\\#{node['hpcpack']['cert']['filename']} | Import-PfxCertificate -CertStoreLocation Cert:\\localmachine\\My -Exportable -Password $secpasswd
    EOH
end

if node['hpcpack']['install_logviewer']
  jetpack_download "LogViewer1.2.2.4.zip" do
    project "hpcpack"
  end

  powershell_script 'unzip-LogViewer' do
    code "#{bootstrap_dir}\\unzip.ps1 #{node['jetpack']['downloads']}\\LogViewer1.2.2.4.zip #{bootstrap_dir}"
    creates "#{bootstrap_dir}\\LogViewer1.2.2.4"
  end
end

