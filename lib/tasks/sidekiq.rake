require 'makandra_sidekiq/sidekiq_control'

namespace :sidekiq do

  def sidekiq_control
    root = Rake.application.original_dir
    @sidekiq_control ||= MakandraSidekiq::SidekiqControl.new(root)
  end

  desc 'Quiet sidekiq (stop processing new tasks)'
  task :quiet do
    sidekiq_control.quiet
  end

  desc 'Stop sidekiq'
  task :stop do
    sidekiq_control.stop
  end

  desc 'Start sidekiq'
  task :start do
    sidekiq_control.start
  end

  desc 'Restart sidekiq'
  task :restart do
    sidekiq_control.stop
    sidekiq_control.start
  end

end
