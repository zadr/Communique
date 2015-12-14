Hi.

Communiqué is an experiment. It's a Twitter app that only lets you use direct messages. It supports logging into a twitter account, viewing direct messages, and replying to them. If you receive spam messages, want to block someone, or change your mind about sending a message and want to delete it, you can do that as well. 

Under the hood, Communiqué supports multiple accounts, but no UI exists for this. Likewise, the bits to support loading more than 200 direct messages exist, but, Communiqué doesn't actively make use of it.

There's a lot of of hacks and bad code in here. Some of it is annotated with `// WARNING:`, but even more of it exists without any heads up. For example, most things that gets `.unique()` applied can probably be considered a hack. Caveat programmer.

You'll need your own Twitter API consumer key and consumer secret for the app to do anything. Once you have them, fill in the constants at the top of Twitter.swift.

All code that's mine to license (everything in the Communiqué/ folder) is released under a 2-clause BSD license.

The networking layer is built on top of [STTwitter](https://github.com/nst/STTwitter) (found in STTwitter/), although, I forgot to keep track of what version it uses. STTwitter is made available under a 3-clause BSD license. Any modifications I've made are released under the same license.

Although I don't see this as a project to be worked on for a long time, any contributors should follow the Contributor Code of Conduct, v1.3.0: http://contributor-covenant.org/version/1/3/0/

And finally, there are no screenshots available, because I'm not sharing my private chat with the entire internet. I like to think that Communiqué looks okay for what it is, though.
