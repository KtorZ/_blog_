---
layout: post
title:  "Alloy Binding: Unveil The Mysteries"
date:   2015-12-16 15:14:52
categories:
cover: /img/articles/alloy_bindings/cover.png
author: Matthias Benkort
---

Despite some reservations about several Alloy features and choices, one does not simply ignore
the most interessant feature so-called data-binding. Unfortunately, the documentation on that
part is rather disastrous; let's try to provide some insights upon which rely in the future. 

<!--more-->

Because the binding mainly concerns *Backbone* models (we'll see more about how we can trick
the current implementation), we'll proceed first with model and then we'll look at how to
extend the concept to collections. Incidentally, data-binding can be used within a widget and
within the widget's scope. We'll consider Alloy's version > 1.6 all along this post.

I do not intend to give an explanation of what data-binding is, I assume the reader already
knows the idea. This is rather a practical guide on how to use it wihtin Alloy. You should be
able to use the binding on any Alloy tag, please let me know if you know any issue with a
component. 

## Model binding

### Global instance

When using an explicit tag `<Model>` in an *xml* view, Alloy will assume you're refering to a
unique singleton stored in `Alloy.Models.<model_name>`. Should Alloy creates a new instance the
first time you refer to that model. Otherwise, the same instance will be used. 

So, here we are:

{% highlight xml %}
<Alloy>
    <Model src="patate" />
    <Label text="{patate.size}" />
</Alloy>
{% endhighlight %}

The snippet below will create a binding between a model instance stored in
`Alloy.Models.patate`. The following rules apply here:

- Alloy will create an instance of the model if it does not exist
- A model file has to be present in the `models/` folder 
- The model file should have the same name as indicated in `src` plus a `.js` extension
- Alloy will listen to `fetch`, `change` and `destroy` events from Backbone
- The `destroy()` method has to be called explicitely to unbind the model
- The model can define a `transform()` method which return an object on which properties
  are going to be accessed
- Without any `transform()` method, Alloy will consider the `toJSON()` method provided by
  Backbone for each model

Incidentally, if there is already an existing instance, we can just omit the `<Model>` tag and
directely refer to the model via string interpolation. To me, it makes more sense to create the
singleton in a separated file, for instance `Alloy.js` and keep away from the view file that
ugly `<Model>`.

If you try to reference a non-existing model, alloy will refuse to compile with a nice error
message if you provide an invalid `src` attribute or, with a message a bit more irrelevant if
you just specified an invalid base for the interpolation. In both cases, this just mean that
you should only bind to existing model.

### Local instance

What if you just need a local instance of your model? Well, there are some attributes you may
add to the `<Model>` to do so.

{% highlight xml %}
<Alloy>
    <Model src="patate" instance="true" id="mypatate" />
    <Label text="{$.mypatate.size}" />
</Alloy>
{% endhighlight %}

Notice the `$.patate` now in the interpolation and the two new attributes in the model tag. 

Each previous rules also apply in that case. The only difference is that, instead of storing
and trying to access the model instance from `Alloy.Models`, this will rather place the
instance within your controller instance and thus, give you an access through `$.<model_id>`.

Unlike the global instance, you cannot omit the `<Model>` tag, nor the `id` attributes. Without
any `id`, the instance will be stored in your controller under a name computed by the compiler,
hard to guess at runtime for you. And, without any tag, the model just won't be created and
you'll end up with a nice error when Alloy will try to bind Backbone event on an undefined
instance when executing the controller. You cannot bind to an existing instance doing that.

By the by, `instance` and `id` are inseparable. There is no point of considering one without
the other.

### Existing instance

Well, sometimes, you still want to bind to an existing instance. Did I say this was impossible?
That wasn't exactly true. From the mysterious valleys of Alloy source code, you can notice that
Alloy actually processes your controller arguments and has a dedicated processing for several of
them. The `$model` is one of them.

Thus, from a view file, you can interpolate the following way:

{% highlight xml %}
<Alloy>so this is a issue I will fix for you asap
    <Label text="{size}" />
</Alloy>
{% endhighlight %}

This syntax assumes that an argument `$model` (no point) has been passed to your controller
with one condition. It should be an object with a property `__transform` which should also
point to an object, empty or not. Because Alloy will try to access this property directly, if
you omit it, the application will crash at runtime. 

You can see the `__transform` property as the result of either the `transform()` or the
`toJSON()` methods we mentionned above. You can populate this object with properties that need
to be accessed (`size` in our example). Besides, if the property is undefined within the
`__transform` object, Alloy will presume that `$model` is a Backbone instance and will try to
access the property via `$model.get('<property_name>')`. 

### Remarks

- **Beware of caps**

If you use a capitalize name for your model, use the downcase name when refering to it in the
interpolation. Alloy stores models names as lower cases. 

{% highlight xml %}
<Alloy>
    <Model src="Patate" />
    <Label text="{patate.size}" />
</Alloy>
{% endhighlight %}

- **Don't nest properties**

If your model holds an object, you won't be able to access its nested properties when
interpolating. Thus, take advantage of the `transform()` method or `__transform` object to
provide a facade for those properties. 

- **Several interpolations with toJSON()**

If you **don't** define a `transform()` method, you can take advantagGe of Backbone templates
and use several interpolation tags in a same string. This won't compile nevertheless if you're
using the `$model` trick, and won't work as expected if `transform()` is defined (in that case,
only the first interpolation will be rendered).

{% highlight xml %}
<Alloy>
    <Label text="{patate.greetings}: {patate.size}cm" />
</Alloy>
{% endhighlight %}

- **Already hydrated models**

Keep in mind that the view associated to your model will only render and re-render when a
`fetch`, `change` or `destroy` event occurs. This means that if you try to bind a view to an
already instantiated model that already possesses its data, you won't see the view as expected.
If you're in such a case, `<your-model>.trigger('change')` will do the trick ;).

## Collection binding

Let's step up the game a bit. One model wasn't enough, we want a complete collection of them.
The idea is quite similar than before should we just add one concept. Each model of the
collection are going to be rendered within a container. It feels natural to use containers such
as `listview` or `tableview` however, one can use any view object as a container (again, let me
know if you encounter any issue with a given UI object).

Thus, given a container which will hold the collection, we need to defined a nested repeater
which will be used to instantiate all view element associated to each model of the collection.
The nested repeater element depends of the nature of the container. The table in the current
documentation is quite accurate though still a bit incomplete. In practice, it is possible to
use `ScrollView` and in fact, any other `View` (or component extending `View`) and then use any
UI component that extends `View` as a repeater. 

### Global Instance

Similarly to models, you may use a `Collection` markup tag to make you're creating a global
instance of an existing colection (the name you supply should exist within your `models`
folder). The instance is stored under `Alloy.Collections` meaning that, the same instance will
be used between several controllers. 

{% highlight xml %}
<Alloy>
    <Collection src="patate" />
    <View dataCollection="patate">
        <Label text="{size}" />
    </View>
</Alloy>
{% endhighlight %}

You can omit the `Collection` tag as well and this suppose that there is an existing instance
store in `Alloy.Collections`. Incidentally, doing that, you're able to give any name you want
to the collection, it does not have to fit an existing model of your `models` folder. This is
quite interesting if you want to keep different collections holding the same type of models.

Notice how we identified the container component with the `dataCollection` attribute. A
collection holder identified this way can also define 3 other attributes:

- **dataFunction**

This property allow you to create an alias accessible within your controller to render the view
on demand. This is useful when you're binding to an already populated collection; By using the
provided function, you can render the data even if no Backbone events have been raised. You
don't need the trick mentionned in the model section, here's a dedicated function.

Using `dataFunction` is quite straightforward:

**view.xml**
{% highlight xml %}
<Alloy>
    <View dataCollection="patate" dataFunction="render">
        <Label text="{size}" />
    </View>
</Alloy>
{% endhighlight %}

**controller.js**
{% highlight javascript %}

// Some code above 

render() // Will behave the same as receiving a watched Backbone event on the collection 

// Some code after
{% endhighlight %}

- **dataFilter**

You have the possibility to filter the given collection to only render a part of that
collection. This is done by providing a filtering function via the `dataFilter` attribute. The
function takes a collection as an argument and is expecting to return an array of models. 

**view.xml**
{% highlight xml %}
<Alloy>
    <View dataCollection="patate" dataFilter="filter">
        <Label text="{size}" />
    </View>
</Alloy>
{% endhighlight %}

**controller.js**
{% highlight javascript %}
// Only patate with a size > 10
function filter (xs) {
    return xs.models.filter(function (x) { return x.get('size') > 10 })
}
{% endhighlight %}


Incidentally, this is quite useful to render different parts of the screen with data extracted
from solely one collection. 

- **dataTransform**  

Remember the `transform()` method we could defined on models ? Well, it doesn't apply
automatically to model inside a collection. Still, you can apply some transformations to your
models by providing an appropriate via the `dataTransform` property. The function will run for
each model stored in the collection and should return a JSON representation of that model. 
The most convinient way is probably to define use the `transform()` method already defined for
the associated model which could be done in either one of the following ways:

**view.xml**  
{% highlight xml %}
<Alloy>
    <View dataCollection="patate" dataTransform="transform">
        <Label text="{size}" />
    </View>
</Alloy>
{% endhighlight %}

**controller.js**
{% highlight javascript %}
function transform (x) { return x.transform() }

// Or

var transform = Function.call.bind(require('alloy/models/<Model>').Model.prototype.transform)
{% endhighlight %}

### Local instance

I won't spend a lot of time on that part. This is highly similar to what is done with models.
you can add an `id` and a `instance` attributes to the `Collection` tag to create a local
instance of the given collection. The collection is thereby stored under `$.<id>` and respect
all previously written rules about collections. 

### Remarks

- **destroy()**

Remember, you still have to call `$.destroy()` once done to remove all bindings that apply on
collections. Without this, the garbage collector won't be able to free the memory after the
controller life.

## What about widgets ?
