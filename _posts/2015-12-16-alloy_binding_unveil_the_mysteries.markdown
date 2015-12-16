---
layout: post
title:  "Alloy Binding: Unveil The Mysteries"
date:   2015-12-16 15:14:52
categories:
cover: /img/articles//cover.jpg
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
you should only bind to existing model (You can try to bind to the `icon` model if you dare,
Alloy will compile. Still, only God knows what would happen). 

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
<Alloy>
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

If you **don't** define a `transform()` method, you can take advantage of Backbone templates
and use several interpolation tags in a same string. This won't compile nevertheless if you're
using the `$model` trick, and won't work as expected if `transform()` is defined (in that case,
only the first interpolation will be rendered).

{% highlight xml %}
<Alloy>
    <Label text="{patate.greetings}: {patate.size}cm" />
</Alloy>
{% endhighlight %}

## Collection binding

## What about widgets ?
