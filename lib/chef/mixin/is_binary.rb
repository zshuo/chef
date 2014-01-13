#
# Author:: Lamont Granquist <lamont@opscode.com>
# Copyright:: Copyright (c) 2011-2012 Opscode, Inc.
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
  module Mixin
    module IsBinary

      # Helper to determine if a file is binary or not.  Does a best guess.
      #
      # This will handle files that are in the ruby default_external encoding correctly (most likely UTF-8),
      # but if Chef is running UTF-8 and you feed this Shift_JIS or Latin-1 it will get it wrong.
      #
      # @param file [String] the pathname to the file
      # @param length [Integer] the number of bytes to read (defaults to 16384, 0 or nil will slurp the whole file)
      # @return [TrueClass, FalseClass] if the file is binary or not
      #
      def is_binary?(file, length = 16384)
        # now we just check for the entire string being printable chars + whitespace or not
        buf = read_buf(file, length)
        begin
          return buf !~ /\A[\s[:print:]]*\z/m
        rescue ArgumentError => e
          return true if e.message =~ /invalid byte sequence/
          raise
        end
      end

      def line_endings(file, length = 16384)
        line_endings = []
        buf = read_buf(file, length)
        # remove any truncated line endings at the end
        while buf[-1] =~ /[\r\n]/
          buf.chop!
        end
        line_endings << :windows if buf =~ /\r\n/m
        line_endings << :unix if buf =~ /\r(?!\n)/m
        line_endings
      end

      private

      def read_buf(file, length)
        if length.nil? || length == 0
          # if we slurp the whole thing to RAM then we get useful encoding on the string, so its simple
          buf = IO.read(file)
          buf = "" if buf.nil?
        else
          # binread gives us ASCII-8BIT and loses encoding obviously, but it truncates binary reads which we want
          buf = IO.binread(file, length)
          buf = "" if buf.nil?
          # ruby 1.8 folks with non-ASCII characters get hosed here.  you must upgrade to get encoding (WONTFIX).
          if Object.const_defined? :Encoding
            buffer_length = buf.length
            # then we just twiddle the encoding to the default external encoding (which will succeed but may not result in a valid string)
            buf.force_encoding(Encoding.default_external)
            # if we read the full buffer, then assume the last character was truncated and left up to 3 characters of garbage
            if length == buffer_length
              buf = buf[0..-3]
            end
          end
        end
        buf
      end
    end
  end
end

