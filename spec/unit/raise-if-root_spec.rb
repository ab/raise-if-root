RSpec.describe RaiseIfRoot do
  it 'should have a version number' do
    expect(RaiseIfRoot::VERSION).to be_a(String)
  end

  it 'raises if root' do
    expect(Process).to receive(:uid).and_return(0)

    expect {
      require 'raise-if-root'
    }.to raise_error(RaiseIfRoot::AssertionFailed, /\bUID is 0\z/)
  end
end
