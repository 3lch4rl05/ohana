Gem::Specification.new do |s|
  s.name        = 'ohana'
  s.version     = '0.1.1'
  s.date        = '2018-09-01'
  s.summary     = 'Personal finances assistant.'
  s.description = 'Meant for the personal and private use by individuals or '\
                  'families to help them manage their home finances.'
  s.authors     = ['Carlos Garcia Velasco']
  s.email       = 'mail.charlitos@gmail.com'
  s.files       = ['lib/ohana/ohana_google.rb', 'lib/ohana/ohana_init.rb',
                   'lib/ohana/ohana_menu.rb', 'lib/ohana/ohana_utils.rb',
                   'lib/ohana/ohana_ops.rb', 'lib/ohana/ohana_out.rb',
                   'lib/google_auth.rb', 'lib/pretty_backtrace.rb']
  s.executables = ['ohana']
  s.add_development_dependency 'rake', '>= 12.3.1'
  s.add_development_dependency 'rubocup', '>= 0.59.2'
end
