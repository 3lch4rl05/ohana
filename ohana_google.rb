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

module OHANA

  ##
  # This class is responsible for all the interactions with Google Sheets API.
  # The main purpose of this class is to contain all the operations needed
  # to read/update/delete information to/from Google sheets.
  #
  # @author Carlos Garcia Velasco <mail.charlitos@gmail.com>
  class OhanaGoogleSheets

    ##
    # This function allows to read data from a specific range from the
    # specified Google sheeet.
    #
    # @param spreadsheet_id [String] The ID of the spreadsheet we want to read from.
    # @param range [String] The cells range we want to read data from.
    # @return [Array] Array of arrays containing the table with the data that was read.
    def self.read_cell_values(spreadsheet_id, range)

      $LOG.debug("Reading sheet ID: '#{spreadsheet_id}', range: #{range}")
      response = $sheetsService.get_spreadsheet_values(spreadsheet_id, range)
      response.values

    end

    def self.write_cell_values(spreadsheet_id, range, values)

      value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: range, values: values)
      result = $sheetsService.update_spreadsheet_value(spreadsheet_id,
        range, value_range_object, value_input_option: "RAW")

    end
  end
end
