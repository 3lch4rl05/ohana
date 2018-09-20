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

# Created to give logging util methods to Ohana. Contains frequently used
# logging methods to facilitate and standarize the output when printing to the
# terminal.
#
# @author Carlos Garcia Velasco <mail.charlitos@gmail.com>
# @version 1.0

require_relative 'pretty_backtrace'
require 'logger'

$LOG = Logger.new(STDOUT)
$LOG.level = Logger::INFO
$LOG.formatter = proc { |severity, datetime, progname, msg|
  callerinfo = caller[4]
  callerinfo = callerinfo.split('/').last
  callerinfo = callerinfo.split(':')[0, 2].join(':')
  date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
  if severity == "INFO"
    "#{date_format} " + "#{severity}".green + "  [@#{callerinfo}] - #{msg}\n".bold
  elsif severity == "WARN"
    "#{date_format} " + "#{severity}".brown + "  [@#{callerinfo}] - #{msg}\n".bold
  elsif severity == "ERROR"
    "#{date_format} " + "#{severity}".red + " [@#{callerinfo}] - #{msg}\n".bold
  elsif severity == "DEBUG"
    "#{date_format} " + "#{severity}".magenta + " [@#{callerinfo}] - #{msg}\n".bold
  end
}

# Prints a standard init message block with gem name and version details.
def print_init_msg(gem_name)
  gem_version = Gem.loaded_specs[gem_name].version
  puts "\n\n"
  puts "  #{gem_name} v#{gem_version}  ".bold.cyan.center(120,"*")
  puts "\n"
end

# Prints default disclaimer notice
def print_notice()
  puts "Ohana Copyright (C) 2018 Carlos Garcia Velasco\n".bold.underline
  print "This is free software and it comes with "
  print "ABSOLUTELY NO WARRANTY".red
  print ". You are welcome to redistribute it under certain conditions; "\
       "Please refer to the GNU General Public License. It should be included "\
       "with this software, if not, see "
  puts "https://www.gnu.org/licenses/".cyan
end

# Prints a header-like block to visually separate specific log sections.
def print_section_header(title)
  puts "=".cyan*132
  puts "::: #{title} :::".center(132,' ')
  puts "=".cyan*132
end

# Prints an error message that doesn't come from an exception.
def print_error_msg(msg)
  puts "\n"
  puts " ERROR ".red.center(100,'#')
  puts "\n"
  $LOG.error(msg.red)
  puts "\n"
  puts " ERROR END ".red.center(100,'#')
end

# Prints a standard error message.
# It requires the exception and the custom message we want to print.
def print_error_msg_exc(e,msg)
  puts "\n"
  puts " ERROR ".red.center(100,'#')
  puts "\n"
  $LOG.error(msg.red)
  $LOG.error("Original message: #{ e.message }".red)
  puts "\n[exception backtrace]:\n\n#{pretty_backtrace(e)}\n\n"
  puts " ERROR END ".red.center(100,'#')
end

# Formats a floating number accordingly so it can be printed as: '***,***.**'
def format_float(amnt)
  formatted_amnt = '%.2f' % amnt
  formatted_amnt = formatted_amnt.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
end

at_exit do
  puts "\nFinishing execution...\n\n".italic
end

# Color definitions if ANSI color is supported. (Unix only)
# @see https://stackoverflow.com/a/16363159
#   Original author: Ivan Black
class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end
