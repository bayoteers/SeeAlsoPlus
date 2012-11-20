SeeAlsoPlus Bugzilla Extension
==============================

Extension to provide additional info about the remote items referenced by the
"see also" URLs on bugs. Aimed to replace existing EnhancedSeeAlso extension.


Key features
------------

*   Caching of the remote data
*   Easily extensible to support other than bugzilla URLs
*   Web service method to get the remote data


Installation
------------

This extension requires [BayotBase](https://github.com/bayoteers/BayotBase)
extension, so install it first.

1.  Put extension files in

        extensions/SeeAlsoPlus

2.  Run checksetup.pl

3.  Restart your webserver if needed (for exmple when running under mod-perl)


TODO
----

*   Support for other than Bugzilla URLs

    *   Debian bug support.
        Parsing the data from bugs.debian.org might be a bit difficult...
    *   Google code support. 
        See [API](http://code.google.com/p/support/wiki/IssueTrackerAPI)
    *   JIRA support.
        See [API](http://docs.atlassian.com/jira/REST/latest/)
    *   Launcpad support.
        See [API](https://help.launchpad.net/API/)
    *   MantisBT support.
        Provides some kind of SOAP API...
    *   SourceForge support.
        See [API](http://sourceforge.net/apps/trac/sourceforge/wiki/API)
    *   Trac support.
        Maybe use the [CSV format](http://trac.edgewall.org/ticket/10855?format=csv)
    *   Github support (comming to seealso in bz 4.4).
        See [API](http://developer.github.com/v3/issues/)

*   Blacklisting of remote sources.
*   Authentication support.
