#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Mark Mzyk (<mmzyk@opscode.com>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
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

require 'chef/log'
require 'chef-config/logger'

# DI our logger into ChefConfig before we load the config. Some defaults are
# auto-detected, and this emits log messages on some systems, all of which will
# occur at require-time. So we need to set the logger first.
ChefConfig.logger = Chef::Log

require 'chef-config/config'

require 'chef/platform/query_helpers'

class Chef
  Config = ChefConfig::Config

  # We re-open ChefConfig::Config to add additional settings. Generally,
  # everything should go in chef-config so it's shared with whoever uses that.
  # We make execeptions to that rule when:
  # * The functionality isn't likely to be useful outside of Chef
  # * The functionality makes use of a dependency we don't want to add to chef-config
  class Config

    default :event_loggers do
      evt_loggers = []
      if ChefConfig.windows? and not Chef::Platform.windows_server_2003?
        evt_loggers << :win_evt
      end
      evt_loggers
    end

  end
end
