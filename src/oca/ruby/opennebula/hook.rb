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

require 'opennebula/pool_element'

module OpenNebula

    # Class for representing a Hook object.
    class Hook < PoolElement

        #######################################################################
        # Constants and Class Methods
        #######################################################################
        HOOK_METHODS = {
            :allocate => 'hook.allocate',
            :delete   => 'hook.delete',
            :update   => 'hook.update',
            :rename   => 'hook.rename',
            :info     => 'hook.info',
            :lock     => 'hook.lock',
            :unlock   => 'hook.unlock',
        }

        # Creates a Hook description with just its identifier
        # this method should be used to create plain Hook objects.
        # +id+ the id of the user
        #
        # Example:
        #   hook = Hook.new(Hook.build_xml(3),rpc_client)
        #
        def self.build_xml(pe_id = nil)
            if pe_id
                obj_xml = "<HOOK><ID>#{pe_id}</ID></HOOK>"
            else
                obj_xml = '<HOOK></HOOK>'
            end

            XMLElement.build_xml(obj_xml, 'HOOK')
        end

        # Class constructor
        def initialize(xml, client)
            super(xml, client)

            @client = client
        end

        #######################################################################
        # XML-RPC Methods for the Template Object
        #######################################################################

        # Retrieves the information of the given Hook.
        def info
            return Error.new('ID not defined') unless @pe_id

            rc = @client.call(HOOK_METHODS[:info], @pe_id, false)

            if !OpenNebula.is_error?(rc)
                initialize_xml(rc, 'HOOK')
                rc = nil

                @pe_id = self['ID'].to_i if self['ID']
                @name  = self['NAME'] if self['NAME']
            end

            rc
        end

        alias :info! info

        # Allocates a new Hook in OpenNebula
        #
        # @param template [String] The contents of the Hook template.
        #
        # @return [nil, OpenNebula::Error] nil in case of success, Error
        #   otherwise
        def allocate(template)
            super(HOOK_METHODS[:allocate], template)
        end

        # Deletes the Hook
        #
        # @return [nil, OpenNebula::Error] nil in case of success, Error
        #   otherwise
        def delete
            call(HOOK_METHODS[:delete], @pe_id, false)
        end

        # Replaces the Hook contents
        #
        # @param new_template [String] New Hook contents
        # @param append [true, false] True to append new attributes instead of
        #   replace the whole template
        #
        # @return [nil, OpenNebula::Error] nil in case of success, Error
        #   otherwise
        def update(new_template, append = false)
            super(HOOK_METHODS[:update], new_template, append ? 1 : 0)
        end

        # Renames this Hook
        #
        # @param name [String] New name for the Hook.
        #
        # @return [nil, OpenNebula::Error] nil in case of success, Error
        #   otherwise
        def rename(name)
            call(HOOK_METHODS[:rename], @pe_id, name)
        end

        #######################################################################
        # Helpers to get Hook information
        #######################################################################

        # Returns the group identifier
        # [return] _Integer_ the element's group ID
        def gid
            self['GID'].to_i
        end

        def owner_id
            self['UID'].to_i
        end

        # Lock a Hook
        def lock(level)
            call(HOOK_METHODS[:lock], @pe_id, level)
        end

        # Unlock a Hook
        def unlock
            call(HOOK_METHODS[:unlock], @pe_id)
        end

    end

end