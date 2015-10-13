---
layout: post
title:  Expeditious guide to Git
date:   2015-10-07 09:00:58
categories:
cover: /img/articles/git_guide/cover.jpg
author: Matthias Benkort
---

Using Git is easy, you just have to add / commit / push and pull to keep the track of other changes.
Is it that simple? Let's see how to use some basic features of Git in order to maintain a clear
and well-defined records.

<!--more-->

This little guide acts more like a reminder of what I see today as good practices with Git. It
does not intend to be an introduction or a tutorial for people willing to learn how to use Git.

### Commits

There are already plenty of excellent article about how to write a commit message and how to do
a nice commit; thus I'll keep this part straightforward. In the past, I used to make quite huge
commit with a quite huge message as well in order to describe the changes operated with that
commit. However, today, I would rather make very small commits that target only few changes.
There are simple reasons explaining that choice: 

- To commit often allows you to be more flexible. You can undo / redo a change more easily.
- This is terrific for tracking bugs in the history.
- Writing long commit messages is tedious and a bit complex.
- Resolving conflicts in this way is also easier as commits usually impact less code.
- When it comes to visualization tools (like GitHub for instance), this is way more readable.

Thereby, commit often and commit well. There are also two main schools about the form of a
commit message. Both agreed on the length - less than 70~80 characters.  Yet on the one hand,
some use verb in a past tense while on the other hand one would rather use an infinitive form.  

- `Fixed typo in the main README file`
- `Fix typo in the main README file`

I find it more logical to use an infinitive form as a commit message
should describe what changes the commit is introducing (and not what changes have been
introduced). What should be clear is that a commit message should start with a verb, and be
lengthed 80 characters at maximum. 

### Merge or Rebase ?

Now talking about importing other changes in our index, the easy way will usually lead to
something like this:

```
git pull origin mybranch
```

By default, this behavior corresponds to a `git fetch origin mybranch` following by a `git merge
origin/mybranch`. If there are changes in the remote repository it will result in a merge commit
with possible conflicts. Moreover, this log history will become uglier and uglier. In fact,
there is no real reason to have a merge commit here and most of the time, that commit does not
have any sense. Instead of that, when importing changes from a remote repository, I would
rather recommend to use Git rebase feature. 

```
git fetch origin
git rebase origin mybranch
```

or simply:

```
git pull origin mybranch --rebase
```

In this way, the history remains clear and clean. Plus it is possible to add new commits that
are consistent with the current remote state. Merge commits are great to keep track of new
features implementation. Working in a separated branch, it is possible to merge back the
feature into the source branch. Having a merge commit in that case is relevant as it refers to
a moment where two different parts of the code that had diverged combined again. Also, when
several developers are working from a same common branch and wish to integrate their changes in
the same time, one will be able to merge easily, but the other may have to resolve conflicts and
create a merge commit. This makes sense because they both worked in the same time. 

Most of the time, I am never using `git pull` but instead `git pull --ff-only` for
*fast-forward only*. This means that if Git is not able to import all changes directly without
having to do a merge commit, it will abort the process and let met see what should be done.
Then, depending on the situation, I will rebase my branch or nicely merge my changes into the
common branch. However, with a proper workflow, this will technically never happens. 
