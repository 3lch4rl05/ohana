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
require 'ohana/ohana_menu'
require 'ohana/ohana_utils'
require 'ohana/ohana_google'
require 'fileutils'
require 'csv'

module OHANA

  ##
  # This class is responsible for all the operations required by the rest
  # of the Ohana module. All the calculations, reading files, etc., happens
  # in this class allowing other components to consume whatever these
  # operations might yield at the end.
  #
  # @author Carlos Garcia Velasco <mail.charlitos@gmail.com>
  class OhanaOps

    ##
    # This function is responsible for reading CSV files located inside
    # the reports folder for the bank and account specified. It cat detect
    # duplicates depending on the date, amount, description and the file where
    # the transactions comes from. It can also filter by date depending on the
    # starting date and end date specified as parameters. If +start_date+
    # is not provided, it will retrieve transactions from the earliest date in
    # the reports. If +end_date+ is not specified, it will use +Time.now+ as
    # the end limit.
    #
    # @param bank [String] Name of the bank where the reports come from.
    # @param acct [String] Name of the account for the specified bank.
    # @param start_date [Time] To filter by dates if necessary.
    # @param end_date [Time] To filter by dates if necessary.
    # @return [Hash] Map containing all the transactions obtained from reports.
    def self.get_transactions_for_acct(bank, acct, start_date = nil, end_date = Time.now)
      transactions = {}
      reports_folder = File.join(OHANA.props['reports']['path'], bank[0], "activity_#{acct}")
      print 'Analyzing data for account: '.brown
      print "#{bank[1]} (#{acct})"

      headers = OHANA.props['reports'][bank[0]][acct]['headers']
      date_format = headers['date']['format']
      date_col = headers['date']['column']
      desc_col = headers['description']['column']
      amnt_col = headers['amount']['column']

      Dir.glob(reports_folder + '/*.{csv,CSV}') do |report|
        file_name = File.basename(report)
        duplicates = 0
        print "\nInspecting file: ".brown
        print file_name.to_s
        puts "\n\nPossible duplicates found:"
        puts '-' * 30
        CSV.foreach(report, headers: true) do |row|
          trans_date = Date.strptime(row[date_col], date_format)
          trans_time = Time.new(trans_date.year, trans_date.month, trans_date.day)
          to_include = trans_time <=> end_date
          to_include = trans_time.between?(start_date, end_date) unless start_date.nil?

          if to_include

            row_data = {}
            row_data['date'] = trans_date
            row_data['desc'] = row[desc_col]
            row_data['amnt'] = row[amnt_col].to_f.abs

            # We use date, description, amount and a counter to build the
            # key name for every transaction added to the transactions map.
            row_key = "#{row[date_col]},#{row[desc_col]},#{row_data['amnt']}#?1"

            # If the key is present (not null) in transactions map, means that
            # there is another transaction with same date, description and
            # ammount in the map.
            if !transactions[row_key].nil?
              prev_row = transactions[row_key][1]
              formatted_amnt = OhanaOut.format_float(prev_row['amnt'])
              key_output = "#{prev_row['date']}  "\
                           "#{prev_row['desc'].ljust(55)} "\
                           "$#{formatted_amnt.to_s.rjust(10)}"
              print key_output

              # If we find a possible duplicate (same date, amount and description)
              # and it comes from a different CSV file, we don't add it to the
              # transactions map because it is more probable for it to be an
              # actual duplicate but from a different file.
              if transactions[row_key][0] != file_name
                puts '     SKIPPED'.red.ljust(22)
              else

                # If the duplicate comes from the same file, it is less probable
                # that it is an actual duplicate but a transaction that just
                # happens to occur twice. If it is in fact a duplicate, then it
                # means there is an issue with the file that the user needs to fix.
                new_key = row_key
                trans_null = transactions[new_key].nil?

                # To make sure we include all the transactions that occured
                # more than once at the same time, with same amount and same
                # description, we iterate through all these transactions using
                # the counter in the key of the transaction.
                until trans_null
                  splitted = new_key.split('#?')
                  counter = splitted[1].to_i + 1
                  new_key = splitted[0] + "#?#{counter}"
                  trans_null = transactions[new_key].nil?
                end

                # ... and when we find a counter value that has not been used
                # we create a new entry in the map for this transaction using
                # the new key.
                transactions[new_key] = []
                transactions[new_key][0] = file_name
                transactions[new_key][1] = row_data
                puts '     ADDED'.green.ljust(22)

              end
              duplicates += 1

            else
              transactions[row_key] = []
              transactions[row_key][0] = file_name
              transactions[row_key][1] = row_data
            end
          end
        end
        puts "#{duplicates} duplicates found.".red
      end
      puts "\n"
      transactions
    end

    ##
    # Used to calculate the estimates for every fixed expense category
    # specified in the app properties file under the 'fe' section. It first
    # obtains a list of all the transactions from the reports available in
    # the reports folder. After that, it tries to estimate what is the
    # amount spent monthly in average for every fixed expense specified.
    # Optionally, this function will also update a Google spreadsheet with
    # the calculated results.
    def self.estimate_fixed_expenses
      puts "\nEstimating fixed expenses...\n".cyan

      # First we create a map that will store all the totals for each provider
      # listed under the 'fe' section in the app properties file. This is a map
      # of maps using the name of the provider as the main key.
      totals_per_provider = {}
      prov_names_set = OhanaUtils.providers_as_set
      prov_names_set.each do |name|
        totals_per_provider[name] = {}
      end

      OHANA.props['banks'].each do |bank|
        OHANA.props['accounts'][bank[0]].each do |acct|
          # We get all the transactions for the bank and account specified.
          transactions = get_transactions_for_acct(bank, acct)
          transactions.each do |transaction_info|
            transaction = transaction_info[1][1]
            prov_names_set.each do |provider_name|
              # If the provider's name is in the transaction description, then
              # we add it to our map.
              next unless transaction['desc'].include?(provider_name)

              # We use "month-year" as key for the 'totals_per_provider' map
              # so we can group them depending on the month they occured.
              date_str = "#{transaction['date'].month}-#{transaction['date'].year}"

              # We add up all the expenses for that provider in each month.
              if totals_per_provider[provider_name][date_str].nil?
                totals_per_provider[provider_name][date_str] = transaction['amnt']
              else
                total_month = totals_per_provider[provider_name][date_str]
                totals_per_provider[provider_name][date_str] = total_month + transaction['amnt']
              end
            end
          end
        end
      end

      # The values per expense per provider per month are merged. This means
      # all of them are added up to calculate the month total for each
      # category expense.
      totals_per_expense = {}
      OHANA.props['fe']['expenses'].each do |expense|
        expense[1]['provider']['names'].each do |name|
          if totals_per_expense[expense[0]].nil?
            totals_per_expense[expense[0]] = totals_per_provider[name]
          else
            prev_hash = totals_per_expense[expense[0]]
            totals_per_expense[expense[0]] =
              prev_hash.merge(totals_per_provider[name]) { |_key, prev_val, new_val| new_val + prev_val }
          end
        end
      end

      # Once we have every month total calculated, we get the monthly average.
      totals_per_expense.each do |expense|
        total_expense = 0.0
        expense[1].each do |_date, total|
          total_expense += total.to_f
        end
        expense[1]['month_avg'] = total_expense / expense[1].length
      end

      # Now, we clean up the list based on joined bills to avoid dups.
      OHANA.props['fe']['joined_bills'].each do |joined|
        joined_aliases = []
        joined.each do |exp|
          exp_alias = OHANA.props['fe']['expenses'][exp]['alias']
          joined_aliases.push(exp_alias)
        end

        # We format the name of joined categories. It will include a plus sign '+'
        # between names so its easier to identify when categories were joined.
        joined_name = joined_aliases.join(' + ')
        totals_per_expense[joined_name] = totals_per_expense.delete(joined[0])
        (1..(joined.length - 1)).each do |num|
          totals_per_expense.delete(joined[num])
        end
      end

      # We perform a basic check of the results before presenting them to the
      # user just to make sure there are no NaN values in final results.
      if OhanaUtils.quick_nan_check(totals_per_expense)

        puts "\nOhana".cyan + " finished analyzing the bank reports provided.\n"\
             "These are the estimates based on the information available:\n\n"
        puts '-' * 33

        totals_per_expense.each do |expense|
          format_expense = OhanaOut.format_float(expense[1]['month_avg'])
          format_expense = format_expense.rjust(9)
          expense_info = OHANA.props['fe']['expenses'][expense[0]]
          if !expense_info.nil?
            expense_alias = expense_info['alias']
            puts "- #{expense_alias.ljust(18)} $" + format_expense.to_s.brown
          else
            puts "- #{expense[0].ljust(18)} $" + format_expense.to_s.brown
          end
        end
        puts '-' * 33
        puts "\n"

        # Now, we ask the user if he would like to update the spreadsheet with
        # the calculated data.
        update_gss_fixed_expenses(totals_per_expense) if OhanaMenu.confirm_sheet_modif == 'Y'

      else

        puts "\n\nSeems that some of the results were not calculated successfully :(".red
        print 'Please make sure folder contains ' + 'valid reports and valid data'.cyan
        puts ".\n"

      end
    end

    ##
    # This function allows Ohana to update the desired spreadsheet with the
    # freshly calculated fixed expenses estimation data. For this, we use the
    # ranges specified in the app properties file to determine where to inject
    # this information.
    #
    # @param totals_per_expense [Hash] Map with the calculated fixed expenses estimations.
    # @see https://stackoverflow.com/a/14091786
    #   Original author of scan regex: sawa
    def self.update_gss_fixed_expenses(totals_per_expense)
      home_finances = OHANA.props['google']['spread_sheets']['home_finances']
      reseg_sheet = home_finances['sheets']['resumen_egresos']
      range_for_names = reseg_sheet['ranges']['fe']['names']

      # We need to obtain the names of the expenses from the spreadsheet to
      # match them against the ones present in the app properties file. This
      # is for the joined bills compound names and not for the single fixed
      # expense provider names. For the latter, the appropiate cell to be
      # modified is already specified under the 'google' section in the
      # properties file.
      exp_names = OhanaGoogleSheets.read_cell_values(home_finances['id'],
                                                     "#{reseg_sheet['name']}!#{range_for_names}")

      # We iterate the data to get the calculated estimate for each expense
      # type. For every different type of expense, Ohana will get its
      # respective cell from application properties file.
      totals_per_expense.each do |expense|
        exp_cell = reseg_sheet['ranges']['fe'][expense[0]]
        month_avg = expense[1]['month_avg']
        val_array = []
        values = []
        values[0] = month_avg
        val_array[0] = values

        # For the 'joined-bills' calculated estimates, this code will try to
        # discover which one is the correct cell to update matching the alias
        # with whatever is in the name's colum.
        if exp_cell.nil?
          cell_count = -1
          expense_alias = expense[0]
          exp_names.each do |name|
            cell_count += 1
            break if name[0] == expense_alias
          end

          # First we obtain the specified range for the names column. We then
          # split it to get the starting cell, we separate the columns from the
          # row numbers with the regex.
          first_in_range_info = range_for_names.split(':')[0].scan(/\d+|\D+/)
          desired_col = first_in_range_info[0].next!
          desired_row = first_in_range_info[1].to_i + cell_count
          exp_cell = "#{desired_col}#{desired_row}"
        end

        OhanaGoogleSheets.write_cell_values(home_finances['id'],
                                            "#{reseg_sheet['name']}!#{exp_cell}",
                                            val_array)
      end
      puts 'Done!'
    end

    ##
    # This function is intended to execute all the steps necessary to prepare
    # the credit cards summary (specified under the 'accounts' section in the
    # app properties file). Can also (optionally) be set up to update
    # a Google spreadsheet with the calculated results.
    #
    # @param month [Integer] The month we want the summary prepared for.
    def self.prepare_cc_for_month(month = Date.today.strftime('%B'))
      puts "Preparing details for credit cards for month: #{month}...\n"
    end

  end

end
