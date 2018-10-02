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
  # Class used to store util functions meant to be used throughout all Ohana.
  # @author Carlos Garcia Velasco <mail.charlitos@gmail.com>
  class OhanaUtils

    ##
    # Used to retrieve all the names of the 'fixed expenses' providers listed
    # in the app properties file. This function makes sure there are no
    # duplicates in the names list.
    #
    # @return [Hash] Map of maps that contains all the provider names.
    def self.providers_as_set
      prov_names_set = []
      OHANA.props['fe']['expenses'].each do |expense|
        expense[1]['provider']['names'].each do |name|
          prov_names_set.push(name)
        end
      end
      prov_names_set.uniq!
    end

    ##
    # Recursive function that performs a check on NaN values that could mean
    # something was wrong with the calculations performed.
    #
    # @param results [Object] Results object to search NaN values from.
    # @return [Boolean] true or false, depending on if there is a NaN value.
    def self.quick_nan_check(results)
      results.each do |result|
        if result.is_a?(Hash) || result.is_a?(Array)
          success = quick_nan_check(result)
          return success unless success
        elsif result.is_a?(Numeric)
          return !result.to_f.nan?
        end
      end
    end

  end

end
