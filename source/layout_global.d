import std.file;
import std.path;
import std.string;

import std.stdio;

string commitShort;
string analytics = "<script>(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)})(window,document,'script','//www.google-analytics.com/analytics.js','ga');ga('create', 'UA-63813475-1', 'auto');ga('send', 'pageview');</script>";

private string getCommitLong()
{
    immutable string headPath = ".git/HEAD";

    if (isFile(headPath))
    {
        const string refHead = ".git/" ~ chomp(readText(headPath)).split(" ")[1];

        if (isFile(refHead))
        {
            return chomp(readText(refHead));
        }
    }
    return null;
}

private string getCommitShort()
{
    return getCommitLong()[0 .. 7];
}

static this()
{
    commitShort = getCommitShort();
}
