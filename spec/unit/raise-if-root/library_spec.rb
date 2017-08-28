# NB: These tests cannot be run as root (uid 0 or gid 0), sorry.
RSpec.describe RaiseIfRoot do

  describe '.raise_if_root' do
    it 'should raise if uid is 0' do
      allow(Process).to receive(:uid).and_return(0)
      expect {
        RaiseIfRoot.raise_if_root
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bUID\b/)
    end
    it 'should raise if euid is 0' do
      allow(Process).to receive(:euid).and_return(0)
      expect {
        RaiseIfRoot.raise_if_root
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bEUID\b/)
    end
    it 'should raise if gid is 0' do
      allow(Process).to receive(:gid).and_return(0)
      expect {
        RaiseIfRoot.raise_if_root
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bGID\b/)
    end
    it 'should raise if egid is 0' do
      allow(Process).to receive(:egid).and_return(0)
      expect {
        RaiseIfRoot.raise_if_root
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bEGID\b/)
    end

    it 'should not raise otherwise' do
      expect(RaiseIfRoot.raise_if_root).to eq nil
    end

    it 'runs assertion callbacks' do
      allow(Process).to receive(:uid).and_return(0)
      expect(RaiseIfRoot).to receive(:run_assertion_callbacks).with(
        instance_of(RaiseIfRoot::AssertionFailed)
      ).once.and_call_original

      expect {
        RaiseIfRoot.raise_if_root
      }.to raise_error(RaiseIfRoot::AssertionFailed)
    end
  end

  describe '.add_assertion_callback' do
    before do
      RaiseIfRoot.assertion_callbacks.clear
    end
    after do
      RaiseIfRoot.assertion_callbacks.clear
    end

    it 'adds a callback' do
      expect(RaiseIfRoot.assertion_callbacks.length).to eq 0

      RaiseIfRoot.add_assertion_callback { :returnvalue }
      expect(RaiseIfRoot.assertion_callbacks.last).is_a?(Proc)
      expect(RaiseIfRoot.assertion_callbacks.length).to eq 1

      expect(RaiseIfRoot.run_assertion_callbacks(nil)).to eq([:returnvalue])
    end
  end

  describe '.run_assertion_callbacks' do
    before do
      RaiseIfRoot.assertion_callbacks.clear
    end
    after do
      RaiseIfRoot.assertion_callbacks.clear
    end

    it 'runs callbacks' do
      sentinel = double('Sentinel')
      expect(sentinel).to(receive(:callback).with(
        instance_of(RaiseIfRoot::AssertionFailed)
      ).twice.and_return(:callbackresponse1, :callbackresponse2))

      expect(RaiseIfRoot.assertion_callbacks.length).to eq 0

      RaiseIfRoot.add_assertion_callback { |err| sentinel.callback(err) }
      RaiseIfRoot.add_assertion_callback { |err| sentinel.callback(err) }

      expect(RaiseIfRoot.assertion_callbacks.length).to eq 2

      expect(RaiseIfRoot.run_assertion_callbacks(
        RaiseIfRoot::AssertionFailed.new
      )).to eq([:callbackresponse1, :callbackresponse2])
    end
  end

  describe '.raise_if' do
    before do
      allow(Process).to receive(:uid).and_return(5000)
      allow(Process).to receive(:euid).and_return(5000)

      allow(Process).to receive(:gid).and_return(5000)
      allow(Process).to receive(:egid).and_return(5000)

      @someuser = double('Etc::Passwd', name: 'someuser')
    end

    it 'does not raise by default' do
      expect(RaiseIfRoot.raise_if).to eq nil
      expect(RaiseIfRoot.raise_if(uid: 0)).to eq nil
      expect(RaiseIfRoot.raise_if(gid: 0)).to eq nil
      expect(RaiseIfRoot.raise_if(uid_not: 5000)).to eq nil
      expect(RaiseIfRoot.raise_if(gid_not: 5000)).to eq nil
      expect(RaiseIfRoot.raise_if(uid: 0, gid: 0)).to eq nil
    end

    it 'raises when any condition matches' do
      expect {
        RaiseIfRoot.raise_if(uid: 0, gid: 0, uid_not: 123, gid_not: 5000)
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bUID\b/)
      expect {
        RaiseIfRoot.raise_if(uid: 0, gid: 5000, uid_not: 5000, gid_not: 5000)
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bGID\b/)
      expect {
        RaiseIfRoot.raise_if(uid: 5000, gid: 0)
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\bUID\b/)
    end

    it 'handles username and not_username' do
      allow(Etc).to receive(:getpwuid).with(5000).and_return(@someuser)

      expect {
        RaiseIfRoot.raise_if(username: 'someuser')
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\busername\b/)

      expect(RaiseIfRoot.raise_if(username: 'other')).to eq nil

      expect {
        RaiseIfRoot.raise_if(username_not: 'other')
      }.to raise_error(RaiseIfRoot::AssertionFailed, /\busername\b/)

      expect(RaiseIfRoot.raise_if(username_not: 'someuser')).to eq nil
    end
  end
end
