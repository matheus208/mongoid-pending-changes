# Mongoid::PendingChanges

[![Build Status](https://travis-ci.org/matheus208/mongoid-pending_changes.svg?branch=master)](https://travis-ci.org/matheus208/mongoid-pending_changes)

version 0.1.1

Mongoid::PendingChanges adds an option to keep further changes from modifying the record, pushing them to a changelist instead.

This is an initial effort to develop an approval system to control changes to collections. 

## Changelog

Version 0.1.1: Fixing a bug where data created before the gem inclusion would cause an exception due to missing fields.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid-pending_changes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid-pending_changes

## Usage

Add the following line to the models you want to track

```
class Model
    include Mongoid::PendingChanges
    
    field :example, type: String
end
```

Then, when you want to have changes that require approval, call

```
model.push_for_approval({example: 'new example value'})
```

Your model will keep the original value, but a new entry will be added to the `changelist` property, with all changes and an incrementing ID.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matheus208/mongoid-pending_changes.

## TODO list


