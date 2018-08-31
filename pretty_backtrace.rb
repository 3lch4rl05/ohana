# Original author: Kristopher Johnson
# https://gist.github.com/kristopherjohnson/e650487a5dc0ce9dd24ea2584db63e18

# Generate a backtrace string for given exception.
# Generated string is a series of lines, each beginning with a tab and "at ".
def pretty_backtrace(exception)
  "\tat #{exception.backtrace.join("\n\tat ")}"
end
