# Fixturama

[![Gem Version](https://badge.fury.io/rb/fixturama.svg)][gem]
[![Build Status](https://travis-ci.org/nepalez/fixturama.svg?branch=master)][travis]

Collection of helpers for dealing with fixtures in RSpec

## Installation

```ruby
gem "fixturama"
```

## Usage

```ruby
# spec/spec_helper.rb
require "fixturama/rspec"
```

The gem defines 3 helpers (support ERB bindings):

- `load_fixture(path, **opts)` to load data from a fixture, and deserialize YAML and JSON
- `seed_fixture(path_to_yaml, **opts)` to prepare database
- `stub_fixture(path_to_yaml, **opts)` to stub some classes

```ruby
# spec/models/user/_spec.rb
RSpec.describe "GraphQL mutation 'deleteProfile'" do
  subject { Schema.execute(mutation).to_h }

  before do
    seed_fixture("#{__dir__}/database.yml", profile_id: 42)
    stub_fixture("#{__dir__}/stubs.yml",    profile_id: 42)
  end

  let(:mutation) { load_fixture "#{__dir__}/mutation.graphql", profile_id: 42 }
  let(:result)   { load_fixture "#{__dir__}/result.yaml" }

  it { is_expected.to eq result }

  it "deletes the profile" do
    expect { subject }.to change { Profile.find_by(id: 42) }.to nil
  end

  it "sends a notification" do
    expect(Notifier)
      .to receive_message_chain(:create)
      .with("profileDeleted", 42)

    subject
  end
end
```

The seed (`seed_fixture`) file should be a YAML/JSON with opinionated parameters, namely:

- `type` for the name of the [FactoryBot][factory_bot] factory
- `traits` for the factory traits
- `params` for parameters of the factory

```yaml
# ./database.yml
#
# This is the same as
# `create :profile, :active, id: profile_id`
---
- type: profile
  traits:
    - active
  params:
    id: <%= profile_id %>
```

Another opinionated format we use for stubs (`stub_fixture`):

- `class` for stubbed class
- `chain` for messages chain
- `actions` for an array of actions for consecutive invocations of the chain

Every action either `return` some value, or `raise` some exception

```yaml
# ./stubs.yml
#
# The first invocation acts like
# allow(Events).to receive_message_chain(:create).and_return true
#
# Afterwards it will act like
# allow(Events).to receive_message_chain(:create).and_raise AlreadyRegisteredError
---
- class: Events
  chain:
    - create
  actions:
    - return: true
    - raise: AlreadyRegisteredError
```

```graphql
mutation {
  deleteProfile(
    input: {
      id: "<%= profile_id %>"
    }
  ) {
    success
    errors {
      message
      fields
    }
  }
}
```

```yaml
# ./result.yaml
---
data:
  deleteProfile:
    success: true
    errors: []
```

With these helpers all the concrete settings can be extracted to fixtures.

I find it especially helpful when I need to check different edge cases. Instead of polluting a specification with various parameters, I create the sub-folder with "input" and "output" fixtures for every case.

Looking at the spec I can easily figure out the "structure" of expectation, while looking at fixtures I can check the concrete corner cases.

## License

The gem is available as open source under the terms of the [MIT License][license].

[gem]: https://rubygems.org/gems/fixturama
[travis]: https://travis-ci.org/nepalez/fixturama
[license]: http://opensource.org/licenses/MIT