---
layout: post
title:  Automated acceptance with Travis
date:   2015-06-21 09:40:02
categories: TheSmiths, test, automation
cover: /img/articles/automated_acceptance/cover.png
author: The Smiths 
---

When it comes to maintain or extend an existing mobile application, there is one thing you want to
ensure at any price: your changes should not break the existing working product. In other words, you
should avoid any kind of regression. This is what **automated acceptance** stands for.

<!--more-->

## Test things before it's too late
Nowadays and especially with framework like **Titanium**, you can build an app really quickly - Even
making a coffee might be longer. However, as an app grows and becomes larger and larger, a
non-structured project might evolve into a complete mess where each new feature brings an additional
bug. Writing tests for an app, before everything goes out of control might be one of the prior
concern of a developer. 

Testing things is a well-known and experienced field of the computer
sciences; Fortunately for us, a lot of testing solutions exist for the mobile development, and
especially in the **Titanium**'s world.

I'll not present existing testing solution here (*Jasmine*, *Mocha*, *Calabash* and *Cucumber* ...); This is
likely to be the subject of a further topic. Nevertheless, whatever testing solution you have
adopted, being able to run tests automatically and generate reports for you about how it went is an
interesting feature.

[**Travis**](https://travis-ci.org/) is an easy way to accomplish such a thing. It is probably the
most used automated acceptance tool alongside **GitHub**. It performs automatic builds and test
runs after every push on a given **GitHub** repository. Let's see how we can setup **Travis** for
our **Titanium** applications.

## How to setup an automated acceptance process
After linking your **GitHub** account with **Travis**, the only thing required to make **Travis** works is a
configuration *YML* file, placed at your repository's root. Right below is an example of a travis
file we used for our application.

{% highlight xml %}
.travis.yml

    language: objective-c 

    env:
        matrix:
            - PLATFORM="ios"
            - PLATFORM="android" ANDROID_VERSION="19"

    before_install:
        - export ANDROID_HOME=$PWD/android-sdk-macosx
        - export ANDROID_SDK=$ANDROID_HOME
        - export PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

    install:
        - npm install -g titanium alloy tishadow gulp ticalabash
        - npm install

        - titanium login travisci@appcelerator.com travisci
        - titanium sdk install latest --no-progress-bars

        - gulp 'install:android_sdk'

    before_script:
        - gulp 'start:emulator'
        - gulp 'config:tiapp' --test

    script: 
        - gulp 'test:calabash'
        - gulp 'test:jasmine'
{% endhighlight %}

This configuration allow us to create two jobs on **Travis**, one for *Android* and the other one
for *iOS*. A job is a set of tasks that are executed in a completly new virtual machine (VM).
Incidentally, each machine in **Travis** comes with a set of existing tools like *rvm* or *npm*. 
Let's dissect a bit that configuration file to understand what's going on. 

### Prepare the environment
As we will need to build for *iOS*, we need to start a VM that runs on *Mac OS*. This could be done
by telling **Travis** to use `objective-c` as a language. 

{% highlight xml %}
...
    language: objective-c
...
{% endhighlight %}


Also, it is possible to create separate
jobs by defining a `matrix` of environment variables. Under the hood, `matrix` definition in
**Travis** are really powerful (a way more powerful that we are currently doing). The next lines
tell **Travis** to create two jobs for which the given environment variables will be available.
Then, we are gonna use those variables in several scripts, but it does not make any sense for
**Travis** itself. By the by, **Travis** configuration files could be split into several sections
(`before_install`, `install`, `before_script`, `script`, `before_deploy`, `deploy`, `after_success` ...)
Those sections have different meanings and for most of them it doesn't change a thing to your build
process. This is rather a semantic consideration. If something goes wrong in the sections
`before_install`, `install` or `before_script`, your build will be considered as *errored*. If something
goes wrong in the `script` section, it will rather be considered as *failed*. 

As a matter of fact, those sections might be used to perform bash commands. A common thing to do is
to call some scripts or tasks runner commands to perform a more complex action. 



{% highlight xml %}
...
    env:
        matrix:
            - PLATFORM="ios"
            - PLATFORM="android" ANDROID_VERSION="19"

    before_install:
        - export ANDROID_HOME=$PWD/android-sdk-macosx
        - export ANDROID_SDK=$ANDROID_HOME
        - export PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
... 
{% endhighlight %}

### Set up Titanium and your test environment
To be able to build a **Titanium** app, it has to be installed on the VM, obviously. Fortunatly, the
node package manager is accessible and then, all the installation could be done the following way: 

{% highlight xml %}
...
    install:
        - npm install -g titanium alloy tishadow gulp ticalabash
        - npm install

        - titanium login travisci@appcelerator.com travisci
        - titanium sdk install latest --no-progress-bars

        - gulp 'install:android_sdk'
...
{% endhighlight %}

In order to use the **Titanium** cli, it is also required to login. As you don't want to put your
credentials on a public repository, you can just use those available for that purpose! 

Moreover, in our case, we are also installing some other tools with **Titanium**. Notably **Gulp**
which is a *JavaScript* task runner that will handle builds and tests. You may find interesting
tasks in our *boilerplate* project right
[here](https://github.com/TheSmiths/ts.boilerplate/tree/master/project_files/.gulp). Most of them
could easily be written using another task runner (such as *Grunt* or *Rake*) or simply written in
some bash scripts. I'll not dive into those tasks as they have been written to fit our needs, and as I
said, it will be the topic of another blog post. 

## Watch your results

With your `.travis.yml` configuration file set up, **Travis** will be able to set up jobs for every
push you perform on **GitHub**. It also gives you any output to the console of any executed command.
Then, it's up to you to look at those results and pieces of information; You can also configure **Travis** to
send you an email after a build to tell you about the results. 

Also, it is nice to put the information directly on **GitHub** using a small badge ![Travis](https://api.travis-ci.org/TheSmiths-Widgets/ts.blurryview.svg). In that way,
other developers might know that what they are looking at is something that compiles and pass some
tests!
