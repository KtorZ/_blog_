Practical Guide to Design Patterns
==================================


## Command 

### In brief

- Represent an action request (a.k.a command) as a full object
- Untight the execution call between the caller and the callee 

An executor could be seend as a blackbox, only providing a single method which can interpret
command to perform an underlying action. 

### Use Cases

Two words: Undo / Redo. It almost feels like the pattern was designed for that specific
functionallity. In general, the command pattern is great to keep trace of a stack of actions,
either as an history of what happened, or as a queue of future actions that are going to
happened. 

### Gave birth to... 


## Observer


## Iterator 



## References
https://sourcemaking.com/design_patterns
http://addyosmani.com/resources/essentialjsdesignpatterns/book/
