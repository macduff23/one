#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2002-2019, OpenNebula Project, OpenNebula Systems                #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

NODE_PATH = '/sys/bus/node/devices/'

# Print node information in OpenNebula Template format. Example:
#
# HUGEPAGE = [NODE_ID = "0", SIZE = "1048576", PAGES = "0", FREE = "0"]
# HUGEPAGE = [NODE_ID = "0", SIZE = "2048", PAGES = "0", FREE = "0"]
# CORE = [ NODE_ID = "0", ID = "0", CPUS = "0,2"]
# CORE = [ NODE_ID = "0", ID = "1", CPUS = "1,3"]
#
def node_to_template(node, nid)
    node_s = ''

    node.each do |k, v|
        case k
        when 'hugepages'
            v.each do |h|
                node_s << "HUGEPAGE = [ NODE_ID = \"#{nid}\","
                node_s << " SIZE = \"#{h['size']}\","
                node_s << " PAGES = \"#{h['nr']}\","
                node_s << " FREE = \"#{h['free']}\"]\n"
            end
        when 'cores'
            v.each do |c|
                node_s << "CORE = [ NODE_ID = \"#{nid}\","
                node_s << " ID = \"#{c['id']}\","
                node_s << " CPUS = \"#{c['cpus'].join(',')}\"]\n"
            end
        end
    end

    node_s
end

# ------------------------------------------------------------------------------
# Get information for each NUMA node.
# ------------------------------------------------------------------------------
nodes = {}

Dir.foreach(NODE_PATH) do |node|
    /node(?<node_id>\d+)/ =~ node
    next unless node_id

    # ----------------------------------------
    # hugepafes information
    # ----------------------------------------
    hp_path = "#{NODE_PATH}/#{node}/hugepages"

    nodes[node_id] = { 'hugepages' => [] }

    Dir.foreach(hp_path) do |hp|
        /hugepages-(?<hp_size>\d+)kB/ =~ hp
        next unless hp_size

        hp_sz_path = "#{hp_path}/#{hp}"
        free = nr = surplus = 0

        hp_info = { 'size' => hp_size }

        begin
        %w{free nr surplus}.each do |var|                                    
                eval("#{var} = File.read(\"#{hp_sz_path}/#{var}_hugepages\").chomp")
                hp_info["#{var}"] = eval("#{var}")                              
        end
        rescue
            next
        end

        nodes[node_id]['hugepages'] << hp_info
    end

    cpu_path = "#{NODE_PATH}/#{node}/"

    nodes[node_id]['cores'] = []
    cpu_visited = []

    Dir.foreach(cpu_path) do |cp|
        /cpu(?<cpu_id>\d+)/ =~ cp
        next unless cpu_id
        next if cpu_visited.include? cpu_id

        begin
            core_path = "#{cpu_path}/#{cp}/topology"

            siblings = File.read("#{core_path}/thread_siblings_list").chomp
            siblings = siblings.split(',')

            cpu_visited.concat(siblings)

            core_id = File.read("#{core_path}/core_id").chomp

            nodes[node_id]['cores'] << { 'id' => core_id, 'cpus' => siblings }

        rescue
            next
        end
    end
end

nodes_s = ''

nodes.each {|i, v| nodes_s << node_to_template(v, i) }

puts nodes_s