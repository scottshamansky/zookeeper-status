#!/usr/bin/env ruby
# zookeeper_status.rb

# Brandon Burton, 2014

# Where zookeeper lives
zookeeper_conf="/etc/zookeeper/zoo.properties"

# this assumes a hostname like 'lookout-zk-bburton-0', where the third bit is the "cluster name"
zookeeper_cluster_name=%x(hostname).split('-')[-2]

zookeeper_cluster_hosts = []
zookeeper_cluster_hosts=%x(grep server #{zookeeper_conf} | cut -d ':' -f 2 | cut -d ':' -f 1).split("\n")

def get_zookeeper_host_status(zookeeper_host)
  zookeeper_host_status = {}

  # get the zookeeper host's current state
  zookeeper_host_state_data=%x(echo ruok | nc #{zookeeper_host} 2181)
  # if the above did not return 'imok", we flag as failed
  if zookeeper_host_state_data != "imok"
   zookeeper_host_status["state"] = "FAILED"
  else
   zookeeper_host_status["state"] = "HEALTHY"
  end

  # get the zookeeper host's current role
  zookeeper_host_mode_data=%x(echo stat | nc #{zookeeper_host} 2181 | grep Mode | cut -d ':' -f 2)
  if zookeeper_host_mode_data == ""
    zookeeper_host_status["mode"] = "No Response"
  else
    zookeeper_host_status["mode"] = zookeeper_host_mode_data
  end

  # get the zookeeper host's serverID
  zookeeper_host_serverid_data=%x(echo conf | nc #{zookeeper_host} 2181 | grep serverId | cut -d '=' -f 2)
  if zookeeper_host_serverid_data == ""
    zookeeper_host_status["serverid"] = "No Response"
  else
    zookeeper_host_status["serverid"] = zookeeper_host_serverid_data
  end

  # get the zookeeper host's watches
  zookeeper_host_watches_data=%x(echo wchc | nc #{zookeeper_host} 2181).rstrip!.gsub(/\n/, "\n              ")
  if zookeeper_host_watches_data == ""
    zookeeper_host_status["watches"] = "(none)"
  else
    zookeeper_host_status["watches"] = zookeeper_host_watches_data
  end

  # return info about zookeeper host
  return zookeeper_host_status

end

puts "Zookeeper Cluster #{zookeeper_cluster_name} status:\n"
zookeeper_cluster_hosts.each do | zookeeper_host |
  zookeeper_host_status = get_zookeeper_host_status(zookeeper_host)
  puts "  #{zookeeper_host}:\n"
  serverid = zookeeper_host_status["serverid"]
  state = zookeeper_host_status["state"]
  mode = zookeeper_host_status["mode"]
  watches = zookeeper_host_status["watches"]
  puts "    ServerID: #{serverid}"
  puts "    State:    #{state}"
  puts "    Role:    #{mode}"
  puts "    Watches:  #{watches}"
  puts

end