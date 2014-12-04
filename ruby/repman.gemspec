Gem::Specification.new do |spec|
    spec.name                      = 'repman'
    spec.version                   = '2014.12.4'
    spec.license                   = 'GPLv2 or later'
    spec.author                    = 'Renato Silva'
    spec.email                     = 'br.renatosilva@gmail.com'
    spec.summary                   = 'Pacman repository manager'
    spec.homepage                  = 'https://github.com/renatosilva/repman'
    spec.files                     = ['lib/repman.rb']
    spec.executables               << 'repman'
    spec.add_runtime_dependency    'easyoptions', '>= 2014.12.2'
    spec.add_runtime_dependency    'inifile', '>= 3.0.0'
end
