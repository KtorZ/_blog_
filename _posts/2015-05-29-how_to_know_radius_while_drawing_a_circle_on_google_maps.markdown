---
layout: post
title:  How to know radius while drawing a circle on Google Maps
date:   2015-05-29 22:00:00
categories:
cover: /img/articles/google_maps/cover.jpg
author: Matthias Benkort
---

Complete answer and challenge to
[a StackOverflow question](http://stackoverflow.com/questions/30368231/how-to-know-radius-while-drawing-a-circle-on-google-maps) upon the Google Maps API.

<!--more-->

A nice challenge indeed. As @DaveAlperovich has commented, the `DrawingManager` can't be used to retrieve this piece of information; While drawing, there is no access to the circle; We have to wait for the `DrawingManager` to trigger the `circlecomplete` event to get a reference to this circle.

**Nevertheless**, if you can't have a real manager, *just fake it*.
See the final result on [JSFiddle](http://jsfiddle.net/KtorZ/kejks9dg/1/) and the description right below.

###Step 1: Create a custom control
Somewhere in the file or as an external library:
{% highlight javascript %}
var FakeDrawer = function (controlDiv, map) {
    var self = this;
   
    /* Initialization, some styling ... */
    self._map = map;
    self.initControls(controlDiv);
};

FakeDrawer.prototype.initControls = function (controlDiv) {
    var self = this;

    function createControlUI (title, image) {
        var controlUI = document.createElement('div');
        /* ... See the snippet for details .. just some styling */
        return controlUI;
    }

    self._controls = {
        circle: createControlUI("Draw a circle", "circle"),
        stop: createControlUI("Stop drawing", "openhand"),
     };

     controlDiv.appendChild(self._controls.stop);
     controlDiv.appendChild(self._controls.circle);
};
{% endhighlight %}
### Step 2: Add some sugars
This are functions that we may use; Highly inspired from your JsFiddle :)

A reset method to recover a consistent state when needed:
{% highlight javascript %}
FakeDrawer.prototype.reset = function () {
    var self = this;
    self._map.setOptions({
        draggableCursor: "",
        draggable: "true"
    });

    /* Remove any applied listener */
    if (self._drawListener) { google.maps.event.removeListener(self._drawListener) ; }
};
{% endhighlight %}

And, a distance computer:

{% highlight javascript %}
FakeDrawer.prototype.distanceBetweenPoints = function (p1, p2) {
    if (!p1 || !p2) {
        return 0;
    }
    var R = 6371;
    var dLat = (p2.lat() - p1.lat()) * Math.PI / 180;
    var dLon = (p2.lng() - p1.lng()) * Math.PI / 180;
    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(p1.lat() * Math.PI / 180) * Math.cos(p2.lat() * Math.PI / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    var d = R * c;
    return d;
};
{% endhighlight %}

### Step 3: Create your own drawing mode
Now that we have some controls, we have to define their behavior. The `stop` control is straightforward; Let's have a look to the `circle` control.

{% highlight javascript %}
FakeDrawer.prototype.drawingMode = function (self) {
    return function (center) {
        /* Let's freeze the map during drawing */
        self._map.setOptions({draggable: false});

        /* Create a new circle which will be manually scaled */
        var circle = new google.maps.Circle({
            fillColor: '#000',
            fillOpacity: 0.3,
            strokeWeight: 2,
            clickable: false,
            editable: false,
            map: self._map,
            radius: 1,
            center: center.latLng,
            zIndex: 1
        });

        /* Update the radius on each mouse move */
        var onMouseMove = self._map.addListener('mousemove', function (border) {
            var radius = 1000 * self.distanceBetweenPoints(center.latLng, border.latLng);
            circle.setRadius(radius);

            /* Here is the feature, know the radius while drawing */
            google.maps.event.trigger(self, 'drawing_radius_changed', circle);
        });

        /* The user has finished its drawing */
        google.maps.event.addListenerOnce(self._map, 'mouseup', function () {
            /* Remove all listeners as they are no more required */
            google.maps.event.removeListener(onMouseMove);

            circle.setEditable(true);

            /* Restore some options to keep a consistent behavior */
            self.reset();

            /* Notify listener with the final circle */
            google.maps.event.trigger(self, 'circlecomplete', circle);
        });
    };
};
{% endhighlight %}

###Step 4: Bind controls
Now that everything is okay, let's add some listeners to the initial version of the constructor so that each control has a corresponding action when clicked.

{% highlight javascript %}
var FakeDrawer = function (controlDiv, map) {
    var self = this;
    
    /* Initialization, some styling ... */
    self._map = map;
    self.initControls(controlDiv);

    /* Setup the click event listeners: drawingmode */
    google.maps.event.addDomListener(self._controls.circle, 'click', function() {
        /* Ensure consistency */
        self.reset();

        /* Only drawingmode */
        self._map.setOptions({draggableCursor: "crosshair"});
        self._drawListener = self._map.addListener('mousedown', self.drawingMode(self));
    });

    google.maps.event.addDomListener(self._controls.stop, 'click', function () {
        self.reset();
    });
};
{% endhighlight %}

###Step 5: Use it!
Assuming that your map has been initialized correctly. 

Inside your map init function:

{% highlight javascript %}
var fakeDrawerDiv = document.createElement('div');
var fakeDrawer = new FakeDrawer(fakeDrawerDiv, map);

fakeDrawerDiv.index = 1;
map.controls[google.maps.ControlPosition.TOP_CENTER].push(fakeDrawerDiv);

var updateInfo = function (circle) {
    document.getElementById("info").innerHTML = "Radius: " + circle.getRadius();
};

google.maps.event.addListener(fakeDrawer, 'drawing_radius_changed', updateInfo);
google.maps.event.addListener(fakeDrawer, 'circlecomplete', function (circle) {
    google.maps.event.addListener(circle, 'radius_changed', function () {
        updateInfo(circle);
    });
});
{% endhighlight %}

Enjoy, hope it will help.
