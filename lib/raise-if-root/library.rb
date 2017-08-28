require 'etc'

require_relative './version'

module RaiseIfRoot
  # Error class for RaiseIfRoot assertion failures. Inherits directly from
  # Exception because we don't want a bare rescue to catch this.
  # rubocop:disable Lint/InheritException
  class AssertionFailed < Exception; end

  # Raise if the process UID/EUID is 0 or if the process GID/EGID is 0.
  #
  # @raise [AssertionFailed] if running as root
  #
  def self.raise_if_root
    raise_if(uid: 0, gid: 0)
  end

  # Raise if the process UID or EUID equals +uid+.
  #
  # @param uid [Integer]
  #
  # @raise [AssertionFailed]
  #
  # @see .raise_if
  #
  def self.raise_if_uid(uid)
    raise_if(uid: uid)
  end

  # Raise AssertionFailed if any of the specified conditions are met. This is
  # the primary method powering RaiseIfRoot.
  #
  # @param uid [Integer] Raise if the process UID or EUID matches
  # @param gid [Integer] Raise if the process GID or EGID matches
  #
  # @param uid_not [Integer] Raise if the process UID or EUID does not match
  #   the provided value
  # @param gid_not [Integer] Raise if the process GID or EGID does not match
  #   the provided value
  #
  # @param username [String] Raise if the username of the process UID or EUID
  #   matches the provided value
  # @param username_not [String] Raise if the username of the process UID or
  #   EUID does not match the provided value
  #
  # @raise [AssertionFailed] if any of the conditions match.
  #
  # rubocop:disable Metrics/ParameterLists
  def self.raise_if(uid: nil, gid: nil, uid_not: nil, gid_not: nil,
                    username: nil, username_not: nil)
    if uid
      assert_not_equal('UID', Process.uid, uid)
      assert_not_equal('EUID', Process.euid, uid)
    end

    if gid
      assert_not_equal('GID', Process.gid, gid)
      assert_not_equal('EGID', Process.egid, gid)
    end

    if uid_not
      assert_equal('UID', Process.uid, uid_not)
      assert_equal('EUID', Process.euid, uid_not)
    end

    if gid_not
      assert_equal('GID', Process.gid, gid_not)
      assert_equal('EGID', Process.egid, gid_not)
    end

    # raise if username
    if username
      assert_not_equal('username', Etc.getpwuid(Process.uid).name, username)
      assert_not_equal('effective username', Etc.getpwuid(Process.euid).name,
                       username)
    end

    # raise unless username is username_not
    if username_not
      assert_equal('username', Etc.getpwuid(Process.uid).name, username_not)
      assert_equal('effective username', Etc.getpwuid(Process.euid).name,
                   username_not)
    end
  end

  # Assert that two values are equal. If they are not, run assertion callbacks
  # and raise AssertionFailed.
  #
  # @param label [String] The label for the comparison we're making
  # @param actual The actual value
  # @param expected The expected value
  #
  # @raise [AssertionFailed] if the values are not equal
  #
  def self.assert_equal(label, actual, expected)
    if expected.nil?
      warn('warning: RaiseIfRoot.assert_equal called with expected=nil')
    end
    if actual != expected
      err = new_assertion_failed(label, actual, expected)
      run_assertion_callbacks(err)
      raise err
    end
  end

  # Assert that two values are not equal. But if they are equal, run assertion
  # callbacks and raise AssertionFailed.
  #
  # @param label [String] The label for the comparison we're making
  # @param actual The actual value
  # @param expected The expected value
  #
  # @raise [AssertionFailed] if the values are equal
  #
  def self.assert_not_equal(label, actual, expected)
    if actual == expected
      err = new_assertion_failed(label, actual)
      run_assertion_callbacks(err)
      raise err
    end
  end

  # Create a new AssertionFailed object.
  #
  # @param label [String] The label for the comparison we're making
  # @param actual The actual value
  # @param expected The expected value, if any
  #
  # @return [AssertionFailed]
  #
  def self.new_assertion_failed(label, actual, expected=nil)
    # rubocop:disable Style/SpecialGlobalVars
    message = "Process[#{$$}] #{label} is #{actual.inspect}"
    if expected
      message << ", expected #{expected.inspect}"
    end

    AssertionFailed.new(message)
  end

  # Add a callback to the list of assertion callbacks that are executed when an
  # assertion fails. The callback will be passed one argument: the
  # AssertionFailed exception object just before it is raised.
  def self.add_assertion_callback(&block)
    raise ArgumentError.new("Must pass block") unless block

    assertion_callbacks << block
  end

  # The list of stored assertion callbacks. These are executed when an
  # assertion fails just before the assertion is raised.
  #
  # @return [Array<Proc>]
  #
  def self.assertion_callbacks
    @assertion_callbacks ||= []
  end

  # Execute all of the stored assertion callbacks.
  #
  # @param [AssertionFailed] err The exception object to pass to each callback.
  #
  # @return [Array] The collected return values of the callbacks.
  #
  def self.run_assertion_callbacks(err)
    assertion_callbacks.map { |block| block.call(err) }
  end
end
