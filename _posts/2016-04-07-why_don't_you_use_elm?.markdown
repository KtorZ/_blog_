---
layout: post
title:  Why Don't You Use Elm?
date:   2016-04-07 22:10:47
categories:
cover: /img/articles/why_not_elm/cover.png
author: Matthias Benkort
---

While achieving a small *Angular* app today, my thoughts stumbled accross something that pique
curiosity. Why isn't more people learning *Elm*? There're loads of frontend technologies
running currently, and the trendiest one might be *React*. I've played rather correctly with
*React* and *Backbone*, and I am now diving seriously into *Angular* (you know, you still have
to eat at the end of the month). Incidentally, I am a huge fan of functional reactive
programming and *Elm* has definitely all my love and devotion. 

<!--more-->

So, let me try to make a point. Each time one learns a new framework, ones get used to the
intrinsic philosophy that this framework built. *React* expects you to understand what
components are and how they behave towards their properties, states and listeners. It also
requires you have an idea of what is happening at the rendering level with the virtual dom.
*Angular* on the other hand presents a slew of services you can inject in your controllers,
factories, directives and how they play well with the two-way data-binding. I won't carp about
*Backbone* because you get the idea. Each framework demands a set of prerequisite knowledge,
that may echo from one to another but nonetheless stay disparate. Although they usually rely on
strong theoritical concepts, they are often so deeply entangled in the framework that it is
complicated to use them out of their initial context. You'll get familiar with the *React* way,
or the *Angular* way yet you're not likely to re-use their concepts elsewhere on your own
(mainly because you'll be using another framework and be compliant with new patterns). Why
don't you learn *Elm* instead? Well I know, *Elm* is a different language (and a functional
one, yuck!) and the learning curve is way too important. Meh.

Therefore, it seems familiar and comfortable, as the big majority of frontend frameworks is
built on top of *JavaScript*, to stick with *JavaScript* as much as possible. Hence, it feels
like there's one less barrier to overcome; the underlying language is always the same, isn't
it? Having a quick look at the *JavaScript* in *Angular*, and the one in *React*, it really
looks like two fairly different flavor of *JavaScript*. The former would rather use a
Vanilla/ES5 *JavaScript* whereas the latter embraces ES6/ES7 with an extensive usage of
destructuring and methods declaration shortcuts. It really sounds like two different - albeit
from a common ancestor - languages. You end up learning two distinct languages. So what's your
excuse now? Instead of learning a framework (and its underlying *JavaScript* flavor), you're
able to deal with a language which will by itself, intrinsically, offers you all the control
and the behaviour you'll expect from a framework. Plus, because you are facing directly
patterns and concerns which built your code, you're getting stronger insights. There's one
remark though. I've been told the main issue with *Elm* was about reading the documention. For
non fonctional programming developers, it appears to be an impenetrable dialect whereas
documentations from the trendiest frameworks are more "standard", more usual.  Inasmuch as it
seems to be the only obstacle that keeps you away from *Elm*, let's spend five more minutes
together to break through this.

So here we are, talking about [Hindley-Milner][hindleymilner] type signatures. Trust me on
that, once you can read that fluently, it becomes the best documentation you'll ever have.
Let's start with an excerpt of *Elm*'s documentation:

{% highlight haskell %}
isEmpty: String -> Bool
{% endhighlight %}

First, there's the function name `isEmpty` that identifies the signature after the colon. Then,
we find two types separated by an arrow. Incidentally, this type system is seemingly relevant
because *Elm* is a strongly statically typed language. Although it sounds rather obvious, it is
worth a remark. So, the arrow basically means that given what is left side, your function will
give you what is on the right side. In this case, this is straightforward, given a `String`,
you'll get a result of `Bool` type. What about several arrows?

{% highlight haskell %}
repeat : Int -> String -> String
{% endhighlight %}

Well, the previous rule still apply. There're now two different cases though. We either
provide an `Int` to the `repeat` function, or we provide an `Int` and a `String` (in that
order). In the second case, we get a `String` as a result (`repeat 2 "patate"` ->
`"patatepatate"). In the first case however, we obtain a function that will, given a `String`,
return a `String`. Assuming we provided `14` as an `Int`, then we could write the result the
following way:

{% highlight haskell %}
repeat14: String -> String
{% endhighlight %}

Can you feel the expressiveness of the type system? Brace yourself, there's more. Try to get
this one by yourself:

{% highlight haskell %}
length: List a -> Int
{% endhighlight %}

At first sight, this signature looks quite unusal. There's a new type `List` but, with a
*parametric* type-variable `a`. Should you haven't guess it, this signifies that your `List`
holds... something, something of type `a`. It could be an `Int`, it could be a `Bool` or it
could be a `List Int` as well. It nonetheless ensures that your list is made only from element
of that same type. The eventual meaning of the signature means that given a `List` of
something, it will always return an `Int`. By the by, this is fair enough as we don't need to
know what are the types of the list's elements to know how many of them are in the list, right?
One more before I let you go code some *Elm*.

{% highlight haskell %}
map: (a -> b) -> List a -> List b
{% endhighlight %}

First of all, parentheses are *completely* optional; they merely enhance the reading and give
us a tiny hint about the meaning of the function. What it suggests is that you would rather
give the two parameters at the same time, i.e, you'll give a function that takes a type `a` and
returns a type `b`. Now we've two different type-variables to identify two (possibly) different
types. They don't have to be different though, but they *might* be. It could be `Int ->
String`, as well as `Bool -> Bool`. Yet, every `a` in the signature has the same type, and
every `b` is consistent as well. Should you already be familiar with the `map` function in
*JavaScript*, this is the *Elmish* version. Given a function from type `a` to type `b` and a
`List` of `a`, you get a mapped `List` of `b`. For instance in *JavaScript*:

{% highlight javascript %}
["patate", "autruche"].map(x => x.length)
// [6, 8]
{% endhighlight %}

And the equivalent in *Elm*:

{% highlight haskell %}
List.map String.length ["patate", "autruche"]
-- [6, 8]
{% endhighlight %}

There are some more theory and syntax properties about *Hindley-Milner* signatures, however
this is what is needed to cover almost all *Elm* signatures you'll find in packages.
Understanding these signatures gives you access to a whole new part of the documentation. In
the same time, it even allows you to reason about your code and to build your application quite
easily. So, what are you waiting for? There're few dependencies, it's blazingly fast, built for
frontend developers, and it's free from any framework shackles. 

[Go learn some *Elm*][elm].

P.S: And the most curious, [Evan Czaplicki][evan] about *Elm*.

[elm]: http://elm-lang.org/try
[hindleymilner]: https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system
[evan]: https://www.youtube.com/watch?v=oYk8CKH7OhE
