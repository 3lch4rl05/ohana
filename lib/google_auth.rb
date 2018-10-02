# =========================================================================== #
# Ohana - Personal finances assistant.
# Copyright (C) 2018 Carlos Garcia Velasco

# This file is part of Ohana.

# Ohana is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# =========================================================================== #

# ! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ !#
# ! Portions of this code are modifications based on work created and shared by
# ! Google and used according to terms described in the Creative Commons 3.0
# ! Attribution License.
# !
# ! Origal source:
# ! https://developers.google.com/sheets/api/quickstart/ruby
# !
# ! Creative Commons 3.0 Attribution License:
# ! https://developers.google.com/terms/site-policies
# ! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ !#

require 'google/apis/sheets_v4'
require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Ohana'.freeze
CREDENTIALS_PATH = 'credentials.json'.freeze
TOKEN_PATH = 'token.yml'.freeze
SCOPE = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS,
         Google::Apis::GmailV1::AUTH_GMAIL_READONLY].freeze

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    system('open', url.to_s) # <- Works only in Mac OS X.
    puts '\nThis seems to be the first time you execute Ohana in this '\
         'computer. In order for Ohana to be able to perform its job, it '\
         'requires to get the necessary permissions to read/write some '\
         'information from your Google account. You only need to do '\
         'this one time.\n'
    puts '\nPlease follow the instructions in the new browser window to '\
         'grant Ohana access to your Google sheets and email. You can also '\
         'copy/paste the following URL in the browser window. Enter the '\
         'resulting code after authorization:\n\n'
    puts '-' * 132
    puts url
    puts '-' * 132
    print '\n\nEnter your code here: '
    code = STDIN.gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
    puts '\nThank you! Please enjoy Ohana.'
  end
  credentials
end
