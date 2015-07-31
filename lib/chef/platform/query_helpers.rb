#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Platform

    class << self
      def windows?
        ChefConfig.windows?
      end

      def windows_server_2003?
        # WMI startup shouldn't be performed unless we're on Windows.
        return false unless windows?
        require 'wmi-lite/wmi'

        wmi = WmiLite::Wmi.new
        host = wmi.first_of('Win32_OperatingSystem')
        is_server_2003 = (host['version'] && host['version'].start_with?("5.2"))

        is_server_2003
      end

      def supports_powershell_execution_bypass?(node)
        node[:languages] && node[:languages][:powershell] &&
          node[:languages][:powershell][:version].to_i >= 3
      end

      def supports_dsc?(node)
        node[:languages] && node[:languages][:powershell] &&
          node[:languages][:powershell][:version].to_i >= 4
      end

      def supports_dsc_invoke_resource?(node)
        require 'rubygems'
        supports_dsc?(node) &&
          Gem::Version.new(node[:languages][:powershell][:version]) >=
            Gem::Version.new("5.0.10018.0")
      end
    end
  end
end
