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

require 'ohana/ohana_menu'
require 'ohana/ohana_ops'
require 'ohana/ohana_out'
require 'google_auth'
require 'yaml'

module OHANA

  ##
  # This class is responsible for initializing several parts required by Ohana
  # like the the logger, Google API services, etc.
  #
  # @author Carlos Garcia Velasco <mail.charlitos@gmail.com>
  class OhanaInit

    def init(args)
      puts "\n"
      OHANA.props = YAML.load_file('app_props.yml')
      OhanaOut.initialize_logger
      OhanaOut.print_init_msg('ohana')
      OhanaOut.print_notice
      OHANA.logger.level = Logger::DEBUG if args.key?('debug')

      begin
        initialize_google_services
        loop do
          OhanaMenu.display_main_menu
          break if OhanaMenu.option == 9

          case OhanaMenu.option
          when 1
            OhanaOps.estimate_fixed_expenses
          when 2
            OhanaOps.prepare_cc_for_month(OhanaMenu.curr_sel)
          end
        end
      rescue StandardError => e
        OhanaOut.print_error_msg_exc(e, 'Unexpected error ocurred.')
        exit
      end
    end

    def initialize_google_services
      # Initialize the sheets API
      ss = Google::Apis::SheetsV4::SheetsService.new
      ss.client_options.application_name = APPLICATION_NAME
      ss.authorization = authorize
      OHANA.ss_service = ss
      OHANA.logger.debug('Google Sheets service initialized.')

      # Initialize the gmail API
      # TODO: Initialize gmail API
      OHANA.logger.debug('Google Gmail service initialized.')
    end

  end

end
