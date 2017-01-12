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

    it 'runs "sidekiqctl quiet"' do
      expect(Open3).to receive(:capture3).with(
        'bundle', 'exec', 'sidekiqctl', 'quiet', match_path(root.join('tmp/pids/sidekiq.pid')),
        chdir: match_path(root)
      ).and_return(['', '', success])
      expect(subject).to receive(:running?).and_return(true)
      subject.quiet
    end

  end

  describe '#stop' do

    it 'runs "sidekiqctl stop"' do
      expect(Open3).to receive(:capture3).with(
        'bundle', 'exec', 'sidekiqctl', 'stop', match_path(root.join('tmp/pids/sidekiq.pid')),
        chdir: match_path(root)
      ).and_return(['', '', success])
      expect(subject).to receive(:running?).and_return(true)
      subject.stop
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

    it 'runs "sidekiq start"' do
      expect(Open3).to receive(:capture3).with(
        'bundle', 'exec', 'sidekiq',
        '--index', '0',
        '--environment', 'test',
        '--config', match_path(root.join('config', 'sidekiq.yml')),
        '--daemon',
        chdir: match_path(root)
      ) do
        create_pid_file
        ['', '', success]
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

end
