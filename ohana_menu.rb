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

require_relative 'ohana_out'
require 'fileutils'

module OHANA
  class OhanaMenu

    def self.main_menu()
      puts "\nPlease, select an option to proceed:\n".magenta.underline
      puts "1. Automatic fixed expenses estimation."
      puts "2. Prepare monthly expenses summary."
      puts "9. Exit\n\n"

      loop do
        print "Selection: ".green
        @@option = STDIN.gets
        @@option = @@option.strip!
        @@option = @@option.to_i
        break if @@option >= 1 && @@option <=9
        print "Incorrect selection, please try again.\n\n".red
      end

      if @@option == 1
        start_01()
      elsif @@option == 2
        start_02()
      end
    end

    def self.start_01()
      puts "\n\nOhana will try to estimate your fixed expenses based on "\
           "bank reports downloaded in the folder you specify.\n\n"

      loop do
        print "Bank reports location: ".green
        $reports_folder = STDIN.gets
        $reports_folder = $reports_folder.strip!
        break if Dir.exist?($reports_folder)
        print "That folder does not exist, please specify it again.\n\n".red
      end

    end

    def self.start_02()
      month = Date.today.strftime("%B")
      puts "\n\nOhana will now prepare the monthly expenses summary for #{month} "\
           "based on bank statements located in the folder specified.\n\n"
      print "Bank statements location: "
      $reports_folder = STDIN.gets
      $reports_folder = $reports_folder.strip!
    end

    def self.confirm_sheet_modif()
      print "Update your spreadsheet".cyan + " with these values? " + "(y/n): ".green
      conf_val = STDIN.gets
      conf_val.chomp!
      conf_val = "Y" if conf_val.nil? || conf_val.empty?
      conf_val.upcase
    end

    def self.option
      @@option
    end
  end
end
