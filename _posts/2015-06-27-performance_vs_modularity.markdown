---
layout: post
title:  Performance VS Modularity
date:   2015-06-27 08:01:25
categories: TheSmiths # Feel free to add specific categories
cover: /img/articles/performance/cover.jpg
author: Matthias Benkort # Complete with your name
---

One of the greatest features of **Titanium** relies on its high modularity. The SDK can be easily
extended using modules, and when it comes to **Alloy**, code can be split into several parts called
*widgets*. However, what is the cost of using a *widget*? What impact does a `require` have on the
performance?

<!--more-->

### Little Benchmark

In order to test the cost of using a widget, we have ran some benchmark tests on different
devices (Samsung Galaxy S3, Archos Neon, LG D855, iPhone 4, iPhone 5s). Several
widget compositions have been created such that at the end, the result will constitute in a window
containing 10 labels.

- **benchmark_10**: The reference one, this is a single widget containing 10 identical labels.
- **benchmark_2x5**: This one is the above one split in two widgets, each of them containing 5
  labels. So, there is 2 imports.
- **benchmark_10x1**: Here, each label has been placed into a single widget; This result in 10
  imports for Alloy.
- **benchmark_5x1p5**: 5 labels are directly placed into the window, the other 5 one have been
  placed into separated widget. 5 imports.
- **benchmark_2x2x2p1**: This one aims at testing the impact of nested widgets. There are 2 widgets
  containing 2 widgets and one label. Each of the latter 2 widgets contains also two widgets that
  encapsulate a single label. Thus, there are 6 imports in total.

Now, what are we measuring exactly? The time it takes to create a widget from a controller.

{% highlight javascript %}
var now = Date.now();
for (var i = 0; i < 100; ++i) {
    widget = Alloy.createWidget("benchmark_xxx");
}
Ti.API.debug(Date.now() - now);
{% endhighlight %}

We have ran the tests multiple times and took the average.
The first benchmark (*benchmark_10*) is use a reference of the time it cost to create all 10 labels.
Therefore, what we are measuring is the deviation from this reference, weighted by the number of
widgets to require / create.

### Results
Results are quite interesting and encouraging. For each device, the instantiation time is under
`1ms` and under `350us` for most of them (R.I.P iPhone 4...). Also, the more widgets are required,
the less it takes to require one of them. However, this seems not to be relevant enough and it's probably due
to the fact that every widget is composed of the same Label element. Titanium or the device itself
might be able to process some sort of cache to speed up the view creation.

Also, nesting widget seems to slow a bit the require time for any device. However.. Except for the
Archos which is definitely not a great warrior in this battle, the additional time might be ignored.

Here are the results, (measure unit are micro seconds per widget):

Device        | Benchmark_2x5 | Benchmark_5x1p5 | Benchmark_2x2x2p1 | Benchmark_10x1
--------------|---------------|-----------------|-------------------|-------------------
Archos Neon   | 619           | 589             | 818               | 485  
LG D855       | 619           | 366             | 380               | 337
Galaxy S3     | 354           | 310             | 334               | 333
iPhone 5s     | 313           | 270             | 289               | 263
iPhone 4      | 776           | 946             | 962               | 937

### Bilan
The benchmarks (what a huge word for some measures of time) comfort us in the idea that the
readability and the high level of maintainability brought by a the modular architecture do not impact the
performance that much. When requiring about 50 different widgets, the overall cost brought by those
calls is less than `50ms` and could be easily done on start-up. Component-driven development for
mobile application sounds even more promising.
