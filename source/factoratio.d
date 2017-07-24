import std.string : translate;
import std.json;
import std.math : round;

import vibe.d;
import vibe.data.json;
import jsonizer;

import webpackdata;
import fact_pack;
import fact_pack.json_utils;

void init_factoratio(WebPackdata pd, URLRouter router)
{
    void resources_js(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        Json resp_json = Json.emptyObject;

        foreach (const ref Resource r; pd.resources)
        {
            Json obj = Json.emptyObject;
            const string ratio_id = translate(r.name, ['-' : '_']);

            obj["id"] = ratio_id;
            obj["name"] = r.title;
            obj["category"] = r.category;
            if (r.minable)
            {
                obj["miningTime"] = Json(round(r.mining_time * 1000) / 1000);
                obj["hardness"] = Json(round(r.hardness * 1000) / 1000);
            }

            resp_json[ratio_id] = obj;
        }

        foreach (const ref Fluid f; pd.fluids)
        {
            Json obj = Json.emptyObject;
            const string ratio_id = translate(f.name, ['-' : '_']);

            obj["id"] = ratio_id;
            obj["name"] = f.title;
            obj["category"] = "fluid";

            resp_json[ratio_id] = obj;
        }

        res.writeBody("resources = " ~ serializeToJsonString(resp_json) ~ ";");
    }

    Json create_recipe_obj(const ref Recipe r, string obj_id)
    {
        Json obj = Json.emptyObject;

        obj["id"] =  obj_id;
        obj["name"] = r.title;
        obj["category"] = r.category != null ? r.category : "crafting";
        obj["speed"] = Json(1.0 / r.energy_required);
        obj["resultCount"] = Json(null);
        obj["ingredients"] = Json.emptyArray;

        foreach (const ref ItemAmount* ingd; r.ingredients)
        {
            string ingd_name = translate(ingd.name, ['-' : '_']);
            obj["ingredients"].appendArrayElement(Json([Json(ingd_name), Json(ingd.amount)]));
        }

        return obj;
    }

    void recipes_js(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        Json resp_json = Json.emptyObject;

        foreach (const ref Recipe r; pd.recipes)
        {
            const string obj_id = translate(r.name, ['-' : '_']);
            Json obj = create_recipe_obj(r, obj_id);

            foreach (const ref ItemAmount* rslt; r.results)
            {
                if (rslt.name == r.name)
                {
                    obj["resultCount"] = Json(rslt.amount != -1 ? rslt.amount : rslt.amount_min);
                    resp_json[obj["id"].get!string] = obj;
                    break;
                }
            }
        }

        // add recipes for items where they are the sole result, may be poor choices :(
        foreach (const ref Recipe r; pd.recipes)
        {
            const string obj_id = translate(r.name, ['-' : '_']);
            Json obj = create_recipe_obj(r, obj_id);

            if (r.results.length == 1 && resp_json[obj_id].type == Json.Type.undefined)
            {
                auto rslt = r.results[0];
                obj["title"] = pd.resolve_locale_name(rslt);
                obj["resultCount"] = Json(rslt.amount != -1 ? rslt.amount : rslt.amount_min);
                resp_json[obj["id"].get!string] = obj;
            }
        }

        // add recipes for remaining items, though they may be poor choices :(
        foreach (const ref Recipe r; pd.recipes)
        {
            foreach (const ref ItemAmount* rslt; r.results)
            {
                auto result_id = translate(rslt.name, ['-' : '_']);

                if (resp_json[result_id].type == Json.Type.undefined)
                {
                    auto rslt_obj = create_recipe_obj(r, result_id);
                    rslt_obj["resultCount"] = Json(rslt.amount != -1 ? rslt.amount : rslt.amount_min);
                    rslt_obj["title"] = pd.resolve_locale_name(rslt);
                    resp_json[result_id] = rslt_obj;
                }
            }
        }

        res.writeBody("recipes = " ~ serializeToJsonString(resp_json) ~ ";");
    }

    void modules_js(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        Json resp_json = Json.emptyObject;

        foreach (const ref Module r; pd.modules)
        {
            Json obj = Json.emptyObject;
            const string ratio_id = translate(r.name, ['-' : '_']);

            obj["id"] = ratio_id;
            obj["name"] = r.title;

            obj["tier"] = r.tier;
            // obj["limitation"] = r.limitation; // TODO
            obj["effect"] = Json.emptyObject;

            if (r.effect.consumption && r.effect.consumption.bonus != 1) {
                obj["effect"]["consumption"] = r.effect.consumption.bonus;
            }
            if (r.effect.speed && r.effect.speed.bonus != 1) {
                obj["effect"]["speed"] = r.effect.speed.bonus;
            }
            if (r.effect.productivity && r.effect.productivity.bonus != 1) {
                obj["effect"]["productivity"] = r.effect.productivity.bonus;
            }
            if (r.effect.pollution && r.effect.pollution.bonus != 1) {
                obj["effect"]["pollution"] = r.effect.pollution.bonus;
            }

            resp_json[ratio_id] = obj;
        }

        res.writeBody("modules = " ~ serializeToJsonString(resp_json) ~ ";");
    }

    void factories_js(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        Json resp_json = Json.emptyObject;

        foreach (const ref Furnace f; pd.furnaces)
        {
            Json obj = Json.emptyObject;
            const string ratio_id = translate(f.name, ['-' : '_']);

            obj["categories"] = Json.emptyArray;
            obj["id"] = ratio_id;
            obj["ingredientCount"] = 1;
            obj["name"] = f.title;
            obj["speed"] = f.crafting_speed;

            foreach (ref const string s; f.crafting_categories)
            {
                obj["categories"] ~= Json(s);
            }

            resp_json[ratio_id] = obj;
        }

        foreach (const ref AssemblingMachine am; pd.assemblingMachines)
        {
            Json obj = Json.emptyObject;
            const string ratio_id = translate(am.name, ['-' : '_']);

            obj["categories"] = Json.emptyArray;
            obj["id"] = ratio_id;
            obj["ingredientCount"] = am.ingredient_count;
            obj["name"] = am.title;
            obj["speed"] = am.crafting_speed;

            foreach (ref const string s; am.crafting_categories)
            {
                obj["categories"] ~= Json(s);
            }

            resp_json[ratio_id] = obj;
        }

        foreach (const ref MiningDrill md; pd.miningDrills)
        {
            Json obj = Json.emptyObject;
            const string ratio_id = translate(md.name, ['-' : '_']);

            obj["categories"] = Json.emptyArray;
            obj["id"] = ratio_id;
            obj["name"] = md.title;
            obj["speed"] = "calculate";
            obj["miningSpeed"] = md.mining_speed;
            obj["miningPower"] = md.mining_power;

            foreach (ref const string s; md.resource_categories)
            {
                obj["categories"] ~= Json(s);
            }

            resp_json[ratio_id] = obj;
        }

        res.writeBody("factories = " ~ serializeToJsonString(resp_json) ~ ";");
    }

    void factoratio_index(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const string title = "Factoratio";
        return res.render!("factoratio.dt", req, pd, title);
    }

    void factoratio_redir(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        res.redirect("factoratio/");
    }

    router.get("/factoratio/", &factoratio_index);
    router.get("/factoratio", &factoratio_redir);
    router.get("/factoratio/resources.js", &resources_js);
    router.get("/factoratio/recipes.js", &recipes_js);
    router.get("/factoratio/factories.js", &factories_js);
    router.get("/factoratio/modules.js", &modules_js);

    auto fsettings = new HTTPFileServerSettings;
    fsettings.serverPathPrefix = router.prefix ~ "/factoratio";
    router.get("/factoratio/*", serveStaticFiles("factoratio/", fsettings));
}
