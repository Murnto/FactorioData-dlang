import vibe.d;
import std.stdio;
import std.path;
import std.string;
import std.regex;
import std.file;
import std.math;
import std.algorithm : sort, map;

import jsonizer.fromjson;
import webpackdata;
import factoratio;
import fact_pack;

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

void route_pack(WebPackdata pd, URLRouter router)
{
    void display_item(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string type = req.params["type"];
        const string name = req.params["name"];

        // Craftable* cft = pd.find_craftable(type, name);
        const Craftable* cft = pd.resolve_craftable(type, name);

        if (cft)
        {
            const string title = cft.title;
            return res.render!("item.dt", req, pd, cft, round, title);
        }
        const string title = "Error";
        res.render!("error.dt", req, pd, title);
    }

    void send_icon(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string type = req.params["type"];
        const string name = req.params["name"];

        const string absPath = absolutePath(buildPath(pd.path, "icon"));
        const string imgPath = absolutePath(buildPath(pd.path, "icon", type, name));

        if (indexOf(name, ".png") + 4 != name.length || matchFirst(name,
                r"[$%?/&]|\.\.") || matchFirst(type, r"[$%?\./&]") || indexOf(imgPath,
                absPath) != 0)
        {
            const string title = "Error";
            return res.render!("error.dt", req, pd, title);
        }
        sendFile(req, res, Path(imgPath));
    }

    void api_popup(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        string type = req.params["type"];
        string name = req.params["name"];

        Craftable* cft = pd.resolve_craftable(type, name);

        if (cft)
        {
            Recipe* chosen_recipe = pd.get_first_recipe_with_ingredients(cft);

            if (chosen_recipe !is null)
            {
                return res.render!("popup/item_popup.dt", req, pd, cft, chosen_recipe);
            }
        }
        const string title = "No craftable";
        return res.render!("popup/no_craft.dt", req, pd, title);
    }

    void tech_list(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Technology";
        return res.render!("tech_list.dt", req, pd, title);
    }

    void technology(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string name = req.params["name"];

        Technology* tech = name in pd.technology;

        if (tech)
        {
            const string title = tech.title;
            return res.render!("technology.dt", req, pd, tech, title);
        }
        const string title = "Error";
        return res.render!("error.dt", req, pd, title);
    }

    void item_search(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = pd.meta.title;
        return res.render!("item_search.dt", req, pd, title);
    }

    void api_item_search(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        string name = req.params["name"];

        Craftable*[] results = pd.search_craftable(name);

        Json[] json_results;

        foreach (cft; results)
        {
            json_results ~= Json(["name" : Json(cft.name),
                "type" : Json(cft.type), "title" : Json(cft.title)]);
        }

        res.writeJsonBody(json_results);
    }

    void debug_index(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Recipes";
        return res.render!("debug/debug_index.dt", req, pd, title);
    }

    void recipe_list(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Recipes";
        const Recipe[] cftecipes = pd.recipes.values;
        return res.render!("debug/tmp_all_recipes.dt", req, pd, title, cftecipes);
    }

    void item_cats_list(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Item Categories";
        const CDContainer[] itemcats = pd.enumerateCategoryData().values();
        return res.render!("item_cats_list.dt", req, pd, title, itemcats);
    }

    void item_category(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        string name = req.params["name"];
        CDContainer* itemcat = name in pd.enumerateCategoryData();

        if (itemcat)
        {
            const string title = itemcat.title;
            return res.render!("item_category.dt", req, pd, title, itemcat);
        }

        const string title = "Error";
        return res.render!("error.dt", req, pd, title);
    }

    void recipe_cat_list(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Recipe Categories";
        const auto catMap = pd.craftCategoryMap;
        return res.render!("recipe_cat_list.dt", req, pd, title, catMap);
    }

    void recipe_category(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        string name = req.params["name"];
        AssemblingMachine[]* machines = name in pd.craftCategoryMap;

        if (machines && machines.length)
        {
            const string title = name;
            return res.render!("recipe_category.dt", req, pd, title, machines);
        }

        const string title = "Error";
        return res.render!("error.dt", req, pd, title);
    }

    void all_popups(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Popups";
        Craftable*[] craftables;

        foreach (ref string cat; pd.all_items.keys)
        {
            foreach (ref Craftable item; pd.all_items[cat])
            {
                craftables ~= &item;
            }
        }

        return res.render!("debug/all_popups.dt", req, pd, title, craftables);
    }

    void pack_redir(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        res.redirect(pd.meta.name ~ "/");
    }

    void about_pack(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Pack information";
        return res.render!("pack_infos.dt", req, pd, title);
    }

    auto packroute = new URLRouter("/pack/" ~ pd.meta.name);
    router.get("/pack/" ~ pd.meta.name, &pack_redir);
    router.get("/pack/" ~ pd.meta.name ~ "/*", packroute);
    pd.router = packroute;

    // router.get("/pack/" ~ pd.meta.name, &item_search);
    packroute.get("/", &item_search);
    packroute.get("/info", &about_pack);
    packroute.get("/icon/:type/:name", &send_icon);
    packroute.get("/i/:type/:name", &display_item);
    packroute.get("/tech", &tech_list);
    packroute.get("/tech/:name", &technology);
    packroute.get("/api/popup/:type/:name", &api_popup);
    packroute.get("/api/find/:name", &api_item_search);
    packroute.get("/itemcats", &item_cats_list);
    packroute.get("/itemcats/:name", &item_category);
    packroute.get("/recipecat", &recipe_cat_list);
    packroute.get("/recipecat/:name", &recipe_category);
    packroute.get("/debug", &debug_index);
    packroute.get("/debug/all_recipes", &recipe_list);
    packroute.get("/debug/all_popups", &all_popups);

    init_factoratio(pd, packroute);
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
        "/home/dave/dev/factorio/pack/base-f12/",
        "/home/dave/dev/factorio/pack/base-f13/", // "/home/dave/dev/factorio/pack/dytech-f12/",
        "/home/dave/dev/factorio/pack/5dim-f12/",
        "/home/dave/dev/factorio/pack/bobmods-f12/",
        "/home/dave/dev/factorio/pack/mopack-f12/",
        "/home/dave/dev/factorio/pack/yuoki-f12/", "/home/dave/dev/factorio/pack/yuoki-f12-a/",
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
    router.get("/", &index);
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
