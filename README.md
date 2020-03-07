vIRCd (Veachian Internet Relay Chat Daemon) is an IRC server written in Perl (old Perl from 2001, circa version 5.6.1). As the original README states, it was a way for me to learn some Perl and do something interesting in the process. Most notably, since I developed vIRCd on Windows, I wasn't able to get threads working, so the server uses a synchronous messaging queue for handling all the input and output.

I wrote it 10 years ago in 2001, back when I was a high school freshman, and hadn't really thought about it until now when, while Googling my name, I stumbled upon this old Perl Monks thread I made about it: http://www.perlmonks.org/?node_id=155351

![merlyn](https://github.com/v64/vircd/raw/master/merlyn.png)

Randal Schwartz (yes, that one) chided me about the post, saying the links to my personal website for a tarball of the source were pointless since the links could disappear at any moment, and that I should've made a CPAN module instead.

Good advice, but for what it's worth, I still maintain the hyperlinks to this day. And to one up that, I'm now putting the development history of vIRCd on GitHub for further posterity.

As the original README states, this project is in the public domain, so do what you will with it.

Original README:

This is the Veachian Internet Relay Chat Daemon (vIRCd), an IRC server written in Perl
simply as a proof of concept project. It was written after I discovered the Perl IRC Daemon
(http://pircd.sourceforge.net/) and found out it didn't work on Windows. So out of
sheer boredom I wrote it. It's in no way meant to be complete or even stable. It was
just a way for me to learn more about Perl and discover a few new things along the way.

This code is being put in the public domain. You can use it for anything you want and not
worry about copyrights or anything else that might cause ya to get sued. However I'm not
responsible for anything this program does so you use it at your own risk. In other words
if you break it, you get to keep the pieces. The code is split up into different versions, 
which I simply did so I'd have something to start over on in case I totally broke the
code I was working on. The previous versions are made available so you can see how the code
evolved and to see the failed implementations of certain functions. The versions skip from 0.15
to 0.20 because I did a major code change between them. In 0.20, the numeric lookup subroutine
(send_user_msg_num) uses a hash (%numstr) instead of a big if statement, which is pretty much faster.
This was done for process_command in 0.22. Also in 0.22, %fhs was merged into %users, breaking the
serv_online() function.

vircd.motd is a semi-informative message of the day file containing some info that I decided to
throw in. data_structs.txt contains some info on the hash, but some of it may be incomplete or
inaccurate.

Like I said this isn't meant to be stable or complete. It's just here for you to do
whatever you want with it.

Happy coding,

Jahn Veach (Veachian64)

V64@V64.net

www.v64.net
