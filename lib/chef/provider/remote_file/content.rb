#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'rest_client'
require 'uri'
require 'tempfile'
require 'chef/file_content_management/content_base'

class Chef
  class Provider
    class RemoteFile
      class Content < Chef::FileContentManagement::ContentBase

        attr_accessor :raw_file

        include Chef::Mixin::Checksum

        private

        def downloaded_checksum
          @downloaded_checksum ||= checksum(raw_file.path)
        end

        def file_for_provider
          Chef::Log.debug("#{@new_resource} checking for changes")

          if current_resource_matches_target_checksum?
            Chef::Log.debug("#{@new_resource} checksum matches target checksum (#{@new_resource.checksum}) - not updating")
          else
            sources = @new_resource.source
            try_multiple_sources(sources)
            if raw_file && @new_resource.checksum && downloaded_checksum !=  @new_resource.checksum
              raise Chef::Exceptions::RemoteFileChecksumMismatch.new(downloaded_checksum, @new_resource.checksum)
            end
          end
          raw_file
        end

        # Given an array of source uris, iterate through them until one does not fail
        def try_multiple_sources(sources)
          sources = sources.dup
          source = sources.shift
          begin
            uri = URI.parse(source)
            grab_file_from_uri(uri)
          rescue SocketError, Errno::ECONNREFUSED, Errno::ENOENT, Errno::EACCES, Timeout::Error, Net::HTTPFatalError, Net::FTPError => e
            Chef::Log.warn("#{@new_resource} cannot be downloaded from #{source}: #{e.to_s}")
            if source = sources.shift
              Chef::Log.info("#{@new_resource} trying to download from another mirror")
              retry
            else
              raise e
            end
          end
        end

        # Given a source uri, return a Tempfile, or a File that acts like a Tempfile (close! method)
        def grab_file_from_uri(uri)
          self.raw_file = Chef::Provider::RemoteFile::Fetcher.for_resource(uri, @new_resource, @current_resource).fetch
        end

        def current_resource_matches_target_checksum?
          @new_resource.checksum && @current_resource.checksum && @current_resource.checksum =~ /^#{Regexp.escape(@new_resource.checksum)}/
        end

      end
    end
  end
end
