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

require_relative 'google_auth'
require_relative 'ohana_menu'
require_relative 'ohana_ops'
require_relative 'ohana_out'
require 'yaml'

module OHANA
  class OhanaInit

    def init(args)

      puts "\n"
      OhanaOut.initialize_logger()
      OhanaOut.print_section_header("Ohana v0.0.1")
      OhanaOut.print_notice()
      if args.key?('debug')
        $LOG.level = Logger::DEBUG
      end

      begin

        initialize_app_props()
        initialize_google_services()
        loop do
          OhanaMenu.main_menu()
          break if OhanaMenu.option == 9

          case OhanaMenu.option
          when 1
            OhanaOps.estimate_fixed_expenses()
          when 2
            OhanaOps.prepare_monthly_summary()
          end
        end

      rescue => e
        OhanaOut.print_error_msg_exc(e,"Unexpected error ocurred.")
        exit
      end
    end

    def initialize_app_props()
      $props = YAML.load_file('app_props.yaml')
      $LOG.debug("App properties loaded.")
    end

    def initialize_google_services()

      # Initialize the sheets API
      $sheetsService = Google::Apis::SheetsV4::SheetsService.new
      $sheetsService.client_options.application_name = APPLICATION_NAME
      $sheetsService.authorization = authorize
      $LOG.debug("Google Sheets service initialized.")

      # Initialize the gmail API
      # TODO: Initialize gmail API
      $LOG.debug("Google Gmail service initialized.")
      
    end
  end
end
