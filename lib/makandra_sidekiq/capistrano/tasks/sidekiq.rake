namespace :sidekiq do

  def run_task(name)
    on roles :sidekiq do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "sidekiq:#{name}"
        end
      end
    end
  end

  desc 'Quiet sidekiq (stop processing new tasks)'
  task :quiet do
    run_task('quiet')
  end

  desc 'Stop sidekiq'
  task :stop do
    run_task('stop')
  end

  desc 'Start sidekiq'
  task :start do
    run_task('start')
  end

  desc 'Restart sidekiq'
  task :restart do
    run_task('restart')
  end
end

after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:updated', 'sidekiq:stop'
after 'deploy:reverted', 'sidekiq:stop'
after 'deploy:published', 'sidekiq:start'
