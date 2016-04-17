---
layout: post
title:  Titanium, Alloy and ES6
date:   2015-10-26 10:27:19
author: Matthias Benkort
---

ES6 is not only about syntactic sugars in your code, It also includes a lot of interesting
features and flow control tools like destructuring and promises. It makes functional
programming even more pleasant in JavaScript and thus we ought to use it with *Alloy*.

<!--more-->

> ##### EDIT 05th November 2015
> I've now created a Titanium plugin available as an npm package which makes the process way
> more convenient to use: [ti.es6](https://www.npmjs.com/package/ti.es6)   



There is already an existing solution that can be used for *Titanium* classic apps:
[ti.babel](https://github.com/dawsontoth/ti.babel). It is using, as I will do, the power of
[Babel](https://babeljs.io/) to transcompile all *Titanium* ES6 sources to a compatible ES5
version for the app. So, let's dive into it and see how to make the thing works with *Alloy*.

### Prerequisites

First of all, we'll need some artifacts but do not worry, `npm` is as usual our devoted friend.

{% highlight bash %}
npm install -g babel browserify 
{% endhighlight %}

For the following, I've been working with *Alloy 1.7.x* and *Titanium 5.0.x*; nevertheless it
should work fine with any version. Also, you'll need *Node.js*, at least version 0.12.x (in
order to do synchronous `exec`) 

### Create destination folder

Assuming we're now in a *Titanium* root project folder (the one that has the `tiapp.xml` file).
In order to compile without disturbing the existing sources, we will ask *Babel* to transcompile
the project `app/` folder into a new one, let's call it `.app/` so it is hidden and nobody
cares about what is happening with this one. In that folder, add three folders `controllers`
and `lib/babel`. Then, put a blank file `index.js` within the folder `controllers` (this is the
minimum required by *Alloy* to start the compilation). 

Then, we'll need to use the lib *Polyfill* packaged with *Babel* to introduce some advanced
features to ES5. 

{% highlight sh %}
mkdir -p .app/controllers .app/lib/babel
touch .app/controllers/index.js
browserify $(npm config get prefix)/lib/node_modules/babel-core/polyfill.js -o
.app/lib/babel/polyfill.js
{% endhighlight %}

Great, now, let's create a little hook for *Alloy* using an *alloy.jmk* file. We'll put a hook
before alloy compilation to transcompile all our original sources to something ES5-compatible.
So, create an `alloy.jmk` and place it into the `.app` folder with the following content:

{% highlight javascript %}
var babel = require('babel'),
    fs = require('fs'),
    path = require('path'),
    exec = require('child_process').execSync;

task("pre:compile", function (e, log) {
    var babelSrc = path.join(e.dir.home, '*').replace('/' + process.env.ALLOY_APP_DIR, '/app'),
        alloy = path.join(e.dir.home, 'alloy.js');

    // Babel everything
    if (process.env.ALLOY_APP_DIR && process.env.ALLOY_APP_DIR !== 'app') {
        log.info("Transcompiling to ES5");
        // First of all, erase previous compilation but index.js and cie.
        exec('find ' + e.dir.home +
            ' ! -name "alloy.jmk"' +
            ' ! -path "' + path.join(e.dir.home, 'controllers', 'index.js') + '"' +
            ' ! -path "' + path.join(e.dir.home, 'lib', 'babel', 'polyfill.js') + '"' +
            ' -type f -delete');
        // Remove empty folders
        exec('find ' + e.dir.home + ' -empty -type d -delete');
        // And copy the current app into the future app folder for Alloy
        exec('cp -r ' + babelSrc + ' ' + e.dir.home);

        // Add a little line to alloy.js in order to include Polyfill
        var content = fs.readFileSync(alloy);
        content = 'require("babel/polyfill");\n' + content;
        fs.writeFileSync(alloy, content);

        // And finally, transcompile with Babel
        exec('babel ' + e.dir.home + ' --out-dir ' + e.dir.home);
    }
});
{% endhighlight %}

So, the *Titanium* project now basically has this kind of structure:

{% highlight bash %}
.
|--- app
|     |-- alloy.js
|     |-- controllers
|          | -- index.js
|     |-- models
|     |-- views 
|--- .app
|     |-- alloy.jmk
|     |-- controllers
|          | -- index.js
|     |-- lib/babel/polyfill.js
|--- build
|--- i18n
|--- modules
|--- platform
|--- plugins
|--- Resources
|--- tiapp.xml
{% endhighlight %}

### Do the trick

Now, this is the tricky part. We need to make *Alloy* think that the correct application folder
is `.app/` and not `app/`. To do so, we'll need to edit *Alloy*'s source files (we'll see about
a Pull Request maybe?).

Incidentally, everything could be easier and simplified if we were working in a separate
folder, using the *Alloy.jmk* to copy and transcompile our source into the original `app/`
folder. However in order to use all other *Alloy* features like scaffolding and also to keep a
common folder architecture, those small hacks into *Alloy* plugins are - to me - worth it.

So, let's find the *Alloy* installation, usually `/usr/local/lib/node_modules/alloy/` and open
the file `Alloy/commands/compile/index.js`.

At the very beginning of the first exported function, you'll need to add those lines (those
with a `+` sign at the beginning):

{% highlight javascript %}
//////////////////////////////////////
////////// command function //////////
//////////////////////////////////////
module.exports = function(args, program) {
	BENCHMARK();
	var alloyConfig = {},
		compilerMakeFile,
		paths = U.getAndValidateProjectPaths(
			program.outputPath || args[0] || process.cwd()
		),
		restrictionPath;

+    if (process.env.ALLOY_APP_DIR) {
+        paths.app = path.join(paths.project, process.env.ALLOY_APP_DIR);
+    }
{% endhighlight %}

We're almost done! Because *Alloy* is a bit messy sometimes ^.^, there is another little
line to fix, around line `250`, find the one that refers to `CONST.ALLOY_DIR` and change it
for our `paths.app` like this: 

{% highlight javascript %}
    // Create collection of all widget and app paths
    var widgetDirs = U.getWidgetDirectories(paths.app);
    var viewCollection = widgetDirs;
-   viewCollection.push({ dir: path.join(paths.project, CONST.ALLOY_DIR) });
+   viewCollection.push({ dir: paths.app });
{% endhighlight %}

Save it, and be ready to enjoy :)

### Last step

Okay, last step, as you probably noticed, we're refering to an environment variable
`ALLOY_APP_DIR`, so, we'll have to define that variable !


{% highlight bash %}
export ALLOY_APP_DIR=.app
{% endhighlight %}

aaaaaaaaand... you're done. You may want to add this export line to your `.bashrc` or
`.bashprofile` or whatever you're using. Also, if you're using a versionning system as `git`,
make sure to correctly set up your `.gitignore` to avoid the `.app` folder (however be careful,
you still need the `index.js`, `alloy.jmk` and `polyfill.js` in there !).

Enjoy !
