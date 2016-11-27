# Pragma::Decorator

[![Build Status](https://img.shields.io/travis/pragmarb/pragma-decorator.svg?maxAge=3600&style=flat-square)](https://travis-ci.org/pragmarb/pragma-decorator)
[![Dependency Status](https://img.shields.io/gemnasium/pragmarb/pragma-decorator.svg?maxAge=3600&style=flat-square)](https://gemnasium.com/github.com/pragmarb/pragma-decorator)
[![Code Climate](https://img.shields.io/codeclimate/github/pragmarb/pragma-decorator.svg?maxAge=3600&style=flat-square)](https://codeclimate.com/github/pragmarb/pragma-decorator)
[![Coveralls](https://img.shields.io/coveralls/pragmarb/pragma-decorator.svg?maxAge=3600&style=flat-square)](https://coveralls.io/github/pragmarb/pragma-decorator)

Decorators are a way to easily convert your API resources into JSON with minimum hassle.

They are built on top of [ROAR](https://github.com/apotonick/roar) but provide some useful helpers
for rendering collections, including pagination metadata and expanding associations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pragma-decorator'
```

And then execute:

```console
$ bundle
```

Or install it yourself as:

```console
$ gem install pragma-decorator
```

## Usage

Creating a decorator is as simple as inheriting from `Pragma::Decorator::Base`:

```ruby
module API
  module V1
    module User
      module Decorator
        class Resource < Pragma::Decorator::Base
          property :id
          property :email
          property :full_name
        end
      end
    end
  end
end
```

Just instantiate the decorator by passing it an object to decorate, then call `#to_hash` or
`#to_json`:

```ruby
decorator = API::V1::User::Decorator::Resource.new(user)
decorator.to_json
```

This will produce the following JSON:

```json
{
  "id": 1,
  "email": "jdoe@example.com",
  "full_name": "John Doe"
}
```

Since Pragma::Decorator is built on top of [ROAR](https://github.com/apotonick/roar) (which, in
turn, is built on top of [Representable](https://github.com/apotonick/representable)), you should
consult their documentation for the basic usage of decorators; the rest of this section only covers
the features provided specifically by Pragma::Decorator.

### Collections

A common pattern is to have a collection decorator whose only job is to wrap a collection and
decorate it with the resource-specific decorator. Pragma decorators have a mixin for this:

```ruby
module API
  module V1
    module User
      module Decorator
        class Collection < Pragma::Decorator::Base
          include Pragma::Decorator::Collection
        end
      end
    end
  end
end
```

This will define a `data` collection on the decorator that will contain the object passed to the
decorator. It will also decorate each object in this collection with a resource-specific decorator.

By default, the resource decorator is simply the `Resource` class in the same namespace as the
collection decorator. It is recommended to follow this naming convention, but you can specify a
different resource decorator by calling `#decorate_items_with`:

```ruby
module API
  module V1
    module User
      class CollectionDecorator < Pragma::Decorator::Base
        include Pragma::Decorator::Collection

        decorate_items_with ResourceDecorator
      end
    end
  end
end
```

### Pagination

`Pragma::Decorator::Pagination` will add pagination metadata to your collection decorator. It is
best used in conjunction with `Pragma::Decorator::Collection`.

```ruby
module API
  module V1
    module User
      module Decorator
        class Collection < Pragma::Decorator::Base
          include Pragma::Decorator::Collection
          include Pragma::Decorator::Pagination
        end
      end
    end
  end
end
```

This will create the following JSON representation:

```json
{
  "data": [
    { "...": "..." },
    { "...": "..." },
    { "...": "..." }
  ],
  "total_entries": 33,
  "per_page": 30,
  "previous_page": 1,
  "current_page": 2,
  "next_page": null,
  "pages": 2
}
```

The pagination mixin seamlessly integrates with both [Kaminari](https://github.com/amatsuda/kaminari)
and [will_paginate](https://github.com/mislav/will_paginate). The property names are the same,
regardless of the pagination engine in use.

### Associations

Buckle up, because this is where the cool part comes.

`Pragma::Decorator::Association` allows you to define associations in your decorator (currently,
only `belongs_to`/`has_one` associations are supported):

```ruby
module API
  module V1
    module Invoice
      module Decorator
        class Resource < Pragma::Decorator::Base
          include Pragma::Decorator::Association

          belongs_to :customer
        end
      end
    end
  end
end
```

Rendering an invoice will now create the following representation:

```json
{
  "customer": {
    "id": 19
  }
}
```

Not impressed? Just wait.

We also support association expansion through an interface similar to the one provided by the
[Stripe API](https://stripe.com/docs/api/curl#expanding_objects). You can define which associations
are expandable in the decorator:

```ruby
module API
  module V1
    module Invoice
      module Decorator
        class Resource < Pragma::Decorator::Base
          include Pragma::Decorator::Association

          belongs_to :customer, expandable: true
        end
      end
    end
  end
end
```

You can now pass `expand[]=customer` as a request parameter and have the `customer` property
expanded into a full object!

```json
{
  "customer": {
    "...": "..."
  }
}
```

This also works for nested associations. For instance, if the customer has a `company` association
marked as expandable, you can pass `expand[]=customer&expand[]=customer.company` to get that
association expanded too.

In order for association expansion to work, you will have to pass the request parameters to the
representer as a user option:

```ruby
decorator = API::V1::Invoice::Decorator::Resource.new(invoice)
decorator.to_json(user_options: {
  params: params # e.g. the params available to a Rails controller
})
```

Here's a list of options accepted when defining an association:

Name | Type | Default | Meaning
---- | ---- | ------- | -------
`expandable` | Boolean | `false` | Whether this association is expandable by consumers. Attempting to expand a non-expandable association will raise a `UnexpandableError`.
`decorator` | Class | - | If provided, decorates the expanded object with this decorator. Otherwise, simply calls `#to_hash` on the object to get a representable hash.
`render_nil` | Boolean | `false` | Whether the property should be rendered at all when it is `nil`.
`exec_context` | Symbol | `decorated` | Passing `decorated` calls the getter on decorated object, while `decorator` calls it on the decorator instance.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pragmarb/pragma-decorator.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
