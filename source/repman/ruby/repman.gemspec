Gem::Specification.new do |spec|
    spec.name                      = 'repman'
    spec.version                   = '16.1.0'
    spec.license                   = 'BSD'
    spec.author                    = 'Renato Silva'
    spec.email                     = 'br.renatosilva@gmail.com'
    spec.summary                   = 'Pacman repository manager'
    spec.homepage                  = 'https://github.com/renatosilva/repman'
    spec.files                     = ['lib/repman.rb']
    spec.executables               << 'repman'
    spec.add_runtime_dependency    'easyoptions'
    spec.add_runtime_dependency    'inifile', '>= 3.0.0'
end
