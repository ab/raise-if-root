# Raise If Root

[![Gem Version](https://badge.fury.io/rb/raise-if-root.svg)](https://rubygems.org/gems/raise-if-root)
[![Build status](https://travis-ci.org/ab/raise-if-root.svg)](https://travis-ci.org/ab/raise-if-root)
[![Code Climate](https://codeclimate.com/github/ab/raise-if-root.svg)](https://codeclimate.com/github/ab/raise-if-root)
[![Inline Docs](http://inch-ci.org/github/ab/raise-if-root.svg?branch=master)](http://www.rubydoc.info/github/ab/raise-if-root/master)

*Raise If Root* is a small gem that helps prevent your application from ever
running as the root user (uid 0).

## Why?

Many software systems rely on user privilege separation for security reasons.
Especially within containers or chroots, running as a non-privileged user gives
stronger isolation.

*Raise If Root* helps enforce that you never inadvertently load your
application code as root.

Will it protect you if your attacker is already running as root? Probably not.
But it does help remove opportunities for error, where you might accidentally
run root rake tasks, cron jobs, or deploy scripts.

## Usage

Add the gem to your application's Gemfile:

```ruby
gem 'raise-if-root', '~> 0'
```

Require it from your main application code:

```ruby
require 'raise-if-root'
```

There is no step three! This will raise `RaiseIfRoot::AssertionFailed` if the
current uid is 0.

### More complex patterns

See the [YARD documentation](http://www.rubydoc.info/github/ab/raise-if-root/master).

If you want to enforce that the application is running as a particular user,
there are several more specific functions available.

Load the library, which doesn't immediately raise when you load it.

```ruby
# load the library, which doesn't raise
require 'raise-if-root/library'

# raise if running as uid 1000
RaiseIfRoot.raise_if_uid(1000)

# raise unless user is nobody
RaiseIfRoot.raise_if(username_not: 'nobody')

# raise with multiple conditions
RaiseIfRoot.raise_if(uid_not: 1000, gid_not: 500)
```

### Notification callbacks

If you want to sound the alarm with something more than just the exception, you
can add callbacks to send emails, smoke signals, etc.

```ruby
# load the library, which doesn't raise
require 'raise-if-root/library'

RaiseIfRoot.add_assertion_callback do |err|
  Mail.deliver do
    from    'system@example.com'
    to      'alerts@example.com'
    subject 'App was run as root'
    body    "RaiseIfRoot is raising an exception:\n  #{err.inspect}\n"
  end
end

# ensure we're not root
RaiseIfRoot.raise_if_root
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
