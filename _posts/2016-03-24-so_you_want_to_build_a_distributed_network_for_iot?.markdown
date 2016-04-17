---
layout: post
title:  So You Want to Build a Distributed Network for IoT?
date:   2016-03-24 16:33:59
author: Matthias Benkort
---

In this article, I'll go through the past 4 months with The Things Network. It aims at giving
technical and non-technical insights on the project for an external enthusiast or someone
willing to catch-up with the work that has already been done.

## Overview of The Things Network

### What is IoT?

The Internet of Things, a.k.a *IoT*, describes the network made by connected objects. In
opposition to the Internet which describes the network of computers (on a very large scale - a
[Raspberry Pi][raspberry] could be here considered as a computer). Connected objects could be
any *things* such as vehicles, a fridge or your cat (please don't do that). So far, the idea of
a network loosely refers to an abstraction of our vocabulary. There's actually no such thing as
*another* network; under the bonnet, everything still relies on the mighty Internet. One rather
calls IoT the extension created by all those devices. I believe nonetheless in the possibility
of an alternative network, dedicated to the *things*. Almost 50 years after [ARPANET][arpanet]
(the most relevant ancestor of the Internet), it is still unusual to consider making two
distant machines communicate with anything else than the standard `tcp/ip` stack alongside with
`dns`. Yet, researchers and engineers are [already looking forward to build a new
stack][iotstack] which could manage traffic more efficiently regarding to *things*. Aiming at
the same direction, The Things Network (hereby known as TTN) strives to build a network for
*IoT*.  Even though it still relies on the standard Internet stack, promises are good enough to
foresee an evolution towards a parallel and independent dedicated network.

### TTN

One does not simply talk about TTN without mentioning [LoRa][lora]. Straightforwardly, *LoRa*
stands for **Lo**ng **Ra**nge. It is a low-energy modulation technique for radio signals. It is
thereby a core technology on which relies The Things Network. Basically, a slew of
**end-devices** can emit signal on a radio frequency using the LoRa modulation in order to be
picked up by one or several **Gateway(s)**. Therefore, it enables a huge area to be covered by
a tiny amount of gateways and in the meanwhile, it enables the network to spread across the
world. Let's paint a big picture of the network architecture and for that, we'll consider
several top-level components with which the reader (you) may want to become familiar.

![overview](/img/articles/ttn/overview.png)

To avoid any ambiguity in the document, I'll consider (and I expect the reader to also consider
it) *the network* to be the combination of **router(s)** + **broker(s)** + **handler(s)** --
handlers are not, properly said, part of the network, but stand more like bridges between the
network and application. Yet, to keep the discussion simple enough, we'll consider them as part
of it.  Therefore, the following document describes The Things Network's Architecture version 1
which aims at being a scalable, low-latency, distributed and reliable implementation of
[LoRaWAN][lorawan].

#### LoRaWAN principles

Before diving a bit more into technical concerns, we need to understand a bit some core
concepts of the LoRaWAN protocol. I will save you the time of reading the 82 pages of
specifications (I am pretty sure you know better ways to spend your Saturday). Let's get some
directly some insights without scratching too much the surface of it though.

##### Frames & Messages

Packets (or datagrams) flow throughout the network. They carry a payload surrounded by
additional pieces of information that are used to conduct this payload from a node to its final
recipient. Because payload is a rather general term to describe something carried by an
encompassing structure, in LoRaWAN, we called the end payload a *frame payload*. The network's
role is to make sure that a message received by a gateway arrives, in time, to an application.
Because LoRaWAN also allows applications to reply, the network should handle messages from
applications to devices. A message going from an end-device towards the application is called
an *uplink* message. The reply is intuitively named a *downlink*.

Besides, messages are encoded, encrypted with a specific key known by the end-devices itself
and the application to which it belongs. Providing keys to a device is called *activation* and
LoRaWAN specifies two different ways to eventually provide those keys: the Activation By
Personalization (ABP) and the Over-The-Air Activation (OTAA).

##### ABP

The ABP means that a device owns its own keys, since the beginning. They are attached to it and
are not configured in any manners. Then, on another level, applications may keep track of
which of their devices is associated to which keys. 

##### OTAA

The OTAA is a bit smarter than the ABP. Instead of holding fixed keys, devices hold the logic
that allows them to generate them alongside the network. Devices may exchange special messages
with the network to establish those keys. The network thereby becomes a mediator between
devices and applications in order to set up the initial configuration. The idea behind OTAA is
quite powerful. It allows devices to roam easily between different networks and still be able
to reach their associated application. 

#### Node
Nodes or end-devices refer to one end of the chain. End-devices emit signals using LoRa
modulation and frequency range towards Gateways. They are split into 3 classes: 

- **A**: Cannot receive any data from the network unless they've initiated the communication
- **B**: Can receive data from the network at precisely scheduled windows (Beacons)
- **C**: Can receive data at any time from the network

Incidentally, class A requires less power than B which requires less power than C.
An end-device participating in a LoRaWAN network, has a device address and a secret
device-specific application session key and network session key.
These values are either assigned by the Network or self-defined.

These specifications primarily focus on the class A. Future network versions will implement
mechanisms to handle class B and class C but they are irrelevant with the current document.

#### Gateway
Gateways might be seen as a way to transform multiple messages emitters into one much more
demanding emitter. Therefore, a Gateway gathers LoRa signals coming from a
bunch of near end-devices. A given end-device does not need to know the nearest gateways, nor it
has to communicate with a specific one - signals are simply broadcast into the wild open. 

Gateways receive signals which reach them, and forward all received messages to a dedicated Router. The
Data could be either a sensor result or a specific network command such as a connection
request. A Gateway actually sends incoming packets to a router after having wrapped each of them
into a json structure holding meta-data about the Gateway itself (such as Gateway's
identifier, a timestamp and GPS coordinates if available). Note that a Gateway will forward
packets from all LoRA Nodes in its vicinity, even if a Node is not part of the Things Network.

Gateways can also emit packets coming from the network toward a Node using the LoRa technology.
In fact, Gateways are in charge of taking care of emission at a scheduled time defined by the
network meaning that the network is able to send packets to Gateways at any moment, regardless
of their emission time. 

#### Router

Routers are entry points of the network from the Nodes perspective. Packets transmitted by Nodes are
forwarded to specific Routers from one or several Gateways. The Router then forwards those packets
to one or several Brokers. The communication is bi-directional: Routers may also
transfer packets from Broker to Gateways.

![Uplink forwarding](/img/articles/ttn/uplink_router.png)

#### Broker & Network Server

Brokers have a global vision of a network's part. They are in charge of several nodes, meaning
that they will handle packets coming from those nodes (thereby, they are able to tell to
Routers if they can handle a given packet). Several Routers may send packets coming from the
same end-device (shared by several segments / Gateways), all duplicates are processed by the
Broker and are sent to a corresponding Handler.

A Broker is thereby able to check the integrity of a received packet and is closely
communicating with a Network Server in order to administer the related end-device. For a
reference of magnitude, Brokers are designed to be in charge of a whole country or region (if
the region has enough activity to deserve a dedicated Broker). Note that while brokers are able
to verify the integrity of the packet (and therefore the identity of the end device), they are
not able to read application data.

Network servers are processing [MAC][mac] commands emitted by end-devices as well as taking care
of the data rates and the frequency of the end-devices. Network Servers would emit commands to
optimize the network by adjusting end-devices data rates / frequencies unless the node is
requesting to keep its configuration as is. 

For the moment, a single Network Server will be associated for each Broker. No communication
mechanisms between Network Servers is planned for the first version. Also, it won't be possible
for a Broker to query another Network Server than the one it has been assigned to. Those
features might be part of a second version. This implies a Broker and a Network Server are, for
an external observer, a seemingly unique component. From then on, I'll consider both of them
when referring to a broker. 

#### Handler

Handlers materialize the entry point to the network for Applications. They are secure
referees which encode and decode data coming from applications before transmitting them to a
Broker of the network. Therefore, they are in charge of handling secret applications keys and
only communicate an application id to Brokers as well as specific network session keys for each
node (described in further sections). This way, the whole chain is able to forward a packet to
the corresponding Handler without having any information about either the recipient (but a
meaningless id) or the content. 

Because a given Handler is able to decrypt the data payload of a given packet, it could also
implement mechanisms such as geolocation and send to the corresponding application some
interesting meta-data alongside the data payload. Incidentally, a handler can only decrypt
payload for packets related to applications registered to that handler. The handler is managing
several secret application session keys and it uses these to encrypt and decrypt corresponding
packet payloads.

A Handler could be either part of an application or a standalone trusty server on which
applications may register. The Things Network will provide Handlers as part of the whole network
but - and this is true for any component - anyone could create its own implementation as long
as it is compliant with TTN's architecture.

#### Application

An Application is the owner of an end device in the LoRaWAN model. Applications run outside the
Things Network core and interact with it via a handler.  As such, applications are responsible
for registering their devices with the network via a handler. If not, the device will not be
able to join The Things Network.

![Uplink to application](/img/articles/ttn/uplink_broker.png)


## Implementations remarks

Before diving into the actual logic implemented in the core components, I want to express some
thoughts about subsidiary details on the implementation. The network is a distributed,
multi-threaded, low-latency and reliable software, and this implies some extra work to wire up
all the different parts such that it seems to make no difference from within the components
themselves.  Actually, routers don't care at all about where are located brokers: Should it be
the same machine, in the same thread, it won't make any difference.  Also, all components
assumed a concurrent environment; they are intended to be used concurrently, and they seemingly
expect their dependencies not to flinch when used concurrently.

### Communication between services

From an external observer, the network is a big black box with merely two entry points
(considering only the main, expected and required features; there's actually more should one
looks at monitoring and meta-information access). 

The first set of entry points is at the bottom of the network: routers. Each router is
listening for `udp` connections on a given port. Most gateways currently being used forward
packets (partially) accordingly to the [Semtech protocol][semtech_protocol] which unfortunately
relies on `udp`. We'll discuss later on what is already planned to replace the current protocol.
Therefore, messages can be sent to the network through those `udp` connections. Eventually,
they may be forwarded to applications. 

On the other hand, the network, as we provide it currently, enables communications directly
with handlers. The need of registering devices (for either ABP or OTAA) drives the construction
of an API for the handler such that it gives users/developers a bit of control on their
nodes among the network. Because we want the communication to be as fast as possible when it
comes to nodes, most communications coming from applications are buffered and kept for later
use. Thereby, when it comes to register a device, the application let the network knows the
target, and the registration, stored, remains in stand-by until the related device shows
itself. The devices are, most of the time, the trigger which starts a set of operations within
the network. By the way, the communication between applications and TTN handlers is based on
`rpc` over `tcp`. 

![TTN Protocols - 1](/img/articles/ttn/services_1.png)

One might object the use of`rpc` between applications and handlers: even though it is a seemly
lightweight protocol, it requires an extra effort to set up as well as being quite unusual for
web developers. Nevertheless, it also glues the core components of the network, and was
therefore a natural choice for us. Moreover, we're also looking forward to getting rid of `udp`
between gateway and router, and a solution based on `rpc` could definitely enhance the
consistency and robustness of the whole infrastructure. 

![TTN Protocols - 2](/img/articles/ttn/services_2.png)

I should also point out that the use of `rpc` makes the scattering in micro-services fairly
easy. Thereby, all components are arranged in small and isolated micro-services with a tight
link to others. From a daemon perspective, it holds a direct reference to another local object
on which it might directly and synchronously call methods. Under the hood, each component only
holds a stub (a client) which presents the same interface as an external `rpc` server,
listening for `tcp` requests from other dependent micro-services. One would say the stub is a
kind of magic component which interacts with an external server by serializing the request,
unserializing the response, and taking care of handling connection establishments and
revocations whereas all of this is actually provided by the combination of [grpc][grpc] and
[protocol buffers][protobuf]. 

![TTN Protocols - 3](/img/articles/ttn/services_3.png)

As I am writing these words, we're using the version 3 of the *proto* language which is still
in a beta version of development. Although we're not making any use of new features introduced in
this major, we still want to look forward to possible evolutions; being already compatible with
the newest available version makes that move quite logical. Plus, it allows us to optimize the
speed and the efficiency of the serialization/unserialization process thanks to
[gogoprotobuf][gogoprotobuf] which provides an incredible set of features on top of *proto 3*.

Besides, while I discussed about the entry points and internal communication in the network, I
forgot to mention the network outputs. For those, because we're likely to find a highly
demanding traffic for which a reply is needed within a really short time frame; we cannot expect
and require a proportional level of availability from an application. For those reasons, using
a publish/subscribe pattern is well indicated. The network can publish regardless of
applications states while the latter can process messages at their own pace. *mqtt* is a strong
and reliable protocol which is designed to connect multiple subscribers and publishers
altogether. 

So, we end up with a bunch of micro-services, with which you can interact through `rpc` over
`tcp` and `udp` (and hopefully soon only over `tcp`) and which spit out data in `mqtt` queues.

![TTN Protocols - 4](/img/articles/ttn/services_4.png)

### Concurrent programming

I mentioned above that the application was a multi-threaded software. Since we're considering
a *Go* context within which several [goroutines][goroutines] live, I would rather talk about a
concurrent application. We've just seen that TTN is split into several micro-services which
behave as independent workers with well defined entry and output paths. Yet, this only
reflects the *distributed* facet of the infrastructure. Each worker actually divides its
workload into concurrent and parallel goroutines. It allows multiple requests to be handled
simultaneously and also gives us a bit of robustness (a single request might fail and panic
without any impact on other requests). Parallelism is not magic though. When it comes to
computers, at the very end of the chain, one is just switching a bit from 1 to 0 or 0 to 1; and
this cannot be done simultaneously by two different processes, goroutines, threads or whatever
they're called. At some point, one needs to wait and to queue up. 

How do we handle parallelism in TTN? Firstly: immutability. Secondly: immutability. And thirdly
... well, immutability? When one looks at patterns used to manage concurrent processes in a
program that might run in parallel, it always ends up to the same idea of *critical zones*.
There's no way to ensure that a memory space won't be accessed simultaneously unless you make
sure that only one actor can operate on it at a time. This is particularly mandatory when you
consider both readings from and writings into that memory space (there's no issue at all to
simultaneously read the same space; it gets more annoying when one's trying to change what
another one is trying to read). Thereby, you either create an artificial safe zone (using
semaphores or monitors, we'll come to that in a minute), or, you simply avoid having shared
memory spaces. 

If you take a quick look at TTN code base, a lot of effort has been done to avoid those
pitfalls. Almost all objects that can be instantiated are stateless components. They do not
hold any internal state; they do not mutate themselves throughout their life cycle. There's a
huge difference between those two samples:

{% highlight go %}
type Stateless struct {}

func (s Stateless) Compute(state, v int) int {
    // whatever
}
{% endhighlight %}

{% highlight go %}
type Stateful struct {
    state int
}

func (s *Stateful) Compute(v int) int {
    // whatever
}
{% endhighlight %}

The first one can safely be ran in parallel whereas the latter one needs additional internal
protections such as `mutex`. Therefore, objects in TTN are divided in two categories:

- **Operational objects**: they gather a set of methods under a same label; they are also possibly
  (and are most of time) composed of other operational objects. They do not carry any data or
  states except for configuration parameters which **don't change over time** and
  are not intended to change **ever**. They assume to be safely used concurrently and
  simultaneously without any issue.

- **Data objects**: they offer a handy way to aggregate a set of related data that can be
  manipulated by foreign methods. They do not declare any method except
  serialization and unserialization methods (marshalling and unmarshalling in the *Go*
  vocabulary) that are only used to persist those objects or to send them along remotely.
  **They're not intended to be shared by concurrent processes** but are merely a way to
  friendly pass several parameters to a local (or remote) function within the same execution
  scope of the calling process itself.

By doing this, we ensure that any operational object can be manipulated simultaneously without
the need of setting up a dedicated, restricted concurrent area. As long as they do not mutate
any internal state, they might safely be called by thousand actors at the same time. The call
itself carries all the data needed and the response illustrates the mutations operated on the
inputs. Several consecutive calls with the same inputs lead to the same outputs. There's no
mutation going on and the code is even stronger.

Notwithstanding this approach, there are still some cases where it is sometimes needed to
operate mutations on an allocated memory space. *Go* isn't a functional programming language,
hence, it doesn't offer mechanisms to totally get rid of those mutations (or more exactly,
sometimes, it doesn't fit well to its philosophy). Besides, there's one adage is *Go* that says:

> Do not communicate by sharing memory; instead, share memory by communicating.

Having this in mind, I find that **monitors** suit well in the *Go* paradigm. Monitors describe
a nice pattern to isolate a mutable piece of data from concurrent accesses by offering a façade
which can be safely accessed simultaneously and which takes care of distributing manipulations
of the underlying data it protects. Basically, in *Go*, it can be implemented really easily
using [channels][channels] and function [closures][closures]. It goes like this:

{% highlight go %}
const(
    Add Order = iota
    Sub
)   
type Order byte

func main() {
    chorder := make(chan Order)
    go monitor(chorder)
    chorder <- Add // Increase
    chorder <- Sub // Decrease
}

func monitor(chorder <-chan Order) {
    var counter uint // Variable being monitored
    for order := range chorder {
        switch order {
            case Add:
            counter++
            case Sub:
            counter--
        }
    }
}
{% endhighlight %}

There's only one goroutine that can access and mutate the `counter` variable, all other
goroutines (the original caller or another subsidiary goroutine, it doesn't matter) can then
safely require mutation by sending orders through the channel. This works well only because
channels are concurrent-safe in *Go* by design. The channel can be accessed by many goroutines,
there's still one single agent that is having control over the variable. The same solution can
be implemented with `mutex` as well (which I find most of the time a bit more inelegant). 

{% highlight go %}
type Monitor struct{
    sync.Mutex
    counter uint
}

func (m *Monitor) Add() {
    m.Lock()
    m.counter++
    m.Unlock()
}

func (m *Monitor) Sub() {
    m.Lock()
    m.counter--
    m.Unlock()
}

func main() {
    monitor := Monitor{}
    monitor.Add()
    monitor.Sub()
}
{% endhighlight %}

Choosing one or another is a matter of context. Sometimes, channels make the monitoring really
flexible and scalable whereas some other times, mutex just makes it easy to write and to
reuse. In the former, the way of communicating is being shared. In the later, that's the whole
data under protection that has to be shared. I would rather go for the solution based on
channels as I find it less error-prone and quite effortless to reason about: the data is only
manipulated by one agent which is just processing orders sequentially whenever it can. By the
way, by using buffered channels, it can also be made completely asynchronous. 

### In-memory storage

If it wasn't clear enough, we're going to explore the four points I stated in introduction of
this section. Should you have followed it correctly, we primarly talked about the *distributed*
aspect of TTN before dealing with the *concurrent* one. Let's now glance at the *low-latency*
facet of it. The network, as specified by LoRaWAN should process a message within a short time
frame. Technically, LoRaWAN allows the network to configure the frame's size but let's assume a
default configuration setup and consider that we have to process a packet (ideally) within a
second. The processing is distributed among several agents and it already takes time to
transfer data from one to another. Incidentally, all those agents also have to persist pieces
of information and get them back when times arrive. 

It feels rather natural to guarantee a high availability on each storage. Furthermore, the
network doesn't have a complicated and evolved database scheme. What is needed is merely a map
which links a given key to one or several entries. Deploying an `sql` server would be effective
yet not efficient. Even though solutions like [Redis][redis] or [levelDB][leveldb] grasped our
interest at first (they are tried and tested in-memory databases), we eventually turn towards
[boltDB][boltdb] which is a robust *Go* in-memory storage. Three essential reasons drive that
choice:

- Bolt's design is extremely simple: it maps keys (raw sequence of bytes) to values (raw
  sequence of bytes as well). 

- Despite its relatively poor performances for writing, Bolt is fast enough for reading. The
  network experiences way more lookups than updates, hence Bolt.

- Bolt is written in *Go* and offers a wonderful *Go* library, completely effortless for us to
  use.

![In-memory backend performances comparison](/img/articles/ttn/chart_db.png)

There's still one downside about using Bolt. We cannot (at least directly) manipulate the
storage from a cluster of components. For instance, this entails one router is bound to one
database. Should we want to deploy a cluster of routers behind a balancer which all share the 
same storage, we need to build all the necessary mechanisms on top of Bolt (mechanisms that are
already included in tools like Redis). 
There's nevertheless nothing wrong in evolving from Bolt to something else. One can even plug
an extra backend manager like [LedisDB][ledisdb] which would extend Bolt's functionality to
enable a distributed processing through cluster. Moving from Bolt to Redis is also a realistic
option. 

### Testing strategy

I remember when I first heard about interfaces in *OO*, it sounded extremely weird to me. Then
one day, I tried to test a piece of software and all of a sudden I realized for what interfaces
were useful. By the by, almost everything in *Go* is about interacting with interfaces. They
are implicitely implemented in the language and rather straightforward to declare. Once the
code is built with them, it becomes a deeply and easily testable application, mostly because
one is able to mock real entities with something on which the tester has a huge control. I
previously explained how components (or operational objects) were solely composed of other
operational objects though I didn't mentioned that all dependencies were injected during the
component instantiation such that it's seemingly possible to declare a component full of fake
internal components. 

{% highlight go %}
// Actual interface
type MyInterface interface{
    MyMethod(arg1 int, arg2 string) (int, error)
}

// Mock type
type MockMyInterface struct {
    InMyMethod struct {
        Arg1 int
        Arg2 string
    }
    OutMyMethod struct {
        Value int
        Error error
    }
}

// MyMethod implements the MyInterface interface
func (m *MockMyInterface) MyMethod(arg1 int, arg2 string) (int, error) {
    m.InMyMethod.Arg1 = arg1
    m.InMyMethod.Arg2 = arg2
    return m.OutMyMethod.Value, m.OutMyMethod.Error
}
{% endhighlight %}

We consistently adopt the same strategy for each entity. We want to be able to drive each
component the way we want: make them return a specific value or make them fail on demand.
Sometimes, knowing the callee's arguments is worth it. The snippet above shows how every mock
has been implemented and the general principle behind them. During testing, it's then
under the tester responsability to provide the desired output to analyse the behaviour of the
tested component.

While looking at the mock's structure, it seems rather obvious that the whole code could be
generated. Interfaces are likely to evolve over time and even though it does't require a lot of
time to write or rewrite all corresponding mock interfaces, it's still constitute time and
effort that could be put into something else. Plus, once a generator has been proven, it saves
a lot of unit tests and globally enhance the reliability of the application by removing codes.
The least code one writes, the least bugs one's likely to introduce. 

In the same idea, all the code needed to serialize and unserialize objects is remarkably
similar. Moreover, it constitutes a critical part of the software: it needs to run quickly. To
avoid repetitions, one is likely lured into a nice design which uses composition and / or
inheritance patterns albeit this has a significant impact on performances. Another approach is
to simply avoid writing this kind of code, and have it generated by a trusted library (so is
*protobuf*). As a result, a lot of code in TTN is automatically generated. I see this as a mark
of reliability. It's less code to write, less code to maintain and less code to test. All of
this makes us really focus on the core logic during testing. The next diagram gives an order of
magnitude of the code's distribution, might it be generated or manually written.

![Code Distribution](/img/articles/ttn/code_distribution.png)

## Components implementation

In this section, I want to explore of what the network core logic is really made. This implies
to take each component and to look under the hood. During the introduction, I gave a general
overview of the whole architecture. The next lines aim more at describing technically the
implementation and the solutions adopted. 

### Semtech Adapter
The network starts with the Semtech adapter which receive and process `udp` datagrams sent by
gateways. As it was stated above, the Router is merely an `rpc` server and thus, listens to
`tcp` requests using an appropriate transport scheme and protocol. This adapter stands as a
bridge between the external world and the network. Indeed, we have less control on the
protocols defined in gateways' firmware than on the network itself. The Semtech adapter enables
a clear separation between the network core logic and the gateways such that we can totally
change gateways protocol without any impact on the internal business logic.

Therefore, it abstracts the Semtech protocol by taking care of replying accordingly to uplink
datagrams: should you glance at the semtech protocol, you'll notice that it defines a mechanism
to keep a connection open (by nature, `udp` connections are not kept open and because routers
might not be able to contact gateways directly, the connection needs to stay available during
the whole communication). Those details have nothing to do with the network itself and
shouldn't be considired in the router. What really matters for the router are the actual uplink
data or join-request, out of any `udp` context. The Semtech adapter is precisely playing that
role, making sure the router is bothered only by actual TTN packets. 

Looking at the code, we can split it in three global parts. First of all, the `udp` server
itself: the adapter plays the role of a server, listening to a specific port on which gateways
can establish connections and send datagrams. 

{% highlight go %}
func listen(netAddr string, conn *net.UDPConn) {
    for {
        // 1. Read from connection
        // 1.1 In case of error, try to reconnect (exponential backoff-like algorithm)
        go func(data []byte, conn *net.UDPConn) {
            // 2.1 Unmarshal Semtech packet
            // 2.2 Update connections pool
            // 2.3 Handle packet as PULL_DATA or PUSH_DATA
        }(data, conn)
    }
}
{% endhighlight %}

Then, we handle packets as they arrive using five different methods. The first two methods use
they three other to carry their tasks. In fact, an incoming uplink datagrams might contain more
than one payload meaning that a single transfer between a gateway and a router is likely to
lead to several uplink network packets (possibly of different natures). To make it clear, all
calls have just been distributed among the following methods:

- **handlePushData()**: Processes a Semtech datagram and call **handleUp** for each rxpk
  packets carried by the Semtech datagram

- **handlePullData()**: Acknowledges a Semtech `PULL_DATA` datagram

- **handleUp()**: Processes an actual network packet which could be either a
  confirmed/unconfirmed data or a join request.

- **handleDataDown()**: Analyses an **handleUp** response in case where the packet carried an
  uplink data

- **handleJoinAccept()**: Analyses an **handleUp** response in case where the packet carried a
  join request.

As a result, those methods wire up Semtech datagrams to the network. They eventually use
conversion method which interpret either a rxpk Semtech packet and translate it to a
corresponding network packet, or in the othr way around, interpret a network packet and
translate it to a txpk packet. 
We thereby defined two methods **toLoRaWANPayload** and **newTXPK** to operate the wiring.
Because each packet comes alongside some metadata, one also needs to transfer and convert
metadata. Those pieces of information evolve with the development and thus, we need reflection
to read from and insert into the corresponding source / target. The Semtech package uses
pointer fields to make a difference between zero-typed fields and undefined types (because in
*Go*, any variable is initialized with its default zero-value which makes impossible to know
whether a variable refers to an uninitialized data). Nevertheless, using `gRPC` forces all
internal metadata to be plain types (no pointer here). Field names are aslo not likely to match
albeit they are rather similar. We deal with this concern by using *Go*
[struct-tags][structtags].  Hence, for instance, to inject metadata from a network packet to a
txpk packet, we use the following small though not straightforward piece of code:

{% highlight go %}
func injectMetadata(xpk interface{}, src interface{}) interface{} {
	m := reflect.ValueOf(src)
	x := reflect.ValueOf(xpk).Elem()
	tx := x.Type()

	for i := 0; i < tx.NumField(); i++ {
		t := tx.Field(i).Tag.Get("full")
		f := m.FieldByName(t)
		if f.IsValid() && f.Interface() != reflect.Zero(f.Type()).Interface() {
			p := reflect.New(f.Type())
			p.Elem().Set(f)
			if p.Type().AssignableTo(x.Field(i).Type()) {
				x.Field(i).Set(p)
			}
		}
	}

	return xpk
}
{% endhighlight %}

### Router

![Router illustrated](/img/articles/ttn/router.png)

The router's role is fondamentally what we could expect from a load-balancer. It redirects the
traffic to the appropriate recipient. At this stage, the network merely knows the device
address associated to the packet (which is likely to conflict with another address). In the
meanwhile, routers also monitor gateways: they process status packet from gateways and keep
track of the time-on-air spent by each transmitter. They distill these pieces of information and
communicate only the bare minimum to the rest of the chain.

A router is split into three main parts that are quite close. They actually have been separated
to enhance readibility and clarity. Here's what it looks like:

{% highlight go %}
func HandleStats(request) (response, error) {
    // 1. Validate request
    // 2. Update gateway statistics
}

func HandleJoin(request) (response, error) {
    // 1. Validate request
    // 2. Add gateways statistics to request
    // 3. Broadcast the request
    // 4. Update gateway statistics
    // 5. Forward response to semtech adapter
}

func HandleData(request) (response, error) {
    // 1. Validate request
    // 2. Add gateways statistics to request
    // 3. Lookup known brokers for corresponding device address
    // 4. Forward (if some brokers has been found) or broadcast the request
    // 5. In case of broadcasting, store any broker that acknowledges the request
    // 6. Update gateway statistics
    // 7. Forward the response, if any, to semtech adapter
}
{% endhighlight %}

The router is really straightforward. Its implementation has been kept short and simple. Almost
all the logic has been put in the *duty cycle Manager* and in the *Broker* such that we consider
the router only as a transition component which filters and redirects incoming messages.  

### Duty cycle manager
Because of band usage regulation per region (US, Europe, China ...), the network has to monitor
its outputs to make sure that the different transmitters don't exceed limits defined by the
authorities. The duty cycle manager precisely serves this purpose. It keeps track of
transmitters and give an indication of a sub-band usage over time. 

Before any further computation, the managers expects to be configured with a set of sub-bands
and a corresponding set of maximum duty cycles. Then, given a frequency in `MHz`, a payload size
in number of bytes a data rate identifier and coding rate identifier, it can compute the
time-on-air required to transfer a message. 

By the by, the duty cycle is a ratio which illustrates, for a given logical signal, whether the
signal is up or down. For instance, a duty cycle of `0.5` indicates that 50% of the time, the
signal is up (or down, as you wish). This implies an idea of time or more exactly, an idea of
duration. What is actually computed by the manager is a duty cycle throughout a fixed interval
of time (the duty cycle is therefore an average duty cycle over that interval). As soon as one
considers a fixed interval, then, given a maximum duty cycle, one can compute the amount of time
allocated for that period. 

Considering an interval of one hour, with a maximum duty cycle of `1%`, we end up with `36s` of
availability each hour. If a transmitter reaches this limit in its first ten minutes, it
would wait for fifty minutes before being allowed to transmit again. Limitations vary with the
considered sub-band, and sub-bands vary with the world region in which the transmitter is
located. 

![duty cycles illustrated](/img/articles/ttn/dutycycle.png)

For a given transmitter, the manager indicates the transmitter usage with a percentage
(ideally, a number between `0` and `100`, seldom above `100` should the transmitter breaks the
limit). Because we don't really need that granularity yet, we only consider four different
states for transmitter on a given sub-band:

- **Blocked:** usage is greater or equal to 100
- **Critical:** usage is above 85 but still lower than 100
- **Available:** usage is between 30 and 85
- **Highly available:** usage is lower than 30

Using these states, a signal noise ratio, and a signal strength, it is possible to compute a
score for a given transmission. In a practical use case, a node emits a message on a frequency;
that message might be caught by several gateways which will all forward the signal to the
routers to which they are connected. At some point, all the messages get dispatched to one
single handler. As a consequence, to each message is associated a given transmitter (gateway),
and only one of them shall be used for a hypothetical reply. In practice, the handler uses the
duty cycle manager to compute a score based on each message's metadata. The priority is given to
the transmitter state, then to the signal noise ratio and finally to the signal strength. The
heuristic is extremely simple and is just used to sort transmitters at different stages, using
those criteria. 

### Broker
Similarly to how the router is designed, the TTN broker is merely a `tcp` server (or more
exactly, two `tcp` servers running side-by-side; this allows a decoupling between network and
monitoring communications). It offers two remote methods to handle data uplinks and join
requests. In addition, the broker also manages applications and, for this purpose, relies on
oAuth 2.0 protocol. Indeed, the broker might receive orders from an application (a handler
being used to mediate the transmission) for which it would expect an identification token to be
sent alongside. The broker is eventually linked to an in-memory local storage in which it can
store information about applications and running end-devices.

The broker handles data and join-request in a similar fashion, considering the following
pseudo-code:

{% highlight go %}
func HandleData(request) (response, error) {
    // 1. Validate request
    // 2. Retrieve associated entries, if any
    for entry := range entries {
        // 3.1 Evaluate frame counter as a 16-bit counter
        // 3.2 Check MIC
        // 3.2.1 If MIC fails, evaluate frame counter as a 32-bit counter and check again
        // 3.3 If MIC check succeed, consider this entry and move along
    }
    // 4. Update the frame counter associated to the device found
    // 5. Forward the request to the corresponding handler
    // 6. Analyze the response; if any, set the MIC and forward it to the router
}

func HandleJoin(request) (response, error) {
    // 1. Validate request
    // 2. Retrieve previously used devNonce
    // 3. Check whether the devNonce has already been used
    // 4. Forward the request to the appropriated handler
    // 5. Analyze the response; if any, store the session keys and the devNonce used
}
{% endhighlight %}

Next to that, the broker is also used as a remote authority to control management operation on
devices and applications. Each broker is able to verify the legitimacy of a request which
provides a bearer token. As a matter of fact, the broker is in tight communication with a token
provider, the same one that authenticates a user of an application by providing a valid token.
Although applications don't interact directly with brokers, they can emit request through a
handler which will forward them on their behalf to an associated broker. The scheme is merely a
close loop of communication where at the end, the broker ends up asking the token provider
whether a user request shall be granted. 

![](/img/articles/ttn/broker.png)

### Handler
Last component properly said of the network infrastructure, the handler is responsible for
making the life of applications easier. It should be clear though that many 
implementations of handlers might exist, I am going to argue about the "official" one TTN
provides as an illustration of *what could be* a handler. Again, handlers simplify
applications' job yet the latter are likely to have different needs. We'll hereby call handler
the TTN handler in the next lines.

The handler is a rather complicated set of intrinsic communications. It has indeed to buffer
and temporize the processing of packets. All packets are forwaded and carried by other network
components but because several gateways might transfer a received datagram originally, we need
to catch them all and deduplicate the whole bundle in the handler. To carry out such a task, it
defines two internal sub-processes **consumeSet** (C1) and **consumeBundles** (C2) which runs
independently in their own goroutine. The former actually buffer an incoming packet into a
queue and set an alarm since the first reception. The latter is triggered once a set of packets
is ready to be processed (meaning, once the alarm previously set rang). Most of the business
logic is located in the **consumeBundles** process in charge of deduplicating the request and
publishing the result.

The handler also defines, like other core components, `rpc` methods intended to be called
remotely. These methods work in pair with the two sub-processes which, by taking advantage of
*Go* channels' nature, enables a synchronous and quite straightforward operation. For instance:

{% highlight go %}
func HandleDataUp(request) (response, error) {
    // 1. Validate request
    // 2. Retrieve device data from AppEUI + DevEUI
    // 3. Wrap packet into a "bundle" and set a new uplink entry
    // 4. Wait for the bundle to be processed
    // 5. If any, forward the response to the broker 
}
{% endhighlight %}

What is called *bundle* is actually a super-set of an uplink packet (or similarly, a
join-request). As well as holding the packet itself and a unique identifier, the bundle also
carries a channel that should be used to reply to the routine that is processing the uplink
(and this is incidentally where the **HandleDataUp** and **HandleJoin** magically become
synchronous methods). 

![](/img/articles/ttn/handler.png)

For class A devices, LoRaWAN also allows the application to reply to an uplink. However,
carrying a datagram from a gateway up to the application already requires time. Moreover, if a
downlink has to be sent, it should be within a second (considering one started to count since a
datagram reaches a gateway), or maybe two seconds should we target the second response window.
That's a short time frame, and applications aren't likely to provide such a level of
availability. In order to cope with this issue, we allow applications to "schedule" downlink for
a specific device. Indeed, one can push a perishable packet into a queue. When appropriated,
the handler might grab one from the queue and use it as the response's frame payload. Beside, in
case where no packet has been scheduled but a response is nonetheless needed (most likely because
the uplink packet was a *Confirmed Data Up*), the handler will generate a response carrying an
empty frame payload. 

By the by, the handler is also in charge of encrypting and decrypting either frame payloads or
join-accept responses. It is incidentally holding application private keys and is able to (has
to) generate new session keys on each join-request. By dealing with these tasks, the handler
becomes a rather complicated component: loads of operations require access to session keys
hence being the only bearer necessarily empowers it as well as makes it a major point of
business logic. Although it was originally designed to serve applications with a low coupling
to the network, the handler has become an important piece of software on which key elements now
rely. We're looking forward to moving as much logic as possible in the broker and the router.
This way, the broker would remain the only heavy component of the network. 

### MQTT Adapter

Last piece of the network, the `mqtt` adapter has a similar role to the semtech adapter
previously presented. It enables the communication between the network and an `mqtt` broker in
such a way that it is transparent for the network. Again, we're here using `rpc` to deal with
this problem. I'll not dive into the `mqtt` protocol; it wouldn't be relevant at all. The
adapter is straightforward and merely describe two remote methods `HandleData` and
`HandleJoin`. Under the hood, it's just a way for the handler to publish messages on `mqtt`
topics without having to deal with the topics itself. 

## Looking ahead

The network is still in its early stages. We're now on the verge of opening the staging
environment to the wild world. It doesn't contain all the expected features though. Some work
is still required to handle `mac` commands as defined in LoRaWAN. Also, as we built the
network, we noticed issues and improvement that could be made on the original architecture. Our
mission is now to make it easy to use and safe for users and developers. We're thereby striving
to provide as many services as we can while in the meanwhile, we work hard on improving the
quality of the existing network. In the nineties, they were building the Internet. Now, we put
all out efforts into building the Internet Of Things. 

[lorawan]: https://www.lora-alliance.org/portals/0/specs/LoRaWAN%20Specification%201R0.pdf
[semtech_protocol]: https://github.com/TheThingsNetwork/ttn/blob/develop/documents/protocols/semtech.pdf
[grpc]: http://www.grpc.io/
[protobuf]: https://developers.google.com/protocol-buffers/
[gogoprotobuf]: http://gogo.github.io/doc/
[goroutines]: http://blog.nindalf.com/how-goroutines-work
[channels]: https://gobyexample.com/channels
[closures]: https://gobyexample.com/closures
[redis]: http://redis.io/
[ledisdb]: http://ledisdb.com/
[leveldb]: http://leveldb.org/
[boltdb]: https://github.com/boltdb/bolt
[structtags]: https://golang.org/pkg/reflect/#StructTag
[raspberry]: https://www.raspberrypi.org/
[arpanet]: https://en.wikipedia.org/wiki/ARPANET
[iotstack]: https://www.micrium.com/iot/internet-protocols/
[lora]: https://www.lora-alliance.org/What-Is-LoRa/Technology
[mac]: https://en.wikipedia.org/wiki/Media_access_control
