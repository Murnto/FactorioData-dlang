import vibe.d;
import std.stdio;
import std.path;
import std.regex;
import std.file;
import std.algorithm : sort;

import jsonizer.fromjson;
import webpackdata;
import routes : route_pack;

private WebPackdata[string] packs;
private WebPackdata[] sorted_packs;

void index(HTTPServerRequest req, HTTPServerResponse res)
{
    WebPackdata pd = null;
    const string title = "FactorioData";
    res.render!("index.dt", req, pd, title);
}

void packs_index(HTTPServerRequest req, HTTPServerResponse res)
{
    WebPackdata pd = null;
    const string title = "Configurations";
    res.render!("packs_index.dt", req, pd, title, sorted_packs);
}

void dump_all_routes(URLRouter router)
{
    foreach (ref r; router.getAllRoutes)
    {
        if (indexOf(r.pattern, ":") == -1 && indexOf(r.pattern, '*') == -1)
        {
            writeln(r.method, " | ", r.pattern);
        }
    }
    foreach (ref pd; packs)
    {
        foreach (ref r; pd.router.getAllRoutes)
        {
            if (indexOf(r.pattern, ":") == -1 && indexOf(r.pattern, '*') == -1)
            {
                writeln(r.method, " | ", "/pack/" ~ pd.meta.name ~ r.pattern);
            }
        }
    }
}

void load_static_packs(URLRouter router)
{
    auto pack_directories = [
        "pack/base-f13/", "pack/base-f12/", "pack/base-f11/"
    ];

    foreach (pack; pack_directories)
    {
        auto pd = new WebPackdata(pack);
        route_pack(pd, router);

        packs[pd.meta.name] = pd;
    }
}

auto create_redirect(const string from, const string to)
{
    void pack_link_redir(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string dest = replaceFirst(req.path,
            regex("/pack/" ~ from ~ "(/|$)"), "/pack/" ~ to ~ "/");
        return res.redirect(dest);
    }

    return &pack_link_redir;
}

void load_dynamic_packs(URLRouter router, const string pack_dir)
{
    foreach (ref DirEntry f; dirEntries(pack_dir, SpanMode.shallow))
    {
        if (f.isFile)
        {
            const string from = baseName(f);
            scope string redir = chomp(readText(f));
            writeln("Redirect ", from, " to ", redir);

            router.get("/pack/" ~ from, create_redirect(from, redir));
            router.get("/pack/" ~ from ~ "/*", create_redirect(from, redir));
        }
        else if (f.isDir)
        {
            StopWatch sw;
            sw.start();
            auto pd = new WebPackdata(f.name ~ "/");
            route_pack(pd, router);

            packs[pd.meta.name] = pd;
            sw.stop();

            writeln("Loaded ", f, " in ", sw.peek().msecs, " ms");
        }
    }
}

shared static this()
{
    auto router = new URLRouter;
    router.get("/", &packs_index);
    router.get("/pack", &packs_index);
    router.get("/pack/", &packs_index);

    load_dynamic_packs(router, "pack");

    sorted_packs = array(sort!"a.meta.title < b.meta.title"(packs.values));

    router.get("*", serveStaticFiles("public/"));

    auto settings = new HTTPServerSettings;
    settings.bindAddresses = ["127.0.0.1"];
    settings.port = 8080;

    // dump_all_routes(router);

    listenHTTP(settings, router);
}
