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

require 'ohana/ohana_out'
require 'fileutils'

module OHANA

  ##
  # This class is responsible for all the menu interactions with the user.
  # It is responsible for displaying all the proper menu options and for
  # reading/validating all the user's input.
  #
  # @author Carlos Garcia Velasco <mail.charlitos@gmail.com>
  class OhanaMenu

    class << self

      attr_accessor :option

    end

    def self.display_main_menu
      puts "\nPlease, select an option to proceed:\n".magenta.underline
      puts '1. Automatic fixed expenses estimation.'
      puts '2. Prepare monthly expenses summary.'
      puts "9. Exit\n\n"

      loop do
        print 'Selection: '.green
        OhanaMenu.option = STDIN.gets
        OhanaMenu.option = OhanaMenu.option.strip!.to_i
        break if OhanaMenu.option >= 1 && OhanaMenu.option <= 9

        print "Incorrect selection, please try again.\n\n".red
      end

      if OhanaMenu.option == 1
        start_01
      elsif OhanaMenu.option == 2
        start_02
      end
    end

    def self.start_01
      puts "\n\nOhana will now try to estimate your fixed expenses based on "\
           "bank reports located in the reports folder.\n\n"

      print 'Press any key to continue...'.green
      STDIN.gets
    end

    def self.start_02
      month = Date.today.strftime('%B')
      puts "\n\nOhana will now prepare the monthly expenses summary for #{month} "\
           "based on bank reports located in the reports folder.\n\n"
    end

    def self.confirm_sheet_modif
      print 'Update your spreadsheet'.cyan + ' with these values? ' + '(y/n): '.green
      conf_val = STDIN.gets
      conf_val.chomp!
      conf_val = 'Y' if conf_val.nil? || conf_val.empty?
      conf_val.upcase
    end

  end

end
