#
# Cookbook Name:: hadoop_cluster
# Recipe::        hadoop_conf_xml
#

#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

class Chef::Recipe; include HadoopCluster ; end

#
# Generate Hadoop xml configuration files in $HADDOP_HOME/conf/
#

# create it in case it's not created, e.g. when this recipe is included by hbase recipes
# which only need the hadoop conf files rather than hadoop packages and conf files)
directory "/etc/hadoop/conf" do
  mode  "0755"
  recursive true
end

# hadoop-daemon.sh will read files in #{hadoop_home}/conf
make_link("#{hadoop_home_dir}/conf", "/etc/hadoop/conf")

template_variables = hadoop_template_variables
Chef::Log.debug template_variables.inspect

files = %w[core-site.xml hdfs-site.xml mapred-site.xml hadoop-env.sh
           log4j.properties fair-scheduler.xml capacity-scheduler.xml mapred-queue-acls.xml hadoop-metrics.properties raw_settings.yaml
           topology.data topology.sh]
files.each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode conf_file.end_with?('.sh') ? "0755" : "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end

template "/etc/default/#{node[:hadoop][:hadoop_handle]}" do
  owner "root"
  mode "0644"
  variables(template_variables)
  source "etc_default_hadoop.erb"
end

exclude_files = %w[mapred.hosts.exclude dfs.hosts.exclude]
exclude_files.each do |exclude_file|
  file "/etc/hadoop/conf/#{exclude_file}" do
    owner "root"
    mode "0644"
    action :create
  end
end

files = []
if node.role? "hadoop_namenode"
  template_variables[:monitor_namenode] = true
  files += %w[vm-namenode.xml]
end
if node.role? "hadoop_jobtracker"
  template_variables[:monitor_jobtracker] = true
  files += %w[vm-jobtracker.xml vsphere-ha-jobtracker-monitor.sh]
end
files.each do |monitor_conf_file|
  template "/usr/lib/hadoop/monitor/#{monitor_conf_file}" do
    owner "root"
    mode monitor_conf_file.end_with?('.sh') ? "0755" : "0644"
    variables(template_variables)
    source "#{monitor_conf_file}.erb"
    only_if "test -d /usr/lib/hadoop/monitor/"
  end
end
