require 'makandra_sidekiq/sidekiq_control'

describe MakandraSidekiq::SidekiqControl do

  let(:root) { Pathname.new(File.expand_path('../fixtures/root', __dir__)) }
  let(:success) { instance_double(Process::Status, success?: true) }

  matcher :match_path do |expected|
    match do |actual|
      expand(actual) == expand(expected)
    end

    description do
      "be the same path as #{expected}"
    end

    failure_message do |actual|
      "expected #{actual} to be the same path as #{expected}"
    end

    failure_message_when_negated do |actual|
      "expected #{actual} not to be the same path as #{expected}"
    end

    def expand(path)
      Pathname.new(path).expand_path
    end
  end

  subject do
    control = described_class.new(root)
    allow(control).to receive(:puts)
    control
  end

  describe '#config validation' do
    let(:root) { Pathname.new(File.expand_path('../fixtures/root_with_empty_config', __dir__)) }

    it 'complains about missing config values' do
      expect {
        described_class.new(root)
      }.to raise_error(/does not set a :pidfile.*does not set a :logfile/m)
    end
  end

  describe '#quiet' do
    before do
      expect(subject).to receive(:running?).and_return(true)
    end

    it 'runs "sidekiqctl quiet" in a new environment' do
      expect(subject).to receive(:without_bundler_env).and_yield do |scope|
        expect(scope).to receive(:capture3).with(
          'bundle', 'exec', 'sidekiqctl', 'quiet', match_path(root.join('tmp/pids/sidekiq.pid')),
          chdir: match_path(root)
        ).and_return(['', '', success])
      end

      subject.quiet
    end
  end

  describe '#stop' do
    before do
      expect(subject).to receive(:running?).and_return(true)
    end

    it 'runs "sidekiqctl stop" in a new environment' do
      timeout = 32
      expect(subject).to receive(:without_bundler_env).and_yield do |scope|
        expect(scope).to receive(:capture3).with(
          'bundle', 'exec', 'sidekiqctl', 'stop', match_path(root.join('tmp/pids/sidekiq.pid')), timeout.to_s,
          chdir: match_path(root)
        ).and_return(['', '', success])
      end

      subject.stop
    end

    context 'when no timeout is configured' do
      let(:root) { Pathname.new(File.expand_path('../fixtures/root_without_timeout', __dir__)) }

      it 'uses Sidekiq’s default timeout' do
        timeout = 10
        expect(Open3).to receive(:capture3).with(
          'bundle', 'exec', 'sidekiqctl', 'stop', match_path(root.join('tmp/pids/sidekiq.pid')), timeout.to_s,
          chdir: match_path(root)
        ).and_return(['', '', success])

        subject.stop
      end
    end
  end

  describe '#start' do
    let(:pidfile) { root.join('tmp', 'pids', 'sidekiq.pid') }

    before do
      allow(subject).to receive(:sleep)
    end

    after do
      pidfile.delete if pidfile.file?
    end

    def create_pid_file(pid = $$)
      pidfile.parent.mkpath
      File.open(root.join('tmp', 'pids', 'sidekiq.pid'), 'w') do |f|
        f.print(pid)
      end
    end

    it 'runs "sidekiq start" in a new environment' do
      expect(subject).to receive(:without_bundler_env).and_yield do |scope|
        expect(scope).to receive(:capture3).with(
          'bundle', 'exec', 'sidekiq',
          '--index', '0',
          '--environment', 'test',
          '--config', match_path(root.join('config', 'sidekiq.yml')),
          '--daemon',
          '-r', 'boot.rb',
          chdir: match_path(root)
        ) do
          create_pid_file
          ['', '', success]
        end
      end
      subject.start
    end

    it 'uses the given RAILS_ENV' do
      begin
        old_env = ENV['RAILS_ENV']
        ENV['RAILS_ENV'] = 'rails_env'
        expect(Open3).to receive(:capture3) do |*arguments|
          expect(arguments).to include('rails_env')
          create_pid_file
          ['', '', success]
        end
        subject.start
      ensure
        ENV['RAILS_ENV'] = old_env
      end
    end

    it 'retries a few times if sidekiq crashes' do
      count = 0
      expect(Open3).to receive(:capture3).exactly(5).times do
        count += 1
        create_pid_file(count == 5 ? $$ : 1234567890)
        ['', '', success]
      end
      subject.start
    end

    it 'fails if sidekiq keeps crashing' do
      expect(Open3).to receive(:capture3).exactly(5).times do
        create_pid_file(1234567890)
        ['', '', success]
      end
      expect {
        subject.start
      }.to raise_error(/failed to start/)
    end
  end

  describe '#without_bundler_env' do
    it 'discards a surrounding bundler environment' do
      block = Proc.new {}
      mock_bundler = double
      stub_const('Bundler', mock_bundler)

      expect(Bundler).to receive(:with_original_env) { |&given_block| expect(given_block).to eq(block) }
      subject.send(:without_bundler_env, &block)
    end

    it 'uses Bundler.with_clean_env on older versions of Bundler' do
      block = Proc.new {}
      mock_bundler = double
      stub_const('Bundler', mock_bundler)

      expect(Bundler).to receive(:with_clean_env) { |&given_block| expect(given_block).to eq(block) }
      subject.send(:without_bundler_env, &block)
    end
  end

  describe '#capture3' do
    it 'delegates to Open3.capture3' do
      expect(Open3).to receive(:capture3).with('my', 'command', { my_options: 'here' })
      subject.send(:capture3, 'my', 'command', { my_options: 'here' })
    end
  end

end
