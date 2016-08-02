import std.file;
import std.path;
import std.string;

import std.stdio;

string commitShort;
string analytics = "";

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
