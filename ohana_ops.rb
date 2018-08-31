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

require_relative 'logging'
require 'fileutils'
require 'csv'

module OHANA
  class OhanaOps

    # To
    def self.get_transactions_from_csv(folder)

    end

    def self.estimate_fixed_expenses()

      puts "\nEstimating fixed expenses..."
      @@totals_per_provider = Hash.new
      prov_names_set = Array.new

      $props["fe"]["expenses"].each do |expense|
        expense[1]["provider"]["names"].each do |name|
          prov_names_set.push(name)
        end
      end
      prov_names_set.uniq!
      prov_names_set.each do |name|
        @@totals_per_provider[name] = Hash.new
      end

      # We iterate every bank,
      $props["banks"].each do |bank|
        bank_reports_folder = File.join($reports_folder,bank[0])

        # ... every account,
        $props["accounts"][bank[0]].each do |account|
          puts "Analyzing data for account: #{bank[1]} (#{account})"

          activity_folder = "activity_#{account}"
          acct_reports_folder = File.join(bank_reports_folder,activity_folder)
          $LOG.debug("Reports path: '...#{bank[0]}/#{activity_folder}'")

          date_col = $props["reports"][bank[0]][account]["headers"]["date"]["column"]
          date_format = $props["reports"][bank[0]][account]["headers"]["date"]["format"]
          desc_col = $props["reports"][bank[0]][account]["headers"]["description"]["column"]
          amount_col = $props["reports"][bank[0]][account]["headers"]["amount"]["column"]

          # ... every report (for that account),
          Dir.glob(acct_reports_folder+"/*.{csv,CSV}") do |report|

            # ... and every row (for that report),
            CSV.foreach(report) do |row|

              # ... to look for every provider name
              prov_names_set.each do |provider_name|

                # ... that appears in the description column of the report
                if row[desc_col].include? provider_name

                  trans_date = Date.strptime(row[date_col], date_format)
                  date_str = "#{trans_date.month}-#{trans_date.year}"

                  # ... so we can add up all the expenses for that provider in each month
                  if @@totals_per_provider[provider_name][date_str].nil?
                    @@totals_per_provider[provider_name][date_str] = row[amount_col].to_f.abs
                  else
                    total_month = @@totals_per_provider[provider_name][date_str]
                    @@totals_per_provider[provider_name][date_str] = total_month + row[amount_col].to_f.abs
                  end

                end
              end
            end
          end
        end
      end

      # the values per expense per provider per month are merged.
      @@totals_per_expense = Hash.new
      $props["fe"]["expenses"].each do |expense|
        expense[1]["provider"]["names"].each do |name|
          if @@totals_per_expense[expense[0]].nil?
            @@totals_per_expense[expense[0]] = @@totals_per_provider[name]
          else
            prev_hash = @@totals_per_expense[expense[0]]
            @@totals_per_expense[expense[0]] =
                prev_hash.merge(@@totals_per_provider[name]) {
                  |key, prev_val, new_val| new_val + prev_val
                }
          end
        end
      end

      # once we have every month total calculated, we obtain the monthly average
      @@totals_per_expense.each do |expense|
        total_expense = 0.0
        expense[1].each do |date,total|
          total_expense = total_expense + total.to_f
        end
        expense[1]["month_avg"]=total_expense/expense[1].length
      end

      # now, we try to clean up the list based on joined bills to avoid dups
      $props["fe"]["joined_bills"].each do |joined|
        joined_aliases = Array.new
        joined.each do |exp|
          exp_alias = $props["fe"]["expenses"][exp]["alias"]
          joined_aliases.push(exp_alias)
        end

        joined_name = joined_aliases.join(" + ")
        @@totals_per_expense[joined_name] = @@totals_per_expense.delete(joined[0])
        (1..(joined.length-1)).each do |num|
          @@totals_per_expense.delete(joined[num])
        end
      end

      puts "\nOhana finished analyzing the bank reports provided.\n" \
           "These are the estimates based on the information available :\n\n"

      puts "-"*30

      @@totals_per_expense.each do |expense|
        format_expense = '%.2f' % expense[1]['month_avg']
        format_expense = format_expense.rjust(8)
        expense_info = $props["fe"]["expenses"][expense[0]]
        if(!expense_info.nil?)
          expense_alias = expense_info["alias"]
          puts "#{expense_alias.ljust(18)} $#{format_expense}\n"
        elsif
          puts "#{expense[0].ljust(18)} $#{format_expense}\n"
        end

      end
      puts "-"*30

    end

    def self.prepare_monthly_summary()

      puts "\nPreparing monthly summary..."


    end

  end
end
